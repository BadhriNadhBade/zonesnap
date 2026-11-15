import AppKit
import ApplicationServices

/// A window reached through Accessibility. Frames use the global top-left origin.
struct AXWindow {
    let element: AXUIElement

    static func focused() -> AXWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication, app.bundleIdentifier != Bundle.main.bundleIdentifier else { return nil }
        let appEl = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appEl, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let win = value else { return nil }
        return AXWindow(element: win as! AXUIElement)
    }

    /// The window under a global top-left point.
    static func at(_ point: CGPoint) -> AXWindow? {
        var el: AXUIElement?
        guard AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(point.x), Float(point.y), &el) == .success,
              let hit = el else { return nil }
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(hit, kAXWindowAttribute as CFString, &value) == .success, let win = value {
            return AXWindow(element: win as! AXUIElement)
        }
        var role: CFTypeRef?
        if AXUIElementCopyAttributeValue(hit, kAXRoleAttribute as CFString, &role) == .success,
           (role as? String) == kAXWindowRole as String {
            return AXWindow(element: hit)
        }
        return nil
    }

    var frame: CGRect? {
        var p: CFTypeRef?, s: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &p) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &s) == .success,
              let pv = p, let sv = s else { return nil }
        var point = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(pv as! AXValue, .cgPoint, &point)
        AXValueGetValue(sv as! AXValue, .cgSize, &size)
        return CGRect(origin: point, size: size)
    }

    /// Size, position, then size again: some apps clamp the first resize
    /// against the old position.
    func setFrame(_ rect: CGRect) {
        var origin = rect.origin, size = rect.size
        guard let pv = AXValueCreate(.cgPoint, &origin), let sv = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sv)
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pv)
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sv)
    }
}

enum ScreenGeometry {
    /// Height of the primary display, the pivot between Cocoa (bottom-left) and CG (top-left) coordinates.
    static var primaryHeight: CGFloat { NSScreen.screens.first?.frame.height ?? 0 }

    /// A Cocoa rect in the global top-left space.
    static func toCG(_ r: NSRect) -> CGRect {
        CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
    }

    /// The screen holding the center of a top-left-space rect, else the nearest.
    static func screen(containing cg: CGRect) -> NSScreen? {
        let center = CGPoint(x: cg.midX, y: cg.midY)
        if let hit = NSScreen.screens.first(where: { toCG($0.frame).contains(center) }) { return hit }
        return NSScreen.screens.min { distance(toCG($0.frame), center) < distance(toCG($1.frame), center) }
    }

    private static func distance(_ r: CGRect, _ p: CGPoint) -> CGFloat {
        let dx = max(r.minX - p.x, 0, p.x - r.maxX), dy = max(r.minY - p.y, 0, p.y - r.maxY)
        return hypot(dx, dy)
    }

    static func isPortrait(_ screen: NSScreen) -> Bool { screen.frame.height > screen.frame.width }

    /// Where a zone lands on a screen, in top-left global coordinates.
    static func rect(for zone: Zone, on screen: NSScreen) -> CGRect {
        let area = toCG(screen.visibleFrame)
        return CGRect(x: area.minX + area.width * zone.x, y: area.minY + area.height * zone.y,
                      width: area.width * zone.w, height: area.height * zone.h).integral
    }
}

extension AXWindow {
    /// Standard, unminimized windows of other regular apps.
    static func otherVisible(excluding skip: AXWindow) -> [AXWindow] {
        var result: [AXWindow] = []
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular
            && app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            let appEl = AXUIElementCreateApplication(app.processIdentifier)
            AXUIElementSetMessagingTimeout(appEl, 0.15)
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appEl, kAXWindowsAttribute as CFString, &value) == .success,
                  let list = value as? [AXUIElement] else { continue }
            for el in list where !CFEqual(el, skip.element) {
                var sub: CFTypeRef?, mini: CFTypeRef?
                AXUIElementCopyAttributeValue(el, kAXSubroleAttribute as CFString, &sub)
                AXUIElementCopyAttributeValue(el, kAXMinimizedAttribute as CFString, &mini)
                guard (sub as? String) == kAXStandardWindowSubrole as String, (mini as? Bool) != true else { continue }
                result.append(AXWindow(element: el))
            }
        }
        return result
    }
}
