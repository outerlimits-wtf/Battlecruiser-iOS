import SwiftUI
import Root

@main
struct BattlecruiserApp: App {
    /// For pushes: the APNs token and tapped notifications.
    @UIApplicationDelegateAdaptor(PushAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
