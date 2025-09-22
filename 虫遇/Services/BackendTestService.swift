import Foundation

final class BackendTestService {
    static let shared = BackendTestService()
    private init() {}
    
    // 与其他服务保持一致的后端地址解析逻辑
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
        #if DEBUG
        return URL(string: "http://127.0.0.1:8787")!
        #else
        return URL(string: "http://121.40.184.29:3000")!
        #endif
    }
    
    /// 测试后端连接状态
    func testConnection() async -> (success: Bool, message: String, details: [String: Any]?) {
        do {
            let url = baseURL
            print("🔍 测试连接到: \(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10.0
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "❌ 无效的HTTP响应", nil)
            }
            
            let statusCode = httpResponse.statusCode
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            
            print("📡 响应状态码: \(statusCode)")
            print("📄 响应内容: \(responseBody)")
            
            var details: [String: Any] = [
                "url": url.absoluteString,
                "status_code": statusCode,
                "response_body": responseBody,
                "headers": httpResponse.allHeaderFields
            ]
            
            if statusCode == 200 {
                // 尝试解析JSON响应
                if let jsonData = data.isEmpty ? nil : data,
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    details["parsed_json"] = json
                    
                    if let message = json["message"] as? String {
                        return (true, "✅ 连接成功: \(message)", details)
                    }
                }
                return (true, "✅ 连接成功 (状态码: \(statusCode))", details)
            } else {
                return (false, "❌ 连接失败 (状态码: \(statusCode)): \(responseBody)", details)
            }
            
        } catch {
            let errorMessage = "❌ 网络错误: \(error.localizedDescription)"
            let details: [String: Any] = [
                "url": baseURL.absoluteString,
                "error": error.localizedDescription,
                "error_code": (error as NSError).code
            ]
            return (false, errorMessage, details)
        }
    }
    
    /// 测试健康检查端点
    func testHealthCheck() async -> (success: Bool, message: String, details: [String: Any]?) {
        do {
            let url = baseURL.appendingPathComponent("health")
            print("🏥 测试健康检查: \(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10.0
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "❌ 无效的HTTP响应", nil)
            }
            
            let statusCode = httpResponse.statusCode
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            
            var details: [String: Any] = [
                "url": url.absoluteString,
                "status_code": statusCode,
                "response_body": responseBody
            ]
            
            if statusCode == 200 {
                return (true, "✅ 健康检查通过", details)
            } else {
                return (false, "❌ 健康检查失败 (状态码: \(statusCode))", details)
            }
            
        } catch {
            let errorMessage = "❌ 健康检查网络错误: \(error.localizedDescription)"
            let details: [String: Any] = [
                "url": baseURL.appendingPathComponent("health").absoluteString,
                "error": error.localizedDescription
            ]
            return (false, errorMessage, details)
        }
    }
} 