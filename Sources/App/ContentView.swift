import SwiftUI
import Playgrounds
import PubDBClient
import PubsFeature

/// The composition root: chooses the real server and hands it to the map.
struct ContentView: View {
    var body: some View {
        PubsMapScreen(source: PubDBClient())
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
