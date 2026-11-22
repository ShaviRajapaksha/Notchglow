import Foundation

/// A source of "what the Mac is playing". Two backends implement it:
/// - CoreAudioTapMonitor (macOS 14.4+): needs only "System Audio Recording" (audio only, no screen access).
/// - SystemAudioMonitor (older macOS): ScreenCaptureKit, needs "Screen & System Audio Recording".
protocol SystemAudioSource: AnyObject {
    var onAudio: ((Float, [Float]) -> Void)? { get set }
    var onStatus: ((Bool, String?) -> Void)? { get set }
    func start()
    func stop()
}

extension SystemAudioMonitor: SystemAudioSource {}

enum SystemAudioBackend {
    /// True when the lighter Core Audio tap backend is available (macOS 14.4+).
    static var usesCoreAudioTap: Bool {
        if #available(macOS 14.4, *) { return true } else { return false }
    }
}
