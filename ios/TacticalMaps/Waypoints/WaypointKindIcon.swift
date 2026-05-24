import SwiftUI

/// Small icon view used in pickers / lists. Shows the proper APP-6
/// military symbol for friendly/enemy units, falls back to an SF Symbol
/// for the generic waypoint and tactical control measures.
struct WaypointKindIcon: View {
    let kind: WaypointKind
    var size: CGFloat = 32

    var body: some View {
        if let spec = kind.militarySpec {
            MilitarySymbolView(spec: spec, size: size)
        } else {
            Image(systemName: kind.sfSymbol)
                .font(.system(size: size * 0.58, weight: .semibold))
                .foregroundStyle(kind.tint)
                .frame(width: size, height: size)
        }
    }
}
