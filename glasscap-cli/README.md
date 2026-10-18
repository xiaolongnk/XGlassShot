# glasscap-cli

A standalone Swift command-line tool that exposes GlassCap's screenshot and screen recording functionality to AI agents via a JSON CLI interface.

## Requirements

- macOS 14.0+
- Screen Recording permission granted to the terminal in System Settings > Privacy & Security > Screen Recording

## Installation

```bash
cd glasscap-cli
chmod +x install.sh
./install.sh
```

This builds a release binary and installs it into `~/.local/bin/glasscap`. Add `~/.local/bin` to PATH if needed. An optional first argument to `install.sh` selects a different install directory.

## Usage

### Discover the interface

```bash
glasscap capabilities
```

This returns schema version 1, supported commands/options, JSON result fields, coordinate rules, and permission requirements. It does not request capture permission. The GUI keeps its own sandbox directory grants; pass explicit CLI destinations to keep agent runs predictable.

### List screens

```bash
glasscap screens
```

```json
{
  "screens": [
    {"index": 0, "name": "Built-in Retina Display", "width": 2560, "height": 1600, "primary": true}
  ]
}
```

### Take a screenshot

```bash
# Full primary screen, default output path
glasscap screenshot

# Specific screen, specific region
glasscap screenshot --screen 1 --region 0,0,1280,800

# A directory and prefix, including spaces and Unicode
glasscap screenshot --screen 1 --directory "$HOME/Pictures/项目 A" --prefix "design review"

# Custom path, low quality (1x scale)
glasscap screenshot --quality low --output /tmp/cap.png
```

```json
{"height": 1600, "path": "/Users/rex/Pictures/GlassCap/glasscap_20261017-143201-000-A1B2C3D4.png", "width": 2560}
```

### Record the screen

```bash
# Start recording (launches a background daemon)
glasscap record start
glasscap record start --screen 0 --region 0,0,1280,800 --quality high --directory /tmp/review --prefix agent

# Stop recording (signals daemon, waits for file to finalise)
glasscap record stop
```

Start response:
```json
{"output": "/Users/rex/Movies/GlassCap/glasscap_20261017-143201-000-A1B2C3D4.mov", "status": "recording"}
```

Stop response:
```json
{"duration_s": 12.4, "path": "/Users/rex/Movies/GlassCap/glasscap_20261017-143201-000-A1B2C3D4.mov"}
```

### Errors

Runtime capture failures exit with code 1 and print a JSON error object:

```json
{"error": "No screen recording permission. Grant permission to your terminal in System Settings > Privacy & Security > Screen Recording."}
```

## Notes

- `--region` takes integer points with a top-left origin: `x,y,width,height`
- `--quality low` captures at 1x scale; `--quality high` at 2x (Retina)
- Recording state is persisted to `~/.glasscap-cli-state.json`; the background daemon exits automatically on `record stop`
- Default screenshot path: `~/Pictures/GlassCap/glasscap-<timestamp>.png`
- Default recording path: `~/Movies/GlassCap/glasscap-<timestamp>.mov`

### Safe screenshot automation

Screenshots refuse to overwrite an existing `--output` file. Automatic filenames include a random suffix. A missing display, zero-sized region, or region outside the selected display fails instead of capturing unexpected content. Use `--region=-10,0,100,100` when testing negative coordinates so the argument parser treats the value as a single argument.

Capture failures are returned as JSON with exit code 1. Invalid command-line syntax is reported by Swift ArgumentParser on stderr.

## Destination contract

- `--output` preserves the exact filename and requires its parent directory to exist. It cannot be combined with `--directory` or `--prefix`.
- `--directory` creates the directory tree as needed. Without it, automatic screenshots use `~/Pictures/GlassCap` and recordings use `~/Movies/GlassCap`.
- `--prefix` defaults to `glasscap`; an empty prefix is supported. Automatic names use `<prefix>_yyyyMMdd-HHmmss-SSS-<random>.png` or `.mov`.
- Prefixes preserve Unicode and interior spaces, omit filename separators `/`, `:`, NUL and newlines, trim surrounding whitespace, and use at most 60 characters. These rules match the GUI's filename policy.
- Quality must be `low` or `high`. Invalid regions and screen indexes fail; recording inputs are checked before the background daemon starts.
- `record stop` waits for a stable, readable video with a video track and positive duration. If finalization fails, it reports an error and retains the output for inspection.

## Verification

```bash
swift test --package-path glasscap-cli
ruby script/verify-agent-cli.rb /absolute/path/to/glasscap /absolute/path/to/evidence-directory
```

Run the hardware script from the repository root with screen-capture permission already granted. It writes local test PNG/MOV files, exercises directories/prefixes with spaces and Chinese characters, checks overwrite protection and JSON failures, and records briefly on the second display when available. It never stops a pre-existing recording.
