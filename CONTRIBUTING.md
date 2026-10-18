# Contributing

Thanks for helping improve XGlassShot. Open an issue for a reproducible bug or discuss a substantial feature before implementing it. Small fixes and documentation improvements are welcome as pull requests.

Use macOS 14.6 or later and Xcode 26.2 or later. Open `XGlassShot.xcodeproj`, select your own development team and a unique bundle identifier when signing locally. No API key or paid service is required to run the app. An unsigned compile can be checked with:

```sh
xcodebuild -project XGlassShot.xcodeproj -scheme XGlassShot -configuration Debug CODE_SIGNING_ALLOWED=NO build
swift test
swift test --package-path xglassshot-cli
```

For UI changes, follow [the Apple UI workflow](docs/apple-ui-workflow.md). Include real Day/Night screenshots and the states you verified. For capture changes, test cancellation, selected-display ownership and output dimensions on actual hardware. Explain any hardware or accessibility settings you could not exercise.

Keep captures, credentials, signing profiles, private keys, personal paths and generated archives out of commits. Use a generic fixture rather than private screen content. Do not enable network calls, analytics, subscriptions or overwrite-on-capture behavior as incidental changes.

Use a concise `<type>: <description>` commit message. Explain the problem, the resulting behavior and your verification in the pull request. Contributions are licensed under the project's MIT license; third-party notices must remain intact.
