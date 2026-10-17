import SwiftUI
import DesignSystem
import PubDBModels

/// What matters at closing time: open or not, how long left, when you'll be
/// turned out, and what a pint costs. Every string is the server's.
struct TonightSection: View {
    let summary: PubSummary
    let gardenCloses: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                OpenPill(pub: summary)
                if let countdown = summary.open.countdownLabel {
                    Text(countdown + " left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if let tonight = summary.tonight {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(tonight.symbol.emoji) \(tonight.label) tonight")
                        .font(.body.weight(.semibold))
                    Text(reportsLabel(tonight.reports))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            if let guinness = summary.guinness {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Guinness \(guinness.formatted)")
                        .font(.body.weight(.semibold))
                    Text("\(guinness.agoLabel) · \(reportsLabel(guinness.reports))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            if let gardenCloses {
                Label("Garden closes \(gardenCloses)", systemImage: "leaf")
                    .font(.subheadline)
            }
        }
    }

    private func reportsLabel(_ count: Int) -> String {
        count == 1 ? "1 report" : "\(count) reports"
    }
}
