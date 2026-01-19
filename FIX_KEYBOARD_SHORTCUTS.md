# Fix KeyboardShortcuts Dependency

## Issue
The `KeyboardShortcuts` module cannot be found because the package dependency hasn't been added to your Xcode project.

## Solution: Add Package Dependency in Xcode

### Step-by-Step Instructions

1. **Open your Xcode project**
   - Open `GlassCap.xcodeproj` in Xcode

2. **Navigate to Package Dependencies**
   - Click on the **blue project icon** at the top of the file navigator (left side)
   - Select the **GlassCap** project (not the target)
   - Click on the **"Package Dependencies"** tab

3. **Add the Package**
   - Click the **"+"** button at the bottom left
   - In the search field, paste: `https://github.com/sindresorhus/KeyboardShortcuts.git`
   - Click **"Add Package"**

4. **Select Version**
   - Choose **"Up to Next Major Version"**
   - Version: **2.0.0** or later
   - Click **"Add Package"**

5. **Add to Target**
   - Make sure **"KeyboardShortcuts"** is checked for the **GlassCap** target
   - Click **"Add Package"**

6. **Verify**
   - The package should now appear in the Package Dependencies list
   - Build the project (⌘B) - the error should be gone

## Alternative: Quick Fix via Terminal

If you prefer command line:

```bash
cd /Users/rex/data/GlassCap/GlassCap
# Open Xcode project
open GlassCap.xcodeproj
```

Then follow steps 2-6 above in Xcode.

## Verification

After adding the package:
1. Clean build folder: **Product** → **Clean Build Folder** (⌘⇧K)
2. Build: **Product** → **Build** (⌘B)
3. The `import KeyboardShortcuts` error should be resolved

## Note

- `Package.swift` has been removed (it's not needed for Xcode projects)
- Only Swift Package Manager projects need `Package.swift`
- Xcode projects use the Package Dependencies UI instead
