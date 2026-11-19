import AppKit
import SwiftUI
import Combine

/// NSStatusItem + compact popover.
final class MenuBarManager: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let settings: SettingsManager
    private let permissions: PermissionsManager
    private var bag = Set<AnyCancellable>()

    init(settings: SettingsManager,
         permissions: PermissionsManager,
         openSettings: @escaping (SettingsPane?) -> Void,
         openOnboarding: @escaping () -> Void) {
        self.settings = settings
        self.permissions = permissions
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "waveform.path", accessibilityDescription: "NotchGlow")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        let root = MenuPopoverView(
            settings: settings,
            permissions: permissions,
            openSettings: { [weak self] pane in
                self?.popover.performClose(nil)
                openSettings(pane)
            },
            openOnboarding: { [weak self] in
                self?.popover.performClose(nil)
                openOnboarding()
            },
            quit: { NSApp.terminate(nil) }
        )
        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
        popover.behavior = .transient
        popover.animates = true

        settings.$app
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in self?.statusItem.button?.appearsDisabled = !app.isEnabled }
            .store(in: &bag)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            permissions.refresh()
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
