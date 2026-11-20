import Foundation

enum DisplayMode: String, Codable, CaseIterable, Identifiable {
    case allDisplays, activeDisplay, primaryDisplay
    var id: String { rawValue }
    var title: String {
        switch self {
        case .allDisplays: return "All displays"
        case .activeDisplay: return "Display under the mouse"
        case .primaryDisplay: return "Primary display only"
        }
    }
}

enum OverlayPlacement: String, Codable, CaseIterable, Identifiable {
    case overMenuBar, belowMenuBar
    var id: String { rawValue }
    var title: String {
        switch self {
        case .overMenuBar: return "Over the menu bar"
        case .belowMenuBar: return "Below the menu bar"
        }
    }
}

/// App-level (non-visual) settings. Decoding is tolerant so new fields never wipe saved settings.
struct AppSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var detectionPaused: Bool = false
    var displayMode: DisplayMode = .allDisplays
    var placement: OverlayPlacement = .overMenuBar
    var avoidNotch: Bool = true
    var verticalOffset: Double = 0          // positive moves the animation down
    var hasCompletedOnboarding: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? d.isEnabled
        detectionPaused = try c.decodeIfPresent(Bool.self, forKey: .detectionPaused) ?? d.detectionPaused
        displayMode = try c.decodeIfPresent(DisplayMode.self, forKey: .displayMode) ?? d.displayMode
        placement = try c.decodeIfPresent(OverlayPlacement.self, forKey: .placement) ?? d.placement
        avoidNotch = try c.decodeIfPresent(Bool.self, forKey: .avoidNotch) ?? d.avoidNotch
        verticalOffset = try c.decodeIfPresent(Double.self, forKey: .verticalOffset) ?? d.verticalOffset
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? d.hasCompletedOnboarding
    }
}
