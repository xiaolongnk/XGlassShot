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

- **support_url** / **privacy_url** in the `deliver()` call — Deliver expects a Hash, not a String. Use **metadata files** instead: in each locale folder add `support_url.txt` and `privacy_url.txt` containing the URL (one line). Same for **copyright**: add `copyright.txt` per locale. Deliver uploads these automatically.

## App Store Connect prerequisites

- The app must exist in App Store Connect with at least one version (e.g. 1.0) in an editable state. Otherwise deliver retries with **Cannot find edit app store version**.
- **App name** — If you see **The app name you entered is already being used**, the name is taken by another account. Change the name in `metadata/<locale>/name.txt` to a unique one or resolve the conflict in App Store Connect.

## Non-interactive / CI

Deliver must be able to resolve credentials and app without prompts. Ensure:

1. `app_identifier` is set in the `deliver()` call.
2. `FASTLANE_APPLE_ID` and `FASTLANE_TEAM_ID` (or equivalent) are set in the environment.
3. Platform is set to `"osx"` for Mac apps.

## Metadata folder

- `fastlane/metadata/<locale>/`: `name.txt`, `subtitle.txt`, `description.txt`, `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `primary_category.txt`, `secondary_category.txt`, **`copyright.txt`**, **`support_url.txt`**, **`privacy_url.txt`** (one line each; same URL for support and privacy is fine).
- **Single source:** Prefer **ENV** from `~/.zshrc`: `FASTLANE_SUPPORT_URL`, `FASTLANE_PRIVACY_URL` (if only one is set, it is used for both), `FASTLANE_COPYRIGHT`. The sync script (run automatically before deliver_metadata/release) reads ENV first, then falls back to `fastlane/metadata/APP_STORE_CONFIG.txt`, and writes support_url.txt, privacy_url.txt, copyright.txt into all locale folders.
- Locales: e.g. `en-US`, `zh-Hans`. First version: deliver may skip `release_notes` (no previous version).

## Script path when run from Fastlane

- The sync script must be invoked with an **absolute path** (or path relative to project root). Fastlane may run with a different cwd, so use in the Fastfile: `project_root = File.expand_path("..", File.dirname(__FILE__))` and `sh("ruby \"#{File.join(project_root, 'fastlane', 'scripts', 'sync_metadata_urls.rb')}\"")`.

## "No data" on first version (metadata-only)

- When uploading metadata for the **very first** app version (no build uploaded yet), deliver can fail with **RuntimeError: No data** in `fetch_app_store_review_detail`. The App Store Connect API returns no review detail until the version has a build or has been set up further.
- **Workaround:** Create the version in App Store Connect and either (1) upload a build once (e.g. via Xcode or `fastlane release`), or (2) fill in the version metadata once manually in ASC. After that, `deliver_metadata` will work for subsequent updates.
