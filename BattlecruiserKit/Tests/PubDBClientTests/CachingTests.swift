import Foundation
import Testing
import PubDBModels
import ResponseCache
@testable import PubDBClient

/// What the client saves, under which key, and how it reads it back. A class so
/// each test's temporary cache folder is removed when it finishes.
final class CachingTests {
    private let directory: URL
    private let cache: ResponseCache
    private let area = BoundingBox(west: -0.165, south: 51.42, east: -0.125, north: 51.45)
    private let listBody = #"{ "pubs": [], "count": 0 }"#

    init() {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "CachingTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        cache = ResponseCache(directory: directory)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func aPubListIsSavedRawUnderTheLastListKeyWithItsRequestTime() async throws {
        let client = makeClient(.json(listBody))

        _ = try await client.pubs(in: area)

        let saved = try #require(await cache.load(Endpoint.lastPubsCacheKey))
        #expect(saved.data == Data(listBody.utf8))
        #expect(abs(saved.fetchedAt.timeIntervalSince(Self.clock)) < 1)
    }

    @Test func theSavedListReadsBackDecoded() async throws {
        let client = makeClient(.json(listBody))
        _ = try await client.pubs(in: area)

        let cached = try #require(await client.cachedPubs())

        #expect(cached.value.pubs.isEmpty)
        #expect(cached.value.count == 0)
    }

    @Test func aDetailIsSavedUnderItsPubsKeyAndReadsBack() async throws {
        let client = makeClient(.json(Self.detailBody(id: "node/1")))

        _ = try await client.pub(id: "node/1")

        let saved = await cache.load(Endpoint.pubCacheKey("node/1"))
        #expect(saved != nil)
        let cached = try #require(await client.cachedPub(id: "node/1"))
        #expect(cached.value.id == "node/1")
    }

    @Test func aFailedFetchIsNotSaved() async {
        let body = #"{ "error": { "code": "not_found", "message": "gone" } }"#
        let client = makeClient(.json(body, status: 404))

        _ = try? await client.pub(id: "node/1")

        let saved = await cache.load(Endpoint.pubCacheKey("node/1"))
        #expect(saved == nil)
    }

    @Test func similarIsNotSaved() async throws {
        let client = makeClient(.json(listBody))

        _ = try await client.similar(to: "node/1")

        let lastList = await cache.load(Endpoint.lastPubsCacheKey)
        #expect(lastList == nil)
    }

    @Test func aResponseThatFailsToDecodeIsNotSaved() async {
        let client = makeClient(.json(#"{ "pubs": "not a list" }"#))

        _ = try? await client.pubs(in: area)

        let saved = await cache.load(Endpoint.lastPubsCacheKey)
        #expect(saved == nil)
    }

    @Test func aSavedEntryThatNoLongerDecodesIsDroppedNotShown() async {
        await cache.store(Data(#"{ "pubs": 42 }"#.utf8), for: Endpoint.lastPubsCacheKey, fetchedAt: Self.clock)
        let client = makeClient(.json(listBody))

        let cached = await client.cachedPubs()
        let stillSaved = await cache.load(Endpoint.lastPubsCacheKey)

        #expect(cached == nil)
        #expect(stillSaved == nil)
    }

    @Test func withoutACacheNothingIsSavedOrRead() async throws {
        let client = PubDBClient.testing(.json(listBody))

        _ = try await client.pubs(in: area)
        let cached = await client.cachedPubs()

        #expect(cached == nil)
    }

    // MARK: - Helpers

    private static let clock = Date(timeIntervalSince1970: 1_760_560_200)

    /// The smallest detail the server could send.
    private static func detailBody(id: String) -> String {
        let symbol = #"{ "key": "amenity.pub", "type": "emoji", "emoji": "🍺", "url": null }"#
        return #"""
        {
          "id": "\#(id)", "name": "The Test Arms",
          "amenity": { "key": "pub", "label": "Pub", "symbol": \#(symbol) },
          "lat": 51.5, "lon": -0.12, "address": null, "postcode": null, "brand": null, "distance": null,
          "status": { "key": "open", "label": "Open", "symbol": \#(symbol), "serving": true, "permanent": false },
          "open": { "state": "unknown", "label": "Hours unknown", "closesAt": null, "closesAtLabel": null,
                    "minutesUntilClose": null, "countdownLabel": null, "closingSoon": false },
          "tonight": null, "guinness": null, "rating": null, "reviewCount": 0, "photo": null,
          "listed": false,
          "description": null, "city": null, "operator": null, "brewery": null,
          "contact": { "phone": null, "website": null, "email": null, "facebook": null, "instagram": null },
          "hours": { "raw": null, "source": null, "attribution": null },
          "weekTable": [], "gardenCloses": null, "timeline": [], "features": [], "sources": []
        }
        """#
    }

    private func makeClient(_ transport: FakeTransport) -> PubDBClient {
        PubDBClient(
            baseURL: URL(string: "https://pubdb.test/api/v1")!,
            transport: transport,
            now: { Self.clock },
            cache: cache
        )
    }
}
