import SwiftUI
import UIKit

/// Renders a `TacticalControlMeasure` from the bundled PNG / SVG asset
/// under `Assets.xcassets/AppSymbols/`. Pure black symbol on a
/// transparent background with a soft white outer glow baked in via
/// stacked Gaussian shadows — reads as a halo rather than a hard
/// outline. The glow scales 1:1 with the symbol via the annotation
/// view's transform.
struct TacticalControlMeasureSymbolView: View {
    let measure: TacticalControlMeasure
    /// Clockwise rotation in degrees. 0 = canonical orientation.
    var rotation: Double = 0
    var size: CGFloat = 56
    /// Extra room reserved around the symbol so the glow isn't
    /// clipped by the rendered bitmap's edges.
    static let haloPadding: CGFloat = 6

    var body: some View {
        let canvas = size + 2 * Self.haloPadding
        return ZStack {
            applyHalo {
                Image("AppSymbols/\(measure.assetName)")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.black)
                    .frame(width: size, height: size)
            }
            .rotationEffect(.degrees(rotation))
        }
        .frame(width: canvas, height: canvas)
    }

    /// Three stacked Gaussian-blurred white shadows. Each is soft on
    /// its own; stacking accumulates alpha into a definite glow that
    /// reads on busy satellite imagery instead of being a sharp
    /// outline.
    @ViewBuilder
    private func applyHalo<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .shadow(color: .white, radius: 2)
            .shadow(color: .white, radius: 2)
            .shadow(color: .white, radius: 1.5)
    }
}

@MainActor
enum TacticalControlMeasureRenderer {
    /// Canonical render size of every produced UIImage. All per-waypoint
    /// size variation (and all zoom-driven scaling) is applied via the
    /// annotation view's `transform` at render time — the renderer here
    /// always returns a base-size bitmap so the cache only ever holds
    /// (measure × rotation) variants, not (measure × rotation × scale).
    static let baseSize: CGFloat = 64

    private struct Key: Hashable {
        let measure: TacticalControlMeasure
        let rotationCentideg: Int   // 0..35999, 1/100 of a degree
    }
    private static var cache: [Key: UIImage] = [:]

    static func image(for measure: TacticalControlMeasure,
                      rotation: Double = 0) -> UIImage? {
        let normalized = ((rotation.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let key = Key(
            measure: measure,
            rotationCentideg: Int((normalized * 100).rounded())
        )
        if let cached = cache[key] { return cached }
        let view = TacticalControlMeasureSymbolView(
            measure: measure,
            rotation: normalized,
            size: baseSize
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        let img = renderer.uiImage
        if let img { cache[key] = img }
        return img
    }
}
