# GlassCap Technical Memory & Overview

This document serves as a persistent technical context for LLMs and developers working on the **GlassCap** project. It records architectural decisions, critical discoveries, and "gotchas" that are not immediately obvious from the code.

## 🏗️ Architecture

### 1. Overlay Selection (`SelectionOverlay.swift`)
- **Mechanism**: The app creates an `NSWindow` for every `NSScreen` currently connected. 
- **Window Level**: Uses `.screenSaver` level to ensure overlays appear above almost all other content.
- **SwiftUI Integration**: Each window hosts a `SelectionOverlayView`. Coordinate mapping is extremely sensitive here due to differences between AppKit (bottom-left) and SwiftUI/ScreenCaptureKit (top-left).

### 2. Capture Engine (`ScreenRecorder.swift`)
- **API**: Uses `ScreenCaptureKit` (`SCStream`).
- **Coordinate Conversion**: 
    - `convertToDisplayCoordinates`: Maps SwiftUI logical points back to `SCStreamConfiguration.sourceRect`.
    - **CRITICAL**: `SCStreamConfiguration` expects **local display coordinates**. (0,0) is always the top-left of the target display, regardless of its position in the global desktop layout.
- **Display Matching**: Matches `NSScreen` to `SCDisplay` using `NSScreenNumber`. 
    - **Gotcha**: `NSScreenNumber` must be extracted as `NSNumber` and then converted via `.uint32Value` to match `SCDisplay.displayID`. Direct casting to `CGDirectDisplayID` (UInt32) often fails.

### 3. File Storage (`StorageManager.swift`)
- **Sandbox Compliance**: Uses security-scoped bookmarks to persist access to user-selected folders.
- **Silent Save**: Implements an "optimistic write" pattern.
    - **Decision**: Avoid relying on `FileManager.isWritableFile`. In sandbox, it often returns false for valid paths until an actual write attempt is made.
    - **Pattern**: `do { try data.write(...) } catch { // fall back to NSSavePanel }`

## 🧩 Key Technical Discoveries

### Multi-Monitor Coordinates
- **Discovery**: When using `SCStreamConfiguration`, the `sourceRect` is relative to the `SCDisplay.frame`. If you provide global coordinates (e.g., x: -1920 for a left monitor), the stream will fail with `com.apple.ScreenCaptureKit.SCStreamErrorDomain Code=-3812` ("contentRect does not contain sourceRect").
- **Fix**: Always normalize selection relative to the specific `NSScreen.frame` before passing to the capture engine.

### App Activation via Shortcuts
- **Discovery**: Global shortcuts via `KeyboardShortcuts` do not automatically bring the application to the foreground. This results in the overlay appearing but not responding to mouse/keyboard until the user clicks it manually.
- **Fix**: Call `NSApp.activate(ignoringOtherApps: true)` immediately when showing the selection overlay.

## 🛠️ Feature Matrix & Settings

| Setting | Internal Key | Description |
| :--- | :--- | :--- |
| **Silent Save** | `alwaysAskWhereToSave` | `false` attempts direct write; `true` forces `NSSavePanel`. |
| **Quality** | `captureQuality` | Adjusts resolution/scaling in `SCStreamConfiguration`. |
| **Outline** | `addScreenshotOutline` | Post-processing step applying a 1px border to the final `CGImage`. |
| **Suffix** | `currentPrefix` | User-defined string appended to date-stamped filenames. |

## 🚀 Known Limitations & Roadmap
- **Video Format**: Currently hardcoded to `.mov` via `AVAssetWriter`.
- **Audio Capture**: Not currently implemented.
- **Window Capture**: Logic exists in `SCShareableContent` but the UI is presently focused on region capture.
