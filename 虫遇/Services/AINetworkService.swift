import Foundation
import Combine

/**
 * AI网络错误枚举
 */
enum AINetworkError: Error {
    case invalidURL
    case noAPIKey
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case httpError(Int)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的API URL"
        case .noAPIKey:
            return "未设置API密钥"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应数据"
        case .decodingError(let error):
            return "解析响应失败: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        }
    }
}

/**
 * AI网络服务
 * 负责与DeepSeek API进行通信
 */
class AINetworkService {
    static let shared = AINetworkService()
    
    // 保存进行中的网络任务
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /**
     * 发送请求到DeepSeek API
     * @param prompt 提示词
     * @return 响应内容的Publisher
     */
    func sendRequest(prompt: String) -> AnyPublisher<String, AINetworkError> {
        guard let apiKey = APIConfigManager.shared.apiKey else {
            print("❌ API调用失败: 未设置API密钥")
            return Fail(error: AINetworkError.noAPIKey).eraseToAnyPublisher()
        }
        
        guard let url = URL(string: APIConfigManager.shared.deepSeekEndpoint) else {
            print("❌ API调用失败: 无效的API URL")
            return Fail(error: AINetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        // 判断当前使用的是哪种API
        let isARKAPI = APIConfigManager.shared.deepSeekEndpoint.contains("ark.cn-beijing.volces.com")
        let apiType = isARKAPI ? "ARK API" : "DeepSeek API"
        
        print("🔄 准备\(apiType)请求 - 端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        print("🔄 使用模型: \(APIConfigManager.shared.modelName)")
        print("🔑 API密钥格式: \(apiKey.hasPrefix("sk-") ? "DeepSeek格式(sk-...)" : "ARK格式(UUID)")")
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": APIConfigManager.shared.modelName,
            "messages": [
                ["role": "system", "content": "你是一个智能助手，能够以历史人物的身份回答问题。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 800,
            "top_p": 0.95,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // 移除超时限制，允许请求无限等待
        // request.timeoutInterval = 15.0  // 15秒超时
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            // 打印请求体内容以便诊断
            if let requestBodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 请求体内容: \(requestBodyString)")
            }
        } catch {
            return Fail(error: AINetworkError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        print("发送请求到\(apiType)...")
        
        // 创建自定义URLSessionConfiguration，设置更长的超时时间
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300  // 5分钟超时
        sessionConfig.timeoutIntervalForResource = 300 // 资源超时也设为5分钟
        let customSession = URLSession(configuration: sessionConfig)
        
        return customSession.dataTaskPublisher(for: request)
            .mapError { error -> AINetworkError in
                print("\(apiType)网络错误: \(error.localizedDescription)")
                
                // 如果网络请求失败，尝试切换API端点并记录
                print("⚠️ 网络请求失败，建议尝试切换API端点")
                if error.localizedDescription.contains("SSL") || error.localizedDescription.contains("证书") {
                    print("🔒 检测到SSL/证书错误，这可能是网络环境或证书配置问题")
                }
                return AINetworkError.requestFailed(error)
            }
            .flatMap { data, response -> AnyPublisher<String, AINetworkError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                }
                
                print("📥 收到\(apiType)响应 - 状态码: \(httpResponse.statusCode)")
                
                // 打印完整响应内容
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 响应内容: \(responseString)")
                }
                
                if httpResponse.statusCode != 200 {
                    print("HTTP错误: \(httpResponse.statusCode)")
                    if let errorStr = String(data: data, encoding: .utf8) {
                        print("错误详情: \(errorStr)")
                        
                        // 检查是否是身份验证错误
                        if errorStr.contains("Authentication") || errorStr.contains("invalid") {
                            print("🔑 API密钥验证失败，请检查密钥格式是否与当前API端点匹配")
                        }
                    }
                    
                    // 建议尝试切换API端点
                    print("⚠️ 请求失败，建议尝试切换API端点")
                    
                    return Fail(error: AINetworkError.httpError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                do {
                    // 解析DeepSeek API响应
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        print("✅ 成功解析\(apiType)响应")
                        print("📝 回复内容长度: \(content.count)字符")
                        
                        // 不再检查模板语言
                        print("👍 API返回内容已成功获取")
                        
                        // 处理可能存在的前导和尾随空格和换行符
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🔍 处理后内容长度: \(trimmedContent.count)字符")
                        
                        return Just(trimmedContent)
                            .setFailureType(to: AINetworkError.self)
                            .eraseToAnyPublisher()
                    } else {
                        print("❌ 无法解析响应数据")
                        if let responseStr = String(data: data, encoding: .utf8) {
                            print("📄 原始响应: \(responseStr)")
                        }
                        
                        // 建议尝试切换API端点
                        print("⚠️ 响应解析失败，建议尝试切换API端点")
                        
                        return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                    }
                } catch {
                    print("❌ 解析响应失败: \(error)")
                    
                    // 建议尝试切换API端点
                    print("⚠️ 响应解析出错，建议尝试切换API端点")
                    
                    return Fail(error: AINetworkError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
} 