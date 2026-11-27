import Foundation
import Testing
@testable import PubDBModels

/// Decodes the real `GET /brands` (Fixtures/brands-1127.json).
struct BrandDecodingTests {
    @Test func brandsComeMostPubsFirstEachWithACount() throws {
        let brands = try Fixture.decode(BrandList.self, from: "brands-1127").brands
        #expect(brands.count > 10)
        #expect(brands.allSatisfy { !$0.name.isEmpty && $0.count > 0 })
        #expect(brands.map(\.count) == brands.map(\.count).sorted(by: >))
        #expect(brands.contains { $0.name == "Young's" })
    }
}
