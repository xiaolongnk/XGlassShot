import Foundation
import AppKit
import AVFoundation

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case saveCancelled
    case directoryNotWritable
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveCancelled:
            return "save_cancelled".localized
        case .directoryNotWritable:
            return "directory_not_writable".localized
        case .invalidData:
            return "invalid_data".localized
        }
    }
}

// MARK: - NSImage Extension

import AVFoundation

extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage {
        let aspectRatio = size.width / size.height
        var newSize = targetSize

        if aspectRatio > targetSize.width / targetSize.height {
            newSize.height = targetSize.width / aspectRatio
        } else {
            newSize.width = targetSize.height * aspectRatio
        }

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
