import Foundation
import PubDBClient
import PubDBModels

/// Sends one fact and reports back in the web's words: the server's message
/// for a refusal (a repeat is `409 duplicate_value`), nothing for a cancel.
struct FactWriter {
    let context: PanelContext
    let pubID: String
    let onChanged: (WriteResult) -> Void
    let onError: (String) -> Void

    func send(_ field: String, _ value: String) {
        Task {
            do {
                onChanged(try await context.writer.addFact(to: pubID, field: field, value: value, near: context.location))
            } catch {
                if let message = PubDBError.wrapping(error)?.userMessage { onError(message) }
            }
        }
    }
}
