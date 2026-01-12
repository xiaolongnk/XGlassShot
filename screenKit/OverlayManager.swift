import Foundation
import AppKit
import SwiftUI
import Combine

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
            
            // Save to Desktop
            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
            let fileName = "Screen Recording \(formatter.string(from: Date())).mov"
            let destinationURL = desktopURL.appendingPathComponent(fileName)
            
            // Copy file
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.copyItem(at: tempURL, to: destinationURL)
            
            // Open in Finder
            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])

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

