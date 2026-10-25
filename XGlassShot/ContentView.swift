import SwiftUI
import AppKit
import KeyboardShortcuts

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
                Button { shortcuts.showSaveDestinationEditor() } label: {
                    Label(CaptureFileStore.sanitizedPrefix(shortcuts.currentPrefix).isEmpty ? "Prefix".localized : CaptureFileStore.sanitizedPrefix(shortcuts.currentPrefix), systemImage: "tag")
                        .lineLimit(1).truncationMode(.middle)
                }
                .help("Filename prefix".localized)
                Spacer(minLength: 4)
                Button { settings.show(.shortcuts) } label: {
                    Label("Keyboard shortcuts".localized, systemImage: "keyboard")
                }
                .labelStyle(.iconOnly)
                .help("Keyboard shortcuts".localized + " (⌘/)")
                Text(AppShortcut.toggleQuality.shortcutText)
                    .font(.caption.monospaced())
                    .help(AppShortcut.toggleQuality.hint)
                Picker("Image quality".localized, selection: $shortcuts.captureQuality) {
                    ForEach(CaptureQuality.allCases, id: \.self) { quality in
                        Text(quality.title).tag(quality)
                    }
                }
                .pickerStyle(.menu).labelsHidden().fixedSize()
                .help(AppShortcut.toggleQuality.hint)
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
            if #available(macOS 26, *) {
                ToolbarSpacer(.flexible)
            } else {
                ToolbarItem { Spacer() }
            }
            ToolbarItemGroup(placement: .automatic) {
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
    @ObservedObject private var shortcuts = ShortcutsManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 3) {
            Button { overlay.showScreenshotOverlay() } label: {
                Label("Screenshot".localized, systemImage: "viewfinder")
            }
            .labelStyle(.titleAndIcon)
            .buttonStyle(.automatic)
            .foregroundStyle(.primary)
            .help(AppShortcut.captureScreenshot.hint)
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
        .labelStyle(.titleAndIcon)
        .tint(overlay.isRecording ? .red : nil)
        .help(overlay.isRecording ? "Stop Recording".localized : AppShortcut.captureZone.hint)
        .disabled(overlay.isBusy && !overlay.isRecording)
    }
}

struct CaptureMenuCommands: Commands {
    @ObservedObject private var overlay = OverlayManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    var body: some Commands {
        CommandMenu("Capture".localized) {
            Button("Screenshot".localized) { overlay.showScreenshotOverlay() }
                .globalKeyboardShortcut(AppShortcut.captureScreenshot.name).disabled(overlay.isBusy)
            Button(overlay.isRecording ? "Stop Recording".localized : "Record".localized) {
                if overlay.isRecording { Task { await overlay.stopRecording() } }
                else { overlay.showSelectionOverlay() }
            }
            .globalKeyboardShortcut(AppShortcut.captureZone.name)
            .disabled(overlay.isBusy && !overlay.isRecording)
            Divider()
            Button("Toggle quality".localized) { ShortcutsManager.shared.toggleQuality() }
                .globalKeyboardShortcut(AppShortcut.toggleQuality.name)
            Button("Filename prefix".localized) { ShortcutsManager.shared.showSaveDestinationEditor() }
                .globalKeyboardShortcut(AppShortcut.changePrefix.name)
        }
        CommandGroup(replacing: .help) {
            Button("Keyboard shortcuts".localized) { SettingsPresentation.shared.show(.shortcuts) }
                .keyboardShortcut("/", modifiers: .command)
        }
    }
}
