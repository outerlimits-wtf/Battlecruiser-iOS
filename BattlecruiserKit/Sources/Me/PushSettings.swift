import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBModels

/// "PUSH NOTIFICATIONS": which kinds reach the phone. The inbox has them all.
struct PushSettings: View {
    let model: NotificationsModel

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            SectionHeader("Push notifications")
            if let settings = model.settings {
                toggle("Likes on your reviews", \.likes, settings)
                toggle("New followers", \.follows, settings)
                toggle("People you follow post", \.following, settings)
            } else {
                ProgressView()
            }
        }
        .task { await model.loadSettings() }
    }

    private func toggle(_ title: String, _ key: WritableKeyPath<NotificationSettings, Bool>, _ settings: NotificationSettings) -> some View {
        Toggle(title, isOn: Binding(
            get: { settings[keyPath: key] },
            set: { value in
                var change = settings
                change[keyPath: key] = value
                Task { await model.update(change) }
            }
        ))
        .font(Typography.body)
        .tint(Palette.good)
    }
}
