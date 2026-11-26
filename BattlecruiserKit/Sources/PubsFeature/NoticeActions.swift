import SwiftUI

/// The button that goes with a notice, if one helps: off to London, where most
/// of the pubs are, when there are none here, or try again after a failure.
/// Offline needs no button: the app retries as the map moves.
struct NoticeActions: View {
    let notice: PubsNotice
    let onGoToLondon: () -> Void
    let onRetry: () -> Void

    var body: some View {
        switch notice {
        case .nothingHere:
            Button("Go to London", action: onGoToLondon)
                .buttonStyle(.bordered)
                .controlSize(.small)
        case .failed:
            Button("Try again", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.small)
        case .offline:
            EmptyView()
        }
    }
}
