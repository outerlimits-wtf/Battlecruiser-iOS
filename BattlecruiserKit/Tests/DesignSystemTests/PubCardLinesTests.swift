import Foundation
import Testing
import PubDBModels
@testable import DesignSystem

/// The card's lines are the server's labels, joined as the web joins them.
@MainActor
struct PubCardLinesTests {
    @Test func theSummaryLineJoinsKindAndAreaLeavingRatingAndBrandOut() throws {
        let pub = try Self.pub(rating: "8.4", area: #""Balham""#, brand: #""Young's""#, guinness: true)

        #expect(PubCardLines.summary(pub) == "Pub · Balham")
    }

    @Test func theRatingShowsOneDecimalPlace() {
        #expect(RatingText.score(8.4) == "8.4")
        #expect(RatingText.score(7) == "7.0")
    }

    @Test func missingPartsAreLeftOutNotBlank() throws {
        let pub = try Self.pub(rating: "null", area: "null", brand: "null", guinness: false)

        #expect(PubCardLines.summary(pub) == "Pub")
        #expect(PubCardLines.features(pub) == nil)
    }

    @Test func aPubThatStoppedTradingSaysWhenAndWhatItBecame() throws {
        let pub = try Self.pub(serving: false, since: #""2019""#, became: #""a Tesco Express""#)

        #expect(PubCardLines.status(pub.status) == "Closed 2019 · now a Tesco Express")
        #expect(PubCardLines.isShut(pub))
    }

    static func pub(
        rating: String = "null", area: String = "null", brand: String = "null", guinness: Bool = false,
        serving: Bool = true, since: String = "null", became: String = "null"
    ) throws -> PubSummary {
        let symbol = #"{ "key": "amenity.pub", "type": "emoji", "emoji": "🍺", "url": null }"#
        let price = guinness
            ? #"{ "pence": 620, "formatted": "£6.20", "reports": 4, "updatedAt": "2026-07-11", "agoLabel": "a month ago" }"#
            : "null"
        let json = """
        {
          "id": "node/1", "name": "The Test", "area": \(area),
          "amenity": { "key": "pub", "label": "Pub", "symbol": \(symbol) },
          "lat": 51.5, "lon": -0.1, "address": null, "postcode": null, "brand": \(brand), "distance": null,
          "status": { "key": "\(serving ? "open" : "closed")", "label": "\(serving ? "Open" : "Closed")",
                      "symbol": \(symbol), "serving": \(serving), "permanent": \(!serving),
                      "since": \(since), "became": \(became) },
          "open": { "state": "\(serving ? "open" : "closed")", "label": "Closes 23:00", "closesAt": null, "closesAtLabel": null,
                    "minutesUntilClose": null, "countdownLabel": null, "closingSoon": false },
          "tonight": null, "guinness": \(price), "rating": \(rating), "reviewCount": 11, "photo": null,
          "features": [], "listed": false
        }
        """
        return try JSONDecoder().decode(PubSummary.self, from: Data(json.utf8))
    }
}
