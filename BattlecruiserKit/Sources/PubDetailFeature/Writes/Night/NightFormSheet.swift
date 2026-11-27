import SwiftUI
import DesignSystem
import PubDBModels

/// A night field, as the hours editor's sibling: the same day rows and the
/// same time picker, with only a closing time. Tonight (the server's
/// `session`) comes first and can be reported as "just now".
struct NightFormSheet: View {
    let field: ContributableField
    let weekdays: [Weekday]
    let session: NightSession?
    let send: (String) -> Void

    @State private var times: [Int: String] = [:]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let session {
                    Section {
                        Button("It just happened") {
                            send(NightReport.justNow())
                            dismiss()
                        }
                        .font(Typography.body.weight(.semibold))
                        .foregroundStyle(Palette.beer)
                        .accessibilityHint("Reports \(field.label.lowercased()) for \(session.long) night at the time now")
                    } header: {
                        Text("Tonight, \(session.long)")
                    }
                }
                Section {
                    ForEach(ordered) { weekday in
                        row(weekday)
                    }
                } header: {
                    Text("Or pick the night and time")
                } footer: {
                    Text("Past midnight still counts as the night before: half twelve after a Thursday is Thursday.")
                }
            }
            .navigationTitle(field.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// The week, starting from tonight.
    private var ordered: [Weekday] {
        guard let session, let start = weekdays.firstIndex(where: { $0.day == session.day }) else { return weekdays }
        return Array(weekdays[start...] + weekdays[..<start])
    }

    private func row(_ weekday: Weekday) -> some View {
        let isTonight = weekday.day == session?.day
        return VStack(alignment: .leading, spacing: Metrics.s) {
            HStack(spacing: Metrics.s) {
                Text(weekday.long).font(Typography.body.weight(.semibold)).foregroundStyle(Palette.ink)
                if isTonight {
                    Text("Tonight").font(Typography.secondary).foregroundStyle(Palette.beer)
                }
            }
            .accessibilityElement(children: .combine)
            HStack(alignment: .top, spacing: Metrics.s) {
                TimeStepPicker(label: "\(field.label), \(weekday.long)", time: time(for: weekday.day))
                Spacer()
                Button(field.corroborating ? "Report" : "Save") {
                    send(NightReport.value(night: weekday.short, time: time(for: weekday.day).wrappedValue))
                    dismiss()
                }
                .buttonStyle(ChipStyle(isSelected: true))
                .accessibilityLabel("Report \(field.label.lowercased()) for \(weekday.long)")
            }
        }
        .padding(.vertical, Metrics.xs)
    }

    private func time(for day: Int) -> Binding<String> {
        Binding(get: { times[day] ?? "23:00" }, set: { times[day] = $0 })
    }
}
