import CoreLocation
import Observation

/// Whether the app may use the user's location, reduced to what the UI cares about.
public nonisolated enum LocationAuthorization: Equatable, Sendable {
    /// Not asked yet.
    case notDetermined
    /// Refused, or restricted by parental controls or device management.
    case denied
    /// Allowed while the app is in use (or always).
    case authorized

    public init(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            self = .authorized
        case .denied, .restricted:
            self = .denied
        @unknown default:
            self = .denied
        }
    }
}

/// Asks for location permission and tracks where the user is (decision D21).
///
/// The blue dot on the map is drawn by MapKit itself once permission is
/// granted; this model is what asks for that permission and supplies the
/// coordinate the app sends to the API for distances.
@Observable
public final class LocationModel: NSObject {
    public private(set) var authorization: LocationAuthorization
    /// The latest known position; nil until the first fix, or when denied.
    public private(set) var coordinate: CLLocationCoordinate2D? = nil

    @ObservationIgnored private let manager: any LocationManaging
    @ObservationIgnored private var wantsUpdates = false

    /// A model backed by the real `CLLocationManager`.
    public override convenience init() {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        // Ignore movement under 25 m: distances in the list don't need more, and
        // it avoids a stream of updates while standing still.
        manager.distanceFilter = 25
        self.init(manager: manager)
    }

    /// A position iOS already knows is used at once if it is at most this old,
    /// so a returning user's map opens where they are rather than in London.
    static let recentEnough: TimeInterval = 10 * 60

    init(manager: any LocationManaging) {
        self.manager = manager
        authorization = LocationAuthorization(manager.authorizationStatus)
        super.init()
        manager.delegate = self
        if authorization == .authorized,
           let known = manager.location,
           Date().timeIntervalSince(known.timestamp) <= Self.recentEnough {
            coordinate = known.coordinate
        }
    }

    /// Start following the user: asks for permission the first time, and starts
    /// location updates once it is granted. Does nothing if permission was refused;
    /// the map then stays on its fallback region.
    public func start() {
        wantsUpdates = true
        switch authorization {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorized: manager.startUpdatingLocation()
        case .denied: break
        }
    }

    /// Stop location updates, e.g. when the app goes to the background.
    public func stop() {
        wantsUpdates = false
        manager.stopUpdatingLocation()
    }

    // MARK: - Delegate events, on the main actor

    func authorizationChanged(to status: CLAuthorizationStatus) {
        authorization = LocationAuthorization(status)
        switch authorization {
        case .authorized:
            if wantsUpdates {
                manager.startUpdatingLocation()
            }
        case .denied:
            coordinate = nil
            manager.stopUpdatingLocation()
        case .notDetermined:
            break
        }
    }

    func locationUpdated(to newCoordinate: CLLocationCoordinate2D) {
        coordinate = newCoordinate
    }
}

// CLLocationManager calls its delegate on the thread it was created on, which is
// the main thread here (this model is main-actor isolated), so it is safe to hop
// straight onto the main actor.
extension LocationModel: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated { authorizationChanged(to: status) }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last?.coordinate else { return }
        MainActor.assumeIsolated { locationUpdated(to: latest) }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // Usually "no fix yet". Keep the last known coordinate; a refusal arrives
        // through the authorization callback instead.
    }
}

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
