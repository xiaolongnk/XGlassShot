import SwiftUI
import AppKit

/// Keeps the main window large enough to contain its native dialogs.
struct CompactWindowSizing: NSViewRepresentable {
    static let minimumSize = NSSize(width: 520, height: 460)
    static let defaultSize = NSSize(width: 600, height: 500)

    func makeNSView(context: Context) -> SizingView { SizingView() }
    func updateNSView(_ nsView: SizingView, context: Context) {}

    final class SizingView: NSView {
        private weak var configuredWindow: NSWindow?
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, window !== configuredWindow else { return }
            configuredWindow = window
            window.identifier = NSUserInterfaceItemIdentifier("GlassCapMainWindow")
            window.tabbingMode = .disallowed
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.contentMinSize = CompactWindowSizing.minimumSize
            window.contentMaxSize = NSSize(width: 800, height: 640)
            DispatchQueue.main.async {
                // SwiftUI may replace its provisional identifier during attachment.
                window.identifier = NSUserInterfaceItemIdentifier("GlassCapMainWindow")
                let top = window.frame.maxY
                window.setContentSize(CompactWindowSizing.defaultSize)
                var frame = window.frame
                frame.origin.y = top - frame.height
                if let screen = window.screen {
                    frame.origin.x = max(screen.visibleFrame.minX, min(frame.minX, screen.visibleFrame.maxX - frame.width))
                    frame.origin.y = max(screen.visibleFrame.minY, min(frame.minY, screen.visibleFrame.maxY - frame.height))
                }
                window.setFrame(frame, display: true)
            }
        }
    }
}
