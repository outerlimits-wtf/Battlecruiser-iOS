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

/// The tab bar and what each tab shows.
extension RootView {
    /// The web's side menu, as a tab bar (decision P6).
    var tabs: some View {
        TabView(selection: $tab) {
            Tab("Map", systemImage: "map", value: RootTab.map) {
                mapTab
            }
            Tab("Social", systemImage: "person.2", value: RootTab.social) {
                SocialScreen(
                    source: client,
                    boards: meta.meta?.boards ?? [],
                    isSignedIn: session.isSignedIn,
                    location: userCoordinate,
                    onOpenPub: open,
                    profileDestination: profile,
                    notifications: session.isSignedIn ? notifications : nil
                )
            }
            .badge(notifications.unread)
            Tab("Lists", systemImage: "star", value: RootTab.lists) {
                ListsScreen(
                    source: client,
                    isSignedIn: session.isSignedIn,
                    location: userCoordinate,
                    onOpenPub: { id, name in open(PubLink(id: id, name: name)) }
                )
                .id(session.user?.id)
            }
            Tab("Me", systemImage: "person.crop.circle", value: RootTab.me) {
                MeScreen(session: session, notifications: notifications, profileDestination: profile)
            }
        }
        .tint(Palette.beer)
    }

    var mapTab: some View {
        PubsMapScreen(
            pubs: pubs,
            pins: pins,
            userCoordinate: userCoordinate,
            isLocationDenied: location.authorization == .denied,
            selectedID: detail.selectedID,
            onSelectPin: select,
            onSelectPub: { pub in detail.select(pub, near: userCoordinate) },
            panel: detail.selectedID == nil ? nil : PubDetailPanel(
                model: detail,
                context: PanelContext(session: session, marks: marks, meta: meta.meta, writer: client),
                onClose: detail.deselect,
                onSelectPub: { pub in detail.select(pub, near: userCoordinate) }
            ),
            meta: meta.meta,
            visitedIDs: marks.visited,
            onSearch: detail.deselect
        )
    }
}
