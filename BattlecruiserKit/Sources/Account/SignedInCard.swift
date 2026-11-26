import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// The signed-in person: picture, handle, what they've done, and the account
/// actions. On beer-soft, as on the web.
struct SignedInCard: View {
    let session: SessionModel
    let user: MeUser
    let onOpenProfile: (String) -> Void

    @State private var isEditingHandle = false
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            Button { onOpenProfile(user.username) } label: {
                HStack(spacing: Metrics.m) {
                    Avatar(url: user.avatarURL, name: user.label, size: .md)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.label).font(Typography.rowTitle).foregroundStyle(Palette.ink)
                        Text(stats).font(Typography.secondary).foregroundStyle(Palette.inkMuted)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows your profile")

            if let level = user.level {
                LevelProgress(level)
            }
            Text(user.usernameChosen ? "It goes on everything you add." : "We picked that one for you. Change it to something worse.")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkMuted)

            ChipFlow {
                Button("My profile") { onOpenProfile(user.username) }.buttonStyle(ChipStyle())
                AvatarPickerButton(session: session, hasAvatar: user.avatarURL != nil)
                Button("Handle") { isEditingHandle = true }.buttonStyle(ChipStyle())
                Button("Sign out") { Task { await session.signOut() } }.buttonStyle(ChipStyle())
            }

            Button("Delete my account", role: .destructive) { isConfirmingDelete = true }
                .font(Typography.secondary)
        }
        .padding(Metrics.l)
        .background(Palette.beerSoft, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
        .sheet(isPresented: $isEditingHandle) {
            HandleEditor(session: session, current: user.username)
        }
        .confirmationDialog("Delete your account?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete my account", role: .destructive) {
                Task { await session.deleteAccount() }
            }
        } message: {
            Text("Your reviews and photos go for good. Facts you added stay, without your name on them.")
        }
    }

    /// "3 visited · 2 reviews · 12 added".
    private var stats: String {
        "\(user.visited ?? 0) visited · \(user.reviews ?? 0) reviews · \(user.contributions) added"
    }
}
