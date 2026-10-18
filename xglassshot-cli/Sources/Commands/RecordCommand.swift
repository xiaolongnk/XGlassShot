import ArgumentParser
import AppKit
import ScreenCaptureKit
import AVFoundation
import Foundation

// Alias to avoid shadowing by ArgumentParser's static exit(_:)
private func processExit(_ code: Int32) -> Never { Foundation.exit(code) }

// MARK: - State file

private let stateFilePath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".glasscap-cli-state.json").path

private struct RecordingState: Codable {
    var recording: Bool
    var output_path: String
    var start_time: Double
    var daemon_pid: Int32
}

private func readState() -> RecordingState? {
    guard let data = FileManager.default.contents(atPath: stateFilePath) else { return nil }
    return try? JSONDecoder().decode(RecordingState.self, from: data)
}

private func writeState(_ state: RecordingState) throws {
    let data = try JSONEncoder().encode(state)
    try data.write(to: URL(fileURLWithPath: stateFilePath))
}

private func removeState() {
    try? FileManager.default.removeItem(atPath: stateFilePath)
}

// MARK: - record (parent command)

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct RecordCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "record",
        abstract: "Start or stop screen recording.",
        subcommands: [RecordStart.self, RecordStop.self]
    )
}

// MARK: - record start

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct RecordStart: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start a screen recording in the background."
    )

    @Option(name: .long, help: "Screen index (from `xglassshot screens`). Defaults to primary screen.")
    var screen: Int = 0

    @Option(name: .long, help: "Capture region as x,y,w,h in integer points (top-left origin). Defaults to full screen.")
    var region: String?

    @Option(name: .long, help: "Recording quality: low or high. Defaults to high.")
    var quality: String = "high"

    @Option(name: .long, help: "Output file path. Defaults to ~/Movies/XGlassShot/xglassshot-<timestamp>.mov.")
    var output: String?

    @Option(name: .long, help: "Destination directory for a unique recording filename. Cannot be combined with --output.")
    var directory: String?

    @Option(name: .long, help: "Automatic filename prefix; default: xglassshot. Cannot be combined with --output.")
    var prefix: String?

    func run() async throws {
        do { try await start() }
        catch { JSONOutput.failure(error.localizedDescription) }
    }

    private func start() async throws {
        guard ["low", "high"].contains(quality) else { JSONOutput.failure("Invalid --quality. Expected low or high.") }
        if output != nil && (directory != nil || prefix != nil) { throw CaptureDestination.DestinationError.conflictingOptions }
        PermissionCheck.requireScreenRecording()

        if let existing = readState(), existing.recording {
            JSONOutput.failure("A recording is already in progress (PID \(existing.daemon_pid)). Run `xglassshot record stop` first.")
        }

        let screens = NSScreen.screens
        guard screen >= 0, screen < screens.count else { JSONOutput.failure("Screen index is out of range. Use `xglassshot screens` to list displays.") }
        _ = try CaptureRegion.parse(region, size: screens[screen].frame.size)

        // Resolve output path
        let outputURL = try CaptureDestination.resolve(output: output, directory: directory, prefix: prefix, recording: true)
        guard !FileManager.default.fileExists(atPath: outputURL.path) else { JSONOutput.failure("Output already exists. No recording was started.") }

        // Build daemon arguments
        let execPath = CommandLine.arguments[0]
        var args: [String] = ["_record-daemon", "--output", outputURL.path,
                              "--screen", "\(screen)", "--quality", quality]
        if let r = region { args += ["--region", r] }

        // Spawn daemon detached
        let process = Process()
        process.executableURL = URL(fileURLWithPath: execPath)
        process.arguments = args

        // Detach: no pipe, no parent wait
        process.standardInput  = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError  = FileHandle.nullDevice

        try process.run()
        let pid = process.processIdentifier

        // Give it 0.5s to start
        try await Task.sleep(nanoseconds: 500_000_000)

        // Verify it is alive
        guard kill(pid, 0) == 0 else {
            JSONOutput.failure("Daemon process (PID \(pid)) failed to start.")
        }

        // Persist state
        let state = RecordingState(
            recording: true,
            output_path: outputURL.path,
            start_time: Date().timeIntervalSince1970,
            daemon_pid: pid
        )
        try writeState(state)

        JSONOutput.success(RecordStartResponse(status: "recording", output: outputURL.path))
    }

}

// MARK: - record stop

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct RecordStop: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop the current screen recording."
    )

    func run() async throws {
        guard let state = readState(), state.recording else {
            JSONOutput.failure("No recording is in progress.")
        }

        let pid = state.daemon_pid
        let outputPath = state.output_path

        // Signal daemon to stop
        if kill(pid, SIGTERM) != 0 {
            removeState()
            JSONOutput.failure("Failed to signal recording daemon (PID \(pid)). It may have already exited.")
        }

        // Wait for the output file to stop growing (daemon is finalising)
        let outputURL = URL(fileURLWithPath: outputPath)
        let deadline = Date().addingTimeInterval(10)
        var lastSize: Int64 = -1
        var stableCount = 0
        var mediaDuration: Double?

        while Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000) // 100 ms

            let attrs = try? FileManager.default.attributesOfItem(atPath: outputPath)
            let size = (attrs?[.size] as? Int64) ?? 0

            if size > 0 && size == lastSize {
                stableCount += 1
                if stableCount >= 3 {
                    let asset = AVURLAsset(url: outputURL)
                    if let duration = try? await asset.load(.duration), duration.seconds.isFinite, duration.seconds > 0,
                       let tracks = try? await asset.loadTracks(withMediaType: .video), !tracks.isEmpty {
                        mediaDuration = duration.seconds
                        break
                    }
                }
            } else {
                stableCount = 0
            }
            lastSize = size
        }

        removeState()

        guard let duration = mediaDuration else {
            JSONOutput.failure("Recording did not finalize into a playable video. Any output was retained at \(outputPath).")
        }
        JSONOutput.success(RecordStopResponse(path: outputURL.path, duration_s: duration))
    }
}

// MARK: - _record-daemon (hidden background worker)

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct RecordDaemon: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "_record-daemon",
        abstract: "Internal background recording daemon. Do not call directly.",
        shouldDisplay: false
    )

    @Option(name: .long, help: "Output file path.")
    var output: String

    @Option(name: .long, help: "Screen index.")
    var screen: Int = 0

    @Option(name: .long, help: "Capture region as x,y,w,h.")
    var region: String?

    @Option(name: .long, help: "Quality: low or high.")
    var quality: String = "high"

    func run() async throws {
        let nsScreens = NSScreen.screens
        guard screen >= 0 && screen < nsScreens.count else {
            processExit(1)
        }
        let nsScreen = nsScreens[screen]

        let captureRegion: CGRect
        if let r = region {
            captureRegion = parseRegion(r, screen: nsScreen)
        } else {
            captureRegion = CGRect(origin: .zero, size: nsScreen.frame.size)
        }

        let scaleFactor: CGFloat = (quality == "low") ? 1.0 : 2.0
        let outputURL = URL(fileURLWithPath: (output as NSString).expandingTildeInPath)

        // Find SCDisplay
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let targetDisplay = findDisplay(for: nsScreen, in: content.displays) else { processExit(1) }

        let displayRegion = convertToDisplayCoordinates(captureRegion, screen: nsScreen, display: targetDisplay)
        let captureWidth  = Int(ceil(captureRegion.width  * scaleFactor))
        let captureHeight = Int(ceil(captureRegion.height * scaleFactor))

        // Set up SCStream + AVAssetWriter
        let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect            = displayRegion
        config.width                 = captureWidth
        config.height                = captureHeight
        config.pixelFormat           = kCVPixelFormatType_32BGRA
        config.showsCursor           = true
        config.capturesAudio         = false
        config.minimumFrameInterval  = CMTime(value: 1, timescale: 60)
        config.queueDepth            = 5

        let session = DaemonRecordingSession(outputURL: outputURL, quality: quality)
        let stream = SCStream(filter: filter, configuration: config, delegate: session)
        try stream.addStreamOutput(session, type: .screen, sampleHandlerQueue: session.writerQueue)
        session.stream = stream

        try await stream.startCapture()

        // Install SIGTERM handler — stops and finalises the recording then exits
        let src = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        signal(SIGTERM, SIG_IGN)
        // main.swift already runs the main run loop. Suspending this async task keeps
        // the stream and signal source alive without calling dispatch_main off-thread.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            src.setEventHandler {
                src.cancel()
                Task {
                    await session.stopAndFinish()
                    continuation.resume()
                }
            }
            src.resume()
        }
        src.cancel()
    }

    // MARK: Helpers

    private func parseRegion(_ str: String, screen: NSScreen) -> CGRect {
        let parts = str.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 4,
              let x = Int(parts[0]), let y = Int(parts[1]),
              let w = Int(parts[2]), let h = Int(parts[3]),
              w > 0, h > 0 else {
            JSONOutput.failure("Invalid region. Expected x,y,w,h with positive dimensions.")
        }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func findDisplay(for screen: NSScreen, in displays: [SCDisplay]) -> SCDisplay? {
        guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return displays.first(where: { $0.displayID == num.uint32Value })
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

// MARK: - DaemonRecordingSession

final class DaemonRecordingSession: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    let writerQueue = DispatchQueue(label: "com.xglassshot.daemon.writer")
    var stream: SCStream?

    private let outputURL: URL
    private let quality: String
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var writerConfigured = false
    private var isRecording = false
    private var sessionStartTime: CMTime?

    init(outputURL: URL, quality: String) {
        self.outputURL = outputURL
        self.quality   = quality
        super.init()

        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        } catch {
            // Fatal for the daemon
            processExit(1)
        }
        isRecording = true
    }

    func stopAndFinish() async {
        isRecording = false
        if let s = stream {
            try? await s.stopCapture()
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writerQueue.async { [weak self] in
                guard let self = self, let writer = self.assetWriter else {
                    continuation.resume()
                    return
                }
                guard writer.status == .writing else {
                    continuation.resume()
                    return
                }
                self.videoInput?.markAsFinished()
                writer.finishWriting { continuation.resume() }
            }
        }
    }

    // MARK: SCStreamDelegate

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        isRecording = false
    }

    // MARK: SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, isRecording else { return }
        guard CMSampleBufferGetNumSamples(sampleBuffer) > 0,
              CMSampleBufferIsValid(sampleBuffer),
              CMSampleBufferGetImageBuffer(sampleBuffer) != nil else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        writerQueue.async { [weak self] in
            guard let self = self, self.isRecording, let writer = self.assetWriter else { return }

            if !self.writerConfigured {
                guard self.configureWriter(from: sampleBuffer) else { return }
            }

            guard let input = self.videoInput else { return }

            if writer.status == .unknown {
                writer.startWriting()
                writer.startSession(atSourceTime: timestamp)
                self.sessionStartTime = timestamp
            }

            guard writer.status == .writing, input.isReadyForMoreMediaData else { return }
            input.append(sampleBuffer)
        }
    }

    // MARK: Private

    private func configureWriter(from sampleBuffer: CMSampleBuffer) -> Bool {
        guard let writer = assetWriter,
              let fmt = CMSampleBufferGetFormatDescription(sampleBuffer) else { return false }

        let dims   = CMVideoFormatDescriptionGetDimensions(fmt)
        let width  = (Int(dims.width)  + 1) & ~1
        let height = (Int(dims.height) + 1) & ~1
        let isHigh = (quality == "high")
        let bitrate = width * height * (isHigh ? 8 : 4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitrate,
                AVVideoProfileLevelKey: isHigh
                    ? AVVideoProfileLevelH264HighAutoLevel
                    : AVVideoProfileLevelH264MainAutoLevel
            ]
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true
        input.transform = .identity

        guard writer.canAdd(input) else { return false }
        writer.add(input)
        videoInput      = input
        writerConfigured = true
        return true
    }
}
