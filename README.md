# GlassCap

**GlassCap** is a high-performance, modern screen recording and screenshot application for macOS, built with **ScreenCaptureKit** and **SwiftUI**. It offers a seamless, "glassmorphism" interface for capturing regions, recording video, and managing your capture workflow with global hotkeys.

## ✨ Features

- **Area Selection**: Intuitive region selection with adjustable borders and real-time dimension feedback.
- **Screen Recording**: High-quality video recording using Apple's latest ScreenCaptureKit API.
- **Instant Screenshots**: Capture any region and save it instantly to your preferred folder.
- **Settings Dock**: A floating, interactive "Command Bar" for quick access to:
    - 📁 **Save Location**: Select and remember your destination folder.
    - 🏷️ **Filename Suffix**: Add custom tags/suffixes to your filenames dynamically.
    - ⚡ **Quality Toggles**: Switch between Performance (Low) and Quality (High) modes.
    - 🔊 **Feedback**: Toggle capture sound effects.
    - 🔳 **Screenshot Border**: Optional 1px stylistic border for all screenshots.
    - 🚀 **Auto Start**: Option to launch at login.
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
3. **Save Location**: Click the Folder icon in the settings dock to set your preferred destination. Enable the **Question Mark Folder** icon if you want to be asked for a location every single time.

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

The local build script embeds the source revision, marks dirty sources, verifies the code signature, and prints the generated app path. It does not install or publish the app. The application header shows the version/build and its tooltip shows the source revision.

External tools and AI agents can use the existing `glasscap-cli` JSON screenshot interface. The GUI does not call a model service. See [glasscap-cli/README.md](glasscap-cli/README.md).
