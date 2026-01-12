import SwiftUI
import Combine
import AppKit

@MainActor
class SelectionOverlay: ObservableObject {
    var onConfirm: (@MainActor (CGRect) async -> Void)?
    var onCancel: (@MainActor () async -> Void)?
    
    @Published var selectionRect: CGRect = .zero
    @Published var isActive: Bool = false
    
    private var window: NSWindow?
    
    func show() {
        guard !isActive else { return }
        isActive = true
        
        let screenFrame = NSScreen.main?.frame ?? .zero
        let overlayWindow = SelectionWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow.level = .screenSaver
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: SelectionOverlayView(overlay: self))
        hostingView.frame = screenFrame
        overlayWindow.contentView = hostingView
        
        overlayWindow.makeKeyAndOrderFront(nil)
        window = overlayWindow
    }
    
    func hide() {
        // Clear content view first to prevent SwiftUI from accessing overlay during deallocation
        window?.contentView = nil
        window?.orderOut(nil)
        window = nil
        isActive = false
        selectionRect = .zero
    }
}

struct SelectionOverlayView: View {
    @ObservedObject var overlay: SelectionOverlay
    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                if isDragging || overlay.selectionRect != .zero {
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
                        }
                        currentPoint = value.location
                        updateSelectionRect()
                    }
                    .onEnded { _ in
                        isDragging = false
                        // Capture rect before async call since hide() will reset it
                        let capturedRect = overlay.selectionRect
                        if capturedRect.width > 10 && capturedRect.height > 10 {
                            Task { @MainActor in
                                await overlay.onConfirm?(capturedRect)
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
    
    var body: some View {
        GlassView(material: .hudWindow, blendingMode: .withinWindow) {
            Text("\(width) × \(height)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

class SelectionWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}
