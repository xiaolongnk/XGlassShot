import Foundation
import SwiftUI
import AppKit

// Localization is irrelevant to this state/persistence check; use the actual appearance manager.
extension String { var localized: String { self } }

@main struct AppearanceVerification {
    @MainActor static func main() {
        let suite = "GlassCapAppearanceVerification-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let appearance = AppAppearance(defaults: defaults)
        precondition(appearance.mode == .system && appearance.transparency == 0.35)
        appearance.transparency = 0.65
        precondition(appearance.transparency == 0.65)
        appearance.mode = .dark
        let restored = AppAppearance(defaults: defaults)
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
        print("Appearance state: 8 checks passed (update, persistence, bounds, nonfinite input, light/dark/system)")
    }
}
