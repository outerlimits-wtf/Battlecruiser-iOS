import SwiftUI
import DesignSystem
import PubDBModels

/// `amenity`: every venue kind from `/meta`, the pub's own picked. Tapping
/// another sends its key. A kind's note, where it has one, is read as a hint.
struct AmenityEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let kinds: [VenueKind]
    let send: (String) -> Void

    var body: some View {
        ChipFlow {
            ForEach(kinds) { kind in
                let isOn = current?.value == kind.key
                Button("\(kind.symbol.emoji) \(kind.label)") {
                    if !isOn { send(kind.key) }
                }
                .buttonStyle(ChipStyle(isSelected: isOn))
                .accessibilityLabel("\(field.label): \(kind.label)")
                .accessibilityHint(kind.note ?? "")
            }
        }
    }
}
