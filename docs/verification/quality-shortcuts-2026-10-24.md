# Quality selection and shortcut discovery

- Replaced the nested footer Menu/Picker with a single native menu Picker. Accessibility inspection confirms that both 1× and 2× are direct children, with the selected option marked.
- Added a footer keyboard button, Settings → Shortcuts, and Help → Keyboard shortcuts (Command-/). The reference reads configured global shortcuts from KeyboardShortcuts and groups app and selection-only keys separately.
- The footer and Capture settings show the quality shortcut. Quality feedback names the selected scale, includes the configured shortcut and a Q = Quality mnemonic, and lasts three seconds. Equal-value assignments no longer repeat feedback.
- The selection quality badge observes quality changes and uses the same scale labels.
- Added the new strings to all ten supported language dictionaries.

## Verification

- `swift test`: 22 tests passed, zero failures.
- `bash script/build-local.sh /tmp/xglassshot-quality-shortcuts-build`: Release build and strict code-signature verification passed (Xcode 26.6, existing macOS 14.6 target).
- Native UI: selected both quality options; opened the shortcut reference from the footer and with Command-/; verified Escape dismissal; inspected English and Simplified Chinese, Day and Night, and active/inactive appearances at the existing 500 × 400 window size. Restored English, Follow system and Retina 2× after checks; destination, prefix and background were preserved.
- Unedited screenshots are outside the worktree in `/tmp/xglassshot-quality-shortcuts-evidence/`; build and test logs are `/tmp/xglassshot-quality-shortcuts-{build,tests}.log`.
- The existing Carbon global-hotkey registration is unchanged. App-directed synthetic Command-Shift-Q did not trigger it; physical-key and background-app activation remain unverified. Minimum-size, other localizations and accessibility-setting permutations were not exercised interactively.
