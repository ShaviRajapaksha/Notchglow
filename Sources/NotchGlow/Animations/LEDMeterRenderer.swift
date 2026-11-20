import CoreGraphics

/// LED Meter — columns of small lit dots (like a VU meter), mirrored above and below the center line.
final class LEDMeterRenderer: LevelFieldRenderer {
    override func draw(_ rc: RenderContext) {
        let n = levels[0].count
        guard n > 0 else { return }
        let halfBand = rc.bandHalf
        rc.glow {
            for (s, side) in Side.allCases.enumerated() {
                let len = rc.length(side)
                guard len > 2 else { continue }
                let pitch = len / CGFloat(n)
                let dot = max(2, min(rc.thickness * 1.4, pitch * 0.8))
                let vp = dot * 1.55
                let rows = max(1, Int(halfBand / vp))
                let drawUnlit = n * rows <= 700            // keep very dense meters cheap
                for i in 0..<n {
                    let t = (CGFloat(i) + 0.5) / CGFloat(n)
                    let x = side.sign * (rc.clearance + (CGFloat(i) + 0.5) * pitch)
                    let lit = Int((levels[s][i] * CGFloat(rows)).rounded(.up))
                    for r in 0..<rows {
                        let isLit = r < lit
                        if !isLit && !drawUnlit { break }
                        let y = (CGFloat(r) + 0.5) * vp
                        let col = rc.color(t, alpha: isLit ? 1 : 0.10)
                        rc.fillRounded(CGRect(x: x - dot / 2, y: y - dot / 2, width: dot, height: dot),
                                       radius: rc.cornerRadius, color: col)
                        rc.fillRounded(CGRect(x: x - dot / 2, y: -y - dot / 2, width: dot, height: dot),
                                       radius: rc.cornerRadius, color: col)
                    }
                }
            }
        }
    }
}
