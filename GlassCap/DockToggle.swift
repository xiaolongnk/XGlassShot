import SwiftUI

struct DockToggle: View {
    @Binding var isOn: Bool
    let icon: String
    let activeColor: Color
    let tooltip: String
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var showStatusTooltip = false
    @State private var tooltipTimer: Timer?

    var body: some View {
        Button(action: {
            isOn.toggle()
            triggerTooltip()
        }) {
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
        .frame(width: 36, height: 36)
        .overlay(alignment: .bottom) {
            Color.clear
                .frame(width: 36, height: 36)
                .overlay(alignment: .bottom) {
                    if showStatusTooltip {
                        Text("\(tooltip): \(isOn ? "enabled".localized : "disabled".localized)")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Theme.cardMaterial(for: colorScheme))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1)
                            )
                            .fixedSize(horizontal: true, vertical: true)
                            .offset(y: -45)
                    }
                }
        }
        .onHover { isHovered = $0 }
        .help(tooltip)
    }

    private func triggerTooltip() {
        showStatusTooltip = false
        tooltipTimer?.invalidate()
        showStatusTooltip = true
        tooltipTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            showStatusTooltip = false
        }
    }
}
