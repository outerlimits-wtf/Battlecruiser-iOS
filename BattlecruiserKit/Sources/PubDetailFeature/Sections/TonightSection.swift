import SwiftUI
import DesignSystem
import PubDBModels

/// What matters at closing time: open or not, how long left, when you'll be
/// turned out, and what a pint costs. Every string is the server's.
struct TonightSection: View {
    let summary: PubSummary
    let gardenCloses: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            line {
                OpenPill(pub: summary)
                if let countdown = summary.open.countdownLabel {
                    Text(countdown + " left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(spokenCountdown ?? countdown + " left")
                }
            }
            if let tonight = summary.tonight {
                line {
                    Text("\(tonight.symbol.emoji) \(tonight.label) tonight")
                        .font(.body.weight(.semibold))
                    Text(reportsLabel(tonight.reports))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            if let guinness = summary.guinness {
                line {
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

    /// Side by side normally; stacked at accessibility text sizes so nothing
    /// is cut off. Read by VoiceOver as one element either way.
    private func line<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))
        return layout {
            content()
        }
        .accessibilityElement(children: .combine)
    }

    /// "1 hour, 24 minutes left", for VoiceOver.
    private var spokenCountdown: String? {
        summary.open.minutesUntilClose.map { Spoken.countdown(minutes: $0) + " left" }
    }

    private func reportsLabel(_ count: Int) -> String {
        count == 1 ? "1 report" : "\(count) reports"
    }
}
