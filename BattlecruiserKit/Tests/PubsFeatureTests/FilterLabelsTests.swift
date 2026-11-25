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

    @Test func hoursPicksTheMostSpecificSetting() {
        var query = PubQuery()
        #expect(FilterLabels.hours(query, weekdays: []) == "Hours")
        query.hasHours = true
        #expect(FilterLabels.hours(query, weekdays: []) == "Has hours")
        query.opensBefore = "18:00"
        #expect(FilterLabels.hours(query, weekdays: []) == "Open by 18:00")
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
