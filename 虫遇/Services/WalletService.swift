import Foundation

struct WalletBalance: Decodable {
    let balance: Int
    let currency: String
}

final class WalletService {
    static let shared = WalletService()
    private init() {}
    
    // BaseURL: 可通过 Info.plist 的 BACKEND_BASE_URL 或 UserDefaults("BackendBaseURL") 覆盖
    private var baseURL: URL {
        if let override = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"], let url = URL(string: override) {
            return url
        }
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String, let url = URL(string: plistURL) {
            return url
        }
        if let userDefault = UserDefaults.standard.string(forKey: "BackendBaseURL"), let url = URL(string: userDefault) {
            return url
        }
        #if targetEnvironment(simulator)
        return URL(string: "http://127.0.0.1:8787")!
        #else
        // 真机默认同样使用 127.0.0.1（如需连接 Mac，请在 Info.plist 或环境变量 BACKEND_BASE_URL 中设置为局域网地址，如 http://192.168.x.x:8787）
        return URL(string: "http://127.0.0.1:8787")!
        #endif
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
        return req
    }
    
    func fetchBalance() async throws -> WalletBalance {
        let req = makeRequest(path: "balance")
        let (data, resp) = try await URLSession.shared.data(for: req)
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
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 402 {
            throw NSError(domain: "wallet", code: 402, userInfo: ["message": "余额不足"]) 
        }
        guard http.statusCode == 200 else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "proxy", code: http.statusCode, userInfo: ["body": text])
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
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "wallet.purchase", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: bodyText.isEmpty ? "充值请求失败(\(http.statusCode))" : bodyText])
        }
        return try JSONDecoder().decode(WalletBalance.self, from: data)
    }
} 