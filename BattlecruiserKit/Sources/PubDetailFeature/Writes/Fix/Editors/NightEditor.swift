import SwiftUI
import DesignSystem
import PubDBModels

/// `night` in the Fix panel: there's only something to add, so a button that
/// opens the night form.
struct NightEditor: View {
    let field: ContributableField
    let weekdays: [Weekday]
    let session: NightSession?
    let send: (String) -> Void

    @State private var isOpen = false

    var body: some View {
        Button("Report \(field.label.lowercased())") { isOpen = true }
            .buttonStyle(ChipStyle())
            .sheet(isPresented: $isOpen) {
                NightFormSheet(field: field, weekdays: weekdays, session: session, send: send)
            }
    }
}
