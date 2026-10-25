import Foundation
import AppKit
import Combine

struct ClipboardEntry: Identifiable {
    let id: UUID
    let capturedAt: Date
    let imageURL: URL
    let thumbnail: NSImage
    let copiedText: String?
}

@MainActor
final class ClipboardRegisterManager: ObservableObject {
    static let shared = ClipboardRegisterManager()
    private static let historyKey = "captureHistoryV1"
    @Published private(set) var history = CaptureHistory()
    @Published private(set) var previewURL: URL?
    @Published private(set) var previewThumbnail: NSImage?
    @Published private(set) var isLoadingPreview = false
    private let defaults: UserDefaults
    private var copiedText: [UUID: String] = [:]
    private var previewAccess: URL?
    private var previewGeneration = UUID()
    private var scanGeneration = UUID()
    private var latestCaptureURL: URL?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.historyKey),
           let restored = try? JSONDecoder().decode(CaptureHistory.self, from: data) {
            history.merge(restored.entries)
        }
    }

    /// The menu keeps five items; the preview can browse all retained records.
    var entries: [ClipboardEntry] {
        history.entries.prefix(5).compactMap { entry in
            withAccess(to: entry) { url in
                guard let image = CaptureThumbnail.image(at: url, maxPixelSize: 160) else { return nil }
                return ClipboardEntry(id: entry.id, capturedAt: entry.capturedAt, imageURL: url,
                    thumbnail: NSImage(cgImage: image, size: .zero), copiedText: copiedText[entry.id])
            }
        }
    }

    func prepare(latestURL: URL?, bookmark: Data?) {
        showLatest(url: latestURL)
        if let latestURL, CaptureHistory.isImage(latestURL), history.position(of: latestURL) == nil {
            let date = (try? latestURL.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
            history.merge([CaptureHistoryEntry(url: latestURL, capturedAt: date, bookmark: bookmark)])
            persist()
        }
    }

    func refresh(in directory: URL) {
        let generation = UUID()
        scanGeneration = generation
        Task {
            let discovered = await Task.detached(priority: .utility) { CaptureHistory.discover(in: directory) }.value
            guard scanGeneration == generation else { return }
            history.merge(discovered.map { item in
                var item = item
                item.bookmark = bookmark(for: item.url)
                return item
            })
            persist()
            if latestCaptureURL == nil, previewURL == nil { browse(.older, from: nil) }
        }
    }

    func addEntry(imageURL: URL) {
        guard CaptureHistory.isImage(imageURL) else { return }
        history.merge([CaptureHistoryEntry(url: imageURL, capturedAt: Date(), bookmark: bookmark(for: imageURL))])
        persist()
    }

    func showLatest(url: URL?) {
        latestCaptureURL = url
        previewGeneration = UUID()
        previewAccess?.stopAccessingSecurityScopedResource()
        previewAccess = nil
        previewURL = nil
        previewThumbnail = nil
        isLoadingPreview = false
    }

    @discardableResult
    func browse(_ direction: CaptureHistory.Direction, from currentURL: URL?) -> Bool {
        if returnsToLatestRecording(direction, from: currentURL) {
            showLatest(url: latestCaptureURL)
            return true
        }
        while let entry = history.neighbor(of: currentURL, direction: direction) {
            let url = resolvedURL(for: entry)
            let accessed = url.startAccessingSecurityScopedResource()
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                if accessed { url.stopAccessingSecurityScopedResource() }
                history.remove(entry.url)
                persist()
                continue
            }
            previewAccess?.stopAccessingSecurityScopedResource()
            previewAccess = accessed ? url : nil
            if CaptureHistory.normalizedURL(url) != entry.url {
                var moved = entry
                moved.url = url
                moved.bookmark = bookmark(for: url) ?? entry.bookmark
                history.remove(entry.url)
                history.merge([moved])
                persist()
            }
            previewURL = url
            previewThumbnail = nil
            isLoadingPreview = true
            let generation = UUID()
            previewGeneration = generation
            Task {
                let image = await Task.detached(priority: .userInitiated) { CaptureThumbnail.image(at: url) }.value
                guard previewGeneration == generation else { return }
                previewThumbnail = image.map { NSImage(cgImage: $0, size: .zero) }
                isLoadingPreview = false
            }
            return true
        }
        return false
    }

    func canBrowse(_ direction: CaptureHistory.Direction, from url: URL?) -> Bool {
        returnsToLatestRecording(direction, from: url) || history.neighbor(of: url, direction: direction) != nil
    }

    private func returnsToLatestRecording(_ direction: CaptureHistory.Direction, from url: URL?) -> Bool {
        direction == .newer && history.position(of: url) == 0 &&
            latestCaptureURL.map { !CaptureHistory.isImage($0) } == true
    }

    func setOCRText(_ text: String, forURL url: URL) {
        guard let position = history.position(of: url) else { return }
        copiedText[history.entries[position].id] = text
    }

    @discardableResult
    func copyImage(at url: URL, to pasteboard: NSPasteboard = .general) -> Bool {
        let position = history.position(of: url)
        let entry = position.map { history.entries[$0] } ?? CaptureHistoryEntry(url: url, capturedAt: Date())
        return withAccess(to: entry) { source in
            writeImage(at: source, to: pasteboard)
        }
    }

    func copyToPasteboard(entry: ClipboardEntry, to pasteboard: NSPasteboard = .general) {
        guard let record = history.entries.first(where: { $0.id == entry.id }),
              withAccess(to: record, perform: { writeImage(at: $0, to: pasteboard) }) else { return }
        if let text = entry.copiedText, !text.isEmpty { pasteboard.setString(text, forType: .string) }
    }

    private func writeImage(at url: URL, to pasteboard: NSPasteboard) -> Bool {
        guard let image = NSImage(contentsOf: url), image.isValid else { return false }
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    private func bookmark(for url: URL) -> Data? {
        try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    private func resolvedURL(for entry: CaptureHistoryEntry) -> URL {
        guard let bookmark = entry.bookmark else { return entry.url }
        var stale = false
        return (try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope,
                         bookmarkDataIsStale: &stale)) ?? entry.url
    }

    private func withAccess<T>(to entry: CaptureHistoryEntry, perform: (URL) -> T) -> T {
        let url = resolvedURL(for: entry)
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return perform(url)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: Self.historyKey) }
    }
}
