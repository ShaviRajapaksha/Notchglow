import CoreGraphics

/// Base class for styles made of per-column levels (needles, LED meter, ...).
/// Keystroke ripples travel outward from the center and lift the columns they pass.
/// Subclasses override `shape` (per-column height pattern) and `draw`.
class LevelFieldRenderer: StyleRenderer {
    var levels: [[CGFloat]] = [[], []]
    var seeds: [[CGFloat]] = [[], []]
    private var seedClock: CGFloat = 0

    var hasActiveContent: Bool { levels.contains { $0.contains { $0 > 0.01 } } }
    func reset() { levels = [[], []]; seeds = [[], []] }

    /// Height multiplier for column i of n (0...1).
    func shape(_ i: Int, _ n: Int) -> CGFloat { 1 }

    private static func randomSeeds(_ n: Int) -> [CGFloat] { (0..<n).map { _ in rnd(0.35, 1) } }

    private func ensureCapacity(_ n: Int) {
        guard levels[0].count != n else { return }
        levels = [[CGFloat](repeating: 0, count: n), [CGFloat](repeating: 0, count: n)]
        seeds = [Self.randomSeeds(n), Self.randomSeeds(n)]
    }

    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        let n = max(2, cfg.spikeCount)
        ensureCapacity(n)
        let speed = CGFloat(cfg.speed)
        let k = CGFloat(cfg.intensity)

        if cfg.randomized {
            seedClock += dt * CGFloat(cfg.frequency) * 11
            if seedClock >= 1 {
                seedClock = 0
                seeds[0] = Self.randomSeeds(n)
                seeds[1] = cfg.symmetrical ? seeds[0] : Self.randomSeeds(n)
            }
        } else {
            for s in 0..<2 {
                let off: CGFloat = (s == 1 && !cfg.symmetrical) ? 1.7 : 0
                for i in 0..<n {
                    let w: CGFloat = abs(sin(CGFloat(i) * 0.9 + off))
                    seeds[s][i] = 0.55 + 0.45 * w
                }
            }
        }

        let drive = state.drive * k
        for s in 0..<2 {
            let side: Side = s == 0 ? .left : .right
            for i in 0..<n {
                let t = (CGFloat(i) + 0.5) / CGFloat(n)
                let seed = seeds[s][i]
                let ripple = state.rippleInfluence(at: t, side: side, speed: speed) * k
                let falloff = 1 - 0.45 * t
                let spec: CGFloat = state.spectrum(at: t) * k
                let ambient: CGFloat = state.hasSpectrum ? 0 : drive * 0.5 * seed
                let kick: CGFloat = ripple * (0.6 + 0.4 * seed)
                let raw: CGFloat = (ambient + kick + spec) * falloff * shape(i, n)
                let target: CGFloat = min(1, raw)
                let cur = levels[s][i]
                levels[s][i] = cur + (target - cur) * smoothing((target > cur ? 30 : 10) * speed, dt)
            }
        }
    }

    func draw(_ rc: RenderContext) {}
}
