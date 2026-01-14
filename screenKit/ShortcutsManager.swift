import Foundation
import AppKit
import SwiftUI
import KeyboardShortcuts
import Combine

// MARK: - Capture Quality

enum CaptureQuality: String, CaseIterable {
    case quick = "quick"      // 1x scale, lower bitrate - fast sharing
    case high = "high"        // 2x scale (Retina), higher bitrate - full quality

    var displayName: String {
        switch self {
        case .quick: return "Quick"
        case .high: return "HQ"
        }
    }

    var description: String {
        switch self {
        case .quick: return "Quick Share (1x)"
        case .high: return "High Quality (2x)"
        }
    }

    var scaleFactor: CGFloat {
        switch self {
        case .quick: return 1.0
        case .high: return 2.0
        }
    }

    var videoBitrateFactor: Int {
        switch self {
        case .quick: return 4    // ~4 bits per pixel
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
    @Published var currentPrefix: String = "bug_"
    @Published var captureQuality: CaptureQuality = .quick {
        didSet {
            UserDefaults.standard.set(captureQuality.rawValue, forKey: "captureQuality")
            showQualityFeedback()
        }
    }

    private var activeInputWindow: NSWindow?
    private var feedbackWindow: NSWindow?

    private init() {
        // Load saved quality preference
        if let savedQuality = UserDefaults.standard.string(forKey: "captureQuality"),
           let quality = CaptureQuality(rawValue: savedQuality) {
            captureQuality = quality
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
        guard activeInputWindow == nil else { return }
        OverlayManager.shared.showSelectionOverlay()
    }

    private func handleCaptureScreenshot() {
        guard activeInputWindow == nil else { return }
        OverlayManager.shared.showScreenshotOverlay()
    }

    func toggleQuality() {
        captureQuality = (captureQuality == .quick) ? .high : .quick
    }

    private func showQualityFeedback() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showQualityFeedback()
            }
            return
        }

        // Close existing feedback window
        feedbackWindow?.close()
        feedbackWindow = nil

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

        // Capture quality value before creating the view
        let quality = self.captureQuality
        let hostingView = NSHostingView(rootView: QualityFeedbackView(quality: quality))
        hostingView.frame = window.contentView?.bounds ?? .zero
        window.contentView = hostingView

        window.center()
        // Use orderFront instead of makeKeyAndOrderFront since window ignores mouse events
        window.orderFront(nil)
        feedbackWindow = window

        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.feedbackWindow?.close()
            self?.feedbackWindow = nil
        }
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
    
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Prefix:")
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
    let quality: CaptureQuality

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: quality == .high ? "sparkles" : "hare")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(quality == .high ? .yellow : .cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text(quality.description)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("⌘⇧Q to toggle")
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
                .stroke(quality == .high ? Color.yellow.opacity(0.3) : Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
