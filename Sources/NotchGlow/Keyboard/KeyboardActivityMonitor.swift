import AppKit

/// Detects *that* a key was pressed, never *which* key.
/// The NSEvent is deliberately ignored: no characters, key codes, or modifiers are read, stored or logged.
final class KeyboardActivityMonitor {
    var onKeystroke: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        // Other apps (requires Input Monitoring or Accessibility permission).
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.onKeystroke?()
        }
        // Our own windows (no permission needed).
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.onKeystroke?()
            return event
        }
        isRunning = true
    }

    func stop() {
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
        globalMonitor = nil
        localMonitor = nil
        isRunning = false
    }

    deinit { stop() }
}
