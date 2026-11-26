import SwiftUI
import UIKit

/// The map's pin states (`/pins` `properties.pin`) and how loud each is drawn
/// (spec, "Building a map"). Open is loud, closed is quiet, at every zoom.
public enum PinState: String, CaseIterable, Sendable {
    case open, closing, unknown, closed, paused, gone

    /// The fill, light and dark.
    public var color: Color {
        Color(uiColor: uiColor)
    }

    /// For renderers that draw with Core Graphics.
    public var uiColor: UIColor {
        UIColor { traits in
            let dark = traits.userInterfaceStyle == .dark
            return switch self {
            case .open: UIColor(hex: dark ? 0x37C66A : 0x1E8E3E)
            case .closing: UIColor(hex: dark ? 0xFF9F4A : 0xE8710A)
            case .unknown: UIColor(hex: dark ? 0xE8B13F : 0xD1972F)
            case .closed: UIColor(hex: dark ? 0x6B7178 : 0xA9ADB2)
            case .paused: UIColor(hex: dark ? 0x7D7365 : 0x9A8F80)
            case .gone: UIColor(hex: dark ? 0x6E655B : 0x8A7F72)
            }
        }
    }

    /// Zoomed-out dot radius, in points.
    public var dotRadius: CGFloat {
        switch self {
        case .open: 6
        case .closing: 5.5
        case .unknown: 3.5
        case .closed: 2.75
        case .paused: 2.5
        case .gone: 2
        }
    }

    public var dotOpacity: CGFloat {
        switch self {
        case .open, .closing: 1
        case .unknown: 0.85
        case .closed: 0.6
        case .paused: 0.5
        case .gone: 0.4
        }
    }

    /// Only the loud states get an outline in the surface colour.
    public var hasOutline: Bool {
        self == .open || self == .closing
    }

    /// Zoomed-in teardrop size, in points.
    public var pinSize: CGFloat {
        switch self {
        case .open: 32
        case .closing: 29
        case .unknown: 26
        case .closed: 21
        case .paused: 20
        case .gone: 18
        }
    }

    public var pinOpacity: CGFloat {
        switch self {
        case .open, .closing: 1
        case .unknown: 0.9
        case .closed: 0.6
        case .paused: 0.55
        case .gone: 0.45
        }
    }

    /// Quietest first, as the server orders pins: later ones draw on top.
    public var rank: Int {
        switch self {
        case .gone: 0
        case .paused: 1
        case .closed: 2
        case .unknown: 3
        case .closing: 4
        case .open: 5
        }
    }
}
