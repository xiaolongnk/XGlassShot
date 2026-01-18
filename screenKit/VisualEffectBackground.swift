import SwiftUI

struct VisualEffectBackground: NSViewRepresentable {
    var colorScheme: ColorScheme

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = Theme.visualEffectMaterial(for: colorScheme)
        view.blendingMode = Theme.visualEffectBlending(for: colorScheme)
        view.state = .active
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(white: colorScheme == .dark ? 0.1 : 0.9, alpha: Theme.visualEffectOpacity(for: colorScheme)).cgColor
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = Theme.visualEffectMaterial(for: colorScheme)
        nsView.layer?.backgroundColor = NSColor(white: colorScheme == .dark ? 0.1 : 0.9, alpha: Theme.visualEffectOpacity(for: colorScheme)).cgColor
    }
}
