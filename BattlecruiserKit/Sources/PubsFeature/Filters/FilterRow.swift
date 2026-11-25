import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels

/// The web's filter pills, scrolling sideways under the search bar. Pills
/// marked ▾ open a panel; the rest switch on and off.
struct FilterRow: View {
    @Binding var query: PubQuery
    @Binding var openPanel: FilterPanel?
    let meta: Meta?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.s) {
                toggle(isOn: $query.openNow) {
                    HStack(spacing: 4) {
                        Circle().fill(Palette.good).frame(width: 7, height: 7)
                        Text("Open now")
                    }
                }
                panelPill(.kind, FilterLabels.kind(query))
                panelPill(.hours, FilterLabels.hours(query, weekdays: meta?.weekdays ?? []))
                panelPill(.features, FilterLabels.features(query, all: meta?.features ?? []))
                panelPill(.rating, FilterLabels.rating(query))
                panelPill(.guinness, FilterLabels.guinness(query))
                toggle(isOn: $query.hasPhoto) { Text("Has photo") }
                toggle(isOn: $query.listed) { Text("Listed") }
                toggle(isOn: $query.includeClosed) { Text("Closed pubs") }
                toggle(isOn: $query.latestClose) { Text("Latest close") }
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
