import SwiftUI

/// Presented by the system Settings scene, including the standard ⌘, command.
struct SettingsDock: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    @ObservedObject private var launch = LaunchManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        TabView {
            Form {
                Picker("Language".localized, selection: $localization.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                }
                Toggle("Launch at login".localized, isOn: Binding(
                    get: { launch.isAutoStartEnabled },
                    set: { if $0 { launch.register() } else { launch.unregister() } }
                ))
                LabeledContent("GlassCap") {
                    Text("1.0 (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") + ")")
                        .foregroundStyle(.secondary)
                        .help(Bundle.main.infoDictionary?["GlassCapSourceRevision"] as? String ?? "")
                }
            }
            .tabItem { Label("General".localized, systemImage: "gearshape") }

            Form {
                Picker("Image quality".localized, selection: $shortcutsManager.captureQuality) {
                    Text("Standard · 1×").tag(CaptureQuality.low)
                    Text("Retina · 2×").tag(CaptureQuality.high)
                }
                Toggle("Capture sound".localized, isOn: $storageManager.playCaptureSound)
                Toggle("Image border".localized, isOn: $storageManager.addScreenshotOutline)
            }
            .tabItem { Label("Capture".localized, systemImage: "viewfinder") }

            Form {
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
            .tabItem { Label("Saving".localized, systemImage: "folder") }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 280)
    }
}
