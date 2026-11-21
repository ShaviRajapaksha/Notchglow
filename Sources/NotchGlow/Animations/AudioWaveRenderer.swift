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
        let asym = !rc.cfg.symmetrical

        func points(_ side: Side) -> [CGPoint] {
            let len = rc.length(side)
            guard len > 2 else { return [] }
            return stride(from: CGFloat(0), through: len, by: 3).map { d in
                let t = min(1, d / len)
                let env = pow(1 - t, 0.55)
                let ripple = rc.state.rippleInfluence(at: t, side: side, speed: speed) * k
                let level: CGFloat = min(1.1, amp + ripple * 0.8)
                let a: CGFloat = H * min(1, 0.10 + 0.9 * level) * env
                var ph: CGFloat = phase
                if asym && side == .right { ph += (phase * 0.13 + 2.1) * min(1, d / 40) }
                let w1: CGFloat = sin(d * 0.045 - ph)
                let w2: CGFloat = sin(d * 0.11 - ph * 1.37 + 1.3)
                let w: CGFloat = (1 - mix) * w1 + mix * w2
                return CGPoint(x: side.sign * (rc.clearance + d), y: a * w)
            }
        }

        let left = points(.left), right = points(.right)
        let path = CGMutablePath()
        func add(_ pts: [CGPoint]) {
            guard let f = pts.first else { return }
            path.move(to: f)
            for p in pts.dropFirst() { path.addLine(to: p) }
        }
        if rc.clearance < 0.5 && !left.isEmpty && !right.isEmpty {
            add(Array(left.reversed()) + Array(right.dropFirst()))       // one continuous waveform
        } else {
            add(left); add(right)
        }

        var flip = CGAffineTransform(scaleX: 1, y: -1)
        let mirrored = path.copy(using: &flip)
        rc.glow {
            rc.strokeGradient(path, width: rc.thickness)
            if let m = mirrored { rc.strokeGradient(m, width: rc.thickness * 0.7, alpha: 0.4) }
        }
    }
}
