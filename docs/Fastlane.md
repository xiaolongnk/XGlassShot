# Mac App Store release

The GUI targets macOS, not iOS. Verify it on a physical Mac; there is no iPhone simulator gate for this target. Run core and CLI tests and inspect Day/Night, capture/cancel, saving, OCR and beautification before upload. The current App Store record is XGlassShot, bundle `com.xiaolongou.glasscap`, app ID `6757980673`.

Use the Gemfile with a supported Ruby and `bundle install`, or an existing Fastlane installation. Keep `~/.fastlane/api_key.json` outside the repository, or configure `ASC_API_KEY_JSON` / `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`. Never print or commit key contents. Contributors building their own fork must use their own app identity, team and profiles.

```sh
swift test
swift test --package-path xglassshot-cli
GLASSCAP_RELEASE_DIR=/absolute/release-directory bundle exec fastlane mac build
GLASSCAP_RELEASE_DIR=/absolute/release-directory bundle exec fastlane mac beta
bundle exec fastlane mac deliver_metadata
```

`build` requires clean committed source, embeds the revision, archives to a fresh release directory and exports a signed `.pkg`. Mac distribution needs both Apple Distribution and Mac Developer Installer private keys, plus the Store provisioning profile. `beta` builds and uploads but does not declare Apple processing successful or submit for review. `release` additionally uploads text metadata. Each lane uses API-key authentication.

Before a public release, verify the exact uploaded build reaches `VALID`, attach it to the matching marketing version, confirm no stale build remains selected, check the free price schedule across territories, reachable support/privacy URLs, current screenshots, privacy answers, review notes and any prior rejection feedback. The App Store listing must remain free, with no IAP/subscriptions. Review submission and availability are separate from binary upload; report the actual server state.

Store screenshots must show real UI with generic content, contain no private captures and meet Apple's Mac dimensions (16:10, e.g. 1280×800). Keep raw evidence and release artifacts outside source. Do not use previous personal verification screenshots as marketing assets. Check the distribution signature, embedded profile, privacy manifest, sandbox and absence of development debug entitlement in the exported app.
