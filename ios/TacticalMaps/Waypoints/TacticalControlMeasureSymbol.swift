import SwiftUI
import UIKit

/// Renders a `TacticalControlMeasure` from the bundled PNG / SVG asset
/// under `Assets.xcassets/AppSymbols/`. Pure black symbol on a
/// transparent background. No halo — instead, four zero-radius BLACK
/// offset shadows in the cardinal directions effectively thicken
/// every black line by ~1pt baked into the bitmap, so the symbol
/// reads better on satellite imagery without an outer glow.
struct TacticalControlMeasureSymbolView: View {
    let measure: TacticalControlMeasure
    /// Clockwise rotation in degrees. 0 = canonical orientation.
    var rotation: Double = 0
    var size: CGFloat = 56
    /// Extra room around the symbol so the thickening offsets aren't
    /// clipped at the bitmap edge.
    static let haloPadding: CGFloat = 2

    var body: some View {
        let canvas = size + 2 * Self.haloPadding
        return ZStack {
            thickenLines {
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

    /// Stack of zero-radius black shadows offset ±0.5pt in the four
    /// cardinal directions. The net effect is that every black pixel
    /// "grows" by 0.5pt in each direction, producing a ~1pt thicker
    /// line baked into the bitmap. Cleaner than a Gaussian — sharp
    /// edges, no blur, no halo.
    @ViewBuilder
    private func thickenLines<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let off: CGFloat = 0.5
        content()
            .shadow(color: .black, radius: 0, x:  off, y:  0)
            .shadow(color: .black, radius: 0, x: -off, y:  0)
            .shadow(color: .black, radius: 0, x:  0,   y:  off)
            .shadow(color: .black, radius: 0, x:  0,   y: -off)
    }
}

@MainActor
enum TacticalControlMeasureRenderer {
    /// Canonical symbol size in points. Symbol scaling at runtime
    /// happens via the annotation view's transform.
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
