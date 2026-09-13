<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="SoundPilot app icon"/>
</p>

<h1 align="center">SoundPilot</h1>

<p align="center">
  <strong>Per-app volume mixer for macOS.</strong><br/>
  Control the volume of every app independently, boost quiet ones up to 4x, route audio to different speakers, and shape your sound with EQ and headphone correction. Lives in your menu bar.
</p>

<p align="center">
  <a href="https://github.com/iamnabink/soundpilot-macos-volume-mixer/releases/latest"><img src="https://img.shields.io/badge/Download-.dmg-6c47ff?style=for-the-badge&logo=apple&logoColor=white" alt="Download DMG"/></a>
</p>

<p align="center">
  <a href="https://github.com/iamnabink/soundpilot-macos-volume-mixer/releases/latest"><img src="https://img.shields.io/github/v/release/iamnabink/soundpilot-macos-volume-mixer?label=latest" alt="Latest release"/></a>
  <a href="https://github.com/iamnabink/soundpilot-macos-volume-mixer/actions/workflows/build.yml"><img src="https://github.com/iamnabink/soundpilot-macos-volume-mixer/actions/workflows/build.yml/badge.svg" alt="Build status"/></a>
  <img src="https://img.shields.io/badge/macOS-15.4%2B-lightgrey?logo=apple" alt="macOS 15.4+"/>
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6"/>
  <img src="https://img.shields.io/badge/signed%20%26%20notarized-by%20Apple-success" alt="Signed and notarized"/>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-PolyForm%20Noncommercial-blue" alt="License"/></a>
</p>

<p align="center">
  <img src="assets/screenshot-main.png" alt="SoundPilot popup showing per-app volume control, multi-device output routing with picker popover, AutoEQ headphone correction, and device-level volume sliders" width="48%"/>
  &nbsp;
  <img src="assets/screenshot-eq.png" alt="SoundPilot showing the Brave Browser app row expanded with the EQ panel open and a Vocal Clarity preset selected" width="48%"/>
</p>

---

## Install

SoundPilot ships as a **DMG only**. It is not on the Mac App Store, because per-app audio taps and monitor DDC control require App Sandbox to be off.

1. Download the latest `SoundPilot-vX.Y.Z.dmg` from the [Releases page](https://github.com/iamnabink/soundpilot-macos-volume-mixer/releases/latest)
2. Open it and drag **SoundPilot** into **Applications**
3. Launch it and grant **Screen & System Audio Recording** permission when prompted

Releases are signed with a Developer ID certificate and notarized by Apple, so Gatekeeper opens them without warnings. Once installed, SoundPilot updates itself through Sparkle. Check for updates from **Settings → Updates**.

## Quick Start

1. Click the SoundPilot icon in your menu bar. Apps playing audio appear automatically.
2. Drag a slider to change that app's volume. Click the chevrons to boost it above 100%.
3. Expand a row to open its EQ, pick an output device, or apply headphone correction.

> **Tip:** Want SoundPilot to auto-switch to a specific device when you connect it? Open edit mode (pencil icon) and drag it above the built-in speakers. This is a one-time setup. Your preferred order is saved permanently.

## Features

### 🎚 Volume Control
- **Per-app volume** — Individual sliders and mute for each application
- **Per-app volume boost** — 2x / 3x / 4x gain presets
- **Pinned apps** — Keep apps visible in the menu bar even when they're not playing, so you can configure volume, EQ, and routing in advance
- **Ignore apps** — Completely disengage SoundPilot from specific apps. Tears down the audio tap so the app returns to normal macOS audio
- **Scroll-wheel volume** — Hover any slider in the popup, the HUD, or the EQ panel and scroll to adjust.

### ⌨️ Keyboard
- **Global volume hotkeys** — Bind your own keys to **App Volume Up**, **App Volume Down**, and **App Mute** from Settings → Shortcuts. The "app" is whichever is currently making sound, so volume-down while a YouTube tab plays behind a foreground Terminal turns down YouTube, not the terminal. If nothing is audible, the hotkey falls through to the frontmost app.
- **Toggle the popup from anywhere** — Bind a hotkey to **Toggle SoundPilot Popup** and the menu bar opens or closes on demand, including from full-screen apps.
- **Configurable step size** — Pick **Coarse / Normal / Fine / Extra-Fine** under Settings → Shortcuts → Volume Step. The same setting governs the F10–F12 media keys, the global hotkeys, and the popup's arrow-key navigation.
- **Hold to ramp, auto-unmute on volume-up** — Holding App Volume Up or Down emits repeats the way macOS does for arrow keys. Volume-up while muted unmutes and sets the new level in one keystroke.
- **Drive the popup with the keyboard** — Once the popup is open, **↑ / ↓** move between rows, **← / →** adjusts the focused row's volume (Shift = 2× step), **M** toggles mute, **Return / Space** activates, **Tab** switches between Output and Input device tabs, **Esc** closes. The focused row autoscrolls to center as you arrow through.

### 🔀 Audio Routing
- **Multi-device output** — Route audio to multiple devices simultaneously
- **Audio routing** — Send apps to different outputs or follow system default
- **Device priority** — Choose which device SoundPilot switches to when a new device connects; auto-fallback on disconnect
- **Auto-restore** — When a device reconnects, apps automatically return to it with their volume, routing, and EQ intact

### 🎛 EQ & Correction
- **10-band EQ** — 20 presets across 5 categories
- **User EQ presets** — Save, rename, and manage custom EQ configurations per app
- **AutoEQ headphone correction** — Search thousands of headphone profiles or import your own ParametricEQ.txt files for per-device frequency response correction
- **Loudness compensation** — Automatic bass and treble correction at low volumes using ISO 226:2023 equal-loudness contours, with real-time level management to keep perceived loudness consistent

### 🖥 Devices & System
- **Input device control** — Monitor and adjust microphone levels
- **Alert volume** — Control macOS notification and alert volume from settings
- **Smart volume backend** — SoundPilot auto-picks hardware, DDC, or software volume per device. If the hardware slider on a USB DAC or HDMI output doesn't actually control level, force software volume from the device inspector and SoundPilot remembers the choice for that device
- **Device inspector** — Tap the info button on any device row for sample rate (with picker), transport, UID copy, hog-mode banner, and the software-volume override
- **Hide devices** — Eye toggle in edit mode hides output and input devices you don't want in the list, mirroring the app-hide flow
- **Bluetooth device management** — Connect paired devices directly from the menu bar
- **Monitor speaker control** — Adjust volume on external displays via DDC
- **Media keys & Volume HUD** — Opt-in F10–F12 control for the default output device, with a Tahoe-style or Classic-style on-screen HUD. The write goes through SoundPilot's volume pipeline, so keys keep working on USB interfaces and HDMI outputs where macOS's own keys are greyed out because the hardware slider is broken.
- **Dynamic menu bar icon** — Pick from four styles in Settings (Default, Speaker, Waveform, Equalizer). The **Speaker** style tracks volume live (zero / low / mid / high glyphs) and switches to a slashed speaker when muted. All styles briefly flash the new output's SF Symbol on device switch. Changing style applies instantly, no relaunch required.
- **Menu bar app** — Lightweight, always accessible
- **URL schemes** — Automate volume, mute, device routing, and more from scripts

### 🎨 Appearance
- **Light or Dark theme** — Settings → General → Theme matches macOS or locks SoundPilot to Light or Dark. The menu bar popup, every popover, and the volume HUD switch immediately.
- **Popup density** — Settings → General → Popup Size picks **Compact / Comfortable / Spacious** with a live tile preview. Compact fits more apps on small screens; Spacious gives bigger hit areas for trackpads.

## How SoundPilot Works

macOS has no built-in per-app volume. SoundPilot builds one on top of the public Core Audio **process tap** API that Apple added in macOS 14.2, without kernel extensions, virtual audio drivers, or hacks that survive a reboot.

### 1. Every app gets its own tap

When an app starts playing audio, SoundPilot creates a `CATapDescription` for that app's process and asks Core Audio for a **process tap**. The tap is created with `muteBehavior = .mutedWhenTapped`, which silences the app's original output. From that moment the only copy of the app's audio that reaches your speakers is the one SoundPilot has processed. Taps are private, so they never show up in other apps' device lists.

### 2. A private aggregate device carries it to the output

For each tapped app SoundPilot builds a **private aggregate device** whose sub-devices are the output(s) you chose and whose tap list is that app's tap. An I/O proc on the aggregate device pulls audio out of the tap and writes it to the output in the same real-time callback. Routing an app to a different device means building a new aggregate for it; **multi-device output** is an aggregate with several stacked sub-devices, clocked from the first one.

### 3. A real-time DSP chain runs inside the callback

Everything happens on Core Audio's HAL I/O thread, in this order:

| Stage | What it does |
| --- | --- |
| Per-app gain | Linear PCM gain with a perceptual x² slider curve. Boost presets go up to 4×. |
| 10-band EQ | Cascaded biquads via `vDSP_biquad`. Presets and per-app user presets. |
| AutoEQ correction | Parametric biquads plus a preamp stage, loaded from AutoEQ or an imported ParametricEQ.txt, keyed by output device. |
| Loudness equalizer | K-weighted loudness measurement with asymmetric attack/release smoothing to hold perceived level near a target. |
| Loudness compensation | ISO 226:2023 equal-loudness contours fitted with a four-section shelf/bell cascade, so bass and treble come back at low volume. |
| Soft limiter | Soft-knee asymptotic limiter above 0.95 so boosted audio never hard-clips. |

The callback never allocates, locks, logs, or calls into Objective-C. Filter coefficients are swapped atomically and old setups are destroyed after a 500 ms grace period, longer than the largest audio buffer, so the audio thread never touches freed memory.

### 4. Device changes crossfade instead of clicking

Switching an app to another output creates the new aggregate first, then runs an **equal-power crossfade** between the old and new devices before tearing the old one down. When SoundPilot sets the system default device itself, an **echo tracker** ignores the resulting Core Audio notification so it doesn't re-route apps in response to its own change. Device priority and auto-restore rebuild an app's routing, volume, and EQ when a preferred device reappears.

### 5. Device volume uses the right backend per device

- **Hardware volume** goes through the HAL virtual main volume property, which the driver already tapers in dB.
- **External monitors** on Apple Silicon are driven over **DDC/CI**, using I2C through the `IOAVService` private interface, so HDMI and DisplayPort displays get a working slider.
- **Software volume** is the fallback for devices whose hardware slider doesn't actually change level, such as some USB DACs, and can be forced per device from the inspector.

### 6. Media keys, HUD, and hotkeys

With permission, a `CGEventTap` intercepts F10–F12, swallows them so the native HUD doesn't double-fire, and pushes the change through SoundPilot's own volume pipeline. That is why the keys keep working on outputs where macOS greys them out. Global hotkeys use Carbon-backed shortcuts and target whichever app is currently audible.

### 7. Crash safety

A tap with `mutedWhenTapped` that outlives its owner would leave the app silently muted. Two guards prevent that:

- **Orphan cleanup** scans Core Audio on launch and destroys any leftover SoundPilot aggregate devices from a previous crash or `kill -9`.
- **Crash guard** installs an async-signal-safe handler that destroys every tracked aggregate device over Mach IPC before re-raising the signal.

### Permissions

| Permission | Why |
| --- | --- |
| Screen & System Audio Recording | Required by Core Audio to create process taps. Nothing is recorded or stored. |
| Accessibility | Optional. Only needed for the F10–F12 media-key override. |
| Bluetooth | Optional. Lets you connect paired devices from the menu bar. |

## Architecture

```
SoundPilot/
├── Audio/
│   ├── Engine/        AudioEngine, ProcessTapController, TapResources, crossfades, limiter, crash guards
│   ├── EQ/            RT-safe biquad base class and the 10-band graphic EQ
│   ├── AutoEQ/        Profile fetcher, parser, and parametric correction processor
│   ├── Loudness/      ISO 226 compensation, K-weighted loudness equalizer
│   ├── DDC/           DDC/CI monitor volume over IOAVService
│   ├── Monitors/      Device, process, Bluetooth, and volume observers
│   ├── Keys/          Media-key event tap
│   └── Extensions/    Typed Core Audio property helpers
├── Coordination/      Permission and popup-visibility services
├── Models/            Apps, devices, EQ presets, volume mapping
├── Settings/          Persisted settings with versioned migrations
├── Shortcuts/         Global hotkeys and target-app resolution
├── Utilities/         Sparkle update manager, URL scheme handler, icon caches
└── Views/             SwiftUI menu bar popup, HUD, settings, design system
```

Built with Swift 6 strict concurrency, SwiftUI, and AppKit. Dependencies: [Sparkle](https://github.com/sparkle-project/Sparkle) (updates), [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (global hotkeys), [FluidMenuBarExtra](https://github.com/wadetregaskis/FluidMenuBarExtra) (menu bar window).

## Build from Source

Requirements: macOS 15.4 or later, Xcode 26 or later (the code uses Swift 6.2 features).

```bash
git clone https://github.com/iamnabink/soundpilot-macos-volume-mixer.git
cd soundpilot-macos-volume-mixer
open SoundPilot.xcodeproj
```

Select the **SoundPilot** scheme and run. Xcode resolves the Swift packages on first build. To build from the command line without signing:

```bash
xcodebuild -project SoundPilot.xcodeproj -scheme SoundPilot -configuration Debug \
  -destination 'platform=macOS' -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO build
```

Run the unit tests with `xcodebuild test -scheme SoundPilot -only-testing:SoundPilotTests`.

## Releasing

Releases are automated with GitHub Actions. Pushing a version tag builds a Developer ID signed and notarized DMG, publishes a GitHub Release, and regenerates the Sparkle appcast:

```bash
git tag v1.2.3 && git push origin v1.2.3
```

See [guide/distribution.md](guide/distribution.md) for the required secrets and the manual build path.

## Documentation

- **[Outside distribution](guide/distribution.md)** — Developer ID signing, notarization, DMG builds, Sparkle updates, and the CI release pipeline
- **[AutoEQ & Headphone Correction](guide/autoeq.md)** — Apply frequency correction from the [AutoEQ](https://github.com/jaakkopasanen/AutoEq) project, import [EqualizerAPO](https://sourceforge.net/projects/equalizerapo/) profiles, or browse [autoeq.app](https://www.autoeq.app/)
- **[URL Schemes](guide/url-schemes.md)** — Automate SoundPilot from Terminal, [Shortcuts](https://support.apple.com/guide/shortcuts-mac), [Raycast](https://raycast.com), or scripts
- **[Troubleshooting](guide/troubleshooting.md)** — Permission issues, missing apps, audio problems

## Requirements

- macOS 15.4 (Sequoia) or later
- Apple Silicon or Intel Mac
- Screen & System Audio Recording permission (prompted on first launch)

## Contributing

Issues and pull requests are welcome. Every PR is compiled by the [Build workflow](.github/workflows/build.yml). Keep real-time audio code allocation-free and lock-free; see the comments at the top of `ProcessTapController.swift` for the threading model.

## Author

Made by **[iamnabink](https://github.com/iamnabink)**.

- GitHub: [github.com/iamnabink](https://github.com/iamnabink)
- Project: [github.com/iamnabink/soundpilot-macos-volume-mixer](https://github.com/iamnabink/soundpilot-macos-volume-mixer)

## License

SoundPilot is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE).

- ✅ Free for **personal, educational, research, and other noncommercial** use
- ❌ **Commercial use requires written permission.** Open an issue or contact [iamnabink](https://github.com/iamnabink) before using SoundPilot, or code derived from it, in a product, service, or business.

## Acknowledgements

- [AutoEQ](https://github.com/jaakkopasanen/AutoEq) for the headphone measurement database
- [Sparkle](https://sparkle-project.org) for software updates
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) and [FluidMenuBarExtra](https://github.com/wadetregaskis/FluidMenuBarExtra)
