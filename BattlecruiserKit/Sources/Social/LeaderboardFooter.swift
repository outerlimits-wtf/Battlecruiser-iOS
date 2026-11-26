import SwiftUI
import DesignSystem
import PubDBModels

/// The web's sentences under the table. S7 asks the server for them ready-made.
struct LeaderboardFooter: View {
    let board: Leaderboard

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            let things = board.totals.contributions + board.totals.reviews
            Text(board.totals.people == 1
                 ? "1 person has added \(things) things between them."
                 : "\(board.totals.people) people have added \(things) things between them.")
            if let imported = board.imported, imported.total > 0 {
                Text("Another \(imported.total) came from \(imported.label)'s own imports.")
            }
            if let anonymous = board.anonymous, anonymous.total > 0 {
                Text("\(anonymous.total) more were added before anyone had to say who they were. Oh those were the days.")
            }
        }
        .font(Typography.secondary)
        .foregroundStyle(Palette.inkMuted)
    }
}
