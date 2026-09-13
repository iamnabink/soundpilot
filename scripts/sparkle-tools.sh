#!/bin/bash
# Sparkle helpers for SoundPilot.
#
# Commands:
#   ./scripts/sparkle-tools.sh public-key                   # print the public key (matches SUPublicEDKey)
#   ./scripts/sparkle-tools.sh export-key [path]            # back up the private key (keep offline!)
#   ./scripts/sparkle-tools.sh import-key <path>            # restore it on another Mac
#   ./scripts/sparkle-tools.sh release SoundPilot-vX.Y.Z.dmg
#
# `release` signs the DMG with the EdDSA key in Keychain and rewrites
# appcast.xml in the project root with an entry pointing at that version's
# GitHub Release asset. Sparkle reads the appcast from the raw main-branch URL
# in SoundPilot/Info.plist (SUFeedURL), so the last step is always:
#
#   git add appcast.xml && git commit -m "chore(release): appcast for vX.Y.Z" && git push
#
# The DMG must already be attached to the GitHub Release for that tag, byte
# for byte identical to the file signed here. build-dmg.sh --appcast --release
# does both in the right order.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

find_sparkle_bin() {
    local candidate
    # build-dmg.sh builds into build/DerivedData and passes it here; a plain
    # Xcode build lands in ~/Library/Developer/Xcode/DerivedData instead.
    for candidate in \
        "${SPARKLE_DERIVED_DATA:-$PROJECT_DIR/build/DerivedData}"/SourcePackages/artifacts/sparkle/Sparkle/bin \
        "$HOME/Library/Developer/Xcode/DerivedData"/SoundPilot-*/SourcePackages/artifacts/sparkle/Sparkle/bin
    do
        if [[ -x "${candidate}/generate_keys" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    echo "error: Sparkle tools not found. Build the project once in Xcode so SPM resolves Sparkle." >&2
    exit 1
}

SPARKLE_BIN="$(find_sparkle_bin)"
CMD="${1:-}"

case "$CMD" in
    public-key)
        "$SPARKLE_BIN/generate_keys" -p
        ;;
    export-key)
        OUT="${2:-$PROJECT_DIR/sparkle-private-key.pem}"
        "$SPARKLE_BIN/generate_keys" -x "$OUT"
        echo "Wrote private key to $OUT — store offline and do not commit."
        ;;
    import-key)
        : "${2:?Usage: $0 import-key <private-key-file>}"
        "$SPARKLE_BIN/generate_keys" -f "$2"
        ;;
    release)
        ARCHIVE="${2:?Usage: $0 release <SoundPilot-vX.Y.Z.dmg>}"
        # Sparkle downloads from the exact URL in the appcast, so the prefix must
        # be the release's own asset path. "latest" is a GitHub redirect page and
        # does not serve files.
        if [[ -z "${DOWNLOAD_URL_PREFIX:-}" ]]; then
            TAG="$(basename "$ARCHIVE" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+[^/]*' | sed 's/\.dmg$//;s/\.zip$//' || true)"
            if [[ -z "$TAG" ]]; then
                echo "error: cannot infer the version from '$(basename "$ARCHIVE")'; set DOWNLOAD_URL_PREFIX" >&2
                exit 1
            fi
            DOWNLOAD_URL_PREFIX="https://github.com/iamnabink/soundpilot/releases/download/$TAG/"
        fi
        RELEASE_DIR="$PROJECT_DIR/build/sparkle-release"
        mkdir -p "$RELEASE_DIR"
        cp "$ARCHIVE" "$RELEASE_DIR/"
        # Seed with the committed appcast so earlier versions stay in the feed.
        [[ -f "$PROJECT_DIR/appcast.xml" ]] && cp "$PROJECT_DIR/appcast.xml" "$RELEASE_DIR/appcast.xml"
        # generate_appcast signs items with the Keychain EdDSA key and writes appcast.xml
        "$SPARKLE_BIN/generate_appcast" \
            --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
            --link "https://github.com/iamnabink/soundpilot/releases" \
            "$RELEASE_DIR"
        if [[ -f "$RELEASE_DIR/appcast.xml" ]]; then
            cp "$RELEASE_DIR/appcast.xml" "$PROJECT_DIR/appcast.xml"
            echo "Updated $PROJECT_DIR/appcast.xml"
            echo "Next: make sure $(basename "$ARCHIVE") is attached to the GitHub Release, then commit and push appcast.xml."
        else
            echo "error: generate_appcast did not produce appcast.xml" >&2
            exit 1
        fi
        ;;
    *)
        cat >&2 <<'EOF'
Usage:
  sparkle-tools.sh public-key
  sparkle-tools.sh export-key [path]
  sparkle-tools.sh import-key <path>
  sparkle-tools.sh release SoundPilot-vX.Y.Z.dmg
EOF
        exit 1
        ;;
esac
