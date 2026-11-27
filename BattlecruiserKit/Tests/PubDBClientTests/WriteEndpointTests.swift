import Foundation
import Testing
@testable import PubDBClient

/// Writes go where the spec says, with the bodies it asks for.
struct WriteEndpointTests {
    private let base = URL(string: "https://pubdb.test/api/v1")!

    private func body(_ endpoint: Endpoint) throws -> [String: Any] {
        let request = try #require(endpoint.request(baseURL: base, now: .now))
        let data = try #require(request.httpBody)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test func aContributionPostsFieldAndValue() throws {
        let sent = try body(.contribute(to: "node/1", field: "guinness_price", value: "620"))
        #expect(sent["field"] as? String == "guinness_price")
        #expect(sent["value"] as? String == "620")
    }

    @Test func aReviewPostsTheRatingAsANumber() throws {
        let sent = try body(.review("node/1", rating: 8, body: "Proper"))
        #expect(sent["rating"] as? Int == 8)
        #expect(sent["body"] as? String == "Proper")
    }

    @Test func removingIsADeleteOnTheRow() throws {
        let request = try #require(Endpoint.removeReview(74, from: "node/1").request(baseURL: base, now: .now))
        #expect(request.httpMethod == "DELETE")
        #expect(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.percentEncodedPath } == "/api/v1/pubs/node%2F1/reviews/74")
    }

    @Test func aReportNamesTheThingAndTheReason() throws {
        let sent = try body(.report(type: "review", id: "74", reason: "spam", note: nil))
        #expect(sent["type"] as? String == "review")
        #expect(sent["id"] as? String == "74")
        #expect(sent["reason"] as? String == "spam")
    }

    /// S12: the 201 carries the pub as the GET would draw it, so the POST sends
    /// the same `at`, `lat` and `lon`.
    @Test func contributionsAndReviewsSendTheClockAndLocation() throws {
        let here = Coordinate(latitude: 51.4431, longitude: -0.1525)
        for endpoint in [
            Endpoint.contribute(to: "node/1", field: "guinness_price", value: "620", near: here),
            Endpoint.review("node/1", rating: 8, body: nil, near: here),
        ] {
            let request = try #require(endpoint.request(baseURL: base, now: .now))
            let items = try #require(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems })
            let names = Set(items.map(\.name))
            #expect(names.isSuperset(of: ["at", "lat", "lon"]))
        }
    }
}
