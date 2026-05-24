import Foundation

/// APP-6C tactical mission task verbs. Each represents an intent — the
/// commander wants a friendly unit to *do* this thing to/at the marked
/// location. Drawn as a polyline (axis of effort) with an arrowhead at
/// the end and the abbreviation rendered alongside the line.
///
/// Selected via the Drawing toolbar's "Task" chip. When `tacticalTask`
/// is set on a `DrawingShape`, the renderer decorates the polyline with
/// task-specific markings (arrowhead style + label).
enum TacticalMissionTask: String, Codable, Hashable, CaseIterable {
    case attack
    case counterAttack
    case attackByFire
    case supportByFire
    case block
    case breach
    case bypass
    case canalize
    case clear
    case contain
    case cover
    case delay
    case destroy
    case disrupt
    case fix
    case guardTask        // `guard` is a Swift keyword
    case interdict
    case isolate
    case neutralize
    case occupy
    case penetrate
    case retain
    case screen
    case secure
    case seize
    case withdraw

    /// Long human-readable name, used in pickers and lists.
    var displayName: String {
        switch self {
        case .attack:        return "Attack"
        case .counterAttack: return "Counter-Attack"
        case .attackByFire:  return "Attack by Fire"
        case .supportByFire: return "Support by Fire"
        case .block:         return "Block"
        case .breach:        return "Breach"
        case .bypass:        return "Bypass"
        case .canalize:      return "Canalise"
        case .clear:         return "Clear"
        case .contain:       return "Contain"
        case .cover:         return "Cover"
        case .delay:         return "Delay"
        case .destroy:       return "Destroy"
        case .disrupt:       return "Disrupt"
        case .fix:           return "Fix"
        case .guardTask:     return "Guard"
        case .interdict:     return "Interdict"
        case .isolate:       return "Isolate"
        case .neutralize:    return "Neutralise"
        case .occupy:        return "Occupy"
        case .penetrate:     return "Penetrate"
        case .retain:        return "Retain"
        case .screen:        return "Screen"
        case .secure:        return "Secure"
        case .seize:         return "Seize"
        case .withdraw:      return "Withdraw"
        }
    }

    /// Short label drawn on the map beside the arrow.
    var abbreviation: String {
        switch self {
        case .attack:        return "ATK"
        case .counterAttack: return "CATK"
        case .attackByFire:  return "ABF"
        case .supportByFire: return "SBF"
        case .block:         return "BLOCK"
        case .breach:        return "BRCH"
        case .bypass:        return "BYPS"
        case .canalize:      return "CNLZ"
        case .clear:         return "CLR"
        case .contain:       return "CONT"
        case .cover:         return "COVR"
        case .delay:         return "DLY"
        case .destroy:       return "DSTRY"
        case .disrupt:       return "DSRPT"
        case .fix:           return "FIX"
        case .guardTask:     return "GUARD"
        case .interdict:     return "INTDCT"
        case .isolate:       return "ISO"
        case .neutralize:    return "NEUT"
        case .occupy:        return "OCC"
        case .penetrate:     return "PENT"
        case .retain:        return "RET"
        case .screen:        return "SCRN"
        case .secure:        return "SEC"
        case .seize:         return "SEIZE"
        case .withdraw:      return "WDRW"
        }
    }

    /// Logical grouping used by the picker menu to keep the list scannable.
    var group: Group {
        switch self {
        case .attack, .counterAttack, .penetrate, .seize, .destroy, .neutralize,
             .clear, .breach, .occupy:
            return .offensive
        case .block, .canalize, .contain, .fix, .delay, .disrupt, .interdict,
             .isolate, .retain:
            return .stabilising
        case .cover, .screen, .guardTask, .secure:
            return .protection
        case .attackByFire, .supportByFire:
            return .fireSupport
        case .bypass, .withdraw:
            return .mobility
        }
    }

    enum Group: String, CaseIterable, Hashable {
        case offensive, stabilising, protection, fireSupport, mobility

        var displayName: String {
            switch self {
            case .offensive:    return "Offensive"
            case .stabilising:  return "Stabilising"
            case .protection:   return "Protection"
            case .fireSupport:  return "Fire Support"
            case .mobility:     return "Mobility"
            }
        }

        var tasks: [TacticalMissionTask] {
            TacticalMissionTask.allCases.filter { $0.group == self }
        }
    }
}
