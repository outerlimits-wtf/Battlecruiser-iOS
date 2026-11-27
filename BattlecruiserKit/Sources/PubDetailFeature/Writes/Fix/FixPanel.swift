import SwiftUI
import DesignSystem
import PubDBModels

/// Fix mode: every field people can correct, in the server's sections and
/// order, each with what the pub has now. Shown in place of the tabs while
/// fixing.
///
/// Each row gets an editor by `kind`. `hours` (H10) and `night` (H9) only
/// show the current value for now.
struct FixPanel: View {
    let layout: FixLayout
    let venueKinds: [VenueKind]
    let weekdays: [Weekday]
    /// The pub's state now, for the status editor.
    let status: PubStatus?
    let writer: FactWriter

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
                        FixRow(item: item, venueKinds: venueKinds, weekdays: weekdays, status: status) { writer.send(item.field.key, $0) }
                    }
                }
            }
        }
    }
}

/// One field: its label, and its editor, picked by `kind` (never by key).
struct FixRow: View {
    let item: FixLayout.Item
    let venueKinds: [VenueKind]
    let weekdays: [Weekday]
    let status: PubStatus?
    let send: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xs) {
            Text(item.field.label)
                .font(Typography.secondary.weight(.medium))
                .foregroundStyle(Palette.inkMuted)
                .accessibilityHidden(true)
            editor
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var editor: some View {
        let field = item.field
        let current = item.current
        switch field.kind {
        case .tri:
            TriEditor(field: field, current: current, send: send)
        case .text, .url, .phone, .other:
            TextValueEditor(field: field, current: current, send: send)
        case .price:
            PriceEditor(field: field, current: current, send: send)
        case .amenity:
            AmenityEditor(field: field, current: current, kinds: venueKinds, send: send)
        case .weekday:
            WeekdayEditor(field: field, current: current, weekdays: weekdays, send: send)
        case .status:
            StatusEditor(field: field, status: status, send: send)
        case .hours, .night, .previousName:
            CurrentValue(label: field.label, current: current)
        }
    }
}

/// A field with no editor yet: what the pub has now, read only.
struct CurrentValue: View {
    let label: String
    let current: EditableValue?

    var body: some View {
        Group {
            if let display = current?.display {
                Text(display).foregroundStyle(Palette.ink)
            } else {
                Text("Not known yet").foregroundStyle(Palette.inkFaint)
            }
        }
        .font(Typography.body)
        .accessibilityLabel("\(label): \(current?.display ?? "not known yet")")
    }
}
