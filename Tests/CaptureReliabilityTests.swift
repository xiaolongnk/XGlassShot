import XCTest
import ImageIO
import CoreGraphics
@preconcurrency import AVFoundation
@testable import CaptureCore

final class CaptureReliabilityTests: XCTestCase {
    func testSelectionCannotEscapeItsOwnDisplayWhenDraggingAcrossAnEdge() throws {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let selection = CaptureGeometry.selection(start: CGPoint(x: 1800, y: 900), end: CGPoint(x: 2400, y: 1200), bounds: bounds)
        XCTAssertEqual(selection, CGRect(x: 1800, y: 900, width: 120, height: 180))
        XCTAssertEqual(try CaptureGeometry.region(selection, in: bounds), selection)
        XCTAssertEqual(CaptureGeometry.selection(start: CGPoint(x: -50, y: -50), end: CGPoint(x: -10, y: -10), bounds: bounds), .zero)
    }

    func testDisplayLocalRegionDoesNotDependOnDesktopOriginOrScale() throws {
        let localRegion = CGRect(x: 100, y: 120, width: 300, height: 180)
        for desktopFrame in [CGRect(x: -1920, y: 200, width: 1920, height: 1080),
                             CGRect(x: 2304, y: -1080, width: 1920, height: 1080)] {
            XCTAssertEqual(try CaptureGeometry.region(localRegion, in: CGRect(origin: .zero, size: desktopFrame.size)), localRegion)
        }
    }

    func testPreviewKeepsRetinaDetailWithoutLoadingTheFullImage() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("large.png")
        let context = try XCTUnwrap(CGContext(data: nil, width: 2400, height: 1200, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 0.1, green: 0.4, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 2400, height: 1200))
        let image = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let thumbnail = try XCTUnwrap(CaptureThumbnail.image(at: url))
        XCTAssertEqual(thumbnail.width, 1200)
        XCTAssertEqual(thumbnail.height, 600)
    }

    func testLegacyKeyIsRemovedWithoutChangingCaptureSettings() throws {
        let suite = "GlassCapTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("test-only-placeholder", forKey: "anthropicAPIKey")
        defaults.set("captures", forKey: "currentPrefix")
        LegacySettings.removeCloudAIKey(from: defaults)
        XCTAssertNil(defaults.object(forKey: "anthropicAPIKey"))
        XCTAssertEqual(defaults.string(forKey: "currentPrefix"), "captures")
    }

    func testCancelledActionDoesNotReachNextScreenshot() {
        var session = CaptureSession()
        XCTAssertTrue(session.begin(.screenshot(.copyText)))
        session.cancelSelection()
        XCTAssertTrue(session.begin(.screenshot(.none)))
        XCTAssertEqual(session.confirm(), .screenshot(.none))
    }

    func testBusyCaptureCannotReplaceActionOrStartAnotherRecording() {
        var session = CaptureSession()
        XCTAssertTrue(session.begin(.screenshot(.beautify)))
        XCTAssertFalse(session.begin(.screenshot(.copyText)))
        XCTAssertEqual(session.confirm(), .screenshot(.beautify))
        XCTAssertFalse(session.begin(.recording))
        session.finish()
        XCTAssertTrue(session.begin(.recording))
        XCTAssertEqual(session.confirm(), .recording)
        session.recordingStarted()
        XCTAssertFalse(session.begin(.screenshot(.none)))
        XCTAssertTrue(session.beginStop())
        XCTAssertFalse(session.beginStop())
        session.finish()
        XCTAssertTrue(session.begin(.screenshot(.none)))
    }

    func testMissingDisplayNeverFallsBackToAnotherScreen() throws {
        XCTAssertEqual(try CaptureGeometry.displayID(expected: 2, available: [1, 2]), 2)
        XCTAssertThrowsError(try CaptureGeometry.displayID(expected: 3, available: [1, 2]))
        XCTAssertThrowsError(try CaptureGeometry.displayID(expected: nil, available: [1]))
    }

    func testInvalidRegionsCannotBecomeFullScreen() throws {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let valid = CGRect(x: 10, y: 20, width: 100, height: 80)
        XCTAssertEqual(try CaptureGeometry.region(valid, in: bounds), valid)
        for rect in [CGRect.zero, CGRect(x: -10, y: 0, width: 100, height: 50),
                     CGRect(x: 2000, y: 0, width: 50, height: 50),
                     CGRect(x: 0, y: 0, width: 2000, height: 50),
                     CGRect(x: CGFloat.infinity, y: 0, width: 50, height: 50)] {
            XCTAssertThrowsError(try CaptureGeometry.region(rect, in: bounds))
        }
    }

    func testSameTimeCapturesHaveUniqueSafeNames() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let names = (0..<100).map { _ in CaptureFileStore.filename(prefix: "../test:tag", extension: "png", date: date) }
        XCTAssertEqual(Set(names).count, 100)
        XCTAssertFalse(names.contains { $0.contains("/") || $0.contains(":") })
    }

    func testScreenshotNeverOverwritesExistingFile() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let target = directory.appendingPathComponent("capture.png")
        try Data("original".utf8).write(to: target)
        XCTAssertThrowsError(try CaptureFileStore.writeScreenshot(Data("new".utf8), to: target))
        XCTAssertEqual(try Data(contentsOf: target), Data("original".utf8))
    }

    func testRecordingCollisionAndFailurePreserveBothFiles() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("recover.mov")
        let target = directory.appendingPathComponent("existing.mov")
        try Data("recording".utf8).write(to: source)
        try Data("original".utf8).write(to: target)
        XCTAssertThrowsError(try CaptureFileStore.copyRecording(from: source, to: target))
        XCTAssertEqual(try Data(contentsOf: source), Data("recording".utf8))
        XCTAssertEqual(try Data(contentsOf: target), Data("original".utf8))
        XCTAssertThrowsError(try CaptureFileStore.copyRecording(from: source, to: directory.appendingPathComponent("missing/new.mov")))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        let saved = directory.appendingPathComponent("saved.mov")
        try CaptureFileStore.copyRecording(from: source, to: saved)
        XCTAssertEqual(try Data(contentsOf: saved), Data("recording".utf8))
    }

    func testApprovedRecordingReplacementKeepsRecoverySource() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("recovery.mov")
        let destination = directory.appendingPathComponent("saved.mov")
        try Data("recording".utf8).write(to: source)
        try Data("original".utf8).write(to: destination)
        try CaptureFileStore.replaceRecording(from: source, to: destination)
        XCTAssertEqual(try Data(contentsOf: destination), Data("recording".utf8))
        XCTAssertEqual(try Data(contentsOf: source), Data("recording".utf8))
    }

    func testSavingRecordingToItsOwnRecoveryPathKeepsTheFile() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("recovery.mov")
        try Data("recording".utf8).write(to: source)
        try CaptureFileStore.replaceRecording(from: source, to: source)
        XCTAssertEqual(try Data(contentsOf: source), Data("recording".utf8))
    }

    func testWriterWithoutFramesFailsAndCanRestart() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let writer = RecordingWriter()
        try await writer.prepare(url: directory.appendingPathComponent("first.mov"), bitrateFactor: 4)
        do { _ = try await writer.finish(); XCTFail("An empty recording must not succeed") } catch {}
        try await writer.prepare(url: directory.appendingPathComponent("second.mov"), bitrateFactor: 4)
        await writer.cancel()
    }

    func testWriterProducesPlayableVideoAndCanRestart() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let writer = RecordingWriter()
        let output = directory.appendingPathComponent("recording.mov")
        try await writer.prepare(url: output, bitrateFactor: 4)
        for index in 0..<12 {
            let sample = try videoSample(frame: index)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                writer.queue.async {
                    do { try writer.append(sample); continuation.resume() }
                    catch { continuation.resume(throwing: error) }
                }
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let completed = try await writer.finish()
        XCTAssertEqual(completed, output)
        let asset = AVURLAsset(url: output)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertEqual(tracks.count, 1)
        let duration = try await asset.load(.duration)
        XCTAssertGreaterThan(duration.seconds, 0)
        try await writer.prepare(url: directory.appendingPathComponent("next.mov"), bitrateFactor: 4)
        await writer.cancel()
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func videoSample(frame: Int) throws -> CMSampleBuffer {
        var buffer: CVPixelBuffer?
        XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary, &buffer), kCVReturnSuccess)
        let pixelBuffer = try XCTUnwrap(buffer)
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        memset(CVPixelBufferGetBaseAddress(pixelBuffer), 64, CVPixelBufferGetDataSize(pixelBuffer))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        var format: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &format)
        var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(value: Int64(frame), timescale: 30), decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
            formatDescription: try XCTUnwrap(format), sampleTiming: &timing, sampleBufferOut: &sample)
        return try XCTUnwrap(sample)
    }
}
