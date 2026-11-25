import SwiftUI
import DesignSystem
import PubDBModels

/// The Reviews tab: what drinkers said, newest first, the first three then
/// the rest on request. Writing one comes with sign-in (Phase E).
struct ReviewsTab: View {
    let reviews: [Review]

    /// How many show before "Show more".
    static let collapsedCount = 3

    @State private var isExpanded = false

    var body: some View {
        if reviews.isEmpty {
            Text("Not a word from anybody. Make of that what you will.")
                .font(Typography.body)
                .foregroundStyle(Palette.inkMuted)
        } else {
            VStack(alignment: .leading, spacing: Metrics.l) {
                ForEach(isExpanded ? reviews : Array(reviews.prefix(Self.collapsedCount))) { review in
                    ReviewRow(review: review)
                }
                if reviews.count > Self.collapsedCount && !isExpanded {
                    Button("Show \(reviews.count - Self.collapsedCount) more") { isExpanded = true }
                        .buttonStyle(ChipStyle())
                }
            }
        }
    }
}
