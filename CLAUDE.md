# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run

This is a macOS SwiftUI app. Open `GlassCap.xcodeproj` in Xcode and build/run with `Cmd+R`.

**Requirements:** macOS 12.3+, Xcode 14.0+, Swift 5.9+

**External dependency:** KeyboardShortcuts package (https://github.com/sindresorhus/KeyboardShortcuts.git)

## Architecture

### Singleton Managers

The app uses singleton managers that coordinate core functionality:

- **ShortcutsManager** (`ShortcutsManager.shared`): Handles global keyboard shortcuts via KeyboardShortcuts library. Manages floating input windows for path/prefix changes.
- **OverlayManager** (`OverlayManager.shared`): Coordinates the screen selection overlay and recording state. Shows/hides the selection UI and status bar stop button.
- **PermissionManager** (`PermissionManager.shared`): Manages screen recording permission via ScreenCaptureKit APIs.
- **ScreenRecorder** (`ScreenRecorder.shared`): Core recording engine using ScreenCaptureKit and AVFoundation. Handles coordinate conversion between SwiftUI and macOS coordinate systems.

### Recording Flow

1. User triggers `Cmd+Shift+1` -> `ShortcutsManager` -> `OverlayManager.showSelectionOverlay()`
2. `SelectionOverlay` creates a full-screen borderless window for region selection
3. On selection confirm -> `OverlayManager.handleSelectionConfirmed()` -> `ScreenRecorder.startRecording()`
4. Status bar button appears for stopping
5. On stop -> `ScreenRecorder.stopRecording()` -> saves to Desktop

### Coordinate System

ScreenCaptureKit uses macOS coordinate system (origin at bottom-left). The `ScreenRecorder.flipRegion()` method converts SwiftUI coordinates (origin at top-left) to macOS coordinates for capture.

### UI Components

- **SelectionOverlay/SelectionWindow**: Full-screen borderless window with viewfinder-style selection rectangle
- **GlassView**: Reusable glassmorphism effect wrapper using NSVisualEffectView
- **TerminalPathInput**: Path input field with filesystem autocomplete
- **CommandBar**: Top command pill UI component
