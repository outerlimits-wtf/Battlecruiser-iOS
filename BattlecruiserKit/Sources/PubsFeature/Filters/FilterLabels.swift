import Foundation
import PubDBClient
import PubDBModels

/// What each filter pill says, so it reads as the filter it has set, as on the web.
enum FilterLabels {
    static func kind(_ query: PubQuery) -> String {
        switch query.amenity {
        case "pub": "Pubs"
        case "bar": "Bars"
        default: "Pubs & bars"
        }
    }

    /// "Open Mon", "Open past 23:00", "Has hours", else "Hours".
    static func hours(_ query: PubQuery, weekdays: [Weekday]) -> String {
        if let day = query.openOnDay {
            return "Open \(weekdays.first { $0.day == day }?.short ?? "that day")"
        }
        if let time = query.closesAfter { return "Open past \(time)" }
        if query.hasHours { return "Has hours" }
        return "Hours"
    }

    static func features(_ query: PubQuery, all: [LabelledSymbol]) -> String {
        switch query.features.count {
        case 0: return "Features"
        case 1: return all.first { query.features.contains($0.key) }?.label ?? "1 feature"
        case let count: return "\(count) features"
        }
    }

    static func rating(_ query: PubQuery) -> String {
        query.minRating.map { "\($0)+ ★" } ?? "Rating"
    }

    static func guinness(_ query: PubQuery) -> String {
        guard let pence = query.maxGuinnessPence, let label = FilterOptions.guinnessLabel(for: pence) else {
            return "Guinness"
        }
        return "Under \(label)"
    }

    /// Whether a panel's pill shows as set.
    static func isActive(_ panel: FilterPanel, in query: PubQuery) -> Bool {
        switch panel {
        case .kind: query.amenity != PubQuery.defaultAmenity
        case .hours: query.openOnDay != nil || query.closesAfter != nil || query.hasHours
        case .features: !query.features.isEmpty
        case .rating: query.minRating != nil
        case .guinness: query.maxGuinnessPence != nil
        }
    }
}
