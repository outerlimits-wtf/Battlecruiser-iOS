import CoreLocation

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
