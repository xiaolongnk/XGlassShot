#!/bin/bash
set -e
cd "$(dirname "$0")"
swift build -c release
cp .build/release/glasscap /usr/local/bin/glasscap
echo "Installed: /usr/local/bin/glasscap"
echo "Grant screen recording permission to your terminal in System Settings > Privacy & Security > Screen Recording"
