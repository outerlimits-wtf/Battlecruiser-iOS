import SwiftUI

/// A notice about the pubs on the map, with the button that helps, if any.
struct NoticeBanner: View {
    let notice: PubsNotice
    let onGoToLondon: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Label(notice.message, systemImage: notice.systemImage)
                .font(.footnote)
            NoticeActions(notice: notice, onGoToLondon: onGoToLondon, onRetry: onRetry)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
