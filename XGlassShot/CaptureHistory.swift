import Foundation

nonisolated struct CaptureHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var url: URL
    var capturedAt: Date
    var bookmark: Data?
}

nonisolated struct CaptureHistory: Codable, Equatable, Sendable {
    enum Direction { case older, newer }
    static let capacity = 100
    private(set) var entries: [CaptureHistoryEntry] = []

    static func normalizedURL(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    static func isImage(_ url: URL) -> Bool {
        ["png", "jpg", "jpeg"].contains(url.pathExtension.lowercased())
    }

    mutating func merge(_ incoming: [CaptureHistoryEntry]) {
        var unique: [URL: CaptureHistoryEntry] = [:]
        for var entry in entries + incoming where Self.isImage(entry.url) {
            entry.url = Self.normalizedURL(entry.url)
            if let previous = unique[entry.url] {
                entry.id = previous.id
                entry.bookmark = entry.bookmark ?? previous.bookmark
                entry.capturedAt = max(entry.capturedAt, previous.capturedAt)
            }
            unique[entry.url] = entry
        }
        entries = Array(unique.values.sorted {
            if $0.capturedAt == $1.capturedAt { return $0.url.path > $1.url.path }
            return $0.capturedAt > $1.capturedAt
        }.prefix(Self.capacity))
    }

    mutating func remove(_ url: URL) {
        entries.removeAll { $0.url == Self.normalizedURL(url) }
    }

    func position(of url: URL?) -> Int? {
        guard let url else { return nil }
        return entries.firstIndex { $0.url == Self.normalizedURL(url) }
    }

    func neighbor(of url: URL?, direction: Direction) -> CaptureHistoryEntry? {
        guard let position = position(of: url) else {
            return direction == .older ? entries.first : nil
        }
        let next = position + (direction == .older ? 1 : -1)
        return entries.indices.contains(next) ? entries[next] : nil
    }

    /// Import generated capture names, not unrelated personal photos.
    static func discover(in directory: URL) -> [CaptureHistoryEntry] {
        let keys: Set<URLResourceKey> = [.creationDateKey, .isRegularFileKey]
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory,
            includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else { return [] }
        let pattern = #"(?:^|_)\d{8}-\d{6}-\d{3}-[A-Fa-f0-9]{8}\.(png|jpe?g)$"#
        return files.compactMap { url in
            guard url.lastPathComponent.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil,
                  let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true else { return nil }
            return CaptureHistoryEntry(url: url, capturedAt: values.creationDate ?? .distantPast)
        }.sorted { $0.capturedAt > $1.capturedAt }.prefix(Self.capacity).map { $0 }
    }
}
