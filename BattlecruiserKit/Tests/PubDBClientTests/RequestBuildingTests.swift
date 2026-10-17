import Foundation
import Testing
@testable import PubDBClient

/// The client must send exactly what production expects (docs/backend/03-api-reference.md).
struct RequestBuildingTests {
    private let balham = BoundingBox(west: -0.165, south: 51.42, east: -0.125, north: 51.45)
    private let user = Coordinate(latitude: 51.4431, longitude: -0.1525)

    @Test func listRequestCarriesAreaAmenityLimitLocationAndClock() async throws {
        let transport = FakeTransport.json(#"{ "pubs": [], "count": 0 }"#)
        _ = try await PubDBClient.testing(transport).pubs(in: balham, near: user)

        let request = try #require(transport.requests.first)
        let path = request.url?.path
        #expect(path == "/api/v1/pubs")

        let query = queryItems(request)
        // Longitude first: west,south,east,north is what production accepts.
        #expect(query["bbox"] == "-0.16500,51.42000,-0.12500,51.45000")
        #expect(query["amenity"] == "pub")
        #expect(query["limit"] == "200")
        #expect(query["lat"] == "51.44310")
        #expect(query["lon"] == "-0.15250")
        #expect(query["at"] == "2025-10-15T20:30:00Z")
    }

    @Test func listRequestWithoutALocationSendsNoLatOrLon() async throws {
        let transport = FakeTransport.json(#"{ "pubs": [], "count": 0 }"#)
        _ = try await PubDBClient.testing(transport).pubs(in: balham)

        let request = try #require(transport.requests.first)
        let query = queryItems(request)
        #expect(query["lat"] == nil)
        #expect(query["lon"] == nil)
        #expect(query["at"] != nil)
    }

    @Test func pubIdSlashIsEncodedInTheDetailPath() throws {
        let request = try #require(Endpoint.pub(id: "node/251526423", near: nil).request(baseURL: Self.base, now: .now))
        let path = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.percentEncodedPath }

        #expect(path == "/api/v1/pubs/node%2F251526423")
    }

    @Test func similarPathEncodesTheIdAndAppendsSimilar() throws {
        let request = try #require(Endpoint.similar(to: "way/1223071579", near: nil).request(baseURL: Self.base, now: .now))
        let path = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.percentEncodedPath }

        #expect(path == "/api/v1/pubs/way%2F1223071579/similar")
    }

    @Test func aTrailingSlashOnTheBaseURLDoesNotDoubleUp() throws {
        let base = try #require(URL(string: "https://pubdb.test/api/v1/"))
        let request = try #require(Endpoint.pub(id: "node/1", near: nil).request(baseURL: base, now: .now))
        let path = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.percentEncodedPath }

        #expect(path == "/api/v1/pubs/node%2F1")
    }

    @Test func requestsAskForJSON() throws {
        let request = try #require(Endpoint.pub(id: "node/1", near: nil).request(baseURL: Self.base, now: .now))
        let accept = request.value(forHTTPHeaderField: "Accept")

        #expect(accept == "application/json")
    }

    @Test func boundingBoxFromAMapRegion() {
        let box = BoundingBox(center: Coordinate(latitude: 51.5, longitude: -0.1), latitudeDelta: 0.2, longitudeDelta: 0.4)

        #expect(abs(box.west - -0.3) < 1e-9)
        #expect(abs(box.east - 0.1) < 1e-9)
        #expect(abs(box.south - 51.4) < 1e-9)
        #expect(abs(box.north - 51.6) < 1e-9)
    }

    @Test func boundingBoxContainment() {
        let outer = BoundingBox(west: -1, south: 50, east: 1, north: 52)
        let inner = BoundingBox(west: -0.5, south: 50.5, east: 0.5, north: 51.5)
        let overlapping = BoundingBox(west: 0.5, south: 51, east: 1.5, north: 51.5)

        #expect(outer.contains(inner))
        #expect(!outer.contains(overlapping))
    }

    @Test func boundingBoxIntersection() {
        let london = BoundingBox(west: -0.51, south: 51.28, east: 0.33, north: 51.69)
        let edgeOfLondon = BoundingBox(west: 0.3, south: 51.5, east: 0.5, north: 51.6)
        let brighton = BoundingBox(west: -0.2, south: 50.8, east: -0.1, north: 50.85)

        #expect(london.intersects(edgeOfLondon))
        #expect(edgeOfLondon.intersects(london))
        #expect(!london.intersects(brighton))
    }

    // MARK: - Helpers

    private static let base = URL(string: "https://pubdb.test/api/v1")!

    private func queryItems(_ request: URLRequest) -> [String: String] {
        guard let url = request.url,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return [:] }
        var result: [String: String] = [:]
        for item in items { result[item.name] = item.value ?? "" }
        return result
    }
}
