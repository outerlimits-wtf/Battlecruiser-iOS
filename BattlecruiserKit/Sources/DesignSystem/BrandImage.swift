import SwiftUI
import UIKit

/// The app's own artwork, bundled with this module.
public enum BrandImage {
    /// The pint, as on the web's pins and menu button (decision P1).
    public static let pintLogo: UIImage = UIImage(named: "pint-logo", in: .module, with: nil) ?? UIImage()
    /// A pint of Guinness, beside the price, as on the web.
    public static let guinness: UIImage = UIImage(named: "guinness-icon", in: .module, with: nil) ?? UIImage()

    /// The Guinness, sized to sit in a line of text like an emoji.
    public static let guinnessInline: UIImage = {
        let size = CGSize(width: 9, height: 13)
        return UIGraphicsImageRenderer(size: size).image { _ in
            guinness.draw(in: CGRect(origin: .zero, size: size))
        }
    }()
}
