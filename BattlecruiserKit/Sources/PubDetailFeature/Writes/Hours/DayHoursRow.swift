import SwiftUI
import DesignSystem
import PubDBModels

/// One day in the hours editor: Open / Closed / Don't know, and while open,
/// each session's opening and closing time, with "late" for no fixed close.
struct DayHoursRow: View {
    let name: String
    @Binding var day: DayHours
    let onCopyToEveryDay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            HStack {
                Text(name).font(Typography.body.weight(.semibold)).foregroundStyle(Palette.ink)
                Spacer()
                Text(day.summary).font(Typography.secondary).foregroundStyle(Palette.inkMuted)
            }
            .accessibilityElement(children: .combine)
            Picker(name, selection: kind) {
                Text("Open").tag(DayState?.some(.open))
                Text("Closed").tag(DayState?.some(.closed))
                Text("Don't know").tag(DayState?.some(.unknown))
            }
            .pickerStyle(.segmented)
            if case .open(let sessions) = day {
                ForEach(sessions.indices, id: \.self) { index in
                    sessionRow(index, of: sessions)
                }
                HStack {
                    Button("Add a session") {
                        if case .open(let sessions) = day {
                            day = .open(sessions + [HoursSession(open: "18:00", close: "23:00")])
                        }
                    }
                    Spacer()
                    Button("Same every day", action: onCopyToEveryDay)
                        .accessibilityHint("Gives every day \(name)'s hours")
                }
                .font(Typography.secondary.weight(.semibold))
                .foregroundStyle(Palette.beer)
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, Metrics.xs)
    }

    private var kind: Binding<DayState?> {
        Binding(
            get: { day.kind },
            set: { new in
                switch new {
                case .open: if day.kind != .open { day = .open([DayHours.defaultSession]) }
                case .closed: day = .closed
                case .unknown: day = .unknown
                case nil: day = .unset
                }
            }
        )
    }

    private func sessionRow(_ index: Int, of sessions: [HoursSession]) -> some View {
        let session = sessions[index]
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Metrics.s) { sessionControls(index, session, count: sessions.count) }
            VStack(alignment: .leading, spacing: Metrics.s) { sessionControls(index, session, count: sessions.count) }
        }
    }

    @ViewBuilder
    private func sessionControls(_ index: Int, _ session: HoursSession, count: Int) -> some View {
        TimeStepPicker(label: "\(name) opens", time: binding(index, \.open))
        Text("to").font(Typography.secondary).foregroundStyle(Palette.inkMuted).accessibilityHidden(true)
        if session.close != nil {
            TimeStepPicker(label: "\(name) closes", time: closeBinding(index))
        }
        Toggle("Late", isOn: lateBinding(index))
            .toggleStyle(.button)
            .font(Typography.secondary)
            .accessibilityLabel("No fixed closing time")
        if count > 1 {
            Button {
                update { $0.remove(at: index) }
            } label: {
                Image(systemName: "minus.circle").frame(width: Metrics.minTap, height: Metrics.minTap)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Palette.inkMuted)
            .accessibilityLabel("Remove this session")
        }
    }

    private func update(_ change: (inout [HoursSession]) -> Void) {
        guard case .open(var sessions) = day else { return }
        change(&sessions)
        day = sessions.isEmpty ? .closed : .open(sessions)
    }

    private func binding(_ index: Int, _ path: WritableKeyPath<HoursSession, String>) -> Binding<String> {
        Binding(
            get: { if case .open(let s) = day, s.indices.contains(index) { s[index][keyPath: path] } else { "" } },
            set: { new in update { if $0.indices.contains(index) { $0[index][keyPath: path] = new } } }
        )
    }

    private func closeBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { if case .open(let s) = day, s.indices.contains(index) { s[index].close ?? "23:00" } else { "23:00" } },
            set: { new in update { if $0.indices.contains(index) { $0[index].close = new } } }
        )
    }

    private func lateBinding(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { if case .open(let s) = day, s.indices.contains(index) { s[index].close == nil } else { false } },
            set: { late in update { if $0.indices.contains(index) { $0[index].close = late ? nil : "23:00" } } }
        )
    }
}
