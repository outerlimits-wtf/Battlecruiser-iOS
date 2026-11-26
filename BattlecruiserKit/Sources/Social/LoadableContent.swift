import SwiftUI
import AppEnvironment
import DesignSystem

/// A page's body for a `RemoteValue`: skeletons, then the content, or the
/// error with "Try again". Loads on appear and refreshes on pull.
struct LoadableContent<Value: Sendable, Content: View>: View {
    let remote: RemoteValue<Value>
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        ScrollView {
            Group {
                if let value = remote.value {
                    content(value)
                } else if let error = remote.state.error {
                    StateView(.error(message: error.userMessage, retry: { Task { await remote.load() } }))
                } else {
                    StateView(.loading())
                }
            }
            .padding(.vertical, Metrics.m)
        }
        .background(Palette.canvas)
        .task { if remote.value == nil { await remote.load() } }
        .refreshable { await remote.load() }
    }
}
