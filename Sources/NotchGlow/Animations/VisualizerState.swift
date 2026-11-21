import CoreGraphics
import Foundation

/// Style-independent typing state: energy, fade envelope, expansion and keystroke ripples.
/// This is the only thing the keyboard side talks to (via registerKey) — the renderers only read it.
final class VisualizerState {
    struct Ripple {
        var birth: CGFloat
        var strength: CGFloat
        var left: CGFloat
        var right: CGFloat
    }

    private(set) var clock: CGFloat = 0
    private(set) var phase: CGFloat = 0          // advances with speed * frequency * energy
    private(set) var energy: CGFloat = 0         // smoothed typing rate (0...1)
    private(set) var kick: CGFloat = 0           // short per-key flash (decays quickly)
    private(set) var alpha: CGFloat = 0          // overall visibility envelope
    private(set) var expansion: CGFloat = 0      // 0 = collapsed at center, 1 = fully expanded
    private(set) var timeSinceKey: CGFloat = 999
    private(set) var ripples: [Ripple] = []
    private var keyTimes: [CGFloat] = []

    // Audio input (music / system sound / microphone)
    private(set) var bands = [CGFloat](repeating: 0, count: AudioAnalyzer.bandCount)
    private(set) var audioLevel: CGFloat = 0
    private var audioAge: CGFloat = 999
    private var avgLevel: CGFloat = 0
    private var lastBeat: CGFloat = -1
    private var bandsPeak: CGFloat = 0

    /// True while live audio is driving a frequency spectrum.
    var hasSpectrum: Bool { bandsPeak > 0.01 }

    /// Combined drive used by renderers.
    var drive: CGFloat { min(1.2, energy + kick * 0.6) }

    var isBusy: Bool {
        if !ripples.isEmpty { return true }
        let values: [CGFloat] = [alpha, expansion, kick, energy, audioLevel, bandsPeak]
        return values.contains { $0 > 0.005 }
    }

    func isQuiescent(_ cfg: AnimationConfiguration) -> Bool {
        timeSinceKey > CGFloat(cfg.animationDuration + cfg.fadeOutDuration)
    }

    func reset() {
        clock = 0; phase = 0; energy = 0; kick = 0; alpha = 0; expansion = 0
        timeSinceKey = 999; ripples.removeAll(); keyTimes.removeAll()
        audioLevel = 0; audioAge = 999; avgLevel = 0; lastBeat = -1; bandsPeak = 0
        for i in bands.indices { bands[i] = 0 }
    }

    @discardableResult
    func registerKey(cfg: AnimationConfiguration) -> CGFloat {
        keyTimes.append(clock)
        timeSinceKey = 0
        let rate = CGFloat(keyTimes.count)
        let strength = min(1, (0.45 + 0.07 * rate) * CGFloat(cfg.sensitivity))
        kick = min(1, kick + 0.45 * strength * CGFloat(cfg.typingIntensity))
        let sym = cfg.symmetrical
        ripples.append(Ripple(birth: clock, strength: strength,
                              left: sym ? 1 : rnd(0.3, 1), right: sym ? 1 : rnd(0.3, 1)))
        if ripples.count > 24 { ripples.removeFirst() }
        return strength
    }

    func update(dt: CGFloat, cfg: AnimationConfiguration) {
        clock += dt
        timeSinceKey += dt
        let speed = CGFloat(cfg.speed)
        phase += dt * speed * CGFloat(cfg.frequency) * (2.0 + drive * 3.0)

        keyTimes.removeAll { clock - $0 > 1.0 }
        kick *= exp(-dt * 6)
        if kick < 0.001 { kick = 0 }

        // Energy from typing rate (keys in the last second).
        let rate = CGFloat(keyTimes.count)
        var targetEnergy = min(1, rate / 9 * CGFloat(cfg.sensitivity) * CGFloat(cfg.typingIntensity))
        // Audio: decay if no recent audio frames, then let loudness drive the energy.
        audioAge += dt
        if audioAge > 0.4 {
            let f = exp(-dt * 8)
            audioLevel *= f
            for i in bands.indices { bands[i] *= f }
        }
        if audioLevel < 0.003 { audioLevel = 0 }
        bandsPeak = bands.max() ?? 0
        targetEnergy = max(targetEnergy, audioLevel)
        if cfg.idleAnimation { targetEnergy = max(targetEnergy, 0.14) }
        energy += (targetEnergy - energy) * smoothing(targetEnergy > energy ? 14 : 3.5, dt)
        if targetEnergy == 0 && energy < 0.004 { energy = 0 }

        // Visibility envelope: hold, then linear fade-out.
        let hold = CGFloat(cfg.animationDuration)
        let fade = max(0.05, CGFloat(cfg.fadeOutDuration))
        var targetAlpha: CGFloat = timeSinceKey < hold ? 1 : max(0, 1 - (timeSinceKey - hold) / fade)
        if cfg.idleAnimation { targetAlpha = max(targetAlpha, 0.4) }
        alpha += (targetAlpha - alpha) * smoothing(targetAlpha > alpha ? 22 : 14, dt)
        if targetAlpha == 0 && alpha < 0.004 { alpha = 0 }

        // Expansion grows from the center with typing energy.
        let expTarget = targetAlpha * (0.3 + 0.7 * min(1, energy * 1.2 + kick * 0.5))
        expansion += (expTarget - expansion) * smoothing(6 * max(0.3, speed), dt)
        if expTarget == 0 && expansion < 0.004 { expansion = 0 }

        let rs = 1.6 * speed
        ripples.removeAll { (clock - $0.birth) * rs > 1.5 }
    }

    /// Spectrum value at normalized distance t (0 = center = bass ... 1 = edge = treble). 0 without audio.
    func spectrum(at t: CGFloat) -> CGFloat {
        guard bandsPeak > 0.01 else { return 0 }
        let x = clamp(t, 0, 1) * CGFloat(bands.count - 1)
        let i = Int(x)
        let j = min(bands.count - 1, i + 1)
        return lerp(bands[i], bands[j], x - CGFloat(i))
    }

    /// Feed one analyzed audio frame. Returns a beat strength when an onset (beat) was detected.
    func feedAudio(level: CGFloat, bands incoming: [CGFloat], cfg: AnimationConfiguration) -> CGFloat? {
        let sens = CGFloat(cfg.sensitivity)
        let lv: CGFloat = min(1, level * sens)
        audioLevel += (lv - audioLevel) * 0.5
        audioAge = 0
        let gain: CGFloat = min(1.5, sens)
        for i in 0..<min(incoming.count, bands.count) {
            let target: CGFloat = min(1, incoming[i] * gain)
            bands[i] += (target - bands[i]) * (target > bands[i] ? 0.7 : 0.25)
        }
        if lv > 0.04 { timeSinceKey = 0 }                  // keep the visualizer visible while sound plays
        avgLevel += (lv - avgLevel) * 0.08

        let isBeat = lv > 0.06 && lv > avgLevel * 1.35 && clock - lastBeat > 0.13
        guard isBeat else { return nil }
        lastBeat = clock
        let strength: CGFloat = min(1, 0.4 + lv)
        kick = min(1, kick + 0.45 * strength * CGFloat(cfg.typingIntensity))
        let sym = cfg.symmetrical
        ripples.append(Ripple(birth: clock, strength: strength,
                              left: sym ? 1 : rnd(0.3, 1), right: sym ? 1 : rnd(0.3, 1)))
        if ripples.count > 24 { ripples.removeFirst() }
        return strength
    }

    /// Influence of all ripples at normalized distance `t` (0 = center, 1 = edge).
    func rippleInfluence(at t: CGFloat, side: Side, speed: CGFloat) -> CGFloat {
        var v: CGFloat = 0
        for r in ripples {
            let f = (clock - r.birth) * 1.6 * speed
            let d = t - f
            let w = r.strength * (side == .left ? r.left : r.right)
            v += w * exp(-d * d / (2 * 0.09 * 0.09)) * max(0, 1 - f * 0.55)
        }
        return min(v, 1.5)
    }
}
