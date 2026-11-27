import SwiftUI
import DesignSystem
import PubDBClient

/// The bottom sheet: the list with its header, or the selected pub's panel.
extension PubsMapScreen {
    var sheet: some View {
        BottomSheet(
            detent: $detent,
            resetKey: selectedID,
            // Until the controls are measured, the sheet's own default. A clear
            // gap under the filters, so a thumb going for the grabber at full
            // doesn't land on a pill instead.
            topInset: controlsHeight > 0 ? controlsHeight + Metrics.xl : nil,
            overlaysGrabber: panel != nil
        ) {
            if panel == nil {
                ResultsHeader(
                    count: pubs.pubs.count,
                    openCount: pubs.openCount,
                    isLoading: pubs.isLoading,
                    knowsLocation: userCoordinate != nil,
                    isEverywhere: !query.usesArea,
                    onTurnOffEverywhere: query.everywhere ? { query.everywhere = false } : nil
                )
            }
        } content: {
            if let panel {
                panel
            } else {
                ResultsList(
                    pubs: pubs,
                    selectedID: selectedID,
                    visitedIDs: visitedIDs,
                    onGoToLondon: goToLondon,
                    onSelect: onSelectPub,
                    onSearchEverywhere: query.everywhere ? nil : { query.everywhere = true },
                    onIncludeBars: query.amenity == "pub" ? { query.amenity = nil } : nil,
                    onClearFilters: query.activeFilterCount > 0 ? { query = PubQuery() } : nil,
                    scrolledID: $listScrolledID
                )
            }
        }
    }
}
