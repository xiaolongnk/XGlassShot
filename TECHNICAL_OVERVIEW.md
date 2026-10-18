# Architecture

The GUI is a sandboxed SwiftUI macOS app. ScreenCaptureKit supplies pixels; Apple Vision performs local OCR. No cloud AI service, network client, analytics or StoreKit product is part of the app.

## Capture and display ownership

`OverlayManager` and `CaptureSession` serialize selection, capture and recording finalization. Each selection belongs to a concrete display ID. `SelectionOverlay` provides a window per display, activates the selected screen and cancels when the layout changes. `CaptureGeometry` transforms the rectangle into top-left coordinates local to that exact display and rejects invalid/missing targets. Never fall back to another display or to a full-screen image.

`ScreenRecorder` uses the validated region and chosen 1×/2× quality. `RecordingWriter` serializes samples and encoder state on its sample queue and validates finalization before success. Recordings are video-only MOV files. Staged recovery files survive cancelled or failed saves.

## Files and previews

`StorageManager` holds a security-scoped bookmark for the user's selected save directory. The latest capture holds an independent grant so changing the destination does not invalidate preview/OCR/editing access. Failed bookmark creation leaves the existing destination intact. `CaptureFileStore` sanitizes prefixes, generates collision-resistant names and performs exclusive automatic writes.

`CaptureThumbnail` uses ImageIO downsampling. Preview results are checked against the current URL before publication. OCR runs off the UI thread; follow-up requests carry their actual capture URL. Beautification presentation uses an identifiable request rather than a Boolean plus a separately mutable file URL.

## Appearance

`AppAppearance` persists System/Day/Night and background transparency. `BackgroundImageStore` validates and normalizes imported images to a local PNG with a 2400-pixel longest-side bound; failed imports preserve the current image. `GlassSurface` changes only the background. Native material under controls preserves readability. Reduce Transparency wins over decorative background effects.

## Automation

The separate Swift package under `glasscap-cli/` exposes JSON discovery, screenshot and recording commands. It has its own caller permissions and explicit destinations. The GUI's sandbox preferences are not a hidden CLI configuration channel. See [the CLI contract](glasscap-cli/README.md).

## Verification and release

Core tests cover geometry/session boundaries, exclusive file writes, recording finalization, thumbnail bounds, OCR, image composition and background persistence. Display checks require physical hardware; unit tests cannot establish behavior after unplugging a monitor. See [contributing](CONTRIBUTING.md), [UI review](docs/apple-ui-workflow.md) and [store release](docs/Fastlane.md).
