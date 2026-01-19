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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [color.opacity(0.6), color.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : color)
                        .shadow(color: color.opacity(0.6), radius: 4)
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary(for: colorScheme))
                    
                    Text(shortcut)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(colorScheme == .light ? Color.black.opacity(0.75) : Theme.textSecondary(for: colorScheme).opacity(0.9))
                }
                
                Spacer()
                
                // Chevron hint
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textSecondary(for: colorScheme).opacity(isHovered ? 0.8 : 0.3))
                    .offset(x: isHovered ? 4 : 0)
            }
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.cardFill(for: colorScheme))
            )
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(colorScheme == .dark ? .white.opacity(isHovered ? 0.08 : 0.03) : .black.opacity(isHovered ? 0.05 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: Theme.cardShadow(for: colorScheme), radius: 10, y: 5)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
        .help(description)
    }
}
