# XGlassShot automation

XGlassShot is a local macOS screenshot and recording tool. Use its JSON CLI when a task needs a screen capture; screen-content OCR and screenshot styling also exist in the GUI and stay local.

For SwiftUI or visual changes, start with [this app's Apple UI notes](docs/apple-ui-workflow.md), which contain the product's design and interaction requirements. If installed, the global `apple-desktop-ui` skill provides reusable Mac UI guidance; community skills remain optional technical review aids. Match API advice to Apple's current documentation and the actual project SDK. Verify active and inactive native windows; an inactive screenshot alone does not establish button color or contrast.

## Discover and capture

```bash
xglassshot capabilities
xglassshot screens
xglassshot screenshot --screen 1 --region 100,120,640,400 --quality high --directory "$PWD/captures" --prefix "agent-review"
```

- `capabilities` describes the versioned automation contract without prompting for capture permission.
- Relist screens before selecting an index. Regions are points with a top-left origin local to that screen; no fallback to a different monitor or full-screen capture occurs for invalid inputs.
- Use `--output` for an exact filename, or `--directory` and `--prefix` for automatic unique filenames. These forms cannot be combined. Automatic destination directories are created as needed. Screenshots refuse to overwrite existing files.
- GUI directory bookmarks and preferences belong to the sandboxed app. CLI callers should pass explicit destinations and prefixes; the CLI does not silently read or change GUI settings.
- Successful capture commands print JSON on stdout and exit 0; runtime capture failures print `{"error":"..."}` and exit 1. ArgumentParser syntax errors are on stderr. Always check the exit status before consuming `path`.
- Screen capture requires Screen Recording permission for the calling terminal. The CLI never opens a save panel. `capabilities` and `--help` do not require capture permission.
- `record start` supports the same destination flags. Pair it with `record stop`; stop validates playable media before returning success. Do not stop a recording you did not start.

Build with `swift build --package-path xglassshot-cli -c release`. `bash xglassshot-cli/install.sh` installs into `~/.local/bin`; an optional directory argument changes that location. See [xglassshot-cli/README.md](xglassshot-cli/README.md) for response examples and hardware verification.
