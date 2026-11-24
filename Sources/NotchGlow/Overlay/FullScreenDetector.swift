import AppKit

/// Detects whether another app currently has a window covering an entire display
/// (a full-screen app, video or game). Reads window geometry only; no screen content and no permission needed.
enum FullScreenDetector {
    static func isFullScreen(displayID: CGDirectDisplayID) -> Bool {
        let display = CGDisplayBounds(displayID)
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return false }
        let ownPID = Int(ProcessInfo.processInfo.processIdentifier)

        for window in windows {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = window[kCGWindowOwnerPID as String] as? Int, pid != ownPID else { continue }
            if let alpha = window[kCGWindowAlpha as String] as? Double, alpha < 0.01 { continue }
            guard let boundsDict = window[kCGWindowBounds as String] as? NSDictionary,
                  let rect = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }

            let samePlace = abs(rect.minX - display.minX) <= 2 && abs(rect.minY - display.minY) <= 2
            let coversDisplay = rect.width >= display.width - 2 && rect.height >= display.height - 2
            if samePlace && coversDisplay { return true }
        }
        return false
    }
}
