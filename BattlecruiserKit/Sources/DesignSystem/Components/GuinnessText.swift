import SwiftUI

/// A Guinness price as the web draws it: the pint, then the server's
/// formatted price. VoiceOver hears "Guinness £6.20".
public enum GuinnessText {
    public static func text(_ formatted: String) -> Text {
        Text(Image(uiImage: BrandImage.guinnessInline)).accessibilityLabel("Guinness") + Text(" " + formatted)
    }
}
