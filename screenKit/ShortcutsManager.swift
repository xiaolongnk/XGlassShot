import Foundation
import AppKit
import SwiftUI
import KeyboardShortcuts
import Combine

enum AppShortcut: String, CaseIterable {
    case captureZone = "captureZone"
    case changePath = "changePath"
    case changePrefix = "changePrefix"
    
    var name: KeyboardShortcuts.Name {
        KeyboardShortcuts.Name(rawValue)
    }
}

@available(macOS 12.3, *)
final class ShortcutsManager: ObservableObject {
    static let shared = ShortcutsManager()
    
    @Published var currentPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    @Published var currentPrefix: String = "bug_"
    
    private var activeInputWindow: NSWindow?
    
    private init() {
        setupDefaultShortcuts()
        setupShortcuts()
    }
    
    private func setupDefaultShortcuts() {
        // Set default shortcuts if not already configured
        if KeyboardShortcuts.getShortcut(for: AppShortcut.captureZone.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.one, modifiers: [.command, .shift]), for: AppShortcut.captureZone.name)
        }
        if KeyboardShortcuts.getShortcut(for: AppShortcut.changePath.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.p, modifiers: [.command, .shift]), for: AppShortcut.changePath.name)
        }
        if KeyboardShortcuts.getShortcut(for: AppShortcut.changePrefix.name) == nil {
            KeyboardShortcuts.setShortcut(.init(.l, modifiers: [.command, .shift]), for: AppShortcut.changePrefix.name)
        }
    }
    
    private func setupShortcuts() {
        // Capture Zone: Cmd+Shift+1
        KeyboardShortcuts.onKeyUp(for: AppShortcut.captureZone.name) { [weak self] in
            self?.handleCaptureZone()
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
        GlassView(material: .hudWindow, blendingMode: .withinWindow) {
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
        }
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
