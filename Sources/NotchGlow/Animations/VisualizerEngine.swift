import AppKit
import QuartzCore

/// Owns the typing state + renderer and drives a timer ONLY while something is animating.
/// One engine drives the screen overlay, another drives the settings preview.
final class VisualizerEngine {
    let state = VisualizerState()
    private let renderer = VisualizerRenderer()
    private let views = NSHashTable<VisualizerView>.weakObjects()

    private var timer: Timer?
    private var currentInterval: TimeInterval = 0
    private var lastTick: CFTimeInterval = 0

    var config: AnimationConfiguration {
        didSet {
            guard config != oldValue else { return }
            if config.style != oldValue.style { renderer.reset() }
            views.allObjects.forEach { $0.configurationChanged() }
            wake()
        }
    }

    /// Extra center clearance (e.g. the camera notch), in points from the center.
    var externalClearance: CGFloat = 0 {
        didSet { if oldValue != externalClearance { wake() } }
    }

    var isEnabled = true {
        didSet {
            guard oldValue != isEnabled else { return }
            if isEnabled {
                wake()
            } else {
                stopTimer()
                state.reset()
                renderer.reset()
                redrawViews()
            }
        }
    }

    init(config: AnimationConfiguration) { self.config = config }

    private var effectiveClearance: CGFloat {
        config.connectSides ? 0 : max(config.clearance, externalClearance)
    }
    private var hasViews: Bool { views.count > 0 }

    // MARK: Views
    func attach(_ view: VisualizerView) {
        views.add(view)
        view.configurationChanged()
        view.needsDisplay = true
        wake()
    }

    func detach(_ view: VisualizerView) {
        views.remove(view)
        if !hasViews { stopTimer() }
    }

    func render(into ctx: CGContext, size: CGSize) {
        renderer.render(into: ctx, size: size, state: state, cfg: config, clearance: effectiveClearance)
    }

    // MARK: Input
    func registerKeystroke() {
        guard isEnabled, hasViews else { return }
        let geo = Geometry.make(config, clearance: effectiveClearance)
        let strength = state.registerKey(cfg: config)
        renderer.keystroke(strength: strength, state: state, cfg: config, geo: geo)
        wake()
    }

    func registerAudio(level: Float, bands: [Float]) {
        guard isEnabled, hasViews else { return }
        let geo = Geometry.make(config, clearance: effectiveClearance)
        let beat = state.feedAudio(level: CGFloat(level), bands: bands.map { CGFloat($0) }, cfg: config)
        if let strength = beat {
            renderer.keystroke(strength: strength, state: state, cfg: config, geo: geo)   // beats act like keystrokes
        }
        wake()
    }

    // MARK: Loop
    private func wake() {
        guard isEnabled, hasViews else { return }
        if timer == nil {
            lastTick = CACurrentMediaTime()
            startTimer(1.0 / 60.0)
        }
    }

    private func startTimer(_ interval: TimeInterval) {
        timer?.invalidate()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        t.tolerance = interval * 0.05
        RunLoop.main.add(t, forMode: .common)   // keeps running while sliders are dragged
        timer = t
        currentInterval = interval
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = CGFloat(min(max(now - lastTick, 0.001), 0.05))
        lastTick = now

        let geo = Geometry.make(config, clearance: effectiveClearance)
        state.update(dt: dt, cfg: config)
        renderer.update(dt: dt, state: state, cfg: config, geo: geo)
        redrawViews()

        let busy = state.isBusy || renderer.hasActiveContent
        if !busy && !config.idleAnimation {
            stopTimer()          // nothing animating: zero CPU
            return
        }
        // Idle animation runs at a reduced frame rate.
        let wanted: TimeInterval = (config.idleAnimation && state.isQuiescent(config)) ? 1.0 / 30.0 : 1.0 / 60.0
        if abs(wanted - currentInterval) > 0.001 { startTimer(wanted) }
    }

    private func redrawViews() {
        for v in views.allObjects { v.needsDisplay = true }
    }
}
