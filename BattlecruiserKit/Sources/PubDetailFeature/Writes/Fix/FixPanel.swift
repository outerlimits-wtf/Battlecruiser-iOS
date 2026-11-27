import SwiftUI
import DesignSystem
import PubDBModels

/// Fix mode: every field people can correct, in the server's sections and
/// order, each with what the pub has now. Shown in place of the tabs while
/// fixing.
///
/// Each row gets an editor by `kind`. `previous_name` is edited on the
/// timeline (H11), so it only shows here if a server puts it outside History.
struct FixPanel: View {
    let layout: FixLayout
    let detail: PubDetail
    let meta: Meta?
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
                        FixRow(item: item, detail: detail, meta: meta, loadBrands: writer.context.writer.brands) {
                            writer.send(item.field.key, $0)
                        }
                    }
                }
            }
        }
    }
}

/// One field: its label, and its editor, picked by `kind` (never by key, with
/// one exception below).
struct FixRow: View {
    /// **Temporary exception to "never by key":** `kind: hours` covers both the
    /// week (`opening_hours`) and a single time (`garden_closes`), so the week
    /// editor is chosen by key until the server gives single times their own
    /// kind (server ask S22).
    static let weekHoursKey = "opening_hours"
    /// **Temporary, as above:** the operator (`brand`) is `kind: text`, so its
    /// picker is chosen by key until the server gives it a kind (server ask S24).
    static let operatorKey = "brand"

    let item: FixLayout.Item
    let detail: PubDetail
    let meta: Meta?
    let loadBrands: () async throws -> [Brand]
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
        case .text where field.key == Self.operatorKey:
            OperatorEditor(field: field, current: current, loadBrands: loadBrands, send: send)
        case .tri:
            TriEditor(field: field, current: current, send: send)
        case .text, .url, .phone, .other:
            TextValueEditor(field: field, current: current, send: send)
        case .price:
            PriceEditor(field: field, current: current, send: send)
        case .amenity:
            AmenityEditor(field: field, current: current, kinds: meta?.venueKinds ?? [], send: send)
        case .weekday:
            WeekdayEditor(field: field, current: current, weekdays: meta?.weekdays ?? [], send: send)
        case .status:
            StatusEditor(field: field, status: detail.summary.status, send: send)
        case .hours where field.key == Self.weekHoursKey:
            WeekHoursEditor(field: field, current: current, weekTable: detail.weekTable, send: send)
        case .hours:
            // A single time (`garden_closes`).
            SingleTimeEditor(field: field, current: current, send: send)
        case .night:
            NightEditor(field: field, weekdays: meta?.weekdays ?? [], session: detail.session, send: send)
        case .previousName:
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
