# Fastlane (Mac App Store)

- **Lanes:** `bundle exec fastlane deliver_metadata` (metadata only), `bundle exec fastlane release` (build + upload).
- **Env (required):** `FASTLANE_APPLE_ID`, `FASTLANE_TEAM_ID` (e.g. in `~/.zshrc`).
- **Gotchas:** Pass `app_identifier` and `platform: "osx"` in the Fastfile; do not pass `support_url`/`privacy_url` as strings.
- **Full deliver setup and troubleshooting:** `.cursor/skills/app-store-assets/fastlane-deliver.md`.
