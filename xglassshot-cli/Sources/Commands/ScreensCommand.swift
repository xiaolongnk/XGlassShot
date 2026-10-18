import ArgumentParser
import AppKit
import ScreenCaptureKit

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct ScreensCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screens",
        abstract: "List available screens as JSON."
    )

    func run() async throws {
        PermissionCheck.requireScreenRecording()

        let nsScreens = NSScreen.screens
        var infos: [ScreenInfo] = []

        for (index, screen) in nsScreens.enumerated() {
            let frame = screen.frame
            // NSScreen.frame uses logical points; width/height in points
            let info = ScreenInfo(
                index: index,
                name: screen.localizedName,
                width: Int(frame.width),
                height: Int(frame.height),
                primary: screen == NSScreen.screens.first
            )
            infos.append(info)
        }

        JSONOutput.success(ScreensResponse(screens: infos))
    }
}
