import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menu: StatusMenu?
    private var settingsWindow: NSWindow?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(opts as CFDictionary)

        let menu = StatusMenu()
        menu.openSettings = { [weak self] in self?.showSettings() }
        self.menu = menu
        HotkeyCenter.shared.start()
        DragSnap.shared.start()
    }

    private func showSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            w.title = "ZoneSnap Settings"
            w.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
