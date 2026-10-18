import SwiftUI
import AppKit

/// A real desktop-sampling material, with a readable tint above it.
struct GlassSurface: View {
    @ObservedObject private var appearance = AppAppearance.shared
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        ZStack {
            if !reduceTransparency { DesktopMaterial() }
            (scheme == .dark ? Color(red: 0.10, green: 0.11, blue: 0.13) : Color(red: 0.97, green: 0.98, blue: 1))
                .opacity(reduceTransparency ? 1 : 1 - appearance.transparency)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
