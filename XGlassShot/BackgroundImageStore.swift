import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

/// Keeps a bounded, metadata-free copy so wallpaper survives moving the original file.
nonisolated struct BackgroundImageStore: Sendable {
    let directory: URL
    var imageURL: URL { directory.appendingPathComponent("background.png") }

    static var applicationStore: Self {
        Self(directory: URL.applicationSupportDirectory.appendingPathComponent("GlassCap/Appearance", isDirectory: true))
    }

    enum ImportError: Error { case unreadableImage, encodingFailed }

    func load() -> CGImage? { CaptureThumbnail.image(at: imageURL, maxPixelSize: 2400) }

    func importImage(from url: URL) throws -> CGImage {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        guard let image = CaptureThumbnail.image(at: url, maxPixelSize: 2400) else {
            throw ImportError.unreadableImage
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw ImportError.encodingFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw ImportError.encodingFailed }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Validate and encode before touching the current background; atomic replacement keeps failures safe.
        try (data as Data).write(to: imageURL, options: .atomic)
        return image
    }

    func remove() throws {
        if FileManager.default.fileExists(atPath: imageURL.path) { try FileManager.default.removeItem(at: imageURL) }
    }
}
