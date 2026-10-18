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
    @Published private(set) var currentScreen: NSScreen?
    private var screenObserver: NSObjectProtocol?
    
    // Annotations (relative to selectionRect)
    @Published var annotations: [CGRect] = []

    private var eventMonitor: Any?

    func show(on selectedScreen: NSScreen? = nil) {
        guard !isActive else { return }
        isActive = true
        setupInputMonitoring()
        NSApp.activate(ignoringOtherApps: true)

        let screens = NSScreen.screens.filter { screen in
            selectedScreen == nil || (selectedScreen?.displayIdentifier != 0 && screen.displayIdentifier == selectedScreen?.displayIdentifier)
        }
        guard !screens.isEmpty else {
            Task { await onCancel?() }
            return
        }
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.onCancel?() }
        }
        // Restrict explicit display choices, otherwise allow selection on any display.
        for screen in screens {
            let overlayWindow = SelectionWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )

            overlayWindow.title = "Select on " + screen.localizedName
            overlayWindow.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
            overlayWindow.backgroundColor = .clear
            overlayWindow.isOpaque = false
            overlayWindow.ignoresMouseEvents = false
            overlayWindow.hidesOnDeactivate = false
            overlayWindow.acceptsMouseMovedEvents = true
            overlayWindow.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .transient,
                .ignoresCycle
            ]

            let hostingView = NSHostingView(rootView: SelectionOverlayView(overlay: self, screen: screen))
            hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
            overlayWindow.contentView = hostingView

            overlayWindow.orderFrontRegardless()
            windows.append(overlayWindow)
        }

        // Make the window under the cursor key so the first click starts selection on that monitor
        let mouseLocation = NSEvent.mouseLocation
        if let screenUnderMouse = screens.first(where: { $0.frame.contains(mouseLocation) }),
           let idx = screens.firstIndex(where: { $0 === screenUnderMouse }),
           idx < windows.count {
            let keyWindow = windows[idx]
            DispatchQueue.main.async { keyWindow.makeKeyAndOrderFront(nil) }
        } else if let first = windows.first {
            DispatchQueue.main.async { first.makeKeyAndOrderFront(nil) }
        }
    }

    func hide() {
        // Order out first so AppKit removes the window from the screen hierarchy,
        // then clear the content view to release the SwiftUI hosting tree.
        // Reversing this order (contentView = nil before orderOut) can leave the
        // window in an inconsistent state where orderOut has no visible effect,
        // causing the dim overlay to persist on screen.
        for window in windows {
            window.orderOut(nil)
            window.contentView = nil
        }
        windows.removeAll()
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        screenObserver = nil
        isActive = false
        selectionRect = .zero
        annotations = []
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

        if event.keyCode == 36 { // Enter/Return
            confirmSelection()
            return nil // Always consume Enter when overlay is active
        } else if event.keyCode == 76 { // Numpad Enter
            confirmSelection()
            return nil
        } else if event.keyCode == 53 { // Escape
            Task { @MainActor in
                await onCancel?()
            }
            return nil // Consume event
        }

        return event
    }

    func confirmSelection() {
        guard isActive else { return }
        guard let screen = currentScreen else {
            // No screen selected yet — hide the overlay so the user isn't stuck
            Task { @MainActor in
                await onCancel?()
            }
            return
        }
        guard selectionRect.width > 10 && selectionRect.height > 10 else {
            // Selection too small — hide overlay so the user isn't stuck with
            // a persistent dim and a swallowed Enter key
            Task { @MainActor in
                await onCancel?()
            }
            return
        }
        let rect = selectionRect
        let ann = annotations
        // Hide first so the overlay is off-screen before the async capture begins
        hide()
        Task { @MainActor in
            await onConfirm?(rect, ann, screen)
        }
    }

    func isSelectedScreen(_ screen: NSScreen) -> Bool {
        guard let currentScreen else { return false }
        return currentScreen.displayIdentifier != 0 && currentScreen.displayIdentifier == screen.displayIdentifier
    }

    func setCurrentScreen(_ screen: NSScreen) {
        currentScreen = screen
    }
}

struct SelectionOverlayView: View {
    @ObservedObject var overlay: SelectionOverlay
    let screen: NSScreen

    @State private var hoveredEdge: ResizeEdge = .none
    @State private var isResizing: Bool = false
    @State private var resizeEdge: ResizeEdge = .none
    @State private var initialRect: CGRect = .zero

    // Missing properties restored
    @State private var startPoint: CGPoint = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var isDrawingAnnotation: Bool = false
    private var isThisScreenActive: Bool {
        overlay.isSelectedScreen(screen)
    }

    enum ResizeEdge {
        case none, top, bottom, left, right
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack {
                        Label(screen.localizedName, systemImage: "display")
                        Spacer()
                        Text("Drag to select · Return to capture · Esc to cancel".localized)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(20)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(1)
                // Dimmed background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                if isThisScreenActive && (isDragging || isResizing || overlay.selectionRect != .zero) {
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

            .background(
                MouseTrackingViewWrapper { location in
                    guard isThisScreenActive && overlay.selectionRect != .zero else { return }
                    
                    // Check if hovering over edges
                    hoveredEdge = detectEdge(at: location, rect: overlay.selectionRect)
                    
                    // Update cursor
                    switch hoveredEdge {
                    case .top, .bottom:
                        NSCursor.resizeUpDown.set()
                    case .left, .right:
                        NSCursor.resizeLeftRight.set()
                    case .none:
                        NSCursor.crosshair.set()
                    }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging && !isDrawingAnnotation && !isResizing {
                            let location = value.startLocation
                            
                            // 1. Check for Resize (High priority)
                            let edge = isThisScreenActive ? detectEdge(at: location, rect: overlay.selectionRect) : .none
                            if edge != .none {
                                isResizing = true
                                resizeEdge = edge
                                initialRect = overlay.selectionRect
                                return
                            }
                            
                            // 2. Check for Annotation (Inside)
                            // We use a small inset to allow resizing/moving selection in future if needed
                            if isThisScreenActive && overlay.selectionRect.insetBy(dx: 10, dy: 10).contains(location) {
                                isDrawingAnnotation = true
                                startPoint = CGPoint(
                                    x: location.x - overlay.selectionRect.minX,
                                    y: location.y - overlay.selectionRect.minY
                                )
                                currentPoint = startPoint
                            } else {
                                // 3. Start new selection (Outside)
                                isDragging = true
                                overlay.setCurrentScreen(screen)
                                overlay.selectionRect = .zero // Reset selection
                                overlay.annotations = []      // Reset annotations
                                startPoint = location
                                currentPoint = location
                                updateSelectionRect()
                            }
                        } else if isResizing {
                             updateResize(value: value)
                        } else if isDrawingAnnotation {
                             // Update current annotation point (relative to selection)
                             currentPoint = CGPoint(
                                 x: value.location.x - overlay.selectionRect.minX,
                                 y: value.location.y - overlay.selectionRect.minY
                             )
                        } else {
                            // Update normal selection
                            currentPoint = value.location
                            updateSelectionRect()
                        }
                    }
                    .onEnded { _ in
                        isResizing = false
                        resizeEdge = .none
                        
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

    private func detectEdge(at point: CGPoint, rect: CGRect) -> ResizeEdge {
        let threshold: CGFloat = 10
        
        let inHp = point.x >= rect.minX - threshold && point.x <= rect.maxX + threshold
        let inVp = point.y >= rect.minY - threshold && point.y <= rect.maxY + threshold
        
        if inHp && abs(point.y - rect.minY) <= threshold { return .top }
        if inHp && abs(point.y - rect.maxY) <= threshold { return .bottom }
        if inVp && abs(point.x - rect.minX) <= threshold { return .left }
        if inVp && abs(point.x - rect.maxX) <= threshold { return .right }
        
        return .none
    }
    
    private func updateResize(value: DragGesture.Value) {
        var newRect = initialRect
        let translation = value.translation
        
        switch resizeEdge {
        case .top:
            // Adjust minY, height changes inversely
            // Ensure height doesn't go negative
            let newHeight = max(10, initialRect.height - translation.height)
            let newY = initialRect.maxY - newHeight // Anchor bottom
            newRect.origin.y = newY
            newRect.size.height = newHeight
            
        case .bottom:
            // Adjust height
            newRect.size.height = max(10, initialRect.height + translation.height)
            
        case .left:
            // Adjust minX, width changes inversely
            let newWidth = max(10, initialRect.width - translation.width)
            let newX = initialRect.maxX - newWidth // Anchor right
            newRect.origin.x = newX
            newRect.size.width = newWidth
            
        case .right:
            // Adjust width
            newRect.size.width = max(10, initialRect.width + translation.width)
            
        case .none:
            break
        }
        
        overlay.selectionRect = newRect.intersection(CGRect(origin: .zero, size: screen.frame.size))
    }

    private func updateSelectionRect() {
        overlay.selectionRect = CaptureGeometry.selection(start: startPoint, end: currentPoint,
            bounds: CGRect(origin: .zero, size: screen.frame.size))
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
