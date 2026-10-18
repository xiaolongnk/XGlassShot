import XCTest
@testable import xglassshot

final class CaptureDestinationTests: XCTestCase {
    func testCustomDirectoryWithUnicodeSpacesAndPrefixCreatesUniqueNames() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("项目 A/截图")
        let one = try CaptureDestination.resolve(output: nil, directory: folder.path, prefix: "设计 review")
        let two = try CaptureDestination.resolve(output: nil, directory: folder.path, prefix: "设计 review")
        XCTAssertEqual(one.deletingLastPathComponent().path, folder.path)
        XCTAssertTrue(one.lastPathComponent.hasPrefix("设计 review_"))
        XCTAssertEqual(one.pathExtension, "png")
        XCTAssertNotEqual(one, two)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.path))
    }
    func testExactOutputDoesNotCreateParentsOrChangeName() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let output = folder.appendingPathComponent("exact.png")
        XCTAssertEqual(try CaptureDestination.resolve(output: output.path, directory: nil, prefix: nil), output)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
    }
    func testConflictingOptionsFailWithoutCreatingDirectory() {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try CaptureDestination.resolve(output: "/tmp/exact.png", directory: folder.path, prefix: nil))
        XCTAssertThrowsError(try CaptureDestination.resolve(output: "/tmp/exact.png", directory: nil, prefix: "tag"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
    }
    func testUnsafePrefixCannotEscapeDirectory() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let output = try CaptureDestination.resolve(output: nil, directory: folder.path, prefix: "../tag:\n\0")
        XCTAssertEqual(output.deletingLastPathComponent().path, folder.path)
        XCTAssertFalse(output.lastPathComponent.contains(":"))
        XCTAssertFalse(output.lastPathComponent.contains("\n"))
    }
    func testEmptyPrefixAndRecordingExtension() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let output = try CaptureDestination.resolve(output: nil, directory: folder.path, prefix: "", recording: true)
        XCTAssertTrue(output.lastPathComponent.first?.isNumber == true)
        XCTAssertEqual(output.pathExtension, "mov")
    }
}

final class CaptureRegionTests: XCTestCase {
    func testRegionUsesLocalTopLeftCoordinates() throws {
        XCTAssertEqual(try CaptureRegion.parse("100,120,320,200", size: CGSize(width: 1920, height: 1080)), CGRect(x: 100, y: 120, width: 320, height: 200))
        XCTAssertEqual(try CaptureRegion.parse(nil, size: CGSize(width: 1920, height: 1080)), CGRect(x: 0, y: 0, width: 1920, height: 1080))
    }
    func testInvalidRegionFailsBeforeRecordingDaemonStarts() {
        for value in ["-1,0,20,20", "0,0,0,20", "1900,0,50,20", "0,0,1", "x,0,2,2"] {
            XCTAssertThrowsError(try CaptureRegion.parse(value, size: CGSize(width: 1920, height: 1080)))
        }
    }
}
