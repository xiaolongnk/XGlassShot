#!/bin/bash

# Check if a file was provided
if [ -z "$1" ]; then
    echo "Usage: ./make_icons.sh <source_image.png>"
    exit 1
fi

SOURCE="$1"
OUT_DIR="GeneratedIcons"

# Check if source file exists
if [ ! -f "$SOURCE" ]; then
    echo "Error: File '$SOURCE' not found."
    exit 1
fi

# Create output directory
mkdir -p "$OUT_DIR"
echo "Generating icons from $SOURCE into ./$OUT_DIR/ ..."

# ---------------------------------------------------------
# macOS App Icon Sizes (Based on standard Xcode requirements)
# ---------------------------------------------------------

# 16pt
sips -z 16 16     "$SOURCE" --out "$OUT_DIR/icon_16x16.png"
sips -z 32 32     "$SOURCE" --out "$OUT_DIR/icon_16x16@2x.png"

# 32pt
sips -z 32 32     "$SOURCE" --out "$OUT_DIR/icon_32x32.png"
sips -z 64 64     "$SOURCE" --out "$OUT_DIR/icon_32x32@2x.png"

# 128pt
sips -z 128 128   "$SOURCE" --out "$OUT_DIR/icon_128x128.png"
sips -z 256 256   "$SOURCE" --out "$OUT_DIR/icon_128x128@2x.png"

# 256pt
sips -z 256 256   "$SOURCE" --out "$OUT_DIR/icon_256x256.png"
sips -z 512 512   "$SOURCE" --out "$OUT_DIR/icon_256x256@2x.png"

# 512pt
sips -z 512 512   "$SOURCE" --out "$OUT_DIR/icon_512x512.png"
sips -z 1024 1024 "$SOURCE" --out "$OUT_DIR/icon_512x512@2x.png"

echo "✅ Done! Drag files from '$OUT_DIR' into Xcode."
