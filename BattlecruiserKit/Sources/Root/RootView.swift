import SwiftUI
import AppEnvironment
import DesignSystem
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
    @State private var location = LocationModel()
    @State private var pubs: PubsModel
    @State private var pins: PinsModel
    @State private var detail: PubDetailModel
    @Environment(\.scenePhase) private var scenePhase

    private let build = AppVersion.current()

    public init(dependencies: AppDependencies) {
        _meta = State(initialValue: MetaStore(source: dependencies.client))
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
        }
        .onChange(of: scenePhase) { previous, phase in
            handleScenePhase(from: previous, to: phase)
        }
    }

    /// The web's side menu, as a tab bar (decision P6).
    private var tabs: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                mapTab
            }
            Tab("Social", systemImage: "person.2") {
                PlaceholderTab(emoji: "🏆", title: "Social", message: "Latest updates, the leaderboard and the boards land here.")
            }
            Tab("Lists", systemImage: "star") {
                PlaceholderTab(emoji: "⭐", title: "Lists", message: "Your hit list and the pubs you've been to land here.")
            }
            Tab("Me", systemImage: "person.crop.circle") {
                PlaceholderTab(emoji: "🍺", title: "Me", message: "Sign-in, your profile and settings land here.")
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
            panel: detail.selectedID == nil ? nil : PubDetailPanel(model: detail, onClose: detail.deselect),
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

    /// The user's position in the client's terms (CoreLocation stays out of it).
    private var userCoordinate: Coordinate? {
        location.coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

#Preview("Live data") {
    RootView(dependencies: .preview)
}
