#!/bin/bash
# Build a Developer ID signed, notarized, stapled SoundPilot DMG on this Mac.
#
# This is the local twin of .github/workflows/release.yml: same version scheme,
# same signing flags, same DMG layout, same file name. A DMG built here is
# interchangeable with one built by CI.
#
#   ./scripts/build-dmg.sh v1.2.3                 sign + notarize + staple → build/SoundPilot-v1.2.3.dmg
#   ./scripts/build-dmg.sh v1.2.3 --skip-notarize sign only (Gatekeeper will warn; for local testing)
#   ./scripts/build-dmg.sh v1.2.3 --appcast       also sign for Sparkle and rewrite appcast.xml
#   ./scripts/build-dmg.sh v1.2.3 --release       also create the GitHub Release and attach the DMG
#
# Versioning (identical to CI):
#   MARKETING_VERSION        = tag minus "v" and any "-suffix"     v1.2.3-beta.4 → 1.2.3
#   CURRENT_PROJECT_VERSION  = major*1000000 + minor*10000 + patch*100 + stage
#                              stage = pre-release counter, or 99 for a final
#                              v1.2.3-beta.4 → 1020304   v1.2.3 → 1020399
#   Sparkle compares CURRENT_PROJECT_VERSION, so a beta always sorts below its
#   own final and every release sorts above the previous one.
#
# Prerequisites:
#   - Xcode 26 or later
#   - A "Developer ID Application" certificate with its private key in Keychain
#   - Notarization credentials, once:   ./scripts/setup-notary.sh
#     (skip with --skip-notarize)
#   - brew install create-dmg           optional; falls back to hdiutil
#
# Environment overrides:
#   SIGN_IDENTITY    full identity string; default: first "Developer ID Application" found
#   NOTARY_PROFILE   keychain profile from setup-notary.sh; default SoundPilot-Notary
#   TEAM_ID          default: read from ExportOptions.plist
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="SoundPilot"
SCHEME="SoundPilot"
REPO="iamnabink/soundpilot"

BUILD_DIR="$PROJECT_DIR/build"
DERIVED="$BUILD_DIR/DerivedData"
ARCHIVE="$BUILD_DIR/$APP_NAME.xcarchive"
NOTARY_PROFILE="${NOTARY_PROFILE:-SoundPilot-Notary}"

# ─── Arguments ──────────────────────────────────────────────────────────────
TAG=""
NOTARIZE=true
DO_APPCAST=false
DO_RELEASE=false
for arg in "$@"; do
    case "$arg" in
        --skip-notarize) NOTARIZE=false ;;
        --appcast)       DO_APPCAST=true ;;
        --release)       DO_RELEASE=true ;;
        -h|--help)       sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        v*)              TAG="$arg" ;;
        *)               echo "error: unknown argument '$arg' (run with --help)" >&2; exit 2 ;;
    esac
done
if [[ -z "$TAG" ]]; then
    echo "error: version tag required, e.g. ./scripts/build-dmg.sh v1.2.3" >&2
    exit 2
fi
if $DO_RELEASE && ! $NOTARIZE; then
    echo "error: --release needs a notarized build; drop --skip-notarize" >&2
    exit 2
fi

# ─── Version → build number (must match release.yml) ────────────────────────
MARKETING="${TAG#v}"; MARKETING="${MARKETING%%-*}"
SUFFIX="${TAG#*-}"
if [[ "$SUFFIX" == "$TAG" ]]; then
    STAGE=99; PRERELEASE=false
else
    STAGE="$(printf '%s' "$SUFFIX" | grep -oE '[0-9]+$' || echo 1)"
    (( STAGE > 98 )) && STAGE=98
    PRERELEASE=true
fi
IFS=. read -r MAJOR MINOR PATCH <<< "$MARKETING"
MAJOR="${MAJOR:-0}"; MINOR="${MINOR:-0}"; PATCH="${PATCH:-0}"
if ! [[ "$MAJOR$MINOR$PATCH" =~ ^[0-9]+$ ]]; then
    echo "error: '$TAG' is not vMAJOR.MINOR.PATCH[-suffix]" >&2
    exit 2
fi
BUILD_NUMBER=$(( MAJOR * 1000000 + MINOR * 10000 + PATCH * 100 + STAGE ))
DMG_PATH="$BUILD_DIR/$APP_NAME-$TAG.dmg"

# ─── Preflight ──────────────────────────────────────────────────────────────
step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

step "Preflight"
TEAM_ID="${TEAM_ID:-$(/usr/libexec/PlistBuddy -c 'Print :teamID' "$PROJECT_DIR/ExportOptions.plist" 2>/dev/null || true)}"
if [[ -z "${SIGN_IDENTITY:-}" ]]; then
    SIGN_IDENTITY="$(security find-identity -v -p codesigning | grep 'Developer ID Application' | head -1 | sed 's/.*"\(.*\)".*/\1/')"
fi
if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "error: no 'Developer ID Application' identity in Keychain." >&2
    echo "       Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application" >&2
    exit 1
fi
if $NOTARIZE && ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    echo "error: no notarization credentials stored as keychain profile '$NOTARY_PROFILE'." >&2
    echo "       Run ./scripts/setup-notary.sh once, or pass --skip-notarize for a local test build." >&2
    exit 1
fi
if $DO_RELEASE && ! command -v gh >/dev/null; then
    echo "error: --release needs the GitHub CLI (brew install gh)" >&2
    exit 1
fi
echo "Version    $MARKETING (build $BUILD_NUMBER, prerelease=$PRERELEASE)"
echo "Identity   $SIGN_IDENTITY"
echo "Team       ${TEAM_ID:-<none>}"
echo "Notarize   $NOTARIZE"
echo "Output     $DMG_PATH"

# ─── Archive ────────────────────────────────────────────────────────────────
step "Cleaning build directory"
rm -rf "$ARCHIVE" "$DMG_PATH" "$BUILD_DIR/dmg-stage" "$BUILD_DIR/$APP_NAME-notarize.zip"
mkdir -p "$BUILD_DIR"

step "Archiving Release with Developer ID"
# Manual signing with an explicit identity, exactly as CI does. The archived
# app is the shippable artifact: Developer ID, hardened runtime, timestamped.
xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$ARCHIVE" \
    -derivedDataPath "$DERIVED" \
    -skipMacroValidation \
    -skipPackagePluginValidation \
    MARKETING_VERSION="$MARKETING" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    OTHER_CODE_SIGN_FLAGS=--timestamp \
    archive \
    | tee "$BUILD_DIR/archive.log" | grep -E "error:|warning: .*sign|\*\* ARCHIVE" || true
grep -q "\*\* ARCHIVE SUCCEEDED \*\*" "$BUILD_DIR/archive.log" || { echo "error: archive failed, see $BUILD_DIR/archive.log" >&2; exit 1; }

APP="$ARCHIVE/Products/Applications/$APP_NAME.app"
test -d "$APP" || { echo "error: $APP not found in archive" >&2; exit 1; }

step "Re-signing Sparkle's nested helpers"
# Xcode re-signs Sparkle.framework's outer shell but leaves the XPC services
# and updater helpers inside it with the ad-hoc signature they shipped with
# from SPM. Notarization rejects ad-hoc nested executables, so sign them with
# the Developer ID inside-out, then the framework, then the app on top.
SPARKLE_B="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
for nested in \
    "$SPARKLE_B/XPCServices/Downloader.xpc" \
    "$SPARKLE_B/XPCServices/Installer.xpc" \
    "$SPARKLE_B/Autoupdate" \
    "$SPARKLE_B/Updater.app"
do
    [[ -e "$nested" ]] || continue
    codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp \
        --preserve-metadata=entitlements "$nested"
done
codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework"
codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp \
    --entitlements "$PROJECT_DIR/SoundPilot/SoundPilot.entitlements" "$APP"

step "Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP"
# Every nested executable must now carry the Developer ID, or notarization fails.
ADHOC="$(find "$APP/Contents/Frameworks" \( -name '*.xpc' -o -name '*.app' -o -name Autoupdate \) -not -path '*/Current/*' \
    -exec sh -c 'codesign -dvv "$1" 2>&1 | grep -q "Signature=adhoc" && echo "$1"' _ {} \;)"
if [[ -n "$ADHOC" ]]; then
    echo "error: still ad-hoc signed (notarization would reject):" >&2
    echo "$ADHOC" >&2
    exit 1
fi
codesign -d --entitlements - "$APP" 2>/dev/null | grep -E "audio-input|bluetooth|network" || true
ACTUAL_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ACTUAL_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist")"
[[ "$ACTUAL_VERSION" == "$MARKETING" && "$ACTUAL_BUILD" == "$BUILD_NUMBER" ]] \
    || { echo "error: bundle reports $ACTUAL_VERSION ($ACTUAL_BUILD), expected $MARKETING ($BUILD_NUMBER)" >&2; exit 1; }

# ─── Notarize app ───────────────────────────────────────────────────────────
if $NOTARIZE; then
    step "Notarizing app"
    ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
    ditto -c -k --keepParent "$APP" "$ZIP"          # notarytool takes an archive, not a .app
    xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    xcrun stapler validate "$APP"
fi

# ─── DMG ────────────────────────────────────────────────────────────────────
step "Creating DMG"
STAGE_DIR="$BUILD_DIR/dmg-stage"
mkdir -p "$STAGE_DIR"
cp -R "$APP" "$STAGE_DIR/"
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 --window-size 600 400 --icon-size 100 \
        --icon "$APP_NAME.app" 175 120 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 425 120 \
        "$DMG_PATH" "$STAGE_DIR/"
else
    echo "create-dmg not installed; using hdiutil (plain layout). brew install create-dmg for the styled window."
    ln -s /Applications "$STAGE_DIR/Applications"
    hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_PATH"
fi
test -f "$DMG_PATH" || { echo "error: DMG was not created" >&2; exit 1; }

step "Signing DMG"
codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"

if $NOTARIZE; then
    step "Notarizing DMG"
    # Notarized separately from the app inside it, so the download itself passes Gatekeeper.
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
    spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH" || true
fi

# ─── Optional: Sparkle appcast ──────────────────────────────────────────────
if $DO_APPCAST; then
    step "Signing for Sparkle and updating appcast.xml"
    DOWNLOAD_URL_PREFIX="https://github.com/$REPO/releases/download/$TAG/" \
    SPARKLE_DERIVED_DATA="$DERIVED" \
        "$SCRIPT_DIR/sparkle-tools.sh" release "$DMG_PATH"
fi

# ─── Optional: GitHub Release ───────────────────────────────────────────────
if $DO_RELEASE; then
    step "Publishing GitHub Release $TAG"
    FLAGS=()
    $PRERELEASE && FLAGS+=(--prerelease)
    if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
        echo "Release $TAG exists; attaching DMG."
    else
        gh release create "$TAG" --repo "$REPO" --title "$APP_NAME $TAG" --generate-notes "${FLAGS[@]}"
    fi
    gh release upload "$TAG" "$DMG_PATH" --repo "$REPO" --clobber
    echo "https://github.com/$REPO/releases/tag/$TAG"
fi

# ─── Summary ────────────────────────────────────────────────────────────────
step "Done"
echo "App   $APP"
echo "DMG   $DMG_PATH  ($(du -h "$DMG_PATH" | cut -f1))"
if ! $NOTARIZE; then
    echo
    echo "NOT notarized: Gatekeeper will warn on first launch. Rerun without --skip-notarize to ship."
fi
if ! $DO_APPCAST; then
    echo
    echo "Next: ./scripts/build-dmg.sh $TAG --appcast   (Sparkle-sign + rewrite appcast.xml)"
fi
