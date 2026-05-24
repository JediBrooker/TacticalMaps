import Foundation
import CoreLocation
import SwiftUI

/// A user-placed point of interest. Stored in WGS84 as lat/lon doubles (matches
/// the GeoJSON export schema and the Android model). The computed `coordinate`
/// adapts to CoreLocation/MapKit APIs.
struct Waypoint: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var notes: String?
    var latitude: Double
    var longitude: Double
    var elevation: Double?      // metres above sea level (optional)
    var kind: WaypointKind
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         notes: String? = nil,
         latitude: Double,
         longitude: Double,
         elevation: Double? = nil,
         kind: WaypointKind = .generic,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.kind = kind
        self.createdAt = createdAt
    }

    /// Convenience for callers working with CoreLocation/MapKit.
    init(id: UUID = UUID(),
         name: String,
         notes: String? = nil,
         coordinate: CLLocationCoordinate2D,
         elevation: Double? = nil,
         kind: WaypointKind = .generic,
         createdAt: Date = .now) {
        self.init(id: id, name: name, notes: notes,
                  latitude: coordinate.latitude, longitude: coordinate.longitude,
                  elevation: elevation, kind: kind, createdAt: createdAt)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var subtitle: String? {
        elevation.map { String(format: "%.0f m", $0) }
    }
}

/// All waypoint kinds, grouped by category. Order within each category is the
/// order shown in the picker.
enum WaypointKind: String, Codable, CaseIterable, Hashable {
    // MARK: Generic
    case generic

    // MARK: Friendly Infantry (APP-6 friend frame: blue rectangle, infantry X)
    case friendlySection, friendlyPlatoon, friendlyCompany, friendlyRegiment, friendlyBrigade

    // MARK: Enemy Infantry (APP-6 hostile frame: red diamond, infantry X)
    case enemySection, enemyPlatoon, enemyCompany, enemyRegiment, enemyBrigade

    // MARK: Tactical control measures (black)
    case axisOfAssault          // arrow showing direction of advance
    case supportByFire          // SBF position
    case attackByFire           // ABF position
    case formUpPoint            // FUP
    case rvPoint                // Rendezvous
    case axp                    // Ambulance Exchange Point
    case lz                     // Landing Zone

    // MARK: - Display

    var displayName: String {
        switch self {
        case .generic:           return "Waypoint"

        case .friendlySection:   return "Friendly Infantry — Section"
        case .friendlyPlatoon:   return "Friendly Infantry — Platoon"
        case .friendlyCompany:   return "Friendly Infantry — Company"
        case .friendlyRegiment:  return "Friendly Infantry — Regiment"
        case .friendlyBrigade:   return "Friendly Infantry — Brigade"

        case .enemySection:      return "Enemy Infantry — Section"
        case .enemyPlatoon:      return "Enemy Infantry — Platoon"
        case .enemyCompany:      return "Enemy Infantry — Company"
        case .enemyRegiment:     return "Enemy Infantry — Regiment"
        case .enemyBrigade:      return "Enemy Infantry — Brigade"

        case .axisOfAssault:     return "Axis of Assault"
        case .supportByFire:     return "Support by Fire (SBF)"
        case .attackByFire:      return "Attack by Fire (ABF)"
        case .formUpPoint:       return "Form Up Point (FUP)"
        case .rvPoint:           return "Rendezvous (RV)"
        case .axp:               return "Ambulance Exchange (AXP)"
        case .lz:                return "Landing Zone (LZ)"
        }
    }

    var category: WaypointCategory {
        switch self {
        case .generic:
            return .field
        case .friendlySection, .friendlyPlatoon, .friendlyCompany,
             .friendlyRegiment, .friendlyBrigade:
            return .friendly
        case .enemySection, .enemyPlatoon, .enemyCompany,
             .enemyRegiment, .enemyBrigade:
            return .enemy
        case .axisOfAssault, .supportByFire, .attackByFire,
             .formUpPoint, .rvPoint, .axp, .lz:
            return .tactical
        }
    }

    /// Returns the APP-6 symbol spec for friendly/enemy unit kinds, or nil
    /// for kinds that aren't drawn as a NATO unit symbol.
    var militarySpec: MilitarySymbolSpec? {
        switch self {
        case .friendlySection:   return .init(affiliation: .friend,  echelon: .section)
        case .friendlyPlatoon:   return .init(affiliation: .friend,  echelon: .platoon)
        case .friendlyCompany:   return .init(affiliation: .friend,  echelon: .company)
        case .friendlyRegiment:  return .init(affiliation: .friend,  echelon: .regiment)
        case .friendlyBrigade:   return .init(affiliation: .friend,  echelon: .brigade)

        case .enemySection:      return .init(affiliation: .hostile, echelon: .section)
        case .enemyPlatoon:      return .init(affiliation: .hostile, echelon: .platoon)
        case .enemyCompany:      return .init(affiliation: .hostile, echelon: .company)
        case .enemyRegiment:     return .init(affiliation: .hostile, echelon: .regiment)
        case .enemyBrigade:      return .init(affiliation: .hostile, echelon: .brigade)

        default: return nil
        }
    }

    /// SF Symbol used as the fallback marker glyph for kinds that don't have
    /// a custom APP-6 drawing (generic waypoint, tactical control measures).
    var sfSymbol: String {
        switch self {
        case .generic:           return "mappin"

        // The military kinds use militarySpec for their real symbology,
        // but we keep an SF Symbol fallback for any code path that still
        // calls into this getter (the MapKit annotation now bypasses it).
        case .friendlySection, .friendlyPlatoon, .friendlyCompany,
             .friendlyRegiment, .friendlyBrigade:
            return "shield.fill"
        case .enemySection, .enemyPlatoon, .enemyCompany,
             .enemyRegiment, .enemyBrigade:
            return "xmark.shield.fill"

        case .axisOfAssault:     return "arrow.up.right.circle.fill"
        case .supportByFire:     return "scope"
        case .attackByFire:      return "flame.fill"
        case .formUpPoint:       return "square.stack.fill"
        case .rvPoint:           return "person.3.fill"
        case .axp:               return "cross.case.fill"
        case .lz:                return "h.square.fill"
        }
    }

    /// Marker pin tint (used only by kinds without a `militarySpec`).
    var tint: Color {
        switch category {
        case .field:    return .yellow
        case .friendly: return .blue   // unused once militarySpec is wired
        case .enemy:    return .red    // unused once militarySpec is wired
        case .tactical: return .black
        }
    }
}

enum WaypointCategory: String, CaseIterable, Hashable {
    case field, friendly, enemy, tactical

    var displayName: String {
        switch self {
        case .field:    return "Field Markers"
        case .friendly: return "Friendly Units (NATO APP-6)"
        case .enemy:    return "Enemy Units (NATO APP-6)"
        case .tactical: return "Tactical Control Measures"
        }
    }

    var kinds: [WaypointKind] {
        WaypointKind.allCases.filter { $0.category == self }
    }
}
