import SwiftUI
import DesignSystem
import PubDBModels

/// The line the list quotes, above the panel's tabs: tap it for that review,
/// or the link for them all. Nothing when nobody has written. A touch smaller
/// than the web's, so it doesn't push the tabs far down.
struct QuoteCard: View {
    let quote: Quote
    /// The quoted review, when it is among those the detail holds.
    let review: Review?
    let reviewCount: Int
    let maxRating: Int
    let onOpenReview: (Int) -> Void
    let onOpenReviews: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { onOpenReview(quote.reviewId) } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("“\(quote.text)”")
                        .font(Typography.body.italic())
                        .foregroundStyle(Palette.ink)
                        .lineLimit(3)
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
                .font(Typography.secondary.weight(.semibold))
                .foregroundStyle(Palette.beer)
        }
        .padding(.horizontal, Metrics.m)
        .padding(.vertical, Metrics.s + 2)
        .background(Palette.canvas, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
    }
}
