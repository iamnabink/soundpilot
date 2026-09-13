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

## Build a notarized DMG locally

```bash
./scripts/build-dmg.sh v1.2.3
```

The script is the local twin of the CI workflow: same version scheme, same signing flags, same DMG layout, same file name. It archives with Developer ID, re-signs Sparkle's nested helpers, notarizes and staples the app, builds the DMG, then signs, notarizes and staples that too. Output lands at `build/SoundPilot-v1.2.3.dmg`.

| Flag | Effect |
| --- | --- |
| `--skip-notarize` | Sign only. Gatekeeper warns on launch; for local testing |
| `--appcast` | Also sign the DMG for Sparkle and rewrite `appcast.xml` |
| `--release` | Also create the GitHub Release and attach the DMG |

Notarization needs the keychain profile from `./scripts/setup-notary.sh` once per Mac.

### Why Sparkle's helpers are re-signed

Xcode re-signs the outer shell of `Sparkle.framework` but leaves the XPC services and updater helpers inside it with the ad-hoc signature they ship with from Swift Package Manager. Apple's notary service rejects ad-hoc signed nested executables, so both the script and the CI workflow sign them inside-out with the Developer ID before notarizing, and fail early if any remain ad-hoc.

## Ship an update by hand

```bash
./scripts/build-dmg.sh v1.2.3 --appcast --release
git add appcast.xml && git commit -m "chore(release): appcast for v1.2.3" && git push
```

That builds, notarizes, creates the release as a draft, attaches the DMG, publishes it, and rewrites `appcast.xml` with a signed entry pointing at that asset. Pushing the appcast is what makes existing installs see the update.

### How the local script and CI stay out of each other's way

Publishing a release fires the Release workflow. If it rebuilt every time, a locally built DMG would be overwritten by CI's bytes, and an appcast signature computed over the local file would stop matching. Two rules prevent that:

- The local script attaches the DMG **before** publishing (draft, upload, then publish), so the asset is already there when the workflow wakes up.
- The workflow's first job checks for an attached DMG and stands down if one exists, logging a notice. Only a manual **Run workflow** overrides this, and it warns when it is about to replace an existing asset.

So either path is safe on its own. Pick one per release and do not mix them for the same tag.

## Automated releases (GitHub Actions)

[`.github/workflows/release.yml`](../.github/workflows/release.yml) does everything in this guide on a `macos-26` runner: archive with Developer ID, notarize, staple, build the DMG, notarize the DMG, publish a GitHub Release, and regenerate the Sparkle appcast.

### Trigger

The workflow is **release-driven**, not commit-driven. Publishing a GitHub Release starts it:

```bash
gh release create v1.2.3 --generate-notes
```

That creates the tag, the release and the run in one step, and the DMG attaches itself to that release when the build finishes. Publishing a draft from the web UI works the same way. A pushed tag on its own does nothing until a release exists for it.

The tag is the version. `v1.2.3` sets `MARKETING_VERSION` to `1.2.3`, and `CURRENT_PROJECT_VERSION` is derived from that version rather than from commit history:

```
major*1000000 + minor*10000 + patch*100 + stage
```

`stage` is the pre-release counter, or 99 for a final release. So `v1.2.3-beta.4` becomes 1020304 and `v1.2.3` becomes 1020399. A beta always sorts below its own final, and each release sorts above the previous one, which is what Sparkle compares. Keep minor and patch under 100.

**Actions → Release → Run workflow** builds on demand. Leave `publish` off to attach the DMG to the workflow run without touching any release.

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

These are the same six secret names the author's other macOS project uses, so the values can be pasted straight across between repositories. GitHub never reveals a stored secret, so they have to be re-entered per repository rather than copied by tooling.

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
