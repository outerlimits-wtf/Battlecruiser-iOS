import SwiftUI
import DesignSystem
import PubDBModels

/// Who, the server's sentence, when; a dot while unread.
struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.m) {
            ZStack(alignment: .bottomTrailing) {
                Avatar(url: notification.actor?.avatarURL, name: notification.actor?.label ?? "?", size: .sm)
                Text(icon).font(.caption2).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.text).font(Typography.body).foregroundStyle(Palette.ink)
                Text(notification.agoLabel).font(Typography.secondary).foregroundStyle(Palette.inkFaint)
            }
            Spacer()
            if !notification.read {
                Circle().fill(Palette.beer).frame(width: 8, height: 8).accessibilityLabel("Unread")
            }
        }
        .padding(.horizontal, Metrics.l)
        .padding(.vertical, Metrics.m)
        .background(notification.read ? .clear : Palette.beerSoft.opacity(0.5))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// By type; a type this build doesn't know gets a plain bell.
    private var icon: String {
        switch notification.type {
        case "review_liked": "❤️"
        case "followed": "👋"
        case "following_review": "⭐"
        case "following_photo": "📷"
        default: "🔔"
        }
    }
}
