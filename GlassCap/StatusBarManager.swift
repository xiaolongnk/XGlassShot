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

        // Quick-capture actions — each triggers capture + runs action atomically
        let copyTextItem = NSMenuItem(title: "Capture → Copy Text", action: #selector(captureAndCopyText), keyEquivalent: "")
        copyTextItem.target = self
        menu.addItem(copyTextItem)

        let describeItem = NSMenuItem(title: "Capture → Describe", action: #selector(captureAndDescribe), keyEquivalent: "")
        describeItem.target = self
        menu.addItem(describeItem)

        let beautifyItem = NSMenuItem(title: "Capture → Beautify", action: #selector(captureAndBeautify), keyEquivalent: "")
        beautifyItem.target = self
        menu.addItem(beautifyItem)

        let screenshotItem = NSMenuItem(title: "Capture Screenshot", action: #selector(captureScreenshot), keyEquivalent: "")
        screenshotItem.target = self
        menu.addItem(screenshotItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func showWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSWorkspace.shared.open(Bundle.main.bundleURL)
    }

    @objc private func captureAndCopyText() {
        Task { @MainActor in
            OverlayManager.shared.showScreenshotOverlay(postAction: .copyText)
        }
    }

    @objc private func captureAndDescribe() {
        Task { @MainActor in
            OverlayManager.shared.showScreenshotOverlay(postAction: .describe)
        }
    }

    @objc private func captureAndBeautify() {
        Task { @MainActor in
            OverlayManager.shared.showScreenshotOverlay(postAction: .beautify)
        }
    }

    @objc private func captureScreenshot() {
        Task { @MainActor in
            OverlayManager.shared.showScreenshotOverlay()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
