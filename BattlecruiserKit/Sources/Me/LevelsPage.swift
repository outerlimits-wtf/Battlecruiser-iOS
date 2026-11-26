import SwiftUI
import DesignSystem
import PubDBModels

/// "How levels work": the levels and what earns XP, both from `/meta`.
struct LevelsPage: View {
    let levels: [LevelInfo]
    let rules: [XPRule]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.xl) {
                VStack(alignment: .leading, spacing: Metrics.m) {
                    SectionHeader("Levels")
                    ForEach(levels) { level in
                        HStack(alignment: .top, spacing: Metrics.m) {
                            Text(level.emoji ?? "🍺").font(.title3).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(level.name) · \(level.minXp) XP").font(Typography.rowTitle).foregroundStyle(Palette.ink)
                                Text(level.line).font(Typography.body.italic()).foregroundStyle(Palette.inkMuted)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                VStack(alignment: .leading, spacing: Metrics.s) {
                    SectionHeader("What earns XP")
                    ForEach(rules) { rule in
                        HStack {
                            Text(rule.label)
                            Spacer()
                            Text("\(rule.xp) XP").fontWeight(.semibold).foregroundStyle(Palette.beer)
                        }
                        .font(Typography.body)
                        .foregroundStyle(Palette.ink)
                    }
                }
            }
            .padding(Metrics.l)
        }
        .background(Palette.canvas)
        .navigationTitle("Levels")
    }
}
