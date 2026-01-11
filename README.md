# ScreenKit

A macOS screen recording application with a modern UI and global keyboard shortcuts.

## Features

- 🎥 Screen recording with region selection
- ⌨️ Global keyboard shortcuts
- 🎨 Modern glassmorphism UI
- 📁 Customizable save paths and prefixes
- 🔒 Permission management

## Requirements

- macOS 12.3 or later
- Xcode 14.0 or later
- Swift 5.9 or later

## Setup Instructions

### Option 1: Create Xcode Project Manually

1. Open Xcode
2. Create a new project:
   - Choose "macOS" → "App"
   - Product Name: `ScreenKit`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `macOS 12.3`

3. Add all Swift files from this directory to your project

4. Add KeyboardShortcuts dependency:
   - File → Add Package Dependencies
   - URL: `https://github.com/sindresorhus/KeyboardShortcuts.git`
   - Version: `2.0.0` or later

5. Configure Info.plist:
   - Add `NSScreenCaptureUsageDescription` (already in Info.plist)
   - Add `NSCameraUsageDescription` (already in Info.plist)

6. Set deployment target:
   - Project Settings → General → Minimum Deployments → macOS 12.3

### Option 2: Use Swift Package Manager

1. Open Terminal
2. Navigate to project directory
3. Run: `swift package generate-xcodeproj` (if needed)
4. Open the generated `.xcodeproj` in Xcode

## Project Structure

```
ScreenKit/
├── ScreenKitApp.swift          # Main app entry point
├── ContentView.swift           # Main window view
├── ScreenRecorder.swift        # Screen recording service
├── SelectionOverlay.swift      # Region selection UI
├── OverlayManager.swift        # Overlay coordination
├── ShortcutsManager.swift      # Global shortcuts
├── PermissionManager.swift     # Permission handling
├── CommandBar.swift            # Command pill UI
├── DashboardSettingsView.swift  # Settings view
├── GlassView.swift             # Glass effect component
├── TerminalPathInput.swift     # Path input with autocomplete
└── Info.plist                  # App configuration
```

## Keyboard Shortcuts

- **⌘⇧1** - Capture Zone (start recording)
- **⌘⇧P** - Quick Change Path
- **⌘⇧L** - Quick Change Prefix

## Permissions

On first launch, the app will request:
- Screen Recording permission (required)
- Camera permission (optional, for future features)

## Building

1. Open `ScreenKit.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and Run (⌘R)

## License

Copyright © 2024. All rights reserved.
