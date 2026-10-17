import Foundation
import PubDBModels

/// Builds summaries and details the way the server would send them, decoded
/// through the real models. `name` lets a test tell one fetch from another.
enum DetailFixtures {
    static func summary(id: String, name: String = "The Test Arms") -> PubSummary {
        decode(PubSummary.self, "{ \(summaryFields(id: id, name: name)) }")
    }

    static func detail(id: String, name: String = "The Test Arms") -> PubDetail {
        decode(PubDetail.self, #"""
        {
          \#(summaryFields(id: id, name: name)),
          "description": null, "city": "London", "operator": null, "brewery": null,
          "contact": { "phone": null, "website": null, "email": null, "facebook": null, "instagram": null },
          "hours": { "raw": null, "source": null, "attribution": null },
          "weekTable": [], "gardenCloses": null, "timeline": [], "features": [], "sources": []
        }
        """#)
    }

    private static func summaryFields(id: String, name: String) -> String {
        let symbol = #"{ "key": "amenity.pub", "type": "emoji", "emoji": "🍺", "url": null }"#
        return #"""
          "id": "\#(id)", "name": "\#(name)",
          "amenity": { "key": "pub", "label": "Pub", "symbol": \#(symbol) },
          "lat": 51.5, "lon": -0.12, "address": null, "postcode": null, "brand": null, "distance": null,
          "status": { "key": "open", "label": "Open", "symbol": \#(symbol), "serving": true, "permanent": false },
          "open": { "state": "open", "label": "Closes 23:00", "closesAt": 1380, "closesAtLabel": "23:00",
                    "minutesUntilClose": 30, "countdownLabel": "30 min", "closingSoon": true },
          "tonight": null, "guinness": null, "rating": null, "reviewCount": 0, "photo": null,
          "features": [], "listed": false
        """#
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ json: String) -> T {
        try! JSONDecoder().decode(type, from: Data(json.utf8))
    }
}
