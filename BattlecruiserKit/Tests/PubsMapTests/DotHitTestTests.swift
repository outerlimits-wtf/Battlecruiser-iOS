import CoreGraphics
import Testing
import PubDBModels
@testable import PubsMap

@MainActor
struct DotHitTestTests {
    private func pin(_ id: String, x: Double) -> Pin {
        Pin(id: id, latitude: 0, longitude: x, name: id, area: nil, amenity: "pub",
            state: "open", rank: 5, emoji: "🍺", label: nil)
    }

    /// Screen position = longitude as x, so tests read plainly.
    private func project(_ pin: Pin) -> CGPoint {
        CGPoint(x: pin.longitude, y: 0)
    }

    @Test func theNearestDotWithinReachWins() {
        let pins = [pin("a", x: 10), pin("b", x: 4)]

        let hit = DotHitTest.nearest(to: .zero, in: pins, excluding: [], project: project)

        #expect(hit?.id == "b")
    }

    @Test func aTapTooFarFromAnyDotHitsNothing() {
        let hit = DotHitTest.nearest(to: .zero, in: [pin("a", x: 30)], excluding: [], project: project)

        #expect(hit == nil)
    }

    @Test func pubsDrawnAsFullPinsAreNotDots() {
        let pins = [pin("a", x: 2), pin("b", x: 8)]

        let hit = DotHitTest.nearest(to: .zero, in: pins, excluding: ["a"], project: project)

        #expect(hit?.id == "b")
    }

    @Test func onATieTheDotDrawnOnTopWins() {
        let pins = [pin("quiet", x: 3), pin("loud", x: 3)]

        let hit = DotHitTest.nearest(to: .zero, in: pins, excluding: [], project: project)

        #expect(hit?.id == "loud")
    }
}
