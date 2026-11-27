import SwiftUI
import DesignSystem
import PubDBModels

/// The Overview tab, in the web's order: tonight, what's there, the price of
/// a Guinness, opening hours, contact, and the pubs nearby.
struct OverviewTab: View {
    let summary: PubSummary
    let detail: PubDetail?
    let nearby: [PubSummary]
    let onSelectPub: (PubSummary) -> Void
    /// Signed in: answering features and reporting prices.
    let writer: FactWriter?
    let priceBounds: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xl) {
            if let detail {
                TonightFacts(tonight: detail.weekTable.first(where: \.isTonight), gardenCloses: detail.gardenCloses)
                WhatsThere(features: detail.features, quizNightDay: detail.quizNightDay, karaokeNightDay: detail.karaokeNightDay)
                if let writer {
                    FeatureAnswers(features: detail.features, writer: writer)
                }
            }
            if let guinness = summary.guinness {
                GuinnessCard(guinness: guinness, history: detail?.priceHistory)
            }
            if let writer {
                PriceReport(
                    title: summary.guinness == nil ? "Add the price of a Guinness" : "Report the price you paid",
                    min: priceBounds.lowerBound,
                    max: priceBounds.upperBound,
                    writer: writer
                )
            }
            if let detail {
                WeekTable(rows: detail.weekTable)
                ContactPills(contact: detail.contact)
            }
            NearbyStrip(pubs: nearby, onSelect: onSelectPub)
        }
    }
}
