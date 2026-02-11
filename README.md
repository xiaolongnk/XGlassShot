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
- `⌘ ⇧ P`: **Change Path** (Quickly select a new default save directory)
- `⌘ ⇧ L`: **Set Filename Suffix** (Quickly focus the filename suffix input)

## 🛠️ Technical Requirements

- **macOS**: 12.3 or later (ScreenCaptureKit support required)
- **Xcode**: 14.0+
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
