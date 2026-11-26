import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// The Reviews tab: what drinkers said, newest first, the first three then
/// the rest on request; signed in, a review of your own, Delete on yours and
/// Report on everyone else's.
struct ReviewsTab: View {
    let pubID: String
    let reviews: [Review]
    let context: PanelContext
    /// A review to bring into view and light up, from a tap on the quote.
    let focusID: Int?
    let onChanged: (WriteResult) -> Void

    /// How many show before "Show more".
    static let collapsedCount = 3

    @State private var isExpanded = false
    @State private var reporting: ReportTarget?

    /// The scroll id for a review.
    static func anchor(_ id: Int) -> String { "review-\(id)" }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.l) {
            if context.session.isSignedIn {
                ReviewComposer(pubID: pubID, context: context, onPosted: onChanged)
            } else if context.session.offersSignIn {
                Text("Sign in to weigh in.").font(Typography.body).foregroundStyle(Palette.inkMuted)
            }
            if reviews.isEmpty {
                Text("Not a word from anybody. Make of that what you will.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.inkMuted)
            }
            ForEach(isExpanded ? reviews : Array(reviews.prefix(Self.collapsedCount))) { review in
                ReviewRow(review: review, pubID: pubID, context: context)
                    .padding(Metrics.s)
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.cardRadius)
                            .stroke(review.id == focusID ? Palette.beerBright : .clear, lineWidth: 2)
                    )
                    .id(Self.anchor(review.id))
                    .contextMenu { menu(for: review) }
            }
            if reviews.count > Self.collapsedCount && !isExpanded {
                Button("Show \(reviews.count - Self.collapsedCount) more") { isExpanded = true }
                    .buttonStyle(ChipStyle())
            }
        }
        .sheet(item: $reporting) { ReportSheet(target: $0, context: context) }
        .onChange(of: focusID, initial: true) { _, id in
            // Asked for one that is folded away: unfold, or there is nothing to show.
            if let id, let index = reviews.firstIndex(where: { $0.id == id }), index >= Self.collapsedCount {
                isExpanded = true
            }
        }
    }

    @ViewBuilder
    private func menu(for review: Review) -> some View {
        if review.canRemove == true {
            Button("Delete my review", systemImage: "trash", role: .destructive) {
                Task {
                    if let result = try? await context.writer.deleteReview(review.id, from: pubID) {
                        onChanged(result)
                    }
                }
            }
        } else if context.session.isSignedIn {
            Button("Report", systemImage: "flag") {
                reporting = ReportTarget(type: "review", id: String(review.id))
            }
        }
    }
}
