import Foundation

/// What the user is looking for: a search and the filters, sent as-is to
/// `/pubs` and `/pins`. The server does the filtering; this only names it, in
/// the same parameters the web's `lib/query.ts` builds.
public struct PubQuery: Hashable, Sendable {
    /// A name, street or brewery (`q`). Searching ignores the map's area.
    public var search = ""
    /// Look everywhere, not just the map's area.
    public var everywhere = false
    /// "pub" or "bar"; nil for both. Not sent while `kinds` is set.
    public var amenity: String? = PubQuery.defaultAmenity
    /// Venue kind keys from `/meta` (`taproom`, `oddity`…), any of which will
    /// do. Kinds cross the pub and bar groups, so they replace `amenity`.
    /// Needs server ask S18; until then the server ignores it.
    public var kinds: Set<String> = []
    public var openNow = false
    /// 0 = Monday.
    public var openOnDay: Int?
    /// "HH:MM": open by this time.
    public var opensBefore: String?
    /// "HH:MM": still open at this time.
    public var closesAfter: String?
    /// Feature keys, all of which must be "yes".
    public var features: Set<String> = []
    public var minRating: Int?
    public var hasHours = false
    public var hasPhoto = false
    public var listed = false
    public var maxGuinnessPence: Int?
    /// Include pubs that have shut (`status=any`).
    public var includeClosed = false
    /// Sort by the latest close on any day (`sortBy=latest_close`).
    public var latestClose = false

    /// Pubs only until someone asks for bars (decision D4).
    public static let defaultAmenity = "pub"

    public init() {}

    var trimmedSearch: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the map's area limits the list. Not when searching or "everywhere".
    public var usesArea: Bool {
        trimmedSearch.isEmpty && !everywhere
    }

    /// How many filters are set, for "Reset" and "Clear filters".
    public var activeFilterCount: Int {
        var count = features.count + kinds.count
        if !trimmedSearch.isEmpty { count += 1 }
        if amenity != Self.defaultAmenity { count += 1 }
        for flag in [openNow, hasHours, hasPhoto, listed, includeClosed, latestClose] where flag { count += 1 }
        for value in [openOnDay, minRating, maxGuinnessPence] as [Int?] where value != nil { count += 1 }
        for value in [opensBefore, closesAfter] where value != nil { count += 1 }
        return count
    }

    /// The filter parameters, without area, location or limit.
    var items: [URLQueryItem] {
        var items: [URLQueryItem] = []
        func add(_ name: String, _ value: String?) {
            if let value { items.append(URLQueryItem(name: name, value: value)) }
        }
        add("q", trimmedSearch.isEmpty ? nil : trimmedSearch)
        add("amenity", kinds.isEmpty ? amenity : nil)
        add("kinds", kinds.isEmpty ? nil : kinds.sorted().joined(separator: ","))
        add("openNow", openNow ? "1" : nil)
        add("openOnDay", openOnDay.map(String.init))
        add("opensBefore", opensBefore)
        add("closesAfter", closesAfter)
        add("features", features.isEmpty ? nil : features.sorted().joined(separator: ","))
        add("minRating", minRating.map(String.init))
        add("hasHours", hasHours ? "1" : nil)
        add("hasPhoto", hasPhoto ? "1" : nil)
        add("listed", listed ? "1" : nil)
        add("maxGuinnessPrice", maxGuinnessPence.map(String.init))
        add("sortBy", latestClose ? "latest_close" : nil)
        add("status", includeClosed ? "any" : nil)
        return items
    }
}
