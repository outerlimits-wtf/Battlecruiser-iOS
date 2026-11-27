import Foundation
import PubDBClient
import PubDBModels

/// Which pubs get a full pin rather than a dot (spec, "Building a map"): none
/// zoomed out; zoomed in, those in view plus a margin, capped, loudest kept.
/// The selected pub always gets one.
enum FullPinSelection {
    /// About the web's zoom 15, where a phone shows tens of pubs, not hundreds.
    static let maxMetresPerPoint: Double = 3.0
    /// The most full pins at once.
    static let cap = 300
    /// How far past the edges to look, as a fraction of the view (the web's 25%).
    static let margin = 0.25

    static func ids(
        for pins: [Pin],
        in viewport: MapViewport?,
        selectedID: String?
    ) -> Set<String> {
        var chosen: Set<String> = []
        if let viewport, viewport.metresPerPoint <= maxMetresPerPoint {
            let area = viewport.area.padded(by: margin)
            // Pins arrive quietest first; keep the loudest when over the cap.
            let inView = pins.filter { area.contains(latitude: $0.latitude, longitude: $0.longitude) }
            chosen = Set(inView.suffix(cap).map(\.id))
        }
        if let selectedID {
            chosen.insert(selectedID)
        }
        return chosen
    }
}

extension BoundingBox {
    func padded(by fraction: Double) -> BoundingBox {
        let dx = (east - west) * fraction
        let dy = (north - south) * fraction
        return BoundingBox(west: west - dx, south: south - dy, east: east + dx, north: north + dy)
    }

    func contains(latitude: Double, longitude: Double) -> Bool {
        longitude >= west && longitude <= east && latitude >= south && latitude <= north
    }
}
