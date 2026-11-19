import Foundation
import CoreGraphics

@inline(__always) func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T { min(max(v, lo), hi) }
@inline(__always) func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

/// Random CGFloat in lo...hi (order-safe).
@inline(__always) func rnd(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    lo < hi ? CGFloat.random(in: lo...hi) : lo
}

/// Frame-rate independent exponential smoothing factor (v += (target - v) * smoothing(rate, dt)).
@inline(__always) func smoothing(_ rate: CGFloat, _ dt: CGFloat) -> CGFloat { 1 - exp(-rate * dt) }
