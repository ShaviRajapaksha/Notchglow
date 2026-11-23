<h1 align="center">
  <br>
  <!-- Add your logo here, for example: -->
  <a href="https://github.com/<your-username>/NotchGlow"><img src="assets/notchglow.png" alt="NotchGlow macOS Notch and Menu Bar Visualizer Logo" width="150"></a>
  <br>
  NotchGlow
  <br>
</h1>

<p align="center">
  <strong>Native macOS menu bar &amp; MacBook notch visualizer that reacts to music, system audio, microphone, and typing.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-yellow?logo=apple&logoColor=white" alt="macOS 13 Ventura or later" />
  <img src="https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white" alt="Swift 5.9+" />
  <img src="https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-native-0A84FF" alt="Native SwiftUI and AppKit" />
  <img src="https://img.shields.io/badge/network-none-30D158" alt="Zero network connections" />
</p>

**NotchGlow** brings your Mac's menu bar and MacBook notch to life with a lightweight, customizable overlay visualizer that dances to your **music**, **system sound**, **microphone**, and **typing**. Choose from 10 real-time animation styles, fine-tune every dimension, color, and glow, and enjoy 0% idle CPU usage—rendering only while something is actively moving.

<p align="center">
  <img
    src="assets/notchglow.gif"
    alt="NotchGlow macOS menu bar and notch audio and typing visualizer in action"
    width="100%"
  />
</p>

---

## Features

- 🎧 **Music & System Audio Reactive** — Follows whatever your Mac plays (Apple Music, Spotify, YouTube, browser audio) or microphone input with real-time beat detection and a live 16-band frequency spectrum.
- ⌨️ **Typing Reactive** — Every keystroke sends a responsive ripple from the center; faster typing increases energy, and animations smoothly fade out when you stop.
- 🎨 **10 Built-In Animation Styles** — Spike Wave, Needle Spikes, Audio Wave, Equalizer, LED Meter, Heartbeat, Lightning, Particle Burst, Energy Pulse, and Minimal Glow.
- 🎚️ **Full Live Customization** — Tune width, height, left/right expansion, multi-color gradients, opacity, glow, blur, speed, intensity, and symmetry with an instant live preview.
- 🪟 **Flexible Menu Bar Layering** — Draw animations above the menu bar's blur or subtly beneath it.
- 🔗 **Notch-Aware Layout** — Run one continuous animation across the center, or leave a clean gap around the MacBook notch.
- 🖥️ **Multi-Display Support** — Display across all monitors, follow the display under your cursor, or target your primary screen.
- 🔒 **Private & Offline by Design** — Never logs keystrokes, never records or saves audio, and makes zero network connections.

---

## Installation

### System Requirements
- **macOS 13 Ventura** or later
- **Apple Silicon** or **Intel** Mac

> [!NOTE]
> Music and system-sound reactions use an audio-only permission on **macOS 14.4 or later**. On **macOS 13 – 14.3**, they use the *Screen & System Audio Recording* permission instead. Typing and microphone reactions work on all supported macOS versions.

### Option 1: Build from Source (3 Commands)

Requires Xcode Command Line Tools (`Swift 5.9+`).

```bash
xcode-select --install          # One-time setup if you don't have the Swift toolchain
cd NotchGlow
./build_app.sh                  # Compiles and packages build/NotchGlow.app
open build/NotchGlow.app
```

- **Debug build:** `./build_app.sh debug`
- **Quit:** Click the menu bar icon and quit from the popover (the app runs without a Dock icon).

<!--
### Option 2: Download Prebuilt DMG
Uncomment this section once you publish a GitHub Release.

<a href="https://github.com/<your-username>/NotchGlow/releases/latest/download/NotchGlow.dmg" target="_self"><img width="200" src="assets/download.png" alt="Download NotchGlow for macOS" /></a>

1. Open the downloaded `.dmg` file.
2. Drag **NotchGlow** into your `/Applications` folder.
-->

<!--
### Option 3: Install via Homebrew
Uncomment once you publish a Homebrew tap.

```bash
brew install --cask <your-username>/notchglow/notchglow
```
-->

---

### First-Launch Gatekeeper Notice (Unsigned Builds)

> [!IMPORTANT]
> If you download a prebuilt copy of NotchGlow that is not signed with an Apple Developer ID, macOS will show an "unidentified developer" warning on first launch. This is expected and only needs to be bypassed once.

#### Recommended: Terminal
After moving `NotchGlow.app` to `/Applications`, run:

```bash
xattr -dr com.apple.quarantine "/Applications/NotchGlow.app"
```

Then open the app normally.

#### Alternative: System Settings
1. Attempt to open **NotchGlow** and click **OK** on the security prompt.
2. Open **System Settings → Privacy & Security**.
3. Scroll to the bottom and click **Open Anyway** next to the NotchGlow notice.
4. Confirm when prompted.

---

## Usage & Permissions

1. Launch **NotchGlow**—a waveform icon appears in your macOS menu bar.
2. Click the icon to switch animation styles, toggle the **Layer** (above or beneath the menu bar), choose input triggers, or open **Customize…**.
3. Play music or start typing in any app to see the top of your screen react in real time.
4. Changes in **Customize…** preview live at the top of the screen and save automatically.

### macOS Privacy Permissions

macOS restricts global keyboard input, system audio, and microphone access. NotchGlow walks you through granting permission the first time you enable each trigger:

| Trigger | Required Permission | System Settings Path |
|---|---|---|
| **Typing in any app** | Input Monitoring **or** Accessibility | System Settings → Privacy & Security |
| **Music / System Audio (macOS 14.4+)** | System Audio Recording *(audio only, no screen access)* | System Settings → Privacy & Security → Screen & System Audio Recording → *System Audio Recording Only* |
| **Music / System Audio (macOS 13 – 14.3)** | Screen & System Audio Recording | System Settings → Privacy & Security |
| **Ambient Sound / Voice** | Microphone | System Settings → Privacy & Security |

After enabling a permission, macOS may require restarting the app before delivering events—use the built-in **Relaunch App** button in the app window.

> [!NOTE]
> **Privacy Guarantee:** Key events are never inspected—no characters, key codes, or modifiers are read, logged, or stored. Audio is analyzed live in memory (loudness + 16-band spectrum) and immediately discarded. NotchGlow makes zero network requests.

> [!TIP]
> **For Developers Rebuilding Locally:** `./build_app.sh` ad-hoc signs the binary, which can cause macOS to treat each rebuild as a new app and reset permissions. You can re-grant permissions, reset via `tccutil reset ListenEvent com.example.NotchGlow`, or sign with a consistent development certificate:
> ```bash
> CODESIGN_IDENTITY="Apple Development: Your Name" ./build_app.sh
> ```

---

## Roadmap

- [x] Typing reactions ⌨️
- [x] Music and system-sound reactions with beat detection and live spectrum 🎧
- [x] Microphone input 🎙️
- [x] 10 animation styles 🎨
- [x] Gradients, glow, blur, and full dimension control 🎚️
- [x] Above / beneath the menu bar layer 🪟
- [x] Connected sides and notch-aware center gap 🔗
- [x] Multi-display support 🖥️
- [x] Live preview and automatic settings persistence 💾
- [x] Launch at login 🚀
- [ ] Notarized release and Homebrew cask 📦
- [ ] Floating "island" mode 🏝️
- [ ] Shareable style presets and settings import / export 🧩
- [ ] Additional animation styles ✨

---

## Technical Architecture & Under the Hood

<details>
<summary><b>Settings Reference</b></summary>

- **General** — Enable/disable visualizer, pause all detection, target display(s), menu bar layer (above/beneath), notch clearance, vertical offset, launch at login, reset defaults.
- **Animation Styles** — Spike Wave, Needle Spikes, Audio Wave, Equalizer, LED Meter, Heartbeat, Lightning, Particle Burst, Energy Pulse, Minimal Glow.
- **Appearance** — Solid, two-color, or multi-color gradient (center → edge), opacity, glow, blur, corner radius, line thickness, spike/bar/column count, spike height, particle count, speed, intensity.
- **Dimensions** — Overall width and height, left/right expansion (% of half-width), connect left and right sides, center gap size.
- **Behavior** — Animation duration, fade-out duration, sensitivity, typing intensity, frequency, symmetry, randomization, idle animation.
- **Sound & Music** — Toggle triggers independently: typing, system music & audio, microphone.
- **Permissions & About** — Permission status helpers and app info.

</details>

<details>
<summary><b>Project Structure</b></summary>

```text
Sources/NotchGlow
├─ App/         main.swift, AppDelegate
├─ Core/        AnimationConfiguration, AppSettings, SettingsManager, AppEnvironment
├─ Audio/       AudioAnalyzer (loudness + 16-band spectrum), CoreAudioTapMonitor, SystemAudioMonitor, MicrophoneMonitor
├─ Keyboard/    KeyboardActivityMonitor (event-only detection), PermissionsManager
├─ MenuBar/     MenuBarManager (NSStatusItem + popover), MenuPopoverView
├─ Overlay/     VisualizerWindowController (non-activating click-through NSPanel per display), DisplayManager
├─ Animations/  VisualizerEngine (on-demand timer), VisualizerState, VisualizerRenderer,
│               StyleRenderer protocol + 10 style renderers, RenderContext, VisualizerView
├─ Settings/    SwiftUI settings window, panes, onboarding, live preview
└─ Utilities/   Math helpers, CodableColor, LaunchAtLogin
Resources/      Info.plist
```

Keyboard and audio monitors feed scalar intensity and frequency data into the animation engine; individual style renderers never access raw keystrokes or audio buffers.

</details>

<details>
<summary><b>Performance & Resource Usage</b></summary>

- **0% Idle CPU:** The 60 FPS render timer runs only while an animation is visible and stops completely once faded out.
- **Low-Power Idle Mode:** Optional idle animation (disabled by default) runs at 30 FPS.
- **Full Teardown on Disable:** Turning off the visualizer stops all timers, keyboard monitors, and audio taps, and hides all overlay panels.

</details>

<details>
<summary><b>Known Limitations</b></summary>

- Certain native full-screen apps and Spaces may cover or hide the overlay window.
- When the macOS menu bar is set to auto-hide, NotchGlow uses a `24 pt` fallback menu bar height (adjustable via **Vertical offset**).
- Enabling **Blur** applies a Core Image layer filter, which increases GPU usage while animating.
- macOS does not expose a public API to query the status of the audio-only capture permission, so the **Sound & Music** pane provides setup guidance and a relaunch button instead of a live status badge.

</details>

---

## Contributing

Contributions are welcome! Fork the repository, create a feature branch, and submit a pull request.

**Adding a new animation style:**
1. Create a renderer conforming to `StyleRenderer`.
2. Add a new case to `AnimationStyle`.
3. Return your renderer in `makeRenderer()`.

New styles automatically appear in both the menu bar popover and the **Customize…** window.

<!--
## Community & Support

<a href="https://discord.gg/<your-invite>" target="_blank"><img src="assets/discord.png" alt="Join the NotchGlow Discord server" height="60" /></a>
<a href="https://ko-fi.com/<your-name>" target="_blank"><img src="assets/kofi.png" alt="Support NotchGlow on Ko-fi" height="60" /></a>
-->

---

## Acknowledgments

NotchGlow is built entirely with Apple's native frameworks:

- **SwiftUI** & **AppKit** — Settings UI, menu bar popover, and click-through transparent overlay windows
- **Core Graphics** & **Core Animation** — High-frame-rate vector and glow rendering
- **Core Audio** & **ScreenCaptureKit** — Low-latency system audio capture
- **AVFoundation** — Real-time microphone input analysis

Thank you for checking out **NotchGlow**!
