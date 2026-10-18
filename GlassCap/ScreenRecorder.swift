import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics
import AppKit

@available(macOS 14.6, *)
@MainActor
final class ScreenRecorder: NSObject, SCStreamOutput, SCStreamDelegate {
    static let shared = ScreenRecorder()
    private var stream: SCStream?
    private let writer = RecordingWriter()
    private var recordingURL: URL?
    var recoveryURL: URL? { recordingURL }
    private var starting = false
    private var startFailure: Error?
    var onRecordingError: ((Error) -> Void)?

    func startRecording(region: CGRect, screen: NSScreen, quality: CaptureQuality) async throws {
        guard stream == nil, !starting else { throw ScreenRecorderError.alreadyRecording }
        starting = true
        startFailure = nil
        recordingURL = nil
        defer { starting = false }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = findDisplay(for: screen, in: content.displays) else {
                throw CaptureGeometryError.displayUnavailable
            }
            let rect = try convertToDisplayCoordinates(region, screen: screen, display: display)
            let config = SCStreamConfiguration()
            config.sourceRect = rect
            config.width = Int(ceil(rect.width * quality.scaleFactor))
            config.height = Int(ceil(rect.height * quality.scaleFactor))
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = true
            config.capturesAudio = false
            config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            config.queueDepth = 5
            let url = try StorageManager.shared.makeRecoveryRecordingURL()
            recordingURL = url
            try await writer.prepare(url: url, bitrateFactor: quality.videoBitrateFactor)
            let stream = SCStream(filter: SCContentFilter(display: display, excludingWindows: []), configuration: config, delegate: self)
            self.stream = stream
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: writer.queue)
            try await stream.startCapture()
            if let startFailure { throw startFailure }
        } catch {
            let failedStream = stream
            stream = nil
            if let failedStream { try? await failedStream.stopCapture() }
            await writer.cancel()
            throw error
        }
    }

    func stopRecording() async throws -> URL {
        guard let stream else { throw ScreenRecorderError.notRecording }
        // Clear first: an expected stop callback must not start another finalization.
        self.stream = nil
        do { try await stream.stopCapture() }
        catch { /* An interrupted stream can still have a playable partial recording. */ }
        let url = try await writer.finish()
        recordingURL = nil
        return url
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            guard self.stream === stream else { return }
            if self.starting { self.startFailure = error }
            else { self.onRecordingError?(error) }
        }
    }

    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
           let status = attachments.first?[.status] as? Int,
           SCFrameStatus(rawValue: status) != .complete { return }
        do { try writer.append(sampleBuffer) }
        catch {
            Task { @MainActor in
                guard self.stream === stream else { return }
                if self.starting { self.startFailure = error }
                else { self.onRecordingError?(error) }
            }
        }
    }

    @MainActor
    func captureScreenshot(region: CGRect, annotations: [CGRect], screen: NSScreen, quality: CaptureQuality) async throws -> URL {
        // Find the SCDisplay matching the NSScreen
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let targetDisplay = findDisplay(for: screen, in: content.displays) else {
            throw ScreenRecorderError.noDisplayFound
        }

        // Convert selection rect (relative to screen) to display coordinates
        let displayRegion = try convertToDisplayCoordinates(region, screen: screen, display: targetDisplay)

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
        StorageManager.shared.showVisualFlash(on: screen)

        return destinationURL
    }

    // MARK: - Display Matching

    /// Find the SCDisplay that matches the given NSScreen
    private func findDisplay(for screen: NSScreen, in displays: [SCDisplay]) -> SCDisplay? {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              let id = try? CaptureGeometry.displayID(expected: number.uint32Value, available: displays.map(\.displayID)) else { return nil }
        return displays.first { $0.displayID == id }
    }

    private func convertToDisplayCoordinates(_ region: CGRect, screen: NSScreen, display: SCDisplay) throws -> CGRect {
        try CaptureGeometry.region(region, in: CGRect(origin: .zero, size: display.frame.size))
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
