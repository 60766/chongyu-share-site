import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class AppleSignInManager: NSObject, ObservableObject {
    static let shared = AppleSignInManager()
    
    @Published var isSignedIn = false
    @Published var userDisplayName: String?
    @Published var userEmail: String?
    @Published var userAppleID: String?
    
    private let serviceIdentifier = "com.虫遇.applesignin"
    private let appleIDKey = "apple_user_id"
    private let displayNameKey = "apple_display_name"
    private let emailKey = "apple_email"
    
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
                    print("🍎 getCredentialState error: \(error)")
                }
                switch state {
                case .authorized:
                    self?.isSignedIn = true
                    self?.userAppleID = appleID
                    self?.userDisplayName = self?.retrieveDisplayName()
                    self?.userEmail = self?.retrieveEmail()
                    print("🍎 Apple ID 登录状态：已授权")
                case .revoked:
                    self?.signOut()
                    print("🍎 Apple ID 登录状态：已撤销")
                case .notFound:
                    self?.signOut()
                    print("🍎 Apple ID 登录状态：未找到")
                default:
                    // 未知时进行一次 silent request 以尝试恢复
                    self?.performExistingAccountSetupFlows()
                    print("🍎 Apple ID 登录状态：未知，尝试恢复")
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
    
    func signOut() {
        // 如果有Apple ID，先尝试从后端解绑
        if let appleID = userAppleID {
            Task {
                do {
                    try await unlinkAppleIDFromBackend(appleUserId: appleID)
                } catch {
                    print("⚠️ Apple ID 后端解绑失败: \(error)")
                    // 即使后端解绑失败，也继续本地登出
                }
            }
        }
        
        isSignedIn = false
        userDisplayName = nil
        userEmail = nil
        userAppleID = nil
        
        // 清除存储的信息
        clearStoredData()
        
        print("🍎 Apple ID 登出成功")
    }
    
    // MARK: - 数据存储
    
    private func saveAppleIDInfo(userID: String, displayName: String?, email: String?) {
        saveToKeychain(key: appleIDKey, value: userID)
        
        if let displayName = displayName {
            saveToKeychain(key: displayNameKey, value: displayName)
        }
        
        if let email = email {
            saveToKeychain(key: emailKey, value: email)
        }
    }
    
    private func retrieveAppleID() -> String? {
        return retrieveFromKeychain(key: appleIDKey)
    }
    
    private func retrieveDisplayName() -> String? {
        return retrieveFromKeychain(key: displayNameKey)
    }
    
    private func retrieveEmail() -> String? {
        return retrieveFromKeychain(key: emailKey)
    }
    
    private func clearStoredData() {
        deleteFromKeychain(key: appleIDKey)
        deleteFromKeychain(key: displayNameKey)
        deleteFromKeychain(key: emailKey)
    }
    
    // MARK: - 钥匙串操作
    
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
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
    
    // MARK: - 与现有账号系统集成
    
    func linkWithExistingAccount() {
        guard let appleID = userAppleID else {
            print("❌ Apple ID 为空，无法关联账号")
            return
        }
        
        Task {
            do {
                if let found = try await findAccountByAppleID(appleUserId: appleID) {
                    let serverToken = found.appAccountToken
                    let currentToken = AppAccountManager.shared.appAccountToken
                    if serverToken != currentToken {
                        AppAccountManager.shared.replaceLocalAccountToken(serverToken)
                    }
                    print("🔄 已切换到与 Apple ID 绑定的账号")
                    return
                }
            } catch {
                // 未找到时继续进行绑定
            }
            do {
                guard let identityToken = latestIdentityToken else {
                    print("⚠️ 缺少 identityToken，无法关联 Apple ID")
                    return
                }
                let currentToken = AppAccountManager.shared.appAccountToken
                try await linkAppleIDToBackend(
                    appleUserId: appleID,
                    appAccountToken: currentToken,
                    displayName: userDisplayName,
                    email: userEmail,
                    identityToken: identityToken
                )
                print("🔗 Apple ID 已与虫遇账号关联: \(currentToken)")
            } catch {
                // 如果后端返回409并包含已存在的token，切换到该token
                if let nsError = error as NSError?, nsError.code == 409,
                   let body = nsError.userInfo[NSLocalizedDescriptionKey] as? String,
                   let data = body.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let existingToken = json["existingToken"] as? String {
                    AppAccountManager.shared.replaceLocalAccountToken(existingToken)
                    print("🔁 已切换到已绑定账号")
                } else {
                    print("❌ Apple ID 关联失败: \(error)")
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
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
              let url = URL(string: "\(baseURL)/account/link-apple") else {
            throw NSError(domain: "AppleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的后端URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appAccountToken, forHTTPHeaderField: "X-App-Account-Token")
        
        var payload: [String: Any] = [
            "appAccountToken": appAccountToken,
            "appleUserId": appleUserId,
            "displayName": displayName as Any,
            "email": email as Any
        ]
        if let identityToken = identityToken {
            payload["identityToken"] = identityToken
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AppleSignIn", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        print("✅ Apple ID 后端关联成功")
    }
    
    private func unlinkAppleIDFromBackend(appleUserId: String) async throws {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
              let url = URL(string: "\(baseURL)/account/unlink-apple") else {
            throw NSError(domain: "AppleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的后端URL"])
        }
        
        let currentToken = AppAccountManager.shared.appAccountToken
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(currentToken, forHTTPHeaderField: "X-App-Account-Token")
        
        let payload = [
            "appAccountToken": currentToken,
            "appleUserId": appleUserId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "AppleSignIn", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        print("✅ Apple ID 后端解绑成功")
    }
    
    private func findAccountByAppleID(appleUserId: String) async throws -> (appAccountToken: String, linkedAt: Int, displayName: String?, email: String?)? {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
              let url = URL(string: "\(baseURL)/account/find-by-apple") else {
            throw NSError(domain: "AppleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的后端URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "appleUserId": appleUserId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
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
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let email = appleIDCredential.email
            
            // 保存用户信息
            saveAppleIDInfo(
                userID: userID,
                displayName: displayName.isEmpty ? nil : displayName,
                email: email
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
            userAppleID = userID
            userDisplayName = displayName.isEmpty ? nil : displayName
            userEmail = email
            
            // 与现有账号系统集成
            linkWithExistingAccount()
            
            print("🍎 Apple ID 登录成功")
            print("   用户ID: \(userID)")
            print("   显示名称: \(displayName)")
            print("   邮箱: \(email ?? "未提供")")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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
            @unknown default:
                print("🍎 Apple ID登录其他错误")
            }
        }
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