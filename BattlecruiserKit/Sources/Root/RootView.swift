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

/// The whole app. Owns the state features share (the server's lists, the
/// user's location, the selected pub) and wires the features together, so no
/// feature has to import another.
public struct RootView: View {
    @State private var meta: MetaStore
    @State private var session: SessionModel
    @State private var location = LocationModel()
    @State private var pubs: PubsModel
    @State private var pins: PinsModel
    @State private var detail: PubDetailModel
    @State private var tab: RootTab = DebugLaunch.tab ?? .map
    @Environment(\.scenePhase) private var scenePhase

    private let build = AppVersion.current()
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    private let client: PubDBClient

    public init(dependencies: AppDependencies) {
        client = dependencies.client
        _meta = State(initialValue: MetaStore(source: dependencies.client))
        _session = State(initialValue: SessionModel(source: dependencies.client, auth: dependencies.auth))
        _pubs = State(initialValue: PubsModel(source: dependencies.client))
        _pins = State(initialValue: PinsModel(source: dependencies.client))
        _detail = State(initialValue: PubDetailModel(source: dependencies.client))
    }

    public var body: some View {
        Group {
            if meta.requiresUpdate(from: build) {
                UpdateRequiredView()
            } else {
                tabs
            }
        }
        .task {
            meta.load()
            location.start()
            await session.load()
            if let id = DebugLaunch.pubToOpen {
                detail.select(id: id, name: "…", near: nil)
            }
        }
        .onChange(of: scenePhase) { previous, phase in
            handleScenePhase(from: previous, to: phase)
        }
        .preferredColorScheme(theme.colorScheme)
    }

    /// The web's side menu, as a tab bar (decision P6).
    private var tabs: some View {
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
                    profileDestination: profile
                )
            }
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
                MeScreen(session: session, profileDestination: profile)
            }
        }
        .tint(Palette.beer)
    }

    private var mapTab: some View {
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
                meta: meta.meta,
                onClose: detail.deselect,
                onSelectPub: { pub in detail.select(pub, near: userCoordinate) }
            ),
            meta: meta.meta
        )
    }

    /// Back from the background, everything on screen may be out of date: open
    /// states change with the clock. Location updates pause while away.
    private func handleScenePhase(from previous: ScenePhase, to phase: ScenePhase) {
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
    private func select(_ pin: Pin) {
        if let summary = pubs.pubs.first(where: { $0.id == pin.id }) {
            detail.select(summary, near: userCoordinate)
        } else {
            detail.select(id: pin.id, name: pin.name, near: userCoordinate)
        }
    }

    /// Someone's profile, for whichever tab's stack asked.
    private func profile(_ link: ProfileLink) -> AnyView {
        AnyView(ProfileScreen(
            username: link.username,
            source: client,
            canFollow: session.isSignedIn,
            onOpenPub: { id, name in open(PubLink(id: id, name: name)) }
        ))
    }

    /// Open a pub from another tab: on the map, in the panel.
    private func open(_ pub: PubLink) {
        tab = .map
        detail.select(id: pub.id, name: pub.name, near: userCoordinate)
    }

    /// The user's position in the client's terms (CoreLocation stays out of it).
    private var userCoordinate: Coordinate? {
        location.coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

#Preview("Live data") {
    RootView(dependencies: .preview)
}
