import ArgumentParser
import Foundation

// Invoke the async entry point. Task + RunLoop.main keeps the process alive
// while async work is dispatched, which ArgumentParser requires for
// AsyncParsableCommand on macOS.
if #available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *) {
    Task { @MainActor in
        await GlassCapCLI.main()
        // GlassCapCLI.main() calls Foundation.exit internally when done.
        // This line is only reached if it returns normally (shouldn't happen).
        Foundation.exit(0)
    }
    // Keep the process alive so the async Task can run on the main thread.
    RunLoop.main.run()
} else {
    print(#"{"error": "glasscap requires macOS 10.15 or later."}"#)
    Foundation.exit(1)
}
