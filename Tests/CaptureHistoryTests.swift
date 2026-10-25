import XCTest
import AppKit
@testable import CaptureCore

final class CaptureHistoryTests: XCTestCase {
    func testChronologyDeduplicationAndStableIdentity() {
        let older = CaptureHistoryEntry(url: URL(fileURLWithPath: "/older.png"), capturedAt: Date(timeIntervalSince1970: 1), bookmark: Data([1]))
        let newer = CaptureHistoryEntry(url: URL(fileURLWithPath: "/newer.png"), capturedAt: Date(timeIntervalSince1970: 2))
        var history = CaptureHistory()
        history.merge([older, newer])
        history.merge([CaptureHistoryEntry(url: older.url, capturedAt: older.capturedAt)])
        XCTAssertEqual(history.entries.map(\.url), [newer.url, older.url])
        XCTAssertEqual(history.entries.last?.id, older.id)
        XCTAssertEqual(history.entries.last?.bookmark, Data([1]))
        XCTAssertEqual(history.neighbor(of: newer.url, direction: .older)?.url, older.url)
        XCTAssertEqual(history.neighbor(of: older.url, direction: .newer)?.url, newer.url)
        XCTAssertNil(history.neighbor(of: older.url, direction: .older))
        XCTAssertNil(history.neighbor(of: newer.url, direction: .newer))
    }

    func testCapacityAndRestartRoundTrip() throws {
        var history = CaptureHistory()
        history.merge((0..<120).map { CaptureHistoryEntry(url: URL(fileURLWithPath: "/\($0).png"), capturedAt: Date(timeIntervalSince1970: Double($0))) })
        XCTAssertEqual(history.entries.count, CaptureHistory.capacity)
        XCTAssertEqual(history.entries.first?.url.lastPathComponent, "119.png")
        let restored = try JSONDecoder().decode(CaptureHistory.self, from: JSONEncoder().encode(history))
        XCTAssertEqual(restored, history)
        XCTAssertEqual(restored.neighbor(of: nil, direction: .older), restored.entries.first)
        XCTAssertNil(restored.neighbor(of: nil, direction: .newer))
    }

    func testDiscoveryExcludesUnrelatedPhotosAndDirectories() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let capture = directory.appendingPathComponent("any-prefix_20261024-120000-123-A1B2C3D4.png")
        try Data().write(to: capture)
        try Data().write(to: directory.appendingPathComponent("personal-photo.png"))
        try Data().write(to: directory.appendingPathComponent("20261024-120000-123-A1B2C3D4.mov"))
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("20261024-120000-123-ABCD1234.png"), withIntermediateDirectories: false)
        XCTAssertEqual(CaptureHistory.discover(in: directory).map { $0.url.resolvingSymlinksInPath() }, [capture.resolvingSymlinksInPath()])
    }

    @MainActor
    func testPersistenceAndDeletedFileNavigation() throws {
        let suite = "history-test-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let older = directory.appendingPathComponent("older.png")
        let missing = directory.appendingPathComponent("missing.png")
        let newer = directory.appendingPathComponent("newer.png")
        try Data([1]).write(to: older)
        try Data([1]).write(to: missing)
        try Data([1]).write(to: newer)
        let manager = ClipboardRegisterManager(defaults: defaults)
        manager.addEntry(imageURL: older)
        manager.addEntry(imageURL: missing)
        manager.addEntry(imageURL: newer)
        try FileManager.default.removeItem(at: missing)
        let restored = ClipboardRegisterManager(defaults: defaults)
        XCTAssertEqual(restored.history.entries.count, 3)
        XCTAssertTrue(restored.browse(.older, from: newer))
        XCTAssertEqual(restored.previewURL?.resolvingSymlinksInPath(), older.resolvingSymlinksInPath())
        XCTAssertEqual(restored.history.entries.count, 2)
        XCTAssertFalse(restored.browse(.older, from: older))
        restored.showLatest(url: newer)
        XCTAssertNil(restored.previewURL)
        let recording = directory.appendingPathComponent("latest.mov")
        restored.showLatest(url: recording)
        XCTAssertTrue(restored.browse(.older, from: recording))
        XCTAssertTrue(restored.canBrowse(.newer, from: newer))
        XCTAssertTrue(restored.browse(.newer, from: newer))
        XCTAssertNil(restored.previewURL)
    }

    @MainActor
    func testCopyUsesOriginalPixelsAndPreservesClipboardOnFailure() throws {
        let suite = "history-test-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let image = NSImage(size: NSSize(width: 1600, height: 900))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 1600, height: 900).fill()
        image.unlockFocus()
        let cg = try XCTUnwrap(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        defer { try? FileManager.default.removeItem(at: file) }
        let png = try XCTUnwrap(NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]))
        try png.write(to: file)
        let manager = ClipboardRegisterManager(defaults: defaults)
        manager.addEntry(imageURL: file)
        let pasteboard = NSPasteboard(name: .init("history-test-" + UUID().uuidString))
        defer { pasteboard.clearContents() }
        XCTAssertTrue(manager.copyImage(at: file, to: pasteboard))
        let copied = try XCTUnwrap(pasteboard.data(forType: .tiff))
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: copied))
        XCTAssertEqual(bitmap.pixelsWide, cg.width)
        XCTAssertEqual(bitmap.pixelsHigh, cg.height)
        let menuEntry = try XCTUnwrap(manager.entries.first)
        XCTAssertEqual(menuEntry.id, manager.entries.first?.id)
        let restarted = ClipboardRegisterManager(defaults: defaults)
        XCTAssertEqual(menuEntry.id, restarted.entries.first?.id)
        restarted.copyToPasteboard(entry: menuEntry, to: pasteboard)
        XCTAssertNotNil(pasteboard.data(forType: .tiff))
        try FileManager.default.removeItem(at: file)
        XCTAssertFalse(manager.copyImage(at: file, to: pasteboard))
        XCTAssertEqual(pasteboard.data(forType: .tiff), copied)
    }
}
