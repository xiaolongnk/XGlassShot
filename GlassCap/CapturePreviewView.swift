import SwiftUI
import AppKit

@available(macOS 12.3, *)
struct CapturePreviewView: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject private var overlayManager = OverlayManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    // Action states
    @State private var isExtracting = false
    @State private var extractedText: String?
    @State private var showBeautifulExport = false
    @State private var beautifulExportURL: URL?
    @State private var showOCRPopover = false

    private var isImage: Bool {
        guard let url = storageManager.lastCaptureURL else { return false }
        return ["png", "jpg", "jpeg"].contains(url.pathExtension.lowercased())
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                if let image = storageManager.lastCaptureThumbnail {
                    GeometryReader { geometry in
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: max(0, geometry.size.width - 16), height: max(0, geometry.size.height - 16))
                            .padding(8)
                    }
                    .accessibilityLabel("Last capture preview".localized)
                } else if storageManager.isLoadingThumbnail {
                    ProgressView().controlSize(.small)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: storageManager.lastCaptureURL == nil ? "viewfinder" : "photo")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(.blue.opacity(0.8))
                        Text(storageManager.lastCaptureURL == nil ? "Ready to capture".localized : "Preview unavailable".localized)
                            .font(.system(size: 13, weight: .medium))
                        Text("Choose an area on any display".localized)
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            if let url = storageManager.lastCaptureURL {
                HStack(spacing: 8) {
                    Text(url.lastPathComponent)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 0)
                    Text(url.pathExtension.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                HStack(spacing: 14) {
                    Button {
                        if isImage, let image = NSImage(contentsOf: url) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.writeObjects([image])
                        } else { NSWorkspace.shared.open(url) }
                    } label: {
                        Label(isImage ? "Copy image".localized : "Open recording".localized, systemImage: isImage ? "doc.on.doc" : "play.rectangle")
                    }
                    if isImage {
                        Button { runOCR() } label: {
                            Label(isExtracting ? "Extracting…".localized : "Copy Text".localized, systemImage: "text.viewfinder")
                        }
                        .disabled(isExtracting)
                        .popover(isPresented: $showOCRPopover, arrowEdge: .bottom) { ocrPopoverContent }
                        Button {
                            beautifulExportURL = url
                            showBeautifulExport = true
                        } label: { Label("Beautify".localized, systemImage: "paintbrush") }
                    }
                    Spacer(minLength: 0)
                    Button { storageManager.revealLastCapture() } label: { Image(systemName: "folder") }
                        .help("reveal_file".localized)
                        .accessibilityLabel("reveal_file".localized)
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(height: 24)
            }
        }
        .sheet(isPresented: $showBeautifulExport) {
            if let url = beautifulExportURL, let image = NSImage(contentsOf: url) {
                BeautifulExportView(sourceImage: image)
            }
        }
        .onChange(of: overlayManager.pendingPostAction) { _, _ in consumePostAction() }
        .onAppear { consumePostAction() }
    }

    private func consumePostAction() {
        guard let request = overlayManager.pendingPostAction else { return }
        overlayManager.pendingPostAction = nil
        switch request.action {
        case .copyText: runOCR(url: request.url)
        case .beautify:
            beautifulExportURL = request.url
            showBeautifulExport = true
        case .none: break
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var ocrPopoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Extracted Text")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                if let text = extractedText, !text.isEmpty {
                    Button("Copy") {
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
                    Text("No text found in this image.")
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
        guard let url = sourceURL ?? storageManager.lastCaptureURL else { return }
        isExtracting = true
        extractedText = nil
        showOCRPopover = false
        Task {
            do {
                let text = try await OCRManager.shared.extractText(from: url)
                guard storageManager.lastCaptureURL == url else { isExtracting = false; return }
                extractedText = text
                if !text.isEmpty {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    // Store in clipboard register so the menu bar can show it
                    ClipboardRegisterManager.shared.setOCRText(text, forURL: url)
                }
            } catch {
                extractedText = error.localizedDescription
            }
            isExtracting = false
            showOCRPopover = true
        }
    }

}
