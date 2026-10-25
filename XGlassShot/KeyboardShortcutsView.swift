import SwiftUI

struct KeyboardShortcutsView: View {
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard shortcuts".localized).font(.headline)
            Text("Available even when XGlassShot is in the background.".localized)
                .font(.caption).foregroundStyle(.secondary)
            ForEach(AppShortcut.allCases, id: \.self) { shortcut in
                shortcutRow(shortcut.title, keys: shortcut.shortcutText)
            }
            Text("Q = Quality · 1× ↔ 2×".localized)
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("In XGlassShot".localized).font(.subheadline.weight(.semibold))
            shortcutRow("Settings".localized, keys: "⌘,")
            shortcutRow("Keyboard shortcuts".localized, keys: "⌘/")
            Divider()
            Text("While selecting an area".localized).font(.subheadline.weight(.semibold))
            shortcutRow("Confirm selection".localized, keys: "↩ Return")
            shortcutRow("Cancel".localized, keys: "Esc")
            Text("⌘ = Command · ⇧ = Shift · Hold both, then press the key.".localized)
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
    }

    private func shortcutRow(_ title: String, keys: String) -> some View {
        HStack(spacing: 16) {
            Text(title)
            Spacer(minLength: 8)
            Text(keys)
                .font(.body.monospaced())
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(.quaternary, in: .rect(cornerRadius: 5))
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}
