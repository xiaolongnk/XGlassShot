# Alternative Ways to Add KeyboardShortcuts

## Method 1: Direct GitHub URL (Try This First)

1. In Xcode, go to **File** → **Add Package Dependencies...**
2. In the search field, paste exactly:
   ```
   https://github.com/sindresorhus/KeyboardShortcuts
   ```
   (Note: without `.git` at the end)
3. Click **Add Package**
4. Select version **2.0.0** or later
5. Make sure **screenKit** target is checked
6. Click **Add Package**

## Method 2: Search in Xcode

1. In Xcode, go to **File** → **Add Package Dependencies...**
2. Type in the search box: `KeyboardShortcuts`
3. Look for: `sindresorhus/KeyboardShortcuts`
4. Select it and click **Add Package**

## Method 3: Manual Package.swift (If Xcode UI Fails)

If the Xcode UI continues to fail, we can create a temporary Package.swift to resolve dependencies, then remove it.

## Method 4: Check Network/Proxy

If you're behind a corporate proxy or firewall:
- Check your network connection
- Try using a different network
- Check if GitHub is accessible

## Verify the Package Exists

The package should be at: https://github.com/sindresorhus/KeyboardShortcuts

Try opening this URL in your browser to verify it's accessible.
