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

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xl) {
            if let detail {
                TonightFacts(tonight: detail.weekTable.first(where: \.isTonight), gardenCloses: detail.gardenCloses)
                WhatsThere(features: detail.features, quizNightDay: detail.quizNightDay, karaokeNightDay: detail.karaokeNightDay)
            }
            if let guinness = summary.guinness {
                GuinnessCard(guinness: guinness, history: detail?.priceHistory)
            }
            if let detail {
                WeekTable(rows: detail.weekTable)
                ContactPills(contact: detail.contact)
            }
            NearbyStrip(pubs: nearby, onSelect: onSelectPub)
        }
    }
}
