import ArgumentParser
import Foundation

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct XGlassShotCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xglassshot",
        abstract: "XGlassShot CLI — screenshot and screen recording for AI agents.",
        version: "1.1.1",
        subcommands: [
            CapabilitiesCommand.self,
            ScreensCommand.self,
            ScreenshotCommand.self,
            RecordCommand.self,
            RecordDaemon.self,  // hidden; invoked by `record start` internally
        ]
    )
}
