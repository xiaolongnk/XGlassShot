import Vision
import AppKit

@available(macOS 12.3, *)
final class OCRManager {
    static let shared = OCRManager()
    private init() {}

    func extractText(from url: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) { try Self.recognize(at: url) }.value
    }

    nonisolated private static func recognize(at url: URL) throws -> String {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.imageLoadFailed
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if #available(macOS 13, *) { request.automaticallyDetectsLanguage = true }
        let supported = try request.supportedRecognitionLanguages()
        let preferred = ["zh-Hans", "zh-Hant", "en-US"] + Locale.preferredLanguages
        let languages = preferred.filter { supported.contains($0) }
        if !languages.isEmpty { request.recognitionLanguages = Array(NSOrderedSet(array: languages)) as? [String] ?? languages }
        try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}

enum OCRError: LocalizedError {
    case imageLoadFailed
    var errorDescription: String? { "Could not load image for text extraction." }
}
