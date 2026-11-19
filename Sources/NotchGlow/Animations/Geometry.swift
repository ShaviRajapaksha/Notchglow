import CoreGraphics

enum Side: CaseIterable {
    case left, right
    var sign: CGFloat { self == .left ? -1 : 1 }
}

/// Layout of the animation band. Coordinates are centered on (0, 0) = middle of the band.
struct Geometry {
    static let padding: CGFloat = 44        // room for glow / blur around the content

    var clearance: CGFloat                  // half of the empty center gap
    var leftMax: CGFloat                    // max distance from center, left
    var rightMax: CGFloat
    var height: CGFloat

    static func make(_ cfg: AnimationConfiguration, clearance: CGFloat) -> Geometry {
        let half = CGFloat(cfg.width) / 2
        let c = clamp(clearance, 0, max(0, half - 12))
        let l = min(half, max(c + 6, half * CGFloat(cfg.leftExpansion) / 100))
        let r = min(half, max(c + 6, half * CGFloat(cfg.rightExpansion) / 100))
        return Geometry(clearance: c, leftMax: l, rightMax: r, height: CGFloat(cfg.height))
    }

    static func contentSize(_ cfg: AnimationConfiguration) -> CGSize {
        CGSize(width: CGFloat(cfg.width) + 2 * padding, height: CGFloat(max(cfg.height, 8)) + 2 * padding)
    }

    func maxExtent(_ side: Side) -> CGFloat { side == .left ? leftMax : rightMax }
}
