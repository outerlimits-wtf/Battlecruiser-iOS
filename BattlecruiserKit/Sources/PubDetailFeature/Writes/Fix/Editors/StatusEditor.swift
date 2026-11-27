import SwiftUI
import UIKit
import DesignSystem
import PubDBModels

/// `status`: "Still there?" and "Listing problem" chips, the pub's own state
/// picked; tapping another sends that state. Once it has stopped serving
/// (and isn't a listing error), the rest of meta's `parts` (the year, what it
/// became) are asked for and sent with it as one JSON object (S5).
struct StatusEditor: View {
    let field: ContributableField
    let status: PubStatus?
    let send: (String) -> Void

    @State private var values: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            chips(StatusState.all.filter { !$0.isListingError })
            Text("Listing problem")
                .font(Typography.secondary.weight(.medium))
                .foregroundStyle(Palette.inkMuted)
                .accessibilityAddTraits(.isHeader)
            chips(StatusState.all.filter(\.isListingError))
            if let status, !status.serving, !StatusState.isListingError(status.key), !detailParts.isEmpty {
                details(state: status.key)
            }
        }
        .onChange(of: status?.key) { values = [:] }
    }

    private func chips(_ states: [StatusState]) -> some View {
        ChipFlow {
            ForEach(states) { state in
                let isOn = status?.key == state.key
                Button("\(state.emoji) \(state.label)") {
                    if !isOn { send(state.key) }
                }
                .buttonStyle(ChipStyle(isSelected: isOn))
                .accessibilityLabel("Mark as \(state.label)")
            }
        }
    }

    /// The parts other than the state itself, which the chips already hold.
    private var detailParts: [FieldPart] { field.parts.filter { $0.kind != "status" } }

    private func details(state: String) -> some View {
        let stateParts = field.parts.filter { $0.kind == "status" }
        var all = values
        for part in stateParts { all[part.key] = state }
        let value = StructuredValue.json(field.parts, values: all)
        return VStack(alignment: .leading, spacing: Metrics.s) {
            ForEach(detailParts) { part in
                TextField(part.optional ? part.label : "\(part.label) (needed)", text: binding(part))
                    .font(Typography.body)
                    .keyboardType(part.kind == "year" ? .numberPad : .default)
                    .padding(Metrics.s)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
                    .accessibilityLabel(part.label)
            }
            Button("Add") {
                if let value { send(value) }
            }
            .buttonStyle(ChipStyle(isSelected: value != nil && hasAnyDetail))
            .disabled(value == nil || !hasAnyDetail)
            .accessibilityHint("Adds when it went and what it became")
        }
    }

    private var hasAnyDetail: Bool {
        detailParts.contains { !(values[$0.key] ?? "").trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func binding(_ part: FieldPart) -> Binding<String> {
        Binding(
            get: { values[part.key] ?? "" },
            set: { new in
                values[part.key] = part.kind == "year" ? String(new.filter(\.isNumber).prefix(4)) : new
            }
        )
    }
}
