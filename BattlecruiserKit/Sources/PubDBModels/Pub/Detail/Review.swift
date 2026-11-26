import Foundation

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
    /// The writer's picture, if they have one.
    public let avatarUrl: String?
    /// Whether the signed-in person may delete it.
    public let canRemove: Bool?
    /// How many accounts like it, and whether the signed-in person does.
    public let likes: Int?
    public let likedByMe: Bool?

    public var avatarURL: URL? { avatarUrl.flatMap(URL.init(string:)) }

    /// The text to show, or nil when there is none worth showing.
    public var text: String? {
        guard let trimmed = body?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
