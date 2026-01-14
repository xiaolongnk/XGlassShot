import SwiftUI
import Combine
import AppKit

@MainActor
class SelectionOverlay: ObservableObject {
    var onConfirm: (@MainActor (CGRect, NSScreen) async -> Void)?
    var onCancel: (@MainActor () async -> Void)?

    @Published var selectionRect: CGRect = .zero
    @Published var isActive: Bool = false

    private var windows: [NSWindow] = []
    private(set) var currentScreen: NSScreen?

    func show() {
        guard !isActive else { return }
        isActive = true

        // Create overlay windows on ALL screens
        for screen in NSScreen.screens {
            let overlayWindow = SelectionWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            overlayWindow.level = .screenSaver
            overlayWindow.backgroundColor = .clear
            overlayWindow.isOpaque = false
            overlayWindow.ignoresMouseEvents = false
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let hostingView = NSHostingView(rootView: SelectionOverlayView(overlay: self, screen: screen))
            hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
            overlayWindow.contentView = hostingView

            overlayWindow.makeKeyAndOrderFront(nil)
            windows.append(overlayWindow)
        }
    }

    func hide() {
        // Clear content views first to prevent SwiftUI from accessing overlay during deallocation
        for window in windows {
            window.contentView = nil
            window.orderOut(nil)
        }
        windows.removeAll()
        isActive = false
        selectionRect = .zero
        currentScreen = nil
    }

    func setCurrentScreen(_ screen: NSScreen) {
        currentScreen = screen
    }
}

struct SelectionOverlayView: View {
    @ObservedObject var overlay: SelectionOverlay
    let screen: NSScreen

    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var isThisScreenActive: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                if isThisScreenActive && (isDragging || overlay.selectionRect != .zero) {
                    // Selection rectangle with viewfinder style
                    ViewfinderRect(rect: overlay.selectionRect)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            startPoint = value.startLocation
                            isDragging = true
                            isThisScreenActive = true
                            overlay.setCurrentScreen(screen)
                        }
                        currentPoint = value.location
                        updateSelectionRect()
                    }
                    .onEnded { _ in
                        isDragging = false
                        guard isThisScreenActive else { return }

                        // Capture rect and screen before async call since hide() will reset them
                        let capturedRect = overlay.selectionRect
                        if capturedRect.width > 10 && capturedRect.height > 10 {
                            Task { @MainActor in
                                await overlay.onConfirm?(capturedRect, screen)
                            }
                        } else {
                            Task { @MainActor in
                                await overlay.onCancel?()
                            }
                        }
                    }
            )
            .onKeyPress(.escape) {
                Task { @MainActor in
                    await overlay.onCancel?()
                }
                return .handled
            }
        }
    }

    private func updateSelectionRect() {
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let maxX = max(startPoint.x, currentPoint.x)
        let maxY = max(startPoint.y, currentPoint.y)

        overlay.selectionRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
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

class SelectionWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}
