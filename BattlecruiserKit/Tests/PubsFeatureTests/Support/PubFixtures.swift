import Foundation
import PubDBModels

/// Builds pubs the way the server would send them, decoded through the real
/// models (they have no public memberwise initialisers, by design).
enum PubFixtures {
    static func pub(
        id: String,
        state: String = "open",
        serving: Bool = true,
        closingSoon: Bool = false,
        metres: Int? = nil
    ) -> PubSummary {
        let json = summaryJSON(id: id, state: state, serving: serving, closingSoon: closingSoon, metres: metres)
        return try! JSONDecoder().decode(PubSummary.self, from: Data(json.utf8))
    }

    static func list(_ pubs: [(id: String, state: String, metres: Int?)]) -> PubList {
        let items = pubs
            .map { summaryJSON(id: $0.id, state: $0.state, serving: true, closingSoon: false, metres: $0.metres) }
            .joined(separator: ",")
        let json = #"{ "pubs": [\#(items)], "count": \#(pubs.count) }"#
        return try! JSONDecoder().decode(PubList.self, from: Data(json.utf8))
    }

    private static func summaryJSON(id: String, state: String, serving: Bool, closingSoon: Bool, metres: Int?) -> String {
        let symbol = #"{ "key": "amenity.pub", "type": "emoji", "emoji": "🍺", "url": null }"#
        let distance = metres.map { #"{ "metres": \#($0), "label": "\#($0) m" }"# } ?? "null"
        return #"""
        {
          "id": "\#(id)", "name": "Pub \#(id)",
          "amenity": { "key": "pub", "label": "Pub", "symbol": \#(symbol) },
          "lat": 51.5, "lon": -0.12, "address": null, "postcode": null, "brand": null,
          "distance": \#(distance),
          "status": { "key": "open", "label": "Open", "symbol": \#(symbol), "serving": \#(serving), "permanent": false },
          "open": { "state": "\#(state)", "label": "x", "closesAt": null, "closesAtLabel": null,
                    "minutesUntilClose": null, "countdownLabel": null, "closingSoon": \#(closingSoon) },
          "tonight": null, "guinness": null, "rating": null, "reviewCount": 0, "photo": null,
          "features": [], "listed": false
        }
        """#
    }
}
