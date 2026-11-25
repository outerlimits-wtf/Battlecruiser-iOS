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
    private var settleTask: Task<Void, Never>?
    private let dotsOverlay = PinDotsOverlay()
    private let dotsRenderer: PinDotsRenderer

    private(set) var pins: [Pin] = []
    private var pinsByID: [String: Pin] = [:]
    private var selectedID: String?
    private var viewport: MapViewport?
    private var colorScheme: ColorScheme?
    /// A camera move asked for before the map had a size, applied once it has one.
    private var pendingCamera: (request: MapCameraRequest, animated: Bool)?
    /// The full pins on the map, by pub id.
    private var annotations: [String: PinAnnotation] = [:]

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
        syncFullPins(forceRedraw: schemeChanged, restyle: [previousSelection, selectedID].compactMap { $0 })
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

    private func performPendingCamera() {
        guard let pending = pendingCamera else { return }
        pendingCamera = nil
        perform(pending.request, animated: pending.animated)
    }

    // MARK: - Full pins and dots

    /// Make the full pins match what should be shown: add and remove only the
    /// difference, replace a pin whose details changed, then repaint the dots
    /// without the pubs that now have full pins.
    private func syncFullPins(forceRedraw: Bool = false, restyle: [String] = []) {
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
        dotsRenderer.show(DotSnapshot(pins: pins, hidden: hidden, traits: mapView.traitCollection))
    }

    private func restyleView(for annotation: PinAnnotation) {
        guard let view = mapView?.view(for: annotation) as? PinAnnotationView else { return }
        view.configure(annotation.pin, isSelected: annotation.pin.id == selectedID, reduceMotion: reduceMotion)
    }

    // MARK: - Delegate

    public func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        overlay === dotsOverlay ? dotsRenderer : MKOverlayRenderer(overlay: overlay)
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? PinAnnotation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: PinAnnotationView.reuseIdentifier, for: annotation
        ) as? PinAnnotationView
        view?.configure(annotation.pin, isSelected: annotation.pin.id == selectedID, reduceMotion: reduceMotion)
        return view
    }

    public func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
        guard let annotation = annotation as? PinAnnotation else { return }
        // Selection is the app's, not MapKit's: no callout, just open the pub.
        mapView.deselectAnnotation(annotation, animated: false)
        onSelect(annotation.pin)
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        settleTask?.cancel()
        settleTask = Task { [weak self, weak mapView] in
            try? await Task.sleep(for: Self.settleDelay)
            guard !Task.isCancelled, let self, let mapView else { return }
            let settled = MapViewport(mapView)
            viewport = settled
            syncFullPins()
            onViewportChange(settled)
        }
    }

    // MARK: - Tapping a dot

    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        guard let mapView, recognizer.state == .ended else { return }
        let location = recognizer.location(in: mapView)
        // A tap on a full pin or the user's dot belongs to that view.
        var hit = mapView.hitTest(location, with: nil)
        while let view = hit {
            if view is MKAnnotationView { return }
            hit = view.superview
        }
        let pin = DotHitTest.nearest(to: location, in: pins, excluding: Set(annotations.keys)) { pin in
            mapView.convert(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), toPointTo: mapView)
        }
        if let pin {
            onSelect(pin)
        }
    }
}
