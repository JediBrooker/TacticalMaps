import SwiftUI
import UIKit

/// Renders a `TacticalControlMeasure` from the bundled PNG / SVG asset
/// under `Assets.xcassets/AppSymbols/`. Pure black symbol on a
/// transparent background.
///
/// **No halo is baked in.** The white outer glow used to make symbols
/// pop on satellite imagery is applied live by `LockedSizeAnnotationView`
/// as a `CALayer` shadow, so its on-screen width can shrink
/// independently as the symbol is transform-scaled up — the user
/// wanted the halo to get *relatively* smaller as the symbol grows
/// (rather than thickening 1:1 with it).
///
/// On non-map surfaces (the picker preview), the symbol just sits on
/// a white card, where a halo would be invisible anyway.
struct TacticalControlMeasureSymbolView: View {
    let measure: TacticalControlMeasure
    /// Clockwise rotation in degrees. 0 = canonical orientation.
    var rotation: Double = 0
    var size: CGFloat = 56

    var body: some View {
        // Fixed-size canvas so `ImageRenderer` produces the same point
        // dimensions regardless of rotation angle. Without the outer
        // .frame, .rotationEffect at non-square angles grows the
        // intrinsic size to the rotated bbox, breaking downstream
        // assumptions about image size.
        ZStack {
            Image("AppSymbols/\(measure.assetName)")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.black)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: size, height: size)
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
