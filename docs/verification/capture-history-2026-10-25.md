# Screenshot history browsing and copy

The preview now has Previous image and Next image controls centered on its left and right edges. A position counter identifies the displayed screenshot. Navigation stops at each end, and the existing Copy image action copies the selected original with a brief Copied confirmation. OCR, beautification and Finder reveal use the same displayed file.

The existing clipboard register now retains up to 100 image records across launches. It imports XGlassShot-generated screenshot filenames from the authorized save directory, keeps file bookmarks for later access and preserves stable record IDs. The menu bar still shows five recent items. Only metadata is pruned at the limit; original files are not deleted. Unrelated photographs are not imported. Older arbitrary filenames that predate this feature are included only when known as the last capture; newly saved custom filenames are recorded normally.

Preview thumbnails load away from the main thread, with generation checks to prevent stale results after rapid navigation. Missing files are skipped. Full-size image loading happens inside the file-access scope when copying; failure leaves existing clipboard content intact. A new capture returns the preview to the actual latest capture. When the latest capture is a recording, navigation can return from the image history to that recording.

## Verification

- **29 tests passed**, including five new tests covering chronology, deduplication and bookmark/ID retention, capacity and encoded restart state, selective directory discovery, persistence and deleted files, recording return behavior, original pixel dimensions, stable menu IDs and clipboard preservation on failure. Tests use isolated preferences and a named test pasteboard.
- Native UI discovered **23 existing screenshots**, moved to the oldest end and returned to the newest end. Both boundaries disabled the unavailable arrow. File names, images and the position counter changed together.
- Copied the second historical screenshot and used Preview's New from Clipboard command. The resulting document showed the selected historical image, not the latest capture. The saved local verification PNG and source both measured **678 × 526 pixels**.
- Inspected default 600-point and minimum 520-point widths, active/inactive windows, and Day and system-following Night appearance with the owner's custom background. Navigation did not cover the image, and all existing action buttons remained reachable.
- The final installed build is checked again for history restoration, navigation and the existing Saving shortcut. Package revision, signatures and executable hashes are recorded in `build/history-20261024/install.json`.

Evidence is retained under `build/history-20261024/`, including test/build logs, native screenshots, AX boundary snapshots, `pasted-in-preview.png` and `paste-dimensions.log`. The test document was saved locally and closed; no cloud upload occurred. Original save directory, `hello` prefix, quality, background and appearance were preserved.

VoiceOver operation, every locale's native window, older macOS fallback runtime, and an exhaustive capture/recording hardware suite were not rerun. Current strings were added in all ten supported languages and translation coverage passed. This local package was not submitted to App Store Connect.
