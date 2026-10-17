import SwiftUI

/// The button that goes with a notice, if one helps: back to London when the
/// map is outside the covered area, or try again after a failure. Offline and
/// "nothing here" need no button: the app retries as the map moves.
struct NoticeActions: View {
    let notice: PubsNotice
    let onGoToLondon: () -> Void
    let onRetry: () -> Void

    var body: some View {
        switch notice {
        case .outsideCoverage:
            Button("Go to London", action: onGoToLondon)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        case .failed:
            Button("Try again", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.small)
        case .offline, .nothingHere:
            EmptyView()
        }
    }
}
