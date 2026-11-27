import Foundation

/// Every Guinness price reported, oldest first, for the price graph.
public struct PriceHistory: Decodable, Hashable, Sendable {
    public struct Point: Decodable, Hashable, Sendable {
        public let pence: Int
        public let at: String
        public let formatted: String
    }

    public let points: [Point]
    public let minPence: Int?
    public let maxPence: Int?
}
