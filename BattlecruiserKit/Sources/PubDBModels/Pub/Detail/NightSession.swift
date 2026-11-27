import Foundation

/// The night a report made now belongs to (S3): at 00:30 on a Friday it is
/// Thursday. Night editors start on it; the app never applies the 06:00 cutoff.
public struct NightSession: Decodable, Hashable, Sendable {
    /// 0 is Monday.
    public let day: Int
    /// "Thu".
    public let short: String
    /// "Thursday".
    public let long: String
}
