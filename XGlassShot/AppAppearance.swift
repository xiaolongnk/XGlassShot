import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class AppAppearance: ObservableObject {
    static let shared = AppAppearance()
    private let defaults: UserDefaults
    private let backgroundStore: BackgroundImageStore
    @Published private(set) var backgroundImage: NSImage?
    @Published private(set) var backgroundName: String?
    @Published private(set) var isImportingBackground = false
    @Published var backgroundError: String?
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
    init(defaults: UserDefaults = .standard, backgroundStore: BackgroundImageStore = .applicationStore) {
        self.defaults = defaults
        self.backgroundStore = backgroundStore
        if let image = backgroundStore.load() {
            backgroundImage = NSImage(cgImage: image, size: .zero)
            backgroundName = defaults.string(forKey: "backgroundImageName") ?? "Custom image".localized
        }
        mode = Mode(rawValue: defaults.string(forKey: "appearanceMode") ?? "system") ?? .system
        let saved = defaults.object(forKey: "glassTransparency") as? Double ?? 0.35
        transparency = min(0.8, max(0, saved.isFinite ? saved : 0.35))
        apply()
    }

    func chooseBackground() async {
        guard !isImportingBackground else { return }
        isImportingBackground = true
        defer { isImportingBackground = false }
        backgroundError = nil
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a background image".localized
        panel.prompt = "Choose…".localized
        guard await panel.begin() == .OK, let url = panel.url else { return }
        do {
            try await importBackground(from: url)
        } catch {
            backgroundError = "Could not read or save this image. Try another image.".localized
        }
    }

    func importBackground(from url: URL) async throws {
        let store = backgroundStore
        let image = try await Task.detached(priority: .userInitiated) { try store.importImage(from: url) }.value
        backgroundImage = NSImage(cgImage: image, size: .zero)
        backgroundName = url.lastPathComponent
        defaults.set(backgroundName, forKey: "backgroundImageName")
    }

    func removeBackground() {
        guard !isImportingBackground else { return }
        do {
            try backgroundStore.remove()
            backgroundImage = nil
            backgroundName = nil
            defaults.removeObject(forKey: "backgroundImageName")
            backgroundError = nil
        } catch {
            backgroundError = "Could not remove the background. Please try again.".localized
        }
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
    enum Tab: String, CaseIterable { case general, appearance, capture, saving, shortcuts }
    @Published var isPresented = false
    @Published var tab: Tab = .general
    @Published private(set) var savingFocusRequest = 0
    func show(_ tab: Tab = .general) {
        self.tab = tab
        if tab == .saving { savingFocusRequest += 1 }
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "GlassCapMainWindow" }) {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        } else { NSWorkspace.shared.open(Bundle.main.bundleURL) }
        isPresented = true
    }
}
