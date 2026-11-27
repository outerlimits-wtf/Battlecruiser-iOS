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

    /// H7 (S12): a write's `201` with the pub under `pub`, built from the detail
    /// fixture as the server sends it. A `202` has neither key.
    @Test func aWriteCarriesTheUpdatedPub() throws {
        let pub = try JSONSerialization.jsonObject(with: Fixture.data("pub-detail-earl-ferrers-1127"))
        let body: [String: Any] = ["id": 2053, "field": "guinness_price", "value": "620", "pub": pub]
        let data = try JSONSerialization.data(withJSONObject: body)
        let result = try JSONDecoder().decode(WriteResult.self, from: data)
        #expect(result.pub?.id == "way/1223071579")
        #expect(!result.queued)

        let queued = try JSONDecoder().decode(WriteResult.self, from: Data(#"{"queued":true,"message":"Sent to an admin."}"#.utf8))
        #expect(queued.pub == nil)
    }

    /// H8a (S4, S5): meta says where each editor goes and how to hint it.
    @Test func fieldsCarrySectionOrderHintsAndParts() throws {
        let meta = try Fixture.decode(Meta.self, from: "meta-1127")
        let fields = meta.contributableFields
        #expect(fields.allSatisfy { $0.section != nil && $0.order != nil })
        #expect(fields.allSatisfy { if case .other = $0.kind { false } else { true } })

        let quiz = try #require(fields.first { $0.key == "quiz_night_day" })
        #expect(quiz.kind == .weekday)
        let status = try #require(fields.first { $0.key == "status" })
        #expect(status.section == .listing)
        #expect(status.parts.map(\.key) == ["state", "year", "became"])
        #expect(status.parts.first?.optional == false)
        let website = try #require(fields.first { $0.key == "website" })
        #expect(website.placeholder != nil && website.maxLength != nil)
    }

    /// H8a (S3, S4): the pub says what each field holds now, and which night it is.
    @Test func detailCarriesEditableValuesAndTheNight() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-earl-ferrers-1127")
        let meta = try Fixture.decode(Meta.self, from: "meta-1127")
        #expect(Set(detail.editable.keys) == Set(meta.contributableFields.map(\.key)))
        #expect(detail.editable["guinness_price"]?.display?.hasPrefix("£") == true)
        #expect(detail.editable["last_orders"]?.value == nil)
        // Captured for a Thursday evening.
        #expect(detail.session?.day == 3)
        #expect(detail.session?.short == "Thu")

        let old = try Fixture.decode(PubDetail.self, from: "pub-detail-earl-ferrers")
        #expect(old.editable.isEmpty)
        #expect(old.session == nil)
    }
}
