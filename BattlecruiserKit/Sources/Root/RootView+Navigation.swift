import SwiftUI
import AppEnvironment
import DesignSystem
import Me
import Social
import Lists
import Profile
import PubDBClient
import PubDBModels
import PubDetailFeature
import PubsFeature
import PubsMap
import UserLocation

/// Lifecycle, and moving between tabs, pubs and profiles.
extension RootView {
    /// Back from the background, everything on screen may be out of date: open
    /// states change with the clock. Location updates pause while away.
    func handleScenePhase(from previous: ScenePhase, to phase: ScenePhase) {
        switch phase {
        case .active:
            location.start()
            if previous == .background {
                Task { await session.load() }
                meta.refresh()
                pins.refresh()
                pubs.refresh()
                detail.refresh()
            }
        case .background:
            location.stop()
        default:
            break
        }
    }

    /// A pin was tapped. Use its summary if the list already has it, so the
    /// sheet opens full; otherwise open on the name and load the rest.
    func select(_ pin: Pin) {
        if let summary = pubs.pubs.first(where: { $0.id == pin.id }) {
            detail.select(summary, near: userCoordinate)
        } else {
            detail.select(id: pin.id, name: pin.name, near: userCoordinate)
        }
    }

    /// Someone's profile, for whichever tab's stack asked.
    func profile(_ link: ProfileLink) -> AnyView {
        AnyView(ProfileScreen(
            username: link.username,
            source: client,
            canFollow: session.isSignedIn,
            onOpenPub: { id, name in open(PubLink(id: id, name: name)) }
        ))
    }

    /// Open a pub from another tab: on the map, in the panel.
    func open(_ pub: PubLink) {
        tab = .map
        detail.select(id: pub.id, name: pub.name, near: userCoordinate)
    }

    /// The user's position in the client's terms (CoreLocation stays out of it).
    var userCoordinate: Coordinate? {
        location.coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}
