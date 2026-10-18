import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import CaptureCore

final class BackgroundImageTests: XCTestCase {
    private func fixture(at url: URL, width: Int = 80, height: Int = 40, red: CGFloat = 0.7) throws {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                             bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: red, green: 0.2, blue: 0.4, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    func testManagedCopySurvivesSourceRemovalAndReplacement() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("背景 image.png")
        let store = BackgroundImageStore(directory: root.appendingPathComponent("managed"))
        try fixture(at: source)
        _ = try store.importImage(from: source)
        try FileManager.default.removeItem(at: source)
        XCTAssertEqual(try XCTUnwrap(store.load()).width, 80)
        // A fresh store reads the same internal copy, without any external file permission.
        XCTAssertEqual(try XCTUnwrap(BackgroundImageStore(directory: store.directory).load()).height, 40)
        try fixture(at: source, width: 100)
        _ = try store.importImage(from: source)
        XCTAssertEqual(try XCTUnwrap(store.load()).width, 100)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: store.directory.path), ["background.png"])
    }

    func testInvalidReplacementPreservesPreviousBackground() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackgroundImageStore(directory: root.appendingPathComponent("managed"))
        let source = root.appendingPathComponent("image.png")
        try fixture(at: source)
        _ = try store.importImage(from: source)
        let previous = try Data(contentsOf: store.imageURL)
        try Data("invalid image".utf8).write(to: source)
        XCTAssertThrowsError(try store.importImage(from: source))
        XCTAssertEqual(try Data(contentsOf: store.imageURL), previous)
        XCTAssertNotNil(store.load())
        XCTAssertThrowsError(try store.importImage(from: root.appendingPathComponent("missing.png")))
    }

    func testLargeImageIsBoundedAndRemovalIsDurable() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = BackgroundImageStore(directory: root.appendingPathComponent("managed"))
        let source = root.appendingPathComponent("large.png")
        try fixture(at: source, width: 4800, height: 1200)
        let image = try store.importImage(from: source)
        XCTAssertEqual(image.width, 2400)
        XCTAssertEqual(image.height, 600)
        try store.remove()
        XCTAssertNil(store.load())
        try store.remove()
    }

    func testUnavailableStorageReportsFailure() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("image.png")
        try fixture(at: source)
        let blocked = root.appendingPathComponent("file-instead-of-folder")
        try Data().write(to: blocked)
        XCTAssertThrowsError(try BackgroundImageStore(directory: blocked).importImage(from: source))
        XCTAssertNil(BackgroundImageStore(directory: blocked).load())
    }
}
