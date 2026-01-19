//
//  StatusBarManager.swift
//  GlassCap
//
//  Created by rex on 2026/1/17.
//

import AppKit
import SwiftUI

class StatusBarManager: NSObject {
    static let shared = StatusBarManager()
    private var statusItem: NSStatusItem?
    
    override init() {
        super.init()
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: "GlassCap")
        }
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        let showItem = NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "s")
        showItem.target = self
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func showWindow() {
        // Activate the app
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Simulating a Dock icon click by opening the app bundle
        // This relies on the system to handle the "reopen" logic (showing existing window or creating new one)
        NSWorkspace.shared.open(Bundle.main.bundleURL)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
