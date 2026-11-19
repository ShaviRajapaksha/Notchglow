import AppKit

enum ColorMode: String, Codable, CaseIterable, Identifiable {
    case solid, twoColor, multiColor
    var id: String { rawValue }
    var title: String {
        switch self {
        case .solid: return "Solid"
        case .twoColor: return "Two-Color"
        case .multiColor: return "Multi-Color"
        }
    }
}

/// Everything describing how the visualizer looks and behaves.
/// Independent from app-level settings (see AppSettings).
struct AnimationConfiguration: Codable, Equatable {
    var style: AnimationStyle = .spikeWave

    // Dimensions
    var width: Double = 480
    var height: Double = 40
    var leftExpansion: Double = 100      // % of half-width
    var rightExpansion: Double = 100     // % of half-width
    var centerSize: Double = 0           // empty gap kept clear at the center

    // Appearance
    var colorMode: ColorMode = .multiColor
    var colors: [CodableColor] = CodableColor.defaultPalette
    var multiColorStops: Int = 3
    var opacity: Double = 0.95
    var glow: Double = 0.55
    var blur: Double = 0
    var cornerRadius: Double = 2
    var spikeCount: Int = 28
    var spikeHeight: Double = 1.0
    var particleCount: Int = 120
    var lineThickness: Double = 2.5
    var speed: Double = 1.0
    var intensity: Double = 1.0

    // Behavior
    var animationDuration: Double = 1.2
    var fadeOutDuration: Double = 0.8
    var sensitivity: Double = 1.0
    var typingIntensity: Double = 1.0
    var frequency: Double = 1.0
    var symmetrical: Bool = true
    var randomized: Bool = true
    var idleAnimation: Bool = false

    mutating func normalize() {
        let palette = CodableColor.defaultPalette
        while colors.count < 5 { colors.append(palette[colors.count]) }
        if colors.count > 5 { colors = Array(colors.prefix(5)) }
        multiColorStops = clamp(multiColorStops, 3, 5)
        width = clamp(width, 120, 1800)
        height = clamp(height, 8, 200)
        leftExpansion = clamp(leftExpansion, 5, 100)
        rightExpansion = clamp(rightExpansion, 5, 100)
        centerSize = clamp(centerSize, 0, 600)
        spikeCount = clamp(spikeCount, 2, 120)
        particleCount = clamp(particleCount, 5, 600)
        blur = clamp(blur, 0, 10)
    }

    var activeColors: [CodableColor] {
        switch colorMode {
        case .solid: return [colors[0]]
        case .twoColor: return [colors[0], colors[1]]
        case .multiColor: return Array(colors.prefix(clamp(multiColorStops, 3, 5)))
        }
    }

    /// 64-entry color lookup (0 = center, 1 = outer edge).
    func colorLUT(size: Int = 64) -> [CGColor] {
        let stops = activeColors
        return (0..<size).map { i -> CGColor in
            if stops.count == 1 { return stops[0].cgColor }
            let t = Double(i) / Double(size - 1)
            let p = t * Double(stops.count - 1)
            let idx = min(Int(p), stops.count - 2)
            let f = p - Double(idx)
            let a = stops[idx], b = stops[idx + 1]
            return NSColor(srgbRed: CGFloat(a.r + (b.r - a.r) * f),
                           green: CGFloat(a.g + (b.g - a.g) * f),
                           blue: CGFloat(a.b + (b.b - a.b) * f),
                           alpha: 1).cgColor
        }
    }
}
