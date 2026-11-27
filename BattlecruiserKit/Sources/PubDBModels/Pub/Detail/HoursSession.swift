import Foundation

/// One session: wall-clock `HH:MM`. A close at or before its open runs past
/// midnight; `close` nil is "onwards" (`20:00+`).
public struct HoursSession: Codable, Hashable, Sendable {
    public var open: String
    public var close: String?

    public init(open: String, close: String?) {
        self.open = open
        self.close = close
    }

    private enum CodingKeys: String, CodingKey { case open, close }

    /// `close` is always written, as null for "onwards", as the spec shows.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(open, forKey: .open)
        try container.encode(close, forKey: .close)
    }
}
