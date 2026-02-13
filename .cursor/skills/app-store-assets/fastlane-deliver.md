# Fastlane deliver — Mac App Store

Use this when setting up or debugging `fastlane deliver` / `deliver_metadata` for a Mac app.

## Required environment variables

Set before running (e.g. in `~/.zshrc`):

- **FASTLANE_APPLE_ID** — Apple ID email (deliver uses it as `username`; also accepts **DELIVER_USER**).
- **FASTLANE_TEAM_ID** — Team ID from [developer.apple.com/account](https://developer.apple.com/account) (Membership details).

Without these, deliver fails with: **No value found for 'username'**.

## Pass these in the Fastfile

In the `deliver()` call, always pass:

- **app_identifier** — Bundle ID (e.g. `"com.example.app"`). Otherwise in non-interactive/CI deliver prompts and crashes: **Could not infer your App's Bundle Identifier**.
- **platform: "osx"** — For Mac App Store. Use `"osx"` only (not `"mac"`). Valid values: `ios`, `appletvos`/`tvos`, `xros`, `osx`. Default is `ios`; without `osx` deliver looks for an iOS version and can report **Cannot find edit app store version**.
- **username** — `ENV["FASTLANE_APPLE_ID"] || ENV["DELIVER_USER"]`.
- **team_id** — `ENV["FASTLANE_TEAM_ID"]`.

## Do not pass as String

- **support_url** / **privacy_url** — Deliver expects a Hash (e.g. per-locale), not a String. Passing a string causes: **'support_url' value must be a Hash! Found String instead.** Set Support URL and Privacy Policy URL in App Store Connect (App Information) instead.

## App Store Connect prerequisites

- The app must exist in App Store Connect with at least one version (e.g. 1.0) in an editable state. Otherwise deliver retries with **Cannot find edit app store version**.
- **App name** — If you see **The app name you entered is already being used**, the name is taken by another account. Change the name in `metadata/<locale>/name.txt` to a unique one or resolve the conflict in App Store Connect.

## Non-interactive / CI

Deliver must be able to resolve credentials and app without prompts. Ensure:

1. `app_identifier` is set in the `deliver()` call.
2. `FASTLANE_APPLE_ID` and `FASTLANE_TEAM_ID` (or equivalent) are set in the environment.
3. Platform is set to `"osx"` for Mac apps.

## Metadata folder

- `fastlane/metadata/<locale>/`: `name.txt`, `subtitle.txt`, `description.txt`, `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `primary_category.txt`, `secondary_category.txt`.
- Locales: e.g. `en-US`, `zh-Hans`. First version: deliver may skip `release_notes` (no previous version).
