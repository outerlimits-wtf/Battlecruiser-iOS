import SwiftUI
import DesignSystem
import PubDBModels

/// Rank, picture, then the name on its own line with pubs and when last under it,
/// and the level below that. The total sits on the right with what makes it up.
/// The name never shares its line with anything, so long handles don't wrap a
/// letter at a time. At accessibility sizes the numbers move under the name.
struct LeaderboardRow: View {
    let contributor: Leaderboard.Contributor

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.m) {
            RankBadge(contributor.rank)
                .padding(.top, 4)
            Avatar(url: contributor.avatarURL, name: contributor.name, size: .sm)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Metrics.s) {
                    who
                    numbers(alignment: .leading)
                }
                Spacer(minLength: 0)
            } else {
                who.layoutPriority(1)
                Spacer(minLength: Metrics.s)
                numbers(alignment: .trailing).fixedSize()
            }
        }
        .padding(.horizontal, Metrics.l)
        .padding(.vertical, Metrics.m)
        .accessibilityElement(children: .combine)
    }

    private var who: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contributor.name)
                .font(Typography.rowTitle)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .truncationMode(.middle)
            Text("\(contributor.pubs) \(contributor.pubs == 1 ? "pub" : "pubs") · \(contributor.agoLabel)")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)
            if let level = contributor.level {
                LevelBadge(level).padding(.top, 2)
            }
        }
    }

    private func numbers(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text("\(contributor.total)")
                .font(Typography.rowTitle)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Group {
                if contributor.reviews > 0 {
                    Text("\(contributor.contributions) added")
                    Text("\(contributor.reviews) \(contributor.reviews == 1 ? "review" : "reviews")")
                } else {
                    Text("added")
                }
            }
            .font(Typography.secondary)
            .monospacedDigit()
            .foregroundStyle(Palette.inkMuted)
        }
    }
}
