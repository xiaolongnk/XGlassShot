// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GlassCapReliability",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "CaptureCore", path: "GlassCap", exclude: ["Assets.xcassets", "BeautifulExportCompositor.swift", "BeautifulExportView.swift", "CaptureImageSupport.swift", "CapturePreviewView.swift", "ClipboardRegister.swift", "Color+Hex.swift", "CompactWindowSizing.swift", "ContentView.swift", "DisplayIdentity.swift", "DockToggle.swift", "GlassCapApp.swift", "GlassView.swift", "HeroActionButton.swift", "Info.plist", "LanguageSwitcher.swift", "LaunchManager.swift", "Localizable.json", "LocalizationManager.swift", "OCRManager.swift", "OverlayManager.swift", "PermissionManager.swift", "ScreenRecorder.swift", "SelectionOverlay.swift", "SelectionOverlayDecorations.swift", "SettingsDock.swift", "ShortcutsManager.swift", "StatusBarManager.swift", "StorageManager.swift", "Theme.swift", "VisualEffectBackground.swift"], sources: ["CaptureSession.swift", "CaptureGeometry.swift", "CaptureFileStore.swift", "RecordingWriter.swift", "LegacySettings.swift", "CaptureThumbnail.swift"]),
        .testTarget(name: "CaptureCoreTests", dependencies: ["CaptureCore"], path: "Tests")
    ]
)
