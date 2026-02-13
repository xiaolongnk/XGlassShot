# Fastlane (Mac App Store)

- **Lanes:** `bundle exec fastlane deliver_metadata` (metadata only), `bundle exec fastlane release` (build + upload).
- **Env (required):** `FASTLANE_APPLE_ID`, `FASTLANE_TEAM_ID` (e.g. in `~/.zshrc`).
- **Copyright, Support URL, Privacy URL:** Set in **~/.zshrc** (preferred): `export FASTLANE_SUPPORT_URL="https://..."` and `FASTLANE_PRIVACY_URL="https://..."` (or one for both), optionally `FASTLANE_COPYRIGHT="Copyright © ..."`. The sync script runs automatically before `deliver_metadata` and `release` and writes these into each locale’s metadata files for upload. Fallback: `fastlane/metadata/APP_STORE_CONFIG.txt`.
- **Gotchas:** Pass `app_identifier` and `platform: "osx"` in the Fastfile; do not pass `support_url`/`privacy_url` as strings in the Fastfile—use the metadata files above.
- **Full deliver setup and troubleshooting:** `.cursor/skills/app-store-assets/fastlane-deliver.md`.
