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
            KeyboardShortcuts.setShortcut(input, for: AppShortcut.toggleQuality.name)
            DefaultsHarness().setupDefaultShortcuts()
            guard KeyboardShortcuts.getShortcut(for: AppShortcut.toggleQuality.name) == expected else {
                print("FAIL: \(label)")
                exit(1)
            }
            DefaultsHarness().setupDefaultShortcuts()
            guard KeyboardShortcuts.getShortcut(for: AppShortcut.toggleQuality.name) == expected else { exit(1) }
            print("PASS: \(label), idempotent")
        }
    }
}
