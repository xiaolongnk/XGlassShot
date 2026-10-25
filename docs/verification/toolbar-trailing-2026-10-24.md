# Trailing main-toolbar actions

The action group previously used `.primaryAction` without flexible space; on this Mac, the native toolbar placed it immediately after the window controls. Removing the app-name item did not establish the requested trailing alignment.

The toolbar now has a native flexible spacer followed by the action group in automatic order. macOS 26 uses `ToolbarSpacer`; earlier supported macOS versions retain a `ToolbarItem`/`Spacer` fallback. The deployment target remains macOS 14.6.

## Verification

- Signed Release build and strict signature validation passed with Xcode 26.6.
- Resized the real native window horizontally to **520**, **600** and **780** points, measured from 1040/1200/1560-pixel screenshots at 2×; height remained 500 points. The action capsule retains the same native right inset at each size and all controls remain visible.
- Restored the default 600-point width. Native accessibility inspection confirms Screenshot, display choice, Record and Settings remain available, with no interactive spacer or app-name badge.
- Screenshots and build log: `build/qa-trailing-toolbar/evidence/` (ignored local evidence).
- The Mac UI workflow now explicitly records this app's trailing alignment contract and requires native-window checks across widths. Existing global `macos-design-guidelines` and `swiftui-pro` skills were reviewed; no additional skill installation or global policy changes were needed.
- Earlier-system fallback appearance and additional theme/accessibility permutations were not exercised in this alignment-only pass.
