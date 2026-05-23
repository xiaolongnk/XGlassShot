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
                    .font(Theme.fontPrimary)
                    .foregroundColor(Theme.textPrimary(for: colorScheme))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textSecondary(for: colorScheme).opacity(0.45))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider().opacity(0.25)

            ScrollView {
                VStack(spacing: 28) {
                    // Live Preview
                    if let result = composited {
                        Image(nsImage: result)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(
                                color: Theme.cardShadowDepth(for: colorScheme),
                                radius: 6, x: 0, y: 3
                            )
                            .shadow(
                                color: Theme.cardShadowElevation(for: colorScheme),
                                radius: 20, x: 0, y: 10
                            )
                            .animation(Theme.springStandard, value: options.padding)
                            .animation(Theme.springStandard, value: options.cornerRadius)
                    }

                    // Background presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Background")
                            .font(Theme.fontCaption)
                            .foregroundColor(Theme.textSecondary(for: colorScheme))
                            .textCase(.uppercase)
                            .tracking(0.5)

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
                                .font(Theme.fontCaption)
                                .foregroundColor(Theme.textSecondary(for: colorScheme))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Spacer()
                            Text("\(Int(options.padding))px")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textCaption(for: colorScheme))
                        }
                        Slider(value: $options.padding, in: 0...96, step: 8)
                            .tint(.accentColor)
                    }

                    // Corner radius slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Corner Radius")
                                .font(Theme.fontCaption)
                                .foregroundColor(Theme.textSecondary(for: colorScheme))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Spacer()
                            Text("\(Int(options.cornerRadius))px")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textCaption(for: colorScheme))
                        }
                        Slider(value: $options.cornerRadius, in: 0...32, step: 4)
                            .tint(.accentColor)
                    }
                }
                .padding(24)
            }

            Divider().opacity(0.25)

            // Copy button
            Button(action: copyToClipboard) {
                Label(
                    copied ? "Copied!" : "Copy to Clipboard",
                    systemImage: copied ? "checkmark.circle.fill" : "doc.on.clipboard"
                )
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(copied ? Color.green : Color.accentColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .animation(Theme.springStandard, value: copied)
            .padding(24)
            .padding(.top, 0)
        }
        .frame(width: 500)
        .background(Theme.cardFill(for: colorScheme))
    }

    @ViewBuilder
    private func gradientSwatch(_ preset: BeautifulExportCompositor.Options.GradientPreset) -> some View {
        let colors = preset.colors.map { Color(nsColor: $0) }
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        selectedPreset == preset ? Color.white.opacity(0.9) : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
            .scaleEffect(selectedPreset == preset ? 1.06 : 1.0)
            .animation(Theme.springSnappy, value: selectedPreset == preset)
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
        withAnimation(Theme.springStandard) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(Theme.springStandard) { copied = false }
        }
    }
}
