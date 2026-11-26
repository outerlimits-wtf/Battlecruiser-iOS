import SwiftUI
import Playgrounds
import Root

/// The composition root: the real server, with the app's response cache,
/// handed to the app's root view.
struct ContentView: View {
    var body: some View {
        RootView(dependencies: .live(workOSClientID: AppConfig.workOSClientID))
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
