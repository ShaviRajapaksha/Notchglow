import AppKit

/// The menu bar icon: a symmetrical waveform, drawn as a template image so macOS tints it correctly
/// for light, dark and highlighted menu bars.
enum StatusIcon {
    static func image() -> NSImage {
        let size = NSSize(width: 20, height: 16)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            let heights: [CGFloat] = [3.5, 7, 10.5, 14, 10.5, 7, 3.5]
            let barWidth: CGFloat = 1.7
            let gap: CGFloat = 1.2
            let total = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
            var x = (size.width - total) / 2
            for h in heights {
                let rect = NSRect(x: x, y: (size.height - h) / 2, width: barWidth, height: h)
                NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
                x += barWidth + gap
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "NotchGlow"
        return image
    }
}
