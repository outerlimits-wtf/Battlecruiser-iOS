import SwiftUI
import DesignSystem
import PubDBModels

/// "OPENING HOURS": what the door says, when the bell goes, when you're out,
/// each night; tonight highlighted. Times past midnight read "24:40" on
/// purpose and are shown as sent. VoiceOver hears each night as a sentence.
struct WeekTable: View {
    let rows: [WeekRow]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if rows.contains(where: { $0.doorSays != nil || $0.bell != nil || $0.out != nil }) {
            VStack(alignment: .leading, spacing: Metrics.s) {
                SectionHeader("Opening hours")
                Group {
                    if dynamicTypeSize.isAccessibilitySize { stacked } else { grid }
                }
                .accessibilityRepresentation {
                    VStack(alignment: .leading) {
                        ForEach(rows) { Text(Spoken.weekRow($0)) }
                    }
                }
                if reports > 0 {
                    Text("Last orders and kicked-out times are the middle of \(reports) \(reports == 1 ? "report" : "reports") from people who were there.")
                        .font(Typography.secondary)
                        .foregroundStyle(Palette.inkMuted)
                }
            }
        }
    }

    private var reports: Int {
        rows.reduce(0) { $0 + ($1.bell?.reports ?? 0) + ($1.out?.reports ?? 0) }
    }

    private var grid: some View {
        Grid(alignment: .leading, horizontalSpacing: Metrics.m, verticalSpacing: 0) {
            GridRow {
                Text("")
                Text("DOOR SAYS")
                Text("🔔 BELL")
                Text("🚪 OUT")
            }
            .font(Typography.sectionHeader)
            .foregroundStyle(Palette.inkMuted)
            .padding(.vertical, 6)
            ForEach(rows) { row in
                GridRow {
                    Text(row.dayLabel).fontWeight(.semibold)
                    Text(row.doorSays ?? "Not known")
                    Text(row.bell?.label ?? "·")
                    Text(row.out?.label ?? "·")
                }
                .font(Typography.body.monospacedDigit())
                .foregroundStyle(row.isTonight ? Palette.beer : Palette.ink)
                .padding(.vertical, 6)
                .background(row.isTonight ? Palette.beerSoft : .clear)
            }
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.dayLongLabel).fontWeight(.bold)
                    Text("Door says \(row.doorSays ?? "not known")")
                    Text("Bell \(row.bell?.label ?? "not reported")")
                    Text("Out \(row.out?.label ?? "not reported")")
                }
                .font(Typography.body)
                .foregroundStyle(row.isTonight ? Palette.beer : Palette.ink)
            }
        }
    }
}
