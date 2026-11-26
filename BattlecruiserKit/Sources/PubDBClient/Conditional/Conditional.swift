import Foundation

/// The answer to a conditional request: a new value, or "same as last time".
public enum Conditional<Value: Sendable>: Sendable {
    /// The server sent a new body.
    case changed(Value)
    /// `304 Not Modified`. Nothing on screen should change at all.
    case unchanged
}

extension Conditional: Equatable where Value: Equatable {}
