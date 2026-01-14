//
//  StorageManager.swift
//  screenKit
//
//  Handles file storage settings and auto-save logic
//

import Foundation
import SwiftUI
import AppKit
import AudioToolbox
import UniformTypeIdentifiers
import Combine

@available(macOS 12.3, *)
@MainActor
final class StorageManager: ObservableObject {

    static let shared = StorageManager()

    // MARK: - Persisted Settings

    @AppStorage("defaultSaveDirectory") private var savedDirectory: String = ""
    @AppStorage("alwaysAskWhereToSave") var alwaysAskWhereToSave: Bool = false
    @AppStorage("lastCaptureURL") private var lastCaptureURLString: String = ""
    @AppStorage("playCaptureSound") var playCaptureSound: Bool = true

    // MARK: - Published Properties

    @Published var lastCaptureURL: URL?
    @Published var lastCaptureThumbnail: NSImage?

    // MARK: - Computed Properties

    var defaultSaveDirectory: URL {
        get {
            if savedDirectory.isEmpty {
                return defaultPicturesDirectory
            }
            let url = URL(fileURLWithPath: savedDirectory)
            // Verify directory exists and is writable
            if isDirectoryWritable(url) {
                return url
            }
            return defaultPicturesDirectory
        }
        set {
            savedDirectory = newValue.path
            objectWillChange.send()
        }
    }

    private var defaultPicturesDirectory: URL {
        FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
    }

    // MARK: - Initialization

    private init() {
        // Load last capture URL
        if !lastCaptureURLString.isEmpty {
            let url = URL(fileURLWithPath: lastCaptureURLString)
            if FileManager.default.fileExists(atPath: url.path) {
                lastCaptureURL = url
                loadThumbnail(for: url)
            }
        }
    }

    // MARK: - Directory Management

    func isDirectoryWritable(_ url: URL) -> Bool {
        FileManager.default.isWritableFile(atPath: url.path)
    }

    func selectSaveDirectory() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose default save location for captures"
        panel.prompt = "Select"

        let response = await panel.begin()

        if response == .OK, let url = panel.url {
            // Create security-scoped bookmark for sandbox
            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmarkData, forKey: "saveDirectoryBookmark")
            } catch {
                print("Failed to create bookmark: \(error)")
            }

            defaultSaveDirectory = url
            return url
        }
        return nil
    }

    func resolveBookmarkedDirectory() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "saveDirectoryBookmark") else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Recreate bookmark
                let newBookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(newBookmarkData, forKey: "saveDirectoryBookmark")
            }

            _ = url.startAccessingSecurityScopedResource()
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    // MARK: - File Naming

    func generateScreenshotFilename(prefix: String = "") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd-HHmmss"
        let timestamp = formatter.string(from: Date())
        
        var prefixPart = prefix
        if !prefixPart.isEmpty && !prefixPart.hasSuffix("_") {
            prefixPart += "_"
        }
        
        return "\(prefixPart)\(timestamp).png"
    }

    func generateRecordingFilename(prefix: String = "") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd-HHmmss"
        let timestamp = formatter.string(from: Date())
        
        var prefixPart = prefix
        if !prefixPart.isEmpty && !prefixPart.hasSuffix("_") {
            prefixPart += "_"
        }
        
        return "\(prefixPart)\(timestamp).mov"
    }

    // MARK: - Save Operations
    
    private func getTargetDirectory() -> (url: URL, releaseAccess: Bool)? {
        if alwaysAskWhereToSave { return nil }
        
        // If no custom directory set, use default Pictures
        if savedDirectory.isEmpty {
            return (defaultPicturesDirectory, false)
        }
        
        // Try to resolve bookmark for custom directory
        if let url = resolveBookmarkedDirectory() {
            return (url, true)
        }
        
        // Fallback: This is likely to fail in sandbox if bookmark is missing/invalid
        // But we return it anyway to attempt write or let it fail
        return (URL(fileURLWithPath: savedDirectory), false) 
    }

    /// Save screenshot data to default directory or prompt user
    /// Returns the URL where the file was saved
    func saveScreenshot(data: Data, prefix: String = "") async throws -> URL {
        let filename = generateScreenshotFilename(prefix: prefix)

        // Try silent save first if configured
        if let (directory, releaseAccess) = getTargetDirectory() {
            defer {
                if releaseAccess {
                    directory.stopAccessingSecurityScopedResource()
                }
            }
            
            let destinationURL = directory.appendingPathComponent(filename)
            
            do {
                try data.write(to: destinationURL)
                
                // Update last capture
                updateLastCapture(url: destinationURL)
                
                // Play capture sound
                playCaptureConfirmation()
                
                return destinationURL
            } catch {
                print("Silent save failed: \(error)")
                // Fallback to panel if silent save fails
            }
        }

        // Fallback or explicit "always ask": Show Panel
        return try await saveWithPanel(data: data, filename: filename, fileType: .png)
    }

    /// Save video file to default directory or prompt user
    /// Returns the URL where the file was saved
    func saveRecording(from tempURL: URL, prefix: String = "") async throws -> URL {
        let filename = generateRecordingFilename(prefix: prefix)

        // Try silent save first if configured
        if let (directory, releaseAccess) = getTargetDirectory() {
            defer {
                if releaseAccess {
                    directory.stopAccessingSecurityScopedResource()
                }
            }
            
            let destinationURL = directory.appendingPathComponent(filename)
            
            do {
                 // Remove existing file if present
                try? FileManager.default.removeItem(at: destinationURL)

                // Copy from temp location
                try FileManager.default.copyItem(at: tempURL, to: destinationURL)

                // Clean up temp file
                try? FileManager.default.removeItem(at: tempURL)

                // Update last capture
                updateLastCapture(url: destinationURL)

                // Play capture sound
                playCaptureConfirmation()

                return destinationURL
            } catch {
                print("Silent save recording failed: \(error)")
                // Fallback to panel
            }
        }
        
        // Fallback or explicit "always ask": Show Panel
        return try await saveRecordingWithPanel(from: tempURL, filename: filename)
    }

    private func saveWithPanel(data: Data, filename: String, fileType: UTType) async throws -> URL {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = filename
        savePanel.allowedContentTypes = [fileType]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.directoryURL = defaultSaveDirectory

        let response = await savePanel.begin()

        guard response == .OK, let destinationURL = savePanel.url else {
            throw StorageError.saveCancelled
        }

        try data.write(to: destinationURL)

        // Update last capture
        updateLastCapture(url: destinationURL)

        // Play capture sound
        playCaptureConfirmation()

        return destinationURL
    }

    private func saveRecordingWithPanel(from tempURL: URL, filename: String) async throws -> URL {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = filename
        savePanel.allowedContentTypes = [.movie]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.directoryURL = defaultSaveDirectory
        savePanel.title = "Save Recording"
        savePanel.message = "Choose a location to save your recording"

        let response = await savePanel.begin()

        guard response == .OK, let destinationURL = savePanel.url else {
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            throw StorageError.saveCancelled
        }

        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)

        // Copy from temp location
        try FileManager.default.copyItem(at: tempURL, to: destinationURL)

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)

        // Update last capture
        updateLastCapture(url: destinationURL)

        // Play capture sound
        playCaptureConfirmation()

        return destinationURL
    }

    // MARK: - Feedback

    func playCaptureConfirmation() {
        guard playCaptureSound else { return }

        // Play system camera shutter sound (1108 is the screen capture sound)
        AudioServicesPlaySystemSound(1108)
    }

    private var flashWindow: NSWindow?
    
    func showVisualFlash() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showVisualFlash()
            }
            return
        }

        guard let screen = NSScreen.main else { return }

        // Create window if needed
        if flashWindow == nil {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.backgroundColor = NSColor.white
            window.isOpaque = false // Allow alpha changes
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            flashWindow = window
        }

        guard let window = flashWindow else { return }
        
        // Update frame in case screen changed
        window.setFrame(screen.frame, display: true)
        
        // Reset state
        window.alphaValue = 0.3
        window.orderFront(nil)

        // Fade out
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        } completionHandler: {
            window.orderOut(nil)
        }
    }

    // MARK: - Recent Capture

    private func updateLastCapture(url: URL) {
        lastCaptureURL = url
        lastCaptureURLString = url.path
        loadThumbnail(for: url)
    }

    private func loadThumbnail(for url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let thumbnail: NSImage?

            if url.pathExtension.lowercased() == "png" || url.pathExtension.lowercased() == "jpg" {
                // Load image thumbnail
                if let image = NSImage(contentsOf: url) {
                    thumbnail = image.resized(to: NSSize(width: 120, height: 80))
                } else {
                    thumbnail = nil
                }
            } else {
                // Generate video thumbnail
                thumbnail = self?.generateVideoThumbnail(for: url)
            }

            DispatchQueue.main.async {
                self?.lastCaptureThumbnail = thumbnail
            }
        }
    }

    nonisolated private func generateVideoThumbnail(for url: URL) -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 240, height: 160)

        do {
            if #available(macOS 13.0, *) {
                return try? runSynchronously {
                    let (cgImage, _) = try await generator.image(at: .zero)
                    return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                }
            } else {
                let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            }
        } catch {
            print("Failed to generate video thumbnail: \(error)")
        }
        return nil
    }

    nonisolated private func runSynchronously<T>(_ operation: @escaping () async throws -> T) throws -> T {
        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                let value = try await operation()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return try result!.get()
    }

    func revealLastCapture() {
        guard let url = lastCaptureURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case saveCancelled
    case directoryNotWritable
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveCancelled:
            return "Save was cancelled"
        case .directoryNotWritable:
            return "Cannot write to the selected directory"
        case .invalidData:
            return "Invalid data to save"
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
