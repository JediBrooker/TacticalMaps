import Foundation
import Combine
import CoreLocation

/// In-memory waypoint store with disk persistence to Application Support/waypoints.json.
final class WaypointStore: ObservableObject {
    @Published private(set) var waypoints: [Waypoint] = []

    private let url: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("waypoints.json")
    }()

    init() { load() }

    func add(_ wp: Waypoint) {
        waypoints.append(wp)
        persist()
    }

    func remove(_ wp: Waypoint) {
        waypoints.removeAll { $0.id == wp.id }
        persist()
    }

    func update(_ wp: Waypoint) {
        guard let idx = waypoints.firstIndex(where: { $0.id == wp.id }) else { return }
        waypoints[idx] = wp
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: url) else {
            seedDemoIfEmpty()
            return
        }
        if let decoded = try? JSONDecoder().decode([Waypoint].self, from: data) {
            waypoints = decoded
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(waypoints)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[WaypointStore] persist failed: \(error)")
        }
    }

    /// Seed the demo waypoints so a first run shows real APP-6 symbology
    /// rather than an empty map. Two friendly platoons opposing two enemy
    /// sections, plus a tactical control measure.
    private func seedDemoIfEmpty() {
        waypoints = [
            Waypoint(name: "1 Pl, A Coy",  latitude: 37.7820, longitude: -122.4310, elevation: 2345, kind: .friendlyPlatoon),
            Waypoint(name: "2 Pl, A Coy",  latitude: 37.7750, longitude: -122.4250, elevation: 1856, kind: .friendlyPlatoon),
            Waypoint(name: "En Sect (S)",  latitude: 37.7790, longitude: -122.4080, elevation: 2120, kind: .enemySection),
            Waypoint(name: "En Sect (N)",  latitude: 37.7730, longitude: -122.4140, elevation: 1620, kind: .enemySection),
            Waypoint(name: "FUP CHARLIE",  latitude: 37.7770, longitude: -122.4200, elevation: 1500, kind: .formUpPoint)
        ]
        persist()
    }
}
