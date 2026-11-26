import SwiftUI
import DesignSystem
import PubDBModels

/// Their reviews, or the pubs they've been to.
struct ProfileTabContent: View {
    let profile: Profile
    let tab: ProfileTab
    let onOpenPub: (String, String) -> Void

    var body: some View {
        switch tab {
        case .reviews:
            if profile.reviews.isEmpty {
                Text("No reviews yet.").font(Typography.body).foregroundStyle(Palette.inkMuted)
            } else {
                VStack(alignment: .leading, spacing: Metrics.l) {
                    ForEach(profile.reviews) { review in
                        Button { onOpenPub(review.pubId, review.pubName) } label: { reviewRow(review) }
                            .buttonStyle(.plain)
                    }
                }
            }
        case .visited:
            if profile.visited.isEmpty {
                Text("No pubs ticked off yet.").font(Typography.body).foregroundStyle(Palette.inkMuted)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(profile.visited) { pub in
                        Button { onOpenPub(pub.id, pub.name) } label: { PubCard(pub) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func reviewRow(_ review: Profile.ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(review.pubName).font(Typography.rowTitle).foregroundStyle(Palette.ink)
                Text("\(review.rating)/10").font(Typography.body.weight(.semibold)).foregroundStyle(Palette.beer)
                Spacer()
                Text(review.agoLabel).font(Typography.secondary).foregroundStyle(Palette.inkFaint)
            }
            if let body = review.body, !body.isEmpty {
                Text(body).font(Typography.body).foregroundStyle(Palette.inkMuted).lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
