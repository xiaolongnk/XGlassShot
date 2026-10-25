# Compact, stable Settings sheet

The sheet previously used its current tab's intrinsic height with `fixedSize(vertical: true)`. The single-column shortcut reference made it 622 points tall; shorter tabs shrank it again.

Settings now has one 460 × 380 point frame with a bounded, scrollable content region. The title, tabs and Done button stay outside the scroll region. Shortcuts use compact columns grouped for accessibility, preserving the configured key combinations and mnemonic text.

## Verification

- Signed Release build and strict signature verification passed using `script/build-local.sh`; build log: `/tmp/xglassshot-compact-settings-build.log`.
- Switched through General, Appearance, Capture, Saving and Shortcuts in the native app. Each unedited sheet screenshot measured exactly **920 × 760 pixels** at 2×; header and footer positions were identical.
- Inspected shortcuts in English, Simplified Chinese and German, including Day/Night and active/inactive appearances. All shortcut rows and hints fit without scrolling at the default text size.
- Escape dismissal worked. English and Follow system were restored; the folder, prefix, quality, background and transparency settings were preserved.
- Screenshots: `/tmp/xglassshot-compact-settings-evidence/`.
- No new tests were added for this reversible layout change. Capture/recording behavior is unchanged. VoiceOver execution, accessibility-setting permutations and the remaining localizations were not manually exercised.
