import Foundation

extension PubDBError {
    /// The `PubDBError` to show for anything a client call threw, or nil for a
    /// cancellation, which is never shown: the caller was superseded.
    public static func wrapping(_ error: any Error) -> PubDBError? {
        switch error {
        case is CancellationError:
            nil
        case let error as PubDBError:
            error
        case let error as URLError where error.code == .cancelled:
            nil
        case let error as URLError:
            .transport(error)
        default:
            .transport(URLError(.unknown))
        }
    }
}
