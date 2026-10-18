import SwiftUI
import AppKit

/// Wallpaper is behind a frosted tint; content never inherits background opacity.
struct GlassSurface: View {
    @ObservedObject private var appearance = AppAppearance.shared
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !reduceTransparency {
                    if let image = appearance.backgroundImage {
                        Image(nsImage: image)
                            .resizable().scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .blur(radius: 8, opaque: true)
                    } else { DesktopMaterial() }
                }
                (scheme == .dark ? Color(red: 0.08, green: 0.09, blue: 0.12) : Color(red: 0.97, green: 0.98, blue: 1))
                    .opacity(reduceTransparency ? 1 : 1 - appearance.transparency)
                if !reduceTransparency {
                    LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.06 : 0.22), .clear, .black.opacity(0.04)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct DesktopMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

struct CaptureActionStyle: ViewModifier {
    var prominent = false
    @ViewBuilder func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            if prominent { content.buttonStyle(.glassProminent) }
            else { content.buttonStyle(.glass) }
        } else {
            if prominent { content.buttonStyle(.borderedProminent) }
            else { content.buttonStyle(.bordered) }
        }
    }
}
