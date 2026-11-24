import AppKit
import SwiftUI
import Combine

/// NSStatusItem + compact popover (click) + quick menu (right-click or control-click).
final class MenuBarManager: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let settings: SettingsManager
    private let permissions: PermissionsManager
    private let openSettings: (SettingsPane?) -> Void
    private var bag = Set<AnyCancellable>()

    init(settings: SettingsManager,
         permissions: PermissionsManager,
         openSettings: @escaping (SettingsPane?) -> Void,
         openOnboarding: @escaping () -> Void) {
        self.settings = settings
        self.permissions = permissions
        self.openSettings = openSettings
        super.init()

        if let button = statusItem.button {
            button.image = StatusIcon.image()
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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

    @objc private func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        let isSecondaryClick = event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) ?? false)
        if isSecondaryClick {
            showQuickMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: Any?) {
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

    private func showQuickMenu() {
        popover.performClose(nil)
        let menu = NSMenu()

        let toggleTitle = settings.app.isEnabled ? "Turn NotchGlow Off" : "Turn NotchGlow On"
        let toggle = NSMenuItem(title: toggleTitle, action: #selector(menuToggleEnabled), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        let customize = NSMenuItem(title: "Customize\u{2026}", action: #selector(menuOpenSettings), keyEquivalent: ",")
        customize.target = self
        menu.addItem(customize)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit NotchGlow", action: #selector(menuQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        // Attach the menu only for this click, so left-clicks keep opening the popover.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func menuToggleEnabled() { settings.app.isEnabled.toggle() }
    @objc private func menuOpenSettings() { openSettings(nil) }
    @objc private func menuQuit() { NSApp.terminate(nil) }
}
