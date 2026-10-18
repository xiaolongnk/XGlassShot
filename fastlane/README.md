fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac build

```sh
[bundle exec] fastlane mac build
```

Build XGlassShot.app for release

### mac deliver_metadata

```sh
[bundle exec] fastlane mac deliver_metadata
```

Upload metadata only (no build). Syncs support/privacy/copyright from ENV or APP_STORE_CONFIG, then uploads.

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Build and upload to TestFlight

### mac release

```sh
[bundle exec] fastlane mac release
```

Build and upload to App Store Connect (metadata + .app)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
