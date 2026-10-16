import Foundation
import Testing
@testable import PubDBModels

/// The app must keep working when the server changes underneath it (new states,
/// new fields, one malformed record). These use small hand-written payloads.
struct RobustDecodingTests {
    @Test func errorBodiesDecodeWithAndWithoutAField() throws {
        let notFound = try Fixture.decode(APIErrorBody.self, from: "error-not-found")
        #expect(notFound.error.code == "not_found")
        #expect(notFound.error.field == nil)

        let invalid = try Fixture.decode(APIErrorBody.self, from: "error-invalid-at")
        #expect(invalid.error.code == "invalid_request")
        #expect(invalid.error.field == "at")
    }

    @Test func anOpenStateTheAppDoesNotKnowBecomesUnknown() throws {
        let pub = try decodePub(openState: "lock_in")

        #expect(pub.open.state == .unknown)
    }

    @Test func aFeatureAnswerTheAppDoesNotKnowBecomesUnknown() throws {
        let json = #"{ "key": "garden", "label": "Garden", "value": "sometimes", "symbol": \#(symbolJSON) }"#
        let answer = try JSONDecoder().decode(FeatureAnswer.self, from: Data(json.utf8))

        #expect(answer.value == .unknown)
    }

    @Test func unknownKeysAreIgnored() throws {
        let pub = try decodePub(extraFields: #", "someFutureField": { "nested": [1, 2, 3] }"#)

        #expect(pub.name == "The Test Arms")
    }

    @Test func oneMalformedPubIsSkippedAndCountedNotFatal() throws {
        let good = pubJSON()
        let bad = #"{ "id": "node/2", "name": 42 }"#
        let json = #"{ "pubs": [\#(good), \#(bad), \#(good)], "count": 3 }"#

        let list = try JSONDecoder().decode(PubList.self, from: Data(json.utf8))

        #expect(list.pubs.count == 2)
        #expect(list.droppedCount == 1)
        #expect(list.count == 3)
    }

    // MARK: - Payload builders

    private let symbolJSON = #"{ "key": "amenity.pub", "type": "emoji", "emoji": "🍺", "url": null }"#

    private func decodePub(openState: String = "open", extraFields: String = "") throws -> PubSummary {
        try JSONDecoder().decode(PubSummary.self, from: Data(pubJSON(openState: openState, extraFields: extraFields).utf8))
    }

    /// The smallest summary the server could send: every required key, every optional one null.
    private func pubJSON(openState: String = "open", extraFields: String = "") -> String {
        #"""
        {
          "id": "node/1", "name": "The Test Arms",
          "amenity": { "key": "pub", "label": "Pub", "symbol": \#(symbolJSON) },
          "lat": 51.5, "lon": -0.12, "address": null, "postcode": null, "brand": null,
          "distance": null,
          "status": { "key": "open", "label": "Open", "symbol": \#(symbolJSON), "serving": true, "permanent": false },
          "open": { "state": "\#(openState)", "label": "Closes 23:00", "closesAt": 1380, "closesAtLabel": "23:00",
                    "minutesUntilClose": 30, "countdownLabel": "30 min", "closingSoon": true },
          "tonight": null, "guinness": null, "rating": null, "reviewCount": 0, "photo": null,
          "features": [], "listed": false\#(extraFields)
        }
        """#
    }
}
