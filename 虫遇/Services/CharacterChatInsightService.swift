import Foundation
import SwiftData
import Combine

/**
 * 角色聊天画像服务
 * 基于用户与单个角色的一对一聊天，使用AI生成有趣的互动画像
 */
class CharacterChatInsightService: ObservableObject {
    static let shared = CharacterChatInsightService()
    
    @Published var isGenerating = false
    @Published var currentInsight: CharacterChatInsight?
    @Published var errorMessage: String?
    
    private let aiNetworkService = AINetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    private var retryCount = 0
    private let maxRetries = 2
    
    private init() {}
    
    /**
     * 生成角色聊天画像
     * @param characterId 角色ID
     * @param characterName 角色名称
     * @param limitDays 限制天数（默认30天）
     * @param maxMessages 最大消息数量（默认20条）
     * @param modelContext SwiftData上下文
     */
    func generateInsight(
        characterId: String,
        characterName: String,
        limitDays: Int = 30,
        maxMessages: Int = 20,
        modelContext: ModelContext,
        completion: @escaping (Result<CharacterChatInsight, Error>) -> Void
    ) {
        #if DEBUG
        debugLog("🎨 开始生成角色聊天画像 - 角色: \(characterName)")
        #endif
        
        DispatchQueue.main.async {
            self.isGenerating = true
            self.errorMessage = nil
            self.retryCount = 0  // 重置重试计数
        }
        
        // 1. 检查缓存
        if let cachedInsight = loadCachedInsight(characterId: characterId, modelContext: modelContext) {
            #if DEBUG
            debugLog("✅ 使用缓存的画像数据: \(cachedInsight.title)")
            #endif
            DispatchQueue.main.async {
                self.currentInsight = cachedInsight
                self.isGenerating = false
            }
            completion(.success(cachedInsight))
            return
        }
        
        // 2. 获取聊天消息
        let messages = fetchChatMessages(
            characterId: characterId,
            limitDays: limitDays,
            maxMessages: maxMessages,
            modelContext: modelContext
        )
        
        #if DEBUG
        debugLog("📊 获取到 \(messages.count) 条消息")
        #endif
        
        // 3. 检查数据是否足够
        guard messages.count >= 10 else {
            let errorMsg = "和\(characterName)的对话还不够多，再多聊聊吧～"
            let error = NSError(
                domain: "CharacterChatInsightService",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            )
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
                self.isGenerating = false
                // 在UI状态更新后再调用completion
                completion(.failure(error))
            }
            return
        }
        
        // 4. 构建提示词
        let prompt = buildPrompt(
            characterName: characterName,
            messages: messages
        )
        
        #if DEBUG
        debugLog("📝 提示词长度: \(prompt.count) 字符")
        #endif
        
        // 5. 调用AI
        #if DEBUG
        debugLog("🌐 开始调用AI服务...")
        #endif
        aiNetworkService.sendRequest(prompt: prompt)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] apiCompletion in
                    self?.isGenerating = false
                    if case .failure(let error) = apiCompletion {
                        Logger.error("画像生成失败", error: error, log: Logger.data)
                        self?.errorMessage = "生成失败: \(error.localizedDescription)"
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] response in
                    #if DEBUG
                    debugLog("📥 收到AI响应，长度: \(response.count) 字符")
                    #endif
                    self?.parseAndSaveInsight(
                        response: response,
                        characterId: characterId,
                        characterName: characterName,
                        messages: messages,
                        modelContext: modelContext,
                        completion: completion
                    )
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 获取聊天消息
     * 只获取最近的 maxMessages 条消息，包含用户和角色的对话
     */
    private func fetchChatMessages(
        characterId: String,
        limitDays: Int,
        maxMessages: Int,
        modelContext: ModelContext
    ) -> [Message] {
        let startDate = Calendar.current.date(byAdding: .day, value: -limitDays, to: Date()) ?? Date()
        
        do {
            // 获取与该角色的所有消息
            let predicate = #Predicate<Message> { message in
                (message.receiverId == characterId || message.senderId == characterId) &&
                message.timestamp >= startDate
            }
            
            let descriptor = FetchDescriptor<Message>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            var allMessages = try modelContext.fetch(descriptor)
            
            // 限制消息数量（取最近的 maxMessages 条消息）
            if allMessages.count > maxMessages {
                allMessages = Array(allMessages.prefix(maxMessages))
            }
            
            // 按时间正序排列（从旧到新）
            return allMessages.reversed()
            
        } catch {
            Logger.error("获取消息失败", error: error, log: Logger.data)
            return []
        }
    }
    
    /**
     * 构建AI提示词
     */
    private func buildPrompt(characterName: String, messages: [Message]) -> String {
        // 构建对话上下文
        var conversationLines: [String] = []
        
        for message in messages {
            let speaker = message.isFromUser ? "你" : characterName
            let content = message.content.count > 120 ? 
                String(message.content.prefix(120)) + "..." : 
                message.content
            conversationLines.append("\(speaker): \(content)")
        }
        
        let conversationContext = conversationLines.joined(separator: "\n")
        
        let systemPrompt = """
        你是一个洞察助手，专门分析用户与虚拟角色的聊天互动。
        
        【核心原则】
        1. 只依据提供的对话内容，不得编造或推测
        2. 输出必须是严格的JSON格式
        3. 语言风格轻松自然，像朋友聊天
        
        【任务】
        基于用户与\(characterName)的对话，生成一个有趣的互动画像。
        
        【输出JSON格式】
        {
          "title": "画像标题（<=12字，风格轻松有趣）",
          "summary": "一句话总结（80-120字，像朋友说话，不要文艺腔）",
          "tags": ["标签1", "标签2", "标签3"],
          "recentFocus": "最近聊的主题（1-2句话）",
          "nextSuggestion": "建议下次可以聊什么（1句话）"
        }
        
        【约束】
        - title: 简短有趣，比如"深夜思考家"、"好奇宝宝"、"话痨搭档"
        - summary: 用"你..."开头，描述用户的聊天风格和与角色的关系
        - tags: 3个词或短语，描述用户特点
        - recentFocus: 概括最近几次对话的主题
        - nextSuggestion: 给用户一个有趣的聊天建议
        
        【对话内容】
        \(conversationContext)
        
        【重要】
        - 只输出JSON，不要有任何其他文字
        - 不要使用markdown代码块（```json）
        - 直接输出纯JSON对象
        - 确保所有字符串都用双引号包裹
        - 确保JSON格式完全正确
        """
        
        return systemPrompt
    }
    
    /**
     * 解析并保存画像
     */
    private func parseAndSaveInsight(
        response: String,
        characterId: String,
        characterName: String,
        messages: [Message],
        modelContext: ModelContext,
        completion: @escaping (Result<CharacterChatInsight, Error>) -> Void
    ) {
        #if DEBUG
        debugLog("🔍 开始解析AI响应...")
        #endif
        
        // 尝试解析JSON
        guard let jsonData = extractJSON(from: response) else {
            #if DEBUG
            debugLog("❌ 无法提取JSON数据")
            #endif
            let error = NSError(
                domain: "CharacterChatInsightService",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "AI响应格式错误"]
            )
            DispatchQueue.main.async {
                self.errorMessage = "生成失败，请重试"
            }
            completion(.failure(error))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let aiResponse = try decoder.decode(CharacterChatInsightResponse.self, from: jsonData)
            
            #if DEBUG
            debugLog("✅ JSON解析成功")
            #endif
            
            // 构建最终的Insight对象
            let insight = CharacterChatInsight(
                title: aiResponse.title,
                summary: aiResponse.summary,
                tags: Array(aiResponse.tags.prefix(3)),
                recentFocus: aiResponse.recentFocus,
                nextSuggestion: aiResponse.nextSuggestion,
                characterId: characterId,
                characterName: characterName
            )
            
            // 保存到缓存 - 在主线程执行
            DispatchQueue.main.async {
                self.saveToCache(insight: insight, messages: messages, modelContext: modelContext)
                self.currentInsight = insight
                self.isGenerating = false
                #if DEBUG
                debugLog("✅ 画像生成完成")
                #endif
                completion(.success(insight))
            }
            
        } catch {
            #if DEBUG
            debugLog("❌ JSON解析失败: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    debugLog("❌ 缺少键: \(key.stringValue), 路径: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    debugLog("❌ 类型不匹配: 期望 \(type), 路径: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    debugLog("❌ 值不存在: \(type), 路径: \(context.codingPath)")
                case .dataCorrupted(let context):
                    debugLog("❌ 数据损坏: \(context.debugDescription)")
                @unknown default:
                    debugLog("❌ 未知解码错误")
                }
            }
            
            // 打印原始JSON用于调试
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                debugLog("📋 原始JSON: \(jsonString)")
            }
            #endif
            
            // 检查是否还能重试
            if retryCount < maxRetries {
                retryCount += 1
                #if DEBUG
                debugLog("🔄 第 \(retryCount) 次重试...")
                #endif
                
                // 尝试修复JSON
                attemptJSONRepair(
                    response: response,
                    characterId: characterId,
                    characterName: characterName,
                    messages: messages,
                    modelContext: modelContext,
                    completion: completion
                )
            } else {
                #if DEBUG
                debugLog("❌ 已达到最大重试次数")
                #endif
                let finalError = NSError(
                    domain: "CharacterChatInsightService",
                    code: 1003,
                    userInfo: [NSLocalizedDescriptionKey: "JSON解析失败，已重试\(maxRetries)次"]
                )
                DispatchQueue.main.async {
                    self.errorMessage = "生成失败，请稍后重试"
                    self.isGenerating = false
                }
                completion(.failure(finalError))
            }
        }
    }
    
    /**
     * 提取JSON数据
     */
    private func extractJSON(from response: String) -> Data? {
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除markdown代码块标记
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
        }
        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
        }
        if cleanedResponse.hasSuffix("```") {
            cleanedResponse = String(cleanedResponse.dropLast(3))
        }
        
        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试提取JSON块（从第一个{到最后一个}）
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            let jsonString = String(cleanedResponse[jsonStart...jsonEnd])
            
            // 打印提取的JSON用于调试
            #if DEBUG
            debugLog("📋 提取的JSON: \(jsonString.prefix(200))...")
            #endif
            
            return jsonString.data(using: .utf8)
        }
        
        // 如果没有找到{}，尝试直接转换
        if let data = cleanedResponse.data(using: .utf8) {
            return data
        }
        
        return nil
    }
    
    /**
     * 尝试修复JSON
     */
    private func attemptJSONRepair(
        response: String,
        characterId: String,
        characterName: String,
        messages: [Message],
        modelContext: ModelContext,
        completion: @escaping (Result<CharacterChatInsight, Error>) -> Void
    ) {
        #if DEBUG
        debugLog("🔧 尝试修复JSON...")
        #endif
        
        let repairPrompt = """
        以下是一个格式不正确的JSON响应，请修复它并返回正确的JSON。
        
        原始响应：
        \(response)
        
        要求的JSON格式：
        {
          "title": "字符串",
          "summary": "字符串",
          "tags": ["字符串数组"],
          "recentFocus": "字符串",
          "nextSuggestion": "字符串"
        }
        
        【重要】
        - 只输出修复后的JSON对象
        - 不要使用markdown代码块
        - 确保所有字符串都用双引号包裹
        - 确保JSON格式完全正确
        - 不要添加任何解释或其他文字
        """
        
        aiNetworkService.sendRequest(prompt: repairPrompt)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] apiCompletion in
                    if case .failure(let error) = apiCompletion {
                        Logger.error("JSON修复失败", error: error, log: Logger.data)
                        self?.errorMessage = "生成失败，请重试"
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] repairedResponse in
                    #if DEBUG
                    debugLog("🔧 收到修复后的响应")
                    #endif
                    self?.parseAndSaveInsight(
                        response: repairedResponse,
                        characterId: characterId,
                        characterName: characterName,
                        messages: messages,
                        modelContext: modelContext,
                        completion: completion
                    )
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 保存到缓存
     */
    private func saveToCache(
        insight: CharacterChatInsight,
        messages: [Message],
        modelContext: ModelContext
    ) {
        do {
            #if DEBUG
            debugLog("💾 CharacterChatInsightService - 开始保存缓存，角色ID: \(insight.characterId)")
            #endif
            
            let encoder = JSONEncoder()
            let insightData = try encoder.encode(insight)
            
            let lastMessageTimestamp = messages.last?.timestamp ?? Date()
            
            // 查找是否已有缓存
            let predicate = #Predicate<CharacterChatInsightCache> { cache in
                cache.characterId == insight.characterId
            }
            let descriptor = FetchDescriptor<CharacterChatInsightCache>(predicate: predicate)
            let existingCaches = try modelContext.fetch(descriptor)
            
            #if DEBUG
            debugLog("📊 CharacterChatInsightService - 保存前查找，找到 \(existingCaches.count) 个现有缓存")
            #endif
            
            if let existingCache = existingCaches.first {
                // 更新现有缓存
                existingCache.insightData = insightData
                existingCache.generatedAt = Date()
                existingCache.messageCount = messages.count
                existingCache.lastMessageTimestamp = lastMessageTimestamp
                #if DEBUG
                debugLog("✅ 更新现有缓存")
                #endif
            } else {
                // 创建新缓存
                let cache = CharacterChatInsightCache(
                    id: insight.characterId,
                    characterId: insight.characterId,
                    characterName: insight.characterName,
                    insightData: insightData,
                    messageCount: messages.count,
                    lastMessageTimestamp: lastMessageTimestamp
                )
                modelContext.insert(cache)
                #if DEBUG
                debugLog("✅ 创建新缓存，ID: \(cache.id)")
                #endif
            }
            
            try modelContext.save()
            #if DEBUG
            debugLog("💾 CharacterChatInsightService - 缓存已保存到数据库")
            #endif
            
            // 立即验证缓存是否保存成功
            let verifyPredicate = #Predicate<CharacterChatInsightCache> { cache in
                cache.characterId == insight.characterId
            }
            let verifyDescriptor = FetchDescriptor<CharacterChatInsightCache>(predicate: verifyPredicate)
            let savedCaches = try modelContext.fetch(verifyDescriptor)
            #if DEBUG
            debugLog("🔍 CharacterChatInsightService - 保存后立即验证，找到 \(savedCaches.count) 个缓存记录")
            
            if let savedCache = savedCaches.first {
                debugLog("✅ 验证成功 - 缓存ID: \(savedCache.id), 生成时间: \(savedCache.generatedAt)")
            }
            #endif
            
        } catch {
            Logger.error("保存缓存失败", error: error, log: Logger.data)
            #if DEBUG
            if let swiftDataError = error as? any LocalizedError {
                debugLog("❌ SwiftData错误详情: \(swiftDataError.errorDescription ?? "未知错误")")
            }
            #endif
        }
    }
    
    /**
     * 加载缓存的画像
     */
    func loadCachedInsight(
        characterId: String,
        modelContext: ModelContext
    ) -> CharacterChatInsight? {
        do {
            #if DEBUG
            debugLog("🔍 CharacterChatInsightService - 查找角色缓存: \(characterId)")
            #endif
            
            let predicate = #Predicate<CharacterChatInsightCache> { cache in
                cache.characterId == characterId
            }
            let descriptor = FetchDescriptor<CharacterChatInsightCache>(predicate: predicate)
            let caches = try modelContext.fetch(descriptor)
            
            #if DEBUG
            debugLog("📊 CharacterChatInsightService - 找到 \(caches.count) 个缓存记录")
            #endif
            
            guard let cache = caches.first else {
                #if DEBUG
                debugLog("⚠️ CharacterChatInsightService - 未找到缓存记录")
                #endif
                return nil
            }
            
            // 检查缓存是否过期（24小时）
            let hoursSinceGeneration = Date().timeIntervalSince(cache.generatedAt) / 3600
            #if DEBUG
            debugLog("⏰ CharacterChatInsightService - 缓存生成时间: \(cache.generatedAt), 距今 \(String(format: "%.1f", hoursSinceGeneration)) 小时")
            #endif
            
            if hoursSinceGeneration > 24 {
                #if DEBUG
                debugLog("⏰ 缓存已过期")
                #endif
                return nil
            }
            
            // 检查是否有新消息（超过10条）
            let currentMessageCount = countMessages(characterId: characterId, modelContext: modelContext)
            #if DEBUG
            debugLog("📬 CharacterChatInsightService - 当前消息数: \(currentMessageCount), 缓存时消息数: \(cache.messageCount)")
            #endif
            
            if currentMessageCount - cache.messageCount >= 10 {
                #if DEBUG
                debugLog("📬 有新消息，需要重新生成")
                #endif
                return nil
            }
            
            // 解码缓存数据
            let decoder = JSONDecoder()
            let insight = try decoder.decode(CharacterChatInsight.self, from: cache.insightData)
            
            #if DEBUG
            debugLog("✅ CharacterChatInsightService - 成功加载缓存画像: \(insight.title)")
            #endif
            return insight
            
        } catch {
            Logger.error("加载缓存失败", error: error, log: Logger.data)
            return nil
        }
    }
    
    /**
     * 统计消息数量
     */
    private func countMessages(characterId: String, modelContext: ModelContext) -> Int {
        do {
            let predicate = #Predicate<Message> { message in
                message.receiverId == characterId || message.senderId == characterId
            }
            let descriptor = FetchDescriptor<Message>(predicate: predicate)
            let messages = try modelContext.fetch(descriptor)
            return messages.count
        } catch {
            return 0
        }
    }
    
    /**
     * 清除缓存
     */
    func clearCache(characterId: String, modelContext: ModelContext) {
        do {
            let predicate = #Predicate<CharacterChatInsightCache> { cache in
                cache.characterId == characterId
            }
            let descriptor = FetchDescriptor<CharacterChatInsightCache>(predicate: predicate)
            let caches = try modelContext.fetch(descriptor)
            
            for cache in caches {
                modelContext.delete(cache)
            }
            
            try modelContext.save()
            #if DEBUG
            debugLog("✅ 缓存已清除")
            #endif
            
        } catch {
            Logger.error("清除缓存失败", error: error, log: Logger.data)
        }
    }
}

