import AppKit

enum DisplayManager {
    static func displayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    static func screenUnderMouse() -> NSScreen? {
        let p = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.main
    }

    static func targetScreens(mode: DisplayMode) -> [NSScreen] {
        switch mode {
        case .allDisplays: return NSScreen.screens
        case .primaryDisplay: return Array(NSScreen.screens.prefix(1))
        case .activeDisplay: return [screenUnderMouse()].compactMap { $0 }
        }
    }

    /// Height of the menu bar on a screen (works with notched displays and hidden menu bars).
    static func menuBarHeight(for screen: NSScreen) -> CGFloat {
        let inset = screen.frame.maxY - screen.visibleFrame.maxY
        if inset > 1 && inset < 60 { return inset }
        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 { return screen.safeAreaInsets.top }
        return NSStatusBar.system.thickness
    }

    /// Half the width of the camera housing (0 on screens without a notch).
    static func notchHalfWidth(for screen: NSScreen) -> CGFloat {
        if #available(macOS 12.0, *),
           let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
            return max(0, (screen.frame.width - l.width - r.width) / 2)
        }
        return 0
    }

    /// Window frame, horizontally centered on the screen.
    /// - overMenuBar: the animation band is vertically centered ON the menu bar.
    /// - belowMenuBar: the top edge of the band sits right under the menu bar.
    static func overlayFrame(for screen: NSScreen, size: CGSize, bandHeight: CGFloat,
                             placement: OverlayPlacement, verticalOffset: CGFloat) -> NSRect {
        let bar = menuBarHeight(for: screen)
        let x = screen.frame.midX - size.width / 2
        let centerY: CGFloat
        switch placement {
        case .overMenuBar: centerY = screen.frame.maxY - bar / 2
        case .belowMenuBar: centerY = screen.frame.maxY - bar - bandHeight / 2
        }
        let y = centerY - size.height / 2 - verticalOffset
        return NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
    }
}
