import SwiftUI
import DesignSystem
import PubDBModels

/// `weekday`: meta's `weekdays` as chips (Mon to Sun), the pub's night
/// picked. Tapping another sends its short form ("Tue"), as the spec asks.
struct WeekdayEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let weekdays: [Weekday]
    let send: (String) -> Void

    var body: some View {
        ChipFlow {
            ForEach(weekdays) { weekday in
                let isOn = current?.value == weekday.short
                Button(weekday.short) {
                    if !isOn { send(weekday.short) }
                }
                .buttonStyle(ChipStyle(isSelected: isOn))
                .accessibilityLabel("\(field.label): \(weekday.long)")
            }
        }
    }
}
