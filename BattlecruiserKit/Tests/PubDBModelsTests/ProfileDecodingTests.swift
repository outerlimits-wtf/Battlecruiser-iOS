import Foundation
import Testing
@testable import PubDBModels

struct ProfileDecodingTests {
    @Test func aProfileHasStatsCoverageReviewsAndPubs() throws {
        let profile = try Fixture.decode(Profile.self, from: "profile")

        #expect(profile.user.label == "@\(profile.user.username)")
        #expect(profile.stats.visited >= profile.visited.count)
        #expect(profile.coverage?.areas.isEmpty == false)
        #expect(!profile.reviews.isEmpty)
        #expect(!profile.isSelf)
    }
}
