#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${1:?Usage: verify-shortcut-migration.sh /absolute/DerivedData}"
products="$build_root/Build/Products/Release"
evidence="$project_root/build/shortcut-migration"
mkdir -p "$evidence/migration.app/Contents/MacOS"

# Compile the actual preference initializer against the app's built dependency.
# The fixture uses a separate bundle domain and never touches app preferences.
ruby - "$project_root" "$evidence" <<'RUBY'
root, evidence = ARGV
source = File.read(File.join(root, "XGlassShot/ShortcutsManager.swift"))
names = source[/enum AppShortcut:.*?(?=\n@available\(macOS 12\.3)/m]
method = source[/    private func setupDefaultShortcuts\(\) \{.*?(?=\n    private func setupShortcuts)/m]
abort "Cannot locate shortcut initialization" unless names && method
fixture = "import Foundation\nimport AppKit\nimport KeyboardShortcuts\n"
fixture += "extension String { var localized: String { self } }\n"
fixture += names + "\n@MainActor final class DefaultsHarness {\n"
fixture += "var shortcutBindings: [AppShortcut: KeyboardShortcuts.Shortcut] = [:]\n"
fixture += "init() { setupDefaultShortcuts(); refreshShortcutBindings() }\n"
fixture += method.sub("private func", "func") + "\n}\n"
File.write(File.join(evidence, "ShortcutMigrationHarness.swift"), fixture)
File.write(File.join(evidence, "migration.app/Contents/Info.plist"), <<~PLIST)
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>qa.xglassshot.shortcut-migration</string>
  <key>CFBundleExecutable</key><string>migration</string>
  </dict></plist>
PLIST
RUBY

xcrun swiftc -swift-version 5 -default-isolation MainActor -I "$products" \
    "$evidence/ShortcutMigrationHarness.swift" \
    "$project_root/script/fixtures/ShortcutMigrationRunner.swift" \
    "$products/KeyboardShortcuts.o" \
    -o "$evidence/migration.app/Contents/MacOS/migration"
"$evidence/migration.app/Contents/MacOS/migration"
