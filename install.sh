#!/bin/bash
# Builds NotchGlow and installs it into /Applications.
#
# Usage:  ./install.sh [--universal] [--dmg] [--no-open]
#   --universal   build for Apple Silicon and Intel
#   --dmg         also build dist/NotchGlow-<version>.dmg
#   --no-open     don't launch the app afterwards
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="NotchGlow"
DEST="/Applications"
BUILD_ARGS=""
MAKE_DMG=0
OPEN_AFTER=1
for arg in "$@"; do
  case "$arg" in
    --universal) BUILD_ARGS="--universal" ;;
    --dmg)       MAKE_DMG=1 ;;
    --no-open)   OPEN_AFTER=0 ;;
    *) echo "Unknown option: $arg"; echo "Usage: $0 [--universal] [--dmg] [--no-open]"; exit 1 ;;
  esac
done

# shellcheck disable=SC2086
./build_app.sh release $BUILD_ARGS

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  echo "▸ Quitting the running $APP_NAME…"
  osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || pkill -x "$APP_NAME" || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -x "$APP_NAME" >/dev/null 2>&1 || break; sleep 0.3; done
fi

echo "▸ Installing to $DEST/$APP_NAME.app"
if [ -w "$DEST" ]; then
  rm -rf "$DEST/$APP_NAME.app"
  ditto "build/$APP_NAME.app" "$DEST/$APP_NAME.app"
else
  echo "  (administrator password needed to write to $DEST)"
  sudo rm -rf "$DEST/$APP_NAME.app"
  sudo ditto "build/$APP_NAME.app" "$DEST/$APP_NAME.app"
fi
echo "✅ Installed $DEST/$APP_NAME.app"

if [ "$MAKE_DMG" = "1" ]; then
  # shellcheck disable=SC2086
  ./build_dmg.sh $BUILD_ARGS
fi

if [ "$OPEN_AFTER" = "1" ]; then
  open "$DEST/$APP_NAME.app"
fi
echo "ℹ︎ If typing or sound reactions stop after a reinstall, macOS may have reset the app's permissions"
echo "  (ad-hoc signatures change on every build). Sign with a stable identity to avoid that:"
echo "  CODESIGN_IDENTITY=\"Apple Development: Your Name\" ./install.sh"
