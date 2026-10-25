import SwiftUI
import KeyboardShortcuts

struct KeyboardShortcutsView: View {
    @ObservedObject var shortcutsManager: ShortcutsManager
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Available even when XGlassShot is in the background.".localized)
                Text("Click to change · Esc cancels · Delete clears".localized)
            }
            .font(.system(size: 10)).foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(AppShortcut.allCases, id: \.self) { action in
                    HStack(spacing: 12) {
                        Text(action.title)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        KeyboardShortcuts.Recorder(for: action.name) { _ in
                            shortcutsManager.shortcutDidChange()
                        }
                        .shortcutValidation { shortcut in
                            shortcutsManager.isShortcutInUse(shortcut, for: action)
                                ? .disallow(reason: "Shortcut already in use".localized + "\n" + "Choose a different combination for each action.".localized)
                                : .allow
                        }
                        .frame(width: 130)
                        .accessibilityLabel(action.title)
                    }
                    .font(.system(size: 12))
                    .accessibilityElement(children: .contain)
                }
            }
            Divider().padding(.vertical, 2)
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("In XGlassShot".localized).fontWeight(.semibold)
                    shortcutRow("Settings".localized, keys: "⌘,")
                    shortcutRow("Keyboard shortcuts".localized, keys: "⌘/")
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                VStack(alignment: .leading, spacing: 4) {
                    Text("While selecting an area".localized).fontWeight(.semibold)
                    shortcutRow("Confirm selection".localized, keys: "↩")
                    shortcutRow("Cancel".localized, keys: "Esc")
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .font(.system(size: 10))
            HStack {
                Button("Restore defaults".localized) { shortcutsManager.restoreDefaultShortcuts() }
                    .controlSize(.small)
                    .disabled(AppShortcut.allCases.allSatisfy(\.usesDefaultShortcut))
                Spacer(minLength: 8)
                Text("⌘ Command · ⇧ Shift · ⌃ Control".localized)
                    .font(.system(size: 9)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }

    private func shortcutRow(_ title: String, keys: String) -> some View {
        HStack(spacing: 6) {
            Text(title).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(keys)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding(.horizontal, 4).padding(.vertical, 1)
                .background(.quaternary, in: .rect(cornerRadius: 4))
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}
