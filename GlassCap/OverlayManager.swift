import Foundation
import AppKit
import SwiftUI
import Combine

enum CapturePostAction: Equatable {
    case none
    case copyText
    case describe
    case beautify
}

@available(macOS 12.3, *)
@MainActor
final class OverlayManager: ObservableObject {

    static let shared = OverlayManager()

    @Published var isShowingOverlay = false
    @Published var isRecording = false
    @Published var pendingPostAction: CapturePostAction = .none

    private var nextPostAction: CapturePostAction = .none
    private var statusItem: NSStatusItem?
    private var selectionOverlay: SelectionOverlay?
    
    private init() {
        selectionOverlay = SelectionOverlay()
    }
    
    func setSelectionOverlay(_ overlay: SelectionOverlay) {
        selectionOverlay = overlay
    }

    func ensureSelectionOverlayReady() {
        if selectionOverlay == nil {
            selectionOverlay = SelectionOverlay()
        }
    }
    
    func showSelectionOverlay() {
        ensureSelectionOverlayReady()
        guard PermissionManager.shared.canRecordScreen() else {
            PermissionManager.shared.openSystemSettings()
            return
        }
        guard let selectionOverlay = selectionOverlay else {
            print("Selection overlay not initialized")
            return
        }
        guard !isShowingOverlay else { return }
        
        isShowingOverlay = true
        
        // Configure SelectionOverlay with callbacks
        selectionOverlay.onConfirm = { [weak self] rect, annotations, screen in
            await self?.handleSelectionConfirmed(rect: rect, annotations: annotations, screen: screen)
        }

        selectionOverlay.onCancel = { [weak self] in
            await self?.handleSelectionCancelled()
        }

        selectionOverlay.show()
    }

    func showScreenshotOverlay(postAction: CapturePostAction) {
        nextPostAction = postAction
        showScreenshotOverlay()
    }

    func showScreenshotOverlay() {
        ensureSelectionOverlayReady()
        guard PermissionManager.shared.canRecordScreen() else {
            PermissionManager.shared.openSystemSettings()
            return
        }
        guard let selectionOverlay = selectionOverlay else {
            print("Selection overlay not initialized")
            return
        }
        guard !isShowingOverlay else { return }

        isShowingOverlay = true

        // Configure SelectionOverlay with callbacks
        selectionOverlay.onConfirm = { [weak self] rect, annotations, screen in
            await self?.handleScreenshotCaptured(rect: rect, annotations: annotations, screen: screen)
        }

        selectionOverlay.onCancel = { [weak self] in
            await self?.handleSelectionCancelled()
        }

        selectionOverlay.show()
    }

    private func handleScreenshotCaptured(rect: CGRect, annotations: [CGRect], screen: NSScreen) async {
        // The overlay was already hidden by confirmSelection() before this callback fires.
        // Only reset the manager-level flag here; do not call hide() again.
        isShowingOverlay = false

        try? await Task.sleep(nanoseconds: 500_000_000)

        let quality = ShortcutsManager.shared.captureQuality
        do {
            _ = try await ScreenRecorder.shared.captureScreenshot(region: rect, annotations: annotations, screen: screen, quality: quality)
            if nextPostAction != .none {
                pendingPostAction = nextPostAction
            }
        } catch {
            print("Failed to capture screenshot: \(error)")
        }
        nextPostAction = .none
    }

    private func handleSelectionConfirmed(rect: CGRect, annotations: [CGRect], screen: NSScreen) async {
        // The overlay was already hidden by confirmSelection() before this callback fires.
        // Only reset the manager-level flag here; do not call hide() again.
        isShowingOverlay = false

        // Wait 0.5 seconds before starting recording so the overlay is fully off-screen
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Start recording with current quality setting
        let quality = ShortcutsManager.shared.captureQuality
        do {
            // Note: Recording currently ignores annotations as it's a video stream
            try await ScreenRecorder.shared.startRecording(region: rect, screen: screen, quality: quality)
            isRecording = true
            showStopButton()
        } catch {
            isRecording = false
            print("Failed to start recording: \(error)")
        }
    }

    private func handleSelectionCancelled() async {
        // onCancel is fired either by ESC (which also triggers NSPanel's native dismiss)
        // or by confirmSelection() when guards fail. In both cases the overlay windows
        // may still be showing — call hide() here to guarantee clean teardown.
        selectionOverlay?.hide()
        isShowingOverlay = false
    }
    
    private func showStopButton() {
        let statusBar = NSStatusBar.system
        
        if statusItem == nil {
            statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        }
        
        guard let button = statusItem?.button else { return }
        
        button.title = "stop_recording".localized
        button.target = self
        button.action = #selector(stopButtonClicked)
    }
    
    @objc private func stopButtonClicked() {
        Task {
            await stopRecording()
        }
    }
    
    func stopRecording() async {
        guard isRecording else { return }

        do {
            let tempURL = try await ScreenRecorder.shared.stopRecording()

            isRecording = false
            hideStopButton()

            // Use StorageManager for silent auto-save
            let prefix = ShortcutsManager.shared.currentPrefix
            let destinationURL = try await StorageManager.shared.saveRecording(from: tempURL, prefix: prefix)

            // Copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([destinationURL as NSURL])

        } catch StorageError.saveCancelled {
            // User cancelled - this is fine
            isRecording = false
            hideStopButton()
        } catch {
            isRecording = false
            hideStopButton()
            print("Failed to stop recording: \(error)")
        }
    }
    
    private func hideStopButton() {
        statusItem?.button?.title = ""
        statusItem = nil
    }
}
