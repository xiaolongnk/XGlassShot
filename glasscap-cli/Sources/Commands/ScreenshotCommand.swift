import ArgumentParser
import AppKit
import ScreenCaptureKit
import CoreGraphics

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct ScreenshotCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Capture a screenshot and save it to disk."
    )

    @Option(name: .long, help: "Screen index (from `glasscap screens`). Defaults to primary screen.")
    var screen: Int = 0

    @Option(name: .long, help: "Capture region as x,y,w,h in integer points (top-left origin). Defaults to full screen.")
    var region: String?

    @Option(name: .long, help: "Image quality: low or high. Defaults to high.")
    var quality: String = "high"

    @Option(name: .long, help: "Output file path. Defaults to ~/Pictures/GlassCap/glasscap-<timestamp>.png.")
    var output: String?

    func run() async throws {
        PermissionCheck.requireScreenRecording()

        let nsScreens = NSScreen.screens
        guard !nsScreens.isEmpty else {
            JSONOutput.failure("No screens found.")
        }
        guard screen >= 0 && screen < nsScreens.count else {
            JSONOutput.failure("Screen index \(screen) is out of range. Use `glasscap screens` to list available screens.")
        }
        let nsScreen = nsScreens[screen]

        // Parse region
        let captureRegion: CGRect
        if let regionStr = region {
            captureRegion = try parseRegion(regionStr, screen: nsScreen)
        } else {
            captureRegion = CGRect(origin: .zero, size: nsScreen.frame.size)
        }

        // Parse quality
        let scaleFactor: CGFloat = (quality == "low") ? 1.0 : 2.0

        // Resolve output path
        let outputURL = try resolveOutputPath(output, ext: "png")

        // Perform capture
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let targetDisplay = findDisplay(for: nsScreen, in: content.displays) else {
            JSONOutput.failure("Could not find a matching SCDisplay for screen \(screen).")
        }

        let displayRegion = convertToDisplayCoordinates(captureRegion, screen: nsScreen, display: targetDisplay)

        let captureWidth  = Int(ceil(captureRegion.width  * scaleFactor))
        let captureHeight = Int(ceil(captureRegion.height * scaleFactor))

        let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect  = displayRegion
        config.width       = captureWidth
        config.height      = captureHeight
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

        // Encode to PNG
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            JSONOutput.failure("Failed to encode screenshot as PNG.")
        }

        // Write to disk
        try pngData.write(to: outputURL)

        JSONOutput.success(ScreenshotResponse(
            path: outputURL.path,
            width: image.width,
            height: image.height
        ))
    }

    // MARK: - Helpers

    private func parseRegion(_ str: String, screen: NSScreen) throws -> CGRect {
        let parts = str.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 4,
              let x = Int(parts[0]), let y = Int(parts[1]),
              let w = Int(parts[2]), let h = Int(parts[3]),
              w > 0, h > 0 else {
            JSONOutput.failure("Invalid --region '\(str)'. Expected format: x,y,w,h with positive integer dimensions.")
        }
        let screenSize = screen.frame.size
        let rect = CGRect(x: x, y: y, width: w, height: h)
        let screenBounds = CGRect(origin: .zero, size: screenSize)
        let clipped = rect.intersection(screenBounds)
        guard !clipped.isNull, clipped.width > 0, clipped.height > 0 else {
            JSONOutput.failure("Region \(str) does not intersect screen bounds (\(Int(screenSize.width))x\(Int(screenSize.height))).")
        }
        return clipped
    }

    private func resolveOutputPath(_ path: String?, ext: String) throws -> URL {
        if let path = path {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        }
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures/GlassCap")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let ts = timestamp()
        return dir.appendingPathComponent("glasscap-\(ts).\(ext)")
    }

    private func timestamp() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd-HHmmss"
        return fmt.string(from: Date())
    }

    private func findDisplay(for screen: NSScreen, in displays: [SCDisplay]) -> SCDisplay? {
        guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return displays.first
        }
        let id = num.uint32Value
        return displays.first(where: { $0.displayID == id }) ?? displays.first
    }

    private func convertToDisplayCoordinates(_ region: CGRect, screen: NSScreen, display: SCDisplay) -> CGRect {
        let displayBounds = CGRect(origin: .zero, size: display.frame.size)
        let clipped = region.intersection(displayBounds)
        return (clipped.isNull || clipped.width <= 0 || clipped.height <= 0) ? displayBounds : clipped
    }
}
