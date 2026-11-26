import Foundation

public struct TimelineStop: Decodable, Hashable, Sendable {
    public let name: String
    public let fromLabel: String?
    public let untilLabel: String?
    public let owner: String?
    public let isCurrent: Bool
    public let attribution: Attribution?
}
