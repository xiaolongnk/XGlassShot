import Foundation
import ScreenCaptureKit
import AppKit

// Helper to print frames
func run() async {
    do {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        print("--- SCDisplays ---")
        for display in content.displays {
            print("ID: \(display.displayID), Frame: \(display.frame)")
        }
        
        print("\n--- NSScreens ---")
        for screen in NSScreen.screens {
             let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
             print("ID: \(id?.uint32Value ?? 0), Frame: \(screen.frame)")
        }
        
    } catch {
        print("Error: \(error)")
    }
}

// Run loop
let semaphore = DispatchSemaphore(value: 0)
Task {
    await run()
    semaphore.signal()
}
semaphore.wait()
