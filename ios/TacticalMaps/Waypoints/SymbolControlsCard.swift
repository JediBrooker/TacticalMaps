import SwiftUI
import CoreLocation

/// Floating compact card that appears when the user taps any waypoint
/// annotation on the map. Surfaces the actions that make sense for
/// the kind:
///   - All kinds: live preview, name, "Move to Crosshair", close.
///   - Tactical control measures: rotation + size sliders.
///   - Military / generic: just move.
///
/// Designed to sit just above the bottom safe-area inset so it doesn't
/// overlap with the "Centre on My Location" pill. Tap-outside dismissal
/// is handled by `ContentView` — this view only renders.
struct SymbolControlsCard: View {
    @ObservedObject var waypointStore: WaypointStore
    /// Map VM exposes the current crosshair coordinate (camera centre)
    /// for the "Move to Crosshair" action.
    @ObservedObject var mapVM: MapViewModel
    /// ID of the waypoint we're editing. The view re-resolves the
    /// current Waypoint from the store on every redraw so changes
    /// persist immediately and the preview stays in sync.
    let waypointID: UUID
    let onDismiss: () -> Void

    var body: some View {
        if let wp = waypointStore.waypoints.first(where: { $0.id == waypointID }) {
            card(for: wp)
        }
    }

    private func card(for wp: Waypoint) -> some View {
        VStack(spacing: 12) {
            header(for: wp)

            Divider()

            // Rotation + size live only for tactical control measures —
            // military symbols don't have orientation or per-instance
            // size in the model.
            if case .controlMeasure = wp.kind {
                rotationRow(for: wp)
                sizeRow(for: wp)
                Divider()
            }

            moveButton(for: wp)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }

    // MARK: Rows

    private func header(for wp: Waypoint) -> some View {
        HStack(spacing: 12) {
            WaypointKindIcon(
                kind: wp.kind,
                size: 36,
                rotation: wp.kind.controlMeasure == nil ? 0 : wp.rotation
            )
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(wp.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(wp.kind.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close symbol controls")
        }
    }

    private func rotationRow(for wp: Waypoint) -> some View {
        sliderRow(
            icon: "arrow.clockwise.circle",
            title: "Rotation",
            valueLabel: "\(Int(wp.rotation.rounded()))°",
            value: Binding(
                get: { wp.rotation },
                set: { newValue in
                    var updated = wp
                    updated.rotation = newValue
                    waypointStore.update(updated)
                }
            ),
            range: 0...360,
            step: 1,
            resetTo: 0
        )
    }

    private func sizeRow(for wp: Waypoint) -> some View {
        sliderRow(
            icon: "arrow.up.left.and.arrow.down.right.circle",
            title: "Size",
            valueLabel: String(format: "%.2f×", wp.scale),
            value: Binding(
                get: { wp.scale },
                set: { newValue in
                    var updated = wp
                    updated.scale = newValue
                    waypointStore.update(updated)
                }
            ),
            range: 0.1...20.0,
            step: 0.1,
            resetTo: 1.0
        )
    }

    /// One-tap relocation: snap the waypoint to the current map centre
    /// (which is where the on-screen crosshair sits). The user pans
    /// the map first to position the crosshair, then taps this. For
    /// drag-style moves, the annotation view is also `isDraggable` so
    /// long-press + drag works directly on the map.
    private func moveButton(for wp: Waypoint) -> some View {
        Button {
            var updated = wp
            updated.latitude  = mapVM.cameraCentre.latitude
            updated.longitude = mapVM.cameraCentre.longitude
            waypointStore.update(updated)
        } label: {
            Label {
                Text("Move to Crosshair")
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "scope")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.85),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Pan the map first so the crosshair is at the new location, then tap.")
    }

    // MARK: Slider primitive

    private func sliderRow(icon: String,
                           title: String,
                           valueLabel: String,
                           value: Binding<Double>,
                           range: ClosedRange<Double>,
                           step: Double,
                           resetTo defaultValue: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(valueLabel)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button {
                    value.wrappedValue = defaultValue
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset \(title)")
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
