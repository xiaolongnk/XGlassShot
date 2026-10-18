import SwiftUI

struct SettingsDock: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    @ObservedObject private var appearance = AppAppearance.shared
    @ObservedObject private var presentation = SettingsPresentation.shared
    @ObservedObject private var launch = LaunchManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings".localized).font(.system(size: 14, weight: .semibold))
            Picker("Settings".localized, selection: $presentation.tab) {
                Text("General".localized).tag(SettingsPresentation.Tab.general)
                Text("Capture".localized).tag(SettingsPresentation.Tab.capture)
                Text("Saving".localized).tag(SettingsPresentation.Tab.saving)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            VStack(spacing: 0) {
                switch presentation.tab {
                case .general: generalSettings
                case .capture: captureSettings
                case .saving: savingSettings
                }
            }
            .padding(.horizontal, 14)
            .background(.primary.opacity(0.035), in: .rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.primary.opacity(0.06)))

            HStack {
                Text("Settings save automatically".localized).font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button("Done".localized) { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .modifier(CaptureActionStyle(prominent: true))
            }
        }
        .padding(20)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .background(GlassSurface())
        .preferredColorScheme(appearance.mode.colorScheme)
        .tint(.blue)
        .onExitCommand { dismiss() }
    }

    private var generalSettings: some View {
        Group {
            SettingsRow("Appearance".localized) {
                Picker("Appearance".localized, selection: $appearance.mode) {
                    ForEach(AppAppearance.Mode.allCases) { mode in Text(mode.title).tag(mode) }
                }
                .pickerStyle(.segmented).labelsHidden()
            }
            Divider()
            SettingsRow("Transparency".localized) {
                HStack(spacing: 8) {
                    Slider(value: $appearance.transparency, in: 0...0.8, step: 0.05)
                        .accessibilityLabel("Transparency".localized)
                    Text(appearance.transparency, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit().frame(width: 32, alignment: .trailing)
                }
                .disabled(reduceTransparency)
                .help("Only the glass background changes; captures stay clear.".localized)
            }
            if reduceTransparency {
                Text("Reduce Transparency is enabled in macOS.".localized)
                    .font(.system(size: 10)).foregroundStyle(.secondary).padding(.bottom, 8)
            }
            Divider()
            SettingsRow("Language".localized) {
                Picker("Language".localized, selection: $localization.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                }.labelsHidden()
            }
            Divider()
            SettingsRow("Launch at login".localized) {
                Toggle("Launch at login".localized, isOn: Binding(
                    get: { launch.isAutoStartEnabled },
                    set: { if $0 { launch.register() } else { launch.unregister() } }
                )).labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
            Divider()
            SettingsRow("GlassCap") {
                Text("1.0 (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") + ")")
                    .foregroundStyle(.secondary)
                    .help(Bundle.main.infoDictionary?["GlassCapSourceRevision"] as? String ?? "")
            }
        }
    }

    private var captureSettings: some View {
        Group {
            SettingsRow("Image quality".localized) {
                Picker("Image quality".localized, selection: $shortcutsManager.captureQuality) {
                    Text("Standard · 1×").tag(CaptureQuality.low)
                    Text("Retina · 2×").tag(CaptureQuality.high)
                }.labelsHidden()
            }
            Divider()
            SettingsRow("Capture sound".localized) {
                Toggle("Capture sound".localized, isOn: $storageManager.playCaptureSound)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
            Divider()
            SettingsRow("Image border".localized) {
                Toggle("Image border".localized, isOn: $storageManager.addScreenshotOutline)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
        }
    }

    private var savingSettings: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Folder".localized).fontWeight(.medium)
                    Spacer()
                    Button("Choose…".localized) { Task { await storageManager.selectSaveDirectory() } }
                }
                Text(storageManager.defaultSaveDirectory.path)
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .textSelection(.enabled).lineLimit(3).fixedSize(horizontal: false, vertical: true)
            }.padding(.vertical, 12)
            Divider()
            SettingsRow("Filename prefix".localized) {
                TextField("Filename prefix".localized, text: $shortcutsManager.currentPrefix)
                    .textFieldStyle(.roundedBorder).labelsHidden()
            }
            Text((CaptureFileStore.sanitizedPrefix(shortcutsManager.currentPrefix).isEmpty ? "" : CaptureFileStore.sanitizedPrefix(shortcutsManager.currentPrefix) + "_") + "YYYYMMDD-HHmmss-SSS-id.png")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).lineLimit(2).padding(.bottom, 10)
            Divider()
            SettingsRow("Ask where to save".localized) {
                Toggle("Ask where to save".localized, isOn: $storageManager.alwaysAskWhereToSave)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
            }
        }
        .font(.system(size: 12))
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    var body: some View {
        HStack(spacing: 12) {
            Text(title).frame(width: 108, alignment: .leading)
            content().frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 12))
        .padding(.vertical, 10)
    }
}
