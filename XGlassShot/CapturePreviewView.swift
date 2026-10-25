import SwiftUI
import AppKit

@available(macOS 12.3, *)
struct CapturePreviewView: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject private var overlayManager = OverlayManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var historyManager = ClipboardRegisterManager.shared

    // Action states
    @State private var isExtracting = false
    @State private var extractedText: String?
    private struct ExportRequest: Identifiable {
        let id = UUID()
        let url: URL
    }
    @State private var beautifulExport: ExportRequest?
    @State private var showOCRPopover = false

    private var displayedURL: URL? { historyManager.previewURL ?? storageManager.lastCaptureURL }
    private var previewThumbnail: NSImage? {
        historyManager.previewURL == nil ? storageManager.lastCaptureThumbnail : historyManager.previewThumbnail
    }
    private var isLoadingPreview: Bool {
        historyManager.previewURL == nil ? storageManager.isLoadingThumbnail : historyManager.isLoadingPreview
    }
    @State private var copiedImageURL: URL?
    @State private var copyFeedbackTask: Task<Void, Never>?

    private var isImage: Bool {
        guard let url = displayedURL else { return false }
        return ["png", "jpg", "jpeg"].contains(url.pathExtension.lowercased())
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.clear
                if let image = previewThumbnail {
                    GeometryReader { geometry in
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: max(0, geometry.size.width - (historyManager.history.entries.isEmpty ? 28 : 100)), height: max(0, geometry.size.height - 28))
                            .clipShape(.rect(cornerRadius: 6))
                            .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
                            .padding(.horizontal, historyManager.history.entries.isEmpty ? 14 : 50)
                            .padding(.vertical, 14)
                    }
                    .accessibilityLabel("Capture preview".localized)
                } else if isLoadingPreview {
                    ProgressView().controlSize(.small)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: displayedURL == nil ? "viewfinder" : "photo")
                            .font(.system(size: 36, weight: .ultraLight))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        VStack(spacing: 5) {
                            Text(displayedURL == nil ? "Your next great capture".localized : "Preview unavailable".localized)
                                .font(.system(size: 15, weight: .medium))
                            Text("Choose an area on any display".localized)
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        Text("⌘ ⇧ 2")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 5))
                    }
                    .padding(20)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
                }
            }
            .overlay {
                if !historyManager.history.entries.isEmpty {
                    HStack {
                        historyButton(.older, title: "Previous image".localized, symbol: "chevron.left")
                        Spacer()
                        historyButton(.newer, title: "Next image".localized, symbol: "chevron.right")
                    }
                    .padding(.horizontal, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            if let url = displayedURL {
                Divider()
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(isImage ? "Screenshot".localized : "Screen recording".localized)
                                .font(.system(size: 12, weight: .medium))
                            Text(url.lastPathComponent)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1).truncationMode(.middle)
                                .help(url.path)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if let position = historyManager.history.position(of: displayedURL) {
                            Text("\(position + 1) / \(historyManager.history.entries.count)")
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                .accessibilityLabel("Capture history".localized)
                                .accessibilityValue("\(position + 1) / \(historyManager.history.entries.count)")
                        }
                        Text(url.pathExtension.uppercased())
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        Button {
                            if isImage {
                                copyImage(at: url)
                            } else { NSWorkspace.shared.open(url) }
                        } label: {
                            Label(isImage ? (copiedImageURL == url ? "Copied!".localized : "Copy image".localized) : "Open recording".localized,
                                  systemImage: isImage ? "doc.on.doc" : "play.fill")
                        }
                        .help(isImage ? "Copy image".localized : "Open recording".localized)
                        .disabled(isImage && previewThumbnail == nil)

                        if isImage {
                            Button { runOCR() } label: {
                                Label(isExtracting ? "Extracting…".localized : "Copy Text".localized, systemImage: "text.viewfinder")
                            }
                            .disabled(isExtracting)
                            .help("Copy Text".localized)
                            .popover(isPresented: $showOCRPopover, arrowEdge: .bottom) { ocrPopoverContent }
                            Button {
                                beautifulExport = ExportRequest(url: url)
                            } label: { Label("Beautify".localized, systemImage: "paintbrush.pointed") }
                            .help("Beautify".localized)
                        }

                        Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: {
                            Label("reveal_file".localized, systemImage: "folder")
                        }
                        .labelStyle(.iconOnly)
                        .help("reveal_file".localized)
                    }
                    .font(.system(size: 11))
                    .modifier(CaptureActionStyle())
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        }
        .sheet(item: $beautifulExport) { request in
            if let image = NSImage(contentsOf: request.url) {
                BeautifulExportView(sourceImage: image)
            } else {
                VStack(spacing: 16) {
                    Text("Preview unavailable".localized)
                    Button("Done".localized) { beautifulExport = nil }
                }.padding(24)
            }
        }
        .onChange(of: overlayManager.pendingPostAction) { _, _ in consumePostAction() }
        .onChange(of: displayedURL) { _, _ in
            copyFeedbackTask?.cancel()
            copiedImageURL = nil
            showOCRPopover = false
            extractedText = nil
        }
        .onAppear { consumePostAction() }
        .onDisappear { copyFeedbackTask?.cancel() }
    }

    private func historyButton(_ direction: CaptureHistory.Direction, title: String, symbol: String) -> some View {
        Button { historyManager.browse(direction, from: displayedURL) } label: {
            Label(title, systemImage: symbol).labelStyle(.iconOnly)
                .frame(width: 28, height: 30)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .disabled(!historyManager.canBrowse(direction, from: displayedURL))
        .help(title)
    }

    private func copyImage(at url: URL) {
        guard historyManager.copyImage(at: url) else { return }
        copyFeedbackTask?.cancel()
        copiedImageURL = url
        copyFeedbackTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            copiedImageURL = nil
        }
    }

    private func consumePostAction() {
        guard let request = overlayManager.pendingPostAction else { return }
        overlayManager.pendingPostAction = nil
        switch request.action {
        case .copyText: runOCR(url: request.url)
        case .beautify:
            beautifulExport = ExportRequest(url: request.url)
        case .none: break
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var ocrPopoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Extracted Text".localized)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                if let text = extractedText, !text.isEmpty {
                    Button("Copy".localized) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                        showOCRPopover = false
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.accentColor)
                }
            }
            if let text = extractedText {
                if text.isEmpty {
                    Text("No text found in this image.".localized)
                        .font(Theme.fontSecondary)
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        Text(text)
                            .font(Theme.fontMono)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    // MARK: - Actions

    private func runOCR(url sourceURL: URL? = nil) {
        guard let url = sourceURL ?? displayedURL else { return }
        isExtracting = true
        extractedText = nil
        showOCRPopover = false
        Task {
            do {
                let text = try await OCRManager.shared.extractText(from: url)
                guard displayedURL == url else { isExtracting = false; return }
                extractedText = text
                if !text.isEmpty {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    // Store in clipboard register so the menu bar can show it
                    ClipboardRegisterManager.shared.setOCRText(text, forURL: url)
                }
            } catch {
                guard displayedURL == url else { isExtracting = false; return }
                extractedText = error.localizedDescription
            }
            isExtracting = false
            showOCRPopover = true
        }
    }

}
