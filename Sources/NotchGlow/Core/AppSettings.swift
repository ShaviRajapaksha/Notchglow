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

/// App-level (non-visual) settings.
struct AppSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var detectionPaused: Bool = false
    var displayMode: DisplayMode = .allDisplays
    var avoidNotch: Bool = true
    var verticalOffset: Double = 0          // positive moves the animation down
    var hasCompletedOnboarding: Bool = false
}
