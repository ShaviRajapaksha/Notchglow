import CoreGraphics

/// Everything a style needs to draw one frame. Origin (0,0) is the center of the band.
struct RenderContext {
    let ctx: CGContext
    let cfg: AnimationConfiguration
    let state: VisualizerState
    let geo: Geometry
    let lut: [CGColor]
    let leftExtent: CGFloat       // current (animated) distance from center
    let rightExtent: CGFloat

    var clearance: CGFloat { geo.clearance }
    var bandHalf: CGFloat { geo.height * CGFloat(cfg.spikeHeight) / 2 }
    var thickness: CGFloat { CGFloat(cfg.lineThickness) }
    var cornerRadius: CGFloat { CGFloat(cfg.cornerRadius) }

    func extent(_ side: Side) -> CGFloat { side == .left ? leftExtent : rightExtent }
    /// Drawable length of one side, measured from the clearance gap.
    func length(_ side: Side) -> CGFloat { max(0, extent(side) - clearance) }

    /// Gradient color at t (0 = center, 1 = edge).
    func color(_ t: CGFloat, alpha: CGFloat = 1) -> CGColor {
        let c = lut[Int(clamp(t, 0, 1) * CGFloat(lut.count - 1))]
        if alpha >= 0.999 { return c }
        return c.copy(alpha: clamp(alpha, 0, 1)) ?? c
    }

    /// Runs `body` twice inside transparency layers with a wide and a tight shadow = soft glow.
    func glow(_ body: () -> Void) {
        let g = CGFloat(cfg.glow)
        let passes: [(blur: CGFloat, alpha: CGFloat)] = g > 0.01
            ? [(g * 30, min(1, 0.3 + g * 0.7)), (g * 9, min(1, 0.4 + g * 0.6))]
            : [(0, 0)]
        for p in passes {
            ctx.saveGState()
            if p.blur > 0 {
                ctx.setShadow(offset: .zero, blur: p.blur, color: color(0.5, alpha: p.alpha))
            }
            ctx.beginTransparencyLayer(auxiliaryInfo: nil)
            body()
            ctx.endTransparencyLayer()
            ctx.restoreGState()
        }
    }

    func fillRounded(_ rect: CGRect, radius: CGFloat, color: CGColor) {
        let r = max(0, min(radius, min(rect.width, rect.height) / 2))
        ctx.setFillColor(color)
        if r < 0.3 {
            ctx.fill(rect)
        } else {
            ctx.addPath(CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil))
            ctx.fillPath()
        }
    }

    /// Gradient that spans the full current width, center color in the middle.
    func xGradient() -> (gradient: CGGradient, start: CGPoint, end: CGPoint)? {
        let total = leftExtent + rightExtent
        guard total > 1 else { return nil }
        let n = 8
        let cl = leftExtent / total
        var colors: [CGColor] = []
        var locs: [CGFloat] = []
        for i in stride(from: n, through: 0, by: -1) {       // left: edge -> center
            let p = CGFloat(i) / CGFloat(n)
            colors.append(color(p)); locs.append(cl * (1 - p))
        }
        for i in 1...n {                                     // right: center -> edge
            let p = CGFloat(i) / CGFloat(n)
            colors.append(color(p)); locs.append(cl + (1 - cl) * p)
        }
        guard let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                 colors: colors as CFArray, locations: locs) else { return nil }
        return (g, CGPoint(x: -leftExtent, y: 0), CGPoint(x: rightExtent, y: 0))
    }

    /// Strokes `path` filled with the horizontal gradient (no glow; wrap in `glow {}`).
    func strokeGradient(_ path: CGPath, width: CGFloat, alpha: CGFloat = 1) {
        guard let g = xGradient() else { return }
        ctx.saveGState()
        ctx.setAlpha(alpha)
        ctx.addPath(path)
        ctx.setLineWidth(width)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        ctx.drawLinearGradient(g.gradient, start: g.start, end: g.end,
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }
}
