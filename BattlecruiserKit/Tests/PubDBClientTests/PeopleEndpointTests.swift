import Foundation
import Testing
@testable import PubDBClient

struct PeopleEndpointTests {
    private let base = URL(string: "https://pubdb.test/api/v1")!

    @Test func listsAndMarksUseTheServersPaths() throws {
        let watch = try #require(Endpoint.mark("node/1", on: .watchlist, true).request(baseURL: base, now: .now))
        let unvisit = try #require(Endpoint.mark("node/1", on: .visited, false).request(baseURL: base, now: .now))
        let list = try #require(Endpoint.savedPubs(.visited, near: nil).request(baseURL: base, now: .now))

        #expect(watch.httpMethod == "PUT")
        #expect(watch.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.percentEncodedPath } == "/api/v1/pubs/node%2F1/watch")
        #expect(unvisit.httpMethod == "DELETE")
        #expect(unvisit.url?.path.hasSuffix("/visited") == true)
        #expect(list.url?.path == "/api/v1/visited")
    }

    @Test func followingIsPutAndUnfollowingDelete() throws {
        let follow = try #require(Endpoint.follow("goatloaf", true).request(baseURL: base, now: .now))
        let unfollow = try #require(Endpoint.follow("goatloaf", false).request(baseURL: base, now: .now))

        #expect(follow.httpMethod == "PUT" && unfollow.httpMethod == "DELETE")
        #expect(follow.url?.path == "/api/v1/users/goatloaf/follow")
    }
}
