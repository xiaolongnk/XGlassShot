# ScreenKit - Quick Start Guide

## 🚀 Create Xcode Project in 5 Minutes

### 1. Create New Project
- Open Xcode → **File** → **New** → **Project**
- Choose **macOS** → **App**
- Name: `ScreenKit`
- Interface: **SwiftUI**
- Language: **Swift**
- Minimum: **macOS 12.3**

### 2. Add Files
- Right-click project folder → **Add Files to "ScreenKit"...**
- Select **ALL** `.swift` files from this directory
- ✅ Check "Copy items if needed"
- Click **Add**

### 3. Add Dependency
- Project Settings → **Package Dependencies** → **+**
- URL: `https://github.com/sindresorhus/KeyboardShortcuts.git`
- Version: `2.0.0+`
- Click **Add Package**

### 4. Configure Info.plist
- Replace `Info.plist` with the provided one
- Or add these keys manually:
  - `NSScreenCaptureUsageDescription`
  - `NSCameraUsageDescription`

### 5. Build & Run
- Press **⌘R**
- Grant Screen Recording permission when prompted

## ✅ That's It!

Your app is ready. Press **⌘⇧1** to start recording!

## 📋 File Checklist

Make sure you have all these files in your Xcode project:

- [x] ScreenKitApp.swift
- [x] ContentView.swift
- [x] ScreenRecorder.swift
- [x] SelectionOverlay.swift
- [x] OverlayManager.swift
- [x] ShortcutsManager.swift
- [x] PermissionManager.swift
- [x] CommandBar.swift
- [x] DashboardSettingsView.swift
- [x] GlassView.swift
- [x] TerminalPathInput.swift
- [x] Color+Hex.swift
- [x] Info.plist

## ⌨️ Keyboard Shortcuts

- **⌘⇧1** - Start recording (capture zone)
- **⌘⇧P** - Change save path
- **⌘⇧L** - Change prefix

## 🐛 Troubleshooting

**"Cannot find KeyboardShortcuts"**
→ Add the package dependency (Step 3)

**"ScreenCaptureKit unavailable"**
→ Set deployment target to macOS 12.3

**Permission denied**
→ System Settings → Privacy → Screen Recording → Enable ScreenKit

## 📚 Next Steps

See `PROJECT_SETUP.md` for detailed instructions.
