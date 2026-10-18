// Hardware check: compiles the production capture engine and selection ownership.
// Only storage/feedback settings are substituted; capture/display logic is unchanged.
import Foundation
import AppKit
import SwiftUI
import ScreenCaptureKit
import ImageIO
import Combine

@MainActor final class StorageManager {
    static let shared = StorageManager()
    var addScreenshotOutline = false
    let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    func makeRecoveryRecordingURL() throws -> URL { directory.appendingPathComponent(UUID().uuidString + ".mov") }
    func saveScreenshot(data: Data, prefix: String) async throws -> URL {
        let url = directory.appendingPathComponent(UUID().uuidString + ".png")
        try data.write(to: url, options: .withoutOverwriting)
        return url
    }
    func showVisualFlash(on screen: NSScreen? = nil) {}
}

enum CaptureQuality {
    case low, high
    var scaleFactor: CGFloat { self == .high ? 2 : 1 }
    var videoBitrateFactor: Int { self == .high ? 12 : 4 }
    var description: String { "Hardware verification" }
    var displayName: String { self == .high ? "High" : "Low" }
}
@MainActor final class ShortcutsManager: ObservableObject {
    static let shared = ShortcutsManager()
    var captureQuality: CaptureQuality = .low
    var currentPrefix = "verification"
}
@MainActor final class LocalizationManager: ObservableObject { static let shared = LocalizationManager() }
extension String { var localized: String { self } }

@main struct VerifyDisplays {
    @MainActor static func main() async throws {
        let directory = StorageManager.shared.directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let screens = NSScreen.screens
        guard screens.count >= 2 else { throw CheckFailure("Two connected displays are required") }
        let selection = SelectionOverlay()
        for _ in 0..<10 {
            for screen in screens {
                selection.setCurrentScreen(screen)
                guard screens.filter({ selection.isSelectedScreen($0) }).map(\.displayIdentifier) == [screen.displayIdentifier] else {
                    throw CheckFailure("Selection ownership leaked to another display")
                }
            }
        }
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        var results: [[String: Any]] = []
        for (index, screen) in screens.enumerated() {
          for quality in [CaptureQuality.low, .high] {
            let rect = CGRect(x: 100, y: 120, width: 320, height: 200)
            let actual = try await ScreenRecorder.shared.captureScreenshot(region: rect, annotations: [], screen: screen, quality: quality)
            guard let source = CGImageSourceCreateWithURL(actual as CFURL, nil),
                  let actualImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
                  let display = content.displays.first(where: { $0.displayID == screen.displayIdentifier }) else {
                throw CheckFailure("The selected display or captured image is missing")
            }
            let expected = try await reference(display: display, rect: rect, scale: quality.scaleFactor)
            let difference = try pixelDifference(actualImage, expected)
            guard difference < 0.01 else { throw CheckFailure("Display \(index) content mismatch: \(difference)") }
            let named = directory.appendingPathComponent("display-\(index)-\(quality.scaleFactor == 1 ? "standard" : "retina")-\(UUID().uuidString.prefix(8)).png")
            try FileManager.default.moveItem(at: actual, to: named)
            results.append(["screen": screen.localizedName, "quality_scale": quality.scaleFactor, "display_id": screen.displayIdentifier,
                            "desktop_origin": [screen.frame.origin.x, screen.frame.origin.y],
                            "backing_scale": screen.backingScaleFactor, "width": actualImage.width,
                            "height": actualImage.height, "pixel_difference_fraction": difference, "path": named.path])
        }
        }
        let report: [String: Any] = ["passed": true, "ownership_switches": screens.count * 10, "screens": results]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: directory.appendingPathComponent("display-check.json"))
        print(String(decoding: data, as: UTF8.self))
    }

    static func reference(display: SCDisplay, rect: CGRect, scale: CGFloat) async throws -> CGImage {
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = Int(rect.width * scale)
        config.height = Int(rect.height * scale)
        config.showsCursor = true
        return try await SCScreenshotManager.captureImage(contentFilter: SCContentFilter(display: display, excludingWindows: []), configuration: config)
    }

    static func pixelDifference(_ lhs: CGImage, _ rhs: CGImage) throws -> Double {
        guard lhs.width == rhs.width, lhs.height == rhs.height else { throw CheckFailure("Pixel dimensions do not match") }
        func pixels(_ image: CGImage) throws -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
            try bytes.withUnsafeMutableBytes { buffer in
                guard let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                    bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw CheckFailure("Cannot compare image pixels") }
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return bytes
        }
        let a = try pixels(lhs), b = try pixels(rhs)
        let mismatches = a.indices.filter { abs(Int(a[$0]) - Int(b[$0])) > 3 }.count
        return Double(mismatches) / Double(a.count)
    }
}
struct CheckFailure: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
