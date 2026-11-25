import CoreLocation

/// The parts of `CLLocationManager` the model uses, so tests can substitute a fake.
protocol LocationManaging: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    /// The most recent position iOS knows, possibly from before this launch.
    var location: CLLocation? { get }
    var delegate: (any CLLocationManagerDelegate)? { get set }
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: LocationManaging {}
