import Foundation

struct WalletBalance: Decodable {
    let balance: Int
    let currency: String
}

/**
 * WalletService
 * 使用系统默认的SSL证书验证（安全且符合App Store要求）
 */
final class WalletService {
    static let shared = WalletService()
    private init() {}
    
    // 创建URLSession（使用系统默认的SSL验证）
    // 系统会自动验证Let's Encrypt证书，无需自定义验证
    private func createSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        // 不使用delegate，让系统使用默认的SSL验证
        return URLSession(configuration: config)
    }
    
    // BaseURL: 统一从 BackendURLProvider 解析
    private var baseURL: URL {
        BackendURLProvider.resolvedURL()
    }
    
    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let body = body {
            req.httpBody = body
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addValue(AppAccountManager.shared.appAccountToken, forHTTPHeaderField: "X-App-Account-Token")
        req.addValue(AppAccountManager.shared.deviceIdentifier, forHTTPHeaderField: "X-Device-Id")
        return req
    }
    
    func fetchBalance() async throws -> WalletBalance {
        let req = makeRequest(path: "balance")
        let session = createSession()
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "wallet.balance", code: status, userInfo: [NSLocalizedDescriptionKey: bodyText.isEmpty ? "请求失败(\(status))" : bodyText])
        }
        return try JSONDecoder().decode(WalletBalance.self, from: data)
    }
    
    func proxyChat(messages: [[String: String]], model: String? = nil, params: [String: Any] = [:]) async throws -> [String: Any] {
        var payload: [String: Any] = [
            "messages": messages,
        ]
        if let model = model { payload["model"] = model }
        params.forEach { payload[$0.key] = $0.value }
        let body = try JSONSerialization.data(withJSONObject: payload)
        let req = makeRequest(path: "api/proxy", method: "POST", body: body)
        let session = createSession()
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 402 {
            throw NSError(domain: "wallet", code: 402, userInfo: ["message": "余额不足"]) 
        }
        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "proxy", code: http.statusCode, userInfo: ["body": text])
        }
        // 从响应头更新余额（如果提供）
        if let balanceStr = (http.allHeaderFields["X-Balance-After"] as? String) ?? (http.allHeaderFields["x-balance-after"] as? String),
           let newBalance = Int(balanceStr) {
            await MainActor.run {
                WalletManager.shared.updateBalance(newBalance)
            }
        }
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
    
    func confirmPurchase(appAccountToken: String, productId: String, transactionId: String, receipt: String?) async throws -> WalletBalance {
        let bodyObj: [String: Any] = [
            "appAccountToken": appAccountToken,
            "productId": productId,
            "transactionId": transactionId,
            "receipt": receipt ?? ""
        ]
        let body = try JSONSerialization.data(withJSONObject: bodyObj)
        let req = makeRequest(path: "purchase/confirm", method: "POST", body: body)
        let session = createSession()
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "wallet.purchase", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: bodyText.isEmpty ? "充值请求失败(\(http.statusCode))" : bodyText])
        }
        let walletBalance = try JSONDecoder().decode(WalletBalance.self, from: data)
        await MainActor.run {
            WalletManager.shared.updateBalance(walletBalance.balance, currency: walletBalance.currency)
            WalletManager.shared.isLoading = false
        }
        return walletBalance
    }

    func getBalance() async throws -> Int {
        let req = makeRequest(path: "api/balance", method: "GET")
        let session = createSession()
        
        do {
        let (data, resp) = try await session.data(for: req)
            
            guard let http = resp as? HTTPURLResponse else {
                throw NSError(domain: "wallet.balance", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "无法获取服务器响应"
                ])
            }
            
            guard http.statusCode == 200 else {
                let bodyText = String(data: data, encoding: .utf8) ?? ""
                throw NSError(domain: "wallet.balance", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "余额查询失败(\(http.statusCode)): \(bodyText.isEmpty ? "未知错误" : bodyText)"
                ])
        }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "wallet.balance", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "余额数据格式错误"
                ])
            }
            
            guard let balance = json["balance"] as? Int else {
                throw NSError(domain: "wallet.balance", code: -3, userInfo: [
                    NSLocalizedDescriptionKey: "余额数据缺失"
                ])
            }
            
            return balance
        } catch {
            // ⚡️ 优化：重新抛出更明确的错误，而不是返回0
            if let nsError = error as? NSError, nsError.domain == "wallet.balance" {
                throw error
            } else {
                // 网络错误等其他错误
                throw NSError(domain: "wallet.balance", code: -4, userInfo: [
                    NSLocalizedDescriptionKey: "余额查询失败: \(error.localizedDescription)"
                ])
            }
        }
    }
    
    /// 获取指定 token 的余额（不切换当前 token）
    func getBalance(for token: String) async throws -> Int {
        let url = baseURL.appendingPathComponent("api/balance")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addValue(token, forHTTPHeaderField: "X-App-Account-Token")
        req.addValue(AppAccountManager.shared.deviceIdentifier, forHTTPHeaderField: "X-Device-Id")
        let session = createSession()
        
        do {
        let (data, resp) = try await session.data(for: req)
            
            guard let http = resp as? HTTPURLResponse else {
                throw NSError(domain: "wallet.balance", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "无法获取服务器响应"
                ])
            }
            
            guard http.statusCode == 200 else {
                let bodyText = String(data: data, encoding: .utf8) ?? ""
                throw NSError(domain: "wallet.balance", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "余额查询失败(\(http.statusCode)): \(bodyText.isEmpty ? "未知错误" : bodyText)"
                ])
        }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "wallet.balance", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "余额数据格式错误"
                ])
            }
            
            guard let balance = json["balance"] as? Int else {
                throw NSError(domain: "wallet.balance", code: -3, userInfo: [
                    NSLocalizedDescriptionKey: "余额数据缺失"
                ])
            }
            
            return balance
        } catch {
            // ⚡️ 优化：重新抛出更明确的错误，而不是返回0
            if let nsError = error as? NSError, nsError.domain == "wallet.balance" {
                throw error
            } else {
                // 网络错误等其他错误
                throw NSError(domain: "wallet.balance", code: -4, userInfo: [
                    NSLocalizedDescriptionKey: "余额查询失败: \(error.localizedDescription)"
                ])
            }
        }
    }

    func consumeTokens(_ amount: Int, operation: String) async throws {
        let payload = ["amount": amount, "operation": operation] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let req = makeRequest(path: "api/consume", method: "POST", body: body)
        let session = createSession()
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 402 {
            throw NSError(domain: "wallet", code: 402, userInfo: ["message": "余额不足"])
        }
        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "wallet", code: http.statusCode, userInfo: ["body": text])
        }
        // Update balance from response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let newBalance = json["balance"] as? Int {
            await MainActor.run {
                WalletManager.shared.updateBalance(newBalance)
            }
        }
    }
} 