# Apple UI development and review

XGlassShot is a compact macOS utility, targeting macOS 14.6+. The preview is the main content; its controls should be quiet, native, keyboard-accessible, and readable over either background style.

## Sources and skills

Apple's [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines) and [Materials guidance](https://developer.apple.com/design/human-interface-guidelines/materials) are the authority. Community skills are review aids, not Apple certification. Match advice to macOS and verify API declarations in the installed SDK before adopting it. Do not apply iOS-only sizing/navigation rules or change deployment/Swift targets because a skill suggests a newer baseline. The toolchain checked on 2026-10-18 is Xcode 26.6 / Swift 6.3.3; the project retains its existing language/build settings.

Complementary skills are installed in this owner's Codex skills directory. Their guidance is MIT-licensed; they add no app runtime dependencies:

| Skill | Pinned source | Use |
|---|---|---|
| `swiftui-pro`, Paul Hudson | [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill/tree/ce32af1693b9e78a7d22ff48001c97a304d32063/swiftui-pro) | Partial review of changed SwiftUI: API availability, view composition, semantic styles, accessibility, and performance when relevant. |
| `macos-design-guidelines` | [ehmo/platform-design-skills](https://github.com/ehmo/platform-design-skills/tree/dc2be825d8b439caea78e9eaa8fb3ac23b0ff3e9/skills/macos) | Mac toolbars, menus, sheets, system colors, window behavior, pointer and keyboard interaction. Apply only rules appropriate to this single-purpose utility. |
| `swiftui-expert-skill`, AvdLee | [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill/tree/204dba7c67256a8b707ee3fbc5759a824191974f/skills/swiftui-expert-skill) | Focused native layout, localization, toolbar and focus review. The installed Mac window example has a recorded local correction for closure arity and `DisplayProxy.visibleRect`, verified against Xcode 26.6. |

Read `SKILL.md` from `$CODEX_HOME/skills/<skill>` (normally `~/.codex/skills/<skill>`), then load only references relevant to the change. Use the Mac checklist plus a focused SwiftUI review; avoid duplicating every checklist in each review. Do not install the entire Apple skill ecosystem or silently update pinned guidance during feature work. Compile proposed API examples against the actual SDK before adopting them.

Discovery snapshot on 2026-10-18: Skills CLI reported approximately 33.7K installs for SwiftUI Pro and 4.1K for macOS Design Guidelines; GitHub reported 6,206 and 615 repository stars. Popularity was only a discovery signal; the actual skill text and relevant references were reviewed before use.

## Before implementation

1. Identify the concrete usability or appearance problem, the affected actions, and a visible success criterion. Read current code and capture a baseline.
2. Check `xcodebuild -version`, the deployment target, and availability of proposed APIs. Prefer existing native controls; no unrelated architecture migration or new app dependency.
3. Define control hierarchy: content actions use neutral native styling; reserve prominent accent fill for a genuine confirmation/default action. Never force one tint across a content container that contains unrelated controls.
4. Keep image pixels independent of background opacity. Use semantic primary/secondary foregrounds. Preserve system focus indicators, labels, disabled states, and recording-state semantics.

## Main toolbar alignment

The capture, display, recording and Settings controls form one compact group at the **trailing edge** of the main window. The area between the traffic lights and the controls is flexible space. Do not add a noninteractive app-name badge or rely on a semantic placement alone to establish alignment. Use the native toolbar spacer on supported systems and retain the older macOS fallback.

Verify the actual right inset at the minimum, default and larger window sizes; resizing must expand the empty space rather than leave the actions near the middle. This is XGlassShot's product layout contract, not a rule that every Mac app must place all actions on the right.

## Verify before delivery

History controls sit beside the image at vertical center and reserve room instead of covering image pixels. Copy/OCR/beautify/reveal must operate on the displayed record. History persistence retains file access grants and metadata only; it must not delete original images or replace a valid clipboard when loading fails.

Saving configuration belongs in **Settings → Saving**, using the same fixed-size sheet and glass surface as every other settings tab. Prefix shortcuts and footer/menu entry points call `SettingsPresentation.show(.saving)`; do not recreate a separate floating destination window. Every request focuses the prefix, including repeated requests while the sheet is open. The directory picker is owned by the settings sheet and returns focus to the prefix on completion.

- Build and verify the signed app; run relevant core tests. Do not add implementation-mirroring tests for a reversible style change.
- Inspect native UI in **Day and Night**, with both **active and inactive windows**. Include hover/pressed feedback, Tab/Shift-Tab focus, Space/Return activation where applicable, and Esc dismissal. Record which states actually ran; do not infer active appearance from an inactive screenshot.
- Check the narrow supported window size and a larger window. Ensure actions, labels, and display selection remain available. Check a longer localization when labels/layout change.
- Check contrast over a custom image and desktop glass, including transparency extremes. Exercise Reduce Transparency/Increase Contrast when changing their behavior; otherwise retain the existing adaptation and state any untested setting.
- Exercise the changed actions. For capture-engine or display-selection changes, relist physical displays and verify the selected display, output region, and scale. An appearance-only change does not require replaying the entire recording hardware suite.
- Save unedited native screenshots plus build/test evidence outside the source worktree. Preserve the owner's destination/prefix, appearance, and background preferences after temporary checks.
- Review the scoped diff, commit/push under the repository's git policy, verify the installed source revision, and close out the task worktree. Report remaining gaps accurately.

For the 2026-10-18 button fix, the regression was inherited blue tint combined with glass styles across the whole content action row. Main capture uses native automatic toolbar styling; copy/OCR/beautification/reveal use neutral bordered controls with semantic foregrounds. Dialog confirmation buttons retain their native prominent/default behavior. The app icon can retain its identity color without turning every action into a colored primary button.
