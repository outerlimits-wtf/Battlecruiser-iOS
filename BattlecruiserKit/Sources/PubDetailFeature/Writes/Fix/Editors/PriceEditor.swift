import SwiftUI
import DesignSystem
import PubDBModels

/// `price`: a £ box prefilled with the current price, checked against the
/// field's own `min` and `max` (pence) before it goes; the server checks again.
/// The same price again counts as a confirmation when the field corroborates.
struct PriceEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let send: (String) -> Void

    @State private var input = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xs) {
            HStack(spacing: Metrics.s) {
                Text("£").foregroundStyle(Palette.inkMuted).accessibilityHidden(true)
                TextField(field.placeholder ?? field.label, text: $input)
                    .font(Typography.body)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("\(field.label), in pounds")
                Button(field.corroborating ? "Report" : "Save", action: save)
                    .buttonStyle(ChipStyle(isSelected: !input.isEmpty))
                    .disabled(input.isEmpty)
            }
            .padding(Metrics.s)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
            if let error {
                Text(error).font(Typography.secondary).foregroundStyle(Palette.bad)
            }
        }
        .onAppear { input = Self.pounds(current?.value) }
        .onChange(of: current?.value) { _, value in input = Self.pounds(value) }
    }

    private var bounds: ClosedRange<Int> { (field.min ?? 200)...(field.max ?? 1500) }

    private func save() {
        guard let pence = GuinnessPrice.pence(from: input), bounds.contains(pence) else {
            error = GuinnessPrice.outOfRange(input, min: bounds.lowerBound, max: bounds.upperBound)
            return
        }
        error = nil
        send(String(pence))
    }

    /// The box's starting text from `editable`'s pence ("730" → "7.30").
    static func pounds(_ pence: String?) -> String {
        guard let pence, let value = Int(pence) else { return "" }
        return String(format: "%d.%02d", value / 100, value % 100)
    }
}
