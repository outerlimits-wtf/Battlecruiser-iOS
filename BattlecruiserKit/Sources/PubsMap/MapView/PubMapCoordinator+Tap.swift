import MapKit
import SwiftUI
import PubDBModels

/// Tapping a dot, which has no view of its own to tap.
extension PubMapCoordinator {

    // MARK: - Tapping a dot

    @objc func tapped(_ recognizer: UITapGestureRecognizer) {
        guard let mapView, recognizer.state == .ended else { return }
        let location = recognizer.location(in: mapView)
        // A tap on a full pin or the user's dot belongs to that view.
        var hit = mapView.hitTest(location, with: nil)
        while let view = hit {
            if view is MKAnnotationView { return }
            hit = view.superview
        }
        let pin = DotHitTest.nearest(to: location, in: pins, excluding: Set(annotations.keys)) { pin in
            mapView.convert(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), toPointTo: mapView)
        }
        if let pin {
            onSelect(pin)
        }
    }
}
