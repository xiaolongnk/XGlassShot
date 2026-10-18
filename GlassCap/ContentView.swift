import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var shortcuts = ShortcutsManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("GlassCap")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Settings".localized)
                .accessibilityLabel("Settings".localized)
            }

            CapturePreviewView(storageManager: storage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

            CaptureControlsRow()

            HStack(spacing: 8) {
                Button { Task { await storage.selectSaveDirectory() } } label: {
                    Label(storage.defaultSaveDirectory.lastPathComponent, systemImage: "folder")
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .help(storage.defaultSaveDirectory.path)
                Spacer(minLength: 8)
                Text(shortcuts.captureQuality == .high ? "Retina · 2×" : "Standard · 1×")
                Text("·")
                Text("v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                    .help("Build " + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") + " · " + (Bundle.main.infoDictionary?["GlassCapSourceRevision"] as? String ?? ""))
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .frame(height: 18)
        }
        .padding(14)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(CompactWindowSizing())
        .sheet(isPresented: $showSettings) {
            SettingsDock(storageManager: storage, shortcutsManager: shortcuts)
        }
    }
}

struct CaptureControlsRow: View {
    @ObservedObject private var overlay = OverlayManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                Button { overlay.showScreenshotOverlay() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "viewfinder")
                        Text("Screenshot".localized).fontWeight(.semibold)
                        Spacer(minLength: 4)
                        Text("⌘⇧2").font(.system(size: 10, design: .monospaced)).opacity(0.75)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Rectangle().fill(.white.opacity(0.25)).frame(width: 1, height: 18)
                Menu {
                    Button("Any display".localized) { overlay.showScreenshotOverlay() }
                    Divider()
                    ForEach(NSScreen.screens, id: \.displayIdentifier) { screen in
                        Button(screen.localizedName) { overlay.showScreenshotOverlay(on: screen) }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 30, height: 40)
                }
                .menuIndicator(.hidden)
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Choose a display".localized)
                .accessibilityLabel("Choose a display".localized)
            }
            .foregroundStyle(.white)
            .background(.blue, in: RoundedRectangle(cornerRadius: 9))
            .disabled(overlay.isBusy)

            Button {
                if overlay.isRecording { Task { await overlay.stopRecording() } }
                else { overlay.showSelectionOverlay() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: overlay.isRecording ? "stop.fill" : "record.circle")
                        .foregroundStyle(overlay.isRecording ? .red : .secondary)
                    Text(overlay.isRecording ? "Stop Recording".localized : "Record".localized)
                        .fontWeight(.medium)
                }
                .frame(width: 116, height: 40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color.primary.opacity(0.08)))
            .disabled(overlay.isBusy && !overlay.isRecording)
            .help("⌘⇧1")
        }
        .font(.system(size: 12))
    }
}
