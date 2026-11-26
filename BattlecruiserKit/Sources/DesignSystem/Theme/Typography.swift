import SwiftUI

/// The web's type scale, mapped onto Dynamic Type text styles so it still scales.
public enum Typography {
    /// A pub's name at the top of its panel (web 24 bold).
    public static let title = Font.title2.bold()
    /// The operator after a pub's name in its panel: a touch under the title.
    public static let subtitle = Font.title3
    /// A row's name (web 16 semibold).
    public static let rowTitle = Font.body.weight(.semibold)
    /// Body text (web 14).
    public static let body = Font.subheadline
    /// Secondary lines (web 12).
    public static let secondary = Font.caption
    /// Credits and fine print (web 11).
    public static let micro = Font.caption2
    /// Pills and chips (web 13 medium).
    public static let pill = Font.footnote.weight(.medium)
    /// The small-caps section headings (web 11 semibold, tracked, uppercase).
    public static let sectionHeader = Font.caption2.weight(.semibold)
}
