import AppKit
import SwiftUI

/// Full customization window. The SwiftUI content is torn down on close so the preview stops rendering.
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show(pane: SettingsPane? = nil) {
        let env = AppEnvironment.shared
        env.permissions.refresh()

        let root = SettingsRootView(settings: env.settings, permissions: env.permissions,
                                    previewEngine: env.previewEngine, initialPane: pane ?? .general)
        let hosting = NSHostingController(rootView: root)

        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 920, height: 740),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.title = "NotchGlow"
            w.titlebarAppearsTransparent = true
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            window = w
        }
        window?.contentViewController = hosting
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in self?.window?.contentViewController = nil }
    }
}

struct OnboardingView: View {
    @ObservedObject var permissions: PermissionsManager
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "keyboard").font(.system(size: 34)).foregroundStyle(.tint)
                VStack(alignment: .leading) {
                    Text("Welcome to NotchGlow").font(.title2.bold())
                    Text("One quick step before the magic starts.").foregroundStyle(.secondary)
                }
            }
            Text("To animate while you type in other apps, macOS requires your permission. Grant either one of the options below in System Settings → Privacy & Security.")
                .font(.callout).fixedSize(horizontal: false, vertical: true)

            PermissionRowsView(permissions: permissions)
            Divider()
            PrivacyNote()

            if permissions.isSufficient {
                Label("All set! If the animation doesn't react, relaunch the app once.", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green).font(.callout)
            }

            HStack {
                Button("Relaunch App") { permissions.relaunch() }
                Spacer()
                Button(permissions.isSufficient ? "Done" : "Not Now", action: onFinish)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}

final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show() {
        let env = AppEnvironment.shared
        env.permissions.refresh()
        let view = OnboardingView(permissions: env.permissions) { [weak self] in
            env.settings.app.hasCompletedOnboarding = true
            self?.window?.close()
        }
        let hosting = NSHostingController(rootView: view)
        if window == nil {
            let w = NSWindow(contentViewController: hosting)
            w.title = "Set Up NotchGlow"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            window = w
        } else {
            window?.contentViewController = hosting
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        AppEnvironment.shared.settings.app.hasCompletedOnboarding = true
    }
}
