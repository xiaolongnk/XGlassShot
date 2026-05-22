import SwiftUI
import AppKit

@available(macOS 12.3, *)
struct BeautifulExportView: View {
    let sourceImage: NSImage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var options = BeautifulExportCompositor.Options()
    @State private var selectedPreset: BeautifulExportCompositor.Options.GradientPreset = .mesh1
    @State private var copied = false

    private var composited: NSImage? {
        BeautifulExportCompositor.compose(image: sourceImage, options: options)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Beautiful Export")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary(for: colorScheme))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textSecondary(for: colorScheme).opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 24) {
                    // Live Preview
                    if let result = composited {
                        Image(nsImage: result)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }

                    // Background presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Background")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary(for: colorScheme))

                        HStack(spacing: 10) {
                            ForEach(BeautifulExportCompositor.Options.GradientPreset.allCases) { preset in
                                gradientSwatch(preset)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Padding slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Padding")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textSecondary(for: colorScheme))
                            Spacer()
                            Text("\(Int(options.padding))px")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Theme.textSecondary(for: colorScheme))
                        }
                        Slider(value: $options.padding, in: 0...96, step: 8)
                            .tint(.cyan)
                    }

                    // Corner radius slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Corner Radius")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textSecondary(for: colorScheme))
                            Spacer()
                            Text("\(Int(options.cornerRadius))px")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Theme.textSecondary(for: colorScheme))
                        }
                        Slider(value: $options.cornerRadius, in: 0...32, step: 4)
                            .tint(.cyan)
                    }
                }
                .padding(24)
            }

            Divider().opacity(0.3)

            // Copy button
            Button(action: copyToClipboard) {
                Label(copied ? "Copied!" : "Copy to Clipboard",
                      systemImage: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(copied ? Color.green : Color.cyan)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(24)
            .padding(.top, 0)
        }
        .frame(width: 500)
        .background(Theme.cardFill(for: colorScheme))
    }

    @ViewBuilder
    private func gradientSwatch(_ preset: BeautifulExportCompositor.Options.GradientPreset) -> some View {
        let colors = preset.colors.map { Color(nsColor: $0) }
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedPreset == preset ? Color.white : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
            .onTapGesture {
                selectedPreset = preset
                options.backgroundStyle = .gradient(preset)
            }
    }

    private func copyToClipboard() {
        guard let result = composited else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([result])
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}
