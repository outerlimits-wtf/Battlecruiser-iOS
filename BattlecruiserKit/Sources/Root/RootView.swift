import SwiftUI
import AppEnvironment
import PubDBClient
import PubDBModels
import PubDetailFeature
import PubsFeature
import UserLocation

/// The whole app. Owns the state features share (the server's lists, the
/// user's location, the selected pub) and wires the features together, so no
/// feature has to import another.
public struct RootView: View {
    @State private var meta: MetaStore
    @State private var location = LocationModel()
    @State private var pubs: PubsModel
    @State private var detail: PubDetailModel
    @Environment(\.scenePhase) private var scenePhase

    private let build = AppVersion.current()

    public init(dependencies: AppDependencies) {
        _meta = State(initialValue: MetaStore(source: dependencies.client))
        _pubs = State(initialValue: PubsModel(source: dependencies.client))
        _detail = State(initialValue: PubDetailModel(source: dependencies.client))
    }

    public var body: some View {
        Group {
            if meta.requiresUpdate(from: build) {
                UpdateRequiredView()
            } else {
                PubsMapScreen(
                    pubs: pubs,
                    userCoordinate: userCoordinate,
                    isLocationDenied: location.authorization == .denied,
                    selectedID: detail.selected?.id,
                    onSelect: { pub in detail.select(pub, near: userCoordinate) }
                )
                .sheet(isPresented: isShowingDetail) {
                    PubDetailSheet(model: detail)
                }
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

    /// Back from the background, everything on screen may be out of date: open
    /// states change with the clock. Location updates pause while away.
    private func handleScenePhase(from previous: ScenePhase, to phase: ScenePhase) {
        switch phase {
        case .active:
            location.start()
            if previous == .background {
                meta.refresh()
                pubs.refresh()
                detail.refresh()
            }
        case .background:
            location.stop()
        default:
            break
        }
    }

    /// The sheet is open while a pub is selected; dismissing it deselects.
    private var isShowingDetail: Binding<Bool> {
        Binding(
            get: { detail.selected != nil },
            set: { isShowing in
                if !isShowing { detail.deselect() }
            }
        )
    }

    /// The user's position in the client's terms (CoreLocation stays out of it).
    private var userCoordinate: Coordinate? {
        location.coordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

#Preview("Live data") {
    RootView(dependencies: .preview)
}
