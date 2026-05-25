import SwiftUI
import UIKit

/// Renders a `TacticalControlMeasure` from the bundled PNG / SVG asset
/// under `Assets.xcassets/AppSymbols/`. Pure black symbol on a
/// transparent background with a soft white outer glow whose
/// **bitmap-baked width is configurable** via the `halo` parameter.
///
/// `halo` is the per-shadow Gaussian radius in points. The renderer
/// picks a halo value per waypoint scale (smaller as the symbol grows)
/// so the on-screen glow stays a roughly constant pixel size after the
/// annotation view's transform is applied.
struct TacticalControlMeasureSymbolView: View {
    let measure: TacticalControlMeasure
    /// Clockwise rotation in degrees. 0 = canonical orientation.
    var rotation: Double = 0
    var size: CGFloat = 56
    /// Per-shadow Gaussian radius (points). 0 = no halo. Three
    /// shadows are stacked at this radius to accumulate alpha.
    var halo: CGFloat = 2

    var body: some View {
        // Canvas grows with halo so the glow has room to render
        // without being clipped at the bitmap edge.
        let pad = max(halo + 1, 1)
        let canvas = size + 2 * pad
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

    @ViewBuilder
    private func applyHalo<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if halo < 0.05 {
            content()
        } else {
            // Three stacked Gaussians accumulate alpha into a definite
            // glow that reads against busy satellite imagery.
            content()
                .shadow(color: .white, radius: halo)
                .shadow(color: .white, radius: halo)
                .shadow(color: .white, radius: halo * 0.75)
        }
    }
}

@MainActor
enum TacticalControlMeasureRenderer {
    /// Canonical symbol size in points (before halo padding). Symbol
    /// scaling at runtime is done via the annotation view's transform.
    static let baseSize: CGFloat = 64

    private struct Key: Hashable {
        let measure: TacticalControlMeasure
        let rotationCentideg: Int   // 0..35999, 1/100 of a degree
        let haloHalfPoints: Int     // halo × 2, rounded → 0.5pt granularity
    }
    private static var cache: [Key: UIImage] = [:]

    /// Render a tactical-symbol bitmap with the given baked halo
    /// width. Cache holds one entry per (measure, rotation, halo) —
    /// the halo is quantised to 0.5pt steps so camera-driven scale
    /// changes hit the cache the vast majority of the time.
    static func image(for measure: TacticalControlMeasure,
                      rotation: Double = 0,
                      halo: CGFloat = 2) -> UIImage? {
        let normalized = ((rotation.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let safeHalo = max(0, halo)
        let key = Key(
            measure: measure,
            rotationCentideg: Int((normalized * 100).rounded()),
            haloHalfPoints: Int((safeHalo * 2).rounded())
        )
        if let cached = cache[key] { return cached }
        let view = TacticalControlMeasureSymbolView(
            measure: measure,
            rotation: normalized,
            size: baseSize,
            halo: safeHalo
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        let img = renderer.uiImage
        if let img { cache[key] = img }
        return img
    }
}
