import SwiftUI
import UIKit

/// Renders a `TacticalControlMeasure` from the bundled SVG asset in
/// `Assets.xcassets/AppSymbols/`. SVGs are generated from the official
/// US Army C5ISR renderer (mil-sym-ts, MIT-licensed) and bundled at
/// build time — they're authoritative MIL-STD-2525D geometry.
struct TacticalControlMeasureSymbolView: View {
    let measure: TacticalControlMeasure
    var size: CGFloat = 56

    var body: some View {
        Image("AppSymbols/\(measure.assetName)")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.black)
            .frame(width: size, height: size)
            .padding(2)
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
    }
}

@MainActor
enum TacticalControlMeasureRenderer {
    private static var cache: [TacticalControlMeasure: UIImage] = [:]

    static func image(for measure: TacticalControlMeasure, size: CGFloat = 64) -> UIImage? {
        if let cached = cache[measure] { return cached }
        let view = TacticalControlMeasureSymbolView(measure: measure, size: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        let img = renderer.uiImage
        if let img { cache[measure] = img }
        return img
    }
}
