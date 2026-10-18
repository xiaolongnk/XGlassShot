#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${1:-$project_root/build/local}"
revision="$(git -C "$project_root" rev-parse --short=12 HEAD)"
if [[ -n "$(git -C "$project_root" status --porcelain)" ]]; then
    revision="$revision-dirty"
fi

xcodebuild -project "$project_root/XGlassShot.xcodeproj" -scheme XGlassShot \
    -configuration Release -derivedDataPath "$build_root" \
    "GLASSCAP_SOURCE_REVISION=$revision" build

app_path="$build_root/Build/Products/Release/XGlassShot.app"
codesign --verify --deep --strict "$app_path"
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :GlassCapSourceRevision' "$app_path/Contents/Info.plist"
printf 'Verified local app: %s\n' "$app_path"
