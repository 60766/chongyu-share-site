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
    
    // 与 WalletService 一致的后端地址解析逻辑
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
        return URL(string: "http://127.0.0.1:8787")!
        #endif
    }
    
    // 从响应头更新余额（如果提供）
    private func updateWalletBalanceIfAvailable(from httpResponse: HTTPURLResponse) {
        let headers = httpResponse.allHeaderFields
        let candidates = ["X-Balance-After", "x-balance-after"]
        var balanceString: String?
        for key in candidates {
            if let v = headers[key] as? String { balanceString = v; break }
            if let v = headers[key] as? NSNumber { balanceString = v.stringValue; break }
        }
        if let balanceString = balanceString, let newBalance = Int(balanceString) {
            Task { @MainActor in
                WalletManager.shared.balance = newBalance
            }
        }
    }
    
    /**
     * 发送请求到DeepSeek API
     * @param prompt 提示词
     * @return 响应内容的Publisher
     */
    func sendRequest(prompt: String) -> AnyPublisher<String, AINetworkError> {
        let url = baseURL.appendingPathComponent("api/proxy")
        
        print("🌐 AINetworkService baseURL: \(baseURL.absoluteString)")
        print("➡️ POST \(url.absoluteString)")
        
        // 构建请求体（后端将附加模型名等）
        let requestBody: [String: Any] = [
            "messages": [
                ["role": "system", "content": "你是一个智能助手，能够以各种角色的身份回答问题。请保持回答简洁、有深度，并体现角色的语言风格和特点。不要使用现代网络用语，避免使用表情符号，保持角色的真实性。"],
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
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let token = AppAccountManager.shared.appAccountToken
        request.addValue(token, forHTTPHeaderField: "X-App-Account-Token")
        print("🪪 X-App-Account-Token prefix: \(token.prefix(8))…")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📦 Request body size: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            return Fail(error: AINetworkError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300
        sessionConfig.timeoutIntervalForResource = 300
        let customSession = URLSession(configuration: sessionConfig)
        
        return customSession.dataTaskPublisher(for: request)
            .mapError { error -> AINetworkError in
                print("🛑 Network error: \(error.localizedDescription)")
                return AINetworkError.requestFailed(error)
            }
            .flatMap { data, response -> AnyPublisher<String, AINetworkError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                }
                print("📥 HTTP status: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 402 {
                    print("💳 402 Payment Required from backend")
                    Task { @MainActor in
                        WalletManager.shared.showPurchaseSheet()
                    }
                    return Fail(error: AINetworkError.httpError(402)).eraseToAnyPublisher()
                }
                if httpResponse.statusCode != 200 {
                    print("❌ Non-200 status: \(httpResponse.statusCode)")
                    return Fail(error: AINetworkError.httpError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                // 更新钱包余额（如果后端提供）
                self.updateWalletBalanceIfAvailable(from: httpResponse)
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        print("📄 Response content prefix: \(content.prefix(60))…")
                        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        return Just(trimmed).setFailureType(to: AINetworkError.self).eraseToAnyPublisher()
                    } else {
                        print("⚠️ Invalid response JSON structure")
                        return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                    }
                } catch {
                    print("🧩 JSON decode error: \(error.localizedDescription)")
                    return Fail(error: AINetworkError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    /**
     * 发送聊天请求到DeepSeek API
     * 专门为历史人物聊天设计的API调用
     * @param characterName 历史人物名称
     * @param characterInfo 历史人物信息
     * @param conversationHistory 对话历史
     * @param userMessage 用户消息
     * @return 响应内容的Publisher
     */
    func sendChatRequest(
        characterName: String,
        characterInfo: String,
        conversationHistory: String,
        userMessage: String
    ) -> AnyPublisher<String, AINetworkError> {
        let url = baseURL.appendingPathComponent("api/proxy")
        
        print("🔄 准备代理聊天请求 - 角色: \(characterName)")
        
        let systemPrompt = """
        你是\(characterName)，\(characterInfo)
        【核心指令】
        1. 绝对禁止使用括号内的任何动作描写或场景描述
        2. 直接回应用户，就像朋友间的日常对话
        3. 每条回复聚焦一个主题，不要东扯西扯
        4. 可以适度使用网络用语，但不要过度
        5. 保持轻松随意的语气，像与老朋友聊天
        6. 绝对禁止在回复中包含对用户消息的分析（如"看到用户发来重复的好哇"）
        7. 禁止在回复中显示你的思考过程或推理分析
        【对话历史处理】
        1. 系统会提供最近3条消息作为上下文，格式为："用户:消息内容"
        2. 优先关注最近一条用户消息，这是你需要直接回应的内容
        3. 不要强行与历史对话关联，仅在有明显关联时才引用
        4. 如果用户提出的新问题与历史无关，完全专注于回答新问题
        5. 不要在回复中提及或分析用户的消息模式（如重复、频率等）
        【对话处理】
        1. 仔细分析用户消息与前文的关联性，但不要在回复中展示你的分析过程
        2. 如果用户转换话题，灵活跟随新话题，不要强行关联前文
        3. 如果用户消息看似奇怪或不相关，不要假设，直接针对当前消息回应
        4. 对于突然的问题或陈述，不要混淆，以当前消息为准
        5. 避免对用户的陈述做过度推断或假设
        【回复风格】
        • 简短自然(40-60字)，像发消息给熟悉的朋友
        • 可以幽默、调侃，但不要过度表演
        • 不要说教或讲大道理，保持对话的平等感
        • 保留你的个性和专业知识，但用更现代、更亲近的方式表达
        • 不要在回复中包含对话分析或元对话内容
        记住：完全避免使用括号内的任何描述。
        """
        
        let fullPrompt = conversationHistory + " " + userMessage
        
        let requestBody: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": fullPrompt]
            ],
            "temperature": 0.8,
            "max_tokens": 500,
            "top_p": 0.92,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(AppAccountManager.shared.appAccountToken, forHTTPHeaderField: "X-App-Account-Token")
        do { request.httpBody = try JSONSerialization.data(withJSONObject: requestBody) } catch {
            return Fail(error: AINetworkError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300
        sessionConfig.timeoutIntervalForResource = 300
        let customSession = URLSession(configuration: sessionConfig)
        
        return customSession.dataTaskPublisher(for: request)
            .mapError { AINetworkError.requestFailed($0) }
            .flatMap { data, response -> AnyPublisher<String, AINetworkError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                }
                print("📥 HTTP status (chat): \(httpResponse.statusCode)")
                if httpResponse.statusCode == 402 {
                    print("💳 402 Payment Required from backend (chat)")
                    Task { @MainActor in
                        WalletManager.shared.showPurchaseSheet()
                    }
                    return Fail(error: AINetworkError.httpError(402)).eraseToAnyPublisher()
                }
                if httpResponse.statusCode != 200 {
                    print("❌ Non-200 status (chat): \(httpResponse.statusCode)")
                    return Fail(error: AINetworkError.httpError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                // 更新钱包余额（如果后端提供）
                self.updateWalletBalanceIfAvailable(from: httpResponse)
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        print("📄 Response content prefix (chat): \(content.prefix(60))…")
                        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        return Just(trimmed).setFailureType(to: AINetworkError.self).eraseToAnyPublisher()
                    } else {
                        print("⚠️ Invalid response JSON structure (chat)")
                        return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                    }
                } catch {
                    print("🧩 JSON decode error (chat): \(error.localizedDescription)")
                    return Fail(error: AINetworkError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 移除角色个性化设置方法
} 