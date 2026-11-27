import Foundation
import Security

/// Tokens in the Keychain, readable only on this device after first unlock.
public struct KeychainTokenStore: TokenStore {
    private let service: String
    private let account = "workos-tokens"

    public init(service: String = "wtf.outerlimits.battlecruiser.auth") {
        self.service = service
    }

    public func load() -> Tokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(Tokens.self, from: data)
    }

    public func save(_ tokens: Tokens?) {
        SecItemDelete(baseQuery as CFDictionary)
        guard let tokens, let data = try? JSONEncoder().encode(tokens) else { return }
        var item = baseQuery
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
