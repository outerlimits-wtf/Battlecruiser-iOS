import SwiftUI
import DesignSystem
import PubDBModels

/// `tri`: Yes / No / Not sure, the pub's answer filled in. Tapping another
/// one sends it.
struct TriEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let send: (String) -> Void

    private struct Choice: Identifiable {
        let value: String
        let title: String
        var id: String { value }
    }

    private static let choices = [
        Choice(value: "yes", title: "Yes"),
        Choice(value: "no", title: "No"),
        Choice(value: "unknown", title: "Not sure"),
    ]

    var body: some View {
        ChipFlow {
            ForEach(Self.choices) { choice in
                let isOn = (current?.value ?? "unknown") == choice.value
                Button(choice.title) {
                    if !isOn { send(choice.value) }
                }
                .buttonStyle(ChipStyle(isSelected: isOn))
                .accessibilityLabel("\(field.label): \(choice.title)")
            }
        }
    }
}
