import Foundation

/// Observable status of the audio inputs, shown in Settings.
final class AudioStatus: ObservableObject {
    @Published var systemRunning = false
    @Published var systemError: String?
    @Published var micRunning = false
}
