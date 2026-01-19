import SwiftUI

struct Theme {
    // MARK: - Core Colors
    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(hex: "F5F5F7") // "Deep Space" vs "Digital Porcelain"
    }

    // MARK: - Gradients
    static func ambientGradientTop(for scheme: ColorScheme) -> RadialGradient {
        let colors = scheme == .dark 
            ? [Color.blue.opacity(0.12), Color.clear] 
            : [Color.orange.opacity(0.15), Color.clear] // "Deep Glow" vs "Morning Sun"
        
        return RadialGradient(
            colors: colors,
            center: .topLeading,
            startRadius: 0,
            endRadius: 1000
        )
    }
    
    static func ambientGradientBottom(for scheme: ColorScheme) -> RadialGradient {
        let colors = scheme == .dark 
            ? [Color.purple.opacity(0.1), Color.clear] 
            : [Color.blue.opacity(0.1), Color.clear] // "Cyber" vs "Sky"
        
        return RadialGradient(
            colors: colors,
            center: .bottomTrailing,
            startRadius: 0,
            endRadius: 800
        )
    }

    // MARK: - Cards & Surfaces
    static func cardFill(for scheme: ColorScheme) -> Color {
        scheme == .dark 
            ? Color.white.opacity(0.04) 
            : Color.white.opacity(0.85)
    }
    
    static func cardMaterial(for scheme: ColorScheme) -> Material {
        scheme == .dark ? .ultraThin : .regular
    }
    
    static func cardBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark 
            ? Color.white.opacity(0.1) 
            : Color.black.opacity(0.08)
    }
    
    static func cardShadow(for scheme: ColorScheme) -> Color {
        scheme == .dark 
            ? Color.black.opacity(0.3) 
            : Color.black.opacity(0.12)
    }
    
    static func cardShadowRadius(for scheme: ColorScheme) -> CGFloat {
        scheme == .dark ? 10 : 15 // Softer, more spread out in light mode
    }

    // MARK: - Text
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(hex: "1D1D1F") // Pure White vs Apple Slate
    }
    
    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.5) : Color(hex: "86868B")
    }
    
    // MARK: - Interactive Elements
    static func buttonGlow(for scheme: ColorScheme, color: Color) -> Color {
        scheme == .dark 
            ? color.opacity(0.6) 
            : color.opacity(0.3)
    }
    
    static func dockBackground(for scheme: ColorScheme) -> Material {
        scheme == .dark ? .ultraThin : .bar
    }
    
    static func divider(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.1) : .black.opacity(0.05)
    }
    
    // MARK: - Visual Effect View
    static func visualEffectBlending(for scheme: ColorScheme) -> NSVisualEffectView.BlendingMode {
        .withinWindow // Always within window for consistency
    }
    
    static func visualEffectMaterial(for scheme: ColorScheme) -> NSVisualEffectView.Material {
        scheme == .dark ? .sidebar : .headerView
    }
    
    static func visualEffectOpacity(for scheme: ColorScheme) -> CGFloat {
        scheme == .dark ? 0.95 : 0.8 // More translucent in light mode
    }
}
