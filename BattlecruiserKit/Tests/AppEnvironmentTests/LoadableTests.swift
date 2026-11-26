import Foundation
import Testing
import PubDBClient
@testable import AppEnvironment

struct LoadableTests {
    private let t0 = Date(timeIntervalSince1970: 0)

    @Test func aFailureKeepsTheValueAndACancellationRecordsNothing() {
        var state = Loadable<Int>()
        state.start()
        state.succeed(1, at: t0)

        state.start()
        state.fail(URLError(.notConnectedToInternet))
        #expect(state.value == 1)
        #expect(state.error?.isOffline == true)
        #expect(!state.isLoading)

        state.error = nil
        state.start()
        state.fail(CancellationError())
        #expect(state.error == nil)
        #expect(!state.isLoading)
    }

    @Test func aCachedCopyNeverReplacesAFreshValue() {
        var state = Loadable<Int>()
        state.showCached(1, fetchedAt: t0)
        #expect(state.value == 1 && state.isFromCache)

        state.succeed(2, at: t0)
        state.showCached(3, fetchedAt: t0)
        #expect(state.value == 2 && !state.isFromCache)
    }
}

struct LRUCacheTests {
    @Test func forgetsTheLeastRecentlyStoredBeyondItsLimit() {
        var cache = LRUCache<String, Int>(limit: 2)
        cache.store(1, for: "a")
        cache.store(2, for: "b")
        cache.store(10, for: "a") // refreshes "a"
        cache.store(3, for: "c")

        #expect(cache["a"] == 10)
        #expect(cache["b"] == nil)
        #expect(cache["c"] == 3)
        #expect(cache.count == 2)
    }
}
