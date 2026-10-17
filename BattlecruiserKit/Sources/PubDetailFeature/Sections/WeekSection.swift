import SwiftUI
import PubDBModels

/// The week at a glance: what the door says, when the bell goes, and when you
/// are actually turned out. Tonight's row is emphasised. Times past midnight
/// read "24:40" on purpose; they are shown as the server sends them.
///
/// At accessibility text sizes the grid would overflow, so each night stacks.
/// VoiceOver hears each night as one sentence (`Spoken.weekRow`) rather than
/// the grid cell by cell.
struct WeekSection: View {
    let rows: [WeekRow]
    let hoursAttribution: Attribution?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("This week")
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        stacked
                    } else {
                        grid
                    }
                }
                .accessibilityRepresentation {
                    VStack(alignment: .leading) {
                        ForEach(rows) { row in
                            Text(Spoken.weekRow(row))
                        }
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

    private var grid: some View {
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
    }

    /// One block per night, for very large text.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.dayLongLabel)
                        .fontWeight(.bold)
                    Text("Open \(row.doorSays ?? "–")")
                    Text("Last orders \(row.bell?.label ?? "–")")
                    Text("Out \(row.out?.label ?? "–")")
                }
                .font(.subheadline)
                .fontWeight(row.isTonight ? .bold : .regular)
            }
        }
    }
}
