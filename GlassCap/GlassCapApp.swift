//
//  GlassCapApp.swift
//  GlassCap
//
//  Created by rex on 2026/1/11.
//

import SwiftUI

@main
struct GlassCapApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Initialize managers
        _ = LocalizationManager.shared
        _ = ShortcutsManager.shared
        _ = PermissionManager.shared
        _ = StorageManager.shared

        // Resolve bookmarked save directory for sandbox access
        _ = StorageManager.shared.resolveBookmarkedDirectory()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 660, minHeight: 620)
                .onAppear {
                    // Force activation when the content view appears
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 660, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {}
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

        // Request screen recording permission on launch.
        // Use the live SCShareableContent check — CGPreflightScreenCaptureAccess()
        // is cached per-process and can return false even when TCC has the grant.
        Task {
            _ = await PermissionManager.shared.requestScreenRecordingPermission()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in background
    }
}
