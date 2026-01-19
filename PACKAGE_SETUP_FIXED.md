# Fix: Adding KeyboardShortcuts Package

## The Error
"Received invalid response at https://github.com/sindresorhus/KeyboardShortcuts.git"

## Solution: Use Correct Method

### Step-by-Step (Try This):

1. **In Xcode, go to:**
   - **File** → **Add Package Dependencies...**
   - (NOT the Package Dependencies tab in project settings)

2. **In the search/URL field:**
   - Type or paste: `https://github.com/sindresorhus/KeyboardShortcuts`
   - **Important:** Remove `.git` from the end if it's there
   - Just use: `https://github.com/sindresorhus/KeyboardShortcuts`

3. **Click "Add Package"**

4. **Select version:**
   - Choose "Up to Next Major Version"
   - Enter: `2.0.0`
   - Click "Add Package"

5. **Select target:**
   - Make sure **GlassCap** is checked
   - Click "Add Package"

## Alternative: If That Still Fails

### Option A: Check Xcode Version
- Make sure you're using Xcode 14.0 or later
- Older versions might have issues

### Option B: Manual Package Resolution
1. Close Xcode
2. Delete these folders if they exist:
   - `~/Library/Developer/Xcode/DerivedData/GlassCap-*`
   - `.build` folder in project directory
3. Reopen Xcode
4. Try adding package again

### Option C: Use Swift Package Manager Directly
Open Terminal in your project directory and run:
```bash
cd /Users/rex/data/GlassCap/GlassCap
swift package resolve
```

Then open the project again in Xcode.

## Verify It Worked

After adding the package:
1. You should see "KeyboardShortcuts" in the Package Dependencies list
2. Build the project (⌘B)
3. The import error should be gone

## Still Having Issues?

If none of these work, I can create a temporary workaround that doesn't require the package, but the KeyboardShortcuts library is the recommended solution for global shortcuts.
