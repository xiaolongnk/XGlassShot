import Foundation
import AppKit
import KeyboardShortcuts

@main
struct MigrationRunner {
    @MainActor static func main() {
        guard let domain = Bundle.main.bundleIdentifier, domain.hasPrefix("qa.xglassshot.") else { exit(2) }
        defer { UserDefaults.standard.removePersistentDomain(forName: domain) }
        let replacement = KeyboardShortcuts.Shortcut(.q, modifiers: [.control, .shift])
        let custom = KeyboardShortcuts.Shortcut(.k, modifiers: [.control, .shift])
        let cases: [(String, KeyboardShortcuts.Shortcut?, KeyboardShortcuts.Shortcut)] = [
            ("fresh", nil, replacement),
            ("legacy", .init(.q, modifiers: [.command, .shift]), replacement),
            ("custom", custom, custom),
            ("already migrated", replacement, replacement)
        ]
        for (label, input, expected) in cases {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            if let input { KeyboardShortcuts.setShortcut(input, for: AppShortcut.toggleQuality.name) }
            DefaultsHarness().setupDefaultShortcuts()
            guard KeyboardShortcuts.getShortcut(for: AppShortcut.toggleQuality.name) == expected else {
                print("FAIL: \(label)")
                exit(1)
            }
            DefaultsHarness().setupDefaultShortcuts()
            guard KeyboardShortcuts.getShortcut(for: AppShortcut.toggleQuality.name) == expected else { exit(1) }
            print("PASS: \(label), idempotent")
        }

        // A cleared binding must survive initialization, including a restart.
        for action in AppShortcut.allCases {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.set(false, forKey: "KeyboardShortcuts_" + action.rawValue)
            DefaultsHarness().setupDefaultShortcuts()
            DefaultsHarness().setupDefaultShortcuts()
            guard KeyboardShortcuts.getShortcut(for: action.name) == nil else {
                print("FAIL: disabled \(action.rawValue) was restored")
                exit(1)
            }
            print("PASS: disabled \(action.rawValue) persists")
        }

        UserDefaults.standard.removePersistentDomain(forName: domain)
        let screenshot = KeyboardShortcuts.Shortcut(.i, modifiers: [.control, .shift])
        KeyboardShortcuts.setShortcut(screenshot, for: AppShortcut.captureScreenshot.name)
        DefaultsHarness().setupDefaultShortcuts()
        DefaultsHarness().setupDefaultShortcuts()
        guard KeyboardShortcuts.getShortcut(for: AppShortcut.captureScreenshot.name) == screenshot else { exit(1) }
        print("PASS: custom screenshot persists")

        let harness = DefaultsHarness()
        let duplicate = KeyboardShortcuts.getShortcut(for: AppShortcut.captureZone.name)!
        guard harness.isShortcutInUse(duplicate, for: .captureScreenshot),
              !harness.isShortcutInUse(screenshot, for: .captureScreenshot),
              KeyboardShortcuts.getShortcut(for: AppShortcut.captureScreenshot.name) == screenshot else { exit(1) }
        print("PASS: duplicate rejected before saving; same action is allowed")

        KeyboardShortcuts.setShortcut(nil, for: AppShortcut.changePrefix.name)
        harness.shortcutDidChange()
        guard KeyboardShortcuts.getShortcut(for: AppShortcut.changePrefix.name) == nil else { exit(1) }
        DefaultsHarness().setupDefaultShortcuts()
        guard KeyboardShortcuts.getShortcut(for: AppShortcut.changePrefix.name) == nil else { exit(1) }
        print("PASS: clearing via recorder remains disabled")

        harness.restoreDefaultShortcuts()
        guard AppShortcut.allCases.allSatisfy(\.usesDefaultShortcut) else { exit(1) }
        print("PASS: restore defaults re-enables all actions")

        let legacy = KeyboardShortcuts.Shortcut(.q, modifiers: [.command, .shift])
        KeyboardShortcuts.setShortcut(legacy, for: AppShortcut.toggleQuality.name)
        DefaultsHarness().setupDefaultShortcuts()
        guard KeyboardShortcuts.getShortcut(for: AppShortcut.toggleQuality.name) == legacy else { exit(1) }
        print("PASS: legacy migration runs only once, preserving later explicit choices")
    }
}
