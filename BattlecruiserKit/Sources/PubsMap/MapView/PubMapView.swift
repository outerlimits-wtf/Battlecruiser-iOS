import MapKit
import SwiftUI
import PubDBModels

/// The pubs map: `MKMapView` under SwiftUI, because only it can draw several
/// thousand pubs smoothly (spec, "Building a map"). Shows the user's location
/// with Apple's locate button, compass and scale, and reports where it settles.
public struct PubMapView: UIViewRepresentable {
    let pins: [Pin]
    let selectedID: String?
    @Binding var cameraRequest: MapCameraRequest?
    let base: MapBase
    let onViewportChange: (MapViewport) -> Void
    let onSelect: (Pin) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        pins: [Pin],
        selectedID: String?,
        cameraRequest: Binding<MapCameraRequest?>,
        base: MapBase = .appleMuted,
        onViewportChange: @escaping (MapViewport) -> Void,
        onSelect: @escaping (Pin) -> Void
    ) {
        self.pins = pins
        self.selectedID = selectedID
        _cameraRequest = cameraRequest
        self.base = base
        self.onViewportChange = onViewportChange
        self.onSelect = onSelect
    }

    public func makeCoordinator() -> PubMapCoordinator {
        PubMapCoordinator()
    }

    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        base.configure(mapView)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.region = Self.london
        context.coordinator.attach(to: mapView)
        MapControls.install(on: mapView)
        return mapView
    }

    public func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onViewportChange = onViewportChange
        coordinator.onSelect = onSelect
        coordinator.update(pins: pins, selectedID: selectedID)
        if let request = cameraRequest {
            request.apply(to: mapView, animated: !reduceMotion)
            DispatchQueue.main.async { cameraRequest = nil }
        }
    }

    /// Where the map opens before it knows where the user is.
    static let london = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5098, longitude: -0.1257),
        latitudinalMeters: 3000,
        longitudinalMeters: 3000
    )
}
