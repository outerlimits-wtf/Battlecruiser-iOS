import SwiftUI
import DesignSystem
import PubDBModels

/// "HISTORY": the pub's names, newest first, as dots on a line: the current
/// name filled, older ones hollow. Hidden when the only name is the current one.
struct HistoryTimeline: View {
    let timeline: [TimelineStop]

    var body: some View {
        if timeline.contains(where: { !$0.isCurrent }) {
            VStack(alignment: .leading, spacing: Metrics.s) {
                SectionHeader("History")
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(timeline.enumerated()), id: \.offset) { index, stop in
                        row(stop, isLast: index == timeline.count - 1)
                    }
                }
            }
        }
    }

    private func row(_ stop: TimelineStop, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Metrics.m) {
            VStack(spacing: 0) {
                Circle()
                    .strokeBorder(Palette.ink, lineWidth: 2)
                    .background(Circle().fill(stop.isCurrent ? Palette.ink : Palette.surface))
                    .frame(width: 12, height: 12)
                if !isLast {
                    Rectangle().fill(Palette.ink).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(TimelineText.title(stop))
                    .font(Typography.body.weight(stop.isCurrent ? .semibold : .regular))
                    .foregroundStyle(Palette.ink)
                if let note = TimelineText.note(stop) {
                    Text(note).font(Typography.secondary).foregroundStyle(Palette.inkMuted)
                }
            }
            .padding(.bottom, Metrics.m)
        }
        .accessibilityElement(children: .combine)
    }
}
