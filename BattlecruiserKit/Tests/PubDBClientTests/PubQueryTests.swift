import Foundation
import Testing
@testable import PubDBClient

/// The same parameters the web's `buildQuery` sends.
struct PubQueryTests {
    private let area = BoundingBox(west: -0.2, south: 51.4, east: -0.1, north: 51.5)

    private func items(_ endpoint: Endpoint) -> [String: String] {
        Dictionary(endpoint.query.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
    }

    @Test func theDefaultIsPubsInTheAreaWithNoFilters() {
        let sent = items(.pubs(matching: PubQuery(), in: area, near: nil, limit: 200))

        #expect(Set(sent.keys) == ["bbox", "amenity", "limit"])
        #expect(sent["amenity"] == "pub")
    }

    @Test func kindsReplaceTheAmenityGroup() {
        var query = PubQuery()
        query.kinds = ["taproom", "oddity"]

        let sent = items(.pubs(matching: query, in: area, near: nil, limit: 200))

        #expect(sent["kinds"] == "oddity,taproom")
        #expect(sent["amenity"] == nil)
        #expect(query.activeFilterCount == 2)
    }

    @Test func everyFilterIsSentUnderTheServersName() {
        var query = PubQuery()
        query.amenity = nil
        query.openNow = true
        query.openOnDay = 4
        query.opensBefore = "18:00"
        query.closesAfter = "23:30"
        query.features = ["garden", "darts"]
        query.minRating = 7
        query.hasHours = true
        query.hasPhoto = true
        query.listed = true
        query.maxGuinnessPence = 600
        query.includeClosed = true
        query.latestClose = true

        let sent = items(.pubs(matching: query, in: area, near: nil, limit: 200))

        #expect(sent["amenity"] == nil)
        #expect(sent["openNow"] == "1")
        #expect(sent["openOnDay"] == "4")
        #expect(sent["opensBefore"] == "18:00")
        #expect(sent["closesAfter"] == "23:30")
        #expect(sent["features"] == "darts,garden")
        #expect(sent["minRating"] == "7")
        #expect(sent["hasHours"] == "1" && sent["hasPhoto"] == "1" && sent["listed"] == "1")
        #expect(sent["maxGuinnessPrice"] == "600")
        #expect(sent["status"] == "any")
        #expect(sent["sortBy"] == "latest_close")
        #expect(query.activeFilterCount == 14)
    }

    @Test func aSearchOrEverywhereDropsTheArea() {
        var search = PubQuery()
        search.search = "  red lion "
        var everywhere = PubQuery()
        everywhere.everywhere = true

        #expect(items(.pubs(matching: search, in: area, near: nil, limit: 200))["bbox"] == nil)
        #expect(items(.pubs(matching: search, in: area, near: nil, limit: 200))["q"] == "red lion")
        #expect(items(.pubs(matching: everywhere, in: area, near: nil, limit: 200))["bbox"] == nil)
    }

    @Test func pinsCarryTheFiltersButNeverAnAreaOrLimit() {
        var query = PubQuery()
        query.openNow = true

        let sent = items(.pins(matching: query))

        #expect(sent["openNow"] == "1")
        #expect(sent["bbox"] == nil && sent["limit"] == nil)
    }
}
