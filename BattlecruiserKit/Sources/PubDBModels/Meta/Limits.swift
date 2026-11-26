import Foundation

/// The server's limits, so inputs and uploads are checked against what it will accept.
public struct Limits: Decodable, Hashable, Sendable {
    public let maxLimit: Int
    public let defaultLimit: Int
    public let maxReviewBody: Int
    public let maxAuthor: Int
    /// The rating scale. Never hard-code it: it has changed once.
    public let minRating: Int
    public let maxRating: Int
    public let maxUploadBytes: Int
    public let minPhotoSide: Int
    /// Shrink photos to this long side before uploading.
    public let clientMaxSide: Int
    public let maxCaption: Int
    public let dailyPhotoLimit: Int
    /// Shown on the upload screen, e.g. "CC BY-SA 4.0".
    public let photoLicense: String
}
