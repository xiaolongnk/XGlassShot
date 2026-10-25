// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XGlassShotReliability",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "CaptureCore", path: "XGlassShot", exclude: ["PrivacyInfo.xcprivacy", "ThirdPartyNotices.txt", "AppAppearance.swift", "GlassSurface.swift", "Assets.xcassets", "BeautifulExportView.swift", "CaptureImageSupport.swift", "CapturePreviewView.swift", "Color+Hex.swift", "CompactWindowSizing.swift", "ContentView.swift", "DisplayIdentity.swift", "DockToggle.swift", "XGlassShotApp.swift", "GlassView.swift", "HeroActionButton.swift", "Info.plist", "LanguageSwitcher.swift", "LaunchManager.swift", "Localizable.json", "LocalizationManager.swift", "OverlayManager.swift", "PermissionManager.swift", "ScreenRecorder.swift", "SelectionOverlay.swift", "SelectionOverlayDecorations.swift", "SettingsDock.swift", "ShortcutsManager.swift", "KeyboardShortcutsView.swift", "StatusBarManager.swift", "StorageManager.swift", "Theme.swift", "VisualEffectBackground.swift"], sources: ["CaptureHistory.swift", "ClipboardRegister.swift", "CaptureSession.swift", "CaptureGeometry.swift", "CaptureFileStore.swift", "RecordingWriter.swift", "LegacySettings.swift", "CaptureThumbnail.swift", "BackgroundImageStore.swift", "OCRManager.swift", "BeautifulExportCompositor.swift"]),
        .testTarget(name: "CaptureCoreTests", dependencies: ["CaptureCore"], path: "Tests")
    ]
)
