import Foundation
import Security
import SwiftUI

class AppAccountManager: ObservableObject {
    static let shared = AppAccountManager()
    private init() {}
    
    /// 用于触发UI更新的版本号
    @Published private var backupCodeVersion = 0
    
    /// 内存缓存的备份码（确保立即更新）
    private var cachedBackupCode: String?
    
    private let serviceIdentifier = "com.虫遇.appaccount"
    private let accountKey = "app_account_token"
    private let accountCreationKey = "account_creation_date"
    private let backupCodeKey = "backup_code"
    
    var appAccountToken: String {
        if let existing = retrieveTokenFromKeychain() {
            return existing
        }
        if let override = ProcessInfo.processInfo.environment["TEST_APP_ACCOUNT_TOKEN"], !override.isEmpty {
            saveTokenToKeychain(override)
            saveAccountCreationDate()
            generateBackupCode()
            return override
        }
        let newToken = UUID().uuidString
        saveTokenToKeychain(newToken)
        // 记录账号创建时间
        saveAccountCreationDate()
        // 生成备份码
        generateBackupCode()
        return newToken
    }
    
    // MARK: - 账号信息
    
    /// 获取账号显示ID（数字格式）
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
    
    // MARK: - 找回码管理
    
    /// 获取当前备份码
    var currentBackupCode: String? {
        // 使用backupCodeVersion确保SwiftUI检测到变化
        _ = backupCodeVersion
        
        // 优先返回缓存的值，然后从钥匙串读取
        if let cached = cachedBackupCode {
            return cached
        }
        
        let keychainValue = retrieveBackupCodeFromKeychain()
        cachedBackupCode = keychainValue
        return keychainValue
    }
    
    /// 检查当前备份码是否为旧格式
    var needsBackupCodeUpgrade: Bool {
        guard let backupCode = currentBackupCode else { return false }
        return !isDigitalFormat(backupCode)
    }
    
    /// 检查备份码是否为数字格式
    private func isDigitalFormat(_ backupCode: String) -> Bool {
        let components = backupCode.components(separatedBy: "-")
        guard components.count == 4 else { return false }
        return components.allSatisfy { component in
            component.count == 3 && component.allSatisfy { $0.isNumber }
        }
    }
    
    /// 生成新的找回码
    @discardableResult
    func generateBackupCode() -> String {
        // 中国用户友好的找回码：使用数字组合，更容易记忆
        let segments = (0..<4).map { _ in 
            String(format: "%03d", Int.random(in: 100...999))
        }
        let backupCode = segments.joined(separator: "-")
        
        // 立即更新缓存
        cachedBackupCode = backupCode
        
        // 保存到钥匙串
        saveBackupCodeToKeychain(backupCode)
        
        // 通知界面更新
        DispatchQueue.main.async {
            self.backupCodeVersion += 1
        }
        
        // 尝试向后端注册备份码（忽略失败）
        registerBackupCodeToBackend(backupCode: backupCode, appAccountToken: appAccountToken)
        
        return backupCode
    }
    
    /// 验证备份码并恢复账号
    func restoreAccountWithBackupCode(_ backupCode: String, completion: @escaping (Result<RestoreOutcome, BackupCodeError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let cleanedBackupCode = backupCode.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 验证备份码格式（支持新格式：XXX-XXX-XXX-XXX 和旧格式：word-word-word-word）
            let components = cleanedBackupCode.components(separatedBy: "-")
            guard components.count == 4 else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidFormat))
                }
                return
            }
            
            // 检查是否为新格式（数字）或旧格式（单词）
            let isDigitalFormat = components.allSatisfy { component in
                component.count == 3 && component.allSatisfy { $0.isNumber }
            }
            
            let isWordFormat = components.allSatisfy { component in
                component.count > 0 && component.allSatisfy { $0.isLetter }
            }
            
            guard isDigitalFormat || isWordFormat else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidFormat))
                }
                return
            }
            
            // 先尝试从后端恢复
            self.restoreFromBackend(backupCode: cleanedBackupCode) { backendToken, isNetworkError in
                if let serverToken = backendToken {
                    // 使用服务端令牌恢复（保持当前找回码不变）
                    self.saveTokenToKeychain(serverToken)
                    self.saveAccountCreationDate()
                    self.cachedBackupCode = cleanedBackupCode
                    self.saveBackupCodeToKeychain(cleanedBackupCode)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .userAccountRestored,
                            object: nil,
                            userInfo: ["token": serverToken, "backupCode": cleanedBackupCode, "restoreSource": "server"]
                        )
                        completion(.success(.serverHit(token: serverToken)))
                        #if DEBUG
                        print("💰 余额找回成功(命中云端): \(String(serverToken.prefix(8)))...")
                        #endif
                    }
                    return
                }
                
                // 网络错误：直接反馈给调用方，不进行本地推导
                if isNetworkError {
                    DispatchQueue.main.async {
                        completion(.failure(.networkError))
                    }
                    return
                }
                
                // 服务端未找到：仅返回本地占位建议，不替换当前账号，交由 UI 二次确认
                let tokenData = cleanedBackupCode.data(using: .utf8)!
                let tokenHash = tokenData.base64EncodedString()
                let derivedToken = "backup-\(tokenHash.prefix(32))"
                DispatchQueue.main.async {
                    completion(.success(.localDerived(token: derivedToken)))
                    #if DEBUG
                    print("ℹ️ 未找回余额(建议本地占位，未切换): \(String(derivedToken.prefix(8)))...")
                    #endif
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
            
            // 2. 清除备份码
            self.clearBackupCodeFromKeychain()
            
            // 3. 清除账号创建时间
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
            
            // 清除旧备份码
            self.clearBackupCodeFromKeychain()
            
            // 生成新令牌
            let newToken = UUID().uuidString
            self.saveTokenToKeychain(newToken)
            self.saveAccountCreationDate()
            
            // 生成新备份码
            let newBackupCode = self.generateBackupCode()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .userAccountCreated,
                    object: nil,
                    userInfo: ["token": newToken, "backupCode": newBackupCode]
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
            let newBackupCode = self.generateBackupCode()
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .userAccountTokenReplaced,
                    object: nil,
                    userInfo: ["token": newToken, "backupCode": newBackupCode]
                )
                #if DEBUG
                print("🔁 本地账号已替换为服务端账号: \(String(newToken.prefix(8)))...")
                #endif
            }
        }
    }
    
    /// 采用本地占位恢复（经用户确认后调用）
    func adoptLocalDerivedAccount(token: String, backupCode: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let cleaned = backupCode.trimmingCharacters(in: .whitespacesAndNewlines)
            self.saveTokenToKeychain(token)
            self.saveAccountCreationDate()
            self.cachedBackupCode = cleaned
            self.saveBackupCodeToKeychain(cleaned)
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .userAccountRestored,
                    object: nil,
                    userInfo: ["token": token, "backupCode": cleaned, "restoreSource": "local"]
                )
                #if DEBUG
                print("📝 已采用本地占位账号: \(String(token.prefix(8)))...")
                #endif
            }
        }
    }
    
    /// 获取账号统计信息
    func getAccountStats() -> [String: Any] {
        return [
            "accountId": accountDisplayId,
            "creationDate": accountCreationDate,
            "isNewAccount": isNewAccount,
            "daysSinceCreation": Int(Date().timeIntervalSince(accountCreationDate) / 86400),
            "hasBackupCode": currentBackupCode != nil
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
    
    private func saveBackupCodeToKeychain(_ backupCode: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: backupCodeKey,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let codeData = Data(backupCode.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: backupCodeKey,
            kSecValueData as String: codeData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String: true // 备份码也支持 iCloud 同步
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func retrieveBackupCodeFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: backupCodeKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func clearBackupCodeFromKeychain() {
        // 清除缓存
        cachedBackupCode = nil
        
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: backupCodeKey,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // 通知界面更新
        DispatchQueue.main.async {
            self.backupCodeVersion += 1
        }
    }
    
    private func saveAccountCreationDate() {
        UserDefaults.standard.set(Date(), forKey: accountCreationKey)
    }
    
    private func backendBaseURL() -> URL? {
        // 优先级：环境变量 -> Info.plist -> 用户默认
        let candidates: [String?] = [
            ProcessInfo.processInfo.environment["BACKEND_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
            UserDefaults.standard.string(forKey: "BackendBaseURL")
        ]
        for candidate in candidates {
            if let raw = candidate, let url = URL(string: raw) {
                #if DEBUG
            return url
                #else
                if url.scheme?.lowercased() == "https" { return url }
                #endif
        }
        }
        #if DEBUG
        // 临时测试生产环境后端
        // return URL(string: "http://121.40.184.29:3000")
        return URL(string: "http://127.0.0.1:8787")
        #else
        return URL(string: "http://121.40.184.29:3000")
        #endif
    }
    
    private func registerBackupCodeToBackend(backupCode: String, appAccountToken: String) {
        guard let base = backendBaseURL() else { return }
        var req = URLRequest(url: base.appendingPathComponent("/account/register-backup"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10
        let body: [String: Any] = [
            "backupCode": backupCode,
            "appAccountToken": appAccountToken
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        func fire(attemptsRemaining: Int) {
            // Use longer timeouts for backup operations
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 300
            config.timeoutIntervalForResource = 300
            let session = URLSession(configuration: config)
            session.dataTask(with: req) { _, response, error in
                if let _ = error {
                    if attemptsRemaining > 0 {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                            fire(attemptsRemaining: attemptsRemaining - 1)
                        }
                    }
                    return
                }
                if let http = response as? HTTPURLResponse, http.statusCode >= 500, attemptsRemaining > 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                        fire(attemptsRemaining: attemptsRemaining - 1)
                    }
                }
            }.resume()
        }
        fire(attemptsRemaining: 1)
    }
    
    private func restoreFromBackend(backupCode: String, attemptsRemaining: Int = 2, completion: @escaping (String?, Bool) -> Void) {
        guard let base = backendBaseURL() else { completion(nil, true); return }
        var req = URLRequest(url: base.appendingPathComponent("/account/restore-by-backup"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["backupCode": backupCode]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        // Use longer timeouts for backup operations
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        session.dataTask(with: req) { data, response, error in
            if let _ = error {
                if attemptsRemaining > 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                        self.restoreFromBackend(backupCode: backupCode, attemptsRemaining: attemptsRemaining - 1, completion: completion)
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
                        self.restoreFromBackend(backupCode: backupCode, attemptsRemaining: attemptsRemaining - 1, completion: completion)
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

// MARK: - 备份码错误类型
enum BackupCodeError: LocalizedError {
    case invalidFormat
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "找回码格式不正确。请确保输入4组3位数字，用短横线连接（如：123-456-789-012）。"
        case .networkError:
            return "网络连接失败，请稍后再试。"
        case .unknown:
            return "未知错误，请稍后再试。"
        }
    }
}

// MARK: - 恢复结果类型
enum RestoreOutcome {
    case serverHit(token: String) // 命中云端映射：余额可找回
    case localDerived(token: String) // 本地占位账号：未找回余额
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