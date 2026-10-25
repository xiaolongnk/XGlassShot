import SwiftUI

struct SaveDestinationView: View {
    @Binding var prefix: String
    let chooseDirectory: () async -> Void
    let onDismiss: () -> Void
    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var appearance = AppAppearance.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var isChoosingDirectory = false
    @FocusState private var isPrefixFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Folder".localized, systemImage: "folder")
                Spacer()
                Button("Choose…".localized) {
                    Task {
                        isChoosingDirectory = true
                        await chooseDirectory()
                        isChoosingDirectory = false
                        isPrefixFocused = true
                    }
                }
                .disabled(isChoosingDirectory)
            }
            Text(storage.defaultSaveDirectory.path)
                .font(.caption).foregroundStyle(.secondary)
                .lineLimit(2).truncationMode(.middle)
                .frame(height: 28, alignment: .topLeading)
                .help(storage.defaultSaveDirectory.path)
            Divider()
            Text("Filename prefix".localized).fontWeight(.medium)
            TextField("Filename prefix".localized, text: $prefix)
                .textFieldStyle(.roundedBorder)
                .focused($isPrefixFocused)
                .onSubmit(onDismiss)
            Text((CaptureFileStore.sanitizedPrefix(prefix).isEmpty ? "" : CaptureFileStore.sanitizedPrefix(prefix) + "_") + "YYYYMMDD-HHmmss-SSS-id.png")
                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                .lineLimit(2).frame(height: 26, alignment: .topLeading)
            HStack {
                Text("Settings save automatically".localized)
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Done".localized, action: onDismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .font(.system(size: 12))
        .padding(16)
        .frame(width: 420)
        .background(GlassSurface())
        .preferredColorScheme(appearance.mode.colorScheme)
        .onAppear { isPrefixFocused = true }
        .onExitCommand(perform: onDismiss)
    }
}
