import SwiftUI
import UIKit

/// Renders the pill-shaped abbreviation label drawn at the midpoint of a
/// tactical-task polyline (e.g. "CATK", "BLOCK", "SBF"). Cached because
/// MKAnnotationView refreshes can fire frequently.
@MainActor
enum TaskLabelRenderer {
    private static var cache: [String: UIImage] = [:]

    static func image(text: String, colorHex: String) -> UIImage? {
        let key = "\(colorHex)|\(text)"
        if let cached = cache[key] { return cached }
        let view = TaskLabelPill(text: text, color: Color(hex: colorHex))
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        let img = renderer.uiImage
        if let img { cache[key] = img }
        return img
    }
}

/// Small SwiftUI pill with a coloured background and white monospaced text.
/// Black border keeps it legible against bright satellite imagery.
private struct TaskLabelPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color)
            )
            .overlay(
                Capsule().stroke(.black, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 1.5, x: 0, y: 1)
    }
}
