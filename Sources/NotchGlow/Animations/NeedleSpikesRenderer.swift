import CoreGraphics

/// Needle Spikes — razor-sharp diamond needles in a tall / short / medium rhythm.
final class NeedleSpikesRenderer: LevelFieldRenderer {
    override func shape(_ i: Int, _ n: Int) -> CGFloat {
        switch i % 3 {
        case 0: return 1.0
        case 1: return 0.5
        default: return 0.75
        }
    }

    override func draw(_ rc: RenderContext) {
        let n = levels[0].count
        guard n > 0 else { return }
        let maxH = rc.geo.height * CGFloat(rc.cfg.spikeHeight)
        rc.glow {
            for (s, side) in Side.allCases.enumerated() {
                let len = rc.length(side)
                guard len > 2 else { continue }
                let pitch = len / CGFloat(n)
                let w = max(1.5, min(pitch * 0.85, rc.thickness * 2.4))
                for i in 0..<n {
                    let t = (CGFloat(i) + 0.5) / CGFloat(n)
                    let h = max(w * 0.8, levels[s][i] * maxH)
                    let x = side.sign * (rc.clearance + (CGFloat(i) + 0.5) * pitch)
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: x - w / 2, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h / 2))
                    p.addLine(to: CGPoint(x: x + w / 2, y: 0))
                    p.addLine(to: CGPoint(x: x, y: -h / 2))
                    p.closeSubpath()
                    rc.ctx.addPath(p)
                    rc.ctx.setFillColor(rc.color(t))
                    rc.ctx.fillPath()
                }
            }
        }
    }
}
