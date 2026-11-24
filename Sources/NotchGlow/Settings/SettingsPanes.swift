import AppKit
import SwiftUI

// MARK: General
struct GeneralPane: View {
    @ObservedObject var settings: SettingsManager
    @State private var loginEnabled = LaunchAtLogin.isEnabled
    @State private var loginError: String?
    @State private var confirmReset = false

    /// Switching to "Selected displays" for the first time preselects the main display, so something is shown.
    private var displayModeBinding: Binding<DisplayMode> {
        Binding<DisplayMode>(
            get: { settings.app.displayMode },
            set: { newMode in
                if newMode == .selectedDisplays {
                    let available = DisplayManager.availableDisplays()
                    let connected = Set(available.map { $0.id })
                    let hasConnectedSelection = settings.app.selectedDisplays.contains { connected.contains($0) }
                    if !hasConnectedSelection, let first = available.first {
                        settings.app.selectedDisplays = [first.id]
                    }
                }
                settings.app.displayMode = newMode
            }
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            Card("Visualizer") {
                Toggle("Enable visualizer", isOn: settings.appBinding(\.isEnabled))
                Toggle("Pause all detection", isOn: settings.appBinding(\.detectionPaused))
                    .disabled(!settings.app.isEnabled)
                Text("Pausing stops listening to the keyboard, system sound and microphone entirely, while keeping the app available in the menu bar.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Card("Center") {
                Toggle("Connect left and right sides", isOn: settings.binding(\.connectSides))
                Text("Draws one continuous effect through the center. Turn off to leave a gap (for example around the notch).")
                    .font(.caption).foregroundStyle(.secondary)
                SliderRow(title: "Center size", value: settings.binding(\.centerSize), range: 0...400, step: 2, unit: " pt",
                          note: "Width of the empty gap at the center. Only used when the sides are not connected.")
                    .disabled(settings.config.connectSides)
            }
            Card("Display") {
                Picker("Show on", selection: displayModeBinding) {
                    ForEach(DisplayMode.allCases) { Text($0.title).tag($0) }
                }
                if settings.app.displayMode == .selectedDisplays {
                    DisplayChooser(settings: settings)
                }
                Picker("Layer", selection: settings.appBinding(\.layer)) {
                    ForEach(OverlayLayer.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text("Above draws the effect on top of the menu bar, including its blurred background. Beneath draws it behind the menu bar, so the blur is applied over the effect.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Show over full-screen apps", isOn: settings.appBinding(\.showInFullScreen))
                Text("Turn this off to hide the effect while an app, video or game is in full screen.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Keep the camera notch area clear", isOn: settings.appBinding(\.avoidNotch))
                SliderRow(title: "Vertical offset", value: settings.appBinding(\.verticalOffset),
                          range: -30...60, step: 1, unit: " pt",
                          note: "Fine-tune the animation's position relative to the menu bar. Positive moves it down.")
            }
            Card("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { loginEnabled },
                    set: { newValue in
                        do { try LaunchAtLogin.set(newValue); loginError = nil }
                        catch { loginError = error.localizedDescription }
                        loginEnabled = LaunchAtLogin.isEnabled
                    }))
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
            }
            Card("Reset") {
                Button("Reset All Settings to Defaults…", role: .destructive) { confirmReset = true }
            }
        }
        .confirmationDialog("Reset all settings to their defaults?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) { settings.resetAll() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: Styles
struct StylesPane: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
            ForEach(AnimationStyle.allCases) { style in
                let selected = settings.config.style == style
                Button { settings.config.style = style } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: style.symbol).font(.title2).foregroundStyle(.tint)
                        Text(style.title).font(.headline)
                        Text(style.summary).font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(nsColor: .controlBackgroundColor)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(selected ? Color.accentColor : Color.primary.opacity(0.08),
                                          lineWidth: selected ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: Appearance
struct AppearancePane: View {
    @ObservedObject var settings: SettingsManager
    @State private var showCustomColors = false

    var body: some View {
        VStack(spacing: 16) {
            Card("Color palette") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                    ForEach(ColorPalette.all) { palette in
                        PaletteSwatch(palette: palette, isSelected: settings.isActive(palette)) {
                            settings.applyPalette(palette)
                        }
                    }
                }
                Text("Gradients run from the center outward.")
                    .font(.caption).foregroundStyle(.secondary)

                Button {
                    showCustomColors.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCustomColors ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold)).frame(width: 10)
                        Text("Custom colors")
                    }
                }
                .buttonStyle(.plain)

                // Created only when opened: color wells are comparatively expensive to build.
                if showCustomColors {
                    CustomColorsView(settings: settings)
                }
            }
            Card("Look") {
                SliderRow(title: "Opacity", value: settings.binding(\.opacity), range: 0.1...1, decimals: 2)
                SliderRow(title: "Glow intensity", value: settings.binding(\.glow), range: 0...1, decimals: 2)
                SliderRow(title: "Blur", value: settings.binding(\.blur), range: 0...10, step: 0.5, unit: " pt")
                SliderRow(title: "Corner radius", value: settings.binding(\.cornerRadius), range: 0...20, step: 0.5,
                          unit: " pt", note: "Spikes, bars, LED dots and pulse trails.")
                SliderRow(title: "Line thickness", value: settings.binding(\.lineThickness), range: 1...10, step: 0.5,
                          unit: " pt", note: "Line width / spike & bar width / particle size.")
            }
            Card("Elements") {
                SliderRow(title: "Spike / bar / column count", value: settings.intBinding(\.spikeCount), range: 6...80,
                          step: 1, note: "Per side. Used by Spike Wave, Equalizer and LED Meter.")
                SliderRow(title: "Spike height", value: settings.binding(\.spikeHeight), range: 0.2...1, decimals: 2,
                          note: "Fraction of the overall height that elements may reach.")
                SliderRow(title: "Particle count", value: settings.intBinding(\.particleCount), range: 10...300,
                          step: 5, note: "Maximum live particles. Used by Particle Burst.")
            }
            Card("Motion") {
                SliderRow(title: "Animation speed", value: settings.binding(\.speed), range: 0.3...3, decimals: 2, unit: "×")
                SliderRow(title: "Animation intensity", value: settings.binding(\.intensity), range: 0.2...2, decimals: 2, unit: "×")
            }
        }
    }
}

/// One palette in the grid: a gradient bar with its name.
struct PaletteSwatch: View {
    let palette: ColorPalette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                LinearGradient(colors: palette.colors.map { $0.color }, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(palette.name).font(.caption)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(isSelected ? 0.10 : 0.04)))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.10), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(palette.name) palette")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Manual color mode and pickers (the original color controls), shown on demand.
struct CustomColorsView: View {
    @ObservedObject var settings: SettingsManager

    private var gradientColors: [Color] {
        let c = settings.config.activeColors.map { $0.color }
        return c.count == 1 ? c + c : c
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: settings.binding(\.colorMode)) {
                ForEach(ColorMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden()

            let count = settings.config.activeColors.count
            ForEach(0..<count, id: \.self) { i in
                ColorPicker(count == 1 ? "Color" : "Color \(i + 1)",
                            selection: settings.colorBinding(i), supportsOpacity: false)
            }
            if settings.config.colorMode == .multiColor {
                Stepper("Number of colors: \(settings.config.multiColorStops)",
                        value: settings.binding(\.multiColorStops), in: 3...5)
            }
            LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                .frame(height: 10).clipShape(Capsule())
        }
    }
}

// MARK: Dimensions
struct DimensionsPane: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        VStack(spacing: 16) {
            Card("Size") {
                SliderRow(title: "Overall width", value: settings.binding(\.width), range: 120...1600, step: 10, unit: " pt")
                SliderRow(title: "Overall height", value: settings.binding(\.height), range: 8...160, step: 1, unit: " pt")
            }
            Card("Expansion") {
                SliderRow(title: "Left expansion", value: settings.binding(\.leftExpansion), range: 5...100, step: 1,
                          unit: " %", note: "How far the left side may reach, as a share of half the overall width.")
                SliderRow(title: "Right expansion", value: settings.binding(\.rightExpansion), range: 5...100, step: 1,
                          unit: " %", note: "Same for the right side. Set different values for a lopsided effect.")
            }
        }
    }
}

// MARK: Behavior
struct BehaviorPane: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        VStack(spacing: 16) {
            Card("Timing") {
                SliderRow(title: "Animation duration", value: settings.binding(\.animationDuration),
                          range: 0.2...4, decimals: 1, unit: " s", note: "How long the animation stays after your last keystroke.")
                SliderRow(title: "Fade-out duration", value: settings.binding(\.fadeOutDuration),
                          range: 0.1...3, decimals: 1, unit: " s")
            }
            Card("Reaction") {
                SliderRow(title: "Reaction sensitivity", value: settings.binding(\.sensitivity),
                          range: 0.3...3, decimals: 2, unit: "×", note: "How strongly each keystroke (and music or sound) registers.")
                SliderRow(title: "Typing intensity", value: settings.binding(\.typingIntensity),
                          range: 0.3...2, decimals: 2, unit: "×", note: "How strongly typing speed raises the energy.")
                SliderRow(title: "Animation frequency", value: settings.binding(\.frequency),
                          range: 0.3...3, decimals: 2, unit: "×", note: "How quickly waves oscillate and random patterns change.")
            }
            Card("Patterns") {
                Toggle("Symmetrical animation", isOn: settings.binding(\.symmetrical))
                Toggle("Randomized patterns", isOn: settings.binding(\.randomized))
                Toggle("Idle animation", isOn: settings.binding(\.idleAnimation))
                Text("Idle animation keeps a faint animation running while you're not typing (renders at 30 FPS). Leave it off for zero background rendering.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Card {
                Button("Reset Animation Settings") { settings.resetAnimation() }
            }
        }
    }
}

// MARK: Sound & Music
struct SoundPane: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var permissions: PermissionsManager
    @ObservedObject var audioStatus: AudioStatus

    var body: some View {
        VStack(spacing: 16) {
            Card("React to") {
                Toggle("Typing", isOn: settings.appBinding(\.reactToTyping))
                Toggle("Laptop music & system sound", isOn: settings.appBinding(\.reactToSystemAudio))
                Text("Everything your Mac plays: Apple Music, Spotify, YouTube, videos and more.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Microphone (sound around you)", isOn: settings.appBinding(\.reactToMicrophone))
                Text("You can combine sources. Turn on only what you want.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if settings.app.reactToSystemAudio {
                Card("Laptop music & system sound") {
                    if SystemAudioBackend.usesCoreAudioTap {
                        Text("macOS will ask to allow \u{201C}System Audio Recording\u{201D}. That permission is for audio only: NotchGlow cannot see your screen. If the animation doesn't react to music, make sure NotchGlow is switched on under System Settings \u{2192} Privacy & Security \u{2192} Screen & System Audio Recording \u{2192} System Audio Recording Only.")
                            .font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack {
                            Button("Open System Settings") { permissions.openScreenRecordingSettings() }
                            Button("Relaunch App") { permissions.relaunch() }
                        }.controlSize(.small)
                    } else {
                        PermissionRow(
                            title: "Screen & System Audio Recording",
                            detail: "On this version of macOS, system audio capture needs this permission. Only the sound is analyzed; no screen content is recorded, stored or shown.",
                            granted: permissions.screenRecordingGranted,
                            request: permissions.requestScreenRecording,
                            openSettings: permissions.openScreenRecordingSettings)
                        if !permissions.screenRecordingGranted {
                            Button("Relaunch App") { permissions.relaunch() }.controlSize(.small)
                        }
                    }
                    if let error = audioStatus.systemError {
                        Text(error).font(.caption).foregroundStyle(.red)
                    } else if audioStatus.systemRunning {
                        Label("Listening to system sound", systemImage: "waveform").foregroundStyle(.green).font(.callout)
                    }
                }
            }

            if settings.app.reactToMicrophone {
                Card("Microphone") {
                    PermissionRow(
                        title: "Microphone",
                        detail: "Lets the visualizer react to sound picked up by your Mac's microphone. Audio is never recorded or stored.",
                        granted: permissions.microphoneGranted,
                        request: permissions.requestMicrophone,
                        openSettings: permissions.openMicrophoneSettings)
                    if audioStatus.micRunning {
                        Label("Listening to the microphone", systemImage: "mic.fill").foregroundStyle(.green).font(.callout)
                    }
                }
            }

            Card("How it reacts") {
                Text("Loudness drives the energy, beats trigger ripples and bursts, and Spike Wave, Equalizer and LED Meter show a live frequency spectrum, with bass in the center and treble toward the edges. Tune it with Reaction sensitivity in Behavior. The live preview above reacts to sound too.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Card {
                Label("Sound stays private", systemImage: "lock.shield.fill").font(.headline)
                Text("Audio is analyzed in memory to measure loudness and frequencies, then discarded. Nothing is recorded, saved or sent anywhere.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: Permissions
struct PermissionsPane: View {
    @ObservedObject var permissions: PermissionsManager

    var body: some View {
        VStack(spacing: 16) {
            Card("Why permissions are needed") {
                Text("macOS protects keyboard input. To animate while you type in other apps, NotchGlow needs either the Input Monitoring or the Accessibility permission. Open System Settings → Privacy & Security, switch NotchGlow on, and come back here.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Card("Status") {
                PermissionRowsView(permissions: permissions)
                Divider()
                Text("If the animation doesn't react right after granting access, macOS may need the app to restart.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Re-check") { permissions.refresh() }
                    Button("Relaunch App") { permissions.relaunch() }
                }
            }
            Card { PrivacyNote() }
        }
    }
}

// MARK: About
struct AboutPane: View {
    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            Card {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable().frame(width: 64, height: 64)
                    VStack(alignment: .leading) {
                        Text("NotchGlow").font(.title2.bold())
                        Text("Version \(version) (\(build))").foregroundStyle(.secondary)
                    }
                }
                Text("Dynamic, customizable animations around the menu bar that react to your typing.")
                    .foregroundStyle(.secondary)
            }
            Card { PrivacyNote() }
        }
    }
}

// MARK: Display chooser
/// Checkbox list of the connected displays, used by "Selected displays".
struct DisplayChooser: View {
    @ObservedObject var settings: SettingsManager
    @State private var displays = DisplayManager.availableDisplays()

    private func binding(for id: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { settings.app.selectedDisplays.contains(id) },
            set: { isOn in
                var selection = settings.app.selectedDisplays
                if isOn {
                    if !selection.contains(id) { selection.append(id) }
                } else {
                    selection.removeAll { $0 == id }
                }
                settings.app.selectedDisplays = selection
            }
        )
    }

    private var hasConnectedSelection: Bool {
        displays.contains { settings.app.selectedDisplays.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(displays) { display in
                Toggle(isOn: binding(for: display.id)) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(display.name)
                        Text(display.detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
            }
            if !hasConnectedSelection {
                Label("No connected display is selected, so nothing is shown.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(.leading, 4)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            displays = DisplayManager.availableDisplays()
        }
    }
}
