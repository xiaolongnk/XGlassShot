import Foundation
import AppKit
import SwiftUI
import Combine

@MainActor
final class OverlayManager: ObservableObject {
    static let shared = OverlayManager()
    @Published private(set) var session = CaptureSession()
    @Published var pendingPostAction: CapturePostActionRequest?
    private var statusItem: NSStatusItem?
    private var selectionOverlay: SelectionOverlay?
    private var recordingInterruption: Error?

    var isShowingOverlay: Bool {
        if case .selecting = session.phase { return true }
        return false
    }
    var isRecording: Bool { session.phase == .recording }
    var isBusy: Bool { session.phase != .idle }

    private init() {
        selectionOverlay = SelectionOverlay()
        ScreenRecorder.shared.onRecordingError = { [weak self] error in
            guard let self else { return }
            if self.session.phase == .processing(.recording) { self.recordingInterruption = error }
            else { Task { @MainActor in await self.stopRecording(interruption: error) } }
        }
    }

    func setSelectionOverlay(_ overlay: SelectionOverlay) { selectionOverlay = overlay }
    func ensureSelectionOverlayReady() {
        if selectionOverlay == nil { selectionOverlay = SelectionOverlay() }
    }
    func showSelectionOverlay() { beginSelection(.recording) }
    func showScreenshotOverlay(postAction: CapturePostAction = .none) {
        beginSelection(.screenshot(postAction))
    }

    private func beginSelection(_ intent: CaptureIntent) {
        guard NSApp.modalWindow == nil, session.begin(intent) else { return }
        recordingInterruption = nil
        Task { @MainActor in
            guard await PermissionManager.shared.checkLivePermission() else {
                session.cancelSelection()
                let alert = NSAlert()
                alert.messageText = "Screen recording permission is required".localized
                alert.informativeText = "Allow GlassCap in System Settings, then try capturing again.".localized
                alert.addButton(withTitle: "Open Settings".localized)
                alert.addButton(withTitle: "Cancel".localized)
                NSApp.activate(ignoringOtherApps: true)
                if alert.runModal() == .alertFirstButtonReturn { PermissionManager.shared.openSystemSettings() }
                return
            }
            ensureSelectionOverlayReady()
            guard let overlay = selectionOverlay else { session.cancelSelection(); return }
            overlay.onConfirm = { [weak self] rect, annotations, screen in
                await self?.captureConfirmed(rect: rect, annotations: annotations, screen: screen)
            }
            overlay.onCancel = { [weak self] in self?.cancelSelection() }
            overlay.show()
        }
    }

    func cancelSelection() {
        selectionOverlay?.hide()
        session.cancelSelection()
    }

    private func captureConfirmed(rect: CGRect, annotations: [CGRect], screen: NSScreen) async {
        guard let intent = session.confirm() else { return }
        // Keep the operation locked until capture and saving finish.
        do {
            try await Task.sleep(nanoseconds: 150_000_000)
            let quality = ShortcutsManager.shared.captureQuality
            switch intent {
            case .screenshot(let action):
                let url = try await ScreenRecorder.shared.captureScreenshot(region: rect, annotations: annotations, screen: screen, quality: quality)
                if action != .none {
                    pendingPostAction = CapturePostActionRequest(action: action, url: url)
                    NSWorkspace.shared.open(Bundle.main.bundleURL)
                    NSApp.activate(ignoringOtherApps: true)
                }
                session.finish()
            case .recording:
                try await ScreenRecorder.shared.startRecording(region: rect, screen: screen, quality: quality)
                session.recordingStarted()
                showStopButton()
                if let recordingInterruption { await stopRecording(interruption: recordingInterruption) }
            }
        } catch StorageError.saveCancelled {
            session.finish()
        } catch {
            session.finish()
            reportFailure(error, recoveryURL: intent == .recording ? ScreenRecorder.shared.recoveryURL : nil)
        }
    }

    private func showStopButton() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "stop_recording".localized
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(stopButtonClicked)
    }
    @objc private func stopButtonClicked() { Task { await stopRecording() } }

    func stopRecording(interruption: Error? = nil) async {
        guard session.beginStop() else { return }
        defer {
            session.finish()
            if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
            statusItem = nil
        }
        do {
            let tempURL = try await ScreenRecorder.shared.stopRecording()
            let url = try await StorageManager.shared.saveRecording(from: tempURL, prefix: ShortcutsManager.shared.currentPrefix)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([url as NSURL])
            if let interruption {
                reportFailure(interruption, detail: "Recording was interrupted. The captured portion was saved.".localized)
            }
        } catch StorageError.saveCancelled {
            reportFailure(StorageError.saveCancelled, recoveryURL: StorageManager.shared.pendingRecordingURL)
        } catch {
            reportFailure(error, recoveryURL: StorageManager.shared.pendingRecordingURL)
        }
    }

    private func reportFailure(_ error: Error, detail: String? = nil, recoveryURL: URL? = nil) {
        let recoveryFile = recoveryURL.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Capture needs attention".localized
        alert.informativeText = detail ?? error.localizedDescription
        if let recoveryURL = recoveryFile {
            alert.informativeText += "\n\n" + "Your recording is kept here:".localized + "\n" + recoveryURL.path
            alert.addButton(withTitle: "Show Recording".localized)
        }
        alert.addButton(withTitle: "OK".localized)
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn, let recoveryURL = recoveryFile {
            NSWorkspace.shared.activateFileViewerSelecting([recoveryURL])
        }
    }
}
