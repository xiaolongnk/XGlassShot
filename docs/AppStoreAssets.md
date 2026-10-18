# Mac App Store assets

Canonical listing text is under `fastlane/metadata/en-US/` and `zh-Hans/`. Preserve the existing App Store names (XGlassShot / GlassCap for Mac), bundle identifier and app record; the unqualified GlassCap name was previously unavailable. Do not silently rename the store app during upload.

Version 1.0 is free, with no IAP or subscriptions. The app processes captures/OCR locally. The separate CLI is available from source and is not part of the store app package. The supported GUI minimum is macOS 14.6. Do not advertise audio recording, annotations, cloud AI or unsupported older macOS versions.

Use current generic-content screenshots of the real app, not personal verification captures. Apple's Mac screenshot sizes are 1280×800, 1440×900, 2560×1600 or 2880×1800, with no alpha channel. Verify every final image before upload. Source/license/support/privacy pages must be reachable before submission. App Review notes explain permission, selected-display capture, save settings and local follow-up tools.
