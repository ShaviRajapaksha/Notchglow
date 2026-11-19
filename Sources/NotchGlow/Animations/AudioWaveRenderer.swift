import CoreGraphics

/// B. Audio Wave — smooth traveling waveform, amplitude follows typing frequency.
final class AudioWaveRenderer: StyleRenderer {
    private var amp: CGFloat = 0

    var hasActiveContent: Bool { amp > 0.01 }
    func reset() { amp = 0 }

    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        let target = min(1.1, state.drive * CGFloat(cfg.intensity))
        amp += (target - amp) * smoothing(target > amp ? 16 : 6, dt)
    }

    func draw(_ rc: RenderContext) {
        let H = rc.bandHalf
        let phase = rc.state.phase
        let k = CGFloat(rc.cfg.intensity)
        let speed = CGFloat(rc.cfg.speed)
        let mix: CGFloat = rc.cfg.randomized ? 0.35 + 0.15 * sin(phase * 0.4) : 0.4
        let path = CGMutablePath()

        for side in Side.allCases {
            let len = rc.length(side)
            guard len > 2 else { continue }
            let ph = (side == .left || rc.cfg.symmetrical) ? phase : phase * 1.13 + 2.1
            var d: CGFloat = 0
            var first = true
            while d <= len + 0.01 {
                let t = min(1, d / len)
                let env = pow(1 - t, 0.55)
                let ripple = rc.state.rippleInfluence(at: t, side: side, speed: speed) * k
                let a = H * min(1, 0.10 + 0.9 * min(1.1, amp + ripple * 0.8)) * env
                let w = (1 - mix) * sin(d * 0.045 - ph) + mix * sin(d * 0.11 - ph * 1.37 + 1.3)
                let p = CGPoint(x: side.sign * (rc.clearance + d), y: a * w)
                if first { path.move(to: p); first = false } else { path.addLine(to: p) }
                d += 3
            }
        }
        var flip = CGAffineTransform(scaleX: 1, y: -1)
        let mirrored = path.copy(using: &flip)
        rc.glow {
            rc.strokeGradient(path, width: rc.thickness)
            if let m = mirrored { rc.strokeGradient(m, width: rc.thickness * 0.7, alpha: 0.4) }
        }
    }
}
