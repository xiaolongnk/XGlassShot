import Foundation
import AppKit
import Combine

@available(macOS 12.3, *)
@MainActor
final class AIManager: ObservableObject {
    static let shared = AIManager()

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "anthropicAPIKey") }
    }

    var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
    }

    func describeImage(at url: URL) async throws -> String {
        guard hasAPIKey else { throw AIError.noAPIKey }
        let imageData = try Data(contentsOf: url)
        let base64 = imageData.base64EncodedString()
        let mediaType = url.pathExtension.lowercased() == "png" ? "image/png" : "image/jpeg"

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1024,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image", "source": ["type": "base64", "media_type": mediaType, "data": base64]],
                    ["type": "text", "text": "Describe this screenshot concisely: what's shown, key UI elements, important text. 2-3 sentences max."]
                ]
            ]]
        ]

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey.trimmingCharacters(in: .whitespaces), forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?
                .compactMap { ($0.key == "error" ? $0.value as? [String: Any] : nil)?["message"] as? String }.first
                ?? "Request failed"
            throw AIError.apiError(msg)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String else { throw AIError.parseError }
        return text
    }
}

enum AIError: LocalizedError {
    case noAPIKey, imageLoadFailed, apiError(String), parseError
    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No Anthropic API key set. Add it in the AI settings (⚙ icon)."
        case .imageLoadFailed: return "Could not load the image."
        case .apiError(let m): return "API error: \(m)"
        case .parseError: return "Could not parse the API response."
        }
    }
}
