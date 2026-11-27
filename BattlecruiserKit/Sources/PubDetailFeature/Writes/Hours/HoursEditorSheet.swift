import SwiftUI
import DesignSystem

/// Opening hours, a day at a time, prefilled from the week table. Save sends
/// the whole week as one structured value; days left unset count as closed.
struct HoursEditorSheet: View {
    let title: String
    let onSave: (String) -> Void

    @State private var week: WeekHours
    private let original: WeekHours
    @Environment(\.dismiss) private var dismiss

    init(title: String, week: WeekHours, onSave: @escaping (String) -> Void) {
        self.title = title
        self.onSave = onSave
        _week = State(initialValue: week)
        original = week
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(week.days.indices, id: \.self) { index in
                        DayHoursRow(name: week.names[index], day: $week.days[index]) {
                            week.copyToEveryDay(from: index)
                        }
                    }
                } footer: {
                    Text("A day left unset is saved as closed. Pick Don't know if nobody's sure.")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = week.value { onSave(value) }
                        dismiss()
                    }
                    .disabled(week == original || week.value == nil)
                }
            }
        }
    }
}
