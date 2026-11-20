import CoreGraphics

/// Lightning — a crackling jagged line that re-randomizes quickly; the previous shape lingers as an afterimage.
final class LightningRenderer: StyleRenderer {
    private let count = 160                       // points per side (6 pt apart)
    private var seeds = [[CGFloat]](repeating: [], count: 2)
    private var previous = [[CGFloat]](repeating: [], count: 2)
    private var refresh: CGFloat = 0
    private var amp: CGFloat = 0

    var hasActiveContent: Bool { amp > 0.01 }
    func reset() { seeds = [[], []]; previous = [[], []]; amp = 0 }

    private func roll() -> [CGFloat] { (0..<count).map { _ in rnd(-1, 1) } }
        private func fixed() -> [CGFloat] {
        var out: [CGFloat] = []
        for i in 0..<count {
            let sign: CGFloat = (i % 2 == 0) ? 1 : -1
            let wobble: CGFloat = abs(sin(CGFloat(i) * 1.3))
            out.append(sign * (0.6 + 0.4 * wobble))
        }
        return out
    }
    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        let target = min(1.1, state.drive * CGFloat(cfg.intensity))
        amp += (target - amp) * smoothing(target > amp ? 18 : 6, dt)

        if seeds[0].isEmpty { seeds = [roll(), roll()]; previous = seeds }
        refresh += dt * CGFloat(cfg.frequency) * 14
        if refresh >= 1 {
            refresh = 0
            previous = seeds
            let a = cfg.randomized ? roll() : fixed()
            let b = cfg.symmetrical ? a : (cfg.randomized ? roll() : Array(fixed().reversed()))
            seeds = [a, b]
        }
    }

    private func path(_ rc: RenderContext, _ sd: [[CGFloat]]) -> CGPath {
        let H = rc.bandHalf
        let k = CGFloat(rc.cfg.intensity)
        let speed = CGFloat(rc.cfg.speed)

        func points(_ side: Side) -> [CGPoint] {
            let len = rc.length(side)
            guard len > 2 else { return [] }
            let s = sd[side == .left ? 0 : 1]
            return stride(from: CGFloat(0), through: len, by: 6).enumerated().map { (i, d) in
                let t = min(1, d / len)
                let env = pow(1 - t, 0.4)
                let ripple = rc.state.rippleInfluence(at: t, side: side, speed: speed) * k
                let a = H * min(1, 0.06 + 0.94 * min(1.1, amp * 0.6 + ripple * 0.9)) * env
                return CGPoint(x: side.sign * (rc.clearance + d), y: a * s[min(i, s.count - 1)])
            }
        }

        let left = points(.left), right = points(.right)
        let p = CGMutablePath()
        func add(_ pts: [CGPoint]) {
            guard let f = pts.first else { return }
            p.move(to: f)
            for q in pts.dropFirst() { p.addLine(to: q) }
        }
        if rc.clearance < 0.5 && !left.isEmpty && !right.isEmpty {
            add(Array(left.reversed()) + Array(right.dropFirst()))
        } else {
            add(left); add(right)
        }
        return p
    }

    func draw(_ rc: RenderContext) {
        guard !seeds[0].isEmpty else { return }
        let main = path(rc, seeds)
        let ghost = path(rc, previous)
        rc.glow {
            rc.strokeGradient(ghost, width: rc.thickness * 0.6, alpha: 0.3)
            rc.strokeGradient(main, width: rc.thickness)
        }
    }
}
