import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class AppleSignInManager: NSObject, ObservableObject {
    static let shared = AppleSignInManager()
    
    @Published var isSignedIn = false
    @Published var userDisplayName: String?
    @Published var userAppleID: String?  // UUID 格式的 userID
    @Published var userAppleIDEmail: String?  // 真实的 Apple ID 邮箱（用于显示）
    
    // 账号冲突状态
    @Published var accountConflict: AccountConflict?
    
    struct AccountConflict {
        let existingToken: String  // 已绑定的旧账号 token
        let currentToken: String   // 当前新账号 token
        let existingBalance: Int?  // 旧账号余额，nil 表示未知
        let currentBalance: Int?   // 当前账号余额，nil 表示未知
    }
    
    private let serviceIdentifier = "com.虫遇.applesignin"
    private let appleIDKey = "apple_user_id"
    private let displayNameKey = "apple_display_name"
    private let profileStorage = AppleProfileStorage.shared
    
    override init() {
        super.init()
        checkAppleSignInStatus()
    }
    
    // MARK: - 检查Apple ID登录状态
    
    func checkAppleSignInStatus() {
        guard let appleID = retrieveAppleID() else {
            isSignedIn = false
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: appleID) { [weak self] state, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print("🍎 getCredentialState error: \(error)")
                    #endif
                }
                switch state {
                case .authorized:
                    self?.isSignedIn = true
                    self?.userAppleID = appleID
                    self?.userDisplayName = self?.retrieveDisplayName()
                    // 如果邮箱为空，尝试从后端恢复
                    if self?.userAppleIDEmail == nil {
                        Task {
                            await self?.restoreEmailFromBackend(appleID: appleID)
                        }
                    }
                    #if DEBUG
                    print("🍎 Apple ID 登录状态：已授权")
                    #endif
                case .revoked:
                    self?.signOut()
                    #if DEBUG
                    print("🍎 Apple ID 登录状态：已撤销")
                    #endif
                case .notFound:
                    self?.signOut()
                    #if DEBUG
                    print("🍎 Apple ID 登录状态：未找到")
                    #endif
                default:
                    // 未知时进行一次 silent request 以尝试恢复
                    self?.performExistingAccountSetupFlows()
                    #if DEBUG
                    print("🍎 Apple ID 登录状态：未知，尝试恢复")
                    #endif
                }
            }
        }
    }
    
    private func performExistingAccountSetupFlows() {
        let requests = [ASAuthorizationAppleIDProvider().createRequest()]
        let controller = ASAuthorizationController(authorizationRequests: requests)
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Apple ID 登录
    
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - 登出
    
    /// 退出登录：只清除本地登录状态，保留后端绑定关系（这样用户还能通过 Apple ID 找回账号）
    func signOut() {
        // 只清除本地状态，不解绑后端关系
        // 这样用户下次还能通过 Apple ID 找回账号和数据
        
        isSignedIn = false
        userDisplayName = nil
        userAppleID = nil
        userAppleIDEmail = nil
        
        // 清除本地存储的登录信息（但保留绑定关系在后端）
        clearStoredData()
        
        #if DEBUG
        print("🍎 Apple ID 退出登录成功（绑定关系保留在后端）")
        #endif
    }
    
    /// 完全解绑：解除 Apple ID 和 Token 的绑定关系（慎用，会导致无法通过 Apple ID 找回账号）
    func unlinkAppleID() {
        guard let appleID = userAppleID else {
            #if DEBUG
            print("⚠️ 没有 Apple ID，无法解绑")
            #endif
            return
        }
        
        Task {
            do {
                try await unlinkAppleIDFromBackend(appleUserId: appleID)
                // 解绑成功后，清除本地状态
                await MainActor.run {
                    self.isSignedIn = false
                    self.userDisplayName = nil
                    self.userAppleID = nil
                    self.userAppleIDEmail = nil
                    self.clearStoredData()
                }
                #if DEBUG
                print("🍎 Apple ID 解绑成功")
                #endif
            } catch {
                Logger.error("Apple ID 解绑失败", error: error, log: Logger.business)
            }
        }
    }
    
    // MARK: - 数据存储
    
    private func saveAppleIDInfo(userID: String, displayName: String?) {
        saveToKeychain(key: appleIDKey, value: userID)
        
        if let displayName = displayName {
            saveToKeychain(key: displayNameKey, value: displayName)
        }
    }
    
    private func retrieveAppleID() -> String? {
        return retrieveFromKeychain(key: appleIDKey)
    }
    
    private func retrieveDisplayName() -> String? {
        return retrieveFromKeychain(key: displayNameKey)
    }
    
    private func clearStoredData() {
        deleteFromKeychain(key: appleIDKey)
        deleteFromKeychain(key: displayNameKey)
    }
    
    // MARK: - 钥匙串操作
    
    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else {
            #if DEBUG
            Logger.error("无法将字符串转换为Data", log: Logger.business)
            #endif
            return
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 删除旧数据
        SecItemDelete(query as CFDictionary)
        
        // 添加新数据
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func retrieveFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - 诊断功能
    
    /// 诊断当前存储状态（用于调试）
    func diagnoseStorageStatus() {
        #if DEBUG
        guard let appleID = userAppleID ?? retrieveAppleID() else {
            print("🔍 [诊断] 未找到 Apple ID")
            return
        }
        
        print("🔍 [诊断] ========== Apple ID 存储状态诊断 ==========")
        print("   Apple ID: \(appleID)")
        print("   当前状态:")
        print("   - isSignedIn: \(isSignedIn)")
        print("   - userDisplayName: \(userDisplayName ?? "无")")
        print("   本地存储:")
        print("   - Keychain 显示名称: \(retrieveDisplayName() ?? "无")")
        if let cached = profileStorage.load(userID: appleID) {
            print("   - UserDefaults 缓存:")
            print("     * 显示名称: \(cached)")
        } else {
            print("   - UserDefaults 缓存: 无")
        }
        print("🔍 [诊断] ==========================================")
        #endif
    }
    
    // MARK: - 与现有账号系统集成
    // 🔒 一对一关系保证：
    // 1. 一个 Apple ID 只能绑定一个 token
    // 2. 一个 token 只能绑定一个 Apple ID
    // 3. 绑定前检查并解绑旧的绑定关系
    
    func linkWithExistingAccount() {
        guard let appleID = userAppleID else {
            #if DEBUG
            print("❌ Apple ID 为空，无法关联账号")
            #endif
            return
        }
        
        Task {
            do {
                #if DEBUG
                print("🔍 [Apple ID] 开始查找绑定的账号...")
                #endif
                if let found = try await findAccountByAppleID(appleUserId: appleID) {
                    #if DEBUG
                    print("✅ [Apple ID] 找到绑定的账号!")
                    print("🔍 [诊断] 后端返回的数据:")
                    print("   - 显示名称: \(found.displayName ?? "无")")
                    print("   - 账号Token: \(String(found.appAccountToken.prefix(8)))...")
                    #endif
                    
                    let serverToken = found.appAccountToken
                    let currentToken = AppAccountManager.shared.appAccountToken
                    if serverToken != currentToken {
                        #if DEBUG
                        print("⚠️ [Apple ID] 检测到账号切换需求!")
                        print("   已绑定的账号: \(String(serverToken.prefix(8)))...")
                        print("   当前新账号: \(String(currentToken.prefix(8)))...")
                        #endif
                        
                        async let existingBalanceTask = getAccountBalance(token: serverToken)
                        async let currentBalanceTask = getAccountBalance(token: currentToken)
                        let existingBalance = await existingBalanceTask
                        let currentBalance = await currentBalanceTask
                        
                        #if DEBUG
                        if let existingBalance {
                        print("💰 [Apple ID] 已绑定账号的余额: \(existingBalance) 虫洞币")
                        } else {
                            print("⚠️ [Apple ID] 未能获取旧账号余额")
                        }
                        if let currentBalance {
                        print("💰 [Apple ID] 当前账号的余额: \(currentBalance) 虫洞币")
                        } else {
                            print("⚠️ [Apple ID] 未能获取当前账号余额")
                        }
                        #endif
                        
                            await MainActor.run {
                                self.accountConflict = AccountConflict(
                                    existingToken: serverToken,
                                    currentToken: currentToken,
                                existingBalance: existingBalance,
                                currentBalance: currentBalance
                            )
                        }
                        #if DEBUG
                        print("💡 [Apple ID] 已触发账号冲突提示，等待用户选择处理方式")
                        #endif
                        return
                    } else {
                        #if DEBUG
                        print("✅ [Apple ID] 账号已匹配，无需切换")
                        #endif
                        // 即使 token 相同，也刷新一下余额（确保余额是最新的）
                        Task { @MainActor in
                            await WalletManager.shared.refreshBalance()
                            #if DEBUG
                            print("💰 [Apple ID] 余额刷新完成，当前余额: \(WalletManager.shared.balance)")
                            #endif
                        }
                    }
                    if let restoredName = found.displayName, !restoredName.isEmpty {
                        self.userDisplayName = restoredName
                        #if DEBUG
                        print("✅ [诊断] 从后端恢复显示名称: \(restoredName)")
                        #endif
                    }
                    // 从后端恢复真实的 Apple ID 邮箱（用于显示）
                    if let restoredEmail = found.email, !restoredEmail.isEmpty {
                        self.userAppleIDEmail = restoredEmail
                        #if DEBUG
                        print("✅ [诊断] 从后端恢复 Apple ID 邮箱: \(restoredEmail)")
                        #endif
                    }
                    saveAppleIDInfo(
                        userID: appleID,
                        displayName: self.userDisplayName
                    )
                    #if DEBUG
                    print("🔄 已切换到与 Apple ID 绑定的账号")
                    #endif
                    return
                } else {
                    #if DEBUG
                    print("⚠️ [Apple ID] 后端未找到该 Apple ID 绑定的账号")
                    print("💡 [Apple ID] 提示: 如果这是您第一次绑定 Apple ID，系统会创建新的绑定关系")
                    print("💡 [Apple ID] 如果您想找回旧账号，请使用账号标识（Token）找回功能")
                    #endif
                }
            } catch {
                #if DEBUG
                print("🔍 [诊断] 查询后端账号失败: \(error)")
                #endif
                // 未找到时继续进行绑定
            }
            do {
                guard let identityToken = latestIdentityToken else {
                    #if DEBUG
                    print("⚠️ 缺少 identityToken，无法关联 Apple ID")
                    #endif
                    return
                }
                let currentToken = AppAccountManager.shared.appAccountToken
                
                // 🔒 确保一对一关系：检查当前 token 是否已绑定其他 Apple ID
                let existingAppleID = retrieveAppleID()
                if let existingAppleID = existingAppleID, existingAppleID != appleID {
                    #if DEBUG
                    print("⚠️ [一对一检查] 检测到当前 token 已绑定其他 Apple ID!")
                    print("   已绑定的 Apple ID: \(existingAppleID)")
                    print("   新的 Apple ID: \(appleID)")
                    print("💡 [一对一检查] 先解绑旧的 Apple ID，确保一对一关系...")
                    #endif
                    
                    // 先解绑旧的 Apple ID
                    do {
                        try await unlinkAppleIDFromBackend(appleUserId: existingAppleID)
                        #if DEBUG
                        print("✅ [一对一检查] 已解绑旧的 Apple ID")
                        #endif
                    } catch {
                        #if DEBUG
                        print("⚠️ [一对一检查] 解绑旧的 Apple ID 失败: \(error)")
                        #endif
                        // 继续尝试绑定新的，让后端处理冲突
                    }
                }
                
                #if DEBUG
                print("🔗 [Apple ID] 正在绑定当前账号到 Apple ID...")
                #endif
                try await linkAppleIDToBackend(
                    appleUserId: appleID,
                    appAccountToken: currentToken,
                    displayName: userDisplayName,
                    email: userAppleIDEmail,  // 保存邮箱到后端，用于后续恢复
                    identityToken: identityToken
                )
                #if DEBUG
                print("✅ [Apple ID] Apple ID 已与虫遇账号关联: \(String(currentToken.prefix(8)))...")
                #endif
                // 绑定后刷新余额
                Task { @MainActor in
                    await WalletManager.shared.refreshBalance()
                    #if DEBUG
                    print("💰 [Apple ID] 余额刷新完成，当前余额: \(WalletManager.shared.balance)")
                    #endif
                }
            } catch {
                // 如果后端返回409并包含已存在的token，触发冲突处理
                if let nsError = error as NSError?, nsError.code == 409,
                   let existingToken = nsError.userInfo["existingToken"] as? String {
                    let currentToken = AppAccountManager.shared.appAccountToken
                    #if DEBUG
                    print("⚠️ [Apple ID] 检测到账号冲突（409错误）!")
                    print("   已绑定的账号: \(String(existingToken.prefix(8)))...")
                    print("   当前新账号: \(String(currentToken.prefix(8)))...")
                    #endif
                    
                    // 获取旧账号的余额信息
                    let existingBalance = await getAccountBalance(token: existingToken)
                    
                    // 设置冲突状态，等待用户选择
                    await MainActor.run {
                        self.accountConflict = AccountConflict(
                            existingToken: existingToken,
                            currentToken: currentToken,
                            existingBalance: existingBalance,
                            currentBalance: nil
                        )
                    }
                    #if DEBUG
                    print("💡 [Apple ID] 等待用户选择处理方式...")
                    #endif
                } else {
                    Logger.error("Apple ID 关联失败", error: error, log: Logger.business)
                }
            }
        }
    }
    
    // 暂存最近一次 Apple 授权返回的 identityToken（JWT）
    private var latestIdentityToken: String?
    
    // MARK: - 后端API调用
    
    private func linkAppleIDToBackend(
        appleUserId: String,
        appAccountToken: String,
        displayName: String?,
        email: String?,
        identityToken: String?
    ) async throws {
        let url = BackendURLProvider.resolvedURL().appendingPathComponent("account/link-apple")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appAccountToken, forHTTPHeaderField: "X-App-Account-Token")
        request.setValue(AppAccountManager.shared.deviceIdentifier, forHTTPHeaderField: "X-Device-Id")
        
        var payload: [String: Any] = [
            "appAccountToken": appAccountToken,
            "appleUserId": appleUserId,
            "displayName": displayName as Any,
            "email": email as Any  // 保存邮箱到后端，用于后续恢复
        ]
        if let identityToken = identityToken {
            payload["identityToken"] = identityToken
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // Use longer timeouts for backend API calls
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            // 如果是 409 错误，尝试解析 existingToken
            if httpResponse.statusCode == 409,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let existingToken = json["existingToken"] as? String {
                var userInfo: [String: Any] = [NSLocalizedDescriptionKey: errorMessage]
                userInfo["existingToken"] = existingToken
                throw NSError(domain: "AppleSignIn", code: httpResponse.statusCode, userInfo: userInfo)
            }
            throw NSError(domain: "AppleSignIn", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        #if DEBUG
        print("✅ Apple ID 后端关联成功")
        #endif
    }
    
    private func unlinkAppleIDFromBackend(appleUserId: String) async throws {
        let url = BackendURLProvider.resolvedURL().appendingPathComponent("account/unlink-apple")
        
        let currentToken = AppAccountManager.shared.appAccountToken
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(currentToken, forHTTPHeaderField: "X-App-Account-Token")
        request.setValue(AppAccountManager.shared.deviceIdentifier, forHTTPHeaderField: "X-Device-Id")
        
        let payload = [
            "appAccountToken": currentToken,
            "appleUserId": appleUserId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // Use longer timeouts for backend API calls
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AppleSignIn", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        #if DEBUG
        print("✅ Apple ID 后端解绑成功")
        #endif
    }
    
    /// 从后端恢复邮箱（当本地邮箱为空时）
    private func restoreEmailFromBackend(appleID: String) async {
        do {
            if let found = try await findAccountByAppleID(appleUserId: appleID) {
                if let restoredEmail = found.email, !restoredEmail.isEmpty {
                    await MainActor.run {
                        self.userAppleIDEmail = restoredEmail
                        #if DEBUG
                        print("✅ [邮箱恢复] 从后端恢复 Apple ID 邮箱: \(restoredEmail)")
                        #endif
                    }
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ [邮箱恢复] 从后端恢复邮箱失败: \(error)")
            #endif
        }
    }
    
    private func findAccountByAppleID(appleUserId: String) async throws -> (appAccountToken: String, linkedAt: Int, displayName: String?, email: String?)? {
        let url = BackendURLProvider.resolvedURL().appendingPathComponent("account/find-by-apple")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "appleUserId": appleUserId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        // Use longer timeouts for backend API calls
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return nil }
        if http.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["appAccountToken"] as? String,
               let linkedAt = json["linkedAt"] as? Int {
                return (token, linkedAt, json["displayName"] as? String, json["email"] as? String)
            }
            return nil
        }
        if http.statusCode == 404 { return nil }
        let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
        throw NSError(domain: "AppleSignIn", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
    
    // MARK: - 账号冲突处理
    
    /// 处理账号冲突：切换到旧账号（保留余额）
    func switchToExistingAccount() {
        guard let conflict = accountConflict else { return }
        
        #if DEBUG
        print("✅ [Apple ID] 用户选择切换到旧账号（保留余额）")
        #endif
        AppAccountManager.shared.replaceLocalAccountToken(conflict.existingToken)
        
        // 刷新余额
        Task { @MainActor in
            await WalletManager.shared.refreshBalance()
            #if DEBUG
            print("💰 [Apple ID] 余额刷新完成，当前余额: \(WalletManager.shared.balance)")
            #endif
        }
        
        // 清除冲突状态
        accountConflict = nil
    }
    
    /// 处理账号冲突：用新账号替换旧账号的绑定（放弃旧账号）
    func replaceExistingAccountBinding() {
        guard let conflict = accountConflict,
              let appleID = userAppleID,
              let identityToken = latestIdentityToken else {
            #if DEBUG
            print("❌ [Apple ID] 无法替换绑定：缺少必要信息")
            #endif
            return
        }
        
        #if DEBUG
        print("✅ [Apple ID] 用户选择用新账号替换旧账号的绑定")
        let existingBalanceText = conflict.existingBalance.map { "\($0) 虫洞币" } ?? "未知"
        print("⚠️ [Apple ID] 警告: 旧账号（\(String(conflict.existingToken.prefix(8)))...）将被解绑，余额: \(existingBalanceText)")
        #endif
        
        Task {
            do {
                let newToken = conflict.currentToken
                
                // 1. 先解绑旧账号（解绑当前 Apple ID 与旧 token 的绑定）
                try await unlinkAppleIDFromBackend(appleUserId: appleID)
                #if DEBUG
                print("✅ [Apple ID] 已解绑旧账号")
                #endif
                
                // 2. 切换到新 token（因为要绑定的是新 token）
                AppAccountManager.shared.replaceLocalAccountToken(newToken)
                
                // 3. 🔒 确保一对一关系：检查本地是否存储了其他 Apple ID
                // 如果本地存储的 Apple ID 和当前要绑定的不一致，先解绑
                if let existingAppleID = retrieveAppleID(),
                   existingAppleID != appleID {
                    #if DEBUG
                    print("⚠️ [一对一检查] 检测到新 token 本地已绑定其他 Apple ID: \(existingAppleID)")
                    print("💡 [一对一检查] 先解绑新 token 的旧绑定...")
                    #endif
                    try await unlinkAppleIDFromBackend(appleUserId: existingAppleID)
                    #if DEBUG
                    print("✅ [一对一检查] 已解绑新 token 的旧绑定")
                    #endif
                }
                
                // 4. 绑定新账号
                try await linkAppleIDToBackend(
                    appleUserId: appleID,
                    appAccountToken: newToken,
                    displayName: userDisplayName,
                    email: userAppleIDEmail,  // 保存邮箱到后端，用于后续恢复
                    identityToken: identityToken
                )
                #if DEBUG
                print("✅ [Apple ID] 已绑定新账号")
                #endif
                
                // 3. 刷新余额
                Task { @MainActor in
                    await WalletManager.shared.refreshBalance()
                    #if DEBUG
                    print("💰 [Apple ID] 余额刷新完成，当前余额: \(WalletManager.shared.balance)")
                    #endif
                }
                
                // 4. 清除冲突状态
                await MainActor.run {
                    accountConflict = nil
                }
            } catch {
                Logger.error("替换绑定失败", error: error, log: Logger.business)
                // 清除冲突状态，让用户可以重试
                await MainActor.run {
                    accountConflict = nil
                }
            }
        }
    }
    
    /// 取消账号冲突处理
    func cancelAccountConflict() {
        #if DEBUG
        print("❌ [Apple ID] 用户取消账号冲突处理")
        #endif
        accountConflict = nil
        // 退出 Apple ID 登录
        signOut()
    }
    
    /// 获取账号余额（用于显示在冲突提示中）
    private func getAccountBalance(token: String) async -> Int? {
        // 直接查询指定 token 的余额，不切换当前 token
        do {
            let balance = try await WalletService.shared.getBalance(for: token)
            #if DEBUG
            print("💰 [Apple ID] 查询账号 \(String(token.prefix(8)))... 的余额: \(balance) 虫洞币")
            #endif
            return balance
        } catch {
            #if DEBUG
            print("⚠️ [Apple ID] 查询账号余额失败: \(error)")
            #endif
            return nil
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let email = appleIDCredential.email  // 真实的 Apple ID 邮箱
            
            // 保存用户信息
            var resolvedDisplayName = displayName.isEmpty ? nil : displayName
            let resolvedEmail = email  // 真实的 Apple ID 邮箱（用于显示）
            
            // 如果 Apple 没有提供显示名称，尝试从本地缓存恢复
            if resolvedDisplayName == nil,
               let cached = profileStorage.load(userID: userID) {
                resolvedDisplayName = cached
            }
            
            // 保存 Apple ID 和显示名称
            saveAppleIDInfo(
                userID: userID,
                displayName: resolvedDisplayName
            )
            
            // 暂存本次授权返回的身份令牌（JWT）
            if let tokenData = appleIDCredential.identityToken,
               let tokenString = String(data: tokenData, encoding: .utf8) {
                latestIdentityToken = tokenString
            } else {
                latestIdentityToken = nil
            }
            
            // 更新状态
            isSignedIn = true
            userAppleID = userID  // UUID 格式的 userID（用于绑定）
            userAppleIDEmail = resolvedEmail  // 真实的 Apple ID 邮箱（用于显示）
            userDisplayName = resolvedDisplayName
            
            // 如果邮箱为空，尝试从后端恢复（异步，不阻塞登录流程）
            if resolvedEmail == nil {
                Task {
                    await restoreEmailFromBackend(appleID: userID)
                }
            }
            
            // 与现有账号系统集成
            linkWithExistingAccount()
            
            #if DEBUG
            print("🍎 Apple ID 登录成功")
            print("   用户ID: \(userID)")
            print("   显示名称: \(resolvedDisplayName ?? "未提供")")
            print("🔍 [诊断] 最终状态:")
            print("   - Apple ID: \(userID)")
            print("   - 显示名称: \(resolvedDisplayName ?? "无")")
            #endif
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        #if DEBUG
        print("🍎 Apple ID 登录失败: \(error.localizedDescription)")
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("🍎 用户取消了Apple ID登录")
            case .failed:
                print("🍎 Apple ID登录失败")
            case .invalidResponse:
                print("🍎 Apple ID登录响应无效")
            case .notHandled:
                print("🍎 Apple ID登录未处理")
            case .unknown:
                print("🍎 Apple ID登录未知错误")
            default:
                print("🍎 Apple ID登录其他错误")
            }
        }
        #endif
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
} 

// MARK: - Apple Profile 本地持久化

private class AppleProfileStorage {
    static let shared = AppleProfileStorage()
    
    private let storageKey = "AppleProfileStorageCache"
    private let queue = DispatchQueue(label: "com.chongyu.appleprofilestorage", qos: .utility)
    
    func persist(userID: String, displayName: String?) {
        queue.async {
            var cache = UserDefaults.standard.dictionary(forKey: self.storageKey) as? [String: [String: String]] ?? [:]
            var entry = cache[userID] ?? [:]
            if let name = displayName, !name.isEmpty {
                entry["displayName"] = name
            }
            cache[userID] = entry
            UserDefaults.standard.set(cache, forKey: self.storageKey)
        }
    }
    
    func load(userID: String) -> String? {
        var result: String?
        queue.sync {
            guard let cache = UserDefaults.standard.dictionary(forKey: self.storageKey) as? [String: [String: String]],
                  let entry = cache[userID] else {
                result = nil
                return
            }
            result = entry["displayName"]
        }
        return result
    }
} 