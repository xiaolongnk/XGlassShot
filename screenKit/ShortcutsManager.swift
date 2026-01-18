import Foundation
import AppKit
import SwiftUI
import KeyboardShortcuts
import Combine

// MARK: - Recording Mode

enum CaptureQuality: String, CaseIterable {
    case low = "efficiency"      // 1x scale, lower bitrate - optimized for size
    case high = "highQuality"    // 2x scale (Retina), higher bitrate - full quality

    var displayName: String {
        switch self {
        case .low: return "Efficiency".localized
        case .high: return "High Quality".localized
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
    case changePath = "changePath"
    case changePrefix = "changePrefix"

    var name: KeyboardShortcuts.Name {
        KeyboardShortcuts.Name(rawValue)
    }
}

@available(macOS 12.3, *)
@MainActor
final class ShortcutsManager: ObservableObject {
    static let shared = ShortcutsManager()

    @Published var currentPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    @Published var currentPrefix: String = "bug"
    @Published var captureQuality: CaptureQuality = .low {
        didSet {
            UserDefaults.standard.set(captureQuality.rawValue, forKey: "captureQuality")
            showQualityFeedback()
        }
    }

    private var activeInputWindow: NSWindow?
    private var feedbackWindow: NSWindow?
    private var feedbackTask: Task<Void, Never>?

    private init() {
        // Load saved quality preference
        if let savedMode = UserDefaults.standard.string(forKey: "captureQuality"),
           let mode = CaptureQuality(rawValue: savedMode) {
            captureQuality = mode
        }
        setupDefaultShortcuts()
        setupShortcuts()
    }

    private func setupDefaultShortcuts() {
        // Set default shortcuts if not already configured
        if KeyboardShortcuts.getShortcut(for: AppShortcut.captureZone.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.one, modifiers: [.command, .shift]), for: AppShortcut.captureZone.name)
        }
        if KeyboardShortcuts.getShortcut(for: AppShortcut.captureScreenshot.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.two, modifiers: [.command, .shift]), for: AppShortcut.captureScreenshot.name)
        }
        if KeyboardShortcuts.getShortcut(for: AppShortcut.toggleQuality.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.q, modifiers: [.command, .shift]), for: AppShortcut.toggleQuality.name)
        }
        if KeyboardShortcuts.getShortcut(for: AppShortcut.changePath.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.p, modifiers: [.command, .shift]), for: AppShortcut.changePath.name)
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

        // Toggle Quality: Cmd+Shift+Q
        KeyboardShortcuts.onKeyUp(for: AppShortcut.toggleQuality.name) { [weak self] in
            self?.toggleQuality()
        }

        // Change Path: Cmd+Shift+P
        KeyboardShortcuts.onKeyUp(for: AppShortcut.changePath.name) { [weak self] in
            self?.handleChangePath()
        }

        // Change Prefix: Cmd+Shift+L
        KeyboardShortcuts.onKeyUp(for: AppShortcut.changePrefix.name) { [weak self] in
            self?.handleChangePrefix()
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
    func toggleQuality() {
        captureQuality = (captureQuality == .low) ? .high : .low
    }
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
        
        // Ensure window is visible
        window.alphaValue = 1.0
        window.orderFront(nil)

        // Schedule auto-hide
        feedbackTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
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
            contentRect: NSRect(x: screenFrame.midX - 100, y: screenFrame.midY - 30, width: 200, height: 60),
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
        hostingView.frame = window.contentView?.bounds ?? .zero
        window.contentView = hostingView
        window.center()
        
        feedbackWindow = window
    }
    
    private func handleChangePath() {
        guard activeInputWindow == nil else { return }
        showPathInputWindow()
    }
    
    private func handleChangePrefix() {
        guard activeInputWindow == nil else { return }
        showPrefixInputWindow()
    }
    
    private func showPathInputWindow() {
        closeActiveWindow()
        
        let screenFrame = NSScreen.main?.frame ?? .zero
        let window = NSWindow(
            contentRect: NSRect(x: screenFrame.midX - 250, y: screenFrame.midY - 50, width: 500, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(
            rootView: TerminalPathInput(currentPath: Binding(
                get: { self.currentPath },
                set: { self.currentPath = $0 }
            )) {
                self.closeActiveWindow()
            }
            .background(Color.clear)
        )
        hostingView.frame = window.contentView?.bounds ?? .zero
        window.contentView = hostingView
        
        window.makeKeyAndOrderFront(nil)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        
        activeInputWindow = window
        
        // Focus text field after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeFirstResponder(hostingView)
        }
    }
    
    private func showPrefixInputWindow() {
        closeActiveWindow()
        
        let screenFrame = NSScreen.main?.frame ?? .zero
        let window = NSWindow(
            contentRect: NSRect(x: screenFrame.midX - 200, y: screenFrame.midY - 30, width: 400, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(
            rootView: PrefixInputView(prefix: Binding(
                get: { self.currentPrefix },
                set: { self.currentPrefix = $0 }
            )) {
                self.closeActiveWindow()
            }
            .background(Color.clear)
        )
        hostingView.frame = window.contentView?.bounds ?? .zero
        window.contentView = hostingView
        
        window.makeKeyAndOrderFront(nil)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        
        activeInputWindow = window
        
        // Focus text field after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeFirstResponder(hostingView)
        }
    }
    
    func closeActiveWindow() {
        activeInputWindow?.close()
        activeInputWindow = nil
    }
}

struct PrefixInputView: View {
    @Binding var prefix: String
    let onDismiss: () -> Void
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text("prefix_label".localized)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
            
            TextField("", text: $inputText)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    confirmPrefix()
                }
                .onKeyPress(.escape) {
                    onDismiss()
                    return .handled
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(GlassView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            inputText = prefix
            isFocused = true
        }
    }
    
    private func confirmPrefix() {
        prefix = inputText
        onDismiss()
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
                Text(mode.description)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("toggle_shortcut".localized)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
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
    }
}
