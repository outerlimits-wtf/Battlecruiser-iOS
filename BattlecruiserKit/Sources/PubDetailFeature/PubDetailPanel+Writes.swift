import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// Writing from the panel: facts, taking them back, and what follows a write.
extension PubDetailPanel {
    func factWriter(_ pubID: String) -> FactWriter? {
        guard context.session.isSignedIn else { return nil }
        return FactWriter(context: context, pubID: pubID, onChanged: changed) { toast = ToastMessage($0, tone: .bad) }
    }

    /// The Guinness price field's bounds, from `/meta`.
    var priceBounds: ClosedRange<Int> {
        let field = context.meta?.contributableFields.first { $0.key == "guinness_price" }
        return (field?.min ?? 200)...(field?.max ?? 1500)
    }

    func removeFact(_ contribution: Contribution, from pubID: String) {
        Task {
            do {
                changed(try await context.writer.deleteFact(contribution.id, from: pubID))
            } catch {
                if let message = PubDBError.wrapping(error)?.userMessage { toast = ToastMessage(message, tone: .bad) }
            }
        }
    }

    /// After a write: say so, and show what the server now has. A change held
    /// for an admin shows the server's message and changes nothing yet.
    func changed(_ result: WriteResult) {
        if result.queued {
            toast = ToastMessage(result.message ?? "Sent to an admin to check.")
            return
        }
        toast = ToastMessage(result.message ?? "Saved. The next person through the door gets that.")
        if let id = model.selectedID { context.marks.noteVisited(id) }
        model.refresh()
        Task { await context.session.load() }
    }
}
