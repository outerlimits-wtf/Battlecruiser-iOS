import SwiftUI

/// Spacing and corner radii from the web client's layout.
public enum Metrics {
    /// 4, 8, 12, 16, 24: the only gaps used.
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24

    /// Inputs.
    public static let inputRadius: CGFloat = 12
    /// Cards and inset blocks.
    public static let cardRadius: CGFloat = 16
    /// The sheet's top corners.
    public static let sheetRadius: CGFloat = 24
    /// Photo thumbnails in rows.
    public static let thumbRadius: CGFloat = 8

    /// The smallest tap target.
    public static let minTap: CGFloat = 44
}
