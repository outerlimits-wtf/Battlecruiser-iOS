import Foundation
import Testing
import PubDBClient
@testable import PubsFeature

/// Which notice the map and list show, and which wins when several apply.
struct PubsNoticeTests {
    private let offline = PubDBError.transport(URLError(.notConnectedToInternet))

    @Test func nothingToSayWhenThereArePubs() {
        let notice = PubsNotice.current(pubCount: 12, hasFreshResult: true, isLoading: false, error: nil)

        #expect(notice == nil)
    }

    @Test func offlineIsToldApartFromOtherFailures() {
        let offlineNotice = PubsNotice.current(pubCount: 5, hasFreshResult: false, isLoading: false, error: offline)
        let failedNotice = PubsNotice.current(pubCount: 5, hasFreshResult: true, isLoading: false, error: .http(status: 502))

        #expect(offlineNotice == .offline(message: offline.userMessage))
        #expect(failedNotice == .failed(message: PubDBError.http(status: 502).userMessage))
    }

    @Test func aFailureWinsOverAnEmptyList() {
        let notice = PubsNotice.current(pubCount: 0, hasFreshResult: true, isLoading: false, error: .http(status: 502))

        #expect(notice == .failed(message: PubDBError.http(status: 502).userMessage))
    }

    /// Anywhere, London or not: only the server knows what it covers.
    @Test func anEmptyFreshResultIsNothingHere() {
        let notice = PubsNotice.current(pubCount: 0, hasFreshResult: true, isLoading: false, error: nil)

        #expect(notice == .nothingHere)
    }

    @Test func emptyWhileLoadingOrBeforeAnyFetchIsNotYetNothingHere() {
        let loading = PubsNotice.current(pubCount: 0, hasFreshResult: true, isLoading: true, error: nil)
        let notFetched = PubsNotice.current(pubCount: 0, hasFreshResult: false, isLoading: false, error: nil)

        #expect(loading == nil)
        #expect(notFetched == nil)
    }
}
