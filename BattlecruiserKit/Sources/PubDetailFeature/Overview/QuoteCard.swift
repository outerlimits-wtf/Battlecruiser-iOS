import SwiftUI
import DesignSystem
import PubDBModels

/// The line the list quotes, at the top of Overview, as the web's: tap it for
/// that review, or the link for them all. Nothing when nobody has written.
struct QuoteCard: View {
    let quote: Quote
    /// The quoted review, when it is among those the detail holds.
    let review: Review?
    let reviewCount: Int
    let maxRating: Int
    let onOpenReview: (Int) -> Void
    let onOpenReviews: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            Button { onOpenReview(quote.reviewId) } label: {
                VStack(alignment: .leading, spacing: Metrics.s) {
                    Text("“\(quote.text)”")
                        .font(.body.italic())
                        .foregroundStyle(Palette.ink)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: Metrics.s) {
                        if let review {
                            Avatar(url: review.avatarURL, name: review.attribution.label, size: .xs)
                            Text(review.attribution.label).fontWeight(.semibold).foregroundStyle(Palette.ink)
                        }
                        Text("\(quote.rating)/\(maxRating)").fontWeight(.semibold).foregroundStyle(Palette.beer)
                        if let likes = review?.likes, likes > 0 {
                            Label("\(likes)", systemImage: "heart").labelStyle(.titleAndIcon)
                        }
                    }
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows the review")
            Button(reviewCount > 1 ? "Read all \(reviewCount) reviews ›" : "Read the review ›", action: onOpenReviews)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.beer)
        }
        .padding(Metrics.m)
        .background(Palette.canvas, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
    }
}
