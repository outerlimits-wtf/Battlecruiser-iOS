import CoreLocation
import Testing
@testable import UserLocation

/// The permission flow behind the user-location dot (decision D21), against a
/// fake location manager so nothing prompts and no real location is needed.
@MainActor
struct LocationModelTests {
    @Test func startAsksForPermissionTheFirstTime() {
        let manager = FakeLocationManager(status: .notDetermined)
        let model = LocationModel(manager: manager)

        model.start()

        #expect(manager.permissionRequests == 1)
        #expect(!manager.isUpdating)
    }

    @Test func startBeginsUpdatesWhenAlreadyAllowed() {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        let model = LocationModel(manager: manager)

        model.start()

        #expect(manager.permissionRequests == 0)
        #expect(manager.isUpdating)
    }

    @Test func startDoesNothingWhenRefused() {
        let manager = FakeLocationManager(status: .denied)
        let model = LocationModel(manager: manager)

        model.start()

        #expect(manager.permissionRequests == 0)
        #expect(!manager.isUpdating)
        #expect(model.authorization == .denied)
    }

    @Test func grantingPermissionAfterStartBeginsUpdates() {
        let manager = FakeLocationManager(status: .notDetermined)
        let model = LocationModel(manager: manager)
        model.start()

        model.authorizationChanged(to: .authorizedWhenInUse)

        #expect(model.authorization == .authorized)
        #expect(manager.isUpdating)
    }

    @Test func grantingPermissionWithoutStartDoesNotBeginUpdates() {
        let manager = FakeLocationManager(status: .notDetermined)
        let model = LocationModel(manager: manager)

        model.authorizationChanged(to: .authorizedWhenInUse)

        #expect(!manager.isUpdating)
    }

    @Test func revokingPermissionForgetsTheLocationAndStops() {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        let model = LocationModel(manager: manager)
        model.start()
        model.locationUpdated(to: CLLocationCoordinate2D(latitude: 51.4431, longitude: -0.1525))

        model.authorizationChanged(to: .denied)

        #expect(model.coordinate == nil)
        #expect(!manager.isUpdating)
    }

    @Test func locationUpdatesAreRecorded() {
        let model = LocationModel(manager: FakeLocationManager(status: .authorizedWhenInUse))

        model.locationUpdated(to: CLLocationCoordinate2D(latitude: 51.4431, longitude: -0.1525))

        let latitude = model.coordinate?.latitude
        #expect(latitude == 51.4431)
    }

    @Test func stopEndsUpdates() {
        let manager = FakeLocationManager(status: .authorizedWhenInUse)
        let model = LocationModel(manager: manager)
        model.start()

        model.stop()

        #expect(!manager.isUpdating)
    }

    @Test func modelBecomesTheManagersDelegate() {
        let manager = FakeLocationManager(status: .notDetermined)
        let model = LocationModel(manager: manager)

        #expect(manager.delegate === model)
    }

    @Test func aRecentKnownPositionIsUsedStraightAway() {
        let recent = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 51.4431, longitude: -0.1525),
            altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10,
            timestamp: Date().addingTimeInterval(-60)
        )
        let manager = FakeLocationManager(status: .authorizedWhenInUse, location: recent)

        let model = LocationModel(manager: manager)

        let latitude = model.coordinate?.latitude
        #expect(latitude == 51.4431)
    }

    @Test func anOldKnownPositionIsIgnored() {
        let stale = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 51.4431, longitude: -0.1525),
            altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10,
            timestamp: Date().addingTimeInterval(-3600)
        )
        let manager = FakeLocationManager(status: .authorizedWhenInUse, location: stale)

        let model = LocationModel(manager: manager)

        #expect(model.coordinate == nil)
    }

    @Test func aKnownPositionIsIgnoredWithoutPermission() {
        let recent = CLLocation(latitude: 51.4431, longitude: -0.1525)
        let manager = FakeLocationManager(status: .denied, location: recent)

        let model = LocationModel(manager: manager)

        #expect(model.coordinate == nil)
    }

    @Test func everyStatusMapsToWhatTheUICaresAbout() {
        #expect(LocationAuthorization(.notDetermined) == .notDetermined)
        #expect(LocationAuthorization(.authorizedWhenInUse) == .authorized)
        #expect(LocationAuthorization(.authorizedAlways) == .authorized)
        #expect(LocationAuthorization(.denied) == .denied)
        #expect(LocationAuthorization(.restricted) == .denied)
    }
}

/// Records what the model asks of it instead of touching Core Location.
final class FakeLocationManager: LocationManaging {
    var authorizationStatus: CLAuthorizationStatus
    var location: CLLocation?
    weak var delegate: (any CLLocationManagerDelegate)?
    private(set) var permissionRequests = 0
    private(set) var isUpdating = false

    init(status: CLAuthorizationStatus, location: CLLocation? = nil) {
        authorizationStatus = status
        self.location = location
    }

    func requestWhenInUseAuthorization() { permissionRequests += 1 }
    func startUpdatingLocation() { isUpdating = true }
    func stopUpdatingLocation() { isUpdating = false }
}
