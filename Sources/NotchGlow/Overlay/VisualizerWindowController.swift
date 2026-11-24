import AppKit

/// Transparent, click-through, non-activating panel.
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    // Allow the window to extend above the visible frame (over the menu bar).
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

/// Creates/updates one overlay panel per target display, and hides them over full-screen apps when asked to.
final class VisualizerWindowController {
    private struct Entry { let panel: OverlayPanel; let view: VisualizerView }

    private var entries: [CGDirectDisplayID: Entry] = [:]
    private let engine: VisualizerEngine
    private let settings: SettingsManager
    private var lastActiveID: CGDirectDisplayID?
    private var watchTimer: Timer?
    private var pendingRefreshes: [DispatchWorkItem] = []
    private var observers: [NSObjectProtocol] = []

    init(engine: VisualizerEngine, settings: SettingsManager) {
        self.engine = engine
        self.settings = settings

        // Entering / leaving a full-screen Space, or switching apps, may change whether we should be visible.
        let workspace = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.activeSpaceDidChangeNotification,
            NSWorkspace.didActivateApplicationNotification
        ]
        for name in names {
            let token = workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.scheduleVisibilityRefresh()
            }
            observers.append(token)
        }
    }

    deinit {
        let workspace = NSWorkspace.shared.notificationCenter
        observers.forEach { workspace.removeObserver($0) }
        watchTimer?.invalidate()
    }

    func rebuild() {
        let app = settings.app
        guard app.isEnabled else {
            removeAll()
            updateWatchTimer()
            return
        }

        let screens = DisplayManager.targetScreens(settings: app)
        let wanted = Set(screens.compactMap { DisplayManager.displayID($0) })
        for id in Array(entries.keys) where !wanted.contains(id) { remove(id) }

        let size = Geometry.contentSize(settings.config)
        var maxNotch: CGFloat = 0
        for screen in screens {
            guard let id = DisplayManager.displayID(screen) else { continue }
            let entry = entries[id] ?? makeEntry(id)
            maxNotch = max(maxNotch, DisplayManager.notchHalfWidth(for: screen))
            let frame = DisplayManager.overlayFrame(for: screen, size: size,
                                                    verticalOffset: CGFloat(app.verticalOffset))
            let level = Self.windowLevel(for: app.layer)
            if entry.panel.level != level { entry.panel.level = level }
            if entry.panel.frame != frame { entry.panel.setFrame(frame, display: false) }
        }
        engine.externalClearance = app.avoidNotch ? maxNotch + 6 : 0

        applyVisibility()
        updateWatchTimer()
    }

    /// Shows or hides each panel depending on the "Show over full-screen apps" setting.
    func applyVisibility() {
        let hideInFullScreen = !settings.app.showInFullScreen
        for (id, entry) in entries {
            let hidden = hideInFullScreen && FullScreenDetector.isFullScreen(displayID: id)
            if hidden {
                if entry.panel.isVisible { entry.panel.orderOut(nil) }
            } else if !entry.panel.isVisible {
                entry.panel.orderFrontRegardless()
            }
        }
    }

    /// For "display under the mouse": follow the mouse between screens.
    func refreshActiveDisplayIfNeeded() {
        guard settings.app.displayMode == .activeDisplay,
              let screen = DisplayManager.screenUnderMouse(),
              let id = DisplayManager.displayID(screen), id != lastActiveID else { return }
        lastActiveID = id
        rebuild()
    }

    // MARK: Full-screen watching

    /// Re-checks shortly after a Space or app change, and again once the full-screen animation has finished.
    private func scheduleVisibilityRefresh() {
        guard settings.app.isEnabled, !settings.app.showInFullScreen else { return }
        pendingRefreshes.forEach { $0.cancel() }
        pendingRefreshes.removeAll()
        for delay in [0.2, 1.0] {
            let work = DispatchWorkItem { [weak self] in self?.applyVisibility() }
            pendingRefreshes.append(work)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }

    /// A slow safety-net timer that only exists while "Show over full-screen apps" is turned off.
    private func updateWatchTimer() {
        let needed = settings.app.isEnabled && !settings.app.showInFullScreen && !entries.isEmpty
        if needed && watchTimer == nil {
            let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in self?.applyVisibility() }
            timer.tolerance = 0.5
            RunLoop.main.add(timer, forMode: .common)
            watchTimer = timer
        } else if !needed {
            watchTimer?.invalidate()
            watchTimer = nil
        }
    }

    // MARK: Windows

    /// Above: higher than the menu bar background, its icons and menus (drawn on top of the blur).
    /// Beneath: just below the menu bar window, so the menu bar's blur/background is drawn over the effect.
    private static func windowLevel(for layer: OverlayLayer) -> NSWindow.Level {
        switch layer {
        case .aboveMenuBar:
            return NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)) + 1)
        case .beneathMenuBar:
            return NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
        }
    }

    private func makeEntry(_ id: CGDirectDisplayID) -> Entry {
        let panel = OverlayPanel(contentRect: .zero,
                                 styleMask: [.borderless, .nonactivatingPanel],
                                 backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = Self.windowLevel(for: settings.app.layer)
        panel.ignoresMouseEvents = true                // never blocks clicks
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let view = VisualizerView(engine: engine)
        panel.contentView = view
        let entry = Entry(panel: panel, view: view)
        entries[id] = entry
        return entry
    }

    private func remove(_ id: CGDirectDisplayID) {
        guard let e = entries.removeValue(forKey: id) else { return }
        e.panel.orderOut(nil)
        e.panel.contentView = nil
    }

    private func removeAll() {
        for id in Array(entries.keys) { remove(id) }
    }
}
