import Foundation

/// **Temporary, until server ask S24:** the app calls a pub's company its
/// operator, but `/meta` still labels the `brand` field (and `previous_name`'s
/// `owner` part) "Owner". Only that exact old label is swapped, so once the
/// server sends its own new label this does nothing and can be deleted.
enum OperatorLabel {
    static let old = "Owner"
    static let new = "Operator"

    static func label(_ label: String, forKey key: String, keys: Set<String>) -> String {
        keys.contains(key) && label == old ? new : label
    }
}
