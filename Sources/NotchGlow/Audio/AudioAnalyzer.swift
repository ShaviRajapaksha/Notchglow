import Foundation

/// Measures loudness and a 16-band frequency spectrum (Goertzel, 40 Hz - 12 kHz, log-spaced) from raw samples.
/// Works purely in memory: samples are analyzed and immediately discarded.
final class AudioAnalyzer {
    static let bandCount = 16

    private var peak: Float = 0.001
    private var window: [Float] = []
    private let zeros = [Float](repeating: 0, count: AudioAnalyzer.bandCount)
    private let minFreq: Double = 40
    private let maxFreq: Double = 12000

    func analyze(_ samples: UnsafeBufferPointer<Float>, sampleRate: Double) -> (level: Float, bands: [Float]) {
        let count = samples.count
        guard count > 0 else { return (0, zeros) }

        var sum: Float = 0
        for s in samples { sum += s * s }
        let rms: Float = (sum / Float(count)).squareRoot()
        let level: Float = min(1, rms.squareRoot() * 1.8)
        guard rms > 0.002, count >= 256 else { return (level, zeros) }

        let n = min(count, 1024)
        let start = count - n
        if window.count != n {
            var w = [Float](repeating: 0, count: n)
            for i in 0..<n {
                let phase: Float = 2 * Float.pi * Float(i) / Float(n - 1)
                w[i] = 0.5 - 0.5 * cos(phase)
            }
            window = w
        }

        var bands = [Float](repeating: 0, count: Self.bandCount)
        var maxV: Float = 0
        let ratio: Double = maxFreq / minFreq
        for b in 0..<Self.bandCount {
            let t: Double = Double(b) / Double(Self.bandCount - 1)
            let freq: Double = min(minFreq * pow(ratio, t), sampleRate * 0.45)
            let omega: Double = 2 * Double.pi * freq / sampleRate
            let coeff: Float = Float(2 * cos(omega))
            var s1: Float = 0
            var s2: Float = 0
            for i in 0..<n {
                let x: Float = samples[start + i] * window[i]
                let s0: Float = x + coeff * s1 - s2
                s2 = s1
                s1 = s0
            }
            let power: Float = s1 * s1 + s2 * s2 - coeff * s1 * s2
            let mag: Float = max(0, power).squareRoot() / Float(n)
            let tilt: Float = Float(1 + 1.5 * t)           // lift treble, which is naturally quieter
            let v: Float = mag.squareRoot() * tilt
            bands[b] = v
            maxV = max(maxV, v)
        }

        peak = max(maxV, peak * 0.9995)                  // adaptive normalization
        let norm: Float = max(peak, 0.0005)
        for b in bands.indices { bands[b] = min(1, bands[b] / norm) }
        return (level, bands)
    }
}
