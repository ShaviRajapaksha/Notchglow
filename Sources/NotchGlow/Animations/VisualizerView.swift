import AppKit
import CoreImage
import SwiftUI

extension AnimationConfiguration {
    /// Half of the empty center gap.
    var clearance: CGFloat { CGFloat(centerSize) / 2 }
}

/// Layer-backed view that renders the engine's current frame with Core Graphics.
final class VisualizerView: NSView {
    private let engine: VisualizerEngine
    private var appliedBlur: Double = -1

    init(engine: VisualizerEngine) {
        self.engine = engine
        super.init(frame: .zero)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layerUsesCoreImageFilters = true
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }      // never intercept clicks

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { engine.attach(self) } else { engine.detach(self) }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        engine.render(into: ctx, size: bounds.size)
    }

    /// Applies the Gaussian blur (if any) as a Core Image layer filter.
    func configurationChanged() {
        let blur = engine.config.blur
        guard blur != appliedBlur else { return }
        appliedBlur = blur
        if blur > 0.3, let f = CIFilter(name: "CIGaussianBlur") {
            f.setValue(blur, forKey: kCIInputRadiusKey)
            layer?.filters = [f]
        } else {
            layer?.filters = nil
        }
        needsDisplay = true
    }
}

/// SwiftUI wrapper used by the live preview.
struct VisualizerPreview: NSViewRepresentable {
    let engine: VisualizerEngine
    func makeNSView(context: Context) -> VisualizerView { VisualizerView(engine: engine) }
    func updateNSView(_ nsView: VisualizerView, context: Context) {}
}
