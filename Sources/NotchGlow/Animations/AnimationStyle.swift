import Foundation

enum AnimationStyle: String, Codable, CaseIterable, Identifiable {
    case spikeWave, audioWave, helixWave, equalizer, ledMeter, heartbeat, lightning
    case particleBurst, energyPulse, minimalGlow

    var id: String { rawValue }

    /// Unknown/removed styles in saved settings (e.g. the old Needle Spikes) fall back to Spike Wave.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AnimationStyle(rawValue: raw) ?? .spikeWave
    }

    var title: String {
        switch self {
        case .spikeWave: return "Spike Wave"
        case .audioWave: return "Audio Wave"
        case .helixWave: return "Helix Wave"
        case .equalizer: return "Equalizer"
        case .ledMeter: return "LED Meter"
        case .heartbeat: return "Heartbeat"
        case .lightning: return "Lightning"
        case .particleBurst: return "Particle Burst"
        case .energyPulse: return "Energy Pulse"
        case .minimalGlow: return "Minimal Glow"
        }
    }

    var summary: String {
        switch self {
        case .spikeWave: return "Rounded spikes ripple outward from the center."
        case .audioWave: return "A fluid waveform whose amplitude follows your typing."
        case .helixWave: return "Two waveforms twist around each other like a double helix."
        case .equalizer: return "Independent bars that jump with each keystroke."
        case .ledMeter: return "Retro LED columns that light up like a VU meter."
        case .heartbeat: return "Each keystroke sends an ECG-style beat along one line."
        case .lightning: return "A crackling, jagged electric line with afterimages."
        case .particleBurst: return "Particles burst from the center to both sides."
        case .energyPulse: return "Glowing lines with pulses that travel outward."
        case .minimalGlow: return "A single subtle glowing line."
        }
    }

    var symbol: String {
        switch self {
        case .spikeWave: return "waveform.path.ecg"
        case .audioWave: return "waveform"
        case .helixWave: return "waveform.path"
        case .equalizer: return "chart.bar.fill"
        case .ledMeter: return "square.grid.3x3.fill"
        case .heartbeat: return "heart.fill"
        case .lightning: return "bolt.horizontal.fill"
        case .particleBurst: return "sparkles"
        case .energyPulse: return "bolt.fill"
        case .minimalGlow: return "minus"
        }
    }

    func makeRenderer() -> StyleRenderer {
        switch self {
        case .spikeWave: return SpikeWaveRenderer()
        case .audioWave: return AudioWaveRenderer()
        case .helixWave: return HelixWaveRenderer()
        case .equalizer: return EqualizerRenderer()
        case .ledMeter: return LEDMeterRenderer()
        case .heartbeat: return HeartbeatRenderer()
        case .lightning: return LightningRenderer()
        case .particleBurst: return ParticleBurstRenderer()
        case .energyPulse: return EnergyPulseRenderer()
        case .minimalGlow: return MinimalGlowRenderer()
        }
    }
}
