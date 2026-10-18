#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
install_dir="${1:-$HOME/.local/bin}"
swift build -c release
mkdir -p "$install_dir"
install -m 755 .build/release/glasscap "$install_dir/glasscap"
printf 'Installed: %s/glasscap\n' "$install_dir"
printf 'Add this directory to PATH if needed. Run glasscap capabilities to discover the JSON interface.\n'
printf 'Grant screen recording permission to your terminal in System Settings > Privacy & Security > Screen Recording.\n'
