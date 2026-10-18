#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
output="${1:?Usage: bash script/verify-displays.sh /absolute/evidence/directory}"
check_directory="$(mktemp -d "${TMPDIR:-/tmp/}glasscap-display-check.XXXXXX")"
check_binary="$check_directory/check"
trap 'rm -f "$check_binary"; rmdir "$check_directory"' EXIT
xcrun swiftc -parse-as-library -swift-version 5 -target arm64-apple-macos14.6 \
    "$root/GlassCap/ScreenRecorder.swift" "$root/GlassCap/RecordingWriter.swift" \
    "$root/GlassCap/CaptureGeometry.swift" "$root/GlassCap/SelectionOverlay.swift" \
    "$root/GlassCap/SelectionOverlayDecorations.swift" "$root/GlassCap/DisplayIdentity.swift" \
    "$root/GlassCap/GlassView.swift" "$root/script/verify-displays.swift" -o "$check_binary"
"$check_binary" "$output"
