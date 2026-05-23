import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics
import AppKit

@available(macOS 12.3, *)
final class ScreenRecorder: NSObject, SCStreamOutput, SCStreamDelegate {

    static let shared = ScreenRecorder()

    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var display: CGDirectDisplayID?
    private var recordingURL: URL?
    private let writerQueue = DispatchQueue(label: "com.glasscap.writer")
    private var isRecording = false
    private var sessionStartTime: CMTime?
    private var writerConfigured = false

    private var currentQuality: CaptureQuality = .low

    func startRecording(region: CGRect, screen: NSScreen, quality: CaptureQuality) async throws {
        guard !isRecording else {
            throw ScreenRecorderError.alreadyRecording
        }

        currentQuality = quality

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

        // Apply quality scale factor to capture dimensions
        // We use the original region (points) * scaleFactor (1x or 2x)
        let scaleFactor = quality.scaleFactor
        let captureWidth = Int(ceil(region.width * scaleFactor))
        let captureHeight = Int(ceil(region.height * scaleFactor))

        print("Recording at \(quality.description): \(captureWidth)x\(captureHeight)")

        // Create stream configuration
        let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = displayRegion
        config.width = captureWidth
        config.height = captureHeight
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        config.capturesAudio = false
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        config.queueDepth = 5

        // Setup recording URL (writer will be configured when first frame arrives)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        recordingURL = tempURL

        assetWriter = try AVAssetWriter(outputURL: tempURL, fileType: .mov)
        writerConfigured = false

        // Create stream with delegate to catch errors
        stream = SCStream(filter: filter, configuration: config, delegate: self)

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: writerQueue)

        // Start recording
        try await stream?.startCapture()
        isRecording = true
    }

    /// Configure the AVAssetWriter based on actual frame dimensions from the first sample buffer
    private func configureWriter(from sampleBuffer: CMSampleBuffer) -> Bool {
        guard let assetWriter = assetWriter,
              let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return false
        }

        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        // Ensure even dimensions for H.264
        let width = (Int(dimensions.width) + 1) & ~1
        let height = (Int(dimensions.height) + 1) & ~1

        // Calculate bitrate based on quality setting
        let bitrate = width * height * currentQuality.videoBitrateFactor

        print("Configuring writer: \(width)x\(height) @ \(bitrate / 1_000_000)Mbps (\(currentQuality.description))")

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitrate,
                AVVideoProfileLevelKey: currentQuality == .high ? AVVideoProfileLevelH264HighAutoLevel : AVVideoProfileLevelH264MainAutoLevel
            ]
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true

        // Set transform to handle coordinate system
        input.transform = CGAffineTransform.identity

        guard assetWriter.canAdd(input) else {
            print("Cannot add video input to asset writer")
            return false
        }

        assetWriter.add(input)
        videoInput = input
        writerConfigured = true

        return true
    }
    
    func stopRecording() async throws -> URL {
        // Check if we have an active recording (either flag or writer exists)
        guard isRecording || assetWriter != nil else {
            throw ScreenRecorderError.notRecording
        }

        isRecording = false

        // Stop the stream capture (ignore errors if already stopped)
        if let stream = stream {
            do {
                try await stream.stopCapture()
            } catch {
                // Stream might have already stopped due to an error - that's OK
                print("Stream stop warning (may be expected): \(error.localizedDescription)")
            }
            self.stream = nil
        }

        // Finish writing the video file
        return try await withCheckedThrowingContinuation { continuation in
            writerQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ScreenRecorderError.writerNotAvailable)
                    return
                }

                let url = self.recordingURL
                guard let assetWriter = self.assetWriter else {
                    // Clean up and return error
                    self.cleanupRecordingState()
                    continuation.resume(throwing: ScreenRecorderError.writerNotAvailable)
                    return
                }

                // Check if writer actually started
                if assetWriter.status != .writing {
                    // Writer never started or failed
                    if assetWriter.status != .cancelled {
                        assetWriter.cancelWriting()
                    }
                    self.cleanupRecordingState()
                    continuation.resume(throwing: ScreenRecorderError.noFramesCaptured)
                    return
                }

                self.videoInput?.markAsFinished()

                assetWriter.finishWriting {
                    if let error = assetWriter.error {
                        self.cleanupRecordingState()
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        self.cleanupRecordingState()
                        continuation.resume(returning: url)
                    } else {
                        self.cleanupRecordingState()
                        continuation.resume(throwing: ScreenRecorderError.noRecordingURL)
                    }
                }
            }
        }
    }

    private func cleanupRecordingState() {
        assetWriter = nil
        videoInput = nil
        recordingURL = nil
        sessionStartTime = nil
        writerConfigured = false
    }
    
    @MainActor
    func captureScreenshot(region: CGRect, annotations: [CGRect], screen: NSScreen, quality: CaptureQuality) async throws -> URL {
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

        // Apply quality scale factor to capture dimensions
        // We use the original region (points) * scaleFactor (1x or 2x)
        let scaleFactor = quality.scaleFactor
        let captureWidth = Int(ceil(region.width * scaleFactor))
        let captureHeight = Int(ceil(region.height * scaleFactor))

        print("Screenshot at \(quality.description): \(captureWidth)x\(captureHeight)")

        // Create configuration
        let filter = SCContentFilter(display: targetDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = displayRegion
        config.width = captureWidth
        config.height = captureHeight
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        if #available(macOS 14.2, *) {
            config.showsRecordingIndicator = false
        }

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

        
        // Apply outline if configured
        var finalImage = image
        if StorageManager.shared.addScreenshotOutline {
            if let outlinedImage = applyOutline(to: image) {
                finalImage = outlinedImage
            }
        }
        
        // Draw annotations
        if !annotations.isEmpty {
            if let annotatedImage = drawAnnotations(on: finalImage, annotations: annotations, sourceRect: displayRegion, scaleFactor: scaleFactor) {
                finalImage = annotatedImage
            }
        }

        // Convert to PNG data first (deep copy/serialization)
        let bitmapRep = NSBitmapImageRep(cgImage: finalImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ScreenRecorderError.writerSetupFailed
        }

        // Copy to clipboard using the clean data-backed NSImage
        if let clipboardImage = NSImage(data: pngData) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([clipboardImage])
        }

        // Use StorageManager for silent auto-save
        let prefix = ShortcutsManager.shared.currentPrefix
        let destinationURL = try await StorageManager.shared.saveScreenshot(data: pngData, prefix: prefix)

        // Show visual flash feedback
        StorageManager.shared.showVisualFlash()

        return destinationURL
    }

    // MARK: - SCStreamDelegate

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error.localizedDescription)")
        // Mark as not recording so stopRecording handles it gracefully
        isRecording = false
    }

    // MARK: - SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, isRecording else { return }

        // Check if this is a valid video frame
        guard CMSampleBufferGetNumSamples(sampleBuffer) > 0,
              CMSampleBufferIsValid(sampleBuffer),
              CMSampleBufferGetImageBuffer(sampleBuffer) != nil else {
            return
        }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        writerQueue.async { [weak self] in
            guard let self = self,
                  self.isRecording,
                  let assetWriter = self.assetWriter else {
                return
            }

            // Configure writer on first frame if not yet configured
            if !self.writerConfigured {
                if !self.configureWriter(from: sampleBuffer) {
                    print("Failed to configure writer")
                    return
                }
            }

            guard let videoInput = self.videoInput else { return }

            if assetWriter.status == .unknown {
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: timestamp)
                self.sessionStartTime = timestamp
                print("Recording started - writing first frame")
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
        // Key is "NSScreenNumber", value is NSNumber (which holds a UInt32)
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            print("Could not find NSScreenNumber for screen: \(screen)")
            return displays.first
        }
        
        let displayID = screenNumber.uint32Value
        
        // Find matching SCDisplay by displayID
        if let match = displays.first(where: { $0.displayID == displayID }) {
            return match
        }
        
        print("No SCDisplay found matching ID: \(displayID). Available: \(displays.map { $0.displayID })")
        
        // Fallback: Geometry matching (if exact ID fails)
        // Check if any display frame matches the screen frame (allowing for some rounding errors)
        // SCDisplay frame is in global coordinates, same as NSScreen.frame (usually)
        // Note: NSScreen.frame has (0,0) at bottom-left of primary, SCDisplay might differ in coordinate space origin?
        // Actually SCDisplay frame is usually top-left based. NSScreen is bottom-left.
        // Let's stick to ID matching as primary. If that fails, just return first as fallback.
        
        return displays.first
    }

    // MARK: - Coordinate Conversion

    /// Convert selection rect from screen-relative SwiftUI coordinates to SCDisplay sourceRect coordinates
    /// - Parameters:
    ///   - region: The selection rect in SwiftUI coordinates (origin top-left, relative to the window/screen)
    ///   - screen: The NSScreen where selection was made
    ///   - display: The target SCDisplay for capture
    /// - Returns: CGRect for SCStreamConfiguration.sourceRect (local coordinates relative to display top-left)
    private func convertToDisplayCoordinates(_ region: CGRect, screen: NSScreen, display: SCDisplay) -> CGRect {
        // SCStreamConfiguration.sourceRect must be in LOCAL display coordinates.
        // i.e., (0,0) is the top-left of the display itself, regardless of where it is on the desktop.
        
        // SelectionOverlay 'region' is already relative to the screen's top-left (0,0).
        // Since we are capturing *this specific display*, and the region is relative to *this screen*,
        // the coordinates should map 1:1 if the resolution matches (points vs pixels).
        // NSScreen and SCDisplay both use "points" (logical pixels).
        
        // However, we need to be careful about rounding and bounds.
        // The sourceRect must be fully contained within the display bounds (0, 0, width, height).
        
        var sourceRect = region
        
        // Intersect with display bounds to ensure we don't request out-of-bounds capture
        // SCDisplay logic: bounds are (0, 0, width, height)
        let displayBounds = CGRect(origin: .zero, size: display.frame.size)
        sourceRect = sourceRect.intersection(displayBounds)
        
        // Ensure strictly positive dimensions
        if sourceRect.width <= 0 || sourceRect.height <= 0 {
             print("Warning: Source rect became empty after intersection. fallback to full screen.")
             return displayBounds
        }

        print("Converted Selection: \(region) -> Display Local: \(sourceRect) (Display Size: \(display.frame.size))")

        return sourceRect
    }

    /// Applies a 1px inner border to the image
    private func applyOutline(to cgImage: CGImage) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        // Create context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        // Draw original image
        context.draw(cgImage, in: rect)

        // Draw basic 1px border
        // We stroke the rect. Since stroke is centered on the line, we inset by 0.5 to keep it inside.
        let borderPath = CGPath(rect: rect.insetBy(dx: 0.5, dy: 0.5), transform: nil)
        
        // Inner shadow/border (white) for visibility on dark backgrounds
        context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 0.2)
        context.setLineWidth(1)
        context.addPath(borderPath)
        context.strokePath()

        // Main border (black)
        context.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 0.15)
        context.setLineWidth(1)
        context.addPath(borderPath)
        context.strokePath()

        return context.makeImage()
    }
    
    /// Draws red rectangle annotations on the image
    private func drawAnnotations(on cgImage: CGImage, annotations: [CGRect], sourceRect: CGRect, scaleFactor: CGFloat) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        // Create context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        // Draw original image
        context.draw(cgImage, in: rect)
        
        // Setup for drawing annotations
        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) // Red
        context.setLineWidth(2.0 * scaleFactor) // Scale line width with quality
        
        // Annotations are relative to the selection rect (sourceRect).
        // Since the image IS the selection rect content, we just need to scale them.
        // However, the coordinate system of Core Graphics has Y-axis flipping potentially relative to SwiftUI.
        // SwiftUI: (0,0) is Top-Left. Core Graphics (context): (0,0) is usually Bottom-Left, BUT
        // for bitmap contexts created like this, it often matches if we don't apply transforms.
        // Actually, CGImage coordinates: (0,0) is top-left when processing data usually, 
        // but `context.draw` might flip if we are not careful or depending on how the image was created.
        // Let's assume standard mapping first: scale annotation logic.
        
        for annotation in annotations {
             // Annotation rects are relative to the capture region (0,0 at top-left of selection)
             // We just need to scale them to the capture resolution
             // Flip Y coordinates because Core Graphics origin is bottom-left, SwiftUI is top-left
             let scaledHeight = annotation.height * scaleFactor
             let scaledY = CGFloat(height) - (annotation.origin.y * scaleFactor) - scaledHeight
             
             let scaledRect = CGRect(
                x: annotation.origin.x * scaleFactor,
                y: scaledY,
                width: annotation.width * scaleFactor,
                height: scaledHeight
             )
             
             let path = CGPath(rect: scaledRect, transform: nil)
             context.addPath(path)
        }
        
        context.strokePath()

        return context.makeImage()
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
    case noFramesCaptured

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
        case .noFramesCaptured:
            return "No frames were captured during recording"
        }
    }
}
