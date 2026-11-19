# NotchGlow (macOS menu-bar app)

Dynamic animations at the top-center of your screen, aligned with the menu bar, that react to typing in any app.
Native Swift · SwiftUI · AppKit · Core Graphics. Requires macOS 13+ and the Xcode command line tools (Swift 5.9+).

## Build & run

```bash
xcode-select --install          # once, if you don't have the Swift toolchain
cd NotchGlow
./build_app.sh                  # builds and creates build/NotchGlow.app
open build/NotchGlow.app
```

Debug build: `./build_app.sh debug`. Quit from the menu-bar popover. The app has no Dock icon (`LSUIElement`).

## Permissions (required for global typing detection)

macOS blocks apps from observing keyboard events in other apps. Grant **one** of:

| Permission | Where |
|---|---|
| Input Monitoring | System Settings → Privacy & Security → Input Monitoring |
| Accessibility | System Settings → Privacy & Security → Accessibility |

A first-run window explains this and has buttons that trigger the system prompt / open the right pane.
After granting, macOS sometimes only delivers events after a relaunch (there is a "Relaunch App" button).

**Privacy:** the key event is never inspected — no characters, key codes or modifiers are read, stored, logged or sent
anywhere (`Keyboard/KeyboardActivityMonitor.swift` ignores the event object). The app makes no network connections.

**Rebuilds & permissions:** the build script ad-hoc signs the app, so macOS may treat every rebuild as a new app and
drop the permission. Either re-grant, reset with `tccutil reset ListenEvent com.example.NotchGlow`, or sign with
a stable certificate: `CODESIGN_IDENTITY="Apple Development: Your Name" ./build_app.sh`.

## Settings reference

* **General** – enable/disable, pause detection, display(s), notch avoidance, vertical offset, launch at login, reset.
* **Animation Styles** – Spike Wave, Audio Wave, Equalizer, Particle Burst, Energy Pulse, Digital Rain, Minimal Glow.
* **Appearance** – solid/two-color/multi-color gradient (center → edge), opacity, glow, blur, corner radius, line thickness,
  spike/bar/column count, spike height, particle count, speed, intensity.
* **Dimensions** – overall width/height, left/right expansion (% of half-width), center size (empty gap at the center).
* **Behavior** – animation duration, fade-out duration, sensitivity, typing intensity, frequency, symmetrical,
  randomized, idle animation.
* **Permissions**, **About**.

Everything is previewed live at the top of the settings window and saved automatically (UserDefaults, JSON).

## Architecture

```
Sources/NotchGlow
├─ App/         main.swift, AppDelegate
├─ Core/        AnimationConfiguration, AppSettings, SettingsManager, AppEnvironment (wiring)
├─ Keyboard/    KeyboardActivityMonitor (events only), PermissionsManager
├─ MenuBar/     MenuBarManager (NSStatusItem + popover), MenuPopoverView
├─ Overlay/     VisualizerWindowController (non-activating click-through NSPanel per display), DisplayManager
├─ Animations/  VisualizerEngine (timer only while animating), VisualizerState, VisualizerRenderer,
│               StyleRenderer protocol + 7 style renderers, RenderContext, VisualizerView
├─ Settings/    SwiftUI settings window, panes, onboarding, live preview
├─ Utilities/   math helpers, CodableColor, LaunchAtLogin
Resources/      Info.plist
```

Keyboard detection only calls `engine.registerKeystroke()`; renderers never see the keyboard. To add a style, implement
`StyleRenderer`, add a case to `AnimationStyle`, and return it from `makeRenderer()`.

## Performance notes

* The 60 FPS timer exists only while something is visible; when the animation has faded out it is stopped (0% CPU).
* "Idle animation" (off by default) runs at 30 FPS.
* Disabling the visualizer stops the timer and the keyboard monitor and hides the overlay windows.

## Known limitations

* Overlay uses window level `.statusBar` with `fullScreenAuxiliary`; some full-screen apps/Spaces may hide it.
* If the menu bar is auto-hidden, the animation is positioned using a 24 pt fallback menu-bar height (adjust with Vertical offset).
* Blur uses a Core Image layer filter, which adds some GPU work when enabled.
