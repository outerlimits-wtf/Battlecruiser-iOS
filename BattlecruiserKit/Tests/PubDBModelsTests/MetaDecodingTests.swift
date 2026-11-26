import Foundation
import Testing
@testable import PubDBModels

/// Decodes the real `GET /meta` (Fixtures/meta.json). Checks shapes and the
/// cases the app depends on, not exact lists that grow over time.
struct MetaDecodingTests {
    private let meta: Meta

    init() throws {
        meta = try Fixture.decode(Meta.self, from: "meta")
    }

    @Test func theTwoAmenityGroupsArePubsAndBars() {
        #expect(meta.amenities.map(\.key) == ["pub", "bar"])
    }

    @Test func venueKindsBelongToAGroupAndGastropubCarriesANote() throws {
        let groups = Set(meta.amenities.map(\.key))
        #expect(meta.venueKinds.allSatisfy { groups.contains($0.group) })

        let gastropub = try #require(meta.venueKinds.first { $0.key == "gastropub" })
        #expect(gastropub.note != nil)
    }

    @Test func sevenWeekdaysMondayFirst() {
        #expect(meta.weekdays.map(\.day) == Array(0...6))
        #expect(meta.weekdays.first?.short == "Mon")
    }

    @Test func everyContributableFieldHasAKindThisBuildKnows() {
        let unknown = meta.contributableFields.filter {
            if case .other = $0.kind { return true }
            return false
        }
        #expect(unknown.isEmpty, "Unknown kinds: \(unknown.map(\.key))")
    }

    @Test func theGuinnessPriceIsAPriceWithBoundsAndCorroborates() throws {
        let price = try #require(meta.contributableFields.first { $0.key == "guinness_price" })

        #expect(price.kind == .price)
        #expect(price.corroborating)
        #expect(price.min != nil && price.max != nil)
    }

    @Test func boardsPhotoKindsAndReportReasonsArePresent() {
        #expect(!meta.boards.isEmpty)
        #expect(!meta.photoKinds.isEmpty)
        #expect(meta.reportReasons.contains { $0.applies(to: "photo") })
        #expect(meta.reportReasons.contains { $0.applies(to: "review") })
    }

    @Test func limitsDescribeARatingScale() {
        #expect(meta.limits.minRating < meta.limits.maxRating)
        #expect(meta.limits.clientMaxSide > 0)
    }
}
