import AppKit

/// Transparent, click-through, non-activating panel.
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    // Allow the window to extend above the visible frame (over the menu bar).
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

/// Creates/updates one overlay panel per target display.
final class VisualizerWindowController {
    private struct Entry { let panel: OverlayPanel; let view: VisualizerView }

    private var entries: [CGDirectDisplayID: Entry] = [:]
    private let engine: VisualizerEngine
    private let settings: SettingsManager
    private var lastActiveID: CGDirectDisplayID?

    init(engine: VisualizerEngine, settings: SettingsManager) {
        self.engine = engine
        self.settings = settings
    }

    func rebuild() {
        let app = settings.app
        guard app.isEnabled else { removeAll(); return }

        let screens = DisplayManager.targetScreens(mode: app.displayMode)
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
            if entry.panel.frame != frame { entry.panel.setFrame(frame, display: false) }
            if !entry.panel.isVisible { entry.panel.orderFrontRegardless() }
        }
        engine.externalClearance = app.avoidNotch ? maxNotch + 6 : 0
    }

    /// For "display under the mouse": follow the mouse between screens.
    func refreshActiveDisplayIfNeeded() {
        guard settings.app.displayMode == .activeDisplay,
              let screen = DisplayManager.screenUnderMouse(),
              let id = DisplayManager.displayID(screen), id != lastActiveID else { return }
        lastActiveID = id
        rebuild()
    }

    private func makeEntry(_ id: CGDirectDisplayID) -> Entry {
        let panel = OverlayPanel(contentRect: .zero,
                                 styleMask: [.borderless, .nonactivatingPanel],
                                 backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar                       // above the menu bar
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
