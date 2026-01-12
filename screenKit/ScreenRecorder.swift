import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics
import AppKit

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

    func startRecording(region: CGRect, screen: NSScreen) async throws {
        guard !isRecording else {
            throw ScreenRecorderError.alreadyRecording
        }

        // Find the SCDisplay matching the NSScreen
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let targetDisplay = findDisplay(for: screen, in: content.displays) else {
            throw ScreenRecorderError.noDisplayFound
        }

        display = targetDisplay.displayID

        // Convert selection rect (relative to screen) to display coordinates
        let displayRegion = convertToDisplayCoordinates(region, screen: screen, display: targetDisplay)

        // Validate region dimensions
        guard displayRegion.width >= 1 && displayRegion.height >= 1 else {
            throw ScreenRecorderError.writerSetupFailed
        }

        // Create stream configuration
        let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = displayRegion
        config.width = Int(displayRegion.width)
        config.height = Int(displayRegion.height)
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
    func captureScreenshot(region: CGRect, screen: NSScreen) async throws -> URL {
        // Find the SCDisplay matching the NSScreen
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let targetDisplay = findDisplay(for: screen, in: content.displays) else {
            throw ScreenRecorderError.noDisplayFound
        }

        // Convert selection rect (relative to screen) to display coordinates
        let displayRegion = convertToDisplayCoordinates(region, screen: screen, display: targetDisplay)

        // Validate region dimensions
        guard displayRegion.width >= 1 && displayRegion.height >= 1 else {
            throw ScreenRecorderError.writerSetupFailed
        }

        // Create configuration
        let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = displayRegion
        config.width = Int(displayRegion.width)
        config.height = Int(displayRegion.height)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

        let bitmapRep = NSBitmapImageRep(cgImage: image)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ScreenRecorderError.writerSetupFailed
        }

        // Use NSSavePanel for sandbox-compatible file saving
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let fileName = "Screenshot \(formatter.string(from: Date())).png"

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = fileName
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Screenshot"
        savePanel.message = "Choose a location to save your screenshot"

        let response = await savePanel.begin()
        guard response == .OK, let destinationURL = savePanel.url else {
            throw ScreenRecorderError.saveCancelled
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
    
    // MARK: - Display Matching

    /// Find the SCDisplay that matches the given NSScreen
    private func findDisplay(for screen: NSScreen, in displays: [SCDisplay]) -> SCDisplay? {
        // Get the CGDirectDisplayID from NSScreen
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return displays.first
        }

        // Find matching SCDisplay by displayID
        return displays.first { $0.displayID == screenNumber } ?? displays.first
    }

    // MARK: - Coordinate Conversion

    /// Convert selection rect from screen-relative SwiftUI coordinates to SCDisplay sourceRect coordinates
    /// - Parameters:
    ///   - region: The selection rect in SwiftUI coordinates (origin top-left, relative to window)
    ///   - screen: The NSScreen where selection was made
    ///   - display: The target SCDisplay for capture
    /// - Returns: CGRect for SCStreamConfiguration.sourceRect (origin top-left)
    private func convertToDisplayCoordinates(_ region: CGRect, screen: NSScreen, display: SCDisplay) -> CGRect {
        // SCStreamConfiguration.sourceRect uses top-left origin (same as SwiftUI)
        // The selection rect is already in the correct coordinate system
        // Just pass it through directly
        return CGRect(
            x: region.origin.x,
            y: region.origin.y,
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
    case saveCancelled

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
        case .saveCancelled:
            return "Save was cancelled"
        }
    }
}
