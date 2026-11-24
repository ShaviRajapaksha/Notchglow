import AppKit
import Combine

/// Wires everything together: settings -> engines/overlay, permissions -> input monitors.
final class AppEnvironment {
    static let shared = AppEnvironment()

    let settings: SettingsManager
    let permissions: PermissionsManager
    let monitor: KeyboardActivityMonitor
    let systemAudio: SystemAudioSource
    let microphone: MicrophoneMonitor
    let audioStatus: AudioStatus
    let overlayEngine: VisualizerEngine
    let previewEngine: VisualizerEngine      // drives the live preview in Settings
    let overlay: VisualizerWindowController

    private var bag = Set<AnyCancellable>()
    private var askedScreenRecording = false

    private init() {
        let s = SettingsManager()
        let oe = VisualizerEngine(config: s.config)
        let pe = VisualizerEngine(config: s.config)
        pe.lowPower = true
        settings = s
        permissions = PermissionsManager()
        monitor = KeyboardActivityMonitor()
        if #available(macOS 14.4, *) {
            systemAudio = CoreAudioTapMonitor()        // audio-only permission, no screen access
        } else {
            systemAudio = SystemAudioMonitor()         // ScreenCaptureKit fallback for older macOS
        }
        microphone = MicrophoneMonitor()
        audioStatus = AudioStatus()
        overlayEngine = oe
        previewEngine = pe
        overlay = VisualizerWindowController(engine: oe, settings: s)
    }

    func start() {
        // Only "a key was pressed" is forwarded; never which key.
        monitor.onKeystroke = { [weak self] in self?.handleKeystroke() }

        // Audio is analyzed in memory (loudness + spectrum) and discarded; nothing is stored.
        let audioHandler: (Float, [Float]) -> Void = { [weak self] level, bands in
            self?.overlayEngine.registerAudio(level: level, bands: bands)
            self?.previewEngine.registerAudio(level: level, bands: bands)
        }
        systemAudio.onAudio = audioHandler
        microphone.onAudio = audioHandler
        systemAudio.onStatus = { [weak self] running, error in
            DispatchQueue.main.async {
                self?.audioStatus.systemRunning = running
                self?.audioStatus.systemError = error
            }
        }
        microphone.onStatus = { [weak self] running in
            DispatchQueue.main.async { self?.audioStatus.micRunning = running }
        }

        settings.$config
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cfg in
                guard let self else { return }
                self.overlayEngine.config = cfg
                self.previewEngine.config = cfg
                self.overlay.rebuild()
            }
            .store(in: &bag)

        settings.$app
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyState()
                self?.overlay.rebuild()
            }
            .store(in: &bag)

        permissions.objectWillChange
            .receive(on: DispatchQueue.main)          // deferred, so values are up to date
            .sink { [weak self] _ in self?.applyState() }
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.overlay.rebuild() }
            .store(in: &bag)

        permissions.start()
        applyState()
    }

    func stop() {
        monitor.stop()
        systemAudio.stop()
        microphone.stop()
        settings.flush()
    }

    /// Start/stop every input according to settings + permissions.
    func applyState() {
        let a = settings.app
        overlayEngine.isEnabled = a.isEnabled
        let live = a.isEnabled && !a.detectionPaused

        // Typing
        permissions.monitorsTyping = live && a.reactToTyping
        if live && a.reactToTyping && permissions.isSufficient { monitor.start() } else { monitor.stop() }

        // Laptop music / system sound
        let wantSystem = live && a.reactToSystemAudio
        if SystemAudioBackend.usesCoreAudioTap {
            // macOS 14.4+: audio-only tap. macOS shows its own prompt the first time.
            if wantSystem { systemAudio.start() } else { systemAudio.stop() }
        } else {
            // Older macOS: ScreenCaptureKit needs the Screen & System Audio Recording permission.
            permissions.monitorsScreenRecording = wantSystem
            if wantSystem && !permissions.screenRecordingGranted && !askedScreenRecording {
                askedScreenRecording = true
                permissions.requestScreenRecording()
            }
            if wantSystem && permissions.screenRecordingGranted { systemAudio.start() } else { systemAudio.stop() }
        }

        // Microphone
        if live && a.reactToMicrophone { microphone.start() } else { microphone.stop() }
    }

    private func handleKeystroke() {
        overlay.refreshActiveDisplayIfNeeded()
        overlayEngine.registerKeystroke()
        previewEngine.registerKeystroke()
    }
}
