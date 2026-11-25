import SwiftUI
import UIKit

/// The app's own artwork, bundled with this module.
public enum BrandImage {
    /// The pint, as on the web's pins and menu button (decision P1).
    public static let pintLogo: UIImage = UIImage(named: "pint-logo", in: .module, with: nil) ?? UIImage()
}
