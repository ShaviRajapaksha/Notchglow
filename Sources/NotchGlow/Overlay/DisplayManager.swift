import AppKit

/// A connected display, as shown in the display chooser.
struct DisplayInfo: Identifiable, Equatable {
    let id: String          // stable display UUID
    let name: String
    let detail: String
}

enum DisplayManager {
    static func displayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    /// A UUID that stays the same for a given physical display across reboots and re-plugging
    /// (unlike CGDirectDisplayID, which can change).
    static func uuid(for screen: NSScreen) -> String? {
        guard let did = displayID(screen),
              let unmanaged = CGDisplayCreateUUIDFromDisplayID(did) else { return nil }
        let cfUUID = unmanaged.takeRetainedValue()
        guard let string = CFUUIDCreateString(nil, cfUUID) else { return nil }
        return string as String
    }

    static func screenUnderMouse() -> NSScreen? {
        let p = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.main
    }

    /// All connected displays, for the display chooser.
    static func availableDisplays() -> [DisplayInfo] {
        var result: [DisplayInfo] = []
        for (index, screen) in NSScreen.screens.enumerated() {
            guard let did = displayID(screen), let uid = uuid(for: screen) else { continue }
            var parts: [String] = ["\(Int(screen.frame.width)) \u{00D7} \(Int(screen.frame.height))"]
            if CGDisplayIsBuiltin(did) != 0 { parts.insert("Built-in", at: 0) }
            if index == 0 { parts.append("Main display") }
            result.append(DisplayInfo(id: uid, name: screen.localizedName, detail: parts.joined(separator: " \u{00B7} ")))
        }
        return result
    }

    static func targetScreens(settings: AppSettings) -> [NSScreen] {
        switch settings.displayMode {
        case .allDisplays:
            return NSScreen.screens
        case .selectedDisplays:
            let wanted = Set(settings.selectedDisplays)
            return NSScreen.screens.filter { screen in
                guard let id = uuid(for: screen) else { return false }
                return wanted.contains(id)
            }
        case .activeDisplay:
            return [screenUnderMouse()].compactMap { $0 }
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

    /// Window frame: horizontally centered on the screen, vertically centered on the menu bar.
    static func overlayFrame(for screen: NSScreen, size: CGSize, verticalOffset: CGFloat) -> NSRect {
        let bar = menuBarHeight(for: screen)
        let x = screen.frame.midX - size.width / 2
        let y = screen.frame.maxY - bar / 2 - size.height / 2 - verticalOffset
        return NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
    }
}
