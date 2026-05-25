import SwiftUI

/// A transparent SwiftUI overlay layered above `MapContainerView`.
/// Renders every tactical-control-measure waypoint as a live SwiftUI
/// view, positioned by the screen coordinate that
/// `MapContainerView.Coordinator` publishes on every camera change.
///
/// Why not MKAnnotationView? Every halo / click-hijack / scale issue
/// we've fought was caused by MKMapView's annotation pipeline clipping
/// child layers, swallowing taps via inflated bounds, and bitmap-
/// sampling at low resolution. Pulling control measures out of that
/// pipeline gives us a real SwiftUI `.shadow()`, vector-crisp
/// rendering at any zoom, and tap-hit testing that matches the
/// visible pixels by construction.
struct TacticalSymbolOverlay: View {
    @ObservedObject var waypointStore: WaypointStore
    @ObservedObject var mapVM: MapViewModel
    @ObservedObject var visibility: LayerVisibility

    var body: some View {
        // ZStack with .topLeading so child .position(x:y:) values use
        // the same coordinate space as MKMapView (origin top-left).
        // A clear background expands the ZStack to fill the parent
        // without intercepting touches in empty areas — taps in
        // empty space pass through to the underlying MKMapView.
        ZStack(alignment: .topLeading) {
            Color.clear.allowsHitTesting(false)

            if visibility.waypointsVisible {
                ForEach(controlMeasures, id: \.id) { wp in
                    if let pos = mapVM.waypointScreenPositions[wp.id],
                       case .controlMeasure(let measure) = wp.kind {
                        TacticalSymbolBubble(
                            waypoint: wp,
                            measure: measure,
                            zoomScale: mapVM.zoomScaleFactor,
                            store: waypointStore,
                            mapVM: mapVM
                        )
                        .position(x: pos.x, y: pos.y)
                    }
                }
            }
        }
    }

    private var controlMeasures: [Waypoint] {
        waypointStore.waypoints.filter { wp in
            if case .controlMeasure = wp.kind { return true }
            return false
        }
    }
}

/// One tactical symbol with its halo, tap, and drag-to-move gesture.
private struct TacticalSymbolBubble: View {
    let waypoint: Waypoint
    let measure: TacticalControlMeasure
    let zoomScale: CGFloat
    @ObservedObject var store: WaypointStore
    @ObservedObject var mapVM: MapViewModel

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    var body: some View {
        let baseSize: CGFloat = 64
        let displaySize = max(
            8,
            baseSize * CGFloat(waypoint.scale) * zoomScale
        )

        TacticalControlMeasureSymbolView(
            measure: measure,
            rotation: waypoint.rotation,
            size: displaySize
        )
        // Real SwiftUI .shadow — works at any view size, vector-
        // crisp because the symbol is re-rendered live (not bitmap-
        // sampled), and not subject to MKMapView's layer clipping.
        .shadow(color: .white, radius: 2)
        .shadow(color: .white, radius: 2)
        .shadow(color: .white, radius: 1.5)
        .scaleEffect(isDragging ? 1.08 : 1.0)
        .offset(dragOffset)
        .animation(.easeOut(duration: 0.12), value: isDragging)
        .onTapGesture {
            mapVM.selectedWaypointID = waypoint.id
        }
        // Long-press + drag (iOS-native draggable-annotation pattern).
        // A regular tap or a two-finger pinch fails the long-press
        // immediately so the touch passes through to MKMapView for
        // pan/zoom. Only an intentional hold for 0.35s engages drag.
        .gesture(
            LongPressGesture(minimumDuration: 0.35)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onChanged { value in
                    switch value {
                    case .first(true):
                        // Long-press detected — enter drag mode with
                        // a haptic so the user knows the symbol's
                        // "grabbed".
                        if !isDragging {
                            isDragging = true
                            UIImpactFeedbackGenerator(style: .medium)
                                .impactOccurred()
                        }
                    case .second(true, let drag):
                        if let drag = drag {
                            dragOffset = drag.translation
                        }
                    default:
                        break
                    }
                }
                .onEnded { value in
                    defer {
                        isDragging = false
                        dragOffset = .zero
                    }
                    guard case .second(true, let drag?) = value,
                          let originalPos = mapVM.waypointScreenPositions[waypoint.id],
                          let convert = mapVM.screenToCoordinate
                    else { return }
                    let newScreenPoint = CGPoint(
                        x: originalPos.x + drag.translation.width,
                        y: originalPos.y + drag.translation.height
                    )
                    let newCoord = convert(newScreenPoint)
                    var updated = waypoint
                    updated.latitude  = newCoord.latitude
                    updated.longitude = newCoord.longitude
                    store.update(updated)
                }
        )
    }
}
