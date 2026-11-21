import CoreGraphics

/// E. Energy Pulse — glowing base line, faint energy wave, and pulses that travel outward per keystroke.
/// Pulses reuse the shared keystroke ripples, so this renderer keeps no state of its own.
final class EnergyPulseRenderer: StyleRenderer {
    var hasActiveContent: Bool { false }
    func reset() {}

    func draw(_ rc: RenderContext) {
        let st = rc.state
        let cfg = rc.cfg
        let k = CGFloat(cfg.intensity)
        let drive = min(1, st.drive * k)
        let c = rc.clearance
        let H = rc.bandHalf
        let base = rc.thickness

        let basePath = CGMutablePath()
        let wavePath = CGMutablePath()
        let lenL = rc.length(.left), lenR = rc.length(.right)
        let connected = c < 0.5 && lenL > 1 && lenR > 1

        func wavePoints(_ side: Side) -> [CGPoint] {
            let len = rc.length(side)
            guard len > 1 else { return [] }
            let asym = !cfg.symmetrical && side == .right
            return stride(from: CGFloat(0), through: len, by: 3).map { d in
                let t = min(1, d / len)
                let off: CGFloat = asym ? 1.9 * min(1, d / 40) : 0
                let arg: CGFloat = d * 0.05 - st.phase * 1.2 + off
                let scale: CGFloat = H * 0.5 * drive * (1 - 0.6 * t)
                let y: CGFloat = sin(arg) * scale
                return CGPoint(x: side.sign * (c + d), y: y)
            }
        }
        func addPoints(_ pts: [CGPoint]) {
            guard let f = pts.first else { return }
            wavePath.move(to: f)
            for p in pts.dropFirst() { wavePath.addLine(to: p) }
        }

        if connected {
            basePath.move(to: CGPoint(x: -lenL, y: 0))
            basePath.addLine(to: CGPoint(x: lenR, y: 0))
            addPoints(Array(wavePoints(.left).reversed()) + Array(wavePoints(.right).dropFirst()))
        } else {
            for side in Side.allCases {
                let len = rc.length(side)
                guard len > 1 else { continue }
                basePath.move(to: CGPoint(x: side.sign * c, y: 0))
                basePath.addLine(to: CGPoint(x: side.sign * (c + len), y: 0))
                addPoints(wavePoints(side))
            }
        }

        let rs = 1.6 * CGFloat(cfg.speed)
        rc.glow {
            rc.strokeGradient(basePath, width: base * (1 + drive * 0.8 + st.kick * 1.2),
                              alpha: 0.4 + 0.6 * min(1, drive + st.kick))
            if drive > 0.05 { rc.strokeGradient(wavePath, width: base * 0.55, alpha: 0.55) }

            for r in st.ripples {
                let f = (st.clock - r.birth) * rs
                guard f < 1.05 else { continue }
                let life = max(0, 1 - f)
                for side in Side.allCases {
                    let len = rc.length(side)
                    guard len > 2 else { continue }
                    let w = min(1, r.strength * (side == .left ? r.left : r.right) * k)
                    let head = f * len
                    let tail = max(0, head - (20 + 60 * w))
                    let thick = base * (1.4 + 2.2 * w)
                    for j in 0..<6 {
                        let b = CGFloat(j + 1) / 6
                        let x0 = lerp(tail, head, CGFloat(j) / 6)
                        let x1 = lerp(tail, head, b)
                        let a = side.sign * (c + x0), bb = side.sign * (c + x1)
                        let h = thick * (0.4 + 0.6 * b)
                        rc.fillRounded(CGRect(x: min(a, bb), y: -h / 2, width: abs(bb - a) + 0.5, height: h),
                                       radius: h / 2,
                                       color: rc.color(x1 / len, alpha: b * life * min(1, w + 0.2)))
                    }
                    let hx = side.sign * (c + head)
                    let rad = thick * 0.9
                    rc.ctx.setFillColor(rc.color(head / len, alpha: life))
                    rc.ctx.fillEllipse(in: CGRect(x: hx - rad, y: -rad, width: rad * 2, height: rad * 2))
                }
            }

            if st.kick > 0.05 {
                let w = 10 + 30 * st.kick
                let h = H * 0.6 * st.kick + base
                rc.ctx.setFillColor(rc.color(0, alpha: st.kick * 0.5))
                rc.ctx.fillEllipse(in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
            }
        }
    }
}
