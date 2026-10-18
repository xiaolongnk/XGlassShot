import Foundation

/// Explicit destinations for automation. GUI sandbox bookmarks are intentionally not read here.
enum CaptureDestination {
    enum DestinationError: LocalizedError {
        case conflictingOptions
        var errorDescription: String? { "Use --output for an exact filename, or --directory and --prefix for automatic naming; do not combine them." }
    }
    static func resolve(output: String?, directory: String?, prefix: String?, recording: Bool = false) throws -> URL {
        if let output {
            guard directory == nil, prefix == nil else { throw DestinationError.conflictingOptions }
            return URL(fileURLWithPath: (output as NSString).expandingTildeInPath)
        }
        let base = directory.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(recording ? "Movies/XGlassShot" : "Pictures/XGlassShot", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        // Keep the filename safety policy consistent with CaptureFileStore in the GUI.
        let safePrefix = String((prefix ?? "xglassshot").filter { !$0.isNewline && !"/:\0".contains($0) }.prefix(60))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let tag = safePrefix.isEmpty ? "" : safePrefix + "_"
        return base.appendingPathComponent("\(tag)\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8)).\(recording ? "mov" : "png")")
    }
}
