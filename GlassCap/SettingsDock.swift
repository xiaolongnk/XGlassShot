import SwiftUI

struct SettingsDock: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    @ObservedObject private var launchManager = LaunchManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @FocusState private var isInputFocused: Bool
    @State private var showAISettings = false
    @ObservedObject private var aiManager = AIManager.shared

    var body: some View {
        HStack(spacing: 0) {
            // Path Selector
            Button(action: {
                Task { await storageManager.selectSaveDirectory() }
            }) {
                HStack(spacing: 7) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 13))
                    Text(storageManager.defaultSaveDirectory.lastPathComponent)
                        .font(Theme.fontSecondary)
                        .foregroundColor(Theme.textPrimary(for: colorScheme))
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .help("Change save location")

            dockDivider

            // Filename suffix
            HStack(spacing: 7) {
                Image(systemName: "tag.fill")
                    .foregroundColor(.purple.opacity(0.75))
                    .font(.system(size: 11))

                ZStack(alignment: .trailing) {
                    TextField("Suffix…", text: $shortcutsManager.currentPrefix)
                        .textFieldStyle(.plain)
                        .font(Theme.fontMono)
                        .foregroundColor(Theme.textPrimary(for: colorScheme))
                        .frame(width: 92)
                        .focused($isInputFocused)
                        .onValueChanged(of: shortcutsManager.currentPrefix) { newValue in
                            let filtered = newValue.filter { !":/".contains($0) }
                            if filtered != newValue {
                                shortcutsManager.currentPrefix = filtered
                            }
                        }

                    if !shortcutsManager.currentPrefix.isEmpty {
                        Button(action: { shortcutsManager.currentPrefix = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.textSecondary(for: colorScheme).opacity(0.45))
                                .font(.system(size: 11))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 14)
            .help("This text will be appended to the saved file name")

            dockDivider

            // Quality Toggle
            Button(action: { shortcutsManager.toggleQuality() }) {
                HStack(spacing: 6) {
                    Image(systemName: shortcutsManager.captureQuality == .low ? "hare.fill" : "sparkles")
                        .foregroundColor(shortcutsManager.captureQuality == .low ? .accentColor : .yellow)
                        .font(.system(size: 12))
                    Text(shortcutsManager.captureQuality.displayName)
                        .font(Theme.fontSecondary)
                        .foregroundColor(Theme.textPrimary(for: colorScheme))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(PlainButtonStyle())
            .help(shortcutsManager.captureQuality.description)

            dockDivider

            // Language Switcher
            LanguageSwitcher()
                .padding(.horizontal, 8)

            dockDivider

            // AI Settings button
            Button(action: { showAISettings = true }) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(
                        aiManager.hasAPIKey
                            ? .yellow
                            : Theme.textSecondary(for: colorScheme).opacity(0.45)
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .help(aiManager.hasAPIKey ? "AI features enabled" : "Set up AI features")
            .sheet(isPresented: $showAISettings) { AISettingsView() }

            dockDivider

            // Icon Toggles
            HStack(spacing: 6) {
                DockToggle(
                    isOn: Binding(
                        get: { launchManager.isAutoStartEnabled },
                        set: { if $0 { launchManager.register() } else { launchManager.unregister() } }
                    ),
                    icon: "power.circle.fill",
                    activeColor: .blue,
                    tooltip: "Launch GlassCap automatically when you log in"
                )

                DockToggle(
                    isOn: $storageManager.playCaptureSound,
                    icon: "speaker.wave.2.fill",
                    activeColor: .pink,
                    tooltip: "Play a sound effect when capturing"
                )

                DockToggle(
                    isOn: $storageManager.alwaysAskWhereToSave,
                    icon: "questionmark.folder.fill",
                    activeColor: .orange,
                    tooltip: "Always ask where to save before saving"
                )

                DockToggle(
                    isOn: $storageManager.addScreenshotOutline,
                    icon: "square.dashed",
                    activeColor: .green,
                    tooltip: "Add a 1px border to screenshots"
                )
            }
            .padding(.horizontal, 10)
        }
        // Floating frosted appearance
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
        // Two-layer shadow for floating elevation
        .shadow(
            color: Theme.cardShadowDepth(for: colorScheme),
            radius: 4, x: 0, y: 2
        )
        .shadow(
            color: Theme.cardShadowElevation(for: colorScheme),
            radius: 18, x: 0, y: 8
        )
    }

    // Shared thin divider used between dock segments
    private var dockDivider: some View {
        Rectangle()
            .fill(Theme.divider(for: colorScheme))
            .frame(width: 1, height: 20)
    }
}

// MARK: - View Extensions

extension View {
    @ViewBuilder
    func onValueChanged<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}
