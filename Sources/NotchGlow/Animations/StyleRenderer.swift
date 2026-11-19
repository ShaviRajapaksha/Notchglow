import CoreGraphics

/// Plug-in interface for animation styles. To add a style: implement this protocol,
/// add a case to AnimationStyle, and return the renderer from makeRenderer().
protocol StyleRenderer: AnyObject {
    var hasActiveContent: Bool { get }
    func reset()
    func keystroke(strength: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry)
    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry)
    func draw(_ rc: RenderContext)
}

extension StyleRenderer {
    func keystroke(strength: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {}
    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {}
}
