#!/bin/bash
# Builds a distributable disk image:  dist/NotchGlow-<version>.dmg
# The DMG contains NotchGlow.app and an "Applications" shortcut, so users just drag one onto the other.
#
# Usage:  ./build_dmg.sh [--universal]
#
# Environment (all optional):
#   CODESIGN_IDENTITY   "Developer ID Application: Your Name (TEAMID)" to sign the app and the DMG
#   NOTARY_PROFILE      name of a notarytool keychain profile; with a real identity the DMG is notarized and stapled
#                       (create it once:  xcrun notarytool store-credentials "NotchGlow" --apple-id … --team-id … )
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="NotchGlow"
IDENTITY="${CODESIGN_IDENTITY:--}"

./build_app.sh release "$@"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
APP="build/$APP_NAME.app"
DMG="dist/$APP_NAME-$VERSION.dmg"
STAGE="build/dmg-stage"

echo "▸ Creating $DMG"
rm -rf "$STAGE" "$DMG" "$DMG.sha256"
mkdir -p "$STAGE" dist
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -fs HFS+ \
  -format UDZO -imagekey zlib-level=9 -ov "$DMG" >/dev/null
rm -rf "$STAGE"

if [ "$IDENTITY" != "-" ]; then
  echo "▸ Signing the DMG"
  codesign --force --sign "$IDENTITY" --timestamp "$DMG"
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "▸ Notarizing (this can take a few minutes)…"
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
  else
    echo "ℹ︎ Signed but not notarized. Set NOTARY_PROFILE to notarize so Gatekeeper opens it without warnings."
  fi
else
  echo "ℹ︎ Ad-hoc signed: macOS will show an 'unidentified developer' warning on other Macs."
  echo "  Users can run:  xattr -dr com.apple.quarantine \"/Applications/$APP_NAME.app\""
fi

(cd dist && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "✅ Built $DMG ($(du -h "$DMG" | cut -f1))"
echo "   SHA-256: $(cut -d' ' -f1 "$DMG.sha256")"
echo "   Open it:  open $DMG"
