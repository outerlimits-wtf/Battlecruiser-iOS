import Foundation
import Testing
import PubDBClient
@testable import PubsFeature

/// Which notice the map and list show, and which wins when several apply.
struct PubsNoticeTests {
    private let balham = BoundingBox(west: -0.165, south: 51.42, east: -0.125, north: 51.45)
    private let brighton = BoundingBox(west: -0.2, south: 50.8, east: -0.1, north: 50.85)
    private let offline = PubDBError.transport(URLError(.notConnectedToInternet))

    @Test func nothingToSayWhenThereArePubs() {
        let notice = PubsNotice.current(area: balham, pubCount: 12, hasFreshResult: true, isLoading: false, error: nil)

        #expect(notice == nil)
    }

    @Test func outsideLondonSaysSo() {
        let notice = PubsNotice.current(area: brighton, pubCount: 0, hasFreshResult: true, isLoading: false, error: nil)

        #expect(notice == .outsideCoverage)
    }

    @Test func outsideLondonWinsOverAFailure() {
        let notice = PubsNotice.current(area: brighton, pubCount: 0, hasFreshResult: false, isLoading: false, error: offline)

        #expect(notice == .outsideCoverage)
    }

    @Test func offlineIsToldApartFromOtherFailures() {
        let offlineNotice = PubsNotice.current(area: balham, pubCount: 5, hasFreshResult: false, isLoading: false, error: offline)
        let failedNotice = PubsNotice.current(area: balham, pubCount: 5, hasFreshResult: true, isLoading: false, error: .http(status: 502))

        #expect(offlineNotice == .offline(message: offline.userMessage))
        #expect(failedNotice == .failed(message: PubDBError.http(status: 502).userMessage))
    }

    @Test func anEmptyFreshResultIsNothingHere() {
        let notice = PubsNotice.current(area: balham, pubCount: 0, hasFreshResult: true, isLoading: false, error: nil)

        #expect(notice == .nothingHere)
    }

    @Test func emptyWhileLoadingOrBeforeAnyFetchIsNotYetNothingHere() {
        let loading = PubsNotice.current(area: balham, pubCount: 0, hasFreshResult: true, isLoading: true, error: nil)
        let notFetched = PubsNotice.current(area: balham, pubCount: 0, hasFreshResult: false, isLoading: false, error: nil)

        #expect(loading == nil)
        #expect(notFetched == nil)
    }

    @Test func noAreaYetIsNeverOutsideCoverage() {
        let notice = PubsNotice.current(area: nil, pubCount: 0, hasFreshResult: false, isLoading: true, error: nil)

        #expect(notice == nil)
    }
}
