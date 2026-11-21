import CoreGraphics

/// Heartbeat — one continuous line; every keystroke sends an ECG-style beat (P, Q, R, S, T waves) outward.
/// Beats reuse the shared keystroke ripples, so this renderer keeps no state of its own.
final class HeartbeatRenderer: StyleRenderer {
    var hasActiveContent: Bool { false }
    func reset() {}

    private static let parts: [(mu: CGFloat, w: CGFloat, a: CGFloat)] = [
        (-0.55, 0.12, 0.15),    // P
        (-0.14, 0.045, -0.22),  // Q
        (0.0, 0.055, 1.0),      // R (the tall spike)
        (0.12, 0.05, -0.38),    // S
        (0.55, 0.14, 0.28)      // T
    ]

    private func complex(_ u: CGFloat) -> CGFloat {
        var v: CGFloat = 0
        for p in Self.parts {
            let d = u - p.mu
            v += p.a * exp(-d * d / (2 * p.w * p.w))
        }
        return v
    }

    func draw(_ rc: RenderContext) {
        let st = rc.state
        let k = CGFloat(rc.cfg.intensity)
        let speed = CGFloat(rc.cfg.speed)
        let H = rc.bandHalf

        func points(_ side: Side) -> [CGPoint] {
            let len = rc.length(side)
            guard len > 2 else { return [] }
            return stride(from: CGFloat(0), through: len, by: 2).map { d in
                var y: CGFloat = 0
                for r in st.ripples {
                    let f = (st.clock - r.birth) * 1.6 * speed
                    let w = r.strength * (side == .left ? r.left : r.right) * k
                    let half = 38 + 30 * min(1, w)
                    let u = (d - f * len) / half
                    if abs(u) < 1.3 { y += complex(u) * w * max(0, 1 - f * 0.5) }
                }
                let tremorArg: CGFloat = d * 0.2 - st.phase * 3
                let tremorAmp: CGFloat = 0.04 * min(1, st.drive * k)
                y += sin(tremorArg) * tremorAmp                       // faint resting tremor
                let clamped: CGFloat = clamp(y, -1.2, 1.2)
                return CGPoint(x: side.sign * (rc.clearance + d), y: clamped * H * 0.95)
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
            add(Array(left.reversed()) + Array(right.dropFirst()))
        } else {
            add(left); add(right)
        }
        rc.glow { rc.strokeGradient(path, width: rc.thickness) }
    }
}
