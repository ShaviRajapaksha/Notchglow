#!/bin/bash
# Builds NotchGlow and wraps it in a proper .app bundle (menu-bar only, no Dock icon).
#
# Usage:  ./build_app.sh [release|debug] [--universal]
#   --universal   build for both Apple Silicon and Intel (needs the full Xcode toolchain)
#
# Environment:
#   CODESIGN_IDENTITY   e.g. "Developer ID Application: Your Name (TEAMID)". Default "-" (ad-hoc).
#                       A real identity keeps macOS privacy permissions across rebuilds and enables notarization.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="NotchGlow"
CONFIG="release"
ARCHS=""
for arg in "$@"; do
  case "$arg" in
    release|debug) CONFIG="$arg" ;;
    --universal)   ARCHS="--arch arm64 --arch x86_64" ;;
    *) echo "Unknown option: $arg"; echo "Usage: $0 [release|debug] [--universal]"; exit 1 ;;
  esac
done
IDENTITY="${CODESIGN_IDENTITY:--}"
APP="build/$APP_NAME.app"

# Make sure there is an icon (the generated .icns is committed; rebuild it from the iconset if it is missing).
if [ ! -f Resources/AppIcon.icns ] && [ -d Resources/AppIcon.iconset ]; then
  iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
fi

echo "▸ Compiling ($CONFIG${ARCHS:+, universal})…"
# shellcheck disable=SC2086
swift build -c "$CONFIG" $ARCHS
# shellcheck disable=SC2086
BIN_DIR="$(swift build -c "$CONFIG" $ARCHS --show-bin-path)"

echo "▸ Creating $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "▸ Signing (identity: $IDENTITY)"
SIGN_ARGS=(--force --sign "$IDENTITY" --entitlements Resources/NotchGlow.entitlements)
if [ "$IDENTITY" != "-" ]; then
  SIGN_ARGS+=(--options runtime --timestamp)   # hardened runtime, required for notarization
fi
codesign "${SIGN_ARGS[@]}" "$APP"
codesign --verify --strict --verbose=1 "$APP"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
echo "✅ Built $APP (version $VERSION)"
echo "   Run it:      open $APP"
echo "   Install it:  ./install.sh      Make a DMG:  ./build_dmg.sh"
