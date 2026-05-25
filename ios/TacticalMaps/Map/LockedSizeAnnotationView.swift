import MapKit
import UIKit

/// `MKAnnotationView` for tactical-symbol images that scales with the
/// map's zoom level via `applyZoomScale(_:)` (called from
/// `MapContainerView.Coordinator` on every camera change).
///
/// The white outline is baked into the bitmap by
/// `TacticalControlMeasureSymbolView`; this view just hosts the image
/// and applies the transform. Bounds match the image exactly so
/// MapKit's hit-test target equals the visible symbol — no slack,
/// no enlarged frames swallowing taps on neighbouring annotations.
final class LockedSizeAnnotationView: MKAnnotationView {

    /// Native point size of the underlying image (before any zoom
    /// scaling). nil until `setSymbolImage` has run.
    private(set) var nativeImageSize: CGSize?

    /// Install the symbol image and pin the view's bounds to its
    /// point size.
    func setSymbolImage(_ img: UIImage?) {
        self.image = img
        if let size = img?.size {
            nativeImageSize = size
            self.bounds = CGRect(origin: bounds.origin, size: size)
        } else {
            nativeImageSize = nil
        }
        // Reset transform so a recycled view from the dequeue pool
        // doesn't carry a stale zoom scale from a previous use.
        self.transform = .identity
    }

    /// Apply a uniform scale to the view via its `transform`. Called
    /// on every map-camera change so the symbol tracks zoom.
    func applyZoomScale(_ scale: CGFloat) {
        self.transform = CGAffineTransform(scaleX: max(scale, 0.01),
                                            y: max(scale, 0.01))
    }
}
