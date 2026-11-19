import AppKit
import ApplicationServices
import CoreGraphics

/// Tracks the two macOS privacy permissions that allow observing global key events.
/// Either one is sufficient for NSEvent global key monitoring.
final class PermissionsManager: ObservableObject {
    @Published private(set) var inputMonitoringGranted = false
    @Published private(set) var accessibilityGranted = false

    var isSufficient: Bool { inputMonitoringGranted || accessibilityGranted }

    private var timer: Timer?

    func start() {
        refresh()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        let im = CGPreflightListenEventAccess()
        let ax = AXIsProcessTrusted()
        if im != inputMonitoringGranted { inputMonitoringGranted = im }
        if ax != accessibilityGranted { accessibilityGranted = ax }
        updatePolling()
    }

    /// Poll (cheaply) only while no permission is granted, so we notice the grant without a restart of the UI.
    private func updatePolling() {
        if isSufficient {
            timer?.invalidate(); timer = nil
        } else if timer == nil {
            let t = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in self?.refresh() }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
    }

    func requestInputMonitoring() {
        _ = CGRequestListenEventAccess()
        refresh()
    }

    func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refresh()
    }

    func openInputMonitoringSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    private func open(_ string: String) {
        if let url = URL(string: string) { NSWorkspace.shared.open(url) }
    }

    /// macOS sometimes only starts delivering events after the app is relaunched.
    func relaunch() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", Bundle.main.bundleURL.path]
        try? task.run()
        NSApp.terminate(nil)
    }
}
