import SwiftUI
import DesignSystem
import PubDBModels

/// "What's there": a chip per feature the pub has, with the night for quiz
/// and karaoke when someone has said. Answering the rest comes with Fix (E4).
struct WhatsThere: View {
    let features: [FeatureAnswer]
    let quizNightDay: String?
    let karaokeNightDay: String?

    var body: some View {
        let present = features.filter { $0.value == .yes }
        if !present.isEmpty {
            VStack(alignment: .leading, spacing: Metrics.s) {
                SectionHeader("What's there")
                ChipFlow {
                    ForEach(present) { feature in
                        HStack(spacing: 4) {
                            SymbolGlyph(feature.symbol, size: 15)
                            Text(label(feature))
                        }
                        .font(Typography.pill)
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, Metrics.m)
                        .padding(.vertical, 6)
                        .background(Palette.surfaceSunken, in: Capsule())
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func label(_ feature: FeatureAnswer) -> String {
        let night = switch feature.key {
        case "quiz_night": quizNightDay
        case "karaoke": karaokeNightDay
        default: String?.none
        }
        return night.map { "\(feature.label) · \($0)" } ?? feature.label
    }
}
