import SwiftUI
import UIKit

/// NATO APP-6 / MIL-STD-2525 symbology, drawn from primitives so we don't
/// need a third-party APP-6 font or SVG library. For now we only handle the
/// **Infantry** function in **Friend** and **Hostile** affiliations, with the
/// echelons listed in `SymbolEchelon`. The same renderer is used for both
/// the map annotation image and the in-app picker icons.

enum SymbolAffiliation: Hashable {
    case friend, hostile

    /// APP-6 medium-intensity fill colour for the frame.
    /// Spec values: Friend = #80E0FF, Hostile = #FF8080.
    var fillColor: Color {
        switch self {
        case .friend:  return Color(red: 0x80/255, green: 0xE0/255, blue: 1.0)
        case .hostile: return Color(red: 1.0,       green: 0x80/255, blue: 0x80/255)
        }
    }

    /// Hex used by GeoJSON simplestyle export.
    var fillHex: String {
        switch self {
        case .friend:  return "#80E0FF"
        case .hostile: return "#FF8080"
        }
    }
}

enum SymbolEchelon: String, Hashable, CaseIterable {
    case section, platoon, company, regiment, brigade

    var displayName: String {
        switch self {
        case .section:  return "Section"
        case .platoon:  return "Platoon"
        case .company:  return "Company"
        case .regiment: return "Regiment"
        case .brigade:  return "Brigade"
        }
    }
}

/// Identity of a military symbol — a small value type so the same
/// renderer can be cached/re-used and shared between map markers and picker
/// rows. `function` is implicit (`infantry`) for now.
struct MilitarySymbolSpec: Hashable {
    let affiliation: SymbolAffiliation
    let echelon:     SymbolEchelon
}

// MARK: - Rendering

/// SwiftUI view that draws the APP-6 symbol. Use directly in lists / pickers,
/// or hand to `MilitarySymbolRenderer.image(for:)` to bake into a UIImage for
/// a MapKit annotation.
struct MilitarySymbolView: View {
    let spec: MilitarySymbolSpec
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let echelonH: CGFloat = h * 0.22
            let gap: CGFloat      = h * 0.06

            // Frame area
            let frameTop = echelonH + gap
            let frameBottom = h - 2
            let frameH = frameBottom - frameTop

            switch spec.affiliation {
            case .friend:
                // Rectangle, ~1.5:1 ratio
                let frameW = min(w - 4, frameH * 1.5)
                let frameX = (w - frameW) / 2
                let rect = CGRect(x: frameX, y: frameTop, width: frameW, height: frameH)
                drawFriendFrame(ctx: ctx, in: rect)
            case .hostile:
                // Diamond inscribed in a square
                let side = min(w - 6, frameH)
                let rect = CGRect(x: (w - side) / 2,
                                  y: frameTop + (frameH - side) / 2,
                                  width: side, height: side)
                drawHostileDiamond(ctx: ctx, in: rect)
            }

            // Echelon centred above the frame
            let echelonRect = CGRect(x: 0, y: 0, width: w, height: echelonH)
            drawEchelon(ctx: ctx, echelon: spec.echelon, in: echelonRect)
        }
        .frame(width: size, height: size)
        // Soft shadow makes it legible on bright satellite imagery.
        .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1)
    }

    // MARK: Frame drawing

    private func drawFriendFrame(ctx: GraphicsContext, in rect: CGRect) {
        let path = Path(rect)
        ctx.fill(path,   with: .color(spec.affiliation.fillColor))
        ctx.stroke(path, with: .color(.black), lineWidth: 1.5)

        // Infantry function: two diagonals corner-to-corner.
        var glyph = Path()
        glyph.move(to:    CGPoint(x: rect.minX, y: rect.minY))
        glyph.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        glyph.move(to:    CGPoint(x: rect.maxX, y: rect.minY))
        glyph.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        ctx.stroke(glyph, with: .color(.black), lineWidth: 2)
    }

    private func drawHostileDiamond(ctx: GraphicsContext, in rect: CGRect) {
        let cx = rect.midX, cy = rect.midY
        let r  = rect.width / 2

        var diamond = Path()
        diamond.move(to:    CGPoint(x: cx,     y: cy - r))
        diamond.addLine(to: CGPoint(x: cx + r, y: cy))
        diamond.addLine(to: CGPoint(x: cx,     y: cy + r))
        diamond.addLine(to: CGPoint(x: cx - r, y: cy))
        diamond.closeSubpath()
        ctx.fill(diamond,   with: .color(spec.affiliation.fillColor))
        ctx.stroke(diamond, with: .color(.black), lineWidth: 1.5)

        // Infantry function: the canonical two-diagonal X lives in the
        // frame's local coords, so after the 45° rotation it appears as
        // horizontal + vertical lines through the centre, capped to the
        // inscribed square's bounds.
        let inset = r * sqrt(2) / 2
        var glyph = Path()
        glyph.move(to:    CGPoint(x: cx - inset, y: cy))
        glyph.addLine(to: CGPoint(x: cx + inset, y: cy))
        glyph.move(to:    CGPoint(x: cx,         y: cy - inset))
        glyph.addLine(to: CGPoint(x: cx,         y: cy + inset))
        ctx.stroke(glyph, with: .color(.black), lineWidth: 2)
    }

    // MARK: Echelon drawing

    private func drawEchelon(ctx: GraphicsContext, echelon: SymbolEchelon, in rect: CGRect) {
        let cx = rect.midX
        let cy = rect.midY
        let ink: GraphicsContext.Shading = .color(.black)

        switch echelon {
        case .section:
            drawDots(count: 2, ctx: ctx, cx: cx, cy: cy, radius: 2, spacing: 7, ink: ink)
        case .platoon:
            drawDots(count: 3, ctx: ctx, cx: cx, cy: cy, radius: 2, spacing: 6, ink: ink)
        case .company:
            drawBars(count: 1, ctx: ctx, cx: cx, top: rect.minY + 1, height: rect.height - 2, barW: 2.5, spacing: 0, ink: ink)
        case .regiment:
            drawBars(count: 3, ctx: ctx, cx: cx, top: rect.minY + 1, height: rect.height - 2, barW: 2.5, spacing: 5, ink: ink)
        case .brigade:
            drawX(ctx: ctx, cx: cx, top: rect.minY + 1, size: rect.height - 2, ink: ink)
        }
    }

    private func drawDots(count: Int, ctx: GraphicsContext,
                          cx: CGFloat, cy: CGFloat,
                          radius: CGFloat, spacing: CGFloat,
                          ink: GraphicsContext.Shading) {
        let totalWidth = CGFloat(count - 1) * spacing
        for i in 0..<count {
            let x = cx - totalWidth / 2 + CGFloat(i) * spacing
            let dot = Path(ellipseIn: CGRect(x: x - radius, y: cy - radius,
                                             width: radius * 2, height: radius * 2))
            ctx.fill(dot, with: ink)
        }
    }

    private func drawBars(count: Int, ctx: GraphicsContext,
                          cx: CGFloat, top: CGFloat, height: CGFloat,
                          barW: CGFloat, spacing: CGFloat,
                          ink: GraphicsContext.Shading) {
        let totalWidth = CGFloat(count - 1) * spacing
        for i in 0..<count {
            let x = cx - totalWidth / 2 + CGFloat(i) * spacing
            let bar = Path(CGRect(x: x - barW / 2, y: top, width: barW, height: height))
            ctx.fill(bar, with: ink)
        }
    }

    private func drawX(ctx: GraphicsContext,
                       cx: CGFloat, top: CGFloat, size: CGFloat,
                       ink: GraphicsContext.Shading) {
        var path = Path()
        path.move(to:    CGPoint(x: cx - size / 2, y: top))
        path.addLine(to: CGPoint(x: cx + size / 2, y: top + size))
        path.move(to:    CGPoint(x: cx + size / 2, y: top))
        path.addLine(to: CGPoint(x: cx - size / 2, y: top + size))
        ctx.stroke(path, with: ink, lineWidth: 2)
    }
}

// MARK: - UIImage renderer for MapKit

@MainActor
enum MilitarySymbolRenderer {

    private static var cache: [MilitarySymbolSpec: UIImage] = [:]

    /// Returns a cached UIImage of the given symbol, suitable for use as
    /// `MKAnnotationView.image`. Cached because building an ImageRenderer
    /// on every annotation refresh is wasteful.
    static func image(for spec: MilitarySymbolSpec, size: CGFloat = 56) -> UIImage? {
        if let cached = cache[spec] { return cached }
        let view = MilitarySymbolView(spec: spec, size: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        let img = renderer.uiImage
        if let img { cache[spec] = img }
        return img
    }
}
