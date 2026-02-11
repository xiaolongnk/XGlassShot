---
name: glasscap-project
description: Provides GlassCap (macOS screen capture app) context: ScreenCaptureKit, coordinate conversion, overlay/recorder architecture, sandbox storage. Use when editing GlassCap, adding capture/screenshot features, or debugging SCKit/display/coordinate issues.
---

# GlassCap Project

## Architecture

- **SelectionOverlay**: One `NSWindow` per `NSScreen`; window level `.screenSaver`. Each hosts `SelectionOverlayView`. Call `NSApp.activate(ignoringOtherApps: true)` when showing overlay so shortcuts bring app to foreground.
- **ScreenRecorder**: Uses `SCStream` (ScreenCaptureKit). Coordinates are display-local: (0,0) = top-left of target display. AppKit uses bottom-left origin; convert before passing to `SCStreamConfiguration.sourceRect`.
- **StorageManager**: Security-scoped bookmarks for user-chosen folders. Optimistic write: try `data.write(to:)` first; on failure fall back to `NSSavePanel`. Do not rely on `FileManager.isWritableFile` in sandbox.

## Critical Rules

1. **sourceRect**: Must be in **local display coordinates**. Normalize selection relative to `NSScreen.frame` (and match `SCDisplay.frame`). Global coords (e.g. negative x for left monitor) cause `SCStreamErrorDomain -3812` ("contentRect does not contain sourceRect").
2. **Display matching**: Get `CGDirectDisplayID` from `NSScreen` via `NSScreenNumber` → `NSNumber` → `.uint32Value` to match `SCDisplay.displayID`. Direct cast to `CGDirectDisplayID` can fail.
3. **Hide overlay**: Set `window.contentView = nil` before `orderOut` to avoid SwiftUI accessing overlay during teardown.

## Key Files

| File | Role |
|------|------|
| `SelectionOverlay.swift` | Overlay windows, selection rect, annotations |
| `ScreenRecorder.swift` | SCStream, `convertToDisplayCoordinates`, recording/screenshot |
| `StorageManager.swift` | Bookmarks, silent save, path/suffix |
| `ShortcutsManager.swift` | Global hotkeys (⌘⇧1/2, etc.) |
| `Theme.swift` | Colors, glass style |
| `TECHNICAL_OVERVIEW.md` | Gotchas and decisions |

## Settings Keys

- `alwaysAskWhereToSave`: false = direct write; true = always NSSavePanel
- `captureQuality`: resolution/scale (e.g. low/high)
- `addScreenshotOutline`: 1px border on screenshots
- `currentPrefix`: filename suffix

## Limits

- Video: `.mov` via `AVAssetWriter`; audio capture not implemented; UI is region-only (no window capture in UI).
