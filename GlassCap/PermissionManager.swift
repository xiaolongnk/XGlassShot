import Foundation
import AppKit
import CoreGraphics
import Combine
import ScreenCaptureKit

@available(macOS 10.15, *)
@MainActor
final class PermissionManager: ObservableObject {
    
    static let shared = PermissionManager()
    
    @Published private(set) var hasPermission: Bool = false
    
    private init() {
        updatePermissionStatus()
    }
    
    func canRecordScreen() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    func checkLivePermission() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            hasPermission = true
        } catch {
            hasPermission = false
        }
        return hasPermission
    }

    func updatePermissionStatus() {
        hasPermission = canRecordScreen()
    }
    
    func openSystemSettings() {
        if #available(macOS 13.0, *) {
            // macOS Ventura and later - use Settings app
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(url)
        } else {
            // macOS Monterey and earlier - use System Preferences
            let url = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
            NSWorkspace.shared.open(url)
        }
    }
}
