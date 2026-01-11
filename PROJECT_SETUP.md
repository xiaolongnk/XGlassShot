# Xcode Project Setup Guide

## Quick Setup (Recommended)

### Step 1: Create New Xcode Project

1. Open **Xcode**
2. **File** → **New** → **Project** (or ⌘⇧N)
3. Select **macOS** → **App**
4. Click **Next**
5. Fill in:
   - **Product Name**: `ScreenKit`
   - **Team**: (Select your development team)
   - **Organization Identifier**: `com.yourcompany` (or your domain)
   - **Bundle Identifier**: Will auto-fill as `com.yourcompany.ScreenKit`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None` (we'll add files manually)
   - **Minimum Deployment**: `macOS 12.3`
6. Click **Next** and choose a location
7. Click **Create**

### Step 2: Add All Swift Files

1. In Xcode, right-click on the **ScreenKit** folder (blue icon)
2. Select **Add Files to "ScreenKit"...**
3. Navigate to your project directory
4. Select **ALL** these files:
   - `ScreenKitApp.swift`
   - `ContentView.swift`
   - `ScreenRecorder.swift`
   - `SelectionOverlay.swift`
   - `OverlayManager.swift`
   - `ShortcutsManager.swift`
   - `PermissionManager.swift`
   - `CommandBar.swift`
   - `DashboardSettingsView.swift`
   - `GlassView.swift`
   - `TerminalPathInput.swift`
   - `Color+Hex.swift`
5. Make sure **"Copy items if needed"** is checked
6. Click **Add**

### Step 3: Replace Default App File

1. Delete the auto-generated `ScreenKitApp.swift` (if it exists)
2. Keep the one we created (it should already be there)

### Step 4: Add KeyboardShortcuts Dependency

1. In Xcode, select your project (top blue icon)
2. Select the **ScreenKit** target
3. Go to **Package Dependencies** tab
4. Click the **+** button
5. Enter: `https://github.com/sindresorhus/KeyboardShortcuts.git`
6. Click **Add Package**
7. Select version **2.0.0** or later
8. Click **Add Package**

### Step 5: Configure Info.plist

1. Find `Info.plist` in your project
2. Right-click → **Open As** → **Source Code**
3. Replace contents with the provided `Info.plist` file
4. Or manually add these keys:
   - `NSScreenCaptureUsageDescription`: "ScreenKit needs screen recording permission to capture your screen."
   - `NSCameraUsageDescription`: "ScreenKit needs camera access for screenshot functionality."

### Step 6: Set Deployment Target

1. Select your project (blue icon)
2. Select **ScreenKit** target
3. Go to **General** tab
4. Under **Deployment Info**, set **Minimum Deployments** to **macOS 12.3**

### Step 7: Configure Signing

1. Still in **General** tab
2. Under **Signing & Capabilities**
3. Select your **Team**
4. Xcode will automatically create an App ID

### Step 8: Build and Run

1. Press **⌘R** or click the **Play** button
2. On first run, grant **Screen Recording** permission in System Settings

## Troubleshooting

### "Cannot find 'KeyboardShortcuts' in scope"
- Make sure you added the package dependency (Step 4)
- Clean build folder: **Product** → **Clean Build Folder** (⌘⇧K)
- Rebuild: **Product** → **Build** (⌘B)

### "ScreenCaptureKit is only available on macOS 12.3"
- Check deployment target is set to 12.3 (Step 6)

### Permission Denied
- Go to **System Settings** → **Privacy & Security** → **Screen Recording**
- Enable **ScreenKit**

## Project Structure

Your Xcode project should look like:

```
ScreenKit/
├── ScreenKitApp.swift          (Main entry point)
├── ContentView.swift            (Main window)
├── ScreenRecorder.swift
├── SelectionOverlay.swift
├── OverlayManager.swift
├── ShortcutsManager.swift
├── PermissionManager.swift
├── CommandBar.swift
├── DashboardSettingsView.swift
├── GlassView.swift
├── TerminalPathInput.swift
├── Color+Hex.swift
├── Info.plist
└── Assets.xcassets            (Auto-generated)
```

## Next Steps

1. **Test the app**: Press ⌘⇧1 to start recording
2. **Customize**: Modify colors, shortcuts, or UI as needed
3. **Add features**: Extend functionality as required

## Keyboard Shortcuts

- **⌘⇧1** - Capture Zone
- **⌘⇧P** - Change Path
- **⌘⇧L** - Change Prefix

Enjoy your ScreenKit app! 🎉
