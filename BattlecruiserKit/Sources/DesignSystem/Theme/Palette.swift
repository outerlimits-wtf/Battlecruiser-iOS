import SwiftUI

/// The web client's colour tokens (`../pubdb/src/index.css`), light and dark.
/// Use these rather than system colours so the app and the web look like one thing.
public enum Palette {
    /// Body text.
    public static let ink = Color(light: 0x202124, dark: 0xE8EAED)
    public static let inkMuted = Color(light: 0x5F6368, dark: 0x9AA0A6)
    public static let inkFaint = Color(light: 0x80868B, dark: 0x7B8085)
    /// Behind everything.
    public static let canvas = Color(light: 0xF8F9FA, dark: 0x101317)
    /// Cards, sheets, pills.
    public static let surface = Color(light: 0xFFFFFF, dark: 0x1B1F24)
    /// Inset blocks, hairlines, placeholders.
    public static let surfaceSunken = Color(light: 0xF1F3F4, dark: 0x272C32)

    /// The brand colour: links, prices, the selected row.
    public static let beer = Color(light: 0xB45309, dark: 0xE8A54A)
    /// Focus rings and the rating star.
    public static let beerBright = Color(light: 0xF59E0B, dark: 0xF59E0B)
    public static let beerSoft = Color(light: 0xFEF3C7, dark: 0x3D2D12)

    public static let good = Color(light: 0x137333, dark: 0x5CC98A)
    public static let goodSoft = Color(light: 0xE6F4EA, dark: 0x15301F)
    public static let warn = Color(light: 0xA15C00, dark: 0xE0AE52)
    public static let warnSoft = Color(light: 0xFEF7E0, dark: 0x33290F)
    public static let bad = Color(light: 0xC5221F, dark: 0xF28B82)
    public static let badSoft = Color(light: 0xFCE8E6, dark: 0x3A201E)

    /// Text on an `ink`, `beer` or `good` fill.
    public static let onInk = Color(light: 0xFFFFFF, dark: 0x16191D)
    public static let onBeer = Color(light: 0xFFFFFF, dark: 0x20150A)
    public static let onGood = Color(light: 0xFFFFFF, dark: 0x07200F)

    /// Behind photos, and the text on them.
    public static let photoBackdrop = Color(light: 0x2B2E33, dark: 0x2B2E33)
    public static let onPhoto = Color.white
}
