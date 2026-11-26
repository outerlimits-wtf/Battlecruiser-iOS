import UIKit

/// The web's pin: a square with three round corners, turned so the sharp one
/// points down at the pub.
enum TeardropShape {
    /// The path for a pin of `size`, in a box `size × height(for:)`, tip at the bottom centre.
    static func path(size: CGFloat) -> UIBezierPath {
        let square = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
            byRoundingCorners: [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: size / 2, height: size / 2)
        )
        // Turn about the centre so the sharp corner (bottom left) points down.
        let centre = CGPoint(x: size / 2, y: size / 2)
        square.apply(CGAffineTransform(translationX: -centre.x, y: -centre.y))
        square.apply(CGAffineTransform(rotationAngle: -.pi / 4))
        square.apply(CGAffineTransform(translationX: centre.x, y: centre.y))
        return square
    }

    /// From the top of the round part to the tip.
    static func height(for size: CGFloat) -> CGFloat {
        size / 2 + size * 0.5.squareRoot()
    }
}
