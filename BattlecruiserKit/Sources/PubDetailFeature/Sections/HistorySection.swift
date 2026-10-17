import SwiftUI
import PubDBModels

/// What the pub used to be called, newest first, as the server orders it.
/// Hidden when the only name is the current one.
struct HistorySection: View {
    let timeline: [TimelineStop]

    var body: some View {
        if timeline.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Names over the years")
                ForEach(Array(timeline.enumerated()), id: \.offset) { _, stop in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                            .font(.subheadline.weight(stop.isCurrent ? .semibold : .regular))
                        if let detail = detailLine(for: stop) {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    /// "1988–1997 · Trumans", "until 1988", "since 1997", or just the owner.
    private func detailLine(for stop: TimelineStop) -> String? {
        let years: String?
        switch (stop.fromLabel, stop.untilLabel) {
        case let (from?, until?):
            years = "\(from)–\(until)"
        case let (from?, nil):
            years = "since \(from)"
        case let (nil, until?):
            years = "until \(until)"
        case (nil, nil):
            years = nil
        }
        let parts = [years, stop.owner].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
