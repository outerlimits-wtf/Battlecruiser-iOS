import SwiftUI
import Account
import AppEnvironment
import DesignSystem

/// The Me tab: the account, how the app looks, and what this is.
public struct MeScreen: View {
    private let session: SessionModel
    private let profileDestination: (ProfileLink) -> AnyView
    private let notifications: NotificationsModel?
    @State private var path = NavigationPath()
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    /// - Parameter profileDestination: Someone's profile, from the Profile
    ///   feature, which this module doesn't import.
    public init(
        session: SessionModel,
        notifications: NotificationsModel? = nil,
        profileDestination: @escaping (ProfileLink) -> AnyView
    ) {
        self.session = session
        self.notifications = notifications
        self.profileDestination = profileDestination
    }

    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.xl) {
                    AccountBlock(session: session, onOpenProfile: { path.append(ProfileLink($0)) })
                    if let notifications, session.isSignedIn {
                        PushSettings(model: notifications)
                    }
                    VStack(alignment: .leading, spacing: Metrics.s) {
                        SectionHeader("Appearance")
                        Picker("Appearance", selection: $theme) {
                            ForEach(ThemePreference.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    NavigationLink {
                        AboutPage()
                    } label: {
                        MenuRow(emoji: "ℹ️", title: "About", blurb: "What this is, and why you should care")
                    }
                    .buttonStyle(.plain)
                    Text("PubDB · © OpenStreetMap contributors, ODbL")
                        .font(Typography.micro)
                        .foregroundStyle(Palette.inkFaint)
                }
                .padding(Metrics.l)
            }
            .background(Palette.canvas)
            .navigationTitle("Me")
            .navigationDestination(for: ProfileLink.self, destination: profileDestination)
        }
    }
}
