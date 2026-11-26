import SwiftUI
import DesignSystem
import PubDBModels

/// Rank, picture, name, how many pubs and when last; what they've added on the right.
struct LeaderboardRow: View {
    let contributor: Leaderboard.Contributor

    var body: some View {
        HStack(spacing: Metrics.m) {
            RankBadge(contributor.rank)
            Avatar(url: contributor.avatarURL, name: contributor.name, size: .sm)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Metrics.s) {
                    Text(contributor.name).font(Typography.rowTitle).foregroundStyle(Palette.ink)
                    if let level = contributor.level { LevelBadge(level) }
                }
                Text("\(contributor.pubs) \(contributor.pubs == 1 ? "pub" : "pubs") · \(contributor.agoLabel)")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(contributor.total)").font(Typography.rowTitle).foregroundStyle(Palette.ink)
                Text(contributor.reviews > 0
                     ? "\(contributor.contributions) added · \(contributor.reviews) \(contributor.reviews == 1 ? "review" : "reviews")"
                     : "added")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
            }
        }
        .padding(.horizontal, Metrics.l)
        .padding(.vertical, Metrics.m)
        .accessibilityElement(children: .combine)
    }
}
