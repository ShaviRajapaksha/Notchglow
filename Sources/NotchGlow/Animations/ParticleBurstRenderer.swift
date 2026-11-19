import CoreGraphics

/// D. Particle Burst — particles fly out of the center toward both sides.
final class ParticleBurstRenderer: StyleRenderer {
    private struct Particle {
        var x, y, vx, vy, size, life, maxLife: CGFloat
    }

    private var particles: [Particle] = []
    private var emit: CGFloat = 0

    var hasActiveContent: Bool { !particles.isEmpty }
    func reset() { particles.removeAll(); emit = 0 }

    private func spawn(dir: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        guard particles.count < cfg.particleCount else { return }
        let speed = CGFloat(cfg.speed)
        let boost = 0.6 + state.drive * 0.8
        let band = geo.height * CGFloat(cfg.spikeHeight)
        let life = rnd(0.5, 1.4) * max(0.5, CGFloat(cfg.animationDuration) * 0.7)
        particles.append(Particle(
            x: dir * (geo.clearance + rnd(0, 5)),
            y: rnd(-band * 0.12, band * 0.12),
            vx: dir * rnd(110, 380) * speed * boost,
            vy: rnd(-90, 90) * speed,
            size: CGFloat(cfg.lineThickness) * rnd(0.5, 1.7) + 0.6,
            life: life, maxLife: life))
    }

    private func spawnPair(state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        if cfg.symmetrical {
            spawn(dir: -1, state: state, cfg: cfg, geo: geo)
            spawn(dir: 1, state: state, cfg: cfg, geo: geo)
        } else {
            spawn(dir: Bool.random() ? -1 : 1, state: state, cfg: cfg, geo: geo)
        }
    }

    func keystroke(strength: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        let count = clamp(Int(CGFloat(cfg.particleCount) * 0.07 * (0.5 + strength) * CGFloat(cfg.intensity)), 2, 40)
        for _ in 0..<count { spawnPair(state: state, cfg: cfg, geo: geo) }
    }

    func update(dt: CGFloat, state: VisualizerState, cfg: AnimationConfiguration, geo: Geometry) {
        if state.alpha > 0.3 {
            emit += dt * state.drive * CGFloat(cfg.intensity) * CGFloat(cfg.particleCount) * 0.4
            while emit >= 1 { emit -= 1; spawnPair(state: state, cfg: cfg, geo: geo) }
        }
        let halfBand = geo.height * CGFloat(cfg.spikeHeight) / 2
        for i in particles.indices {
            particles[i].life -= dt
            particles[i].x += particles[i].vx * dt
            particles[i].y += particles[i].vy * dt
            particles[i].vx *= exp(-dt * 1.1)
            particles[i].vy *= exp(-dt * 1.6)
            if abs(particles[i].y) > halfBand {
                particles[i].y = clamp(particles[i].y, -halfBand, halfBand)
                particles[i].vy = -particles[i].vy * 0.5
            }
        }
        particles.removeAll { p in
            p.life <= 0 || abs(p.x) > (p.x < 0 ? geo.leftMax : geo.rightMax)
        }
    }

    func draw(_ rc: RenderContext) {
        guard !particles.isEmpty else { return }
        rc.glow {
            for p in particles {
                let life = p.life / p.maxLife
                let side: Side = p.x < 0 ? .left : .right
                let span = max(1, rc.geo.maxExtent(side) - rc.clearance)
                let t = (abs(p.x) - rc.clearance) / span
                let size = p.size * (0.35 + 0.65 * life)
                rc.ctx.setFillColor(rc.color(t, alpha: min(1, life * 1.8)))
                rc.ctx.fillEllipse(in: CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size))
            }
        }
    }
}
