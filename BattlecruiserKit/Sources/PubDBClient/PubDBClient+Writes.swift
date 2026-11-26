import Foundation
import PubDBModels

/// Adding to a pub, and taking your own additions back. All need sign-in.
extension PubDBClient {
    /// One fact: `field` is a `/meta` contributable field key, `value` as its
    /// kind takes it. A repeat of a non-corroborating value is `409`.
    public func contribute(to pubID: String, field: String, value: String) async throws -> WriteResult {
        try await send(.contribute(to: pubID, field: field, value: value))
    }

    public func removeContribution(_ id: Int, from pubID: String) async throws -> WriteResult {
        try await send(.removeContribution(id, from: pubID))
    }

    /// A score within `/meta`'s rating limits, and optionally some words.
    public func review(_ pubID: String, rating: Int, body: String?) async throws -> WriteResult {
        try await send(.review(pubID, rating: rating, body: body))
    }

    public func removeReview(_ id: Int, from pubID: String) async throws -> WriteResult {
        try await send(.removeReview(id, from: pubID))
    }

    /// Flag a photo, review or contribution for an admin. Takes nothing down.
    public func report(type: String, id: String, reason: String, note: String? = nil) async throws -> WriteResult {
        try await send(.report(type: type, id: id, reason: reason, note: note))
    }

    /// A photo: JPEG at most `/meta`'s `clientMaxSide`, a `/meta` photo kind,
    /// and an optional caption. Shared under `/meta`'s `photoLicense`.
    public func uploadPhoto(to pubID: String, image: MultipartForm.File, kind: String, caption: String?) async throws -> PhotoUploadResult {
        try await send(.uploadPhoto(to: pubID, image: image, kind: kind, caption: caption))
    }
}
