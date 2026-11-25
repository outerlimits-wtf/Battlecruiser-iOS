import CoreGraphics
import PubDBModels

/// Which dot a tap meant: the nearest drawn one within reach (the web's 12 pt).
enum DotHitTest {
    static let tolerance: CGFloat = 12

    /// - Parameter project: Where a pin is on screen, in points.
    static func nearest(
        to tap: CGPoint,
        in pins: [Pin],
        excluding hidden: Set<String>,
        project: (Pin) -> CGPoint
    ) -> Pin? {
        var best: (pin: Pin, distance: CGFloat)?
        for pin in pins where !hidden.contains(pin.id) {
            let point = project(pin)
            let dx = point.x - tap.x
            let dy = point.y - tap.y
            guard abs(dx) <= tolerance, abs(dy) <= tolerance else { continue }
            let distance = (dx * dx + dy * dy).squareRoot()
            // Ties go to the later pin: the server sends loudest last, and it is drawn on top.
            if distance <= tolerance, distance <= (best?.distance ?? .infinity) {
                best = (pin, distance)
            }
        }
        return best?.pin
    }
}
