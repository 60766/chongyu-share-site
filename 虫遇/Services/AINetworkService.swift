import Foundation
import Combine

/**
 * 自定义URLSessionDataDelegate，用于捕获部分数据
 */
class PartialDataDelegate: NSObject, URLSessionDataDelegate {
    private var receivedData = Data()
    private var completion: ((Data?, URLResponse?, Error?) -> Void)?
    
    func setCompletion(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completion = completion
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // 即使有错误，也尝试返回已接收的数据
        if let error = error as? URLError, error.code == .networkConnectionLost {
            print("🔄 Connection lost, but we have \(receivedData.count) bytes of partial data")
            completion?(receivedData.isEmpty ? nil : receivedData, task.response, error)
        } else {
            completion?(error == nil ? receivedData : nil, task.response, error)
        }
    }
}

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
    case partialDataAvailable(URLError)
    
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
            if code == 402 {
                return "余额不足，请先充值"
            }
            return "HTTP错误: \(code)"
        case .partialDataAvailable(let error):
            return "部分数据可用，但传输失败: \(error.localizedDescription)"
        }
    }
}

/**
 * AI网络服务
 * 负责与DeepSeek API进行通信
 */
class AINetworkService: ObservableObject {
    static let shared = AINetworkService()
    
    // 保存进行中的网络任务
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 与 WalletService 一致的后端地址解析逻辑
        if let override = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"], let url = URL(string: override) {
            self.baseURL = url
        } else if let plistURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String, let url = URL(string: plistURL) {
            self.baseURL = url
        } else if let userDefault = UserDefaults.standard.string(forKey: "BackendBaseURL"), let url = URL(string: userDefault) {
            self.baseURL = url
        } else {
            #if DEBUG
            // 临时测试生产环境后端
            // self.baseURL = URL(string: "http://121.40.184.29:3000")!
            self.baseURL = URL(string: "http://127.0.0.1:8787")!
            #else
            self.baseURL = URL(string: "http://121.40.184.29:3000")!
            #endif
        }
    }
    
    // 与 WalletService 一致的后端地址解析逻辑
    private var baseURL: URL
    
    /**
     * 使用自定义delegate发送请求，能够捕获部分数据
     */
    private func sendRequestWithPartialDataCapture(request: URLRequest) -> AnyPublisher<String, AINetworkError> {
        return Future<String, AINetworkError> { promise in
            let delegate = PartialDataDelegate()
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 300
            sessionConfig.timeoutIntervalForResource = 300
            sessionConfig.waitsForConnectivity = true
            
            let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
            
            delegate.setCompletion { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                print("📥 HTTP status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 402 {
                    print("💳 402 Payment Required from backend")
                    Task { @MainActor in
                        WalletManager.shared.showPurchaseSheet()
                    }
                    promise(.failure(.httpError(402)))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    print("❌ Non-200 status: \(httpResponse.statusCode)")
                    promise(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
                
                // 更新钱包余额
                self.updateWalletBalanceIfAvailable(from: httpResponse)
                
                if let data = data {
                    // 尝试解析数据，即使是部分数据
                    self.parseJSONResponse(data: data, allowPartial: true)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let parseError) = completion {
                                    // 如果解析失败但有网络错误，优先报告网络问题
                                    if let urlError = error as? URLError, urlError.code == .networkConnectionLost {
                                        print("🔄 Data parsing failed, but connection was lost - treating as partial data available")
                                        promise(.failure(.partialDataAvailable(urlError)))
                                    } else {
                                        promise(.failure(parseError))
                                    }
                                }
                            },
                            receiveValue: { content in
                                promise(.success(content))
                            }
                        )
                        .store(in: &self.cancellables)
                } else if let error = error {
                    if let urlError = error as? URLError, urlError.code == .networkConnectionLost {
                        promise(.failure(.partialDataAvailable(urlError)))
                    } else {
                        promise(.failure(.requestFailed(error)))
                    }
                } else {
                    promise(.failure(.invalidResponse))
                }
            }
            
            let task = session.dataTask(with: request)
            task.resume()
        }
        .eraseToAnyPublisher()
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
        
        // 调试日志已关闭
        // print("🌐 AINetworkService baseURL: \(baseURL.absoluteString)")
        // print("➡️ POST \(url.absoluteString)")
        
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
        print("🪪 实际使用的Token: \(token)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            // print("📦 Request body size: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            return Fail(error: AINetworkError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return sendRequestWithPartialDataCapture(request: request)
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
        
        // print("🔄 准备代理聊天请求 - 角色: \(characterName)")
        
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
        let chatToken = AppAccountManager.shared.appAccountToken
        request.addValue(chatToken, forHTTPHeaderField: "X-App-Account-Token")
        print("🪪 聊天使用的Token: \(chatToken)")
        do { request.httpBody = try JSONSerialization.data(withJSONObject: requestBody) } catch {
            return Fail(error: AINetworkError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return sendRequestWithPartialDataCapture(request: request)
    }
    
    // 移除角色个性化设置方法

    /**
     * 解析JSON响应，支持部分数据解析
     */
    private func parseJSONResponse(data: Data, allowPartial: Bool = false) -> AnyPublisher<String, AINetworkError> {
        do {
            print("📦 Received data size: \(data.count) bytes")
            
            // 尝试解析完整的JSON
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return self.extractContentFromJSON(jsonObject)
            }
            
            // 如果允许部分数据且完整JSON解析失败，尝试部分解析
            if allowPartial {
                return self.tryPartialJSONParsing(data: data)
            }
            
            throw AINetworkError.decodingError(NSError(domain: "JSON", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"]))
            
        } catch {
            print("❌ JSON parsing failed: \(error)")
            
            // 如果允许部分数据，尝试从原始数据中提取有用信息
            if allowPartial {
                return self.tryPartialJSONParsing(data: data)
            }
            
            return Fail(error: AINetworkError.decodingError(error)).eraseToAnyPublisher()
        }
    }
    
    /**
     * 尝试从部分JSON数据中提取内容
     */
    private func tryPartialJSONParsing(data: Data) -> AnyPublisher<String, AINetworkError> {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return Fail(error: AINetworkError.decodingError(NSError(domain: "Encoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode data as UTF-8"]))).eraseToAnyPublisher()
        }
        
        print("🔍 Attempting partial JSON parsing from: \(dataString.prefix(200))...")
        
        // 尝试修复不完整的JSON
        let repairedJSON = self.repairIncompleteJSON(dataString)
        
        if let repairedData = repairedJSON.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: repairedData) as? [String: Any] {
            print("✅ Successfully repaired and parsed partial JSON")
            return self.extractContentFromJSON(jsonObject)
        }
        
        // 如果JSON修复失败，尝试正则表达式提取内容
        return self.extractContentWithRegex(from: dataString)
    }
    
    /**
     * 修复不完整的JSON字符串
     */
    private func repairIncompleteJSON(_ jsonString: String) -> String {
        var repaired = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果JSON没有正确结束，尝试添加缺失的括号和引号
        let openBraces = repaired.filter { $0 == "{" }.count
        let closeBraces = repaired.filter { $0 == "}" }.count
        let openQuotes = repaired.filter { $0 == "\"" }.count
        
        // 修复未闭合的引号
        if openQuotes % 2 != 0 {
            repaired += "\""
        }
        
        // 修复未闭合的大括号
        let missingBraces = openBraces - closeBraces
        if missingBraces > 0 {
            repaired += String(repeating: "}", count: missingBraces)
        }
        
        print("🔧 JSON repair: \(jsonString.count) -> \(repaired.count) chars")
        return repaired
    }
    
    /**
     * 使用正则表达式从字符串中提取AI回复内容
     */
    private func extractContentWithRegex(from dataString: String) -> AnyPublisher<String, AINetworkError> {
        // 更强大的正则表达式模式，支持中文和转义字符
        let patterns = [
            // 标准的content字段，支持转义字符和中文
            "\"content\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"",
            // 嵌套在message中的content
            "\"message\"\\s*:\\s*\\{[^}]*\"content\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)",
            // 备用的text字段
            "\"text\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"",
            // 更宽松的匹配，处理不完整的引号
            "\"content\"\\s*:\\s*\"([^\"]*)",
            // 处理可能的其他响应格式
            "\"response\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"",
        ]
        
        for (index, pattern) in patterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                let range = NSRange(dataString.startIndex..., in: dataString)
                if let match = regex.firstMatch(in: dataString, options: [], range: range) {
                    if let contentRange = Range(match.range(at: 1), in: dataString) {
                        let extractedContent = String(dataString[contentRange])
                        // 处理转义字符
                        let unescapedContent = extractedContent
                            .replacingOccurrences(of: "\\\"", with: "\"")
                            .replacingOccurrences(of: "\\n", with: "\n")
                            .replacingOccurrences(of: "\\r", with: "\r")
                            .replacingOccurrences(of: "\\t", with: "\t")
                            .replacingOccurrences(of: "\\\\", with: "\\")
                        
                        print("✅ Extracted content via regex pattern #\(index + 1): \(unescapedContent.prefix(100))...")
                        return Just(unescapedContent.trimmingCharacters(in: .whitespacesAndNewlines))
                            .setFailureType(to: AINetworkError.self)
                            .eraseToAnyPublisher()
                    }
                }
            }
        }
        
        print("❌ Failed to extract content from partial data")
        print("🔍 Data sample: \(dataString.prefix(500))")
        return Fail(error: AINetworkError.decodingError(NSError(domain: "Regex", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to extract content from partial data"]))).eraseToAnyPublisher()
    }
    
    /**
     * 从JSON对象中提取内容
     */
    private func extractContentFromJSON(_ jsonObject: [String: Any]) -> AnyPublisher<String, AINetworkError> {
        // 标准OpenAI格式
        if let choices = jsonObject["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return Just(content)
                .setFailureType(to: AINetworkError.self)
                .eraseToAnyPublisher()
        }
        
        // 其他可能的格式
        if let content = jsonObject["content"] as? String {
            return Just(content)
                .setFailureType(to: AINetworkError.self)
                .eraseToAnyPublisher()
        }
        
        if let text = jsonObject["text"] as? String {
            return Just(text)
                .setFailureType(to: AINetworkError.self)
                .eraseToAnyPublisher()
        }
        
        return Fail(error: AINetworkError.decodingError(NSError(domain: "JSON", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content found in response"]))).eraseToAnyPublisher()
    }
} 