import Foundation
import Testing
@testable import PubDBModels

/// Decodes a real `GET /pins` (trimmed to 15 pins per state; docs/test-fixtures.md).
struct PinCollectionDecodingTests {
    private let collection: PinCollection

    init() throws {
        collection = try Fixture.decode(PinCollection.self, from: "pins-pub-thu-2130")
    }

    @Test func everyPinDecodes() {
        #expect(collection.droppedCount == 0)
        #expect(!collection.pins.isEmpty)
    }

    @Test func coordinatesAreLongitudeFirstInTheJSON() throws {
        // Southern England (London, Brighton): latitude about 50–52, longitude
        // about 0. Swapped, the latitude would be near zero.
        for pin in collection.pins {
            #expect((49...56).contains(pin.latitude), "\(pin.name) at \(pin.latitude)")
            #expect((-6...2).contains(pin.longitude), "\(pin.name) at \(pin.longitude)")
        }
    }

    @Test func pinsArriveQuietestFirst() {
        let ranks = collection.pins.map(\.rank)
        #expect(ranks == ranks.sorted())
    }

    @Test func openPinsHaveALabelAndKnownStatesAreUsed() {
        let known: Set = ["open", "closing", "unknown", "closed", "paused", "gone"]
        #expect(collection.pins.allSatisfy { known.contains($0.state) })
        #expect(collection.pins.filter { $0.state == "open" }.allSatisfy { $0.label != nil })
    }

    @Test func aBrokenFeatureIsSkippedNotFatal() throws {
        let json = #"""
        { "type": "FeatureCollection", "features": [
          { "type": "Feature", "id": "node/1", "geometry": { "type": "Point", "coordinates": [-0.1, 51.5] },
            "properties": { "id": "node/1", "name": "A", "area": null, "amenity": "pub", "pin": "open",
                            "rank": 5, "emoji": "🍺", "label": "Open till 23:00" } },
          { "type": "Feature", "id": "node/2", "geometry": { "type": "Point", "coordinates": [] },
            "properties": {} }
        ] }
        """#
        let decoded = try JSONDecoder().decode(PinCollection.self, from: Data(json.utf8))

        #expect(decoded.pins.map(\.id) == ["node/1"])
        #expect(decoded.droppedCount == 1)
    }
}
