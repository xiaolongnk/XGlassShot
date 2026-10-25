//
//  GlassCapApp.swift
//  GlassCap
//
//  Created by rex on 2026/1/11.
//

import SwiftUI

@main
struct XGlassShotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        LegacySettings.removeCloudAIKey()
        // Initialize managers
        _ = LocalizationManager.shared
        _ = ShortcutsManager.shared
        _ = PermissionManager.shared
        _ = StorageManager.shared
        _ = AppAppearance.shared

    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: CompactWindowSizing.minimumSize.width,
                       minHeight: CompactWindowSizing.minimumSize.height)
                .onAppear {
                    // Force activation when the content view appears
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .defaultSize(width: CompactWindowSizing.defaultSize.width,
                     height: CompactWindowSizing.defaultSize.height)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CaptureMenuCommands()
            CommandGroup(replacing: .appSettings) {
                Button("Settings…".localized) { SettingsPresentation.shared.show() }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarManager: StatusBarManager?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Set activation policy early to ensure app appears in Dock and can become foreground
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Status Bar Manager
        statusBarManager = StatusBarManager.shared

        // Ensure overlay is ready even if the main window is not shown
        Task { @MainActor in
            OverlayManager.shared.ensureSelectionOverlayReady()
        }

        // Show and activate window after app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Activate the app and bring it to front
            NSApplication.shared.activate(ignoringOtherApps: true)

            // Make the main window key and order it front
            // Filter for normal windows to avoid making an overlay window key
            let mainWindow = NSApplication.shared.windows.first { window in
                window.canBecomeKey && window.className.contains("SwiftUI") && !window.className.contains("SelectionWindow")
            }
            
            if let window = mainWindow ?? NSApplication.shared.windows.first(where: { $0.canBecomeKey }) {
                window.makeKeyAndOrderFront(nil)
            }
        }

    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in background
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let manager = OverlayManager.shared
        if manager.isShowingOverlay {
            manager.cancelSelection()
            return .terminateNow
        }
        if manager.isRecording {
            Task { @MainActor in
                await manager.stopRecording()
                sender.reply(toApplicationShouldTerminate: true)
            }
            return .terminateLater
        }
        // Do not abandon a screenshot, startup, or file finalization midway.
        if manager.isBusy {
            NSSound.beep()
            return .terminateCancel
        }
        return .terminateNow
    }
}
