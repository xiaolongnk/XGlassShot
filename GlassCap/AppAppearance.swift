import SwiftUI
import AppKit
import Combine

@MainActor
final class AppAppearance: ObservableObject {
    static let shared = AppAppearance()
    private let defaults: UserDefaults
    enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: return "Follow system".localized
            case .light: return "Day".localized
            case .dark: return "Night".localized
            }
        }
        var colorScheme: ColorScheme? {
            switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
        }
    }
    @Published var mode: Mode {
        didSet { defaults.set(mode.rawValue, forKey: "appearanceMode"); apply() }
    }
    /// Changes the background tint, never the opacity of text or screenshot pixels.
    @Published var transparency: Double {
        didSet {
            let bounded = min(0.8, max(0, transparency.isFinite ? transparency : 0.35))
            if transparency != bounded { transparency = bounded; return }
            defaults.set(bounded, forKey: "glassTransparency")
        }
    }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        mode = Mode(rawValue: defaults.string(forKey: "appearanceMode") ?? "system") ?? .system
        let saved = defaults.object(forKey: "glassTransparency") as? Double ?? 0.35
        transparency = min(0.8, max(0, saved.isFinite ? saved : 0.35))
        apply()
    }
    private func apply() {
        let application = NSApplication.shared
        switch mode {
        case .system: application.appearance = nil
        case .light: application.appearance = NSAppearance(named: .aqua)
        case .dark: application.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

@MainActor
final class SettingsPresentation: ObservableObject {
    static let shared = SettingsPresentation()
    enum Tab: String, CaseIterable { case general, capture, saving }
    @Published var isPresented = false
    @Published var tab: Tab = .general
    func show(_ tab: Tab = .general) {
        self.tab = tab
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "GlassCapMainWindow" && $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else { NSWorkspace.shared.open(Bundle.main.bundleURL) }
        isPresented = true
    }
}
