import Foundation
import Testing
import PubDBClient
import PubDBModels
@testable import PubsFeature

/// The pills say what they've set, in the web's words.
@MainActor
struct FilterLabelsTests {
    @Test func kindNamesTheGroup() {
        var query = PubQuery()
        #expect(FilterLabels.kind(query) == "Pubs")
        query.amenity = nil
        #expect(FilterLabels.kind(query) == "Pubs & bars")
    }

    @Test func kindNamesThePickedTypeAndCountsTheRest() throws {
        let kinds = try JSONDecoder().decode([VenueKind].self, from: Data(#"""
        [{"key": "taproom", "group": "pub", "label": "Taproom", "symbol": {"key": "amenity.taproom", "type": "emoji", "emoji": "🍺", "url": null}, "note": null},
         {"key": "oddity", "group": "bar", "label": "Oddity", "symbol": {"key": "amenity.oddity", "type": "emoji", "emoji": "🦄", "url": null}, "note": null}]
        """#.utf8))
        var query = PubQuery()
        query.kinds = ["oddity"]
        #expect(FilterLabels.kind(query, all: kinds) == "Oddity")
        #expect(FilterLabels.isActive(.kind, in: query))
        query.kinds = ["oddity", "taproom"]
        #expect(FilterLabels.kind(query, all: kinds) == "Taproom +1")
    }

    @Test func pillsThatAreSetMoveToTheFront() {
        var query = PubQuery()
        #expect(FilterPill.ordered(for: query).first == .openNow)
        query.latestClose = true
        query.minRating = 7
        #expect(Array(FilterPill.ordered(for: query).prefix(2)) == [.panel(.rating), .latestClose])
    }

    @Test func hoursPicksTheMostSpecificSetting() {
        var query = PubQuery()
        #expect(FilterLabels.hours(query, weekdays: []) == "Hours")
        query.hasHours = true
        #expect(FilterLabels.hours(query, weekdays: []) == "Has hours")
        query.closesAfter = "23:00"
        #expect(FilterLabels.hours(query, weekdays: []) == "Open past 23:00")
    }

    @Test func featuresCountsOrNamesTheOne() {
        var query = PubQuery()
        #expect(FilterLabels.features(query, all: []) == "Features")
        query.features = ["a", "b"]
        #expect(FilterLabels.features(query, all: []) == "2 features")
    }

    @Test func ratingAndGuinnessShowTheirLimit() {
        var query = PubQuery()
        query.minRating = 7
        query.maxGuinnessPence = 600
        #expect(FilterLabels.rating(query) == "7+ ★")
        #expect(FilterLabels.guinness(query) == "Under £6.00")
        #expect(FilterLabels.isActive(.guinness, in: query))
        #expect(!FilterLabels.isActive(.kind, in: query))
    }
}
