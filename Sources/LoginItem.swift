import Foundation

/// Opens ZoneSnap at login through a per-user LaunchAgent (works on macOS 12).
enum LoginItem {
    private static var id: String { Bundle.main.bundleIdentifier ?? "com.local.ZoneSnap" }
    private static var url: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents/\(id).login.plist")
    }

    static var isEnabled: Bool { FileManager.default.fileExists(atPath: url.path) }

    static func setEnabled(_ on: Bool) {
        if !on { try? FileManager.default.removeItem(at: url); return }
        let plist: [String: Any] = ["Label": "\(id).login", "ProgramArguments": ["/usr/bin/open", "-a", Bundle.main.bundlePath],
                                    "RunAtLoad": true]
        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
