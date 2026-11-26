import Foundation
import PubDBClient
import PubDBModels

/// The writes the panel makes. `PubDBClient` in the app.
public protocol PubWriteSource: Sendable {
    func postReview(_ pubID: String, rating: Int, body: String?) async throws -> WriteResult
    func deleteReview(_ id: Int, from pubID: String) async throws -> WriteResult
    func sendReport(type: String, id: String, reason: String) async throws -> WriteResult
    func addFact(to pubID: String, field: String, value: String) async throws -> WriteResult
    func deleteFact(_ id: Int, from pubID: String) async throws -> WriteResult
    func sendPhoto(to pubID: String, jpeg: Data, kind: String, caption: String?) async throws -> PhotoUploadResult
}

extension PubDBClient: PubWriteSource {
    public nonisolated func postReview(_ pubID: String, rating: Int, body: String?) async throws -> WriteResult {
        try await review(pubID, rating: rating, body: body)
    }

    public nonisolated func deleteReview(_ id: Int, from pubID: String) async throws -> WriteResult {
        try await removeReview(id, from: pubID)
    }

    public nonisolated func sendReport(type: String, id: String, reason: String) async throws -> WriteResult {
        try await report(type: type, id: id, reason: reason)
    }

    public nonisolated func addFact(to pubID: String, field: String, value: String) async throws -> WriteResult {
        try await contribute(to: pubID, field: field, value: value)
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
