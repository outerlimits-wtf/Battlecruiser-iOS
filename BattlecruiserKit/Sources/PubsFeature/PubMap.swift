import MapKit
import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// The map: the user's blue dot, a 🚢 for every pub, and the standard controls
/// (decision D21). Reports the area it settles on; owns no state of its own.
struct PubMap: View {
    @Binding var position: MapCameraPosition
    let pubs: [PubSummary]
    let onAreaChange: (BoundingBox) -> Void

    var body: some View {
        Map(position: $position) {
            ForEach(pinsInDrawOrder) { pub in
                Annotation(pub.name, coordinate: CLLocationCoordinate2D(latitude: pub.lat, longitude: pub.lon)) {
                    // ShipPin is decorative; this wrapper is what VoiceOver reads.
                    ZStack {
                        ShipPin(emphasis: PinEmphasis(pub))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(pub.name), \(pub.open.label)")
                }
                .annotationTitles(.hidden)
            }
            // Declared last so the blue dot is never covered by a pin.
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            onAreaChange(BoundingBox(context.region))
        }
    }

    /// Later annotations draw on top, so quiet pins go first and open ones last.
    /// Ties keep display order.
    private var pinsInDrawOrder: [PubSummary] {
        pubs.enumerated()
            .sorted { first, second in
                let firstOrder = PinEmphasis(first.element).drawOrder
                let secondOrder = PinEmphasis(second.element).drawOrder
                if firstOrder != secondOrder {
                    return firstOrder < secondOrder
                }
                return first.offset < second.offset
            }
            .map { $0.element }
    }
}

extension BoundingBox {
    /// The area a MapKit region covers.
    init(_ region: MKCoordinateRegion) {
        self.init(
            center: Coordinate(latitude: region.center.latitude, longitude: region.center.longitude),
            latitudeDelta: region.span.latitudeDelta,
            longitudeDelta: region.span.longitudeDelta
        )
    }
}
