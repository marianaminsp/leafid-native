//
//  KeychainTokenStore.swift
//  LeafID-native
//
//  Session access/refresh tokens are credentials — Keychain, not UserDefaults (unencrypted plist,
//  readable from an unencrypted device backup). API shape mirrors UserDefaults so call sites stay small.
//

import Foundation
import Security

enum KeychainTokenStore {
    private static var service: String {
        Bundle.main.bundleIdentifier ?? "com.marianaminafro.leafid"
    }

    static func set(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        SecItemDelete(baseQuery(forKey: key) as CFDictionary)
        var addQuery = baseQuery(forKey: key)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func string(forKey key: String) -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func removeObject(forKey key: String) {
        SecItemDelete(baseQuery(forKey: key) as CFDictionary)
    }

    private static func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
