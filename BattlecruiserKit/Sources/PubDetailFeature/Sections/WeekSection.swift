import SwiftUI
import PubDBModels

/// The week at a glance: what the door says, when the bell goes, and when you
/// are actually turned out. Tonight's row is emphasised. Times past midnight
/// read "24:40" on purpose; they are shown as the server sends them.
struct WeekSection: View {
    let rows: [WeekRow]
    let hoursAttribution: Attribution?

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("This week")
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                    GridRow {
                        Text("")
                        Text("Open")
                        Text("Last orders")
                        Text("Out")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    ForEach(rows) { row in
                        GridRow {
                            Text(row.dayLabel)
                            Text(row.doorSays ?? "–")
                            Text(row.bell?.label ?? "–")
                            Text(row.out?.label ?? "–")
                        }
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(row.isTonight ? .bold : .regular)
                    }
                }
                if let hoursAttribution {
                    Text("Opening hours from \(hoursAttribution.label). Last orders and out times are reported by drinkers.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
