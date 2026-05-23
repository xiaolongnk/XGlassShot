import SwiftUI
import AppKit

@available(macOS 12.3, *)
struct CapturePreviewView: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject private var overlayManager = OverlayManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    // Action states
    @State private var isExtracting = false
    @State private var extractedText: String?
    @State private var isDescribing = false
    @State private var aiDescription: String?
    @State private var aiError: String?
    @State private var showBeautifulExport = false
    @State private var showOCRPopover = false
    @State private var showAIPopover = false

    var body: some View {
        VStack(spacing: 12) {
            // Preview card
            Button(action: { storageManager.revealLastCapture() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Theme.cardFill(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1)
                        )
                        .shadow(
                            color: Theme.cardShadow(for: colorScheme),
                            radius: Theme.cardShadowRadius(for: colorScheme),
                            x: 0, y: 15
                        )

                    if let thumbnail = storageManager.lastCaptureThumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .padding(8)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(RadialGradient(colors: [Color.cyan.opacity(0.1), .clear],
                                                        center: .center, startRadius: 0, endRadius: 80))
                                    .frame(width: 140, height: 140)
                                Image(systemName: "camera.macro")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(LinearGradient(
                                        colors: [.cyan.opacity(0.8), .purple.opacity(0.8)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .shadow(color: .cyan.opacity(0.3), radius: 10)
                            }
                            Text("ready_to_capture".localized)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.textSecondary(for: colorScheme))
                                .tracking(1)
                        }
                    }

                    if isHovered && storageManager.lastCaptureThumbnail != nil {
                        ZStack {
                            Color.black.opacity(0.3)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                Text("reveal_file".localized)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Capsule().fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.2), radius: 5, y: 2))
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                        }
                    }
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .scaleEffect(isHovered ? 1.01 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHovered)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovered = $0 }
            .help("Click to reveal file in Finder")

            // Action buttons — only shown when there's a capture
            if storageManager.lastCaptureURL != nil {
                HStack(spacing: 10) {
                    // OCR button
                    captureActionButton(
                        icon: isExtracting ? "hourglass" : "text.viewfinder",
                        label: isExtracting ? "Extracting…" : "Copy Text",
                        color: .purple,
                        disabled: isExtracting
                    ) {
                        runOCR()
                    }
                    .popover(isPresented: $showOCRPopover, arrowEdge: .top) {
                        ocrPopoverContent
                    }

                    // AI describe button
                    captureActionButton(
                        icon: isDescribing ? "hourglass" : "sparkles",
                        label: isDescribing ? "Asking…" : "Describe",
                        color: .yellow,
                        disabled: isDescribing
                    ) {
                        runAIDescribe()
                    }
                    .popover(isPresented: $showAIPopover, arrowEdge: .top) {
                        aiPopoverContent
                    }

                    // Beautiful export button
                    captureActionButton(
                        icon: "paintbrush.pointed.fill",
                        label: "Beautify",
                        color: .cyan,
                        disabled: false
                    ) {
                        showBeautifulExport = true
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .sheet(isPresented: $showBeautifulExport) {
                    if let url = storageManager.lastCaptureURL,
                       let image = NSImage(contentsOf: url) {
                        BeautifulExportView(sourceImage: image)
                    }
                }
            }
        }
        .onChange(of: overlayManager.pendingPostAction) { _, action in
            guard action != .none else { return }
            overlayManager.pendingPostAction = .none
            switch action {
            case .copyText: runOCR()
            case .describe: runAIDescribe()
            case .beautify: showBeautifulExport = true
            case .none: break
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var ocrPopoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Extracted Text")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if let text = extractedText, !text.isEmpty {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                        showOCRPopover = false
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.cyan)
                }
            }
            if let text = extractedText {
                if text.isEmpty {
                    Text("No text found in this image.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        Text(text)
                            .font(.system(size: 12, design: .monospaced))
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

    @ViewBuilder
    private var aiPopoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI Description")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if let text = aiDescription {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                        showAIPopover = false
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.cyan)
                }
            }
            if let error = aiError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            } else if let description = aiDescription {
                Text(description)
                    .font(.system(size: 12))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    @ViewBuilder
    private func captureActionButton(
        icon: String,
        label: String,
        color: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(disabled ? .secondary : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color.opacity(disabled ? 0.05 : 0.12))
            )
            .overlay(Capsule().stroke(color.opacity(disabled ? 0.1 : 0.25), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
    }

    // MARK: - Actions

    private func runOCR() {
        guard let url = storageManager.lastCaptureURL else { return }
        isExtracting = true
        extractedText = nil
        showOCRPopover = false
        Task {
            do {
                let text = try await OCRManager.shared.extractText(from: url)
                extractedText = text
                if !text.isEmpty {
                    // Auto-copy to clipboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
            } catch {
                extractedText = ""
            }
            isExtracting = false
            showOCRPopover = true
        }
    }

    private func runAIDescribe() {
        guard let url = storageManager.lastCaptureURL else { return }
        guard AIManager.shared.hasAPIKey else {
            aiError = "No API key set. Open AI settings (⚙) to add your Anthropic key."
            aiDescription = nil
            showAIPopover = true
            return
        }
        isDescribing = true
        aiDescription = nil
        aiError = nil
        showAIPopover = false
        Task {
            do {
                let description = try await AIManager.shared.describeImage(at: url)
                aiDescription = description
            } catch {
                aiError = error.localizedDescription
            }
            isDescribing = false
            showAIPopover = true
        }
    }
}
