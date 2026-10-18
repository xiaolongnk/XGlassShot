# GlassCap

**GlassCap** is a high-performance, modern screen recording and screenshot application for macOS, built with **ScreenCaptureKit** and **SwiftUI**. It provides a compact native workspace for capturing regions, recording video, and managing captures with global hotkeys.

## ✨ Features

- **Area Selection**: Intuitive region selection with adjustable borders and real-time dimension feedback.
- **Screen Recording**: High-quality video recording using Apple's latest ScreenCaptureKit API.
- **Instant Screenshots**: Capture any region and save it instantly to your preferred folder.
- **Native Settings**: An independent settings window with General, Capture, and Saving tabs. Choose the destination, filename prefix, quality, capture feedback, and launch-at-login behavior.
- **Global Shortcuts**: Control the app from anywhere on your system.
- **Multi-Monitor Support**: Precise capture and selection across all connected displays.

## ⌨️ Keyboard Shortcuts

- `⌘ ⇧ 1`: **Record Region** (Triggers area selection for video recording)
- `⌘ ⇧ 2`: **Capture Screenshot** (Triggers area selection for instant image capture)
- `⌘ ⇧ Q`: **Toggle Quality** (Switch between 1x and 2x capture)
- `⌘ ⇧ L`: **Set Filename Suffix** (Quickly focus the filename suffix input)

## 🛠️ Technical Requirements

- **macOS**: 14.6 or later
- **Xcode**: 26.2 or later
- **Developer Resource**: Requires Screen Recording permissions in System Settings.

## 📁 Project Structure

```
GlassCap/
├── GlassCapApp.swift      # Application entry point & lifecycle
├── ContentView.swift       # Main window and Command Bar UI
├── SettingsDock.swift      # Floating settings and toggle management
├── ScreenRecorder.swift    # Core SCKit logic, coordinate conversion, and saving
├── SelectionOverlay.swift  # Cross-display SwiftUI selection windows
├── StorageManager.swift    # Robust file storage, bookmarks, and silent save logic
├── ShortcutsManager.swift  # Global hotkey registration and handling
└── Theme.swift             # Centralized design system (colors, shadows, glass)
```

## 🚀 Getting Started

1. **Permissions**: On first launch, GlassCap will request Screen Recording access. You must grant this in *System Settings > Privacy & Security > Screen Recording*.
2. **Shortcuts**: Use `⌘ ⇧ 2` to take your first screenshot.
3. **Save Location**: Click the folder in the status bar to choose the destination, or open Settings → Saving. Enable **Ask where to save** for a save panel after each capture.

## 📜 Recent Development Highlights

- **Activation Fix**: The app now automatically gains focus when triggered via shortcut, allowing immediate interaction without an extra click.
- **Multi-Monitor Accuracy**: Robust display identification enables precise capture on secondary monitors, even with mixed resolutions or non-standard orientations.
- **Optimistic Silent Save**: Faster, quieter saving logic that works reliably within the macOS sandbox environment.

## Reliability baseline (Build 14)

- Cloud AI description and API-key settings have been removed. Local Vision OCR stays on-device. The app clears the legacy `anthropicAPIKey` preference at launch and no longer has a network-client entitlement.
- Selection, capture, recording, and finalization are serialized. Cancelling a selection clears its action; follow-up OCR/beautification is bound to the actual capture URL.
- Automatic captures use collision-resistant names and never overwrite existing files. Explicit replacements through the save panel are staged before replacing the destination.
- A missing display or invalid region produces an error; it never falls back to another display or the full screen.
- Recordings are written under Application Support/GlassCap/Recovery inside the sandbox. Cancelling or failing a save retains the source. Use **Recover Recordings…** in the menu bar to find it. Successfully saved recovery copies are removed.
- Capture and recording failures are shown to the user. The main Record button becomes Stop Recording while recording.

### Verify and build locally

```bash
swift test
bash script/build-local.sh /absolute/path/to/build-directory
```

The local build script embeds the source revision, marks dirty sources, verifies the code signature, and prints the generated app path. It does not install or publish the app. Settings → General shows the version/build; its tooltip shows the source revision.

External tools and AI agents can use the existing `glasscap-cli` JSON screenshot interface. The GUI does not call a model service. See [glasscap-cli/README.md](glasscap-cli/README.md).

## Native capture workspace (Build 16)

The main window opens at 500×380 points, with a 440×300 minimum and an 800×640 maximum. A standard compact macOS toolbar contains screenshot, display selection, recording, and Settings controls. The preview canvas takes the flexible space; a slim information strip holds image actions. System materials, colors, fonts, focus, and hover feedback follow macOS appearance and accessibility preferences. Image previews are downsampled to at most 1200 pixels instead of enlarging 120×80 history thumbnails; the most recent file bookmark is restored before loading. Settings use an independent native window with General, Capture, and Saving tabs, also available with ⌘,. Screenshot actions include a display menu: **Any display** or one named monitor.

Selection ownership is derived from one display ID. Switching displays removes the previous screen's active selection; dragging past an edge is bounded to the selected screen. A screen-layout change cancels an in-progress selection. Capture flash feedback uses the selected display too.

For a real two-display check, grant screen capture access to the terminal and run:

```bash
bash script/verify-displays.sh /absolute/path/to/evidence-directory
```

This compiles the production `ScreenRecorder` and `SelectionOverlay` sources with test-only file storage, checks 20 selection ownership switches, and compares standard and Retina captures against an independent ScreenCaptureKit reference for each connected display. The report includes display IDs, desktop origins, output dimensions, and pixel differences. It does not create or reposition UI windows. The main app is built separately with `script/build-local.sh`.

The Build 16 design pass used [Design macOS Interfaces](https://github.com/0xKoru/apple-hig-codex-skills/tree/6563e765da1e66e5fe443637baeb75eba97b7e35/skills/design-macos-interfaces) alongside the local SwiftUI Expert skill. The layout follows Apple's [macOS guidance](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) and [toolbar conventions](https://developer.apple.com/design/human-interface-guidelines/toolbars). This pass changes the workspace and Settings; the existing selection and beautification editors retain their current controls.
