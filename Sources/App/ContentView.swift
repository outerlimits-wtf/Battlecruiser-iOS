import SwiftUI
import Playgrounds
import PubDBClient
import PubsFeature

/// The composition root: chooses the real server, with the app's response
/// cache, and hands it to the map.
struct ContentView: View {
    var body: some View {
        PubsMapScreen(source: PubDBClient.live())
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
