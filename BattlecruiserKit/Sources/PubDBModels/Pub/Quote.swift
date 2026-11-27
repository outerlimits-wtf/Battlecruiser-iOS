import Foundation

/// A line pulled from one of the pub's reviews, already cut to length.
public struct Quote: Decodable, Hashable, Sendable {
    public let reviewId: Int
    public let rating: Int
    public let text: String
    /// True when `text` was cut short; show an ellipsis.
    public let truncated: Bool
}
