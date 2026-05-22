# glasscap-cli

A standalone Swift command-line tool that exposes GlassCap's screenshot and screen recording functionality to AI agents via a JSON CLI interface.

## Requirements

- macOS 12.3+
- Screen Recording permission granted to the terminal in System Settings > Privacy & Security > Screen Recording

## Installation

```bash
cd glasscap-cli
chmod +x install.sh
./install.sh
```

This builds a release binary and copies it to `/usr/local/bin/glasscap`.

## Usage

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

# Custom path, low quality (1x scale)
glasscap screenshot --quality low --output /tmp/cap.png
```

```json
{"height": 1600, "path": "/Users/rex/Pictures/GlassCap/glasscap-2026-05-23-143201.png", "width": 2560}
```

### Record the screen

```bash
# Start recording (launches a background daemon)
glasscap record start
glasscap record start --screen 0 --region 0,0,1280,800 --quality high --output /tmp/rec.mov

# Stop recording (signals daemon, waits for file to finalise)
glasscap record stop
```

Start response:
```json
{"output": "/Users/rex/Movies/GlassCap/glasscap-2026-05-23-143201.mov", "status": "recording"}
```

Stop response:
```json
{"duration_s": 12.4, "path": "/Users/rex/Movies/GlassCap/glasscap-2026-05-23-143201.mov"}
```

### Errors

All errors exit with code 1 and print a JSON error object:

```json
{"error": "No screen recording permission. Grant permission to your terminal in System Settings > Privacy & Security > Screen Recording."}
```

## Notes

- `--region` takes integer points with a top-left origin: `x,y,width,height`
- `--quality low` captures at 1x scale; `--quality high` at 2x (Retina)
- Recording state is persisted to `~/.glasscap-cli-state.json`; the background daemon exits automatically on `record stop`
- Default screenshot path: `~/Pictures/GlassCap/glasscap-<timestamp>.png`
- Default recording path: `~/Movies/GlassCap/glasscap-<timestamp>.mov`
