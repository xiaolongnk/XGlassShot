import SwiftUI

struct SettingsDock: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    @ObservedObject private var launchManager = LaunchManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Path Selector
            Button(action: {
                 Task { await storageManager.selectSaveDirectory() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.cyan)
                    Text(storageManager.defaultSaveDirectory.lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary(for: colorScheme).opacity(0.9))
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .help("Change save location")
            
            Divider()
                .frame(height: 20)
                .background(Theme.divider(for: colorScheme))
            
            // Prefix
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .foregroundColor(.purple.opacity(0.8))
                    .font(.system(size: 12))
                
                ZStack(alignment: .trailing) {
                    TextField("Filename suffix...", text: $shortcutsManager.currentPrefix)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textPrimary(for: colorScheme))
                        .frame(width: 100)
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
                                .foregroundColor(Theme.textSecondary(for: colorScheme).opacity(0.5))
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 0)
                    }
                }
            }
            .padding(.horizontal, 16)
            .help("This text will be appended to the saved file name")
            
            Divider()
                .frame(height: 20)
                .background(Theme.divider(for: colorScheme))
            
            // Quality Toggle
            Button(action: { shortcutsManager.toggleQuality() }) {
                HStack(spacing: 6) {
                    Image(systemName: shortcutsManager.captureQuality == .low ? "hare.fill" : "sparkles")
                        .foregroundColor(shortcutsManager.captureQuality == .low ? .cyan : .yellow)
                    Text(shortcutsManager.captureQuality.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary(for: colorScheme).opacity(0.9))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())
            .help(shortcutsManager.captureQuality.description)
            
            Divider()
                .frame(height: 20)
                .background(Theme.divider(for: colorScheme))
            
            // Language Switcher
            LanguageSwitcher()
                .padding(.horizontal, 8)
            
            Divider()
                .frame(height: 20)
                .background(Theme.divider(for: colorScheme))
            
            // Icon Toggles
            HStack(spacing: 8) {
                DockToggle(
                    isOn: Binding(
                        get: { launchManager.isAutoStartEnabled },
                        set: { if $0 { launchManager.register() } else { launchManager.unregister() } }
                    ),
                    icon: "power.circle.fill",
                    activeColor: .blue,
                    tooltip: "Launch ScreenKit automatically when you log in"
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
            .padding(.horizontal, 12)
        }
        .background(
            Capsule()
                .fill(Theme.dockBackground(for: colorScheme))
        )
        .overlay(
            Capsule()
                .stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .shadow(
            color: Theme.cardShadow(for: colorScheme), 
            radius: Theme.cardShadowRadius(for: colorScheme) + 5, 
            y: 10
        )
        .onTapGesture {
            isInputFocused = false
        }
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
