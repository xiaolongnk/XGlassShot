import SwiftUI
import AppKit

struct AnnotationRect: View {
    let rect: CGRect
    let selectionRect: CGRect

    var body: some View {
        Rectangle()
            .stroke(Color.red, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            // Position is relative to the selectionRect top-left
            .position(
                x: selectionRect.minX + rect.midX,
                y: selectionRect.minY + rect.midY
            )
            .shadow(color: .black.opacity(0.3), radius: 1)
    }
}

struct ViewfinderRect: View {
    let rect: CGRect
    private let cornerLength: CGFloat = 20
    private let cornerThickness: CGFloat = 3
    private let borderThickness: CGFloat = 1

    var body: some View {
        ZStack {
            // Main border
            Rectangle()
                .stroke(Color.white, lineWidth: borderThickness)
                .frame(width: rect.width, height: rect.height)
                .position(
                    x: rect.midX,
                    y: rect.midY
                )
                .shadow(color: .cyan, radius: 5)

            // Corner brackets
            Group {
                // Top-left
                CornerBracket(
                    position: CGPoint(x: rect.minX, y: rect.minY),
                    corner: .topLeft,
                    length: cornerLength,
                    thickness: cornerThickness
                )

                // Top-right
                CornerBracket(
                    position: CGPoint(x: rect.maxX, y: rect.minY),
                    corner: .topRight,
                    length: cornerLength,
                    thickness: cornerThickness
                )

                // Bottom-left
                CornerBracket(
                    position: CGPoint(x: rect.minX, y: rect.maxY),
                    corner: .bottomLeft,
                    length: cornerLength,
                    thickness: cornerThickness
                )

                // Bottom-right
                CornerBracket(
                    position: CGPoint(x: rect.maxX, y: rect.maxY),
                    corner: .bottomRight,
                    length: cornerLength,
                    thickness: cornerThickness
                )
            }
            .shadow(color: .cyan, radius: 5)

            // Dimension badge
            if rect.width > 0 && rect.height > 0 {
                DimensionBadge(width: Int(rect.width), height: Int(rect.height))
                    .position(
                        x: rect.midX,
                        y: rect.maxY - 30
                    )
            }
        }
    }
}

struct CornerBracket: View {
    let position: CGPoint
    let corner: CornerType
    let length: CGFloat
    let thickness: CGFloat

    enum CornerType {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        Path { path in
            switch corner {
            case .topLeft:
                // Horizontal line (left to right)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x + length, y: position.y))
                // Vertical line (top to bottom)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y + length))

            case .topRight:
                // Horizontal line (right to left)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x - length, y: position.y))
                // Vertical line (top to bottom)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y + length))

            case .bottomLeft:
                // Horizontal line (left to right)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x + length, y: position.y))
                // Vertical line (bottom to top)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y - length))

            case .bottomRight:
                // Horizontal line (right to left)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x - length, y: position.y))
                // Vertical line (bottom to top)
                path.move(to: CGPoint(x: position.x, y: position.y))
                path.addLine(to: CGPoint(x: position.x, y: position.y - length))
            }
        }
        .stroke(Color.white, lineWidth: thickness)
    }
}

struct DimensionBadge: View {
    let width: Int
    let height: Int
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @available(macOS 12.3, *)
    var body: some View {
        let quality = ShortcutsManager.shared.captureQuality

        HStack(spacing: 8) {
            Text("\(width) × \(height)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white)

            // Quality indicator
            HStack(spacing: 3) {
                Image(systemName: quality == .high ? "sparkles" : "hare")
                    .font(.system(size: 9, weight: .semibold))
                Text(quality.displayName)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
            }
            .foregroundColor(quality == .high ? .yellow : .cyan)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(quality == .high ? Color.yellow.opacity(0.2) : Color.cyan.opacity(0.2))
            )


            // Hint
            Text("enter_to_capture".localized)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .padding(.leading, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(GlassView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(quality == .high ? Color.yellow.opacity(0.3) : Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

class SelectionWindow: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.becomesKeyOnlyIfNeeded = false
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

struct MouseTrackingViewWrapper: NSViewRepresentable {
    var onMoved: (CGPoint) -> Void

    func makeNSView(context: Context) -> MouseTrackingNSView {
        let view = MouseTrackingNSView()
        view.onMoved = onMoved
        return view
    }

    func updateNSView(_ nsView: MouseTrackingNSView, context: Context) {
        nsView.onMoved = onMoved
    }
}

class MouseTrackingNSView: NSView {
    var onMoved: ((CGPoint) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }

        // Track mouse moves even when not active application if possible, or at least when key
        let options: NSTrackingArea.Options = [.mouseMoved, .activeAlways, .inVisibleRect]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        onMoved?(point)
    }
}
