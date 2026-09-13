#!/bin/bash
# Store App Store Connect credentials for notarytool (one-time).
#
# Prefer an App Store Connect API key:
#   1. developer.apple.com → Users and Access → Integrations → App Store Connect API
#   2. Create a key with at least Developer role, download the .p8 once
#   3. Run this script with KEY_ID / ISSUER_ID / KEY_PATH set
#
# Or use Apple ID + app-specific password interactively:
#   ./scripts/setup-notary.sh apple-id
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-SoundPilot-Notary}"
TEAM_ID="${TEAM_ID:-5D2WHHVG3W}"
MODE="${1:-api-key}"

case "$MODE" in
    api-key)
        : "${KEY_ID:?Set KEY_ID to your App Store Connect API Key ID}"
        : "${ISSUER_ID:?Set ISSUER_ID to your Issuer ID (UUID)}"
        : "${KEY_PATH:?Set KEY_PATH to the path of AuthKey_XXXXXX.p8}"
        xcrun notarytool store-credentials "$PROFILE" \
            --key "$KEY_PATH" \
            --key-id "$KEY_ID" \
            --issuer "$ISSUER_ID" \
            --team-id "$TEAM_ID"
        ;;
    apple-id)
        echo "You will be prompted for Apple ID and an app-specific password"
        echo "(appleid.apple.com → Sign-In and Security → App-Specific Passwords)."
        xcrun notarytool store-credentials "$PROFILE" \
            --apple-id "${APPLE_ID:-}" \
            --team-id "$TEAM_ID"
        ;;
    *)
        echo "Usage: $0 [api-key|apple-id]" >&2
        exit 1
        ;;
esac

echo "Stored notary credentials as keychain profile: $PROFILE"
echo "Verify with: xcrun notarytool history --keychain-profile $PROFILE"
