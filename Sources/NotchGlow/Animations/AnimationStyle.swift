import Foundation

enum AnimationStyle: String, Codable, CaseIterable, Identifiable {
    case spikeWave, audioWave, equalizer, particleBurst, energyPulse, digitalRain, minimalGlow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spikeWave: return "Spike Wave"
        case .audioWave: return "Audio Wave"
        case .equalizer: return "Equalizer"
        case .particleBurst: return "Particle Burst"
        case .energyPulse: return "Energy Pulse"
        case .digitalRain: return "Digital Rain"
        case .minimalGlow: return "Minimal Glow"
        }
    }

    var summary: String {
        switch self {
        case .spikeWave: return "Sharp spikes ripple outward from the center."
        case .audioWave: return "A fluid waveform whose amplitude follows your typing."
        case .equalizer: return "Independent bars that jump with each keystroke."
        case .particleBurst: return "Particles burst from the center to both sides."
        case .energyPulse: return "Glowing lines with pulses that travel outward."
        case .digitalRain: return "Small digital segments falling around the bar."
        case .minimalGlow: return "A single subtle glowing line."
        }
    }

    var symbol: String {
        switch self {
        case .spikeWave: return "waveform.path.ecg"
        case .audioWave: return "waveform"
        case .equalizer: return "chart.bar.fill"
        case .particleBurst: return "sparkles"
        case .energyPulse: return "bolt.fill"
        case .digitalRain: return "arrow.down.to.line"
        case .minimalGlow: return "minus"
        }
    }

    func makeRenderer() -> StyleRenderer {
        switch self {
        case .spikeWave: return SpikeWaveRenderer()
        case .audioWave: return AudioWaveRenderer()
        case .equalizer: return EqualizerRenderer()
        case .particleBurst: return ParticleBurstRenderer()
        case .energyPulse: return EnergyPulseRenderer()
        case .digitalRain: return DigitalRainRenderer()
        case .minimalGlow: return MinimalGlowRenderer()
        }
    }
}
