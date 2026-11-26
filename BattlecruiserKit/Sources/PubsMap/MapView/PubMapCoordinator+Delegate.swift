import MapKit
import SwiftUI
import PubDBModels

/// MapKit's callbacks: renderers, pin views, selection, and settling.
extension PubMapCoordinator {

    // MARK: - Delegate

    public func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        overlay === dotsOverlay ? dotsRenderer : MKOverlayRenderer(overlay: overlay)
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? PinAnnotation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: PinAnnotationView.reuseIdentifier, for: annotation
        ) as? PinAnnotationView
        view?.configure(annotation.pin, isSelected: annotation.pin.id == selectedID, reduceMotion: reduceMotion)
        return view
    }

    public func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
        guard let annotation = annotation as? PinAnnotation else { return }
        // Selection is the app's, not MapKit's: no callout, just open the pub.
        mapView.deselectAnnotation(annotation, animated: false)
        onSelect(annotation.pin)
    }

    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // MapKit doesn't say who moved the map; a gesture in progress on its
        // content view means the person did.
        let gestures = mapView.subviews.first?.gestureRecognizers ?? []
        if gestures.contains(where: { $0.state == .began || $0.state == .changed || $0.state == .ended }) {
            isUserMove = true
        }
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        settleTask?.cancel()
        settleTask = Task { [weak self, weak mapView] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled, let self, let mapView else { return }
            let settled = MapViewport(mapView, movedByUser: isUserMove)
            isUserMove = false
            viewport = settled
            syncFullPins()
            onViewportChange(settled)
        }
    }
}
