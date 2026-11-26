import SwiftUI
import DesignSystem
import PubDBModels

/// Picture, handle, followers, and Follow / Following (changes at once, put
/// back if the server says no).
struct ProfileHeader: View {
    let profile: Profile
    let source: any ProfileSource
    let canFollow: Bool

    @State private var following: Bool?
    @State private var followers: Int?

    var body: some View {
        HStack(spacing: Metrics.l) {
            Avatar(url: profile.user.avatarURL, name: profile.user.label, size: .lg)
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.user.label).font(Typography.title).foregroundStyle(Palette.ink)
                Text("\(followerCount) \(followerCount == 1 ? "follower" : "followers") · \(profile.stats.following) following")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
                if canFollow {
                    Button(isFollowing ? "Following" : "Follow") { toggle() }
                        .buttonStyle(ChipStyle(isSelected: !isFollowing))
                }
            }
        }
    }

    private var isFollowing: Bool { following ?? profile.isFollowing }
    private var followerCount: Int { followers ?? profile.stats.followers }

    private func toggle() {
        let was = isFollowing
        let count = followerCount
        following = !was
        followers = count + (was ? -1 : 1)
        Task {
            do {
                let change = try await source.setFollowing(profile.user.username, !was)
                following = change.following
                followers = change.followers
            } catch {
                following = was
                followers = count
            }
        }
    }
}
