import XCTest
import AppKit
@testable import CaptureCore

final class LocalFeatureTests: XCTestCase {
    @MainActor
    func testChineseAndEnglishTextCanBeRecognizedLocally() async throws {
        let image = NSImage(size: NSSize(width: 1200, height: 400))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1200, height: 400)).fill()
        ("截图目录和文件前缀\nGlassCap 2026" as NSString).draw(at: NSPoint(x: 60, y: 120), withAttributes: [
            .font: NSFont.systemFont(ofSize: 54, weight: .medium), .foregroundColor: NSColor.black
        ])
        image.unlockFocus()
        let cgImage = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let data = try XCTUnwrap(NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]))
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("ocr-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: file) }
        try data.write(to: file)
        let text = try await OCRManager.shared.extractText(from: file)
        XCTAssertTrue(text.contains("截图目录和文件前缀"), "Chinese line was not recognized")
        XCTAssertTrue(text.contains("GlassCap 2026"), "English line was not recognized")
    }

    @MainActor
    func testBeautificationPreservesImageAndAddsBackground() throws {
        let image = NSImage(size: NSSize(width: 200, height: 100))
        image.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 200, height: 100)).fill()
        image.unlockFocus()
        var options = BeautifulExportCompositor.Options()
        options.padding = 48
        let output = try XCTUnwrap(BeautifulExportCompositor.compose(image: image, options: options))
        let cgImage = try XCTUnwrap(output.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let sourceCG = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        XCTAssertEqual(cgImage.width, sourceCG.width + 96)
        XCTAssertEqual(cgImage.height, sourceCG.height + 96)
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let center = try XCTUnwrap(bitmap.colorAt(x: cgImage.width / 2, y: cgImage.height / 2)?.usingColorSpace(.deviceRGB))
        let background = try XCTUnwrap(bitmap.colorAt(x: 0, y: 0)?.usingColorSpace(.deviceRGB))
        XCTAssertGreaterThan(center.redComponent, 0.9)
        XCTAssertLessThan(center.greenComponent, 0.1)
        XCTAssertLessThan(background.redComponent, 0.5)
        XCTAssertGreaterThan(background.alphaComponent, 0.99)
    }
}
