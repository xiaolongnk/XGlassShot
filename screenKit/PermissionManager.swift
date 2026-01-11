import Foundation
import AppKit
import CoreGraphics

@available(macOS 10.15, *)
final class PermissionManager: ObservableObject {
    
    static let shared = PermissionManager()
    
    @Published private(set) var hasPermission: Bool = false
    
    private init() {
        updatePermissionStatus()
    }
    
    func canRecordScreen() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        let granted = await withCheckedContinuation { continuation in
            CGRequestScreenCaptureAccess { granted in
                continuation.resume(returning: granted)
            }
        }
        
        await MainActor.run {
            hasPermission = granted
        }
        
        return granted
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
