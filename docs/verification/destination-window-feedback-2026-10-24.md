# Main window, destination editor and complete quality feedback

The prefix shortcut created a borderless `NSWindow`, which cannot become key by default, then reassigned first responder to the hosting view after SwiftUI focused its TextField. The native reproduction confirmed that the old window cannot become key and the replacement titled `NSPanel` can.

- Main window: one shared default of **600 × 500**, minimum **520 × 460**. Both AppKit and SwiftUI use the same constants. Settings stays **460 × 380**.
- Saving panel: the shortcut, Capture menu and footer prefix button use the same editor. It presents the current folder, a native directory picker and a focused editable prefix. Changes save automatically; Return, Done, Escape and the native close button dismiss it. Reopening a visible panel reuses it; reopening a closed panel creates a new one.
- Folder selection uses the existing bookmark/grant persistence and opens as a sheet owned by the editor, then returns focus to the prefix field. Cancelling selection preserves the destination.
- Quality feedback: fixed 440-point width, wrapping text, and native content-size measurement after each update. Shadow padding participates in measurement, removing the old window/content width mismatch.

## Verification

- `swift test`: 22 tests passed with zero failures. Signed Release build and strict signature verification passed.
- Native UI: typed a different prefix, selected a temporary directory, confirmed both in the panel and footer, dismissed/reopened the editor and confirmed persistence. Tested directory cancellation, Return completion, native close and reopen. Restored `Pictures`, the original prefix and the original 1× quality.
- Main screenshot measured **1200 × 1000 pixels** at 2×; Settings remained **920 × 760 pixels**. Native editor accepted keyboard input and regained input focus after directory selection.
- A temporary offscreen Swift/AppKit harness rendered the actual `QualityFeedbackView` and localization sources for all ten languages and both qualities, with the default shortcut text as fixture data. All 20 native fitted sizes were **440 × 90**. English, Simplified Chinese and German renders were visually checked: all text, symbols and borders are complete.
- Evidence and the reproducible layout/focus harness: `/tmp/xglassshot-destination-window-evidence/`. Build/test logs: `/tmp/xglassshot-destination-window-{build,tests}.log`.
- Carbon global-key delivery and additional accessibility-setting permutations were not exercised by the automation. The existing registered keys are unchanged; their prefix callback now invokes the same editor tested through native controls.
