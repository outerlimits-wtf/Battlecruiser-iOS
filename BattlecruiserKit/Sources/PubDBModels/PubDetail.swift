import Foundation

/// One pub in full, from `GET /pubs/{id}`. The server sends every summary field
/// plus the extras below in one flat object; `summary` holds the shared part so a
/// detail screen can start from the summary it already has and fill in the rest.
public struct PubDetail: Decodable, Hashable, Sendable, Identifiable {
    public let summary: PubSummary
    public let description: String?
    public let city: String?
    public let `operator`: String?
    public let brewery: String?
    public let contact: Contact
    public let hours: Hours
    /// Always seven rows, Monday first. The row with `isTonight` is tonight's session.
    public let weekTable: [WeekRow]
    public let gardenCloses: String?
    /// Starts on the current name and runs backwards in time.
    public let timeline: [TimelineStop]
    /// Every feature with its yes/no/unknown answer. `summary.features` keeps only the yeses.
    public let features: [FeatureAnswer]
    /// Drinkers' reviews, in the server's order (newest first).
    public let reviews: [Review]
    /// Where the data came from. Displaying these is a licence condition.
    public let sources: [DataSource]

    public var id: String { summary.id }

    private enum CodingKeys: String, CodingKey {
        case description, city, `operator`, brewery, contact, hours, weekTable,
             gardenCloses, timeline, features, reviews, sources
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        `operator` = try container.decodeIfPresent(String.self, forKey: .operator)
        brewery = try container.decodeIfPresent(String.self, forKey: .brewery)
        contact = try container.decode(Contact.self, forKey: .contact)
        hours = try container.decode(Hours.self, forKey: .hours)
        weekTable = try container.decode([WeekRow].self, forKey: .weekTable)
        gardenCloses = try container.decodeIfPresent(String.self, forKey: .gardenCloses)
        timeline = try container.decode([TimelineStop].self, forKey: .timeline)
        features = try container.decode([FeatureAnswer].self, forKey: .features)
        reviews = try Self.decodeReviews(from: container)
        sources = try container.decode([DataSource].self, forKey: .sources)

        // The detail payload's `features` carries every answer, so decoding a
        // summary from it would wrongly list "no" and "unknown" as features the
        // pub has. Keep the summary true to its meaning: yeses only.
        var summary = try PubSummary(from: decoder)
        summary.features = features
            .filter { $0.value == .yes }
            .map { LabelledSymbol(key: $0.key, label: $0.label, symbol: $0.symbol) }
        self.summary = summary
    }

    /// Reviews are extra to the core of a pub: a missing list, or one review
    /// that can't be read, must not cost the user the whole detail. Lossy in
    /// the same way as `PubList`.
    private static func decodeReviews(from container: KeyedDecodingContainer<CodingKeys>) throws -> [Review] {
        guard container.contains(.reviews), try !container.decodeNil(forKey: .reviews) else {
            return []
        }
        var elements = try container.nestedUnkeyedContainer(forKey: .reviews)
        var reviews: [Review] = []
        while !elements.isAtEnd {
            do {
                reviews.append(try elements.decode(Review.self))
            } catch {
                _ = try elements.decode(SkippedElement.self)
            }
        }
        return reviews
    }
}

/// One drinker's review: a score out of 10 and, usually, a few words.
public struct Review: Decodable, Hashable, Sendable, Identifiable {
    public let id: Int
    /// 1–10. Reviews from before August 2026, rated out of 5, were deleted.
    public let rating: Int
    /// What they wrote; nil or empty when they only gave a score.
    public let body: String?
    public let createdAt: String
    /// Ready to show, e.g. "11 Sept 2026".
    public let createdAtLabel: String
    /// Who wrote it, e.g. "@goatloaf".
    public let attribution: Attribution

    /// The text to show, or nil when there is none worth showing.
    public var text: String? {
        guard let trimmed = body?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

public struct Contact: Decodable, Hashable, Sendable {
    public let phone: String?
    public let website: String?
    public let email: String?
    public let facebook: String?
    public let instagram: String?

    public var websiteURL: URL? { website.flatMap(URL.init(string:)) }
}

/// What the door says. Every field is nil when the hours are unknown; the
/// object itself is still present.
public struct Hours: Decodable, Hashable, Sendable {
    /// The OpenStreetMap opening_hours string. For display only; never parse it.
    public let raw: String?
    public let source: String?
    public let attribution: Attribution?
}

public struct WeekRow: Decodable, Hashable, Sendable, Identifiable {
    /// 0 = Monday.
    public let day: Int
    public let dayLabel: String
    public let dayLongLabel: String
    public let isTonight: Bool
    /// Opening hours for the day, e.g. "12:00–23:00"; nil when unknown.
    public let doorSays: String?
    /// When last orders is called, from drinkers' reports.
    public let bell: NightFigure?
    /// When people are turned out, from drinkers' reports.
    public let out: NightFigure?

    public var id: Int { day }
}

/// A reported time for one night: the median of the last two years of reports.
public struct NightFigure: Decodable, Hashable, Sendable {
    public let minutes: Int
    /// May read "24:40" past midnight; show as sent.
    public let label: String
    public let reports: Int
    public let latestAt: String
    public let latestLabel: String
}

public struct TimelineStop: Decodable, Hashable, Sendable {
    public let name: String
    public let fromLabel: String?
    public let untilLabel: String?
    public let owner: String?
    public let isCurrent: Bool
    public let attribution: Attribution?
}

public struct FeatureAnswer: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let symbol: Symbol
    public let value: FeatureValue

    public var id: String { key }
}

public enum FeatureValue: String, Decodable, Hashable, Sendable {
    case yes
    case no
    case unknown

    /// Any answer the server adds later is treated as unknown rather than failing.
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FeatureValue(rawValue: raw) ?? .unknown
    }
}

/// A dataset the pub's information came from, e.g. OpenStreetMap.
public struct DataSource: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let url: String?

    public var id: String { key }
    public var linkURL: URL? { url.flatMap(URL.init(string:)) }
}
