import AppKit
import ApplicationServices
import AVFoundation
import CoreGraphics

/// Tracks the macOS privacy permissions the app can use:
/// - Input Monitoring / Accessibility (either one) for typing detection,
/// - Screen & System Audio Recording for laptop music / system sound,
/// - Microphone for sound around you.
final class PermissionsManager: ObservableObject {
    @Published private(set) var inputMonitoringGranted = false
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var screenRecordingGranted = false
    @Published private(set) var microphoneGranted = false

    /// Set by the app while typing reactions are wanted, so we keep checking until a permission is granted.
    var monitorsTyping = false { didSet { updatePolling() } }

    /// Set by the app while system-audio capture (ScreenCaptureKit fallback) is wanted.
    var monitorsScreenRecording = false { didSet { updatePolling() } }

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
        let sr = CGPreflightScreenCaptureAccess()
        let mic = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        if im != inputMonitoringGranted { inputMonitoringGranted = im }
        if ax != accessibilityGranted { accessibilityGranted = ax }
        if sr != screenRecordingGranted { screenRecordingGranted = sr }
        if mic != microphoneGranted { microphoneGranted = mic }
        updatePolling()
    }

    /// Poll (cheaply) only while a permission that is actually wanted is still missing.
    private func updatePolling() {
        let needsPolling = (monitorsTyping && !isSufficient) || (monitorsScreenRecording && !screenRecordingGranted)
        if !needsPolling {
            timer?.invalidate(); timer = nil
        } else if timer == nil {
            let t = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in self?.refresh() }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
    }

    // MARK: Requests
    func requestInputMonitoring() {
        _ = CGRequestListenEventAccess()
        refresh()
    }

    func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refresh()
    }

    func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
        refresh()
    }

    func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    // MARK: System Settings
    func openInputMonitoringSettings() { open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") }
    func openAccessibilitySettings() { open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") }
    func openScreenRecordingSettings() { open("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") }
    func openMicrophoneSettings() { open("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") }

    private func open(_ string: String) {
        if let url = URL(string: string) { NSWorkspace.shared.open(url) }
    }

    /// macOS sometimes only starts delivering events/audio after the app is relaunched.
    func relaunch() {
        // Start the new copy after this one has quit, so the single-instance check doesn't stop it.
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 0.8; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
        try? task.run()
        NSApp.terminate(nil)
    }
}
