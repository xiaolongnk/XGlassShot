#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
output="${1:?Usage: bash script/verify-displays.sh /absolute/evidence/directory}"
check_directory="$(mktemp -d "${TMPDIR:-/tmp/}glasscap-display-check.XXXXXX")"
check_binary="$check_directory/check"
trap 'rm -f "$check_binary"; rmdir "$check_directory"' EXIT
xcrun swiftc -parse-as-library -swift-version 5 -target arm64-apple-macos14.6 \
    "$root/XGlassShot/ScreenRecorder.swift" "$root/XGlassShot/RecordingWriter.swift" \
    "$root/XGlassShot/CaptureGeometry.swift" "$root/XGlassShot/SelectionOverlay.swift" \
    "$root/XGlassShot/SelectionOverlayDecorations.swift" "$root/XGlassShot/DisplayIdentity.swift" \
    "$root/XGlassShot/GlassView.swift" "$root/script/verify-displays.swift" -o "$check_binary"
"$check_binary" "$output"
