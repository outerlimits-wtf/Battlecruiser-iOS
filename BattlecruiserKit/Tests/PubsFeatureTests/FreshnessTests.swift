import Foundation
import Testing
@testable import PubsFeature

/// When data is labelled old, and how often it is replaced.
struct FreshnessTests {
    private let fetched = Date(timeIntervalSince1970: 1_760_560_200)

    @Test func freshDataIsNotStale() {
        let fourMinutesLater = fetched.addingTimeInterval(4 * 60)

        #expect(!Freshness.isStale(fetchedAt: fetched, now: fourMinutesLater))
    }

    @Test func dataOlderThanFiveMinutesIsStale() {
        let sixMinutesLater = fetched.addingTimeInterval(6 * 60)

        #expect(Freshness.isStale(fetchedAt: fetched, now: sixMinutesLater))
    }

    @Test func nothingFetchedIsNotStale() {
        #expect(!Freshness.isStale(fetchedAt: nil, now: fetched))
    }

    @Test func refreshEveryMinuteWhileAPubIsClosingSoon() {
        let pubs = [
            PubFixtures.pub(id: "relaxed"),
            PubFixtures.pub(id: "last-call", closingSoon: true),
        ]

        let interval = Freshness.refreshInterval(for: pubs)

        #expect(interval == .seconds(60))
    }

    @Test func refreshEveryFiveMinutesOtherwise() {
        let pubs = [PubFixtures.pub(id: "relaxed")]

        let interval = Freshness.refreshInterval(for: pubs)

        #expect(interval == .seconds(300))
    }
}
