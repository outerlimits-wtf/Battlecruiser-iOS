import MapKit
import SwiftUI
import PubDBModels

/// The map's delegate: reports where it settles, and keeps the pubs drawn.
public final class PubMapCoordinator: NSObject, MKMapViewDelegate {
    var onViewportChange: (MapViewport) -> Void = { _ in }
    var onSelect: (Pin) -> Void = { _ in }

    private weak var mapView: MKMapView?
    private var settleTask: Task<Void, Never>?
    private let dotsOverlay = PinDotsOverlay()
    private let dotsRenderer: PinDotsRenderer

    private(set) var pins: [Pin] = []
    /// Pubs currently drawn as full pins, so not as dots.
    private(set) var fullPinIDs: Set<String> = []
    private var colorScheme: ColorScheme?

    /// How long the map must be still before it counts as settled (the web's 300 ms).
    static let settleDelay: Duration = .milliseconds(300)

    override init() {
        dotsRenderer = PinDotsRenderer(overlay: dotsOverlay)
        super.init()
    }

    func attach(to mapView: MKMapView) {
        self.mapView = mapView
        mapView.addOverlay(dotsOverlay, level: .aboveRoads)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tap)
    }

    func update(pins: [Pin], selectedID: String?, colorScheme: ColorScheme) {
        let pinsChanged = pins != self.pins
        let schemeChanged = colorScheme != self.colorScheme
        self.pins = pins
        self.colorScheme = colorScheme
        if pinsChanged || schemeChanged {
            redrawDots()
        }
    }

    private func redrawDots() {
        guard let mapView else { return }
        dotsRenderer.show(DotSnapshot(pins: pins, hidden: fullPinIDs, traits: mapView.traitCollection))
    }

    // MARK: - Delegate

    public func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        overlay === dotsOverlay ? dotsRenderer : MKOverlayRenderer(overlay: overlay)
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        settleTask?.cancel()
        settleTask = Task { [weak self, weak mapView] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled, let self, let mapView else { return }
            onViewportChange(MapViewport(mapView))
        }
    }

    // MARK: - Tapping a dot

    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        guard let mapView, recognizer.state == .ended else { return }
        let location = recognizer.location(in: mapView)
        // A tap on a full pin or the user's dot belongs to that view.
        if let hit = mapView.hitTest(location, with: nil), hit is MKAnnotationView || hit.superview is MKAnnotationView {
            return
        }
        let pin = DotHitTest.nearest(to: location, in: pins, excluding: fullPinIDs) { pin in
            mapView.convert(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), toPointTo: mapView)
        }
        if let pin {
            onSelect(pin)
        }
    }
}
