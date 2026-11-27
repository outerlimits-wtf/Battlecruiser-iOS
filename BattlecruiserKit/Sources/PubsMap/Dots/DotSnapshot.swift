import MapKit
import UIKit
import DesignSystem
import PubDBModels

/// Everything the dot renderer needs, projected and coloured once, then never
/// changed: the renderer draws on background threads, so it reads only this.
final class DotSnapshot: @unchecked Sendable {
    struct Group {
        let points: [MKMapPoint]
        let radius: CGFloat
        let fill: CGColor
        /// The ring for loud states, in the surface colour; nil for quiet ones.
        let outline: CGColor?
    }

    /// Quietest first, so loud dots are painted on top.
    let groups: [Group]

    static let empty = DotSnapshot(groups: [])

    /// The ring around open and closing dots, in points.
    static let outlineWidth: CGFloat = 1.5

    private init(groups: [Group]) {
        self.groups = groups
    }

    /// - Parameters:
    ///   - hidden: Pubs drawn as full pins instead, so never as both.
    ///   - traits: Light or dark, to resolve the colours for.
    @MainActor
    convenience init(pins: [Pin], hidden: Set<String>, traits: UITraitCollection) {
        var byState: [PinState: [MKMapPoint]] = [:]
        for pin in pins where !hidden.contains(pin.id) {
            let state = PinState(rawValue: pin.state) ?? .unknown
            byState[state, default: []].append(
                MKMapPoint(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
            )
        }
        let surface = UIColor(Palette.surface).resolvedColor(with: traits).cgColor
        let groups = PinState.allCases
            .sorted { $0.rank < $1.rank }
            .compactMap { state -> Group? in
                guard let points = byState[state], !points.isEmpty else { return nil }
                let fill = state.uiColor.resolvedColor(with: traits).withAlphaComponent(state.dotOpacity).cgColor
                return Group(
                    points: points,
                    radius: state.dotRadius,
                    fill: fill,
                    outline: state.hasOutline ? surface : nil
                )
            }
        self.init(groups: groups)
    }
}
