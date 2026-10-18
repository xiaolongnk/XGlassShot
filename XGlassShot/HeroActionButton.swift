import SwiftUI

struct HeroActionButton: View {
    let icon: String
    let label: String
    let shortcut: String
    let color: Color
    let description: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isHovered = false
    @GestureState private var isPressed = false

    var body: some View {
        Button(action: action) {
            // Outer frosted capsule wrapping the full pill
            ZStack {
                // Base material layer
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Hover tint
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        isHovered
                            ? color.opacity(colorScheme == .dark ? 0.10 : 0.06)
                            : Color.clear
                    )

                // Border
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isHovered
                            ? color.opacity(0.35)
                            : Theme.cardBorder(for: colorScheme),
                        lineWidth: 1
                    )

                // Content row
                HStack(spacing: 14) {
                    // Icon container — tinted circle badge
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(color.opacity(0.30), lineWidth: 1)
                            )

                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(color)
                    }

                    // Label stack
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(Theme.fontPrimary)
                            .foregroundColor(Theme.textPrimary(for: colorScheme))

                        Text(shortcut)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.textCaption(for: colorScheme))
                    }

                    Spacer()

                    // Chevron hint
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(
                            Theme.textSecondary(for: colorScheme)
                                .opacity(isHovered ? 0.75 : 0.25)
                        )
                        .offset(x: isHovered ? 3 : 0)
                        .animation(Theme.springSnappy, value: isHovered)
                }
                .padding(.leading, 14)
                .padding(.trailing, 18)
            }
            .frame(height: 72)
            .frame(minWidth: 140, maxWidth: .infinity)
            // Two-layer shadow: tight depth + large diffuse elevation
            .shadow(
                color: Theme.cardShadowDepth(for: colorScheme),
                radius: 4, x: 0, y: 2
            )
            .shadow(
                color: Theme.cardShadowElevation(for: colorScheme),
                radius: 16, x: 0, y: 8
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in state = true }
        )
        .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
        .animation(Theme.springStandard, value: isPressed)
        .animation(Theme.springStandard, value: isHovered)
        .onHover { isHovered = $0 }
        .help(description)
    }
}
