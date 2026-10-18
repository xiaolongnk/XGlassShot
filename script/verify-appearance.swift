import Foundation
import SwiftUI
import AppKit

// Localization is irrelevant to this state/persistence check; use the actual appearance manager.
extension String { var localized: String { self } }

@main struct AppearanceVerification {
    @MainActor static func main() async throws {
        let suite = "GlassCapAppearanceVerification-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackgroundImageStore(directory: root.appendingPathComponent("managed"))
        let appearance = AppAppearance(defaults: defaults, backgroundStore: store)
        precondition(appearance.mode == .system && appearance.transparency == 0.35)
        appearance.transparency = 0.65
        precondition(appearance.transparency == 0.65)
        appearance.mode = .dark
        let restored = AppAppearance(defaults: defaults, backgroundStore: store)
        precondition(restored.mode == .dark && restored.transparency == 0.65)
        appearance.transparency = 2
        precondition(appearance.transparency == 0.8)
        appearance.transparency = -1
        precondition(appearance.transparency == 0)
        appearance.transparency = .nan
        precondition(appearance.transparency == 0.35)
        appearance.mode = .light
        precondition(NSApplication.shared.appearance?.name == .aqua)
        appearance.mode = .system
        precondition(NSApplication.shared.appearance == nil)

        let source = root.appendingPathComponent("Background.png")
        let image = NSImage(size: NSSize(width: 80, height: 40))
        image.lockFocus()
        NSColor.cyan.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 80, height: 40)).fill()
        image.unlockFocus()
        let bitmap = NSBitmapImageRep(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
        try bitmap.representation(using: .png, properties: [:])!.write(to: source)
        try await appearance.importBackground(from: source)
        precondition(appearance.backgroundImage != nil && appearance.backgroundName == "Background.png")
        try FileManager.default.removeItem(at: source)
        let withBackground = AppAppearance(defaults: defaults, backgroundStore: store)
        precondition(withBackground.backgroundImage != nil && withBackground.backgroundName == "Background.png")
        do {
            try await appearance.importBackground(from: source)
            preconditionFailure("Missing source should fail")
        } catch { precondition(appearance.backgroundImage != nil && appearance.backgroundName == "Background.png") }
        withBackground.removeBackground()
        precondition(withBackground.backgroundImage == nil && withBackground.backgroundName == nil)
        precondition(AppAppearance(defaults: defaults, backgroundStore: store).backgroundImage == nil)
        print("Appearance state: 13 checks passed (modes, bounds, persistence, image import/restore/failure/removal)")
    }
}
