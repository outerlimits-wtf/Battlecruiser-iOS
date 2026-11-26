import MapKit
import UIKit
import DesignSystem
import PubDBModels

/// A full pin: the teardrop in the state's colour with the pint logo, sized
/// and faded by how loud the state is. The selected pub's pin is larger and on top.
final class PinAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "pin"
    static let selectedSize: CGFloat = 38

    private let drop = CAShapeLayer()
    private let logo = CALayer()
    private let pulse = CAShapeLayer()
    private(set) var showsAsSelected = false

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        layer.addSublayer(pulse)
        layer.addSublayer(drop)
        layer.addSublayer(logo)
        logo.contents = BrandImage.pintLogo.cgImage
        logo.contentsGravity = .resizeAspect
        drop.lineWidth = 2
        drop.shadowColor = UIColor.black.cgColor
        drop.shadowOpacity = 0.25
        drop.shadowRadius = 2
        drop.shadowOffset = CGSize(width: 0, height: 1)
        pulse.fillColor = nil
        pulse.lineWidth = 3
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used from storyboards") }

    func configure(_ pin: Pin, isSelected: Bool, reduceMotion: Bool) {
        let state = PinState(rawValue: pin.state) ?? .unknown
        let size = isSelected ? Self.selectedSize : state.pinSize
        let height = TeardropShape.height(for: size)
        let wasSelected = showsAsSelected
        showsAsSelected = isSelected

        frame.size = CGSize(width: size, height: height + 2)
        // Put the tip on the pub.
        centerOffset = CGPoint(x: 0, y: -height / 2)
        zPriority = isSelected ? .max : MKAnnotationViewZPriority(rawValue: Float(state.rank) * 100)
        displayPriority = .required
        alpha = isSelected ? 1 : state.pinOpacity

        let traits = traitCollection
        drop.path = TeardropShape.path(size: size).cgPath
        drop.fillColor = state.uiColor.resolvedColor(with: traits).cgColor
        drop.strokeColor = UIColor(Palette.surface).resolvedColor(with: traits).cgColor
        let logoSide = size * 0.5
        logo.frame = CGRect(x: (size - logoSide) / 2, y: (size - logoSide) / 2, width: logoSide, height: logoSide)

        accessibilityLabel = [pin.name, pin.area, pin.label].compactMap { $0 }.joined(separator: ", ")
        accessibilityHint = "Shows this pub"

        updatePulse(on: state == .closing && !isSelected && !reduceMotion, size: size)
        if isSelected, !wasSelected, !reduceMotion {
            pop()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        showsAsSelected = false
        pulse.removeAllAnimations()
        layer.removeAllAnimations()
    }

    /// Closing soon: a ring that grows and fades. Transform and opacity only.
    private func updatePulse(on: Bool, size: CGFloat) {
        guard on else {
            pulse.removeAllAnimations()
            pulse.isHidden = true
            return
        }
        pulse.isHidden = false
        pulse.frame = CGRect(x: 0, y: 0, width: size, height: size)
        pulse.path = UIBezierPath(ovalIn: pulse.bounds).cgPath
        pulse.strokeColor = PinState.closing.uiColor.withAlphaComponent(0.45).cgColor
        guard pulse.animation(forKey: "pulse") == nil else { return }
        let grow = CABasicAnimation(keyPath: "transform.scale")
        grow.fromValue = 0.85
        grow.toValue = 1.6
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        let group = CAAnimationGroup()
        group.animations = [grow, fade]
        group.duration = 1.9
        group.repeatCount = .infinity
        pulse.add(group, forKey: "pulse")
    }

    /// The web's "pop" when a pin is selected.
    private func pop() {
        let bounce = CAKeyframeAnimation(keyPath: "transform.scale")
        bounce.values = [0.5, 1.18, 1]
        bounce.keyTimes = [0, 0.6, 1]
        bounce.duration = 0.28
        layer.add(bounce, forKey: "pop")
    }
}
