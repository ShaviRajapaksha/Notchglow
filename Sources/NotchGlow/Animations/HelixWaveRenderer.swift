import CoreGraphics

/// Helix Wave: two waveforms twist around each other like a double helix, joined by fine "rungs".
final class HelixWaveRenderer: StyleRenderer {
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
        let asym = !rc.cfg.symmetrical
        let state = rc.state
        let amp = self.amp

        /// Height of one strand at distance d from the gap. `turn` is 0 for the first strand and pi for the second.
        func height(_ side: Side, _ d: CGFloat, _ len: CGFloat, turn: CGFloat) -> CGFloat {
            let t: CGFloat = min(1, d / len)
            let env: CGFloat = pow(1 - t, 0.45)
            let ripple: CGFloat = state.rippleInfluence(at: t, side: side, speed: speed) * k
            let level: CGFloat = min(1.1, amp + ripple * 0.8)
            let a: CGFloat = H * min(1, 0.12 + 0.88 * level) * env
            var ph: CGFloat = phase
            if asym && side == .right { ph += (phase * 0.13 + 2.1) * min(1, d / 40) }
            let angle: CGFloat = d * 0.05 - ph * 1.1 + turn
            return a * sin(angle)
        }

        func points(_ side: Side, turn: CGFloat) -> [CGPoint] {
            let len = rc.length(side)
            guard len > 2 else { return [] }
            return stride(from: CGFloat(0), through: len, by: 3).map { d in
                CGPoint(x: side.sign * (rc.clearance + d), y: height(side, d, len, turn: turn))
            }
        }

        func strandPath(turn: CGFloat) -> CGPath {
            let left = points(.left, turn: turn)
            let right = points(.right, turn: turn)
            let path = CGMutablePath()
            func add(_ pts: [CGPoint]) {
                guard let first = pts.first else { return }
                path.move(to: first)
                for p in pts.dropFirst() { path.addLine(to: p) }
            }
            if rc.clearance < 0.5 && !left.isEmpty && !right.isEmpty {
                add(Array(left.reversed()) + Array(right.dropFirst()))       // one continuous strand
            } else {
                add(left)
                add(right)
            }
            return path
        }

        let strandA = strandPath(turn: 0)
        let strandB = strandPath(turn: CGFloat.pi)

        rc.glow {
            rc.strokeGradient(strandB, width: rc.thickness, alpha: 0.65)
            rc.strokeGradient(strandA, width: rc.thickness)

            // Rungs between the two strands.
            rc.ctx.setLineWidth(max(0.8, rc.thickness * 0.4))
            rc.ctx.setLineCap(.round)
            for side in Side.allCases {
                let len = rc.length(side)
                guard len > 2 else { continue }
                var d: CGFloat = 4
                while d < len {
                    let ya = height(side, d, len, turn: 0)
                    let yb = height(side, d, len, turn: CGFloat.pi)
                    let spread = abs(ya - yb)
                    if spread > 2 {
                        let alpha: CGFloat = min(0.55, spread / (H * 2) * 0.9 + 0.1)
                        rc.ctx.setStrokeColor(rc.color(d / len, alpha: alpha))
                        let x = side.sign * (rc.clearance + d)
                        rc.ctx.move(to: CGPoint(x: x, y: ya))
                        rc.ctx.addLine(to: CGPoint(x: x, y: yb))
                        rc.ctx.strokePath()
                    }
                    d += 9
                }
            }
        }
    }
}
