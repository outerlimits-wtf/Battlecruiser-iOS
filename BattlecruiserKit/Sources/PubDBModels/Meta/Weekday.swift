import Foundation

public struct Weekday: Decodable, Hashable, Sendable, Identifiable {
    /// 0 = Monday.
    public let day: Int
    /// "Mon". Also the value quiz and karaoke nights are contributed as.
    public let short: String
    /// "Monday".
    public let long: String

    public var id: Int { day }
}
