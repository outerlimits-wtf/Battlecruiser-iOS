import Foundation

/// Decodes an array, skipping elements that fail, so one odd record never
/// costs the whole list.
enum LossyArray {
    static func decode<Element: Decodable, Key: CodingKey>(
        _ type: Element.Type,
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> [Element] {
        guard container.contains(key), try !container.decodeNil(forKey: key) else { return [] }
        var elements = try container.nestedUnkeyedContainer(forKey: key)
        var decoded: [Element] = []
        while !elements.isAtEnd {
            if let element = try? elements.decode(Element.self) {
                decoded.append(element)
            } else {
                _ = try elements.decode(SkippedElement.self)
            }
        }
        return decoded
    }
}
