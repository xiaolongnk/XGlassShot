import Foundation

enum CaptureFileStore {
    static func sanitizedPrefix(_ prefix: String) -> String {
        String(prefix.filter { !$0.isNewline && !"/:\0".contains($0) }.prefix(60))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func filename(prefix: String, extension fileExtension: String, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let safePrefix = sanitizedPrefix(prefix)
        let tag = safePrefix.isEmpty ? "" : safePrefix + "_"
        return "\(tag)\(formatter.string(from: date))-\(UUID().uuidString.prefix(8)).\(fileExtension)"
    }

    static func writeScreenshot(_ data: Data, to destination: URL) throws {
        try data.write(to: destination, options: .withoutOverwriting)
    }

    /// The source survives every failure, including a pre-existing destination.
    static func copyRecording(from source: URL, to destination: URL) throws {
        try FileManager.default.copyItem(at: source, to: destination)
    }

    /// Only used after NSSavePanel has obtained the user's replacement confirmation.
    static func replaceRecording(from source: URL, to destination: URL) throws {
        guard source.resolvingSymlinksInPath() != destination.resolvingSymlinksInPath() else { return }
        let staged = destination.deletingLastPathComponent().appendingPathComponent(".glasscap-\(UUID().uuidString).mov")
        try FileManager.default.copyItem(at: source, to: staged)
        defer { try? FileManager.default.removeItem(at: staged) }
        _ = try FileManager.default.replaceItemAt(destination, withItemAt: staged)
    }
}
