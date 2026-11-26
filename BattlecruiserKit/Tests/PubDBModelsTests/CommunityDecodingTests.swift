import Foundation
import Testing
@testable import PubDBModels

/// The feed, leaderboard and a board, from production (2026-11-26).
struct CommunityDecodingTests {
    @Test func theFeedHasFactsAndReviewsReadyToShow() throws {
        let feed = try Fixture.decode(Feed.self, from: "feed")

        #expect(!feed.updates.isEmpty)
        for entry in feed.updates {
            if entry.isReview {
                #expect(entry.rating != nil)
            } else {
                #expect(entry.fieldLabel != nil && entry.displayValue != nil)
            }
        }
        #expect(Set(feed.updates.map(\.id)).count == feed.updates.count)
    }

    @Test func theLeaderboardIsRankedWithTotals() throws {
        let board = try Fixture.decode(Leaderboard.self, from: "leaderboard")

        #expect(board.contributors.first?.rank == 1)
        #expect(board.totals.people > 0)
    }

    @Test func aBoardKeepsTheServersOrderAndLabels() throws {
        let board = try Fixture.decode(Board.self, from: "board-cheapest")

        #expect(board.board.key == "cheapest")
        #expect(board.entries.map(\.rank) == board.entries.map(\.rank).sorted())
        #expect(board.entries.allSatisfy { !$0.value.isEmpty })
        #expect(!board.empty.title.isEmpty)
    }
}
