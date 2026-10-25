# XGlassShot 1.0 / Build 23 submission

Owner requested submitting the newly installed customizable-shortcuts feature. Confirmed before replacement that withdrawing/resubmitting restarts App Review. The previous Build 22 submission was kept queued until the new binary reached VALID and APP_STORE_ELIGIBLE.

## Apple read-back

- App: XGlassShot, `6757980673`, bundle `com.xiaolongou.glasscap`.
- Version: `1.0`, version ID `a9b5b589-879a-49c2-be6b-17d9f65c1e43`.
- Build: **23**, build ID `b8a3e1e5-04fd-4a59-b6c1-53877306366b`; processing VALID, usesNonExemptEncryption false.
- Submission: `8da254e9-f0a1-4ab5-848b-66d6c732d2ee`, submitted **2026-10-25 06:21:50 PDT** (`2026-10-25T13:21:50.938Z`).
- Independent final GETs confirmed version and submission are both **WAITING_FOR_REVIEW**, and the selected build is 23. This is not approval.
- Existing release mode remains `AFTER_APPROVAL`.

The prior Build 22 submission (`0a19819b-e33c-4704-850e-3ff69a4ca7b8`) was WAITING_FOR_REVIEW when canceled. It reached COMPLETE and version 1.0 reached DEVELOPER_REJECTED before the build relationship was changed. Created a fresh submission with exactly one app-version item, verified Build 23 again immediately before submitting, then independently read back Apple state.

## Artifact and validation

- Source revision: `22f9e4c4508e`, committed and verified on main before archiving. Includes [custom shortcut behavior and native verification](custom-shortcuts-2026-10-25.md).
- PKG SHA-256: `15dc36179dde3995977dbe3b60187a7e8b041761404105f840194c1ab405d400`.
- Toolchain: Xcode 27.1 (27A9275), following completion of its updated first-launch license setup. Ruby 4.0.1 and locked Fastlane 2.241.1; preserved the app's Swift language setting and macOS 14.6 deployment target.
- Re-ran **29 core tests, 7 CLI tests and 13 isolated shortcut scenarios** using the new toolchain and freshly built KeyboardShortcuts module; all passed. Signed local build and archive/export succeeded.
- Expanded the actual uploaded PKG and verified Build 23/version 1.0/source revision, x86_64 + arm64 architectures, strict Apple Distribution app signature, Mac Developer Installer package signature, sandbox, team/profile, privacy manifest and absence of debug entitlements.
- Reused existing valid profile `GlassCap Mac App Store Release 20261018` under team UU76YYR83R. Credentials remain outside source control. FASTLANE_SKIP_DOCS prevented generated README changes from invalidating the clean-source archive gate.
- Base and 174 automatically priced territories remained free; no IAP or subscription groups. Support, marketing and privacy URLs returned HTTP 200. Preserved both locales' three COMPLETE 1280 × 800 screenshots; no private verification screenshots were uploaded.
- Updated en-US and zh-Hans listing descriptions to distinguish default shortcuts from editable settings. Added Build 23 testing instructions to App Review notes, preserving existing notes/contact details and no-sign-in status. The first-version whatsNew restriction was already known, so no unsupported whatsNew edit was attempted.

Full API read-back, signed archive/package, hashes and build/test/upload logs remain in ignored `build/store-build23-20261025/`, including `preflight.json`, `package-verification.json`, `submission-preflight.json`, `final-version.json`, `final-submission.json` and `final-summary.json`. The already installed local feature build and Apple support case were not modified by this submission.
