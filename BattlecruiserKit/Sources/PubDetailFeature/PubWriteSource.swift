import PubDBClient
import PubDBModels

/// The writes the panel makes. `PubDBClient` in the app.
public protocol PubWriteSource: Sendable {
    func postReview(_ pubID: String, rating: Int, body: String?) async throws -> WriteResult
    func deleteReview(_ id: Int, from pubID: String) async throws -> WriteResult
    func sendReport(type: String, id: String, reason: String) async throws -> WriteResult
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
}
