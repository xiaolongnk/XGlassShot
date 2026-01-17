import SwiftUI
import Combine
import AppKit

@MainActor
class SelectionOverlay: ObservableObject {
    var onConfirm: (@MainActor (CGRect, [CGRect], NSScreen) async -> Void)?
    var onCancel: (@MainActor () async -> Void)?

    @Published var selectionRect: CGRect = .zero
    @Published var isActive: Bool = false

    private var windows: [NSWindow] = []
    private(set) var currentScreen: NSScreen?
    
    // Annotations (relative to selectionRect)
    @Published var annotations: [CGRect] = []

    private var eventMonitor: Any?

    func show() {
        guard !isActive else { return }
        isActive = true
        setupInputMonitoring()

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
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func setupInputMonitoring() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyDown(event: event)
        }
    }
    
    private func handleKeyDown(event: NSEvent) -> NSEvent? {
        guard isActive else { return event }
        
        if event.keyCode == 36 { // Enter
            confirmSelection()
            return nil // Consume event
        } else if event.keyCode == 53 { // Escape
            Task { @MainActor in
                await onCancel?()
            }
            return nil // Consume event
        }
        
        return event
    }
    
    func confirmSelection() {
        guard let screen = currentScreen else { return }
        
        // Check if there is a valid selection
        if selectionRect.width > 10 && selectionRect.height > 10 {
            Task { @MainActor in
                await onConfirm?(selectionRect, annotations, screen)
            }
        }
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
    @State private var isDrawingAnnotation: Bool = false
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
                    
                    // Annotations
                    ForEach(0..<overlay.annotations.count, id: \.self) { index in
                        AnnotationRect(rect: overlay.annotations[index], selectionRect: overlay.selectionRect)
                    }
                    
                    // Current drawing annotation
                    if isDrawingAnnotation {
                        AnnotationRect(
                            rect: calculateAnnotationRect(start: startPoint, end: currentPoint),
                            selectionRect: overlay.selectionRect
                        )
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging && !isDrawingAnnotation {
                            let location = value.startLocation
                            
                            // Check if start location is substantially inside existing selection to start annotation
                            // We use a small inset to allow resizing/moving selection in future if needed (though not implemented yet)
                            if isThisScreenActive && overlay.selectionRect.insetBy(dx: 5, dy: 5).contains(location) {
                                isDrawingAnnotation = true
                                startPoint = CGPoint(
                                    x: location.x - overlay.selectionRect.minX,
                                    y: location.y - overlay.selectionRect.minY
                                )
                                currentPoint = startPoint
                            } else {
                                // Start new selection
                                isDragging = true
                                isThisScreenActive = true
                                overlay.setCurrentScreen(screen)
                                overlay.selectionRect = .zero // Reset selection
                                overlay.annotations = []      // Reset annotations
                                startPoint = location
                                currentPoint = location
                                updateSelectionRect()
                            }
                        } else if isDrawingAnnotation {
                             // Update current annotation point (relative to selection)
                             currentPoint = CGPoint(
                                 x: value.location.x - overlay.selectionRect.minX,
                                 y: value.location.y - overlay.selectionRect.minY
                             )
                        } else {
                            // Update selection
                            currentPoint = value.location
                            updateSelectionRect()
                        }
                    }
                    .onEnded { _ in
                        if isDrawingAnnotation {
                            // Finalize annotation
                            let rect = calculateAnnotationRect(start: startPoint, end: currentPoint)
                            if rect.width > 5 && rect.height > 5 {
                                overlay.annotations.append(rect)
                            }
                            isDrawingAnnotation = false
                        } else {
                            // Finalize selection
                            isDragging = false
                        }
                        
                        guard isThisScreenActive else { return }
                    }
            )
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



    
    private func calculateAnnotationRect(start: CGPoint, end: CGPoint) -> CGRect {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        
        // Clamp to selection bounds (which is 0,0 to width,height in local annotation coords)
        let width = overlay.selectionRect.width
        let height = overlay.selectionRect.height
        
        let clampedMinX = max(0, minX)
        let clampedMinY = max(0, minY)
        let clampedMaxX = min(width, maxX)
        let clampedMaxY = min(height, maxY)
        
        return CGRect(
            x: clampedMinX,
            y: clampedMinY,
            width: max(0, clampedMaxX - clampedMinX),
            height: max(0, clampedMaxY - clampedMinY)
        )
    }
}

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

class SelectionWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}
