#!/usr/bin/env bash
# Regenerate the Xcode project from project.yml and build for the simulator. Run this after
# adding/removing/renaming any source file (XcodeGen has to re-scan the PhomTaLa/ tree).
set -euo pipefail
cd "$(dirname "$0")"

echo "==> xcodegen generate"
xcodegen generate

DEVICE_ID="${1:-}"
if [ -z "$DEVICE_ID" ]; then
    DEVICE_ID=$(xcrun simctl list devices available | grep -m1 -E "iPhone .*Pro Max" | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
fi
if [ -z "$DEVICE_ID" ]; then
    echo "No available iPhone simulator found; pass a device UDID as \$1." >&2
    exit 1
fi

echo "==> building for simulator ($DEVICE_ID)"
xcodebuild -project PhomTaLa.xcodeproj -scheme PhomTaLa -configuration Debug \
    -sdk iphonesimulator -destination "id=$DEVICE_ID" build

echo "==> done"
