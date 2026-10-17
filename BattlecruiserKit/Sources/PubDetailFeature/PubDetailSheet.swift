import SwiftUI
import DesignSystem
import PubDBModels

/// One pub in full, shown in a sheet over the map.
///
/// Opens at half height with the map still usable behind it, so tapping another
/// pin switches pubs without closing anything. Draws from the summary straight
/// away and fills in the rest when the detail arrives.
public struct PubDetailSheet: View {
    private let model: PubDetailModel

    public init(model: PubDetailModel) {
        self.model = model
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
                            FeaturesSection(features: detail.features)
                            HistorySection(timeline: detail.timeline)
                            SourcesSection(sources: detail.sources)
                        }
                    }
                    .padding()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .presentationDragIndicator(.visible)
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

/// A section heading, the same everywhere in the sheet.
struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }
}
