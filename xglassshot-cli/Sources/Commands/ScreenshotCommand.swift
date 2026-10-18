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

    @Option(name: .long, help: "Screen index (from `xglassshot screens`). Defaults to primary screen.")
    var screen: Int = 0

    @Option(name: .long, help: "Capture region as x,y,w,h in integer points (top-left origin). Defaults to full screen.")
    var region: String?

    @Option(name: .long, help: "Image quality: low or high. Defaults to high.")
    var quality: String = "high"

    @Option(name: .long, help: "Output file path. Defaults to ~/Pictures/XGlassShot/xglassshot-<timestamp>.png.")
    var output: String?

    @Option(name: .long, help: "Destination directory for a unique automatic filename. Cannot be combined with --output.")
    var directory: String?

    @Option(name: .long, help: "Automatic filename prefix; default: xglassshot. Cannot be combined with --output.")
    var prefix: String?

    func run() async throws {
        do { try await capture() }
        catch { JSONOutput.failure(error.localizedDescription) }
    }

    private func capture() async throws {
        guard ["low", "high"].contains(quality) else { JSONOutput.failure("Invalid --quality. Expected low or high.") }
        if output != nil && (directory != nil || prefix != nil) { throw CaptureDestination.DestinationError.conflictingOptions }
        PermissionCheck.requireScreenRecording()

        let nsScreens = NSScreen.screens
        guard !nsScreens.isEmpty else {
            JSONOutput.failure("No screens found.")
        }
        guard screen >= 0 && screen < nsScreens.count else {
            JSONOutput.failure("Screen index \(screen) is out of range. Use `xglassshot screens` to list available screens.")
        }
        let nsScreen = nsScreens[screen]

        let captureRegion = try CaptureRegion.parse(region, size: nsScreen.frame.size)

        // Parse quality
        let scaleFactor: CGFloat = (quality == "low") ? 1.0 : 2.0

        // Resolve output path
        let outputURL = try CaptureDestination.resolve(output: output, directory: directory, prefix: prefix)

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
        try pngData.write(to: outputURL, options: .withoutOverwriting)

        JSONOutput.success(ScreenshotResponse(
            path: outputURL.path,
            width: image.width,
            height: image.height
        ))
    }

    // MARK: - Helpers

    private func findDisplay(for screen: NSScreen, in displays: [SCDisplay]) -> SCDisplay? {
        guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        let id = num.uint32Value
        return displays.first(where: { $0.displayID == id })
    }

    private func convertToDisplayCoordinates(_ region: CGRect, screen: NSScreen, display: SCDisplay) -> CGRect {
        let displayBounds = CGRect(origin: .zero, size: display.frame.size)
        guard region.origin.x.isFinite, region.origin.y.isFinite,
              region.width >= 1, region.height >= 1, displayBounds.contains(region) else {
            JSONOutput.failure("Capture region is outside the selected display. No capture was made.")
        }
        return region
    }
}
