import UIKit
import MapKit

/// One vector shape (saved drawing, in-progress sketch, or measure line) to be
/// redrawn ABOVE the imported PDF.
struct PDFVectorShape {
    let coords: [CLLocationCoordinate2D]
    let isPolygon: Bool
    let style: DrawingStyle
    let isSelected: Bool
    /// In-progress sketches render dashed regardless of the saved dash pattern.
    let inProgress: Bool
}

/// Redraws drawing / measure / in-progress vector shapes as a transparent
/// subview layered ABOVE the imported-PDF image.
///
/// Shapes are `MKPolyline`/`MKPolygon` overlays, which MapKit renders in its
/// overlay layer — BENEATH the PDF `UIImageView` subview — so over a PDF they'd
/// be hidden (the user's drawings vanished under the imported map). This view
/// projects each shape's coordinates with `MKMapView.convert` every camera
/// change and strokes/fills them in Core Graphics, matching the MKOverlay
/// renderer's styling, so they sit on top of the PDF. Used only while a PDF is
/// active; the plain-basemap path keeps the cheaper MKOverlay renderer.
final class DrawingsOverlayView: UIView {

    private weak var mapView: MKMapView?
    private var shapes: [PDFVectorShape] = []

    init(mapView: MKMapView) {
        self.mapView = mapView
        super.init(frame: mapView.bounds)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false   // taps fall through to the map
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func update(shapes: [PDFVectorShape]) {
        self.shapes = shapes
        setNeedsDisplay()
    }

    /// Re-project against the current camera (geometry unchanged).
    func reproject() { setNeedsDisplay() }

    func clear() {
        guard !shapes.isEmpty else { return }
        shapes = []
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let mv = mapView else { return }
        for shape in shapes where shape.coords.count >= 2 {
            let pts = shape.coords.map { mv.convert($0, toPointTo: self) }
            let path = UIBezierPath()
            path.move(to: pts[0])
            for p in pts.dropFirst() { path.addLine(to: p) }
            if shape.isPolygon { path.close() }

            // Fill (polygons) — matches MapContainerCoordinator+Rendering: the
            // fill brightens slightly when selected and is capped at 0.6 alpha.
            if shape.isPolygon {
                let fillHex = shape.style.fillColorHex ?? shape.style.strokeColorHex
                let alpha = min(shape.style.fillOpacity * (shape.isSelected ? 1.6 : 1.0), 0.6)
                UIColor(hex: fillHex, alpha: alpha).setFill()
                path.fill()
            }

            // Stroke — selection bumps the width by 3pt; in-progress is dashed.
            UIColor(hex: shape.style.strokeColorHex).setStroke()
            path.lineWidth = CGFloat(shape.style.strokeWidth) + (shape.isSelected ? 3.0 : 0.0)
            let dash = shape.inProgress ? [6.0, 4.0] : shape.style.dashPattern
            if let dash, !dash.isEmpty {
                path.setLineDash(dash.map { CGFloat($0) }, count: dash.count, phase: 0)
            }
            path.stroke()
        }
    }
}
