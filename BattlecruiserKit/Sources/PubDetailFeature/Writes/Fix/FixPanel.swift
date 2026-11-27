import SwiftUI
import DesignSystem
import PubDBModels

/// Fix mode: every field people can correct, in the server's sections and
/// order, each with what the pub has now. Shown in place of the tabs while
/// fixing.
///
/// For now each row only shows the current value; the editors by `kind`
/// come next (H8c, H8d), then hours (H10) and night times (H9).
struct FixPanel: View {
    let layout: FixLayout

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xl) {
            if layout.groups.isEmpty {
                Text("Nothing to fix until the server's field list has loaded.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.inkMuted)
            }
            ForEach(layout.groups) { group in
                VStack(alignment: .leading, spacing: Metrics.m) {
                    SectionHeader(group.title)
                    ForEach(group.items) { item in
                        FixRow(item: item)
                    }
                }
            }
        }
    }
}

/// One field: its label, and what the pub has now.
struct FixRow: View {
    let item: FixLayout.Item

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.field.label)
                .font(Typography.secondary.weight(.medium))
                .foregroundStyle(Palette.inkMuted)
            if let display = item.current?.display {
                Text(display).font(Typography.body).foregroundStyle(Palette.ink)
            } else {
                Text("Not known yet").font(Typography.body).foregroundStyle(Palette.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
