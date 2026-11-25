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
