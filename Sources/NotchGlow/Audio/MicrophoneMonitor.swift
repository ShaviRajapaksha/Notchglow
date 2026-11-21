import AVFoundation

/// Listens to the microphone (sound around you). Requires the Microphone permission.
final class MicrophoneMonitor {
    var onAudio: ((Float, [Float]) -> Void)?
    var onStatus: ((Bool) -> Void)?

    private let engine = AVAudioEngine()
    private let analyzer = AudioAnalyzer()
    private(set) var isRunning = false
    private var requesting = false

    func start() {
        guard !isRunning, !requesting else { return }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            begin()
        case .notDetermined:
            requesting = true
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.requesting = false
                    if granted { self?.begin() }
                }
            }
        default:
            break
        }
    }

    private func begin() {
        guard !isRunning else { return }
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }
        let rate = format.sampleRate
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self, let channels = buffer.floatChannelData else { return }
            let count = Int(buffer.frameLength)
            let samples = UnsafeBufferPointer(start: channels[0], count: count)
            let result = self.analyzer.analyze(samples, sampleRate: rate)
            DispatchQueue.main.async { self.onAudio?(result.level, result.bands) }
        }
        do {
            try engine.start()
            isRunning = true
            onStatus?(true)
        } catch {
            input.removeTap(onBus: 0)
            isRunning = false
            onStatus?(false)
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        onStatus?(false)
    }
}
