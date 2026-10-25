# Customizable global shortcuts

Settings → Shortcuts now contains native recorders for Screenshot, Record, Toggle quality and Filename prefix. Click a field and press a new combination; Escape cancels, Delete or the clear button disables that shortcut, and Restore defaults resets all four. Changes persist and apply immediately. Standard in-app and selection-only keys remain listed separately in the same 460 × 380 settings sheet.

The library's initial values replace the previous nil-means-reset startup logic. Explicit disabled records now survive restart, and the old Command-Shift-Q safety migration runs only once. Shortcut hints and Capture menu equivalents use current saved combinations; a custom quality combination no longer displays the Q mnemonic in its feedback banner. Duplicate app actions are validated before saving; native recorder checks warn about reserved system and app-menu combinations. macOS does not provide a complete inventory of arbitrary other apps' shortcuts, so users may still need to choose another combination when an external app interferes.

## Dependency and review

The first native test reproduced a self-conflict in KeyboardShortcuts 2.4.0: recording Screenshot's existing combination was rejected as belonging to its own menu. Updated the existing dependency to exactly **3.1.0**, revision `772133d9dbe800fdac0473226822994c5c162c58`, whose [official release notes](https://github.com/sindresorhus/KeyboardShortcuts/releases/tag/3.1.0) and 3.0 fixes address current-shortcut/menu false positives. Reused its native pre-save validation API, updated the `initial:` initializer and retained all preference key names. No new app dependency, target or language setting was introduced; the signed app still targets macOS 14.6. Updated the bundled MIT notice version.

Review checked persistence/disabled distinction, one-time migration, avoiding duplicate callbacks, input focus and cancellation, stable action identity, localization and reactive hints. The app's source/store metadata and submitted Build 22 were not changed on Apple.

## Verification

- **29 core and 7 CLI tests passed.** Ten-language coverage includes the four new editing/validation strings.
- **13 shortcut harness scenarios passed** against the actual newly built dependency and extracted production configuration methods in an isolated preferences domain: fresh/legacy/custom/already-migrated quality, four disabled actions, custom screenshot persistence, duplicate/self validation, recorder clearing, default restoration and one-time migration. The initial regression failed with `disabled captureZone was restored` before the fix.
- Native UI accepted a new Control-Shift-I screenshot combination. Its toolbar help updated immediately; the key opened the actual selection overlay, which was canceled without writing a capture. A full app restart retained the custom combination.
- App-menu duplicate and Command-Space system conflict alerts appeared; dismissed the system alert without overriding it. Re-recording the current combination succeeded with 3.1.0. Clearing Screenshot prevented the old combination from opening an overlay and remained disabled after a second full restart. Restore defaults re-enabled all four.
- Changed quality to Control-Shift-U; footer/hint updated, and two front-app key presses changed Standard to Retina and back once each. Restored all original shortcuts, Standard quality, English, Follow system, custom Mac Purple background/50% transparency and `hello` prefix.
- Inspected Day/Night, English/Simplified Chinese/German native layouts, including active and inactive appearances. The unchanged sheet dimensions remain 920 × 760 pixels at 2×; long labels and Restore defaults remain available inside the scroll container.

Unedited native screenshots, AX snapshots, regression/build logs, final signed package/install revision and hashes are retained in ignored `build/custom-shortcuts-20261025/`. Physical global-key delivery while another app is foreground, every locale's native UI, older macOS runtime and VoiceOver were not exhaustively rerun. This feature is a local update; the existing Apple Build 22 waiting submission and support case were preserved.
