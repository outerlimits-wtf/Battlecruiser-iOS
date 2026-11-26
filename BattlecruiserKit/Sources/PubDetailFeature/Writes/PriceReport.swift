import SwiftUI
import DesignSystem

/// "Report the price you paid": a £ field and Report, checked against
/// `/meta`'s bounds before it goes (the server checks again).
struct PriceReport: View {
    let title: String
    let min: Int
    let max: Int
    let writer: FactWriter

    @State private var isOpen = false
    @State private var input = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            Button(title) { isOpen.toggle() }
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.beer)
            if isOpen {
                HStack(spacing: Metrics.s) {
                    Text("£").foregroundStyle(Palette.inkMuted)
                    TextField("Price of a Guinness, e.g. 5.60", text: $input)
                        .keyboardType(.decimalPad)
                    Button("Report", action: report).buttonStyle(ChipStyle(isSelected: true))
                }
                .padding(Metrics.s)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Metrics.inputRadius))
                if let error {
                    Text(error).font(Typography.secondary).foregroundStyle(Palette.bad)
                }
            }
        }
    }

    private func report() {
        guard let pence = GuinnessPrice.pence(from: input), (min...max).contains(pence) else {
            error = GuinnessPrice.outOfRange(input, min: min, max: max)
            return
        }
        error = nil
        writer.send("guinness_price", String(pence))
        input = ""
        isOpen = false
    }
}
