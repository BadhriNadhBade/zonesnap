import Foundation
import Combine

final class ZoneStore: ObservableObject {
    static let shared = ZoneStore()

    @Published var zones: [Zone] { didSet { save() } }
    @Published var dragSnapEnabled: Bool { didSet { UserDefaults.standard.set(dragSnapEnabled, forKey: "dragSnap") } }

    private static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ZoneSnap", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("zones.json")
    }

    private init() {
        if let data = try? Data(contentsOf: Self.url),
           let saved = try? JSONDecoder().decode([Zone].self, from: data) {
            zones = saved
        } else {
            zones = DefaultZones.make()
        }
        dragSnapEnabled = UserDefaults.standard.object(forKey: "dragSnap") as? Bool ?? true
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(zones) else { return }
        try? data.write(to: Self.url, options: .atomic)
    }

    func resetToDefaults() { zones = DefaultZones.make() }

    func addZone() {
        zones.append(Zone(name: "New zone", x: 0, y: 0, w: 0.5, h: 0.5))
    }
}
