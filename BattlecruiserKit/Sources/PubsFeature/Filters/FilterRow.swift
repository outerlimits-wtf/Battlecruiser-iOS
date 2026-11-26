import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// The web's filter pills, scrolling sideways under the search bar. Pills
/// marked ▾ open a panel; the rest switch on and off. Whatever is set moves
/// to the front, filled in and saying what it is ("Oddity", "Taproom +2"),
/// so the filters at work are never scrolled out of sight.
struct FilterRow: View {
    @Binding var query: PubQuery
    @Binding var openPanel: FilterPanel?
    let meta: Meta?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.s) {
                ForEach(FilterPill.ordered(for: query)) { pill in
                    view(for: pill)
                }
                if query.activeFilterCount > 0 {
                    Button("Reset") {
                        let search = query.search
                        query = PubQuery()
                        query.search = search
                        openPanel = nil
                    }
                    .buttonStyle(PillStyle())
                    .foregroundStyle(Palette.beer)
                }
            }
            .padding(.horizontal, Metrics.m)
            .padding(.vertical, 6)
            .animation(reduceMotion ? nil : .default, value: FilterPill.ordered(for: query))
        }
    }

    @ViewBuilder
    private func view(for pill: FilterPill) -> some View {
        switch pill {
        case .openNow:
            toggle(isOn: $query.openNow) {
                HStack(spacing: 4) {
                    Circle().fill(Palette.good).frame(width: 7, height: 7)
                    Text("Open now")
                }
            }
        case .panel(let panel):
            panelPill(panel, title(of: panel))
        case .includeClosed:
            toggle(isOn: $query.includeClosed) { Text("Closed pubs") }
        case .latestClose:
            toggle(isOn: $query.latestClose) { Text("Latest close") }
        }
    }

    private func title(of panel: FilterPanel) -> String {
        switch panel {
        case .kind: FilterLabels.kind(query, all: meta?.venueKinds ?? [])
        case .hours: FilterLabels.hours(query, weekdays: meta?.weekdays ?? [])
        case .features: FilterLabels.features(query, all: meta?.features ?? [])
        case .rating: FilterLabels.rating(query)
        case .guinness: FilterLabels.guinness(query)
        }
    }

    private func toggle(isOn: Binding<Bool>, @ViewBuilder label: () -> some View) -> some View {
        Button { isOn.wrappedValue.toggle() } label: { label() }
            .buttonStyle(PillStyle(isActive: isOn.wrappedValue))
    }

    private func panelPill(_ panel: FilterPanel, _ title: String) -> some View {
        Button {
            openPanel = openPanel == panel ? nil : panel
        } label: {
            Text("\(title) ▾")
        }
        .buttonStyle(PillStyle(isActive: FilterLabels.isActive(panel, in: query) || openPanel == panel))
        .accessibilityLabel(title)
        .accessibilityHint("Shows the choices")
    }
}

/// One pill in the row, so the row can put the ones that are set first.
enum FilterPill: Hashable, Identifiable {
    case openNow
    case panel(FilterPanel)
    case includeClosed
    case latestClose

    var id: Self { self }

    /// The web's order, with whatever is set moved to the front (in that
    /// same order among themselves).
    static func ordered(for query: PubQuery) -> [FilterPill] {
        let all: [FilterPill] = [.openNow] + FilterPanel.allCases.map { .panel($0) } + [.includeClosed, .latestClose]
        let set = all.filter { $0.isActive(in: query) }
        return set + all.filter { !$0.isActive(in: query) }
    }

    func isActive(in query: PubQuery) -> Bool {
        switch self {
        case .openNow: query.openNow
        case .panel(let panel): FilterLabels.isActive(panel, in: query)
        case .includeClosed: query.includeClosed
        case .latestClose: query.latestClose
        }
    }
}
