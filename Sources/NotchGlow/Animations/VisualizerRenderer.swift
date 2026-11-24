import CoreGraphics

/// Draws the current frame by dispatching to the active style. Knows nothing about the keyboard.
final class VisualizerRenderer {
    private struct ColorKey: Equatable {
        var mode: ColorMode
        var colors: [CodableColor]
        var stops: Int
    }

    private var cache: [AnimationStyle: StyleRenderer] = [:]
    private var lut: [CGColor] = []
    private var lutKey: ColorKey?

    func renderer(for style: AnimationStyle) -> StyleRenderer {
        if let r = cache[style] { return r }
        let r = style.makeRenderer()
        cache[style] = r
        return r
    }

    func reset() { cache.values.forEach { $0.reset() } }
    var hasActiveContent: Bool { cache.values.contains { $0.hasActiveContent } }

    func keystroke(strength: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        renderer(for: cfg.style).keystroke(strength: strength, state: state, cfg: cfg, geo: geo)
    }

    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        renderer(for: cfg.style).update(dt: dt, state: state, cfg: cfg, geo: geo)
    }

    private func refreshLUT(_ cfg: AnimationConfiguration) {
        let key = ColorKey(mode: cfg.colorMode, colors: cfg.colors, stops: cfg.multiColorStops)
        if key != lutKey || lut.isEmpty {
            lut = cfg.colorLUT()
            lutKey = key
        }
    }

    func render(into ctx: CGContext, size: CGSize, state: VisualizerState,
                cfg: AnimationConfiguration, clearance: CGFloat, simplifiedGlow: Bool = false) {
        ctx.clear(CGRect(origin: .zero, size: size))
        guard state.alpha > 0.002 else { return }
        refreshLUT(cfg)

        let geo = Geometry.make(cfg, clearance: clearance)
        let content = Geometry.contentSize(cfg)
        let scale = min(1, size.width / content.width, size.height / content.height)

        let e = clamp(state.expansion, 0, 1)
        let eased = 1 - (1 - e) * (1 - e)
        let left = geo.clearance + (geo.leftMax - geo.clearance) * eased
        let right = geo.clearance + (geo.rightMax - geo.clearance) * eased

        ctx.saveGState()
        ctx.translateBy(x: size.width / 2, y: size.height / 2)
        ctx.scaleBy(x: scale, y: scale)
        ctx.setAlpha(state.alpha * CGFloat(cfg.opacity))
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        let rc = RenderContext(ctx: ctx, cfg: cfg, state: state, geo: geo, lut: lut,
                               leftExtent: left, rightExtent: right, simplifiedGlow: simplifiedGlow)
        renderer(for: cfg.style).draw(rc)
        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }
}
