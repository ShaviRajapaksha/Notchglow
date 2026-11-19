import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarManager?
    private let settingsWindow = SettingsWindowController()
    private let onboardingWindow = OnboardingWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let env = AppEnvironment.shared
        env.start()

        menuBar = MenuBarManager(
            settings: env.settings,
            permissions: env.permissions,
            openSettings: { [weak self] pane in self?.settingsWindow.show(pane: pane) },
            openOnboarding: { [weak self] in self?.onboardingWindow.show() }
        )

        if !env.settings.app.hasCompletedOnboarding { onboardingWindow.show() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppEnvironment.shared.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
