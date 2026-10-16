import Foundation

/// One pub as it appears in a list or on the map: everything needed to draw a
/// pin or a row. Every display string arrives ready-made from the server; show
/// the labels as sent rather than formatting the raw numbers (decision D12).
public struct PubSummary: Decodable, Hashable, Sendable, Identifiable {
    /// The OpenStreetMap id, e.g. "node/123". Contains a slash.
    public let id: String
    public let name: String
    public let amenity: LabelledSymbol
    public let lat: Double
    public let lon: Double
    public let address: String?
    public let postcode: String?
    public let brand: String?
    /// Present only when the request carried `lat` and `lon`.
    public let distance: Distance?
    public let status: PubStatus
    public let open: OpenInfo
    /// When people are turned out tonight, else when the bell goes; nil if nobody has said.
    public let tonight: Tonight?
    public let guinness: Guinness?
    /// Average review rating out of 10; nil with no reviews.
    public let rating: Double?
    public let reviewCount: Int
    public let photo: Photo?
    /// Only the features answered "yes", already ordered.
    public internal(set) var features: [LabelledSymbol]
    public let listed: Bool
}

public struct Distance: Decodable, Hashable, Sendable {
    public let metres: Int
    public let label: String
}

/// Whether the pub still exists. Branch on `serving` and `permanent`, never on
/// `key`, because more states will be added.
public struct PubStatus: Decodable, Hashable, Sendable {
    public let key: String
    public let label: String
    public let symbol: Symbol
    /// Can you get a drink here at all. False for anything but a trading pub.
    public let serving: Bool
    /// Is it gone for good. False for "shut for a refit".
    public let permanent: Bool
}

/// Open or closed at the moment the request's `at` named. Goes stale with the clock.
public struct OpenInfo: Decodable, Hashable, Sendable {
    public let state: OpenState
    /// Pill text: "Closes 23:00", "Closed", "Hours unknown".
    public let label: String
    /// Wall-clock minute of the closing day (60 = 01:00). Never subtract this from
    /// the clock; count down `minutesUntilClose` instead.
    public let closesAt: Int?
    public let closesAtLabel: String?
    public let minutesUntilClose: Int?
    /// "1h 24m", "15 min". Nil unless open.
    public let countdownLabel: String?
    /// Within an hour of closing.
    public let closingSoon: Bool
}

public enum OpenState: String, Decodable, Hashable, Sendable {
    case open
    case closed
    /// No hours on record. Must not be drawn as either open or closed.
    case unknown

    /// Any state the server adds later is treated as unknown rather than failing.
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = OpenState(rawValue: raw) ?? .unknown
    }
}

/// Tonight's last orders or kicked-out time. `minutes` can exceed 1440 and
/// `label` can read "24:40"; both are deliberate, so show `label` as sent.
public struct Tonight: Decodable, Hashable, Sendable {
    /// "kicked_out" or "last_orders".
    public let kind: String
    public let label: String
    public let symbol: Symbol
    public let minutes: Int
    public let reports: Int
}

public struct Guinness: Decodable, Hashable, Sendable {
    public let pence: Int
    /// "£6.20".
    public let formatted: String
    public let reports: Int
    public let updatedAt: String
    /// "a month ago", relative to the request's `at`.
    public let agoLabel: String
}

/// Showing `attribution` and `license` beside the photo is a licence condition.
public struct Photo: Decodable, Hashable, Sendable {
    public let url: String
    public let thumbUrl: String
    public let license: String?
    public let attribution: String?
    public let descriptionUrl: String?

    public var imageURL: URL? { URL(string: url) }
    public var thumbnailURL: URL? { URL(string: thumbUrl) }
    public var descriptionURL: URL? { descriptionUrl.flatMap(URL.init(string:)) }
}
