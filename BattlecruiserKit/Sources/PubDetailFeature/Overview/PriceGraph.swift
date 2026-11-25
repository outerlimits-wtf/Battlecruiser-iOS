import Charts
import SwiftUI
import DesignSystem
import PubDBModels

/// Every Guinness price reported, over time. The first and last are labelled
/// with the server's formatted prices; the scale is left to Charts. (The
/// web's shared £ band and gridlines wait for the server to send them, S7.)
struct PriceGraph: View {
    let points: [PriceHistory.Point]

    var body: some View {
        let plotted = points.compactMap { point in
            Self.date(point.at).map { (date: $0, point: point) }
        }
        VStack(alignment: .leading, spacing: Metrics.s) {
            Text("\(points.count) reports")
                .font(Typography.sectionHeader)
                .foregroundStyle(Palette.inkMuted)
            Chart {
                ForEach(Array(plotted.enumerated()), id: \.offset) { index, entry in
                    LineMark(x: .value("When", entry.date), y: .value("Pence", entry.point.pence))
                        .foregroundStyle(Palette.beer)
                    PointMark(x: .value("When", entry.date), y: .value("Pence", entry.point.pence))
                        .foregroundStyle(Palette.beer)
                        .annotation(position: .top) {
                            if index == 0 || index == plotted.count - 1 {
                                Text(entry.point.formatted)
                                    .font(Typography.micro)
                                    .foregroundStyle(Palette.inkMuted)
                            }
                        }
                }
            }
            .chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 116)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    /// "£6.90 to £7.30 over 4 reports", from the server's labels.
    private var spoken: String {
        guard let first = points.first, let last = points.last else { return "No reports" }
        return "\(first.formatted) to \(last.formatted) over \(points.count) reports"
    }

    /// The server's ISO time, for placing a point on the axis (not for display).
    static func date(_ iso: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
    }
}
