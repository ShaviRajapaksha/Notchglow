# Building NotchGlow

Everything you need to build, package, sign and release NotchGlow from source. End-user documentation lives in [README.md](README.md).

## Requirements

- macOS 13 Ventura or later
- Xcode command line tools (Swift 5.9 or later): `xcode-select --install`
- For universal builds (`--universal`): the full Xcode toolchain
- For the icon generator: Python 3 and `pip install pillow`

## Build and run

```bash
./build_app.sh                  # creates build/NotchGlow.app
open build/NotchGlow.app
```

| Command | Result |
|---|---|
| `./build_app.sh` | Release build of `build/NotchGlow.app` for this Mac's architecture |
| `./build_app.sh debug` | Debug build |
| `./build_app.sh --universal` | Apple Silicon **and** Intel |
| `./install.sh` | Builds, then installs into `/Applications` (quits a running copy, replaces the old one, launches the new one) |
| `./install.sh --dmg` | …and also builds the DMG |
| `./install.sh --no-open` | …without launching the app afterwards |
| `./build_dmg.sh` | Builds `dist/NotchGlow-<version>.dmg` and a `.sha256` checksum |
| `./build_dmg.sh --universal` | Universal DMG |

The DMG contains `NotchGlow.app` and an **Applications** shortcut, so installing is a drag-and-drop.

## Signing and notarization

By default the app is **ad-hoc signed**. That works locally, but:

- macOS treats every ad-hoc rebuild as a new app and may reset its privacy permissions (reset manually with `tccutil reset ListenEvent com.notchglow.app`), and
- other Macs show Gatekeeper's "unidentified developer" warning.

To avoid both, sign with a certificate:

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"    # or "Apple Development: Your Name" for local builds
./build_app.sh
```

With a real identity the build automatically enables the **hardened runtime** and applies `Resources/NotchGlow.entitlements`. The entitlement `com.apple.security.device.audio-input` is required for microphone access under the hardened runtime.

To notarize (needs a paid Apple Developer account):

```bash
xcrun notarytool store-credentials "NotchGlow" --apple-id you@example.com --team-id TEAMID   # once
export NOTARY_PROFILE="NotchGlow"
./build_dmg.sh --universal      # signs, notarizes and staples the DMG
```

## Releasing

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. Update [RELEASE_NOTES.md](RELEASE_NOTES.md).
3. `./build_dmg.sh --universal` (with `CODESIGN_IDENTITY` and `NOTARY_PROFILE` set for a public release).
4. Test the DMG on a clean Mac: first launch, onboarding, each permission, typing, music, microphone, two displays, a full-screen app.
5. Upload `dist/NotchGlow-<version>.dmg` and its `.sha256` to your release page.

The bundle identifier is `com.notchglow.app` (`Resources/Info.plist`). Change it before your first public release if you want one tied to your own domain.

## App icon

`Resources/AppIcon.icns` is committed and copied into the app bundle by `build_app.sh`. To regenerate it:

```bash
python3 scripts/make_icon.py
```

This rewrites `Resources/AppIcon.icns`, `Resources/AppIcon.iconset/` and `Resources/AppIcon-1024.png`. On a Mac you can also rebuild the `.icns` from the iconset with `iconutil -c icns Resources/AppIcon.iconset`. The menu bar icon is drawn in code (`MenuBar/StatusIcon.swift`).

## Project structure

```
Sources/NotchGlow
├─ App/         main.swift, AppDelegate (single-instance handling)
├─ Core/        AnimationConfiguration, AppSettings, ColorPalette, SettingsManager, AppEnvironment (wiring)
├─ Audio/       AudioAnalyzer (loudness + spectrum), CoreAudioTapMonitor, SystemAudioMonitor, MicrophoneMonitor
├─ Keyboard/    KeyboardActivityMonitor (events only), PermissionsManager
├─ MenuBar/     MenuBarManager (status item, popover, right-click menu), StatusIcon, MenuPopoverView
├─ Overlay/     VisualizerWindowController (non-activating click-through panel per display),
│               DisplayManager (display UUIDs, chooser), FullScreenDetector
├─ Animations/  VisualizerEngine (timer only while animating), VisualizerState, VisualizerRenderer,
│               StyleRenderer protocol + 10 style renderers, RenderContext, VisualizerView
├─ Settings/    SwiftUI settings window, panes, onboarding, live preview
└─ Utilities/   math helpers, CodableColor, LaunchAtLogin
Resources/      Info.plist, NotchGlow.entitlements, AppIcon.icns (+ iconset and 1024 px artwork)
scripts/        make_icon.py
build_app.sh · build_dmg.sh · install.sh
```

Keyboard and audio detection only feed the animation engine; renderers never see the keyboard or raw audio.

## Adding an animation style

1. Create a renderer that implements `StyleRenderer` (see `AudioWaveRenderer.swift` or `HelixWaveRenderer.swift`).
2. Add a case to `AnimationStyle` with its title, summary and SF Symbol, and return your renderer from `makeRenderer()`.

It then appears in the menu-bar popover and the Animation Styles pane automatically. Saved settings that reference a style that no longer exists fall back to Spike Wave.

## Performance notes

- The 60 FPS timer exists only while something is visible; once the animation has faded out it is stopped (0% CPU).
- "Idle animation" (off by default) runs at 30 FPS.
- The small preview in Settings renders in a low-power mode (30 FPS, single glow pass), and the settings panes use flat fills instead of blur materials, to keep the window responsive while the preview animates.
- Disabling the visualizer stops the timer, the keyboard monitor and the audio monitors, and hides the overlay windows.
- Full-screen watching is event-driven (Space and app changes), with a slow 2-second safety check that exists only while *Show over full-screen apps* is off.

## Known limitations

- Some full-screen Spaces or games with their own window layer may hide the overlay even when *Show over full-screen apps* is on.
- With an auto-hiding menu bar the animation uses a 24 pt fallback menu-bar height (adjust with **Vertical offset**).
- Blur uses a Core Image layer filter, which adds some GPU work when enabled.
- macOS offers no public way to read the status of the audio-only permission, so the Sound & Music pane shows guidance and a relaunch button instead of a status indicator.
