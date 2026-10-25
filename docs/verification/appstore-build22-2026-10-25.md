# XGlassShot 1.0 / Build 22 submission

Owner authorized publishing the current local feature set to Apple review on October 25, 2026. The submitted binary includes screenshot history navigation and original-image copying, compact settings, editable Saving settings and keyboard-shortcut improvements.

## Apple read-back

- App: XGlassShot, `6757980673`, bundle `com.xiaolongou.glasscap`.
- Version: `1.0`, version ID `a9b5b589-879a-49c2-be6b-17d9f65c1e43`.
- Build: `22`, build ID `bfcbb97d-12e5-47fd-a868-137e357290d5`; processing `VALID`, non-exempt encryption `false`.
- New review submission: `0a19819b-e33c-4704-850e-3ff69a4ca7b8`, submitted October 25 at **03:17:06 PDT** (`2026-10-25T10:17:06.09Z`).
- Independent final GETs confirmed both submission and version were `WAITING_FOR_REVIEW`, with Build 22 selected. This is not approval.
- Existing release mode remains `AFTER_APPROVAL`.

The prior waiting submission for Build 21 was canceled only after Build 22 had uploaded and reached VALID. The prior submission became COMPLETE and the version became DEVELOPER_REJECTED before its build was replaced. Exactly one version item was added to the new review submission.

## Artifact and verification

- Source revision: `862fde99d5cf`, committed and pushed to main before archiving.
- PKG SHA-256: `95073da7dab8da0fd3d24006360d983660af6aa1468f6c93849e2352714a8bf9`.
- Core tests: **29 passed**. CLI tests: **7 passed**. Native behavior and cross-app full-resolution paste verification are recorded in [the history report](capture-history-2026-10-25.md).
- Expanded the actual uploaded PKG and verified version/build/revision, arm64 + x86_64 architectures, strict distribution signature, sandbox, embedded profile/team and privacy manifest; no development debug entitlement.
- Existing valid signing profile: `GlassCap Mac App Store Release 20261018`, team `UU76YYR83R`. The Fastfile default profile name was not installed; using its supported `GLASSCAP_STORE_PROFILE` override resolved export. No new signing privileges or credentials were created.
- Used locked Fastlane 2.241.1 dependencies in ignored `build/release-gems` with Ruby 4.0.1. Set `FASTLANE_SKIP_DOCS=1` so generated tracked README changes do not invalidate the clean-source archive gate.
- Existing base price and all 174 automatically priced territories remained zero; no IAP or subscription groups. Support, marketing and privacy URLs returned HTTP 200. Existing three 1280 × 800 screenshots per en-US/zh-Hans locale remained COMPLETE and were preserved; no private verification captures were uploaded.
- Preserved listing descriptions, contacts and privacy settings. App Review notes were extended with history/copy/Saving/shortcut testing steps. Apple rejected editing `whatsNew` for the initial version; existing store text was left intact, and the prepared release notes remain in source.

Release artifact, full API snapshots and logs remain in ignored `build/store-20261025/`, including `preflight.json`, `package-verification.json`, `upload.log`, `final-version.json`, `final-submission.json` and `final-summary.json`. Credential material is not included in this report or source control.
