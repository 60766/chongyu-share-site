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
            return Fail(error: AINetworkError.noAPIKey).eraseToAnyPublisher()
        }
        
        guard let url = URL(string: APIConfigManager.shared.deepSeekEndpoint) else {
            return Fail(error: AINetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        // 判断当前使用的是哪种API
        let isARKAPI = APIConfigManager.shared.deepSeekEndpoint.contains("ark.cn-beijing.volces.com")
        let apiType = isARKAPI ? "ARK API" : "DeepSeek API"
        
        // 使用红色背景的醒目日志标记
        print("🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴")
        print("🚨🚨🚨 【虚拟角色评论生成】API请求开始 🚨🚨🚨")
        print("🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴")
        print("🔄 准备\(apiType)请求 - 端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        print("🔄 使用模型: \(APIConfigManager.shared.modelName)")
        print("🔑 API密钥格式: \(apiKey.hasPrefix("sk-") ? "DeepSeek格式(sk-...)" : "ARK格式(UUID)")")
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": APIConfigManager.shared.modelName,
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
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        // 移除超时限制，允许请求无限等待
        // request.timeoutInterval = 15.0  // 15秒超时
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // 🔴🔴🔴 超级醒目的API请求内容日志 🔴🔴🔴
            print("\n🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨")
            print("🚨🚨🚨                    【API请求详细内容】                    🚨🚨🚨")
            print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨")
            print("📍 API端点: \(url.absoluteString)")
            print("🤖 使用模型: \(APIConfigManager.shared.modelName)")
            print("🌡️ 温度参数: 0.7")
            print("🎯 最大Token: 800")
            print("📊 Top-p参数: 0.95")
            print("\n🔴 ===== 系统提示词 =====")
            print("你是一个智能助手，能够以各种角色的身份回答问题。请保持回答简洁、有深度，并体现角色的语言风格和特点。不要使用现代网络用语，避免使用表情符号，保持角色的真实性。")
            print("\n🔴 ===== 用户提示词（角色生成指令）=====")
            print(prompt)
            print("\n🔴 ===== 完整JSON请求体 =====")
            if let requestBodyString = String(data: request.httpBody!, encoding: .utf8) {
                print(requestBodyString)
            }
            print("🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨")
            print("")
            
        } catch {
            return Fail(error: AINetworkError.requestFailed(error)).eraseToAnyPublisher()
        }
        

        
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
                
                // 🔴🔴🔴 超级醒目的API响应日志 🔴🔴🔴
                print("\n🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢")
                print("🎉🎉🎉 【虚拟角色评论生成】API响应接收 🎉🎉🎉")
                print("🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢")
                print("📥 收到\(apiType)响应 - 状态码: \(httpResponse.statusCode)")
                
                // 打印完整响应内容
                if let responseString = String(data: data, encoding: .utf8) {
                    print("\n🟢 ===== API完整响应内容 =====")
                    print(responseString)
                    print("🟢 ===== 响应内容结束 =====\n")
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
                                                // 处理可能存在的前导和尾随空格和换行符
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        return Just(trimmedContent)
                            .setFailureType(to: AINetworkError.self)
                            .eraseToAnyPublisher()
                    } else {
    

                        
                        // 建议尝试切换API端点
                        print("⚠️ 响应解析失败，建议尝试切换API端点")
                        
                        return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                    }
                } catch {

                    
                    // 建议尝试切换API端点
                    print("⚠️ 响应解析出错，建议尝试切换API端点")
                    
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
        guard let apiKey = APIConfigManager.shared.apiKey else {
            return Fail(error: AINetworkError.noAPIKey).eraseToAnyPublisher()
        }
        
        guard let url = URL(string: APIConfigManager.shared.deepSeekEndpoint) else {
            return Fail(error: AINetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        // 判断当前使用的是哪种API
        let isARKAPI = APIConfigManager.shared.deepSeekEndpoint.contains("ark.cn-beijing.volces.com")
        let apiType = isARKAPI ? "ARK API" : "DeepSeek API"
        
        print("🔄 准备\(apiType)聊天请求 - 角色: \(characterName)")
        
        // 进一步优化的系统提示词 - 增强历史消息处理能力
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
        
        记住：完全避免使用括号内的任何描述。你们是在进行自然的聊天，每次回复都应适应用户当前的话题和语境，不要分析用户的消息模式或行为。
        """
        
        // 极简用户提示词 - 只保留必要内容
        let fullPrompt = conversationHistory + " " + userMessage
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": APIConfigManager.shared.modelName,
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
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📤 聊天请求已准备 - 角色: \(characterName)")
            
            // 添加详细日志，显示完整请求内容
            print("\n📋 ===== 聊天请求详细内容 =====")
            print("🔷 角色名称: \(characterName)")
            print("\n🔷 系统提示词:")
            print(systemPrompt)
            print("\n🔷 用户提示词:")
            print(fullPrompt)
            print("\n🔷 API参数:")
            print("  - 模型: \(APIConfigManager.shared.modelName)")
            print("  - 温度: 0.8")
            print("  - 最大token: 500")
            print("  - top_p: 0.92")
            print("\n🔷 历史消息处理说明:")
            print("  - 当前应用将最近3条消息作为上下文传递给API")
            print("  - 历史消息在ChatView.buildConversationContext()中构建")
            print("  - 历史消息被格式化为简洁形式，仅保留必要内容")
            print("  - ConversationMemoryManager记录和管理更长期的对话历史")
            
            // 打印完整JSON请求体
            if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("\n🔷 完整JSON请求体:")
                print(jsonString)
            }
            print("📋 ===== 请求详情结束 =====\n")
            
        } catch {
            return Fail(error: AINetworkError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        // 创建自定义URLSessionConfiguration，设置更长的超时时间
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300  // 5分钟超时
        sessionConfig.timeoutIntervalForResource = 300 // 资源超时也设为5分钟
        let customSession = URLSession(configuration: sessionConfig)
        
        return customSession.dataTaskPublisher(for: request)
            .mapError { error -> AINetworkError in
                print("\(apiType)聊天请求网络错误: \(error.localizedDescription)")
                return AINetworkError.requestFailed(error)
            }
            .flatMap { data, response -> AnyPublisher<String, AINetworkError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                }
                
                print("📥 收到\(apiType)聊天响应 - 状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("HTTP错误: \(httpResponse.statusCode)")
                    if let errorStr = String(data: data, encoding: .utf8) {
                        print("错误详情: \(errorStr)")
                    }
                    return Fail(error: AINetworkError.httpError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                do {
                    // 解析DeepSeek API响应
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
    
                        
                        // 处理可能存在的前导和尾随空格和换行符
                        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🔍 处理后内容长度: \(trimmedContent.count)字符")
                        
                        return Just(trimmedContent)
                            .setFailureType(to: AINetworkError.self)
                            .eraseToAnyPublisher()
                    } else {
    
                        return Fail(error: AINetworkError.invalidResponse).eraseToAnyPublisher()
                    }
                } catch {
                    print("❌ 解析聊天响应失败: \(error)")
                    return Fail(error: AINetworkError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 移除角色个性化设置方法
} 