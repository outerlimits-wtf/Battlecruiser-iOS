import Foundation

public struct FeatureAnswer: Decodable, Hashable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let symbol: Symbol
    public let value: FeatureValue

    public var id: String { key }
}
