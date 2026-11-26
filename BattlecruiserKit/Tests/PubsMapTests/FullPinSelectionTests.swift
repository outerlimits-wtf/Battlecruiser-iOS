import Testing
import PubDBClient
import PubDBModels
@testable import PubsMap

@MainActor
struct FullPinSelectionTests {
    private let box = BoundingBox(west: 0, south: 0, east: 1, north: 1)

    private func pin(_ id: String, at x: Double = 0.5) -> Pin {
        Pin(id: id, latitude: 0.5, longitude: x, name: id, area: nil, amenity: "pub",
            state: "open", rank: 5, emoji: "🍺", label: nil)
    }

    private func viewport(metresPerPoint: Double) -> MapViewport {
        MapViewport(area: box, metresPerPoint: metresPerPoint)
    }

    @Test func zoomedOutOnlyTheSelectedPubIsAFullPin() {
        let ids = FullPinSelection.ids(for: [pin("a"), pin("b")], in: viewport(metresPerPoint: 20), selectedID: "b")

        #expect(ids == ["b"])
    }

    @Test func zoomedInPubsInViewAndJustOutsideAreFullPins() {
        let pins = [pin("in"), pin("margin", at: 1.2), pin("far", at: 3)]

        let ids = FullPinSelection.ids(for: pins, in: viewport(metresPerPoint: 1), selectedID: nil)

        #expect(ids == ["in", "margin"])
    }

    @Test func overTheCapTheLoudestAreKept() {
        // Quietest first, as the server sends them.
        let pins = (0..<(FullPinSelection.cap + 10)).map { pin("p\($0)") }

        let ids = FullPinSelection.ids(for: pins, in: viewport(metresPerPoint: 1), selectedID: nil)

        #expect(ids.count == FullPinSelection.cap)
        #expect(!ids.contains("p0"))
        #expect(ids.contains("p\(FullPinSelection.cap + 9)"))
    }

    @Test func theSelectedPubIsAlwaysAFullPin() {
        let ids = FullPinSelection.ids(for: [pin("far", at: 5)], in: viewport(metresPerPoint: 1), selectedID: "far")

        #expect(ids.contains("far"))
    }
}
