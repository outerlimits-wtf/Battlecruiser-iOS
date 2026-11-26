import SwiftUI
import DesignSystem
import PubDBClient

/// "MOST YOU WILL PAY FOR A GUINNESS".
struct GuinnessFilterPanel: View {
    @Binding var query: PubQuery

    var body: some View {
        SectionHeader("Most you will pay for a Guinness")
        ChipFlow {
            ForEach(FilterOptions.guinnessSteps, id: \.pence) { step in
                Button(step.label) { query.maxGuinnessPence = step.pence }
                    .buttonStyle(ChipStyle(isSelected: query.maxGuinnessPence == step.pence))
            }
            Button("Any") { query.maxGuinnessPence = nil }
                .buttonStyle(ChipStyle(isSelected: query.maxGuinnessPence == nil))
        }
        Text("Prices come from drinkers reporting what they actually paid.")
            .font(Typography.secondary)
            .foregroundStyle(Palette.inkMuted)
    }
}
