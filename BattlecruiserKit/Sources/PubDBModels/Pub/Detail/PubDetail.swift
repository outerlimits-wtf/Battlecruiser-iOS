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
