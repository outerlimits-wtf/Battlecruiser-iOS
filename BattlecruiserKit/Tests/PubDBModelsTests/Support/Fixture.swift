import Foundation

/// Loads the production responses in `Fixtures/` (see docs/test-fixtures.md),
/// which Package.swift copies into this test target's resource bundle.
enum Fixture {
    enum LoadError: Error, CustomStringConvertible {
        case missing(String)

        var description: String {
            switch self {
            case .missing(let name): "No fixture named Fixtures/\(name).json in the test bundle"
            }
        }
    }

    static func data(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw LoadError.missing(name)
        }
        return try Data(contentsOf: url)
    }

    static func decode<T: Decodable>(_ type: T.Type, from name: String) throws -> T {
        try JSONDecoder().decode(type, from: data(name))
    }
}
