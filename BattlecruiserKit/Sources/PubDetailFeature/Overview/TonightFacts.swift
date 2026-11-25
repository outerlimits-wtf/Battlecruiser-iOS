import SwiftUI
import DesignSystem
import PubDBModels

/// Tonight, as drinkers reported it: when the bell goes, when you're out, when
/// the garden shuts. Nothing at all when nobody has said.
struct TonightFacts: View {
    let tonight: WeekRow?
    let gardenCloses: String?

    var body: some View {
        if tonight?.bell != nil || tonight?.out != nil || gardenCloses != nil {
            VStack(alignment: .leading, spacing: Metrics.s) {
                SectionHeader("Tonight")
                if let bell = tonight?.bell {
                    fact("🔔", "Last orders", bell.label, reports: bell)
                }
                if let out = tonight?.out {
                    fact("🚪", "Kicked out", out.label, reports: out)
                }
                if let gardenCloses {
                    fact("🌳", "Garden shuts", gardenCloses, reports: nil)
                }
            }
        }
    }

    private func fact(_ emoji: String, _ title: String, _ value: String, reports: NightFigure?) -> some View {
        HStack(spacing: Metrics.s) {
            Text(emoji).accessibilityHidden(true)
            Text(title).foregroundStyle(Palette.inkMuted)
            Text(value).fontWeight(.semibold).foregroundStyle(Palette.ink)
        }
        .font(Typography.body)
        .accessibilityElement(children: .combine)
        .accessibilityHint(reports.map { "\($0.reports) reports, last on \($0.latestLabel)" } ?? "")
    }
}
