import SwiftUI

struct KeyboardShortcutsView: View {
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available even when XGlassShot is in the background.".localized)
                .font(.system(size: 11)).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(AppShortcut.allCases, id: \.self) { shortcut in
                        shortcutRow(shortcut.title, keys: shortcut.shortcutText)
                    }
                    Text("Q = Quality · 1× ↔ 2×".localized)
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .accessibilityElement(children: .contain)
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("In XGlassShot".localized).fontWeight(.semibold)
                    shortcutRow("Settings".localized, keys: "⌘,")
                    shortcutRow("Keyboard shortcuts".localized, keys: "⌘/")
                    Divider().padding(.vertical, 2)
                    Text("While selecting an area".localized).fontWeight(.semibold)
                    shortcutRow("Confirm selection".localized, keys: "↩")
                    shortcutRow("Cancel".localized, keys: "Esc")
                }
                .font(.system(size: 11))
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .accessibilityElement(children: .contain)
            }
            Text("⌘ = Command · ⇧ = Shift · Hold both, then press the key.".localized)
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    private func shortcutRow(_ title: String, keys: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
            Spacer(minLength: 8)
            Text(keys)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(.quaternary, in: .rect(cornerRadius: 5))
                .fixedSize()
        }
        .font(.system(size: 12))
        .accessibilityElement(children: .combine)
    }
}
