# Native UI and shortcut polish

The quality shortcut previously used Command-Shift-Q, which macOS reserves for Log Out. The default is now **Control-Shift-Q**. Startup migrates only the old default or an unset binding; custom bindings remain intact. Control-Option was excluded because it is a default [VoiceOver modifier](https://support.apple.com/guide/voiceover/control-your-mac-with-keyboard-commands-vo2681/mac). Quality keeps its Q mnemonic.

The Capture menu now uses the existing KeyboardShortcuts library's native shortcut presentation, instead of appending key glyphs to action titles. The footer, settings and quality feedback continue reading the actual saved binding. The shortcut legend now explains Control alongside Command and Shift.

The eight incomplete language dictionaries now contain all 117 English localization keys, including current settings, capture actions, accessibility descriptions and error messages. Japanese, Spanish, French, German, Korean, Traditional Chinese, Italian and Dutch retain their existing translations and gain the missing current strings. Long row labels can wrap vertically within the fixed settings window. No deployment-target, appearance-system or capture-engine migration was needed.

## Verification

- `swift test`: **24 tests passed**. Two new coverage tests reproduced the missing translations before the fix, then passed after it. They also catch Swift UI localization literals absent from the English dictionary.
- `bash script/verify-shortcut-migration.sh <DerivedData>`: four migration cases passed, each repeated to verify idempotence: fresh install, legacy default, custom binding, already migrated. The harness compiles the actual shortcut initializer against the app's built KeyboardShortcuts dependency in an isolated `qa.xglassshot` preferences domain.
- Signed Release build passed with Xcode 26.6 and the existing macOS 14.6 target. The running preview migrated the owner's saved legacy shortcut and displayed Control-Shift-Q in the footer.
- German: all five settings tabs visually inspected, each 920 by 760 pixels at 2x. Long row labels wrap, all tab titles remain visible, and the shortcut page fits its fixed container.
- French: General and Shortcuts inspected, including active selected-tab/default-button appearance. Chinese Shortcuts inspected in Day and Night; previous inactive screenshots also retained.
- Main window checked at 520- and 600-point widths. The trailing action group, quality control, folder and prefix remain available. Default width restored.

Native screenshots, AX state, compiler/test logs and final package/install smoke evidence are stored under `build/ui-polish-20261024/`. The final signed package revision and installed executable hashes are recorded in that directory's `install.json`. Temporary language and appearance changes were restored to English and Follow system; directory `/Users/rex/Pictures`, prefix `mixcrew-macos`, Standard 1x, custom background and 50% transparency were preserved.

Physical global hotkey delivery from other foreground applications, every translated screen, VoiceOver operation, older-macOS fallback execution and accessibility system settings were not exhaustively exercised. Global shortcut migration and persistence are covered by the isolated integration harness; menu activation and installed UI are checked separately. Existing capture/recording engines were unchanged.
