import SwiftUI
import PubDBModels

/// What drinkers said, newest first, as the server orders it. Read-only: writing
/// a review needs sign-in, which comes later (decision D19). Shows the first few
/// and the rest on request, so a busy pub doesn't push everything else away.
/// Hidden when there are none; the header already says the pub is unrated.
struct ReviewsSection: View {
    let reviews: [Review]

    /// How many show before "Show all".
    static let collapsedCount = 3

    @State private var isExpanded = false

    var body: some View {
        if !reviews.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle("Reviews")
                ForEach(visibleReviews) { review in
                    ReviewRow(review: review)
                }
                if reviews.count > Self.collapsedCount && !isExpanded {
                    Button("Show all \(reviews.count) reviews") {
                        isExpanded = true
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var visibleReviews: [Review] {
        if isExpanded {
            return reviews
        }
        return Array(reviews.prefix(Self.collapsedCount))
    }
}

private struct ReviewRow: View {
    let review: Review

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            metaLayout {
                Label("\(review.rating)/10", systemImage: "star")
                    .font(.subheadline.weight(.semibold))
                Text("\(review.attribution.label) · \(review.createdAtLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let text = review.text {
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    /// Score and byline side by side, or stacked at accessibility text sizes.
    private var metaLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
    }

    /// "Rated 5 out of 10 by @goatloaf, 11 Sept 2026. How u kicking me in at 10"
    private var spokenLabel: String {
        let heading = "Rated \(review.rating) out of 10 by \(review.attribution.label), \(review.createdAtLabel)."
        guard let text = review.text else {
            return heading
        }
        return "\(heading) \(text)"
    }
}
