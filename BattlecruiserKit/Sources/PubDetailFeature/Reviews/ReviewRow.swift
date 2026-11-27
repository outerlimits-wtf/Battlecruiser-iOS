import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// One review: who, the score in beer, when, and what they said.
struct ReviewRow: View {
    let review: Review
    let pubID: String
    let context: PanelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            words
            LikeButton(review: review, pubID: pubID, context: context)
        }
    }

    /// Who, the score, when and what they said: one element for VoiceOver.
    private var words: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Metrics.s) {
                author
                Text("\(review.rating)/10")
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Palette.beer)
                Text(review.createdAtLabel)
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkFaint)
            }
            if let text = review.text {
                Text(text)
                    .font(Typography.body)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .accessibilityActions {
            if let open = openProfile {
                Button("Show \(review.attribution.label)'s profile", action: open)
            }
        }
    }

    /// Picture and handle: tap them for the reviewer's profile, when they
    /// are a person and the panel can show one.
    @ViewBuilder
    private var author: some View {
        let label = HStack(spacing: Metrics.s) {
            Avatar(url: review.avatarURL, name: review.attribution.label, size: .xs)
            Text(review.attribution.label)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.ink)
        }
        if let open = openProfile {
            Button(action: open) { label.contentShape(Rectangle()) }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    private var openProfile: (() -> Void)? {
        guard let link = ProfileLink(review.attribution), let open = context.onOpenProfile else { return nil }
        return { open(link) }
    }

    /// "Rated 5 out of 10 by @goatloaf, 11 Sept 2026. How u kicking me in at 10"
    private var spokenLabel: String {
        let heading = "Rated \(review.rating) out of 10 by \(review.attribution.label), \(review.createdAtLabel)."
        return review.text.map { "\(heading) \($0)" } ?? heading
    }
}
