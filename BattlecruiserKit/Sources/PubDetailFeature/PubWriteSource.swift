import Foundation
import PubDBClient
import PubDBModels

/// The writes the panel makes. `PubDBClient` in the app.
public protocol PubWriteSource: Sendable {
    func postReview(_ pubID: String, rating: Int, body: String?, near location: Coordinate?) async throws -> WriteResult
    func deleteReview(_ id: Int, from pubID: String) async throws -> WriteResult
    func sendReport(type: String, id: String, reason: String) async throws -> WriteResult
    func like(_ reviewID: Int, on pubID: String, _ on: Bool) async throws -> LikeChange
    func addFact(to pubID: String, field: String, value: String, near location: Coordinate?) async throws -> WriteResult
    func deleteFact(_ id: Int, from pubID: String) async throws -> WriteResult
    func sendPhoto(to pubID: String, jpeg: Data, kind: String, caption: String?) async throws -> PhotoUploadResult
    /// Every known operator with its pub count, for the operator picker.
    func brands() async throws -> [Brand]
}

extension PubDBClient: PubWriteSource {
    public nonisolated func postReview(_ pubID: String, rating: Int, body: String?, near location: Coordinate?) async throws -> WriteResult {
        try await review(pubID, rating: rating, body: body, near: location)
    }

    public nonisolated func deleteReview(_ id: Int, from pubID: String) async throws -> WriteResult {
        try await removeReview(id, from: pubID)
    }

    public nonisolated func sendReport(type: String, id: String, reason: String) async throws -> WriteResult {
        try await report(type: type, id: id, reason: reason)
    }

    public nonisolated func like(_ reviewID: Int, on pubID: String, _ on: Bool) async throws -> LikeChange {
        try await setLike(reviewID, on: pubID, on)
    }

    public nonisolated func addFact(to pubID: String, field: String, value: String, near location: Coordinate?) async throws -> WriteResult {
        try await contribute(to: pubID, field: field, value: value, near: location)
    }

    public nonisolated func deleteFact(_ id: Int, from pubID: String) async throws -> WriteResult {
        try await removeContribution(id, from: pubID)
    }

    public nonisolated func sendPhoto(to pubID: String, jpeg: Data, kind: String, caption: String?) async throws -> PhotoUploadResult {
        try await uploadPhoto(
            to: pubID,
            image: MultipartForm.File(filename: "photo.jpg", mimeType: "image/jpeg", data: jpeg),
            kind: kind,
            caption: caption
        )
    }
}
