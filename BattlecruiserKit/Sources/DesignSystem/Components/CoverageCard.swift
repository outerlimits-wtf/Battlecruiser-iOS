import SwiftUI
import PubDBModels

/// How much of London someone has drunk in, overall and by area, as the web's
/// card. (S7 asks the server for ready-made percentage labels.)
public struct CoverageCard: View {
    private let coverage: Coverage
    @State private var showsAllAreas = false

    public init(_ coverage: Coverage) {
        self.coverage = coverage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            row(title: "London", visited: coverage.visited, total: coverage.total, percent: coverage.percent,
                color: Palette.good, minimum: 0.02, font: Typography.rowTitle)
            if !coverage.areas.isEmpty {
                SectionHeader("By area")
                ForEach(showsAllAreas ? coverage.areas : Array(coverage.areas.prefix(5))) { area in
                    row(title: area.code, visited: area.visited, total: area.total, percent: area.percent,
                        color: Palette.beer, minimum: 0.03, font: Typography.body)
                }
                if coverage.areas.count > 5 {
                    Button(showsAllAreas ? "Show fewer areas" : "Show \(coverage.areas.count - 5) more areas") {
                        showsAllAreas.toggle()
                    }
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.beer)
                }
            }
        }
        .padding(Metrics.l)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
    }

    private func row(title: String, visited: Int, total: Int, percent: Double, color: Color, minimum: Double, font: Font) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(font).foregroundStyle(Palette.ink)
                Spacer()
                Text("\(visited) / \(total) · \(percent.formatted())%")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkMuted)
            }
            GeometryReader { proxy in
                Capsule().fill(Palette.surfaceSunken)
                    .overlay(alignment: .leading) {
                        Capsule().fill(color)
                            .frame(width: proxy.size.width * (visited > 0 ? max(percent / 100, minimum) : 0))
                    }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(visited) of \(total) pubs")
    }
}
