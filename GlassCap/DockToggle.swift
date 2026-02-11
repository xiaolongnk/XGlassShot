import SwiftUI
import Combine

@MainActor
final class StatusTooltipState: ObservableObject {
    static let shared = StatusTooltipState()
    @Published var activeTooltipID: String?
    private var hideTimer: Timer?
    
    func showTooltip(id: String) {
        hideTimer?.invalidate()
        activeTooltipID = id
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.activeTooltipID = nil
            }
        }
        RunLoop.main.add(hideTimer!, forMode: .common)
    }
}

struct DockToggle: View {
    @Binding var isOn: Bool
    let icon: String
    let activeColor: Color
    let tooltip: String
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var tooltipState = StatusTooltipState.shared
    @State private var isHovered = false

    private var showStatusTooltip: Bool {
        tooltipState.activeTooltipID == tooltip
    }

    var body: some View {
        Button(action: {
            isOn.toggle()
            tooltipState.showTooltip(id: tooltip)
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
}
