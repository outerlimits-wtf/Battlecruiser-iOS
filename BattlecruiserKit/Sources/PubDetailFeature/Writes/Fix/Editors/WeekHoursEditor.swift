import SwiftUI
import DesignSystem
import PubDBModels

/// Opening hours in the Fix panel: what the pub has now, and Edit, which
/// opens the week editor.
struct WeekHoursEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let weekTable: [WeekRow]
    let send: (String) -> Void

    @State private var isEditing = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.s) {
            if weekTable.isEmpty {
                CurrentValue(label: field.label, current: current)
            } else {
                Grid(alignment: .leading, horizontalSpacing: Metrics.s, verticalSpacing: 2) {
                    ForEach(weekTable) { row in
                        GridRow {
                            Text(row.dayLabel).foregroundStyle(Palette.inkMuted)
                            Text(row.doorSays ?? "Unknown").foregroundStyle(Palette.ink)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(row.dayLongLabel): \(row.doorSays ?? "unknown")")
                    }
                }
                .font(Typography.secondary)
            }
            Spacer()
            Button("Edit") { isEditing = true }
                .buttonStyle(ChipStyle())
                .accessibilityLabel("Edit \(field.label.lowercased())")
        }
        .sheet(isPresented: $isEditing) {
            HoursEditorSheet(title: field.label, week: WeekHours(weekTable: weekTable), onSave: send)
        }
    }
}
