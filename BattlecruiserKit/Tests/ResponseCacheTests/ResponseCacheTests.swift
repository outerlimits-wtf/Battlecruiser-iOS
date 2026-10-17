import Foundation
import Testing
@testable import ResponseCache

/// Stores raw bytes with their fetch time, keeps keys apart, stays bounded.
/// A class so each test's temporary folder is removed when it finishes.
final class ResponseCacheTests {
    private let directory: URL
    private let fetched = Date(timeIntervalSince1970: 1_760_560_200)

    init() {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "ResponseCacheTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func storedBytesComeBackUnchangedWithTheirFetchTime() async throws {
        let cache = ResponseCache(directory: directory)
        let body = Data(#"{ "pubs": [], "count": 0 }"#.utf8)

        await cache.store(body, for: "pubs/last", fetchedAt: fetched)
        let cached = try #require(await cache.load("pubs/last"))

        #expect(cached.data == body)
        #expect(abs(cached.fetchedAt.timeIntervalSince(fetched)) < 1)
    }

    @Test func aKeyNeverStoredLoadsNothing() async {
        let cache = ResponseCache(directory: directory)

        let cached = await cache.load("pub/node/404")

        #expect(cached == nil)
    }

    @Test func keysThatWouldCollideAsFileNamesStayApart() async {
        let cache = ResponseCache(directory: directory)

        await cache.store(Data("slash".utf8), for: "pub/node/1", fetchedAt: fetched)
        await cache.store(Data("underscore".utf8), for: "pub/node_1", fetchedAt: fetched)

        let slash = await cache.load("pub/node/1")?.data
        let underscore = await cache.load("pub/node_1")?.data
        #expect(slash == Data("slash".utf8))
        #expect(underscore == Data("underscore".utf8))
    }

    @Test func storingAgainReplacesTheDataAndTheTime() async throws {
        let cache = ResponseCache(directory: directory)
        let later = fetched.addingTimeInterval(600)

        await cache.store(Data("old".utf8), for: "pubs/last", fetchedAt: fetched)
        await cache.store(Data("new".utf8), for: "pubs/last", fetchedAt: later)
        let cached = try #require(await cache.load("pubs/last"))

        #expect(cached.data == Data("new".utf8))
        #expect(abs(cached.fetchedAt.timeIntervalSince(later)) < 1)
    }

    @Test func beyondTheLimitTheOldestResponsesGo() async {
        let cache = ResponseCache(directory: directory, maxEntries: 2)

        await cache.store(Data("a".utf8), for: "a", fetchedAt: fetched)
        await cache.store(Data("b".utf8), for: "b", fetchedAt: fetched.addingTimeInterval(60))
        await cache.store(Data("c".utf8), for: "c", fetchedAt: fetched.addingTimeInterval(120))

        let a = await cache.load("a")
        let b = await cache.load("b")
        let c = await cache.load("c")
        #expect(a == nil)
        #expect(b != nil)
        #expect(c != nil)
    }

    @Test func removeAndRemoveAll() async {
        let cache = ResponseCache(directory: directory)
        await cache.store(Data("a".utf8), for: "a", fetchedAt: fetched)
        await cache.store(Data("b".utf8), for: "b", fetchedAt: fetched)

        await cache.remove("a")
        let afterRemove = await cache.load("a")
        let stillThere = await cache.load("b")
        #expect(afterRemove == nil)
        #expect(stillThere != nil)

        await cache.removeAll()
        let afterRemoveAll = await cache.load("b")
        #expect(afterRemoveAll == nil)
    }

    @Test func responsesSurviveANewCacheOnTheSameFolder() async {
        await ResponseCache(directory: directory).store(Data("kept".utf8), for: "pubs/last", fetchedAt: fetched)

        let reopened = await ResponseCache(directory: directory).load("pubs/last")

        #expect(reopened?.data == Data("kept".utf8))
    }
}
