import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics

@available(macOS 12.3, *)
final class ScreenRecorder: NSObject, SCStreamOutput {
    
    static let shared = ScreenRecorder()
    
    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var display: CGDirectDisplayID?
    private var recordingURL: URL?
    private let writerQueue = DispatchQueue(label: "com.screenkit.writer")
    private var isRecording = false
    private var sessionStartTime: CMTime?
    
    func startRecording(region: CGRect) async throws {
        guard !isRecording else {
            throw ScreenRecorderError.alreadyRecording
        }
        
        // Find main display
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let mainDisplay = content.displays.first else {
            throw ScreenRecorderError.noDisplayFound
        }
        
        display = mainDisplay.displayID
        
        // Convert SwiftUI coordinates to macOS coordinates
        let flippedRegion = flipRegion(region, for: mainDisplay)
        
        // Create stream configuration
        let filter = SCContentFilter(display: mainDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = flippedRegion
        config.width = Int(flippedRegion.width)
        config.height = Int(flippedRegion.height)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        config.capturesAudio = false
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        config.queueDepth = 5
        
        // Setup AVAssetWriter
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        recordingURL = tempURL
        
        assetWriter = try AVAssetWriter(outputURL: tempURL, fileType: .mov)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: config.width,
            AVVideoHeightKey: config.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: config.width * config.height * 4
            ]
        ]
        
        videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        videoInput?.expectsMediaDataInRealTime = true
        
        guard let videoInput = videoInput,
              let assetWriter = assetWriter,
              assetWriter.canAdd(videoInput) else {
            throw ScreenRecorderError.writerSetupFailed
        }
        
        assetWriter.add(videoInput)
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: config.width,
            kCVPixelBufferHeightKey as String: config.height
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        // Create stream
        stream = SCStream(filter: filter, configuration: config, delegate: nil)
        
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: writerQueue)
        
        // Start recording
        try await stream?.startCapture()
        isRecording = true
    }
    
    func stopRecording() async throws -> URL {
        guard isRecording, let stream = stream else {
            throw ScreenRecorderError.notRecording
        }
        
        isRecording = false
        
        try await stream.stopCapture()
        self.stream = nil
        
        return try await withCheckedThrowingContinuation { continuation in
            writerQueue.async { [weak self] in
                guard let self = self,
                      let assetWriter = self.assetWriter,
                      let videoInput = self.videoInput else {
                    continuation.resume(throwing: ScreenRecorderError.writerNotAvailable)
                    return
                }
                
                videoInput.markAsFinished()
                
                assetWriter.finishWriting { [weak self] in
                    if let error = assetWriter.error {
                        continuation.resume(throwing: error)
                    } else if let url = self?.recordingURL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: ScreenRecorderError.noRecordingURL)
                    }
                    
                    self?.assetWriter = nil
                    self?.videoInput = nil
                    self?.pixelBufferAdaptor = nil
                    self?.recordingURL = nil
                    self?.sessionStartTime = nil
                }
            }
        }
    }
    
    @MainActor
    func captureScreenshot(region: CGRect) async throws -> URL {
        // Find main display
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let mainDisplay = content.displays.first else {
            throw ScreenRecorderError.noDisplayFound
        }
        
        // Convert SwiftUI coordinates to macOS coordinates
        let flippedRegion = flipRegion(region, for: mainDisplay)
        
        // Create configuration
        let filter = SCContentFilter(display: mainDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = flippedRegion
        config.width = Int(flippedRegion.width)
        config.height = Int(flippedRegion.height)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        
        // Save to Desktop
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let fileName = "Screenshot \(formatter.string(from: Date())).png"
        let destinationURL = desktopURL.appendingPathComponent(fileName)
        
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ScreenRecorderError.writerSetupFailed
        }
        
        try pngData.write(to: destinationURL)
        
        // Open in Finder
        NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
        
        return destinationURL
    }

    // MARK: - SCStreamOutput
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        writerQueue.async { [weak self] in
            guard let self = self,
                  let assetWriter = self.assetWriter,
                  let videoInput = self.videoInput else {
                return
            }
            
            if assetWriter.status == .unknown {
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: timestamp)
                self.sessionStartTime = timestamp
            }
            
            guard assetWriter.status == .writing,
                  videoInput.isReadyForMoreMediaData else {
                return
            }
            
            videoInput.append(sampleBuffer)
        }
    }
    
    // MARK: - Coordinate Conversion
    
    private func flipRegion(_ region: CGRect, for display: SCDisplay) -> CGRect {
        let displayFrame = display.frame
        let flippedY = displayFrame.height - region.origin.y - region.height
        return CGRect(
            x: region.origin.x,
            y: flippedY,
            width: region.width,
            height: region.height
        )
    }
}

enum ScreenRecorderError: LocalizedError {
    case alreadyRecording
    case noDisplayFound
    case writerSetupFailed
    case notRecording
    case writerNotAvailable
    case noRecordingURL
    
    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Recording is already in progress"
        case .noDisplayFound:
            return "No display found"
        case .writerSetupFailed:
            return "Failed to setup video writer"
        case .notRecording:
            return "No recording in progress"
        case .writerNotAvailable:
            return "Video writer is not available"
        case .noRecordingURL:
            return "Recording URL is not available"
        }
    }
}
