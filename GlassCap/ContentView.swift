import SwiftUI
import AppKit

/// A small native workspace: commands in the toolbar, the capture on the canvas.
struct ContentView: View {
    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var shortcuts = ShortcutsManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            CapturePreviewView(storageManager: storage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

            Divider()
            HStack(spacing: 8) {
                Button { Task { await storage.selectSaveDirectory() } } label: {
                    Label(storage.defaultSaveDirectory.lastPathComponent, systemImage: "folder")
                        .lineLimit(1)
                }
                .buttonStyle(.borderless)
                .help(storage.defaultSaveDirectory.path)
                Spacer(minLength: 8)
                Menu {
                    Picker("Image quality".localized, selection: $shortcuts.captureQuality) {
                        Text("Standard · 1×").tag(CaptureQuality.low)
                        Text("Retina · 2×").tag(CaptureQuality.high)
                    }
                } label: {
                    Text(shortcuts.captureQuality == .high ? "Retina · 2×" : "Standard · 1×")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Image quality".localized)
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .frame(height: 34)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .background(CompactWindowSizing())
        .navigationTitle("GlassCap")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                CaptureControlsRow()
                SettingsLink {
                    Label("Settings".localized, systemImage: "gearshape")
                }
                .help("Settings".localized)
            }
        }
    }
}

struct CaptureControlsRow: View {
    @ObservedObject private var overlay = OverlayManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        Button { overlay.showScreenshotOverlay() } label: {
            Label("Screenshot".localized, systemImage: "viewfinder")
        }
        .labelStyle(.titleAndIcon)
        .help("Screenshot".localized + " (⌘⇧2)")
        .disabled(overlay.isBusy)

        Menu {
            Button("Any display".localized) { overlay.showScreenshotOverlay() }
            Divider()
            ForEach(NSScreen.screens, id: \.displayIdentifier) { screen in
                Button(screen.localizedName) { overlay.showScreenshotOverlay(on: screen) }
            }
        } label: {
            Label("Choose a display".localized, systemImage: "display")
        }
        .help("Choose a display".localized)
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
                .keyboardShortcut("2", modifiers: [.command, .shift])
                .disabled(overlay.isBusy)
            Button(overlay.isRecording ? "Stop Recording".localized : "Record".localized) {
                if overlay.isRecording { Task { await overlay.stopRecording() } }
                else { overlay.showSelectionOverlay() }
            }
            .keyboardShortcut("1", modifiers: [.command, .shift])
            .disabled(overlay.isBusy && !overlay.isRecording)
        }
    }
}
