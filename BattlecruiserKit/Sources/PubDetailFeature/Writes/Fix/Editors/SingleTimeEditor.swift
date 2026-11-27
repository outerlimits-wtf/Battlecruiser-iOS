import SwiftUI
import DesignSystem
import PubDBModels

/// A single time of day (`garden_closes`) on the shared time picker,
/// starting from the current value when it is a time.
struct SingleTimeEditor: View {
    let field: ContributableField
    let current: EditableValue?
    let send: (String) -> Void

    @State private var time = "21:00"

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xs) {
            if let display = current?.display, !Self.isTime(display) {
                Text(display).font(Typography.body).foregroundStyle(Palette.ink)
            }
            HStack(alignment: .top, spacing: Metrics.s) {
                TimeStepPicker(label: field.label, time: $time)
                Button("Save") { send(time) }
                    .buttonStyle(ChipStyle(isSelected: time != current?.value))
                    .disabled(time == current?.value)
                    .accessibilityLabel("Save \(field.label.lowercased())")
            }
        }
        .onAppear(perform: reset)
        .onChange(of: current?.value) { reset() }
    }

    private func reset() {
        if let value = current?.value, Self.isTime(value) { time = value }
    }

    static func isTime(_ text: String) -> Bool {
        let pieces = text.split(separator: ":", omittingEmptySubsequences: false)
        return pieces.count == 2 && pieces.allSatisfy { $0.count == 2 && $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }
    }
}
