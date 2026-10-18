import Foundation
import AVFoundation

/// All writer state, including failure and finalization, belongs to this queue.
nonisolated final class RecordingWriter: @unchecked Sendable {
    let queue = DispatchQueue(label: "com.glasscap.writer")
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var url: URL?
    private var bitrateFactor = 4
    private var finishing = false

    func prepare(url: URL, bitrateFactor: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    guard self.writer == nil else { throw RecordingWriterError.busy }
                    self.writer = try AVAssetWriter(outputURL: url, fileType: .mov)
                    self.url = url
                    self.bitrateFactor = bitrateFactor
                    continuation.resume()
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    /// Called directly on the stream's sample-handler queue; never re-enqueues frames.
    func append(_ sample: CMSampleBuffer) throws {
        dispatchPrecondition(condition: .onQueue(queue))
        guard !finishing, let writer else { return }
        guard CMSampleBufferIsValid(sample), CMSampleBufferGetNumSamples(sample) > 0,
              CMSampleBufferGetImageBuffer(sample) != nil else { return }
        if input == nil {
            guard let format = CMSampleBufferGetFormatDescription(sample) else { return }
            let dimensions = CMVideoFormatDescriptionGetDimensions(format)
            let width = (Int(dimensions.width) + 1) & ~1
            let height = (Int(dimensions.height) + 1) & ~1
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width, AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: width * height * bitrateFactor]
            ])
            input.expectsMediaDataInRealTime = true
            guard writer.canAdd(input) else { throw RecordingWriterError.setupFailed }
            writer.add(input)
            self.input = input
        }
        if writer.status == .unknown {
            guard writer.startWriting() else { throw writer.error ?? RecordingWriterError.setupFailed }
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
        }
        guard writer.status == .writing else { throw writer.error ?? RecordingWriterError.writeFailed }
        guard let input, input.isReadyForMoreMediaData else { return }
        guard input.append(sample) else { throw writer.error ?? RecordingWriterError.writeFailed }
    }

    func finish() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard !self.finishing else {
                    continuation.resume(throwing: RecordingWriterError.busy)
                    return
                }
                guard let writer = self.writer, let url = self.url else {
                    continuation.resume(throwing: RecordingWriterError.noFrames)
                    return
                }
                guard writer.status == .writing else {
                    let error = writer.error ?? RecordingWriterError.noFrames
                    if writer.status == .unknown { writer.cancelWriting() }
                    self.reset()
                    continuation.resume(throwing: error)
                    return
                }
                self.finishing = true
                self.input?.markAsFinished()
                writer.finishWriting {
                    self.queue.async {
                        self.reset()
                        if writer.status == .completed { continuation.resume(returning: url) }
                        else { continuation.resume(throwing: writer.error ?? RecordingWriterError.writeFailed) }
                    }
                }
            }
        }
    }

    func cancel() async {
        await withCheckedContinuation { continuation in
            queue.async {
                if let writer = self.writer, writer.status == .writing || writer.status == .unknown {
                    writer.cancelWriting()
                }
                self.reset()
                continuation.resume()
            }
        }
    }

    private func reset() {
        writer = nil
        input = nil
        url = nil
        finishing = false
    }
}

nonisolated enum RecordingWriterError: LocalizedError {
    case busy, setupFailed, writeFailed, noFrames
    var errorDescription: String? {
        switch self {
        case .busy: return "A recording is already being prepared or saved."
        case .setupFailed: return "The video encoder could not start. Please try a smaller capture area."
        case .writeFailed: return "The recording could not be written. Check available disk space."
        case .noFrames: return "No video frames were captured. Please record for a little longer."
        }
    }
}
