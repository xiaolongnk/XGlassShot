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
        VStack(spacing: 14) {
            // Preview card
            Button(action: { storageManager.revealLastCapture() }) {
                ZStack {
                    // Card surface — frosted material base
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1)
                        )
                    // Two-layer shadow applied via modifiers below

                    if let thumbnail = storageManager.lastCaptureThumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .padding(8)
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.97))
                            )
                    } else {
                        // Empty state — centered icon + tagline
                        VStack(spacing: 14) {
                            ZStack {
                                // Subtle gradient halo behind icon only
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.accentColor.opacity(0.12), .clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 56
                                        )
                                    )
                                    .frame(width: 96, height: 96)

                                Image(systemName: "camera.macro")
                                    .font(.system(size: 38, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color.accentColor.opacity(0.75),
                                                Color.accentColor.opacity(0.45)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 4) {
                                Text("ready_to_capture".localized)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary(for: colorScheme))

                                Text("⌘⇧1  ·  ⌘⇧2")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.textCaption(for: colorScheme))
                            }
                        }
                    }

                    // Hover overlay — reveal-in-Finder hint
                    if isHovered && storageManager.lastCaptureThumbnail != nil {
                        ZStack {
                            Color.black.opacity(0.28)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                            HStack(spacing: 7) {
                                Image(systemName: "folder.fill")
                                Text("reveal_file".localized)
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                            )
                            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                // Two-layer shadow: tight depth + large diffuse
                .shadow(
                    color: Theme.cardShadowDepth(for: colorScheme),
                    radius: 6, x: 0, y: 3
                )
                .shadow(
                    color: Theme.cardShadowElevation(for: colorScheme),
                    radius: 24, x: 0, y: 12
                )
                .scaleEffect(isHovered ? 1.01 : 1.0)
                .animation(Theme.springStandard, value: isHovered)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovered = $0 }
            .help("Click to reveal file in Finder")

            // Action buttons — only shown when there's a capture
            if storageManager.lastCaptureURL != nil {
                HStack(spacing: 8) {
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
                        color: .accentColor,
                        disabled: false
                    ) {
                        showBeautifulExport = true
                    }
                }
                .transition(
                    .opacity.combined(with: .move(edge: .bottom))
                )
                .animation(Theme.springStandard, value: storageManager.lastCaptureURL != nil)
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

    @ViewBuilder
    private var aiPopoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI Description")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                if let text = aiDescription {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                        showAIPopover = false
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.accentColor)
                }
            }
            if let error = aiError {
                Text(error)
                    .font(Theme.fontSecondary)
                    .foregroundColor(.red)
            } else if let description = aiDescription {
                Text(description)
                    .font(Theme.fontSecondary)
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
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(disabled ? .secondary : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(disabled ? 0.05 : 0.10))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(disabled ? 0.08 : 0.22), lineWidth: 1)
            )
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
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    // Store in clipboard register so the menu bar can show it
                    ClipboardRegisterManager.shared.setOCRText(text, forURL: url)
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
