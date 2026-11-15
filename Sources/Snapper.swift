import AppKit

enum Snapper {
    static func snap(_ window: AXWindow, to zone: Zone) {
        guard let current = window.frame, let screen = ScreenGeometry.screen(containing: current) else { return }
        window.setFrame(ScreenGeometry.rect(for: zone, on: screen))
    }

    /// Hotkey press: zones sharing the pressed key and modifiers cycle in list
    /// order when the window already sits in one of them.
    static func trigger(group: [Zone]) {
        guard let window = AXWindow.focused(), let current = window.frame,
              let screen = ScreenGeometry.screen(containing: current) else { NSSound.beep(); return }
        let portrait = ScreenGeometry.isPortrait(screen)
        let candidates = group.filter { $0.applies(toPortrait: portrait) }
        guard !candidates.isEmpty else { return }
        let frames = candidates.map { ScreenGeometry.rect(for: $0, on: screen) }
        let index = frames.firstIndex { close($0, current) }
        let next = index.map { ($0 + 1) % candidates.count } ?? 0
        window.setFrame(frames[next])
    }

    private static func close(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 12 && abs(a.minY - b.minY) < 12 && abs(a.width - b.width) < 12 && abs(a.height - b.height) < 12
    }
}
