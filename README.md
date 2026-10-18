# GlassCap

A free, open-source screenshot and screen-recording utility for macOS. Built with SwiftUI, ScreenCaptureKit and local Apple Vision OCR. No account, cloud AI, analytics, subscriptions or in-app purchases.

The existing Mac App Store record is **XGlassShot** ([store page](https://apps.apple.com/app/id6757980673)); its new free release is being prepared for review. The source project and desktop workspace are called GlassCap.

## Capture, save, automate

- Select an area on the display you choose, including secondary displays. Standard 1× and Retina 2× capture.
- Save screenshots and video recordings to a folder you control. Customize filename prefixes, including Unicode and spaces. Automatic captures never overwrite an existing file.
- Copy images, recognize Chinese/English text locally, or add a background, padding and rounded corners with the local beautification editor.
- Use a compact workspace with Day, Night or Follow System appearance. Import a local background image and adjust background transparency without fading your capture.
- Drive captures from scripts and agents with the JSON CLI: discover capabilities and displays, provide explicit destinations, and check exit status before consuming output.

## Requirements and build

macOS 14.6+ for the GUI (14.0+ for the CLI), Xcode 26.2+ and Screen Recording permission when capturing. The current verified toolchain is Xcode 26.6. Audio recording, scrolling capture and annotations are not included.

```sh
git clone https://github.com/xiaolongnk/screenkit.git
cd screenkit
open GlassCap.xcodeproj
```

Select your own development team and unique bundle identifier in Xcode before running. Apple signing certificates and App Store credentials are not included. For an unsigned compile:

```sh
xcodebuild -project GlassCap.xcodeproj -scheme GlassCap -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

For an already configured signing environment, `bash script/build-local.sh /absolute/build-directory` creates and verifies a signed local app. It does not install, upload or publish it.

## Usage

- **⌘⇧2:** choose an area for a screenshot. Drag, then Return to capture or Esc to cancel.
- **⌘⇧1:** choose an area for recording; stop from the app or menu bar.
- **⌘⇧Q:** toggle capture quality.
- **⌘,:** open settings. **Saving** controls the folder, filename prefix and optional save panel; **Appearance** controls the theme, image and transparency.
- Use the arrow beside Screenshot to select a specific display. No unavailable-display fallback silently captures another screen.
- Recordings cancelled at the save panel remain in the sandbox's recovery folder. Choose **Recover Recordings…** from the menu to find them.

Permission is requested when you start a capture. Allow GlassCap in System Settings → Privacy & Security → Screen Recording if requested, then retry. Full Disk Access and Accessibility access are not prerequisites for ordinary capture.

## Agent-friendly CLI

```sh
bash glasscap-cli/install.sh
glasscap capabilities
glasscap screens
glasscap screenshot --screen 1 --region 100,120,640,400 --quality high --directory "$PWD/captures" --prefix "design-review"
```

Relist displays before selecting an index. Regions are top-left coordinates in points local to that display. Successful commands return JSON and exit 0; capture failures return an error and exit nonzero. The CLI has its own terminal permissions and destinations; it does not silently read sandboxed GUI preferences. See [CLI documentation](glasscap-cli/README.md) and [AGENTS.md](AGENTS.md).

## Verification

```sh
swift test
swift test --package-path glasscap-cli
bash script/verify-displays.sh /absolute/evidence-directory
```

The hardware check uses the production selection/capture sources and requires two physical displays plus Screen Recording permission. See [contributing](CONTRIBUTING.md), the [Apple UI review workflow](docs/apple-ui-workflow.md) and [release process](docs/Fastlane.md). Hardware limitations are recorded explicitly rather than inferred from unit tests.

## Privacy, support and license

Captures, OCR, editing, preferences and imported backgrounds stay on your Mac. The app has no network-client entitlement. Imported backgrounds are retained as bounded local copies. The separate GitHub/support website follows its hosting provider's privacy policy.

- [Privacy policy](https://xiaolongnk.github.io/screenkit/privacy.html)
- [Support](https://xiaolongnk.github.io/screenkit/support.html) and [issues](https://github.com/xiaolongnk/screenkit/issues)
- [Security reporting](SECURITY.md)
- [MIT license](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md)
