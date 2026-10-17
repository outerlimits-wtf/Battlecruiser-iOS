import Testing
import PubDBModels
@testable import PubsFeature

/// Open first, then unknown, then closed, each nearest first (docs/mvp-plan.md).
struct PubOrderingTests {
    @Test func openBeforeUnknownBeforeClosed() {
        let pubs = [
            PubFixtures.pub(id: "closed", state: "closed", metres: 10),
            PubFixtures.pub(id: "unknown", state: "unknown", metres: 20),
            PubFixtures.pub(id: "open", state: "open", metres: 30),
        ]

        let ids = PubOrdering.forDisplay(pubs).map { $0.id }

        #expect(ids == ["open", "unknown", "closed"])
    }

    @Test func nearestFirstWithinEachGroup() {
        let pubs = [
            PubFixtures.pub(id: "far", metres: 900),
            PubFixtures.pub(id: "near", metres: 50),
            PubFixtures.pub(id: "middle", metres: 300),
        ]

        let ids = PubOrdering.forDisplay(pubs).map { $0.id }

        #expect(ids == ["near", "middle", "far"])
    }

    @Test func pubsWithoutADistanceComeLastInTheirGroup() {
        let pubs = [
            PubFixtures.pub(id: "unmeasured", metres: nil),
            PubFixtures.pub(id: "measured", metres: 500),
        ]

        let ids = PubOrdering.forDisplay(pubs).map { $0.id }

        #expect(ids == ["measured", "unmeasured"])
    }

    @Test func tiesKeepTheServersOrder() {
        let pubs = [
            PubFixtures.pub(id: "first"),
            PubFixtures.pub(id: "second"),
            PubFixtures.pub(id: "third"),
        ]

        let ids = PubOrdering.forDisplay(pubs).map { $0.id }

        #expect(ids == ["first", "second", "third"])
    }

    @Test func aPubThatIsNotTradingSortsWithTheClosed() {
        let pubs = [
            PubFixtures.pub(id: "shut-for-refit", state: "open", serving: false, metres: 10),
            PubFixtures.pub(id: "unknown", state: "unknown", metres: 500),
        ]

        let ids = PubOrdering.forDisplay(pubs).map { $0.id }

        #expect(ids == ["unknown", "shut-for-refit"])
    }
}
