import CoreGraphics

/// C. Equalizer — bars react independently; each keystroke kicks a random subset.
final class EqualizerRenderer: StyleRenderer {
    private var levels = [[CGFloat]](repeating: [], count: 2)
    private var targets = [[CGFloat]](repeating: [], count: 2)
    private var peaks = [[CGFloat]](repeating: [], count: 2)
    private var ambient = [[CGFloat]](repeating: [], count: 2)
    private var ambientClock: CGFloat = 0

    var hasActiveContent: Bool { levels.contains { $0.contains { $0 > 0.01 } } }

    func reset() {
        levels = [[], []]; targets = [[], []]; peaks = [[], []]; ambient = [[], []]
    }

    private func ensure(_ n: Int) {
        guard levels[0].count != n else { return }
        let zeros = [CGFloat](repeating: 0, count: n)
        levels = [zeros, zeros]; targets = [zeros, zeros]; peaks = [zeros, zeros]
        ambient = [zeros.map { _ in rnd(0.1, 1) }, zeros.map { _ in rnd(0.1, 1) }]
    }

    private func pick(_ n: Int) -> Int { min(n - 1, Int(CGFloat(n) * pow(rnd(0, 1), 1.5))) }

    func keystroke(strength: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        let n = max(2, cfg.spikeCount)
        ensure(n)
        let picks = max(1, Int((CGFloat(n) * (0.22 + 0.4 * strength)).rounded()))
        for _ in 0..<picks {
            let i = pick(n)
            let v = strength * rnd(0.55, 1.0) * CGFloat(cfg.intensity)
            targets[0][i] = max(targets[0][i], v)
            if cfg.symmetrical {
                targets[1][i] = targets[0][i]
            } else {
                let j = pick(n)
                targets[1][j] = max(targets[1][j], strength * rnd(0.55, 1.0) * CGFloat(cfg.intensity))
            }
        }
    }

    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        let n = max(2, cfg.spikeCount)
        ensure(n)
        let speed = CGFloat(cfg.speed)
        let decay = 2.4 / max(0.3, CGFloat(cfg.animationDuration) * 0.6)
        ambientClock += dt * CGFloat(cfg.frequency) * 12
        let reroll = ambientClock >= 1
        if reroll { ambientClock = 0 }

        if cfg.randomized {
            if reroll {
                for i in 0..<n { ambient[0][i] = rnd(0.1, 1) }
                if cfg.symmetrical { ambient[1] = ambient[0] } else { for i in 0..<n { ambient[1][i] = rnd(0.1, 1) } }
            }
        } else {
            for s in 0..<2 { for i in 0..<n { ambient[s][i] = 0.55 + 0.45 * abs(sin(CGFloat(i) * 0.6 + CGFloat(s) * 1.3)) } }
        }

        let drive = state.drive * CGFloat(cfg.intensity)
        for s in 0..<2 {
            for i in 0..<n {
                targets[s][i] *= exp(-dt * decay)
                let t = (CGFloat(i) + 0.5) / CGFloat(n)
                let target = min(1, max(targets[s][i], drive * 0.45 * ambient[s][i])) * (1 - 0.5 * t)
                let cur = levels[s][i]
                levels[s][i] = cur + (target - cur) * smoothing((target > cur ? 38 : 11) * speed, dt)
                peaks[s][i] = max(levels[s][i], peaks[s][i] - dt * 0.7 * speed)
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
                let w = max(1, min(rc.thickness * 1.6, pitch * 0.85))
                for i in 0..<n {
                    let t = (CGFloat(i) + 0.5) / CGFloat(n)
                    let x = side.sign * (rc.clearance + (CGFloat(i) + 0.5) * pitch)
                    let h = max(w, levels[s][i] * maxH)
                    let col = rc.color(t)
                    rc.fillRounded(CGRect(x: x - w / 2, y: -h / 2, width: w, height: h),
                                   radius: rc.cornerRadius, color: col)
                    // peak-hold caps
                    if peaks[s][i] > levels[s][i] + 0.04 {
                        let y = peaks[s][i] * maxH / 2 + 2.5
                        let cap = max(1.5, w * 0.5)
                        rc.fillRounded(CGRect(x: x - w / 2, y: y, width: w, height: cap), radius: rc.cornerRadius, color: col)
                        rc.fillRounded(CGRect(x: x - w / 2, y: -y - cap, width: w, height: cap), radius: rc.cornerRadius, color: col)
                    }
                }
            }
        }
    }
}
