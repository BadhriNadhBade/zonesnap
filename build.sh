#!/bin/bash
# Builds ZoneSnap.app with the Command Line Tools only (no Xcode). macOS 12+.
set -euo pipefail
cd "$(dirname "$0")"
SDK=$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX13*.sdk 2>/dev/null | tail -1 || true)
SDK=${SDK:-$(xcrun --show-sdk-path)}
ARCH=$(uname -m)
APP="build/ZoneSnap.app"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS"
swiftc -O -sdk "$SDK" -target "$ARCH-apple-macos12.0" -module-name ZoneSnap Sources/*.swift -o "$APP/Contents/MacOS/ZoneSnap"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "built $APP"
