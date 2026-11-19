import AppKit
import SwiftUI

/// Small Codable sRGB color so gradients can be persisted in UserDefaults.
struct CodableColor: Codable, Equatable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }

    init(_ color: NSColor) {
        let c = color.usingColorSpace(.sRGB) ?? NSColor.white
        self.init(r: Double(c.redComponent), g: Double(c.greenComponent), b: Double(c.blueComponent))
    }

    init(_ color: Color) { self.init(NSColor(color)) }

    var nsColor: NSColor { NSColor(srgbRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1) }
    var color: Color { Color(nsColor: nsColor) }
    var cgColor: CGColor { nsColor.cgColor }

    static let defaultPalette: [CodableColor] = [
        CodableColor(r: 0.22, g: 0.86, b: 1.00),
        CodableColor(r: 0.62, g: 0.42, b: 1.00),
        CodableColor(r: 1.00, g: 0.36, b: 0.72),
        CodableColor(r: 1.00, g: 0.62, b: 0.25),
        CodableColor(r: 1.00, g: 0.90, b: 0.35)
    ]
}
