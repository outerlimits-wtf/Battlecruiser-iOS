import PubDBModels

/// The order pubs are shown in, on the map and in the list.
///
/// Production returns pubs nearest the centre of the requested area, not
/// open-first as the v1 spec says (docs/backend/03-api-reference.md), so the
/// app sorts: open, then hours unknown, then closed, each nearest-first. Only
/// values the server sent are used (decision D12).
public nonisolated enum PubOrdering {
    public static func forDisplay(_ pubs: [PubSummary]) -> [PubSummary] {
        pubs.enumerated()
            .sorted { first, second in
                let firstRank = rank(first.element)
                let secondRank = rank(second.element)
                if firstRank != secondRank {
                    return firstRank < secondRank
                }
                let firstDistance = first.element.distance?.metres ?? .max
                let secondDistance = second.element.distance?.metres ?? .max
                if firstDistance != secondDistance {
                    return firstDistance < secondDistance
                }
                // Equal on both: keep the server's order.
                return first.offset < second.offset
            }
            .map { $0.element }
    }

    /// 0 is shown first. A pub that is not trading counts as closed, whatever
    /// its last known hours say.
    static func rank(_ pub: PubSummary) -> Int {
        guard pub.status.serving else {
            return 2
        }
        switch pub.open.state {
        case .open:
            return 0
        case .unknown:
            return 1
        case .closed:
            return 2
        }
    }
}
