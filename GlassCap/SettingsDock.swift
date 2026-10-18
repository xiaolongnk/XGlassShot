import SwiftUI

struct SettingsDock: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    @ObservedObject private var launch = LaunchManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings".localized).font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("Done".localized) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(20)
            Divider()
            Form {
                Section("Saving".localized) {
                    LabeledContent("Folder".localized) {
                        HStack {
                            Text(storageManager.defaultSaveDirectory.lastPathComponent)
                                .lineLimit(1).foregroundStyle(.secondary)
                                .help(storageManager.defaultSaveDirectory.path)
                            Button("Choose…".localized) { Task { await storageManager.selectSaveDirectory() } }
                        }
                    }
                    TextField("Filename prefix".localized, text: $shortcutsManager.currentPrefix)
                        .textFieldStyle(.roundedBorder)
                    Toggle("Ask where to save".localized, isOn: $storageManager.alwaysAskWhereToSave)
                }
                Section("Capture".localized) {
                    Picker("Image quality".localized, selection: $shortcutsManager.captureQuality) {
                        Text("Standard · 1×").tag(CaptureQuality.low)
                        Text("Retina · 2×").tag(CaptureQuality.high)
                    }
                    Toggle("Capture sound".localized, isOn: $storageManager.playCaptureSound)
                    Toggle("Image border".localized, isOn: $storageManager.addScreenshotOutline)
                }
                Section("General".localized) {
                    Picker("Language".localized, selection: $localization.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                    }
                    Toggle("Launch at login".localized, isOn: Binding(
                        get: { launch.isAutoStartEnabled },
                        set: { if $0 { launch.register() } else { launch.unregister() } }
                    ))
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 420, height: 470)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
