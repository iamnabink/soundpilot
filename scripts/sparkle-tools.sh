#!/bin/bash
# Sparkle helpers for SoundPilot outside distribution.
#
# Commands:
#   ./scripts/sparkle-tools.sh public-key
#   ./scripts/sparkle-tools.sh export-key [path]     # backup private key (keep offline!)
#   ./scripts/sparkle-tools.sh import-key <path>
#   ./scripts/sparkle-tools.sh release <SoundPilot.dmg|zip|app>
#
# `release` signs the archive with your EdDSA key and (re)writes appcast.xml
# in the project root. Host that file + the archive at a public HTTPS URL
# matching SUFeedURL in SoundPilot/Info.plist.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

find_sparkle_bin() {
    local candidate
    for candidate in \
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
        ARCHIVE="${2:?Usage: $0 release <SoundPilot.dmg|zip|app>}"
        RELEASE_DIR="$PROJECT_DIR/build/sparkle-release"
        mkdir -p "$RELEASE_DIR"
        cp "$ARCHIVE" "$RELEASE_DIR/"
        # generate_appcast signs items with the Keychain EdDSA key and writes appcast.xml
        "$SPARKLE_BIN/generate_appcast" \
            --download-url-prefix "${DOWNLOAD_URL_PREFIX:-https://github.com/iamnabink/soundpilot/releases/download/latest/}" \
            "$RELEASE_DIR"
        if [[ -f "$RELEASE_DIR/appcast.xml" ]]; then
            cp "$RELEASE_DIR/appcast.xml" "$PROJECT_DIR/appcast.xml"
            echo "Updated $PROJECT_DIR/appcast.xml"
            echo "Upload the archive + appcast to a public HTTPS host matching SUFeedURL."
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
  sparkle-tools.sh release <SoundPilot.dmg|zip|app>
EOF
        exit 1
        ;;
esac
