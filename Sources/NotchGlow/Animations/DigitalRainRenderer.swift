import CoreGraphics

/// F. Digital Rain — short digital segments fall through the band; keystrokes spawn them near the center.
final class DigitalRainRenderer: StyleRenderer {
    private struct Drop {
        var side: Side
        var col: Int
        var fall: CGFloat      // distance fallen from the top of the band
        var speed: CGFloat
        var len: CGFloat
    }

    private var drops: [Drop] = []
    private var trickle: CGFloat = 0

    var hasActiveContent: Bool { !drops.isEmpty }
    func reset() { drops.removeAll(); trickle = 0 }

    private func spawn(state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        guard drops.count < 320 else { return }
        let n = max(2, cfg.spikeCount)
        let reach = 0.3 + 0.7 * min(1, state.drive + state.kick)
        let col = min(n - 1, Int(CGFloat(n) * pow(rnd(0, 1), 1.3) * reach))
        let band = geo.height * CGFloat(cfg.spikeHeight)
        let speed = rnd(90, 260) * CGFloat(cfg.speed) * (0.7 + 0.6 * state.drive)
        let len = rnd(6, max(8, band * 0.9))
        if cfg.symmetrical {
            drops.append(Drop(side: .left, col: col, fall: 0, speed: speed, len: len))
            drops.append(Drop(side: .right, col: col, fall: 0, speed: speed, len: len))
        } else {
            let s: Side = Bool.random() ? .left : .right
            drops.append(Drop(side: s, col: col, fall: 0, speed: speed, len: len))
        }
    }

    func keystroke(strength: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        let count = 2 + Int(strength * 4 * CGFloat(cfg.intensity))
        for _ in 0..<count { spawn(state: state, cfg: cfg, geo: geo) }
    }

    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        if state.alpha > 0.3 {
            trickle += dt * state.drive * CGFloat(cfg.intensity) * 16
            while trickle >= 1 { trickle -= 1; spawn(state: state, cfg: cfg, geo: geo) }
        }
        let band = geo.height * CGFloat(cfg.spikeHeight)
        for i in drops.indices { drops[i].fall += drops[i].speed * dt }
        drops.removeAll { $0.fall > band + $0.len }
    }

    func draw(_ rc: RenderContext) {
        guard !drops.isEmpty else { return }
        let n = max(2, rc.cfg.spikeCount)
        let band = rc.bandHalf * 2
        let w = max(1, rc.thickness)
        rc.glow {
            for d in drops {
                let len = rc.length(d.side)
                guard len > 2 else { continue }
                let t = (CGFloat(d.col) + 0.5) / CGFloat(n)
                let x = d.side.sign * (rc.clearance + t * len)
                let progress = clamp(d.fall / (band + d.len), 0, 1)
                var top = band / 2 - d.fall
                top = (top / 2).rounded() * 2                    // quantize: "digital" stepping
                let chunk = max(1.5, d.len / 3 - 1.5)
                for i in 0..<3 {
                    let y = top - CGFloat(i + 1) * chunk - CGFloat(i) * 1.5
                    let a = (1 - 0.3 * CGFloat(i)) * (1 - 0.6 * progress)
                    rc.fillRounded(CGRect(x: x - w / 2, y: y, width: w, height: chunk),
                                   radius: rc.cornerRadius, color: rc.color(t, alpha: a))
                }
            }
        }
    }
}
