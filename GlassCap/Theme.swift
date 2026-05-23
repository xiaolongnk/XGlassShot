import SwiftUI

struct Theme {
    // MARK: - Core Colors
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(hex: "F5F5F7")
    }

    // MARK: - Gradients
    static func ambientGradientTop(for scheme: ColorScheme) -> RadialGradient {
        let colors = scheme == .dark
            ? [Color.blue.opacity(0.10), Color.clear]
            : [Color.orange.opacity(0.12), Color.clear]

        return RadialGradient(
            colors: colors,
            center: .topLeading,
            startRadius: 0,
            endRadius: 1000
        )
    }

    static func ambientGradientBottom(for scheme: ColorScheme) -> RadialGradient {
        let colors = scheme == .dark
            ? [Color.purple.opacity(0.08), Color.clear]
            : [Color.blue.opacity(0.08), Color.clear]

        return RadialGradient(
            colors: colors,
            center: .bottomTrailing,
            startRadius: 0,
            endRadius: 800
        )
    }

    // MARK: - Cards & Surfaces

    // Flat fill used as a fallback or when .ultraThinMaterial is unavailable
    static func cardFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.05)
            : Color.white.opacity(0.88)
    }

    // Two-layer shadow: tight depth shadow + large diffuse elevation shadow
    static func cardShadowDepth(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.45)
            : Color.black.opacity(0.10)
    }

    static func cardShadowElevation(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.20)
            : Color.black.opacity(0.06)
    }

    static func cardMaterial(for scheme: ColorScheme) -> Material {
        .ultraThinMaterial
    }

    static func cardBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.10)
            : Color.black.opacity(0.07)
    }

    // Legacy single-shadow helpers kept for call sites not yet updated
    static func cardShadow(for scheme: ColorScheme) -> Color {
        cardShadowDepth(for: scheme)
    }

    static func cardShadowRadius(for scheme: ColorScheme) -> CGFloat {
        scheme == .dark ? 8 : 12
    }

    // MARK: - Typography hierarchy

    /// Primary label — 17pt semibold rounded (titles, action labels)
    static let fontPrimary = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Secondary label — 13pt regular rounded (subtitles, descriptions)
    static let fontSecondary = Font.system(size: 13, weight: .regular, design: .rounded)

    /// Caption — 11pt regular rounded (hints, shortcuts)
    static let fontCaption = Font.system(size: 11, weight: .regular, design: .rounded)

    /// Monospaced for technical output only
    static let fontMono = Font.system(size: 12, design: .monospaced)

    // MARK: - Text
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(hex: "1D1D1F")
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.50) : Color(hex: "86868B")
    }

    static func textCaption(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.35) : Color(hex: "AEAEB2")
    }

    // MARK: - Interactive Elements
    static func buttonGlow(for scheme: ColorScheme, color: Color) -> Color {
        scheme == .dark
            ? color.opacity(0.5)
            : color.opacity(0.25)
    }

    static func dockBackground(for scheme: ColorScheme) -> Material {
        .ultraThinMaterial
    }

    static func divider(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.09) : .black.opacity(0.05)
    }

    // MARK: - Animation presets

    /// Standard spring for UI state transitions
    static let springStandard = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Snappy spring for hover/press feedback
    static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.70)

    // MARK: - Visual Effect View
    static func visualEffectBlending(for scheme: ColorScheme) -> NSVisualEffectView.BlendingMode {
        .withinWindow
    }

    static func visualEffectMaterial(for scheme: ColorScheme) -> NSVisualEffectView.Material {
        scheme == .dark ? .sidebar : .headerView
    }

    static func visualEffectOpacity(for scheme: ColorScheme) -> CGFloat {
        scheme == .dark ? 0.95 : 0.80
    }
}
