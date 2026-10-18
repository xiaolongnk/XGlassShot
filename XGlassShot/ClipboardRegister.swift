//
//  ClipboardRegister.swift
//  GlassCap
//
//  In-memory ring buffer of the last 5 capture entries.
//  Resets on app quit — no persistence required for MVP.
//

import Foundation
import AppKit
import Combine

// MARK: - Model

struct ClipboardEntry: Identifiable {
    let id: UUID
    let capturedAt: Date
    let imageURL: URL
    let thumbnail: NSImage
    var copiedText: String?

    init(imageURL: URL, thumbnail: NSImage, copiedText: String? = nil) {
        self.id = UUID()
        self.capturedAt = Date()
        self.imageURL = imageURL
        self.thumbnail = thumbnail
        self.copiedText = copiedText
    }
}

// MARK: - Manager

@MainActor
final class ClipboardRegisterManager: ObservableObject {

    static let shared = ClipboardRegisterManager()

    private let maxEntries = 5

    /// Most-recent entry is at index 0.
    @Published private(set) var entries: [ClipboardEntry] = []

    private init() {}

    // MARK: - Mutations

    /// Adds a new entry for the given capture. Drops the oldest when the cap is exceeded.
    func addEntry(imageURL: URL, thumbnail: NSImage) {
        let entry = ClipboardEntry(imageURL: imageURL, thumbnail: thumbnail)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast()
        }
    }

    /// Attaches OCR text to the most-recent entry (if it matches the given URL).
    func setOCRText(_ text: String, forURL url: URL) {
        guard let idx = entries.firstIndex(where: { $0.imageURL == url }) else { return }
        entries[idx].copiedText = text
    }

    // MARK: - Pasteboard copy

    /// Copies the entry's image (and text if present) to the system pasteboard.
    func copyToPasteboard(entry: ClipboardEntry) {
        let pb = NSPasteboard.general
        pb.clearContents()

        if let image = NSImage(contentsOf: entry.imageURL) {
            pb.writeObjects([image])
        }

        if let text = entry.copiedText, !text.isEmpty {
            pb.setString(text, forType: .string)
        }
    }
}
