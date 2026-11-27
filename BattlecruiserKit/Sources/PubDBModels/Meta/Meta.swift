import Foundation

/// `GET /meta`: every list, label and limit the UI needs, so nothing that lives
/// on the server is hard-coded in the app. Fetched at launch and cached; it
/// changes only when the server does.
public struct Meta: Decodable, Hashable, Sendable {
    /// The two groups the `amenity` filter takes: pubs and bars.
    public let amenities: [Amenity]
    /// What a place can actually be (gastropub, wine bar, club…), each in a group.
    public let venueKinds: [VenueKind]
    public let features: [LabelledSymbol]
    /// Monday first (`day` 0).
    public let weekdays: [Weekday]
    /// What can be contributed, and which editor draws each (`kind`).
    public let contributableFields: [ContributableField]
    public let boards: [BoardInfo]
    public let photoKinds: [PhotoKind]
    public let reportReasons: [ReportReason]
    public let clients: ClientRules
    public let limits: Limits
    /// The levels and what earns XP (S16); nil until the server sends them.
    public let levels: [LevelInfo]?
    public let xpRules: [XPRule]?
}
