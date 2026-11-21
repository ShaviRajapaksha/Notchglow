<h1 align="center">
  <br>
  <!-- Add your logo here, for example: -->
  <!-- <a href="https://github.com/<your-username>/NotchGlow"><img src="assets/logo.png" alt="NotchGlow" width="150"></a> -->
  <br>
  NotchGlow
  <br>
</h1>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple&logoColor=white" alt="macOS 13+" />
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift 5.9" />
  <img src="https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-native-0A84FF" alt="SwiftUI and AppKit" />
  <img src="https://img.shields.io/badge/network-none-30D158" alt="Makes no network connections" />
</p>

Say hello to **NotchGlow**, the coolest way to make your Mac's menu bar and notch the star of the show! Instead of a static strip of icons, the top of your screen lights up with a vibrant, fully customizable visualizer that dances to your **music**, your **sound**, and your **typing**. Pick from 10 animation styles, tune every dimension, color and glow, and watch it react in real time. It's a native menu-bar app, lightweight, and it only renders while something is actually moving.

<p align="center">
  <img
    src="assets/notchglow.gif"
    alt="NotchGlow demonstration"
    width="100%"
  />
</p>

---

## ✨ Features

- 🎧 **Music and sound reactive** — follows whatever your Mac plays (Apple Music, Spotify, YouTube…) or the microphone, with beat detection and a live frequency spectrum
- ⌨️ **Typing reactive** — every keystroke sends a ripple from the center; type fast and it gets more energetic, stop and it fades away
- 🎨 **10 animation styles** — Spike Wave, Needle Spikes, Audio Wave, Equalizer, LED Meter, Heartbeat, Lightning, Particle Burst, Energy Pulse, Minimal Glow
- 🎚️ **Fully customizable** — width, height, expansion, gradients, opacity, glow, blur, speed, intensity, symmetry and more, with a live preview
- 🪟 **Above or beneath the menu bar** — draw on top of the menu bar's blur, or behind it
- 🔗 **Connected sides** — one continuous effect through the center, or leave a gap for the notch
- 🖥️ **Multi-display** — all displays, the display under your mouse, or just the primary one
- 🔒 **Private by design** — it never reads *which* key you press, never records audio, and makes no network connections

---

## Installation

**System Requirements:**
- macOS **13 Ventura** or later
- Apple Silicon or Intel Mac (the app is built for the Mac you build it on)

> [!NOTE]
> Music and system-sound reactions use an audio-only permission on **macOS 14.4 or later**. On macOS 13 – 14.3 they use the *Screen & System Audio Recording* permission instead. Typing and microphone reactions work on every supported version.

---

### Option 1: Build from Source (3 commands)

```bash
xcode-select --install          # once, if you don't have the Swift toolchain
cd NotchGlow
./build_app.sh                  # builds and creates build/NotchGlow.app
open build/NotchGlow.app
```

Debug build: `./build_app.sh debug`. Quit from the menu-bar popover. The app has no Dock icon.

<!--
### Option 2: Download and Install Manually
Uncomment this section once you publish a release.

<a href="https://github.com/<your-username>/NotchGlow/releases/latest/download/NotchGlow.dmg" target="_self"><img width="200" src="assets/download.png" alt="Download for macOS" /></a>

Once downloaded, open the `.dmg` and move **NotchGlow** to your `/Applications` folder.
-->

<!--
### Option 3: Install via Homebrew
Uncomment once you have a Homebrew tap.

```bash
brew install --cask <your-username>/notchglow/notchglow
```
-->

---

> [!IMPORTANT]
> If you download a prebuilt copy of NotchGlow that isn't signed with an Apple Developer ID, macOS will warn you that it is from an unidentified developer on first launch. This is expected. You only need to bypass it once.

#### Recommended: Terminal (always works)

After moving NotchGlow to your Applications folder, run:

```bash
xattr -dr com.apple.quarantine "/Applications/NotchGlow.app"
```

Then open the app normally.

#### Alternative: System Settings

1. Try to open the app. You'll see a security warning.
2. Click **OK** to dismiss it.
3. Open **System Settings** > **Privacy & Security**.
4. Scroll to the bottom and click **Open Anyway** next to the NotchGlow warning.
5. Confirm if prompted.

---

## Usage

- Launch the app, and voilà — a waveform icon appears in your menu bar.
- Click it to switch animation styles, flip the **Layer** (above/beneath the menu bar), toggle what NotchGlow reacts to, or open **Customize…**.
- Start typing, or play some music, and watch the top of your screen come alive.
- In **Customize…**, every change is previewed live at the top of the window and saved automatically.

### Permissions

macOS protects keyboard input, system audio and the microphone, so NotchGlow asks for permission the first time you use each one. A first-run window walks you through it.

| What you want | Permission | Where |
|---|---|---|
| React to typing in other apps | Input Monitoring **or** Accessibility (either one) | System Settings → Privacy & Security |
| React to music / system sound (macOS 14.4+) | System Audio Recording (audio only, no screen access) | System Settings → Privacy & Security → Screen & System Audio Recording → *System Audio Recording Only* |
| React to music / system sound (macOS 13 – 14.3) | Screen & System Audio Recording | System Settings → Privacy & Security |
| React to sound around you | Microphone | System Settings → Privacy & Security |

After granting a permission, macOS sometimes only starts delivering events after a relaunch. There is a **Relaunch App** button in the app for that.

> [!NOTE]
> **Privacy:** the key event is never inspected — no characters, key codes or modifiers are read, stored, logged or sent anywhere. Audio is analyzed live in memory (loudness plus a 16-band spectrum) and immediately discarded; nothing is recorded or saved. The app makes no network connections.

> [!TIP]
> The build script ad-hoc signs the app, so macOS may treat every rebuild as a new app and drop its permissions. Either re-grant them, reset with `tccutil reset ListenEvent com.example.NotchGlow`, or sign with a stable certificate:
> `CODESIGN_IDENTITY="Apple Development: Your Name" ./build_app.sh`

---

## 📋 Roadmap

- [x] Typing reactions ⌨️
- [x] Music and system-sound reactions with beat detection and live spectrum 🎧
- [x] Microphone input 🎙️
- [x] 10 animation styles 🎨
- [x] Gradients, glow, blur and full dimension control 🎚️
- [x] Above / beneath the menu bar layer 🪟
- [x] Connected sides and notch-aware center gap 🔗
- [x] Multi-display support 🖥️
- [x] Live preview and automatic saving of settings 💾
- [x] Launch at login 🚀
- [ ] Notarized release and Homebrew cask 📦
- [ ] Floating "island" mode 🏝️
- [ ] Style presets and settings import / export 🧩
- [ ] More animation styles ✨

---

## 🛠️ Under the Hood

<details>
<summary><b>Settings reference</b></summary>

* **General** – enable/disable, pause all detection, display(s), layer (above or beneath the menu bar), keep the notch area clear, vertical offset, launch at login, reset.
* **Animation Styles** – Spike Wave, Needle Spikes, Audio Wave, Equalizer, LED Meter, Heartbeat, Lightning, Particle Burst, Energy Pulse, Minimal Glow.
* **Appearance** – solid / two-color / multi-color gradient (center → edge), opacity, glow, blur, corner radius, line thickness, spike/bar/column count, spike height, particle count, speed, intensity.
* **Dimensions** – overall width and height, left/right expansion (% of half-width), connect left and right sides, center size (empty gap at the center).
* **Behavior** – animation duration, fade-out duration, sensitivity, typing intensity, frequency, symmetrical, randomized, idle animation.
* **Sound & Music** – choose what to react to: typing, laptop music & system sound, microphone.
* **Permissions**, **About**.

</details>

<details>
<summary><b>Architecture</b></summary>

```
Sources/NotchGlow
├─ App/         main.swift, AppDelegate
├─ Core/        AnimationConfiguration, AppSettings, SettingsManager, AppEnvironment (wiring)
├─ Audio/       AudioAnalyzer (loudness + spectrum), CoreAudioTapMonitor, SystemAudioMonitor, MicrophoneMonitor
├─ Keyboard/    KeyboardActivityMonitor (events only), PermissionsManager
├─ MenuBar/     MenuBarManager (NSStatusItem + popover), MenuPopoverView
├─ Overlay/     VisualizerWindowController (non-activating click-through NSPanel per display), DisplayManager
├─ Animations/  VisualizerEngine (timer only while animating), VisualizerState, VisualizerRenderer,
│               StyleRenderer protocol + 10 style renderers, RenderContext, VisualizerView
├─ Settings/    SwiftUI settings window, panes, onboarding, live preview
├─ Utilities/   math helpers, CodableColor, LaunchAtLogin
Resources/      Info.plist
```

Keyboard and audio detection only feed the animation engine; renderers never see the keyboard or raw audio.

</details>

<details>
<summary><b>Performance</b></summary>

* The 60 FPS timer exists only while something is visible; once the animation has faded out it is stopped (0% CPU).
* "Idle animation" (off by default) runs at 30 FPS.
* Disabling the visualizer stops the timer, the keyboard monitor and the audio monitors, and hides the overlay windows.

</details>

<details>
<summary><b>Known limitations</b></summary>

* Some full-screen apps and Spaces may hide the overlay.
* If the menu bar is auto-hidden, the animation is positioned using a 24 pt fallback menu-bar height (adjust with **Vertical offset**).
* Blur uses a Core Image layer filter, which adds some GPU work when enabled.
* macOS offers no public way to read the status of the audio-only permission, so the Sound & Music pane shows guidance and a relaunch button instead of a status indicator.

</details>

---
<!--
## 🤝 Contributing

Contributions are welcome! Fork the repo, create a branch, and open a pull request.

**Adding an animation style** is the easiest way to get started:

1. Create a renderer that implements `StyleRenderer`.
2. Add a case to `AnimationStyle`.
3. Return your renderer from `makeRenderer()`.

It then shows up in the menu-bar popover and in the settings window automatically.
-->

<!--
## Join our Discord Server
<a href="https://discord.gg/<your-invite>" target="_blank"><img src="assets/discord.png" alt="Join the NotchGlow server" style="height: 60px !important;" ></a>

## Support us on Ko-fi!
<a href="https://ko-fi.com/<your-name>" target="_blank"><img src="assets/kofi.png" alt="Support us on Ko-fi" style="height: 70px !important;" ></a>
-->

---

## 🎉 Acknowledgments

NotchGlow is built entirely on Apple's native frameworks:

- **SwiftUI** and **AppKit** for the interface and the transparent overlay windows
- **Core Graphics** and **Core Animation** for rendering
- **Core Audio** and **ScreenCaptureKit** for listening to system sound
- **AVFoundation** for the microphone

Thank you for checking out **NotchGlow**!
