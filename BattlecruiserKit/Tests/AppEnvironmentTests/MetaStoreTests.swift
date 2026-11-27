import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import AppEnvironment

@MainActor
struct MetaStoreTests {
    @Test func showsTheSavedCopyThenTheFreshOne() async throws {
        let source = FakeMetaSource(cached: try Self.meta(minVersion: nil), fresh: .success(try Self.meta(minVersion: "0.2")))
        let store = MetaStore(source: source)

        store.load()
        await store.loadTask?.value

        #expect(store.meta?.clients.ios.minVersion == "0.2")
        #expect(store.state.isFromCache == false)
    }

    @Test func aFailedFetchKeepsTheSavedCopy() async throws {
        let source = FakeMetaSource(cached: try Self.meta(minVersion: "0.1"), fresh: .failure(URLError(.notConnectedToInternet)))
        let store = MetaStore(source: source)

        store.load()
        await store.loadTask?.value

        #expect(store.meta?.clients.ios.minVersion == "0.1")
        #expect(store.state.isFromCache)
        #expect(store.state.error?.isOffline == true)
    }

    @Test func anOldBuildIsAskedToUpdateOnlyOnceMetaIsKnown() async throws {
        let source = FakeMetaSource(cached: nil, fresh: .success(try Self.meta(minVersion: "0.10")))
        let store = MetaStore(source: source)
        let build = AppVersion("0.9")

        #expect(!store.requiresUpdate(from: build))
        store.load()
        await store.loadTask?.value
        #expect(store.requiresUpdate(from: build))
        #expect(!store.requiresUpdate(from: AppVersion("0.10")))
    }

    static func meta(minVersion: String?) throws -> Meta {
        let floor = minVersion.map { "\"\($0)\"" } ?? "null"
        let json = """
        {
          "amenities": [], "venueKinds": [], "features": [], "weekdays": [],
          "contributableFields": [], "boards": [], "photoKinds": [], "reportReasons": [],
          "clients": { "ios": { "minVersion": \(floor) } },
          "limits": { "maxLimit": 2000, "defaultLimit": 500, "maxReviewBody": 2000, "maxAuthor": 60,
                      "minRating": 1, "maxRating": 10, "maxUploadBytes": 15728640, "minPhotoSide": 400,
                      "clientMaxSide": 2000, "maxCaption": 140, "dailyPhotoLimit": 10,
                      "photoLicense": "CC BY-SA 4.0" }
        }
        """
        return try JSONDecoder().decode(Meta.self, from: Data(json.utf8))
    }
}

private struct FakeMetaSource: MetaSource {
    let cached: Meta?
    let fresh: Result<Meta, any Error>

    func fetchMeta() async throws -> Meta {
        try fresh.get()
    }

    func cachedMeta() async -> Cached<Meta>? {
        cached.map { Cached(value: $0, fetchedAt: Date(timeIntervalSince1970: 0)) }
    }
}
