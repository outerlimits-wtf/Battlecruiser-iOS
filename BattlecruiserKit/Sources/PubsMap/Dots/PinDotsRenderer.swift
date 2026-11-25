import MapKit
import os

/// Paints every dot in a tile: one fill per state, not one per pub, so all of
/// London costs a millisecond or two. MapKit calls `draw` on background
/// threads, once per tile, and again for each tile after `setNeedsDisplay()`.
final class PinDotsRenderer: MKOverlayRenderer, @unchecked Sendable {
    private let current = OSAllocatedUnfairLock(initialState: DotSnapshot.empty)

    /// Swap in new dots and repaint.
    func show(_ snapshot: DotSnapshot) {
        current.withLock { $0 = snapshot }
        setNeedsDisplay()
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let snapshot = current.withLock { $0 }
        // Sizes are in screen points; the context is in map points.
        let pointsToMap = 1 / zoomScale
        let outline = DotSnapshot.outlineWidth * pointsToMap

        for group in snapshot.groups {
            let radius = group.radius * pointsToMap
            let reach = radius + outline
            let area = mapRect.insetBy(dx: -reach, dy: -reach)
            let visible = group.points.filter(area.contains)
            guard !visible.isEmpty else { continue }

            if let ring = group.outline {
                context.setFillColor(ring)
                for point in visible {
                    context.addEllipse(in: circle(at: point, radius: reach))
                }
                context.fillPath()
            }
            context.setFillColor(group.fill)
            for point in visible {
                context.addEllipse(in: circle(at: point, radius: radius))
            }
            context.fillPath()
        }
    }

    private func circle(at mapPoint: MKMapPoint, radius: CGFloat) -> CGRect {
        let centre = point(for: mapPoint)
        return CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)
    }
}
