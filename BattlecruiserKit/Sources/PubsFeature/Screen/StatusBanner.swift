import SwiftUI
import UIKit
import DesignSystem

/// What sits at the top of the map: location turned off, how old the pubs
/// are, and any notice (offline, failed, nothing here).
struct StatusBanner: View {
    let pubs: PubsModel
    let isLocationDenied: Bool
    /// The list shows its own notice; on the map it is a banner.
    let showsNotice: Bool
    let onGoToLondon: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 8) {
            if isLocationDenied {
                Button {
                    if let settings = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settings)
                    }
                } label: {
                    Label("Location is off. Turn it on in Settings to see pubs near you.", systemImage: "location.slash")
                        .font(.footnote)
                }
                .buttonStyle(.borderedProminent)
            }
            TimelineView(.everyMinute) { context in
                if let fetchedAt = pubs.fetchedAt,
                   pubs.isShowingCached || Freshness.isStale(fetchedAt: fetchedAt, now: context.date) {
                    FreshnessLabel(fetchedAt: fetchedAt)
                }
            }
            if showsNotice, let notice = pubs.notice {
                NoticeBanner(notice: notice, onGoToLondon: onGoToLondon, onRetry: pubs.refresh)
            } else if pubs.isLoading {
                ProgressView()
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
    }
}
