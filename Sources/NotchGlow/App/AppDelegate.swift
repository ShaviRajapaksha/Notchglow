import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let showSettingsNotification = Notification.Name("com.notchglow.app.showSettings")

    private var menuBar: MenuBarManager?
    private let settingsWindow = SettingsWindowController()
    private let onboardingWindow = OnboardingWindowController()
    private var isDuplicateInstance = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Only one copy may run. Launching a second time just opens Settings in the first one.
        if handOverToRunningInstance() { return }

        let env = AppEnvironment.shared
        env.start()

        menuBar = MenuBarManager(
            settings: env.settings,
            permissions: env.permissions,
            openSettings: { [weak self] pane in self?.settingsWindow.show(pane: pane) },
            openOnboarding: { [weak self] in self?.onboardingWindow.show() }
        )

        DistributedNotificationCenter.default().addObserver(
            forName: Self.showSettingsNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.settingsWindow.show() }

        if !env.settings.app.hasCompletedOnboarding { onboardingWindow.show() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // A duplicate instance must never write its (default) settings over the real ones.
        if !isDuplicateInstance { AppEnvironment.shared.stop() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Returns true (and quits this copy) if another instance of the app is already running.
    private func handOverToRunningInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let current = NSRunningApplication.current
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != current.processIdentifier }
        guard !others.isEmpty else { return false }

        isDuplicateInstance = true
        DistributedNotificationCenter.default().postNotificationName(
            Self.showSettingsNotification, object: nil, userInfo: nil, deliverImmediately: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { NSApp.terminate(nil) }
        return true
    }
}
