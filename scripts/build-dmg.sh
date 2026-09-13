#!/bin/bash
# SoundPilot outside-distribution build
# Developer ID sign → export → notarize → staple → DMG
#
# Prerequisites:
#   - Xcode with team 5D2WHHVG3W signed in
#   - A "Developer ID Application" certificate (with private key) in Keychain
#   - Notary credentials once:  ./scripts/setup-notary.sh
#   - Optional DMG polish:      brew install create-dmg
#                              (falls back to hdiutil if missing)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/SoundPilot.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH=""
NOTARY_PROFILE="${NOTARY_PROFILE:-SoundPilot-Notary}"
# codesign/xcodebuild match the identity by prefix; override SIGN_IDENTITY if you have several.
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application}"

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$EXPORT_PATH"

echo "==> Archiving Release (Developer ID)..."
xcodebuild -project "$PROJECT_DIR/SoundPilot.xcodeproj" \
    -scheme SoundPilot \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
    DEVELOPMENT_TEAM=5D2WHHVG3W \
    archive

echo "==> Exporting Developer ID app..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"

APP_PATH="$EXPORT_PATH/SoundPilot.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "error: exported app not found at $APP_PATH" >&2
    exit 1
fi

echo "==> Verifying Developer ID signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH" 2>&1 || true

echo "==> Notarizing app (zip for notarytool)..."
APP_ZIP="$BUILD_DIR/SoundPilot-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$APP_ZIP"
xcrun notarytool submit "$APP_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "==> Stapling notarization ticket to app..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "==> Creating DMG..."
DMG_PATH="$BUILD_DIR/SoundPilot.dmg"
rm -f "$DMG_PATH"
if command -v create-dmg >/dev/null 2>&1 || command -v npx >/dev/null 2>&1; then
    if command -v create-dmg >/dev/null 2>&1; then
        create-dmg --overwrite "$APP_PATH" "$BUILD_DIR"
    else
        npx --yes create-dmg "$APP_PATH" "$BUILD_DIR" --overwrite
    fi
    # create-dmg names the file from the app version; normalize to SoundPilot.dmg
    GENERATED="$(find "$BUILD_DIR" -maxdepth 1 -name '*.dmg' ! -name 'SoundPilot.dmg' | head -1 || true)"
    if [[ -n "${GENERATED:-}" ]]; then
        mv "$GENERATED" "$DMG_PATH"
    fi
else
    STAGE="$BUILD_DIR/dmg-stage"
    rm -rf "$STAGE"
    mkdir -p "$STAGE"
    cp -R "$APP_PATH" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"
    hdiutil create -volname "SoundPilot" -srcfolder "$STAGE" -ov -format UDZO "$DMG_PATH"
fi

if [[ ! -f "$DMG_PATH" ]]; then
    echo "error: DMG was not created" >&2
    exit 1
fi

echo "==> Signing DMG..."
codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH"

echo "==> Notarizing DMG..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
xcrun stapler staple "$DMG_PATH"

echo "==> Done"
echo "   App: $APP_PATH"
echo "   DMG: $DMG_PATH"
ls -lh "$DMG_PATH"
echo
echo "Next: ship updates with ./scripts/sparkle-tools.sh release $DMG_PATH"
