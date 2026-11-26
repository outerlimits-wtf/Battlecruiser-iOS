import MapKit
import SwiftUI
import PubDBModels

/// The map's delegate: reports where it settles, and keeps the pubs drawn,
/// dots for all of them and full pins for the few in view when zoomed in.
public final class PubMapCoordinator: NSObject, MKMapViewDelegate {
    var onViewportChange: (MapViewport) -> Void = { _ in }
    var onSelect: (Pin) -> Void = { _ in }
    var reduceMotion = false

    weak var mapView: MKMapView?
    var settleTask: Task<Void, Never>?
    let dotsOverlay = PinDotsOverlay()
    let dotsRenderer: PinDotsRenderer

    private(set) var pins: [Pin] = []
    var pinsByID: [String: Pin] = [:]
    var selectedID: String?
    var viewport: MapViewport?
    var colorScheme: ColorScheme?
    /// A camera move asked for before the map had a size, applied once it has one.
    var pendingCamera: (request: MapCameraRequest, animated: Bool)?
    /// The full pins on the map, by pub id.
    var annotations: [String: PinAnnotation] = [:]
    /// The pubs left out of the dots last time they were painted, so a settle
    /// that changes nothing doesn't repaint every tile.
    var paintedHidden: Set<String>?

    /// Set when a pan, pinch or rotate starts a move; cleared once it settles.
    var isUserMove = false

    /// How long the map must be still before it counts as settled (the web's 300 ms).
    static let settleDelay: Duration = .milliseconds(300)

    override init() {
        dotsRenderer = PinDotsRenderer(overlay: dotsOverlay)
        super.init()
    }

    func attach(to mapView: MKMapView) {
        self.mapView = mapView
        mapView.register(PinAnnotationView.self, forAnnotationViewWithReuseIdentifier: PinAnnotationView.reuseIdentifier)
        mapView.addOverlay(dotsOverlay, level: .aboveRoads)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tap)
    }

    func update(pins: [Pin], selectedID: String?, colorScheme: ColorScheme) {
        let pinsChanged = pins != self.pins
        let selectionChanged = selectedID != self.selectedID
        let schemeChanged = colorScheme != self.colorScheme
        guard pinsChanged || selectionChanged || schemeChanged else { return }

        let previousSelection = self.selectedID
        self.pins = pins
        if pinsChanged {
            pinsByID = Dictionary(pins.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        }
        self.selectedID = selectedID
        self.colorScheme = colorScheme
        syncFullPins(
            forceRedraw: schemeChanged,
            repaintDots: pinsChanged || schemeChanged,
            restyle: [previousSelection, selectedID].compactMap { $0 }
        )
    }

    /// Move the camera now, or as soon as the map has been laid out: a region
    /// set on a map with no size lands somewhere else.
    func perform(_ request: MapCameraRequest, animated: Bool) {
        guard let mapView, mapView.bounds.width > 0, mapView.bounds.height > 0 else {
            pendingCamera = (request, animated)
            DispatchQueue.main.async { [weak self] in self?.performPendingCamera() }
            return
        }
        request.apply(to: mapView, animated: animated)
    }

    func performPendingCamera() {
        guard let pending = pendingCamera else { return }
        pendingCamera = nil
        perform(pending.request, animated: pending.animated)
    }

    // MARK: - Full pins and dots

    /// Make the full pins match what should be shown: add and remove only the
    /// difference, replace a pin whose details changed, then repaint the dots
    /// without the pubs that now have full pins.
    ///
    /// Repainting the dots throws away every tile MapKit has drawn, at every
    /// zoom, and until they are drawn again it stretches whatever coarser tile
    /// it still has, so the dots swell into blobs. So it only happens when the
    /// dots would look different: new pins, a new colour scheme, or a change
    /// in which pubs have full pins.
    /// - Parameter repaintDots: The pins or colours changed.
    func syncFullPins(forceRedraw: Bool = false, repaintDots: Bool = false, restyle: [String] = []) {
        guard let mapView else { return }
        let wanted = FullPinSelection.ids(for: pins, in: viewport, selectedID: selectedID)
        let shown = Set(annotations.keys)

        var stale: [PinAnnotation] = []
        var fresh: [PinAnnotation] = []
        for id in shown.subtracting(wanted) {
            if let gone = annotations.removeValue(forKey: id) { stale.append(gone) }
        }
        for id in wanted {
            guard let pin = pinsByID[id] else { continue }
            if let existing = annotations[id] {
                guard existing.pin != pin else { continue }
                stale.append(existing)
            }
            let annotation = PinAnnotation(pin)
            annotations[id] = annotation
            fresh.append(annotation)
        }
        mapView.removeAnnotations(stale)
        mapView.addAnnotations(fresh)

        for id in restyle {
            if let annotation = annotations[id] { restyleView(for: annotation) }
        }
        if forceRedraw {
            annotations.values.forEach(restyleView)
        }
        let hidden = Set(annotations.keys)
        guard repaintDots || hidden != paintedHidden else { return }
        paintedHidden = hidden
        dotsRenderer.show(DotSnapshot(pins: pins, hidden: hidden, traits: mapView.traitCollection))
    }

    func restyleView(for annotation: PinAnnotation) {
        guard let view = mapView?.view(for: annotation) as? PinAnnotationView else { return }
        view.configure(annotation.pin, isSelected: annotation.pin.id == selectedID, reduceMotion: reduceMotion)
    }
}
