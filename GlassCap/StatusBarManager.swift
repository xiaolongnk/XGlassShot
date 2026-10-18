//
//  StatusBarManager.swift
//  GlassCap
//
//  Created by rex on 2026/1/17.
//

import AppKit
import SwiftUI

@available(macOS 12.3, *)
class StatusBarManager: NSObject, NSMenuDelegate {
    static let shared = StatusBarManager()
    private var statusItem: NSStatusItem?
    private var recentCapturesMenuItem: NSMenuItem?

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
        menu.delegate = self

        let showItem = NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "s")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        // Quick-capture actions — each triggers capture + runs action atomically
        let copyTextItem = NSMenuItem(title: "Capture → Copy Text", action: #selector(captureAndCopyText), keyEquivalent: "")
        copyTextItem.target = self
        menu.addItem(copyTextItem)

        let beautifyItem = NSMenuItem(title: "Capture → Beautify", action: #selector(captureAndBeautify), keyEquivalent: "")
        beautifyItem.target = self
        menu.addItem(beautifyItem)

        let screenshotItem = NSMenuItem(title: "Capture Screenshot", action: #selector(captureScreenshot), keyEquivalent: "")
        screenshotItem.target = self
        menu.addItem(screenshotItem)

        menu.addItem(NSMenuItem.separator())

        // "Recent Captures" submenu — rebuilt each time the menu opens
        let recentItem = NSMenuItem(title: "Recent Captures", action: nil, keyEquivalent: "")
        recentItem.submenu = NSMenu(title: "Recent Captures")
        menu.addItem(recentItem)
        recentCapturesMenuItem = recentItem

        menu.addItem(NSMenuItem.separator())

        let recoveryItem = NSMenuItem(title: "Recover Recordings…".localized, action: #selector(showRecovery), keyEquivalent: "")
        recoveryItem.target = self
        menu.addItem(recoveryItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        rebuildRecentCapturesSubmenu()
    }

    private func rebuildRecentCapturesSubmenu() {
        guard let recentItem = recentCapturesMenuItem,
              let submenu = recentItem.submenu else { return }
        submenu.removeAllItems()

        let entries = ClipboardRegisterManager.shared.entries
        guard !entries.isEmpty else {
            let emptyItem = NSMenuItem(title: "No recent captures", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
            return
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        let calendar = Calendar.current

        for entry in entries {
            let timeString: String
            if calendar.isDateInToday(entry.capturedAt) {
                timeString = "Today \(timeFormatter.string(from: entry.capturedAt))"
            } else if calendar.isDateInYesterday(entry.capturedAt) {
                timeString = "Yesterday \(timeFormatter.string(from: entry.capturedAt))"
            } else {
                timeString = DateFormatter.localizedString(from: entry.capturedAt, dateStyle: .short, timeStyle: .short)
            }

            var title = timeString
            if let text = entry.copiedText, !text.isEmpty {
                let snippet = String(text.prefix(30)).replacingOccurrences(of: "\n", with: " ")
                title += " — \(snippet)"
            }

            let item = NSMenuItem(title: title, action: #selector(recentCaptureClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = entry.id
            item.image = entry.thumbnail.resized(to: NSSize(width: 32, height: 22))
            submenu.addItem(item)
        }
    }

    // MARK: - Actions

    @objc private func recentCaptureClicked(_ sender: NSMenuItem) {
        guard let entryID = sender.representedObject as? UUID else { return }
        let entries = ClipboardRegisterManager.shared.entries
        guard let entry = entries.first(where: { $0.id == entryID }) else { return }
        ClipboardRegisterManager.shared.copyToPasteboard(entry: entry)
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

    @objc private func showRecovery() {
        do { NSWorkspace.shared.open(try StorageManager.shared.recoveryDirectory()) }
        catch {
            let alert = NSAlert(error: error)
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
