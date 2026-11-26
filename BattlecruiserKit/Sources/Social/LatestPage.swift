import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// "Latest updates": facts and reviews as they arrive. Signed in, the people
/// you follow too.
struct LatestPage: View {
    let source: any CommunitySource
    let isSignedIn: Bool
    let onOpenPub: (PubLink) -> Void

    @State private var following = false
    @State private var everyone: RemoteValue<Feed>
    @State private var followed: RemoteValue<Feed>

    init(source: any CommunitySource, isSignedIn: Bool, onOpenPub: @escaping (PubLink) -> Void) {
        self.source = source
        self.isSignedIn = isSignedIn
        self.onOpenPub = onOpenPub
        _everyone = State(initialValue: RemoteValue { try await source.fetchFeed(following: false) })
        _followed = State(initialValue: RemoteValue { try await source.fetchFeed(following: true) })
    }

    var body: some View {
        VStack(spacing: 0) {
            if isSignedIn {
                Picker("Whose", selection: $following) {
                    Text("Everyone").tag(false)
                    Text("Following").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(Metrics.l)
            }
            LoadableContent(remote: following ? followed : everyone) { feed in
                if feed.updates.isEmpty {
                    if following {
                        StateView(.empty(emoji: "👥", title: "Nobody followed yet", body: "Tap anyone's handle on the Leaderboard or in a pub's reviews to follow them."))
                    } else {
                        StateView(.empty(emoji: "🕑", title: "Nothing added yet", body: "The first pint reported or review written lands here straight away."))
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(feed.updates) { entry in
                            Button { onOpenPub(PubLink(id: entry.pub.id, name: entry.pub.name)) } label: {
                                FeedRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .id(following)
        }
        .background(Palette.canvas)
        .navigationTitle("Latest updates")
    }
}
