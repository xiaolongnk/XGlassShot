import Foundation
import AppKit
import SwiftUI
import KeyboardShortcuts
import Combine

// MARK: - Recording Mode

enum CaptureQuality: String, CaseIterable {
    case low = "efficiency"      // 1x scale, lower bitrate - optimized for size
    case high = "highQuality"    // 2x scale (Retina), higher bitrate - full quality

    var title: String {
        self == .high ? "Retina · 2×".localized : "Standard · 1×".localized
    }

    var displayName: String {
        switch self {
        case .low: return "Low".localized
        case .high: return "High".localized
        }
    }

    var description: String {
        switch self {
        case .low: return "Low file size, 1x scale".localized
        case .high: return "Best resolution, 2x scale".localized
        }
    }

    var scaleFactor: CGFloat {
        switch self {
        case .low: return 1.0
        case .high: return 2.0
        }
    }

    var videoBitrateFactor: Int {
        switch self {
        case .low: return 4    // ~4 bits per pixel
        case .high: return 12    // ~12 bits per pixel
        }
    }
}

// MARK: - App Shortcuts

enum AppShortcut: String, CaseIterable {
    case captureZone = "captureZone"
    case captureScreenshot = "captureScreenshot"
    case toggleQuality = "toggleQuality"
    case changePrefix = "changePrefix"

    var name: KeyboardShortcuts.Name {
        KeyboardShortcuts.Name(rawValue)
    }

    var title: String {
        switch self {
        case .captureZone: return "Record".localized
        case .captureScreenshot: return "Screenshot".localized
        case .toggleQuality: return "Toggle quality".localized
        case .changePrefix: return "Filename prefix".localized
        }
    }

    var shortcutText: String {
        KeyboardShortcuts.getShortcut(for: name)?.description ?? "—"
    }

    var hint: String { title + " · " + shortcutText }
}

@available(macOS 12.3, *)
@MainActor
final class ShortcutsManager: ObservableObject {
    static let shared = ShortcutsManager()

    @Published var currentPrefix: String = "bug" {
        didSet {
            UserDefaults.standard.set(currentPrefix, forKey: "currentPrefix")
        }
    }
    @Published var captureQuality: CaptureQuality = .low {
        didSet {
            UserDefaults.standard.set(captureQuality.rawValue, forKey: "captureQuality")
            if !isRestoringPreferences && captureQuality != oldValue { showQualityFeedback() }
        }
    }

    private var activeInputWindow: NSWindow?
    private var feedbackWindow: NSWindow?
    private var feedbackTask: Task<Void, Never>?
    private var isRestoringPreferences = true

    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: "captureQuality"),
           let mode = CaptureQuality(rawValue: savedMode) {
            captureQuality = mode
        }
        
        // Load saved prefix
        if let savedPrefix = UserDefaults.standard.string(forKey: "currentPrefix") {
            currentPrefix = savedPrefix
        }
        setupDefaultShortcuts()
        setupShortcuts()
        isRestoringPreferences = false
    }

    private func setupDefaultShortcuts() {
        // Set default shortcuts if not already configured
        if KeyboardShortcuts.getShortcut(for: AppShortcut.captureZone.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.one, modifiers: [.command, .shift]), for: AppShortcut.captureZone.name)
        }
        if KeyboardShortcuts.getShortcut(for: AppShortcut.captureScreenshot.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.two, modifiers: [.command, .shift]), for: AppShortcut.captureScreenshot.name)
        }
        let qualityShortcut = KeyboardShortcuts.getShortcut(for: AppShortcut.toggleQuality.name)
        // Migrate the former default, which is reserved by macOS for Log Out.
        // Preserve any other saved binding.
        if qualityShortcut == nil || qualityShortcut == .init(.q, modifiers: [.command, .shift]) {
            KeyboardShortcuts.setShortcut(.init(.q, modifiers: [.control, .shift]), for: AppShortcut.toggleQuality.name)
        }
        if KeyboardShortcuts.getShortcut(for: AppShortcut.changePrefix.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.l, modifiers: [.command, .shift]), for: AppShortcut.changePrefix.name)
        }
    }

    private func setupShortcuts() {
        // Capture Zone (Recording): Cmd+Shift+1
        KeyboardShortcuts.onKeyUp(for: AppShortcut.captureZone.name) { [weak self] in
            self?.handleCaptureZone()
        }

        // Capture Screenshot: Cmd+Shift+2
        KeyboardShortcuts.onKeyUp(for: AppShortcut.captureScreenshot.name) { [weak self] in
            self?.handleCaptureScreenshot()
        }

        // Toggle Quality: Control+Shift+Q
        KeyboardShortcuts.onKeyUp(for: AppShortcut.toggleQuality.name) { [weak self] in
            self?.toggleQuality()
        }

        // Change Prefix: Cmd+Shift+L
        KeyboardShortcuts.onKeyUp(for: AppShortcut.changePrefix.name) { [weak self] in
            self?.showSaveDestinationEditor()
        }
    }

    private func handleCaptureZone() {
        if activeInputWindow != nil {
            closeActiveWindow()
        }
        OverlayManager.shared.showSelectionOverlay()
    }

    private func handleCaptureScreenshot() {
        if activeInputWindow != nil {
            closeActiveWindow()
        }
        OverlayManager.shared.showScreenshotOverlay()
    }

    func toggleQuality() {
        captureQuality = (captureQuality == .low) ? .high : .low
    }



    private func showQualityFeedback() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showQualityFeedback()
            }
            return
        }

        // Cancel pending hide task
        feedbackTask?.cancel()

        // Create window if needed
        if feedbackWindow == nil {
            createFeedbackWindow()
        }

        guard let window = feedbackWindow,
              let hostingView = window.contentView as? NSHostingView<QualityFeedbackView> else {
            return
        }

        // Update content
        hostingView.rootView = QualityFeedbackView(mode: captureQuality)
        window.setContentSize(hostingView.fittingSize)
        window.center()
        
        // Ensure window is visible
        window.alphaValue = 1.0
        window.orderFront(nil)

        // Schedule auto-hide
        feedbackTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    self.feedbackWindow?.animator().alphaValue = 0
                } completionHandler: {
                    Task { @MainActor in
                        self.feedbackWindow?.orderOut(nil)
                    }
                }
            }
        }
    }

    private func createFeedbackWindow() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let window = NSWindow(
            contentRect: NSRect(x: screenFrame.midX - 220, y: screenFrame.midY, width: 440, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: QualityFeedbackView(mode: captureQuality))
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        window.center()
        
        feedbackWindow = window
    }
    
    func showSaveDestinationEditor() {
        if let window = activeInputWindow, window.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }
        showSaveDestinationWindow()
    }
    
    private func showSaveDestinationWindow() {
        closeActiveWindow()
        
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.title = "Saving".localized
        window.identifier = NSUserInterfaceItemIdentifier("SaveDestinationPanel")
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(
            rootView: SaveDestinationView(prefix: Binding(
                get: { self.currentPrefix },
                set: { self.currentPrefix = $0 }
            ), chooseDirectory: { [weak window] in
                guard let window else { return }
                _ = await StorageManager.shared.selectSaveDirectory(presenting: window)
            }, onDismiss: {
                self.closeActiveWindow()
            })
        )
        window.contentView = hostingView
        window.setContentSize(hostingView.fittingSize)
        
        if let mainWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "GlassCapMainWindow" && $0.isVisible }) {
            window.setFrameOrigin(NSPoint(x: mainWindow.frame.midX - window.frame.width / 2,
                                          y: mainWindow.frame.midY - window.frame.height / 2))
        } else {
            window.center()
        }
        activeInputWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    func closeActiveWindow() {
        activeInputWindow?.close()
        activeInputWindow = nil
    }
}

// MARK: - Quality Feedback View

struct QualityFeedbackView: View {
    let mode: CaptureQuality
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode == .high ? "sparkles" : "hare")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(mode == .high ? .yellow : .cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(AppShortcut.toggleQuality.hint)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("Q = Quality · 1× ↔ 2×".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(GlassView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(mode == .high ? Color.yellow.opacity(0.3) : Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(8)
        .frame(width: 440)
    }
}
