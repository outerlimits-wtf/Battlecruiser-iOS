import Foundation
import Testing
@testable import PubDBModels

/// Decodes real `GET /pubs/{id}` responses (docs/test-fixtures.md).
struct PubDetailDecodingTests {
    @Test func weekTableIsSevenRowsMondayFirstWithOneTonight() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-earl-ferrers")

        let days = detail.weekTable.map(\.day)
        #expect(days == Array(0...6))
        let tonightRows = detail.weekTable.filter(\.isTonight)
        #expect(tonightRows.count == 1)
        // The fixture was captured on a Thursday evening.
        #expect(tonightRows.first?.day == 3)
    }

    @Test func reportedNightTimesDecodeIntoTheWeekTableAndTonight() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-earl-ferrers")
        // Key paths passed to rethrowing functions inside #require/#expect read as
        // throwing once the macro expands, so work the value out first.
        let tonightRow = detail.weekTable.first(where: \.isTonight)
        let thursday = try #require(tonightRow)

        #expect(thursday.bell != nil)
        #expect(thursday.out != nil)
        #expect(detail.summary.tonight?.kind == "kicked_out")
    }

    @Test func summaryFeaturesKeepOnlyTheYesAnswers() throws {
        // Earl Ferrers answers every feature "no" or "unknown": the detail lists
        // all of them, the summary must list none.
        let earlFerrers = try Fixture.decode(PubDetail.self, from: "pub-detail-earl-ferrers")
        #expect(!earlFerrers.features.isEmpty)
        #expect(earlFerrers.features.allSatisfy { $0.value != .yes })
        #expect(earlFerrers.summary.features.isEmpty)

        // The Bedford answers "yes" to the garden only.
        let bedford = try Fixture.decode(PubDetail.self, from: "pub-detail-the-bedford")
        let bedfordFeatures = bedford.summary.features.map(\.key)
        #expect(bedfordFeatures == ["garden"])
    }

    @Test func photoAndPriceDecodeWhereTheyExist() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-the-bedford")
        let photo = try #require(detail.summary.photo)

        #expect(photo.imageURL != nil)
        #expect(photo.thumbnailURL != nil)
        #expect(detail.summary.guinness?.formatted.hasPrefix("£") == true)
    }

    @Test func sourcesIncludeOpenStreetMapWithALink() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-the-bedford")
        let osm = try #require(detail.sources.first(where: { $0.key == "osm" }))

        #expect(osm.label == "OpenStreetMap")
        #expect(osm.linkURL != nil)
    }

    @Test func sparsePubDecodesWithHoursUnknown() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-sparse-the-furzedown")

        #expect(detail.summary.open.state == .unknown)
        #expect(detail.summary.photo == nil)
        // The server sends an hours object with every field null, not a null object.
        #expect(detail.hours.raw == nil)
        #expect(detail.hours.attribution == nil)
        #expect(detail.weekTable.allSatisfy { $0.doorSays == nil })
    }

    @Test func reviewsDecodeWithScoreBylineAndText() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-the-bedford")
        let review = try #require(detail.reviews.first)

        #expect((1...10).contains(review.rating))
        #expect(review.attribution.label.hasPrefix("@"))
        #expect(!review.createdAtLabel.isEmpty)
        #expect(review.text != nil)
    }

    @Test func pubWithoutReviewsHasAnEmptyList() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-earl-ferrers")

        #expect(detail.reviews.isEmpty)
    }

    @Test func blankReviewBodyHasNoText() throws {
        let json = Data("""
        { "id": 1, "rating": 7, "body": "  ", "createdAt": "2026-09-11T20:50:07.583Z",
          "createdAtLabel": "11 Sept 2026",
          "attribution": { "kind": "user", "label": "@someone", "sourceKey": null } }
        """.utf8)
        let review = try JSONDecoder().decode(Review.self, from: json)

        #expect(review.text == nil)
    }

    @Test func timelineStartsOnTheCurrentName() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-the-bedford")

        #expect(detail.timeline.first?.isCurrent == true)
    }
}
