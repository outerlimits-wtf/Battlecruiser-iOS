import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// The inbox: likes on your reviews, new followers, and what people you
/// follow posted. Marked read once shown. A tap opens the pub, or for a
/// follow, their profile.
struct NotificationsPage: View {
    let model: NotificationsModel
    let onOpenPub: (PubLink) -> Void

    var body: some View {
        ScrollView {
            if let inbox = model.inbox.value {
                if inbox.notifications.isEmpty {
                    StateView(.empty(emoji: "🔔", title: "Nothing yet",
                                     body: "Likes on your reviews, new followers and what the people you follow post land here."))
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(inbox.notifications) { row($0) }
                    }
                }
            } else if let error = model.inbox.error {
                StateView(.error(message: error.userMessage, retry: { Task { await model.load() } }))
            } else {
                StateView(.loading())
            }
        }
        .background(Palette.canvas)
        .navigationTitle("Notifications")
        .task {
            await model.load()
            await model.markAllRead()
        }
        .refreshable { await model.load() }
    }

    @ViewBuilder
    private func row(_ notification: AppNotification) -> some View {
        if notification.opensProfile, let actor = notification.actor {
            NavigationLink(value: ProfileLink(actor.username)) { NotificationRow(notification: notification) }
                .buttonStyle(.plain)
        } else if let pub = notification.pub {
            Button { onOpenPub(PubLink(id: pub.id, name: pub.name)) } label: { NotificationRow(notification: notification) }
                .buttonStyle(.plain)
        } else {
            NotificationRow(notification: notification)
        }
    }
}
