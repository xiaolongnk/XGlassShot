//
//  StorageManager.swift
//  GlassCap
//
//  Handles file storage settings and auto-save logic
//

import Foundation
import SwiftUI
import AppKit
import AudioToolbox
import UniformTypeIdentifiers
import Combine
import AVFoundation

@available(macOS 12.3, *)
@MainActor
final class StorageManager: ObservableObject {

    static let shared = StorageManager()

    // MARK: - Persisted Settings

    @AppStorage("defaultSaveDirectory") private var savedDirectory: String = ""
    @AppStorage("alwaysAskWhereToSave") var alwaysAskWhereToSave: Bool = false
    @AppStorage("lastCaptureURL") private var lastCaptureURLString: String = ""
    @AppStorage("playCaptureSound") var playCaptureSound: Bool = true
    @AppStorage("addScreenshotOutline") var addScreenshotOutline: Bool = false

    // MARK: - Published Properties

    @Published var lastCaptureURL: URL?
    @Published var lastCaptureThumbnail: NSImage?
    @Published private(set) var isLoadingThumbnail = false
    private var lastCaptureAccess: URL?

    // MARK: - Computed Properties

    var defaultSaveDirectory: URL {
        get {
            if savedDirectory.isEmpty {
                return defaultPicturesDirectory
            }
            // Always try to use the saved directory even if we can't confirm writability (sandbox limitations)
            return URL(fileURLWithPath: savedDirectory)
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
        // Restore directory/file grants before attempting to read a preview.
        _ = resolveBookmarkedDirectory()
        if let bookmark = UserDefaults.standard.data(forKey: "lastCaptureBookmark") {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale),
               url.startAccessingSecurityScopedResource() { lastCaptureAccess = url }
        }
        if !lastCaptureURLString.isEmpty {
            let url = lastCaptureAccess ?? URL(fileURLWithPath: lastCaptureURLString)
            lastCaptureURL = url
            loadThumbnail(for: url)
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
        panel.message = "choose_save_location".localized
        panel.prompt = "select".localized

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
        CaptureFileStore.filename(prefix: prefix, extension: "png")
    }

    func generateRecordingFilename(prefix: String = "") -> String {
        CaptureFileStore.filename(prefix: prefix, extension: "mov")
    }

    @AppStorage("pendingRecordingPath") private var pendingRecordingPath = ""
    var pendingRecordingURL: URL? {
        guard !pendingRecordingPath.isEmpty,
              FileManager.default.fileExists(atPath: pendingRecordingPath) else { return nil }
        return URL(fileURLWithPath: pendingRecordingPath)
    }

    func recoveryDirectory() throws -> URL {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = support.appendingPathComponent("GlassCap/Recovery", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func makeRecoveryRecordingURL() throws -> URL {
        let url = try recoveryDirectory().appendingPathComponent(generateRecordingFilename())
        pendingRecordingPath = url.path
        return url
    }

    private func recordingSaved(from source: URL) {
        // Never remove the recovery source until the destination copy has succeeded.
        do {
            try FileManager.default.removeItem(at: source)
            if pendingRecordingPath == source.path { pendingRecordingPath = "" }
        } catch {
            // A redundant recovery copy is preferable to losing a recording.
            NSLog("GlassCap: could not remove saved recovery copy: %@", error.localizedDescription)
        }
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
        // We now optimistically try to save to the default directory.
        // If it fails (e.g., sandbox issue without bookmark), we catch the error and fall back to the panel.
        if let (directory, releaseAccess) = getTargetDirectory() {
            defer {
                if releaseAccess {
                    directory.stopAccessingSecurityScopedResource()
                }
            }
            
            let destinationURL = directory.appendingPathComponent(filename)
            
            do {
                try CaptureFileStore.writeScreenshot(data, to: destinationURL)
                
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
                try CaptureFileStore.copyRecording(from: tempURL, to: destinationURL)
                recordingSaved(from: tempURL)

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

        try data.write(to: destinationURL, options: .atomic)

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
        savePanel.title = "save_recording".localized
        savePanel.message = "choose_location".localized

        let response = await savePanel.begin()

        guard response == .OK, let destinationURL = savePanel.url else {
            // The recording stays in the persistent Recovery folder.
            throw StorageError.saveCancelled
        }

        if destinationURL.resolvingSymlinksInPath() == tempURL.resolvingSymlinksInPath() {
            pendingRecordingPath = ""
            updateLastCapture(url: destinationURL)
            playCaptureConfirmation()
            return destinationURL
        }
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try CaptureFileStore.replaceRecording(from: tempURL, to: destinationURL)
        } else {
            try CaptureFileStore.copyRecording(from: tempURL, to: destinationURL)
        }
        recordingSaved(from: tempURL)

        // Update last capture
        updateLastCapture(url: destinationURL)

        // Play capture sound
        playCaptureConfirmation()

        return destinationURL
    }

    // MARK: - Feedback

    func playCaptureConfirmation() {
        guard playCaptureSound else { return }

        // Play a clear sound effect (Tink) for better audibility
        NSSound(named: "Tink")?.play()
    }

    private var flashWindow: NSWindow?
    
    func showVisualFlash(on selectedScreen: NSScreen? = nil) {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.showVisualFlash(on: selectedScreen)
            }
            return
        }

        guard let screen = selectedScreen ?? NSScreen.main else { return }

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
        lastCaptureAccess?.stopAccessingSecurityScopedResource()
        lastCaptureAccess = nil
        if let bookmark = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(bookmark, forKey: "lastCaptureBookmark")
        } else { UserDefaults.standard.removeObject(forKey: "lastCaptureBookmark") }
        lastCaptureURL = url
        lastCaptureURLString = url.path
        loadThumbnail(for: url)
        pushToClipboardRegister(url: url)
    }

    private func pushToClipboardRegister(url: URL) {
        // Only register image captures (not video recordings)
        guard url.pathExtension.lowercased() == "png" || url.pathExtension.lowercased() == "jpg" else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail: NSImage
            if let img = NSImage(contentsOf: url) {
                thumbnail = img.resized(to: NSSize(width: 120, height: 80))
            } else {
                thumbnail = NSImage()
            }
            DispatchQueue.main.async {
                ClipboardRegisterManager.shared.addEntry(imageURL: url, thumbnail: thumbnail)
            }
        }
    }

    private func loadThumbnail(for url: URL) {
        isLoadingThumbnail = true
        lastCaptureThumbnail = nil
        Task {
            let thumbnail: NSImage?
            if ["png", "jpg", "jpeg"].contains(url.pathExtension.lowercased()) {
                let image = await Task.detached(priority: .userInitiated) { CaptureThumbnail.image(at: url) }.value
                thumbnail = image.map { NSImage(cgImage: $0, size: NSSize(width: $0.width, height: $0.height)) }
            } else {
                let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 1200, height: 900)
                if let result = try? await generator.image(at: .zero) {
                    thumbnail = NSImage(cgImage: result.image, size: NSSize(width: result.image.width, height: result.image.height))
                } else { thumbnail = nil }
            }
            guard lastCaptureURL == url else { return }
            lastCaptureThumbnail = thumbnail
            isLoadingThumbnail = false
        }
    }

    func revealLastCapture() {
        guard let url = lastCaptureURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
