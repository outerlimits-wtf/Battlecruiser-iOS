import Foundation

/// A field's current value on one pub, for prefilling its editor (S4).
/// `value` is in the form the field's contribution takes ("620", "pub",
/// "closed | 2019 | flats"); `display` is the same ready to show ("£6.20").
/// Both are nil when nothing is known, and always for report fields such as
/// `last_orders`, where there is only something to add.
public struct EditableValue: Decodable, Hashable, Sendable {
    public let value: String?
    public let display: String?

    public init(value: String?, display: String?) {
        self.value = value
        self.display = display
    }
}
