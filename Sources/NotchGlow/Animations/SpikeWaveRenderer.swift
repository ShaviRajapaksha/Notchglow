import CoreGraphics

/// A. Spike Wave — vertical spikes; keystroke ripples travel from the center outward.
final class SpikeWaveRenderer: StyleRenderer {
    private var levels: [[CGFloat]] = [[], []]
    private var seeds: [[CGFloat]] = [[], []]
    private var seedClock: CGFloat = 0

    var hasActiveContent: Bool { levels.contains { $0.contains { $0 > 0.01 } } }
    func reset() { levels = [[], []]; seeds = [[], []] }

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
                let falloff = 1 - 0.5 * t
                let spec: CGFloat = state.spectrum(at: t) * k
                let ambient: CGFloat = state.hasSpectrum ? 0 : drive * 0.5 * seed
                let kick: CGFloat = ripple * (0.6 + 0.4 * seed)
                let target: CGFloat = min(1, (ambient + kick + spec) * falloff)
                let cur = levels[s][i]
                levels[s][i] = cur + (target - cur) * smoothing((target > cur ? 30 : 10) * speed, dt)
            }
        }
    }

    func draw(_ rc: RenderContext) {
        let n = levels[0].count
        guard n > 0 else { return }
        let maxH = rc.geo.height * CGFloat(rc.cfg.spikeHeight)
        rc.glow {
            for (s, side) in Side.allCases.enumerated() {
                let len = rc.length(side)
                guard len > 2 else { continue }
                let pitch = len / CGFloat(n)
                let w = max(1, min(rc.thickness, pitch * 0.9))
                for i in 0..<n {
                    let t = (CGFloat(i) + 0.5) / CGFloat(n)
                    let h = max(w, levels[s][i] * maxH)
                    let x = side.sign * (rc.clearance + (CGFloat(i) + 0.5) * pitch)
                    rc.fillRounded(CGRect(x: x - w / 2, y: -h / 2, width: w, height: h),
                                   radius: rc.cornerRadius, color: rc.color(t))
                }
            }
        }
    }
}
