import MapKit
import PubDBModels

/// The map's delegate: reports where it settles, and keeps the pins drawn.
public final class PubMapCoordinator: NSObject, MKMapViewDelegate {
    var onViewportChange: (MapViewport) -> Void = { _ in }
    var onSelect: (Pin) -> Void = { _ in }

    private weak var mapView: MKMapView?
    private var settleTask: Task<Void, Never>?

    /// How long the map must be still before it counts as settled (the web's 300 ms).
    static let settleDelay: Duration = .milliseconds(300)

    func attach(to mapView: MKMapView) {
        self.mapView = mapView
    }

    func update(pins: [Pin], selectedID: String?) {
        // Drawn from B3 (dots) and B4 (full pins).
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        settleTask?.cancel()
        settleTask = Task { [weak self, weak mapView] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled, let self, let mapView else { return }
            onViewportChange(MapViewport(mapView))
        }
    }
}
