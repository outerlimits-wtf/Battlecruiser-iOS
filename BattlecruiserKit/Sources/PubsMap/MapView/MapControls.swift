import MapKit
import UIKit

/// Apple's locate-me button and compass, placed where the web puts its own
/// controls: bottom right, clear of the sheet's peek.
enum MapControls {
    static func install(on mapView: MKMapView) {
        let locate = MKUserTrackingButton(mapView: mapView)
        locate.backgroundColor = .systemBackground
        locate.layer.cornerRadius = 12
        locate.layer.cornerCurve = .continuous
        locate.translatesAutoresizingMaskIntoConstraints = false

        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .adaptive
        compass.translatesAutoresizingMaskIntoConstraints = false

        mapView.addSubview(locate)
        mapView.addSubview(compass)
        let guide = mapView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            locate.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
            locate.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -104),
            locate.widthAnchor.constraint(equalToConstant: 44),
            locate.heightAnchor.constraint(equalToConstant: 44),
            compass.centerXAnchor.constraint(equalTo: locate.centerXAnchor),
            compass.bottomAnchor.constraint(equalTo: locate.topAnchor, constant: -12),
        ])
    }
}
