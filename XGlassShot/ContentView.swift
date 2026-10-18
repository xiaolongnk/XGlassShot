import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var shortcuts = ShortcutsManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var appearance = AppAppearance.shared
    @ObservedObject private var settings = SettingsPresentation.shared

    var body: some View {
        VStack(spacing: 0) {
            CapturePreviewView(storageManager: storage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
            Divider().opacity(0.5)
            HStack(spacing: 12) {
                Button { Task { await storage.selectSaveDirectory() } } label: {
                    Label(storage.defaultSaveDirectory.lastPathComponent, systemImage: "folder")
                        .lineLimit(1).truncationMode(.middle)
                }
                .help(storage.defaultSaveDirectory.path)
                Button { settings.show(.saving) } label: {
                    Label(CaptureFileStore.sanitizedPrefix(shortcuts.currentPrefix).isEmpty ? "Prefix".localized : CaptureFileStore.sanitizedPrefix(shortcuts.currentPrefix), systemImage: "tag")
                        .lineLimit(1).truncationMode(.middle)
                }
                .help("Filename prefix".localized)
                Spacer(minLength: 4)
                Menu {
                    Picker("Image quality".localized, selection: $shortcuts.captureQuality) {
                        Text("Standard · 1×").tag(CaptureQuality.low)
                        Text("Retina · 2×").tag(CaptureQuality.high)
                    }
                } label: {
                    Text(shortcuts.captureQuality == .high ? "Retina · 2×" : "Standard · 1×")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton).fixedSize()
                .help("Image quality".localized)
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11)).foregroundStyle(.secondary)
            .padding(.horizontal, 16).frame(height: 34)
            .background(.regularMaterial)
        }
        .background(GlassSurface())
        .background(CompactWindowSizing())
        .preferredColorScheme(appearance.mode.colorScheme)
        .navigationTitle("XGlassShot")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 6) {
                    Image(systemName: "viewfinder").font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white).padding(4)
                        .background(.blue.gradient, in: .rect(cornerRadius: 5))
                        .accessibilityHidden(true)
                    Text("XGlassShot").font(.system(size: 12, weight: .semibold))
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                CaptureControlsRow()
                Button { settings.show() } label: {
                    Label("Settings".localized, systemImage: "gearshape")
                }.help("Settings".localized)
            }
        }
        .sheet(isPresented: $settings.isPresented) {
            SettingsDock(storageManager: storage, shortcutsManager: shortcuts)
        }
    }
}

struct CaptureControlsRow: View {
    @ObservedObject private var overlay = OverlayManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 3) {
            Button { overlay.showScreenshotOverlay() } label: {
                Label("Screenshot".localized, systemImage: "viewfinder")
            }
            .labelStyle(.titleAndIcon)
            .buttonStyle(.automatic)
            .foregroundStyle(.primary)
            .help("Screenshot".localized + " (⌘⇧2)")
            Menu {
                Button("Any display".localized) { overlay.showScreenshotOverlay() }
                Divider()
                ForEach(NSScreen.screens, id: \.displayIdentifier) { screen in
                    Button(screen.localizedName) { overlay.showScreenshotOverlay(on: screen) }
                }
            } label: {
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .medium))
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .accessibilityLabel("Choose a display".localized)
            .help("Choose a display".localized)
        }
        .disabled(overlay.isBusy)

        Button {
            if overlay.isRecording { Task { await overlay.stopRecording() } }
            else { overlay.showSelectionOverlay() }
        } label: {
            Label(overlay.isRecording ? "Stop Recording".localized : "Record".localized,
                  systemImage: overlay.isRecording ? "stop.circle.fill" : "record.circle")
        }
        .tint(overlay.isRecording ? .red : nil)
        .help((overlay.isRecording ? "Stop Recording".localized : "Record".localized) + " (⌘⇧1)")
        .disabled(overlay.isBusy && !overlay.isRecording)
    }
}

struct CaptureMenuCommands: Commands {
    @ObservedObject private var overlay = OverlayManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    var body: some Commands {
        CommandMenu("Capture".localized) {
            Button("Screenshot".localized) { overlay.showScreenshotOverlay() }
                .keyboardShortcut("2", modifiers: [.command, .shift]).disabled(overlay.isBusy)
            Button(overlay.isRecording ? "Stop Recording".localized : "Record".localized) {
                if overlay.isRecording { Task { await overlay.stopRecording() } }
                else { overlay.showSelectionOverlay() }
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])
            .disabled(overlay.isBusy && !overlay.isRecording)
        }
    }
}
