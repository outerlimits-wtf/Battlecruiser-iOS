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
    @State var meta: MetaStore
    @State var session: SessionModel
    @State var marks: MarksModel
    @State var notifications: NotificationsModel
    @State var push = PushInbox.shared
    @State var location = LocationModel()
    @State var pubs: PubsModel
    @State var pins: PinsModel
    @State var detail: PubDetailModel
    @State var tab: RootTab = DebugLaunch.tab ?? .map
    /// A profile opened from the pub panel, which has no stack to push onto.
    @State var presentedProfile: ProfileLink?
    @Environment(\.scenePhase) private var scenePhase

    let build = AppVersion.current()
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    let client: PubDBClient

    public init(dependencies: AppDependencies) {
        client = dependencies.client
        _meta = State(initialValue: MetaStore(source: dependencies.client))
        _session = State(initialValue: SessionModel(source: dependencies.client, auth: dependencies.auth))
        _marks = State(initialValue: MarksModel(source: dependencies.client))
        _notifications = State(initialValue: NotificationsModel(source: dependencies.client))
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
        .task(id: session.user?.id) {
            await accountChanged()
        }
        .onChange(of: push.deviceToken) { _, token in
            guard let token, session.isSignedIn else { return }
            Task { await notifications.register(deviceToken: token, environment: PushPermission.environment) }
        }
        .onChange(of: notifications.unread) { _, count in PushPermission.setBadge(count) }
        .onChange(of: push.tapped) { _, route in
            guard let route else { return }
            push.tapped = nil
            openPush(route)
        }
    }
}


#Preview("Live data") {
    RootView(dependencies: .preview)
}
