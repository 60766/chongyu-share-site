import Foundation
import Security

class AppAccountManager {
    static let shared = AppAccountManager()
    private init() {}
    
    private let serviceIdentifier = "com.虫遇.appaccount"
    private let accountKey = "app_account_token"
    
    var appAccountToken: String {
        #if DEBUG
        // 使用固定测试令牌，确保与本地后端的测试一致
        return "test-token"
        #endif
        if let existing = retrieveTokenFromKeychain() {
            return existing
        }
        let newToken = UUID().uuidString
        saveTokenToKeychain(newToken)
        return newToken
    }
    
    private func saveTokenToKeychain(_ token: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let tokenData = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func retrieveTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
} 