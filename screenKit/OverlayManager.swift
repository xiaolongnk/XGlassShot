import Foundation
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

@available(macOS 12.3, *)
@MainActor
final class OverlayManager: ObservableObject {
    
    static let shared = OverlayManager()
    
    @Published var isShowingOverlay = false
    @Published var isRecording = false
    
    private var statusItem: NSStatusItem?
    private var selectionOverlay: SelectionOverlay?
    
    private init() {}
    
    func setSelectionOverlay(_ overlay: SelectionOverlay) {
        selectionOverlay = overlay
    }
    
    func showSelectionOverlay() {
        guard PermissionManager.shared.canRecordScreen() else {
            PermissionManager.shared.openSystemSettings()
            return
        }
        guard !isShowingOverlay else { return }
        
        isShowingOverlay = true
        
        // Configure SelectionOverlay with callbacks
        selectionOverlay?.onConfirm = { [weak self] rect in
            await self?.handleSelectionConfirmed(rect: rect)
        }
        
        selectionOverlay?.onCancel = { [weak self] in
            await self?.handleSelectionCancelled()
        }
        
        selectionOverlay?.show()
    }
    
    func showScreenshotOverlay() {
        guard PermissionManager.shared.canRecordScreen() else {
            PermissionManager.shared.openSystemSettings()
            return
        }
        guard !isShowingOverlay else { return }
        
        isShowingOverlay = true
        
        // Configure SelectionOverlay with callbacks
        selectionOverlay?.onConfirm = { [weak self] rect in
            await self?.handleScreenshotCaptured(rect: rect)
        }
        
        selectionOverlay?.onCancel = { [weak self] in
            await self?.handleSelectionCancelled()
        }
        
        selectionOverlay?.show()
    }
    
    private func handleScreenshotCaptured(rect: CGRect) async {
        // Hide overlay immediately
        selectionOverlay?.hide()
        isShowingOverlay = false
        
        // Wait 0.5 seconds
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Capture Screenshot
        do {
            _ = try await ScreenRecorder.shared.captureScreenshot(region: rect)
        } catch {
            print("Failed to capture screenshot: \(error)")
        }
    }
    
    private func handleSelectionConfirmed(rect: CGRect) async {
        // Hide overlay immediately
        selectionOverlay?.hide()
        isShowingOverlay = false
        
        // Wait 0.5 seconds
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Start recording
        do {
            try await ScreenRecorder.shared.startRecording(region: rect)
            isRecording = true
            showStopButton()
        } catch {
            isRecording = false
            print("Failed to start recording: \(error)")
        }
    }
    
    private func handleSelectionCancelled() async {
        selectionOverlay?.hide()
        isShowingOverlay = false
    }
    
    private func showStopButton() {
        let statusBar = NSStatusBar.system
        
        if statusItem == nil {
            statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        }
        
        guard let button = statusItem?.button else { return }
        
        button.title = "Stop Recording"
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

            // Use NSSavePanel for sandbox-compatible file saving
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
            let fileName = "Screen Recording \(formatter.string(from: Date())).mov"

            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = fileName
            savePanel.allowedContentTypes = [UTType.movie]
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            savePanel.title = "Save Recording"
            savePanel.message = "Choose a location to save your recording"

            let response = await savePanel.begin()

            isRecording = false
            hideStopButton()

            guard response == .OK, let destinationURL = savePanel.url else {
                // User cancelled - clean up temp file
                try? FileManager.default.removeItem(at: tempURL)
                return
            }

            // Copy file to user-selected location
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.copyItem(at: tempURL, to: destinationURL)

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)

            // Open in Finder
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
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

