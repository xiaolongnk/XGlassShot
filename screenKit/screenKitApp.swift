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
                .frame(minWidth: 550, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 550, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarManager: StatusBarManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Status Bar Manager
        statusBarManager = StatusBarManager.shared
        
        // Show and activate window after app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
        // Request screen recording permission on launch
        Task {
            if !PermissionManager.shared.canRecordScreen() {
                _ = await PermissionManager.shared.requestScreenRecordingPermission()
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in background
    }
}
