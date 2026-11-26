import Foundation

/// The choices the rating and Guinness filters offer, as the web hard-codes
/// them in `Filters.tsx`. To come from `/meta` once the server sends them
/// (server ask S8); then this table goes.
enum FilterOptions {
    /// Low ones too: the worst-rated pubs are half the fun.
    static let ratingSteps = Array(1...9)

    static let guinnessSteps: [(pence: Int, label: String)] = [
        (500, "£5.00"), (550, "£5.50"), (600, "£6.00"), (650, "£6.50"), (700, "£7.00"),
    ]

    static func guinnessLabel(for pence: Int) -> String? {
        guinnessSteps.first { $0.pence == pence }?.label
    }
}
