import Foundation

/// How much of London someone has drunk in: overall and by postcode area.
public struct Coverage: Decodable, Hashable, Sendable {
    public struct Area: Decodable, Hashable, Sendable, Identifiable {
        public let code: String
        public let visited: Int
        public let total: Int
        public let percent: Double

        public var id: String { code }
    }

    public let visited: Int
    public let total: Int
    public let percent: Double
    public let areas: [Area]
}
