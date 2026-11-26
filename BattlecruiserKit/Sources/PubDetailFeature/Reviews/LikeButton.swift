import SwiftUI
import DesignSystem
import PubDBModels

/// The heart, as the web's: flips on tap and back if the server says no,
/// without reloading the pub. Signed out, or on your own review, it is only
/// the count, and nothing at zero.
struct LikeButton: View {
    let review: Review
    let pubID: String
    let context: PanelContext

    @State private var liked: Bool?
    @State private var likes: Int?
    @State private var isBusy = false

    var body: some View {
        let count = likes ?? review.likes ?? 0
        let isLiked = liked ?? review.likedByMe ?? false
        if canLike {
            Button(action: toggle) {
                Label(count > 0 ? "\(count)" : "", systemImage: isLiked ? "heart.fill" : "heart")
                    .labelStyle(.titleAndIcon)
                    .font(Typography.secondary.weight(isLiked ? .semibold : .regular))
                    .foregroundStyle(isLiked ? Palette.bad : Palette.inkFaint)
                    .frame(minHeight: Metrics.minTap)
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
            .accessibilityLabel(isLiked ? "Unlike, \(count) likes" : "Like, \(count) likes")
        } else if count > 0 {
            Label("\(count)", systemImage: "heart")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkFaint)
                .accessibilityLabel("\(count) likes")
        }
    }

    /// Signed in, and not your own review.
    private var canLike: Bool {
        guard let me = context.session.user?.label else { return false }
        return review.attribution.label != me
    }

    private func toggle() {
        let wasLiked = liked ?? review.likedByMe ?? false
        let count = likes ?? review.likes ?? 0
        liked = !wasLiked
        likes = count + (wasLiked ? -1 : 1)
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                let change = try await context.writer.like(review.id, on: pubID, !wasLiked)
                liked = change.liked
                likes = change.likes
            } catch {
                liked = wasLiked
                likes = count
            }
        }
    }
}
