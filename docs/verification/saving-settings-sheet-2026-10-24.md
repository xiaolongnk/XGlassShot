# Saving configuration in Settings

Prefix editing now opens the existing **Settings → Saving** tab instead of a separate NSPanel. The shortcut, footer prefix control and Capture menu reuse the same presentation path. This removes the separate black title bar and duplicate destination form while keeping the shared glass appearance and fixed settings dimensions.

Every Saving request explicitly focuses the prefix, even when another tab is open or the existing sheet already has focus elsewhere. A minimized main window is restored before presenting settings. Folder selection uses an owned system picker and returns focus after completion. Starting capture through the global handlers dismisses settings first.

## Verification

- Signed Release build passed using Xcode 26.6 and the existing macOS 14.6 target.
- All **24 core tests passed**, including translation coverage after deleting the old view and removing its package exclusion.
- Native Command-Shift-L opened a Settings sheet with Saving selected and the prefix selected. The footer opened the same sheet; no SaveDestinationPanel was created.
- Triggering the shortcut from General selected Saving. Triggering it again after Tab moved focus to another control selected the prefix again.
- The owned directory picker opened successfully; cancelling preserved the directory and returned focus to the prefix.
- Minimizing the main window and triggering Command-Shift-L returned to Saving with the prefix selected.
- Prefix editing and Return dismissal worked; the owner's new `hello` prefix was preserved after their direct test. Temporary dictation text was removed before that test.

Evidence is under `build/titlebar-20261024/`: native screenshots and AX snapshots, core/build logs, and `install.json` for the final signed artifact. Existing appearance, quality and destination settings were preserved. Capture/recording engines, every locale, older macOS runtime fallback and physical shortcut delivery from another foreground app were not exhaustively retested for this presentation-only change.

## App Store review snapshot

Read-only App Store Connect GET requests at **2026-10-24 23:11 Pacific time** reported:

- App: XGlassShot, ID `6757980673`, bundle `com.xiaolongou.glasscap`.
- macOS version **1.0**, state **WAITING_FOR_REVIEW**; approval is still pending.
- Attached build **21**, uploaded **2026-10-18 02:04:52 Pacific time**, processing state VALID.
- Release type AFTER_APPROVAL. Upload time is not the review submission time.

The local UI changes made after that upload are not in Apple's submitted build. No upload, submission, release, metadata change or withdrawal was performed. The response snapshot is retained in `build/titlebar-20261024/appstore-review.json`.
