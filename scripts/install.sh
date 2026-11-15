#!/bin/bash
# Build ZoneSnap and install it to ~/Applications, then open it.
set -euo pipefail
cd "$(dirname "$0")/.."
./build.sh
mkdir -p "$HOME/Applications"
pkill -x ZoneSnap 2>/dev/null || true
rm -rf "$HOME/Applications/ZoneSnap.app"
cp -R build/ZoneSnap.app "$HOME/Applications/"
open "$HOME/Applications/ZoneSnap.app"
echo "Installed to ~/Applications/ZoneSnap.app"
echo "Allow it in System Settings > Privacy & Security > Accessibility."
