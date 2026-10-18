# Build 17 verification

Owner-approved Concept 02 implementation: light/dark/system appearance, adjustable background glass, compact settings sheet, direct directory/prefix controls, and agent CLI discovery/destination options. No cloud AI services.

## Automated checks

- Core tests include safe/unique prefixes, capture/session/display boundaries, recording finalization, 1200px thumbnails, Chinese/English local OCR, and local beautification output.
- The production appearance manager passes 8 isolated checks for updating transparency, persistence, bounds/nonfinite input, and light/dark/system appearance. This covers a recursive published-property assignment caught during GUI slider verification.
- CLI unit tests cover explicit versus generated destinations, Unicode/spaces, no path escape, empty prefixes, and invalid capture regions.
- `script/verify-agent-cli.rb` exercises the production release CLI on hardware: capability/screen discovery, a selected-display Retina PNG, Unicode directory/prefix, collision protection, invalid inputs, and a short playable recording with custom naming.

## Native GUI checks

Verified the main window and content-sized settings sheet in both appearances, including changing the transparency slider from 35% to 65%. Adjust glass without fading text or image pixels. Choose a directory through the native open panel, enter a prefix containing Chinese and spaces, capture, quit/relaunch, and capture from a named secondary monitor. Confirm both captures land in the same directory with that prefix without a new save panel. Restore the owner's original destination/prefix after testing.

Verified local OCR presentation and first-open beautification preview, copy confirmation, and dismissal. Inspect transparency persistence after relaunch. Build and verify the signed Release artifact from a clean committed revision before the final installation.

## Reliability findings fixed during verification

- A new destination was accepted even if bookmark creation failed; it now keeps the previous working destination on error and holds/restores directory access.
- The old OCR request used its default recognition languages, which failed the mixed Chinese/English fixture. Language detection and supported language hints now pass the same fixture; recognition runs off the main actor.
- Beautification presentation previously combined a Boolean and optional URL, producing a blank first sheet. The sheet now owns one identifiable image request and displays a visible failure if loading fails.
- The CLI recording daemon called `dispatch_main()` after suspension on a cooperative executor. The observed crash explicitly reported that dispatch_main must be on the main thread. The daemon now suspends on its signal continuation while the entry point owns the main run loop. Stop validates playable media before returning success.
- Restoring capture quality displayed an unnecessary startup toast. Restore now updates the value silently; deliberate quality changes retain feedback. Cold-start appearance uses NSApplication.shared so it is safe before the application singleton has otherwise been created.

## Limits

Physical monitor removal, mixed backing scales on hardware, disk exhaustion, and every supported localization are not induced by these checks. Hardware recording covers video without audio. The CLI keeps its existing single-recording state-file model; it is not a multi-session recording service.
