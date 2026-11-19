#!/bin/bash
# Builds NotchGlow and wraps it in a proper .app bundle (menu-bar only, no Dock icon).
# Usage: ./build_app.sh [release|debug]
# Optional: CODESIGN_IDENTITY="My Dev Cert" ./build_app.sh   (keeps macOS privacy grants across rebuilds)
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
IDENTITY="${CODESIGN_IDENTITY:--}"   # "-" = ad-hoc signature

swift build -c "$CONFIG"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

APP="build/NotchGlow.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/NotchGlow" "$APP/Contents/MacOS/NotchGlow"
cp Resources/Info.plist "$APP/Contents/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns" || true

codesign --force --deep --sign "$IDENTITY" "$APP"
echo " Built $APP"
echo "   Run it with:  open $APP"
