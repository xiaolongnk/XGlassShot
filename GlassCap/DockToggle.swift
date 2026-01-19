import SwiftUI

struct DockToggle: View {
    @Binding var isOn: Bool
    let icon: String
    let activeColor: Color
    let tooltip: String
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isOn ? activeColor : Theme.textSecondary(for: colorScheme).opacity(0.5))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isOn ? activeColor.opacity(0.1) : .clear)
                )
                .overlay(
                    Circle()
                        .stroke(Theme.cardBorder(for: colorScheme), lineWidth: isHovered ? 1 : 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
        .help(tooltip)
    }
}
