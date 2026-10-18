import ArgumentParser
import Foundation

struct CapabilitiesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "capabilities", abstract: "Describe the JSON automation interface without requesting capture permission.")
    func run() {
        JSONOutput.success(CapabilityResponse(
            schema_version: 1,
            commands: [
                CapabilityCommand(name: "screens", options: [], result: ["screens: index, name, width, height, primary"]),
                CapabilityCommand(name: "screenshot", options: ["--screen", "--region", "--quality", "--output", "--directory", "--prefix"], result: ["path", "width", "height"]),
                CapabilityCommand(name: "record start", options: ["--screen", "--region", "--quality", "--output", "--directory", "--prefix"], result: ["status", "output"]),
                CapabilityCommand(name: "record stop", options: [], result: ["path", "duration_s"])
            ],
            notes: [
                "List screens before selecting an index; regions use display-local top-left points.",
                "Quality is low (1x) or high (2x).",
                "Use --output for an exact path, or --directory and --prefix for unique automatic names.",
                "Directories are created as needed; automatic prefixes omit /, :, NUL and newlines and are limited to 60 characters.",
                "Capture runtime failures return JSON {error: string} and exit 1. Parser syntax errors use stderr.",
                "Screenshots never overwrite existing files. GUI directory grants and preferences are separate; provide explicit CLI destinations.",
                "Screen capture requires terminal permission in macOS; capabilities and help do not."
            ]))
    }
}
private struct CapabilityResponse: Encodable {
    let schema_version: Int
    let commands: [CapabilityCommand]
    let notes: [String]
}
private struct CapabilityCommand: Encodable {
    let name: String
    let options: [String]
    let result: [String]
}
