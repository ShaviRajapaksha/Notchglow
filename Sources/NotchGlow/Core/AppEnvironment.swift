import AppKit
import Combine

/// Wires everything together: settings -> engines/overlay, permissions -> keyboard monitor.
final class AppEnvironment {
    static let shared = AppEnvironment()

    let settings: SettingsManager
    let permissions: PermissionsManager
    let monitor: KeyboardActivityMonitor
    let overlayEngine: VisualizerEngine
    let previewEngine: VisualizerEngine      // drives the live preview in Settings
    let overlay: VisualizerWindowController

    private var bag = Set<AnyCancellable>()

    private init() {
        let s = SettingsManager()
        let oe = VisualizerEngine(config: s.config)
        let pe = VisualizerEngine(config: s.config)
        settings = s
        permissions = PermissionsManager()
        monitor = KeyboardActivityMonitor()
        overlayEngine = oe
        previewEngine = pe
        overlay = VisualizerWindowController(engine: oe, settings: s)
    }

    func start() {
        // Only "a key was pressed" is forwarded; never which key.
        monitor.onKeystroke = { [weak self] in self?.handleKeystroke() }

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

        permissions.$inputMonitoringGranted
            .combineLatest(permissions.$accessibilityGranted)
            .receive(on: DispatchQueue.main)
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
        settings.flush()
    }

    /// Start/stop the keyboard monitor and overlay according to settings + permissions.
    func applyState() {
        let a = settings.app
        overlayEngine.isEnabled = a.isEnabled
        let shouldMonitor = a.isEnabled && !a.detectionPaused && permissions.isSufficient
        if shouldMonitor { monitor.start() } else { monitor.stop() }
    }

    private func handleKeystroke() {
        overlay.refreshActiveDisplayIfNeeded()
        overlayEngine.registerKeystroke()
        previewEngine.registerKeystroke()
    }
}
