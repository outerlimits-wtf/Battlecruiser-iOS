import Foundation

/// What someone types for a Guinness, as pence: "5.60", "£5.60", "5" → 560,
/// 500. Only for reading input; the server sends every price formatted.
enum GuinnessPrice {
    static func pence(from input: String) -> Int? {
        let cleaned = input.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let pounds = Decimal(string: cleaned), pounds > 0 else { return nil }
        return NSDecimalNumber(decimal: pounds * 100).rounding(accordingToBehavior: nil).intValue
    }

    /// The web's refusal, with the bounds `/meta` gives.
    static func outOfRange(_ input: String, min: Int, max: Int) -> String {
        "£\(input.replacingOccurrences(of: "£", with: "")) does not look right for a pint. Somewhere between \(pounds(min)) and \(pounds(max))?"
    }

    private static func pounds(_ pence: Int) -> String {
        String(format: "£%d.%02d", pence / 100, pence % 100)
    }
}
