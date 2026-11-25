import SwiftUI
import DesignSystem
import PubDBModels

/// One pub in full, shown in the bottom sheet over the map.
///
/// The map stays usable behind it, so tapping another pin switches pubs
/// without closing anything. Draws from the summary straight away and fills in
/// the rest when the detail arrives.
public struct PubDetailPanel: View {
    private let model: PubDetailModel
    private let onClose: () -> Void

    public init(model: PubDetailModel, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
    }

    public var body: some View {
        Group {
            if let summary = model.summary {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let savedAt = model.showingCachedFrom {
                            // A copy from an earlier session: say how old it is.
                            FreshnessLabel(fetchedAt: savedAt)
                        }
                        DetailHeader(summary: summary, city: model.detail?.city)
                        TonightSection(summary: summary, gardenCloses: model.detail?.gardenCloses)
                        loadingOrError
                        if let detail = model.detail {
                            WeekSection(rows: detail.weekTable, hoursAttribution: detail.hours.attribution)
                            ContactSection(summary: summary, contact: detail.contact)
                            ReviewsSection(reviews: detail.reviews)
                                .id(detail.id)
                            FeaturesSection(features: detail.features)
                            HistorySection(timeline: detail.timeline)
                        }
                    }
                    .padding()
                }
            } else if let name = model.placeholderName {
                // Chosen from a map pin: the name now, the rest on arrival.
                VStack(alignment: .leading, spacing: 24) {
                    Text(name)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    loadingOrError
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .overlay(alignment: .topTrailing) {
            CloseButton(action: onClose)
        }
    }

    @ViewBuilder
    private var loadingOrError: some View {
        if let error = model.lastError {
            VStack(alignment: .leading, spacing: 8) {
                Text(error.userMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Try again") {
                    model.retry()
                }
                .buttonStyle(.bordered)
            }
        } else if model.isLoading && model.detail == nil {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
    }
}
