import SwiftUI
import DesignSystem

/// The one time control the hours editor and night forms share: a time as
/// `HH:MM`, picked in 5-minute steps (parity-plan "Time pickers"). Shows the
/// time as a chip; tapping it opens hour and minute wheels underneath.
struct TimeStepPicker: View {
    /// The step, in minutes, for every time picker in the app.
    static let step = 5

    let label: String
    @Binding var time: String
    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.xs) {
            Button {
                isOpen.toggle()
            } label: {
                Text(time).monospacedDigit()
            }
            .buttonStyle(ChipStyle(isSelected: isOpen))
            .accessibilityLabel("\(label), \(time)")
            .accessibilityHint(isOpen ? "Hides the time wheels" : "Shows wheels to pick a time")
            if isOpen {
                HStack(spacing: 0) {
                    Picker("Hour", selection: hour) {
                        ForEach(0..<24, id: \.self) { Text(Self.twoDigits($0)).tag($0) }
                    }
                    Picker("Minute", selection: minute) {
                        ForEach(minutes, id: \.self) { Text(Self.twoDigits($0)).tag($0) }
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(label)
            }
        }
    }

    /// The steps, plus the current minute when the server sent one off-step
    /// (a pub's "22:47" stays as it is until someone changes it).
    private var minutes: [Int] {
        let steps = Array(stride(from: 0, to: 60, by: Self.step))
        let current = Self.parts(time).minute
        return steps.contains(current) ? steps : (steps + [current]).sorted()
    }

    private var hour: Binding<Int> {
        Binding(get: { Self.parts(time).hour }, set: { time = Self.format($0, Self.parts(time).minute) })
    }

    private var minute: Binding<Int> {
        Binding(get: { Self.parts(time).minute }, set: { time = Self.format(Self.parts(time).hour, $0) })
    }

    /// `HH:MM` to numbers; "24:00" is midnight, shown as 00.
    static func parts(_ time: String) -> (hour: Int, minute: Int) {
        let pieces = time.split(separator: ":").compactMap { Int($0) }
        guard pieces.count == 2 else { return (0, 0) }
        return (pieces[0] % 24, min(max(pieces[1], 0), 59))
    }

    static func format(_ hour: Int, _ minute: Int) -> String {
        "\(twoDigits(hour)):\(twoDigits(minute))"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
