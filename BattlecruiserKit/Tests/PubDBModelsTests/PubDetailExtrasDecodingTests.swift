import Foundation
import Testing
@testable import PubDBModels

/// The parts of a detail the panel's tabs draw: gallery, price history,
/// listing, drinkers' facts, tags, and the venue kind.
struct PubDetailExtrasDecodingTests {
    @Test func theBedfordHasPhotosPricesAListingAndFacts() throws {
        let detail = try Fixture.decode(PubDetail.self, from: "pub-detail-the-bedford")

        #expect(!detail.photos.isEmpty)
        #expect((detail.priceHistory?.points.count ?? 0) >= 2)
        #expect(detail.heritage?.designation != nil)
        #expect(!detail.contributions.isEmpty)
        #expect(detail.contributions.allSatisfy { !$0.displayValue.isEmpty && !$0.fieldLabel.isEmpty })
        #expect(!detail.osmTags.isEmpty)
        #expect(detail.summary.area != nil)
    }

    @Test func theVenueKindComesWithTheAmenity() throws {
        let legion = try Fixture.decode(PubDetail.self, from: "pub-detail-sparse-british-legion")

        #expect(legion.summary.amenity.key == "pub")
        #expect(legion.summary.amenity.kind == "social_club")
        #expect(legion.photos.isEmpty)
    }

    @Test func aBadExtraCostsTheSectionNotThePub() throws {
        var json = try JSONSerialization.jsonObject(with: Fixture.data("pub-detail-the-bedford")) as! [String: Any]
        json["priceHistory"] = "not an object"
        json["photos"] = 42
        let data = try JSONSerialization.data(withJSONObject: json)

        let detail = try JSONDecoder().decode(PubDetail.self, from: data)

        #expect(detail.priceHistory == nil)
        #expect(detail.photos.isEmpty)
        #expect(detail.summary.name == "The Bedford")
    }
}
