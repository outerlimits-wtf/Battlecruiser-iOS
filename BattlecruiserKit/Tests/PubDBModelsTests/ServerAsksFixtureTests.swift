import Foundation
import Testing
@testable import PubDBModels

/// The `-1127` fixtures were captured on 2026-11-27, after the server asks
/// (S1–S16) were deployed (docs/test-fixtures.md). The older fixtures stay, so
/// both shapes keep decoding: every new field is optional.
///
/// Each Phase H step adds its own checks of the new fields here as it models them.
struct ServerAsksFixtureTests {
    @Test(arguments: [
        "pub-detail-earl-ferrers-1127",
        "pub-detail-the-bedford-1127",
        "pub-detail-sparse-british-legion-1127",
    ])
    func newDetailsDecode(name: String) throws {
        let detail = try Fixture.decode(PubDetail.self, from: name)
        #expect(detail.weekTable.count == 7)
    }

    @Test func newListDecodes() throws {
        let list = try Fixture.decode(PubList.self, from: "pubs-list-thu-2230-1127")
        #expect(!list.pubs.isEmpty)
    }

    @Test func newMetaDecodes() throws {
        let meta = try Fixture.decode(Meta.self, from: "meta-1127")
        #expect(!meta.contributableFields.isEmpty)
    }

    @Test func newLeaderboardDecodes() throws {
        let board = try Fixture.decode(Leaderboard.self, from: "leaderboard-1127")
        #expect(!board.contributors.isEmpty)
    }

    @Test func newProfileAndFeedDecode() throws {
        _ = try Fixture.decode(Profile.self, from: "profile-1127")
        _ = try Fixture.decode(Feed.self, from: "feed-1127")
    }
}
