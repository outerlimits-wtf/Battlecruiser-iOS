import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// Someone's page, as the web's: who they are, follow, what they've done,
/// how much of London they've drunk in, their reviews and their pubs.
public struct ProfileScreen: View {
    private let source: any ProfileSource
    private let canFollow: Bool
    private let onOpenPub: (String, String) -> Void
    @State private var remote: RemoteValue<Profile>
    @State private var tab = ProfileTab.reviews

    /// - Parameters:
    ///   - canFollow: Signed in, so Follow is offered (never on your own page).
    ///   - onOpenPub: Open a pub by id and name.
    public init(username: String, source: any ProfileSource, canFollow: Bool, onOpenPub: @escaping (String, String) -> Void) {
        self.source = source
        self.canFollow = canFollow
        self.onOpenPub = onOpenPub
        _remote = State(initialValue: RemoteValue { try await source.fetchProfile(username) })
    }

    public var body: some View {
        ScrollView {
            if let profile = remote.value {
                VStack(alignment: .leading, spacing: Metrics.xl) {
                    ProfileHeader(profile: profile, source: source, canFollow: canFollow && !profile.isSelf)
                    StatTiles(stats: profile.stats)
                    if let coverage = profile.coverage, profile.stats.visited > 0 {
                        CoverageCard(coverage)
                    }
                    Picker("Show", selection: $tab) {
                        Text("Reviews (\(profile.stats.reviews))").tag(ProfileTab.reviews)
                        Text("Been here (\(profile.stats.visited))").tag(ProfileTab.visited)
                    }
                    .pickerStyle(.segmented)
                    ProfileTabContent(profile: profile, tab: tab, onOpenPub: onOpenPub)
                }
                .padding(Metrics.l)
            } else if let error = remote.state.error {
                StateView(.error(message: error.userMessage, retry: { Task { await remote.load() } }))
            } else {
                StateView(.loading(rows: 3))
            }
        }
        .background(Palette.canvas)
        .navigationTitle(remote.value?.user.label ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { if remote.value == nil { await remote.load() } }
        .refreshable { await remote.load() }
    }
}
