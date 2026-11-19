import CoreGraphics

/// G. Minimal Glow — one subtle glowing line with tapered ends; a small bead travels out per keystroke.
final class MinimalGlowRenderer: StyleRenderer {
    var hasActiveContent: Bool { false }
    func reset() {}

    func draw(_ rc: RenderContext) {
        let st = rc.state
        let k = CGFloat(rc.cfg.intensity)
        let drive = min(1, st.drive * k)
        let path = CGMutablePath()
        for side in Side.allCases {
            let len = rc.length(side)
            guard len > 1 else { continue }
            path.move(to: CGPoint(x: side.sign * rc.clearance, y: 0))
            path.addLine(to: CGPoint(x: side.sign * (rc.clearance + len), y: 0))
        }
        guard !path.isEmpty, let g = rc.xGradient() else { return }

        let width = rc.thickness * (1 + 0.5 * drive + 0.9 * st.kick * k)
        let alpha = 0.45 + 0.55 * min(1, drive + st.kick * 0.8)
        let rs = 1.6 * CGFloat(rc.cfg.speed)
        let maskColors: [CGFloat] = [1, 0, 1, 1, 1, 1, 1, 0]       // (gray, alpha) pairs
        let maskLocs: [CGFloat] = [0, 0.35, 0.65, 1]

        rc.glow {
            rc.strokeGradient(path, width: width, alpha: alpha)

            // Taper both ends of the line.
            if let mask = CGGradient(colorSpace: CGColorSpaceCreateDeviceGray(),
                                     colorComponents: maskColors, locations: maskLocs, count: 4) {
                rc.ctx.saveGState()
                rc.ctx.setBlendMode(.destinationIn)
                rc.ctx.drawLinearGradient(mask, start: g.start, end: g.end,
                                          options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                rc.ctx.restoreGState()
            }

            // Keystroke beads.
            for r in st.ripples {
                let f = (st.clock - r.birth) * rs
                guard f < 1 else { continue }
                for side in Side.allCases {
                    let len = rc.length(side)
                    guard len > 2 else { continue }
                    let w = min(1, r.strength * (side == .left ? r.left : r.right) * k)
                    let x = side.sign * (rc.clearance + f * len)
                    let rad = rc.thickness * (0.9 + 0.8 * w)
                    rc.ctx.setFillColor(rc.color(f, alpha: (1 - f) * min(1, w + 0.3)))
                    rc.ctx.fillEllipse(in: CGRect(x: x - rad, y: -rad, width: rad * 2, height: rad * 2))
                }
            }
        }
    }
}
