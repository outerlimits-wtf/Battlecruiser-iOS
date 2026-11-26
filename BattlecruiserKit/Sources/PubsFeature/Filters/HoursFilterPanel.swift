import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// "WHEN ARE YOU DRINKING": known hours only, a day, and how late.
struct HoursFilterPanel: View {
    @Binding var query: PubQuery
    let weekdays: [Weekday]

    var body: some View {
        SectionHeader("When are you drinking")
        Toggle("Only pubs we know the hours of", isOn: $query.hasHours)
            .font(Typography.body)
            .tint(Palette.good)
        Text("Open on a day").font(Typography.secondary).foregroundStyle(Palette.inkMuted)
        ChipFlow {
            ForEach(weekdays) { weekday in
                Button(weekday.short) {
                    query.openOnDay = query.openOnDay == weekday.day ? nil : weekday.day
                }
                .buttonStyle(ChipStyle(isSelected: query.openOnDay == weekday.day))
                .accessibilityLabel(weekday.long)
            }
        }
        TimeFilterField(title: "Still open at", value: $query.closesAfter, fallback: "23:00")
    }
}

/// A time the filter can be set to, or not set at all. Sent as "HH:MM".
struct TimeFilterField: View {
    let title: String
    @Binding var value: String?
    /// Where the picker starts when switched on.
    let fallback: String

    var body: some View {
        HStack {
            Toggle(title, isOn: isOn)
                .font(Typography.body)
                .tint(Palette.good)
            if value != nil {
                DatePicker(title, selection: date, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_GB"))
            }
        }
    }

    private var isOn: Binding<Bool> {
        Binding(get: { value != nil }, set: { value = $0 ? fallback : nil })
    }

    private var date: Binding<Date> {
        Binding(
            get: { TimeOfDay.date(from: value ?? fallback) },
            set: { value = TimeOfDay.string(from: $0) }
        )
    }
}

/// "HH:MM" to and from a `Date` today, for the time picker. Only for what the
/// user types; nothing the server sends is parsed.
enum TimeOfDay {
    static func date(from string: String) -> Date {
        let parts = string.split(separator: ":").compactMap { Int($0) }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = parts.first ?? 0
        components.minute = parts.count > 1 ? parts[1] : 0
        return Calendar.current.date(from: components) ?? Date()
    }

    static func string(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
