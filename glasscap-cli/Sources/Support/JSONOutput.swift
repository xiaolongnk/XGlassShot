import Foundation

// MARK: - JSON output helpers

struct JSONOutput {
    /// Print a JSON-encodable value to stdout and exit with code 0.
    static func success<T: Encodable>(_ value: T) -> Never {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(value)
            print(String(data: data, encoding: .utf8) ?? "{}")
        } catch {
            printError("Failed to encode JSON: \(error.localizedDescription)")
        }
        exit(0)
    }

    /// Print a JSON error object to stdout and exit with code 1.
    static func failure(_ message: String) -> Never {
        printError(message)
    }

    private static func printError(_ message: String) -> Never {
        let obj = ["error": message]
        if let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        } else {
            print(#"{"error": "\#(message)"}"#)
        }
        exit(1)
    }
}

// MARK: - Response models

struct ScreensResponse: Encodable {
    let screens: [ScreenInfo]
}

struct ScreenInfo: Encodable {
    let index: Int
    let name: String
    let width: Int
    let height: Int
    let primary: Bool
}

struct ScreenshotResponse: Encodable {
    let path: String
    let width: Int
    let height: Int
}

struct RecordStartResponse: Encodable {
    let status: String
    let output: String
}

struct RecordStopResponse: Encodable {
    let path: String
    let duration_s: Double
}
