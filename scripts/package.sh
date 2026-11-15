#!/bin/bash
# Build and zip the app for a GitHub release: build/ZoneSnap-<version>.zip
set -euo pipefail
cd "$(dirname "$0")/.."
./build.sh
VERSION=$(plutil -extract CFBundleShortVersionString raw Info.plist)
ditto -c -k --keepParent build/ZoneSnap.app "build/ZoneSnap-$VERSION.zip"
shasum -a 256 "build/ZoneSnap-$VERSION.zip"
