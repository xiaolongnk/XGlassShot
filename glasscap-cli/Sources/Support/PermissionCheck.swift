import CoreGraphics
import Foundation

enum PermissionCheck {
    /// Exits with a JSON error if screen recording permission is not granted.
    static func requireScreenRecording() {
        guard CGPreflightScreenCaptureAccess() else {
            JSONOutput.failure(
                "No screen recording permission. Grant permission to your terminal in " +
                "System Settings > Privacy & Security > Screen Recording."
            )
        }
    }
}
