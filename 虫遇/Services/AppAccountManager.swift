import Foundation
import Security
import SwiftUI

class AppAccountManager: ObservableObject {
    static let shared = AppAccountManager()
    private init() {}
    
    private let serviceIdentifier = "com.虫遇.appaccount"
    private let accountKey = "app_account_token"
    private let accountCreationKey = "account_creation_date"
    
    var appAccountToken: String {
        if let existing = retrieveTokenFromKeychain() {
            return existing
        }
        if let override = ProcessInfo.processInfo.environment["TEST_APP_ACCOUNT_TOKEN"], !override.isEmpty {
            saveTokenToKeychain(override)
            saveAccountCreationDate()
            return override
        }
        let newToken = UUID().uuidString
        saveTokenToKeychain(newToken)
        // 记录账号创建时间
        saveAccountCreationDate()
        return newToken
    }
    
    // MARK: - 账号信息
    
    /// 获取账号显示标识（优先使用真实的 Apple ID 邮箱，否则显示 token 前8位+后4位）
    @MainActor
    var accountDisplayIdentifier: String {
        // 优先使用真实的 Apple ID 邮箱（用于显示）
        if let appleIDEmail = AppleSignInManager.shared.userAppleIDEmail, !appleIDEmail.isEmpty {
            return appleIDEmail
        }
        // 否则显示 appAccountToken 的前8位 + 后4位
        let token = appAccountToken
        let prefix = String(token.prefix(8))
        let suffix = String(token.suffix(4))
        return "\(prefix)...\(suffix)"
    }
    
    /// 获取完整的账号标识（用于复制）
    @MainActor
    var fullAccountIdentifier: String {
        // 优先使用真实的 Apple ID 邮箱（用于显示）
        if let appleIDEmail = AppleSignInManager.shared.userAppleIDEmail, !appleIDEmail.isEmpty {
            return appleIDEmail
        }
        // 否则返回完整的 appAccountToken
        return appAccountToken
    }
    
    /// 获取账号显示ID（数字格式）- 已废弃，保留用于兼容
    @available(*, deprecated, message: "使用 accountDisplayIdentifier 替代")
    var accountDisplayId: String {
        let token = appAccountToken
        
        // 使用稳定的哈希算法，确保相同token每次都生成相同ID
        let stableHash = token.stableHashValue
        let unsigned = UInt64(bitPattern: Int64(stableHash))
        let accountNumber = Int(unsigned % 1_000_000_000)
        
        // 格式化为易读的数字格式
        let numberString = String(accountNumber).padded(to: 9, with: "0")
        return "\(numberString.prefix(3)) \(numberString.dropFirst(3).prefix(3)) \(numberString.suffix(3))"
    }
    
    /// 获取账号创建时间
    var accountCreationDate: Date {
        if let date = UserDefaults.standard.object(forKey: accountCreationKey) as? Date {
            return date
        }
        // 如果没有记录，使用当前时间并保存
        let now = Date()
        UserDefaults.standard.set(now, forKey: accountCreationKey)
        return now
    }
    
    /// 检查是否为新账号（创建不到24小时）
    var isNewAccount: Bool {
        let creationTime = accountCreationDate
        let hoursSinceCreation = Date().timeIntervalSince(creationTime) / 3600
        return hoursSinceCreation < 24
    }
    
    // MARK: - 账号找回
    
    /// 通过 token 找回账号
    func restoreAccountWithToken(_ token: String, completion: @escaping (Result<String, TokenRestoreError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let cleanedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 验证 token 格式（仅支持完整 UUID）
            // UUID 格式：xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36字符)
            guard cleanedToken.count == 36, cleanedToken.contains("-") else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidFormat))
                }
                return
            }
            
            // 尝试从后端恢复
            self.restoreFromBackendByToken(token: cleanedToken) { backendToken, isNetworkError in
                if let serverToken = backendToken {
                    // 使用服务端令牌恢复
                    self.saveTokenToKeychain(serverToken)
                    self.saveAccountCreationDate()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .userAccountRestored,
                            object: nil,
                            userInfo: ["token": serverToken, "restoreSource": "server"]
                        )
                        completion(.success(serverToken))
                        #if DEBUG
                        print("💰 账号找回成功(命中云端): \(String(serverToken.prefix(8)))...")
                        #endif
                    }
                    return
                }
                
                // 网络错误
                if isNetworkError {
                    DispatchQueue.main.async {
                        completion(.failure(.networkError))
                    }
                    return
                }
                
                // 服务端未找到
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
    
    // MARK: - 账号管理
    
    /// 退出登录（清除当前账号数据）
    func logout(completion: @escaping (Bool) -> Void) {
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            var success = true
            
            // 1. 清除钥匙串中的令牌
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: self.serviceIdentifier,
                kSecAttrAccount as String: self.accountKey,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
            ]
            let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
            if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
                print("❌ 清除钥匙串失败: \(deleteStatus)")
                success = false
            } else {
                print("✅ 已清除钥匙串数据")
            }
            
            // 2. 清除账号创建时间
            UserDefaults.standard.removeObject(forKey: self.accountCreationKey)
            
            // 4. 通知其他组件清除用户数据
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .userAccountLogout,
                    object: nil
                )
                
                completion(success)
                print("🔐 退出登录完成")
            }
        }
    }
    
    /// 重置为新账号（生成新令牌）
    func createNewAccount(completion: @escaping (String) -> Void) {
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 清除旧令牌
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: self.serviceIdentifier,
                kSecAttrAccount as String: self.accountKey,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            // 生成新令牌
            let newToken = UUID().uuidString
            self.saveTokenToKeychain(newToken)
            self.saveAccountCreationDate()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .userAccountCreated,
                    object: nil,
                    userInfo: ["token": newToken]
                )
                
                completion(newToken)
                print("🆕 新账号创建完成: \(String(newToken.prefix(8)))...")
            }
        }
    }
    
    /// 用服务端返回的 token 替换本地账号
    func replaceLocalAccountToken(_ newToken: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.saveTokenToKeychain(newToken)
            if UserDefaults.standard.object(forKey: self.accountCreationKey) == nil {
                self.saveAccountCreationDate()
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .userAccountTokenReplaced,
                    object: nil,
                    userInfo: ["token": newToken]
                )
                #if DEBUG
                print("🔁 本地账号已替换为服务端账号: \(String(newToken.prefix(8)))...")
                #endif
            }
        }
    }
    
    /// 获取账号统计信息
    @MainActor
    func getAccountStats() -> [String: Any] {
        return [
            "accountIdentifier": accountDisplayIdentifier,
            "creationDate": accountCreationDate,
            "isNewAccount": isNewAccount,
            "daysSinceCreation": Int(Date().timeIntervalSince(accountCreationDate) / 86400)
        ]
    }
    
    // MARK: - 私有方法
    
    private func saveTokenToKeychain(_ token: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountKey,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let tokenData = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String: true // 启用 iCloud 同步
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func retrieveTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny // 支持从 iCloud 同步获取
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func saveAccountCreationDate() {
        UserDefaults.standard.set(Date(), forKey: accountCreationKey)
    }
    
    private func backendBaseURL() -> URL? {
        return BackendURLProvider.resolvedURL()
    }
    
    /// 通过 token 从后端恢复账号
    private func restoreFromBackendByToken(token: String, attemptsRemaining: Int = 2, completion: @escaping (String?, Bool) -> Void) {
        guard let base = backendBaseURL() else { completion(nil, true); return }
        var req = URLRequest(url: base.appendingPathComponent("/account/restore-by-token"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["appAccountToken": token]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        // Use longer timeouts for restore operations
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        session.dataTask(with: req) { data, response, error in
            if let _ = error {
                if attemptsRemaining > 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                        self.restoreFromBackendByToken(token: token, attemptsRemaining: attemptsRemaining - 1, completion: completion)
                    }
                } else {
                    completion(nil, true)
                }
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 200, let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["appAccountToken"] as? String {
                completion(token, false)
            } else if let http = response as? HTTPURLResponse, http.statusCode >= 500 {
                if attemptsRemaining > 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                        self.restoreFromBackendByToken(token: token, attemptsRemaining: attemptsRemaining - 1, completion: completion)
                    }
                } else {
                    completion(nil, true)
                }
            } else {
                completion(nil, false)
            }
        }.resume()
    }
}

// MARK: - Token 找回错误类型
enum TokenRestoreError: LocalizedError {
    case invalidFormat
    case networkError
    case notFound
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "账号标识格式不正确。请输入完整的 UUID 或简化格式（前8位...后4位）。"
        case .networkError:
            return "网络连接失败，请稍后再试。"
        case .notFound:
            return "未找到该账号。请确认账号标识是否正确。"
        case .unknown:
            return "未知错误，请稍后再试。"
        }
    }
}

// MARK: - 通知扩展
extension Notification.Name {
    static let userAccountLogout = Notification.Name("userAccountLogout")
    static let userAccountCreated = Notification.Name("userAccountCreated")
    static let userAccountRestored = Notification.Name("userAccountRestored")
    static let userAccountTokenReplaced = Notification.Name("userAccountTokenReplaced")
}

// MARK: - String 扩展
extension String {
    func padded(to length: Int, with character: String) -> String {
        let paddingLength = max(0, length - self.count)
        return String(repeating: character, count: paddingLength) + self
    }
} 