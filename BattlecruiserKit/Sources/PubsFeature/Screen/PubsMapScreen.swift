import SwiftUI
import DesignSystem
import PubDBClient
import PubDBModels
import PubsMap

/// The Map tab, laid out as the web is on a phone: the map, and over it a
/// bottom sheet holding the list of pubs, or the selected pub's panel.
///
/// The map draws every pin (`PinsModel`, from `/pins`); the list draws the
/// pubs in the map's area (`PubsModel`, from `/pubs`). A tapped pin or row goes
/// to the root, which opens the pub and hands its panel back as `panel`. This
/// module knows nothing of the detail feature, permissions or lifecycle.
public struct PubsMapScreen<Panel: View>: View {
    let pubs: PubsModel
    let pins: PinsModel
    let userCoordinate: Coordinate?
    let isLocationDenied: Bool
    let selectedID: String?
    let onSelectPin: (Pin) -> Void
    let onSelectPub: (PubSummary) -> Void
    /// The selected pub's panel, shown in the sheet instead of the list.
    let panel: Panel?
    /// The server's lists, for the filters; nil until loaded.
    let meta: Meta?
    /// Pubs on the person's Been here list, ticked in the results.
    let visitedIDs: Set<String>
    /// Typing a search: close the open pub, so the results show (as the web).
    let onSearch: () -> Void

    @State var detent: SheetDetent = .half
    /// The search and filters, shared by the list and the pins.
    @State var query = PubQuery()
    @State var openPanel: FilterPanel?
    @State var cameraRequest: MapCameraRequest?
    /// Whether the person has moved the map themselves this launch.
    @State var userHasMovedMap = false
    /// Whether the map has been brought to the user's first fix this launch.
    @State var hasCenteredOnUser = false
    /// The height of the search bar and filter pills: the sheet stops below
    /// them at full, so the grabber is never tucked under the filters.
    @State var controlsHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    public init(
        pubs: PubsModel,
        pins: PinsModel,
        userCoordinate: Coordinate?,
        isLocationDenied: Bool,
        selectedID: String?,
        onSelectPin: @escaping (Pin) -> Void,
        onSelectPub: @escaping (PubSummary) -> Void,
        panel: Panel?,
        meta: Meta?,
        visitedIDs: Set<String> = [],
        onSearch: @escaping () -> Void = {}
    ) {
        self.pubs = pubs
        self.pins = pins
        self.userCoordinate = userCoordinate
        self.isLocationDenied = isLocationDenied
        self.selectedID = selectedID
        self.onSelectPin = onSelectPin
        self.onSelectPub = onSelectPub
        self.panel = panel
        self.meta = meta
        self.visitedIDs = visitedIDs
        self.onSearch = onSearch
    }

    public var body: some View {
        ZStack {
            PubMapView(
                pins: pins.pins,
                selectedID: selectedID,
                cameraRequest: $cameraRequest,
                onViewportChange: { viewport in
                    if viewport.movedByUser { userHasMovedMap = true }
                    pubs.areaChanged(to: viewport.area)
                },
                onSelect: onSelectPin
            )
            // Keep Apple's credit and the controls clear of the sheet's peek.
            .safeAreaPadding(.bottom, SheetDetent.peekHeight)
            // Edge to edge: the tab bar floats over it.
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                MapAttribution().padding(.bottom, SheetDetent.peekHeight)
            }
            sheet
        }
        .overlay(alignment: .top) {
            VStack(spacing: Metrics.s) {
                VStack(spacing: Metrics.s) {
                    SearchBar { text in
                        guard text != query.search else { return }
                        query.search = text
                        // Clearing the box leaves whatever is open alone.
                        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSearch()
                        // The results are what was asked for: open the sheet
                        // all the way, as the keyboard hides the lower half.
                        if detent != .full {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { detent = .full }
                        }
                    }
                        .padding(.horizontal, Metrics.m)
                    FilterRow(query: $query, openPanel: $openPanel, meta: meta)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { controlsHeight = $0 }
                if let openPanel {
                    FilterPanelCard(panel: openPanel, query: $query, meta: meta) { self.openPanel = nil }
                }
                // About the map, so not over a sheet that covers it.
                if detent != .full {
                    StatusBanner(
                        pubs: pubs,
                        isLocationDenied: isLocationDenied,
                        showsNotice: detent == .peek,
                        onGoToLondon: goToLondon
                    )
                }
            }
        }
        .onChange(of: query) { _, query in
            pubs.queryChanged(query)
            pins.queryChanged(query)
        }
        .task {
            // Last session's pubs first, marked with their age, so the screen
            // is never empty while the first fetch is under way.
            await pubs.loadCached()
            // The map normally reports its area as soon as it appears. If it
            // hasn't after a second, show London rather than an empty list.
            try? await Task.sleep(for: .seconds(1))
            pubs.loadIfIdle(in: MapPlaces.fallbackArea)
        }
        .task {
            #if DEBUG
            // For looking at the sheet's contents in the Simulator.
            if ProcessInfo.processInfo.arguments.contains("-sheetFull") { detent = .full }
            #endif
            pins.refresh()
            await pins.refreshPeriodically()
        }
        .onChange(of: userCoordinate, initial: true) { _, coordinate in
            pubs.userLocationChanged(to: coordinate)
            centerOnUserIfNeeded(at: coordinate)
        }
        .task(id: Freshness.refreshInterval(for: pubs.pubs)) {
            await pubs.refreshPeriodically(every: Freshness.refreshInterval(for: pubs.pubs))
        }
    }
}

#Preview("Live data") {
    PubsMapScreen<EmptyView>(
        pubs: PubsModel(source: PubDBClient()),
        pins: PinsModel(source: PubDBClient()),
        userCoordinate: nil,
        isLocationDenied: false,
        selectedID: nil,
        onSelectPin: { _ in },
        onSelectPub: { _ in },
        panel: nil,
        meta: nil
    )
}
