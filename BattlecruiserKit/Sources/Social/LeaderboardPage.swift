import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// "Leaderboard": who has added the most, and the totals underneath.
struct LeaderboardPage: View {
    @State private var remote: RemoteValue<Leaderboard>

    init(source: any CommunitySource) {
        _remote = State(initialValue: RemoteValue { try await source.fetchLeaderboard() })
    }

    var body: some View {
        LoadableContent(remote: remote) { board in
            if board.contributors.isEmpty {
                StateView(.empty(emoji: "🏆", title: "Empty", body: "One pint reported and you're top of the table."))
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(board.contributors) { contributor in
                        if contributor.attribution.kind == "user" {
                            NavigationLink(value: ProfileLink(contributor.name)) {
                                LeaderboardRow(contributor: contributor)
                            }
                            .buttonStyle(.plain)
                        } else {
                            LeaderboardRow(contributor: contributor)
                        }
                    }
                    LeaderboardFooter(board: board).padding(Metrics.l)
                }
            }
        }
        .navigationTitle("Leaderboard")
    }
}
