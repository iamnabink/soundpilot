# Outside distribution (Developer ID)

SoundPilot is distributed **outside the Mac App Store** with your Apple Developer ID. That keeps App Sandbox off (required for per-app audio taps and DDC), and lets Sparkle handle updates.

Team: `5D2WHHVG3W`  
Signing identity: `Developer ID Application` (matched by prefix; set `SIGN_IDENTITY` to pick a specific certificate)

## One-time setup

### 1. Notarization credentials

```bash
# Preferred: App Store Connect API key (.p8)
KEY_ID=XXXXXXXX \
ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
KEY_PATH=~/Downloads/AuthKey_XXXXXXXX.p8 \
./scripts/setup-notary.sh api-key

# Or: Apple ID + app-specific password (interactive)
./scripts/setup-notary.sh apple-id
```

This stores a keychain profile named `SoundPilot-Notary` used by `build-dmg.sh`.

### 2. Sparkle signing key

Already generated on this Mac and embedded in `SoundPilot/Info.plist` as `SUPublicEDKey`.

```bash
./scripts/sparkle-tools.sh public-key          # print public key
./scripts/sparkle-tools.sh export-key          # backup private key (keep offline, never commit)
```

Private key lives in Keychain as **Private key for signing Sparkle updates**. Losing it without a backup means you must rotate keys for existing installs.

### 3. Public update feed URL

Sparkle clients fetch `SUFeedURL` with **no authentication**. A private GitHub repo’s `raw.githubusercontent.com` URL will fail for users.

The repository is public, so `SUFeedURL` in `SoundPilot/Info.plist` points at the raw `appcast.xml` on the `main` branch and the DMGs live on GitHub Releases. The release workflow below rewrites and commits `appcast.xml` on every tagged release.

## Build a notarized DMG

```bash
./scripts/build-dmg.sh
```

Produces:

- `build/export/SoundPilot.app` — Developer ID signed + notarized + stapled
- `build/SoundPilot.dmg` — signed + notarized + stapled

Give users the DMG. Gatekeeper will accept it on first launch (right-click → Open still works if they haven’t launched a notarized app before, but stapled notarization usually skips that).

## Ship an update

1. Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in the Xcode target.
2. `./scripts/build-dmg.sh`
3. Sign + regenerate appcast:

```bash
DOWNLOAD_URL_PREFIX="https://your-public-host/soundpilot/" \
  ./scripts/sparkle-tools.sh release build/SoundPilot.dmg
```

4. Upload `build/SoundPilot.dmg` (or the copy under `build/sparkle-release/`) and `appcast.xml` to the public host matching `SUFeedURL`.

## Automated releases (GitHub Actions)

[`.github/workflows/release.yml`](../.github/workflows/release.yml) does everything in this guide on a `macos-26` runner: archive with Developer ID, notarize, staple, build the DMG, notarize the DMG, publish a GitHub Release, and regenerate the Sparkle appcast.

### Trigger

```bash
git tag v1.2.3 && git push origin v1.2.3
```

The tag is the version: `v1.2.3` sets `MARKETING_VERSION` to `1.2.3`, and the commit count becomes `CURRENT_PROJECT_VERSION` so Sparkle always sees a higher build number. A tag with a suffix (`v1.3.0-beta.1`) is published as a pre-release. **Actions → Release → Run workflow** builds on demand; leave `publish` off to only attach the DMG to the run.

### Secrets

Create a repository environment named `release` (Settings → Environments) and add:

| Secret | Value |
| --- | --- |
| `MACOS_CERTIFICATE` | base64 of the **Developer ID Application** `.p12`, exported from Keychain Access *with* its private key |
| `MACOS_CERTIFICATE_PWD` | password chosen when exporting the `.p12` |
| `APPLE_TEAM_ID` | `5D2WHHVG3W` |
| `ASC_KEY_P8` | base64 of `AuthKey_<KEY_ID>.p8` (App Store Connect API key, Developer role, used only for notarization) |
| `ASC_KEY_ID` | the key id |
| `ASC_ISSUER_ID` | the issuer id (UUID) |
| `SPARKLE_PRIVATE_KEY` | contents of the file from `./scripts/sparkle-tools.sh export-key` |
| `KEYCHAIN_PASSWORD` | optional, any string |

```bash
base64 -i DeveloperID.p12 | pbcopy        # MACOS_CERTIFICATE
base64 -i AuthKey_XXXXXXXX.p8 | pbcopy    # ASC_KEY_P8
./scripts/sparkle-tools.sh export-key /tmp/sparkle.key && pbcopy < /tmp/sparkle.key && rm /tmp/sparkle.key
```

Without `MACOS_CERTIFICATE` the workflow still runs, but produces an **unsigned** DMG and skips notarization and the appcast. Without `SPARKLE_PRIVATE_KEY` the release is published but existing installs are not told about it.

### What it commits

After a successful publish the workflow commits `appcast.xml` to `main` as `github-actions[bot]`. Pull before your next push.

## Verify locally

```bash
codesign --verify --deep --strict --verbose=2 build/export/SoundPilot.app
spctl --assess --type execute --verbose=4 build/export/SoundPilot.app
xcrun stapler validate build/SoundPilot.dmg
```

## Why not TestFlight / Mac App Store

TestFlight only accepts Mac App Store builds. Those require App Sandbox, ban Sparkle-style updaters, and reject private API use (SoundPilot’s DDC path). Per-app process taps also have no App Store entitlement. Outside distribution with Developer ID + notarization is the supported path for this app.
