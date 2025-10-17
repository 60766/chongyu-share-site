import Foundation
import Combine
import UIKit

// 定义多角色聊天服务专用的用户角色类型
enum MultiChatUserRole: Equatable, Hashable {
    case observer                    // 观察者模式
}

/**
 * 多角色聊天服务
 * 用于多人聊天模式中批量生成多个虚拟角色的消息，共用一次API调用
 * 优化成本和响应速度
 */
class MultiCharacterChatService {
    // 单例实例
    static let shared = MultiCharacterChatService()
    
    // 依赖的服务
    private let characterDataManager = CharacterDataManager.shared
    private let personalityManager = CharacterPersonalityManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // 私有初始化方法
    private init() {}
    
    /**
     * 批量生成多个角色的聊天消息
     * @param characters 参与聊天的角色列表
     * @param conversationHistory 对话历史
     * @param userMessage 用户最新消息（可选）
     * @param chatTheme 聊天主题
     * @param maxResponders 最大回复角色数量，默认为2-3个
     * @param userRole 用户角色（观察者或参与者）
     * @param completion 完成回调，返回按顺序排列的角色回复
     */
    func generateMultiCharacterChat(
        characters: [CharacterModel],
        conversationHistory: [ChatMessage],
        userMessage: String? = nil,
        chatTheme: String,
        maxResponders: Int = 3,
        userRole: MultiChatUserRole,
        completion: @escaping (Result<[(characterId: String, content: String)], Error>) -> Void
    ) {
        print("🚀 开始批量生成聊天消息 - 主题: \(chatTheme)")
        
        // 创建后台任务
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ MultiCharacterChatService: 批量生成聊天消息的后台任务超时")
        }
        
        // 选择参与回复的角色
        let respondingCharacters = selectRespondingCharacters(
            from: characters,
            maxCount: maxResponders,
            conversationHistory: conversationHistory,
            userRole: userRole
        )
        
        print("📝 选择了\(respondingCharacters.count)个角色参与回复")
        
        // 构建角色信息
        let characterInfo = buildCharacterInfos(respondingCharacters)
        
        // 构建对话上下文
        let conversationContext = buildConversationContext(conversationHistory)
        
        // 构建提示词
        let prompt = buildChatPrompt(
            characters: respondingCharacters,
            characterInfo: characterInfo,
            conversationContext: conversationContext,
            userMessage: userMessage,
            chatTheme: chatTheme,
            userRole: userRole
        )
        
        print("📤 发送批量聊天生成请求")
        
        // 调用AI服务
        AINetworkService.shared.sendRequest(prompt: prompt)
            .sink(
                receiveCompletion: { completionStatus in
                    // 结束后台任务
                    if backgroundTaskID != .invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                    
                    if case .failure(let error) = completionStatus {
                        print("❌ 批量聊天生成失败: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] response in
                    print("✅ 批量聊天生成成功，开始解析回复")
                    print("📊 API响应统计: 长度=\(response.count)字符")
                    
                    guard let self = self else {
                        completion(.failure(NSError(domain: "MultiCharacterChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service was deallocated"])))
                        return
                    }
                    
                    // 🔧 稳健性检查：确保API响应不为空
                    if response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        print("❌ API返回了空响应")
                        completion(.failure(NSError(domain: "MultiCharacterChatService", code: -2, userInfo: [NSLocalizedDescriptionKey: "API返回了空响应"])))
                        return
                    }
                    
                    let parsedReplies = self.parseMultiCharacterResponse(
                        response: response,
                        expectedCharacters: respondingCharacters
                    )
                    
                    // 🔧 最终验证：确保至少有一个有效回复
                    if parsedReplies.isEmpty {
                        print("❌ 解析失败：无法从API响应中提取任何有效回复")
                        print("📄 原始响应内容: \(response)")
                        completion(.failure(NSError(domain: "MultiCharacterChatService", code: -3, userInfo: [
                            NSLocalizedDescriptionKey: "解析失败：无法从API响应中提取有效回复",
                            "originalResponse": response
                        ])))
                        return
                    }
                    
                    print("🎉 解析成功：获得\(parsedReplies.count)个有效角色回复")
                    completion(.success(parsedReplies))
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 选择参与回复的角色
     */
    private func selectRespondingCharacters(
        from characters: [CharacterModel],
        maxCount: Int,
        conversationHistory: [ChatMessage],
        userRole: MultiChatUserRole
    ) -> [CharacterModel] {
        // 观察者模式下，所有角色都可参与对话
        let availableCharacters = characters
        
        // 如果没有可用角色，返回空数组
        guard !availableCharacters.isEmpty else { return [] }
        
        // 分析最近的发言者，避免连续发言
        let recentSpeakers = conversationHistory.suffix(3).compactMap { message in
            availableCharacters.first { $0.id == message.characterId }
        }
        
        // 优先选择最近没有发言的角色
        let nonRecentSpeakers = availableCharacters.filter { character in
            !recentSpeakers.contains { $0.id == character.id }
        }
        
        var selectedCharacters: [CharacterModel] = []
        
        // 首先从非最近发言者中选择
        if !nonRecentSpeakers.isEmpty {
            let count = min(maxCount, nonRecentSpeakers.count)
            selectedCharacters = Array(nonRecentSpeakers.shuffled().prefix(count))
        }
        
        // 如果还需要更多角色，从最近发言者中补充
        if selectedCharacters.count < maxCount && selectedCharacters.count < availableCharacters.count {
            let remaining = maxCount - selectedCharacters.count
            let additionalCharacters = recentSpeakers.filter { character in
                !selectedCharacters.contains { $0.id == character.id }
            }
            selectedCharacters.append(contentsOf: Array(additionalCharacters.prefix(remaining)))
        }
        
        return selectedCharacters
    }
    
    /**
     * 构建角色信息字符串
     */
    private func buildCharacterInfos(_ characters: [CharacterModel]) -> String {
        return characters.map { character in
            let name = character.name
            let description = character.bio
            let personality = "智慧而深刻"  // 简洁版本：使用统一描述，个性化调整会在提示词中体现
            
            return """
            [\(character.id)] \(name) （@时使用中文名：@\(name)）
            - 背景：\(description)
            - 特点：\(personality)
            """
        }.joined(separator: "\n\n")
    }
    
    /**
     * 构建对话上下文
     */
    private func buildConversationContext(_ messages: [ChatMessage]) -> String {
        // 只取最近的5-8条消息作为上下文
        let recentMessages = Array(messages.suffix(8))
        
        return recentMessages.map { message in
            let speakerName = getCharacterName(for: message.characterId)
            return "\(speakerName): \(message.content)"
        }.joined(separator: "\n")
    }
    
    /**
     * 根据角色ID获取角色名称
     */
    private func getCharacterName(for characterId: String) -> String {
        if characterId == "user" {
            return "用户"
        }
        return characterDataManager.getName(for: characterId) ?? characterId.capitalized
    }
    
    /**
     * 构建聊天提示词
     */
    private func buildChatPrompt(
        characters: [CharacterModel],
        characterInfo: String,
        conversationContext: String,
        userMessage: String?,
        chatTheme: String,
        userRole: MultiChatUserRole
    ) -> String {
        var prompt = """
        你正在主持一个跨时空的多人聊天对话。以下角色正在参与讨论：

        角色信息：
        \(characterInfo)

        聊天主题：\(chatTheme)

        """
        
        if !conversationContext.isEmpty {
            prompt += """
            
            最近的对话历史：
            \(conversationContext)
            
            """
        }
        
        if let userMessage = userMessage {
            prompt += """
            
            🔥 用户刚刚说："\(userMessage)"
            
            🚨 绝对强制要求：用户是这个对话的中心！
            
            ⚠️ 所有角色都必须直接回应用户，产生以下反应：
            - 🎯 每个角色都要直接对用户说话，不要和其他角色对话
            - 💭 从各自的人生经历出发，直接回应用户的观点
            - 🔍 结合自己的阅历，直接对用户表达认同、质疑或建议
            - 💡 向用户分享相关的人生体验，让用户感受到被理解或被挑战
            - 🗣️ 用"你"来称呼用户，表现出在和用户直接对话
            - ❌ 严禁角色之间互相对话，严禁@其他角色
            - ❌ 严禁回复其他角色的观点，只能回应用户
            
            用户的话就是这轮对话的唯一焦点！每个角色都要直接对用户表达自己的态度！
            
            """
        }
        
        prompt += """
        
        ⭐ 核心使命：紧扣主题"\(chatTheme)"，避免偏离话题！
        
        让这些角色基于内心经历对话题进行真实交流，源于内心驱动而非任务要求：

        核心要求：
        1. 必须围绕主题"\(chatTheme)"展开，直接对用户分享具体的人生经历和感受
        2. 从人生阅历、价值观核心出发，找到与话题的深度连接，并告诉用户
        3. 当核心信念被触动时，直接向用户表达自己的立场和态度
        4. 对用户的观点产生真实情感反应：认同、质疑、反驳或共鸣
        5. 因真正在乎而向用户坚持表达自己的观点
        6. 🚨 严禁回应其他角色，只能直接对用户说话
        7. 🚨 避免抽象讨论，要向用户分享具体的人生故事和真实感受
        
        表达要求：
        - 每个回复15-45字，言简意赅但有情感重量
        - 体现角色独特的生命体验和思维方式，直接对用户说
        - 可用讽刺、反问、挑战等方式直接回应用户
        - 避免客套话，向用户表达内心最真实的声音
        - 让每句话都有分量，能让用户感受到被理解或被挑战
        - 说出只有这个角色才会对用户说的话
        - 🚨 必须用"你"来称呼用户，表现出在直接对话
        
        🎭 真实群聊行为（让角色更有活人感）：
        - 😏 吃瓜围观："哦？这么刺激的吗？"、"说来听听"
        - 🔥 起哄煽风："就是就是！"、"我支持你！"、"太对了！"
        - 🤔 抬杠质疑："真的假的？"、"我觉得不对吧"、"有证据吗？"
        - 😅 调侃玩梗："哈哈哈笑死"、"你这话说的"、"太逗了"
        - 🙄 略带偏见：基于时代背景的固有观念和局限性
        - 😤 情绪激动："气死我了！"、"太过分了！"、"不能忍！"
        - 🤨 表示怀疑："我不信"、"扯淡"、"你骗谁呢"
        - 😎 忍不住炫耀："我当年..."、"这个我熟"、"说起这个..."
        - 🥱 兴趣缺失："哦"、"还行吧"、"无所谓"
        - 💭 话题跑偏：从用户的话联想到自己完全不相关的经历
        
        ⚠️ 注意：这些行为要符合角色身份，不要过度使用，保持真实感

        请按照以下格式生成回复：

        [角色ID]
        这里是该角色犀利、真实的回复内容...

        [下一个角色ID]
        这里是下一个角色针锋相对的回复内容...

        格式要求：
        - 🚨必须使用角色信息中的英文ID，如[tolstoy]、[marquez]、[kawabata]、[libai]
        - 🚨禁止使用中文名称，如[托尔斯泰]、[川端康成]、[列夫·托尔斯泰]
        - 严格按照[角色ID]方括号格式，不添加额外标点
        - 🚨严禁@其他角色，只能直接对用户说话
        - 🚨每个角色都要用"你"来称呼用户，表现出在和用户直接对话
        - 基于内心信念向用户展现强烈个性和立场
        """
        
        return prompt
    }
    
    /**
     * 标准化角色ID - 处理常见变体和错误
     */
    private func normalizeCharacterId(_ rawId: String, expectedCharacters: [CharacterModel]) -> String? {
        let normalizedInput = rawId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 尝试匹配角色ID: '\(rawId)' (标准化后: '\(normalizedInput)')")
        
        // 1. 直接匹配
        if let character = expectedCharacters.first(where: { $0.id.lowercased() == normalizedInput }) {
            print("✅ 直接匹配角色ID: \(rawId) -> \(character.id)")
            return character.id
        }
        
        // 2. 常见变体匹配
        let idMappings: [String: String] = [
            "wall-e": "walle",
            "wall_e": "walle", 
            "wan-li": "walle",
            "瓦力": "walle",
            "li-bai": "libai",
            "li_bai": "libai",
            "李白": "libai",
            "sun-wukong": "sunwukong",
            "sun_wukong": "sunwukong", 
            "孙悟空": "sunwukong",
            "tang-sanzang": "tangsanzang",
            "tang_sanzang": "tangsanzang",
            "唐三藏": "tangsanzang",
            "yang-guo": "yangguo",
            "yang_guo": "yangguo",
            "杨过": "yangguo",
            "nikola_tesla": "tesla",
            "nikola-tesla": "tesla",
            "尼古拉·特斯拉": "tesla",
            "尼古拉特斯拉": "tesla",
            "特斯拉": "tesla"
        ]
        
        if let standardId = idMappings[normalizedInput] {
            if expectedCharacters.contains(where: { $0.id == standardId }) {
                print("✅ 变体匹配角色ID: \(rawId) -> \(standardId)")
                return standardId
            }
        }
        
        // 3. 按名称匹配
        if let character = expectedCharacters.first(where: { $0.name.lowercased().contains(normalizedInput) || normalizedInput.contains($0.name.lowercased()) }) {
            print("✅ 名称匹配角色ID: \(rawId) -> \(character.id)")
            return character.id
        }
        
        // 4. 模糊匹配（编辑距离）
        for character in expectedCharacters {
            if editDistance(normalizedInput, character.id.lowercased()) <= 2 {
                print("✅ 模糊匹配角色ID: \(rawId) -> \(character.id)")
                return character.id
            }
        }
        
        print("⚠️ 无法匹配角色ID: \(rawId)")
        return nil
    }
    
    /**
     * 计算编辑距离
     */
    private func editDistance(_ s1: String, _ s2: String) -> Int {
        let len1 = s1.count
        let len2 = s2.count
        
        if len1 == 0 { return len2 }
        if len2 == 0 { return len1 }
        
        var dp = Array(repeating: Array(repeating: 0, count: len2 + 1), count: len1 + 1)
        
        for i in 0...len1 { dp[i][0] = i }
        for j in 0...len2 { dp[0][j] = j }
        
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = Array(s1)[i-1] == Array(s2)[j-1] ? 0 : 1
                dp[i][j] = min(
                    dp[i-1][j] + 1,      // 删除
                    dp[i][j-1] + 1,      // 插入
                    dp[i-1][j-1] + cost  // 替换
                )
            }
        }
        
        return dp[len1][len2]
    }
    
    /**
     * 解析多角色回复
     */
    private func parseMultiCharacterResponse(
        response: String,
        expectedCharacters: [CharacterModel]
    ) -> [(characterId: String, content: String)] {
        print("🔍 开始解析多角色回复，响应长度: \(response.count)")
        print("📝 期望角色列表(\(expectedCharacters.count)个): \(expectedCharacters.map { "\($0.name)(\($0.id))" }.joined(separator: ", "))")
        print("📝 原始API响应内容:\n\(response)")
        
        var result: [(characterId: String, content: String)] = []
        let lines = response.components(separatedBy: .newlines)
        
        var currentCharacterId: String?
        var currentContent: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查是否是角色ID行
            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                // 保存之前的角色回复
                if let characterId = currentCharacterId, !currentContent.isEmpty {
                    let content = currentContent.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !content.isEmpty {
                        result.append((characterId: characterId, content: content))
                        print("✅ 解析到角色回复: \(characterId) -> \(content.prefix(30))...")
                    }
                }
                
                // 开始新的角色回复
                let extractedId = String(trimmedLine.dropFirst().dropLast())
                // 🔧 增强角色ID匹配：支持常见变体和容错
                if let normalizedId = normalizeCharacterId(extractedId, expectedCharacters: expectedCharacters) {
                    currentCharacterId = normalizedId
                    currentContent = []
                } else {
                    // 如果无法匹配，跳过这个角色
                    print("❌ 跳过无法匹配的角色ID: \(extractedId)")
                    currentCharacterId = nil
                currentContent = []
                }
            } else if !trimmedLine.isEmpty && currentCharacterId != nil {
                // 添加到当前角色的回复内容
                currentContent.append(trimmedLine)
            }
        }
        
        // 处理最后一个角色的回复
        if let characterId = currentCharacterId, !currentContent.isEmpty {
            let content = currentContent.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                result.append((characterId: characterId, content: content))
                print("✅ 解析到最后一个角色回复: \(characterId) -> \(content.prefix(30))...")
            }
        }
        
        print("📊 标准解析完成，共获得 \(result.count) 个角色回复")
        
        // 🔧 稳健性增强：如果标准解析失败或结果不足，尝试备用解析方法
        if result.isEmpty || result.count < min(expectedCharacters.count, 2) {
            print("⚠️ 标准解析结果不满意，尝试备用解析方法...")
            result = fallbackParseResponse(response: response, expectedCharacters: expectedCharacters)
        }
        
        // 🔧 最终验证：确保每个角色的回复都有有效内容
        result = validateAndEnhanceResponses(result, expectedCharacters: expectedCharacters, originalResponse: response)
        
        print("🎯 最终解析结果: \(result.count) 个有效角色回复")
        return result
    }
    
    /**
     * 备用解析方法 - 使用更宽松的规则解析API响应
     * 当标准解析失败时使用，确保不浪费API费用
     */
    private func fallbackParseResponse(
        response: String,
        expectedCharacters: [CharacterModel]
    ) -> [(characterId: String, content: String)] {
        print("🔄 执行备用解析方法...")
        
        var result: [(characterId: String, content: String)] = []
        
        // 方法1：尝试基于角色名称的模糊匹配
        for character in expectedCharacters {
            let characterNames = [character.id, character.name].compactMap { $0 }
            
            for name in characterNames {
                // 使用正则表达式查找角色名称后的内容
                let patterns = [
                    "\(name)[：:][\\s\\n]*([^\\n]+(?:\\n[^\\[]*)*)",  // 角色名:内容
                    "\\[\(character.id)\\][\\s\\n]*([^\\[]+)",        // [角色ID]内容
                    "\\[\(name)\\][\\s\\n]*([^\\[]+)",               // [角色名]内容
                    "\(name)[\\s\\n]+([^\\n]+(?:\\n[^\\[]*)*)"       // 角色名 内容
                ]
                
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                        let nsRange = NSRange(response.startIndex..<response.endIndex, in: response)
                        if let match = regex.firstMatch(in: response, options: [], range: nsRange),
                           let contentRange = Range(match.range(at: 1), in: response) {
                            let content = String(response[contentRange])
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !content.isEmpty && content.count > 5 { // 至少5个字符
                                result.append((characterId: character.id, content: content))
                                print("🔄 备用解析找到: \(character.id) -> \(content.prefix(30))...")
                                break // 找到一个就跳出pattern循环
                            }
                        }
                    }
                }
                
                if result.contains(where: { $0.characterId == character.id }) {
                    break // 已找到该角色的回复，跳出name循环
                }
            }
        }
        
        // 方法2：如果方法1失败，尝试按段落分割
        if result.isEmpty {
            print("🔄 尝试按段落分割解析...")
            let paragraphs = response.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count > 10 }
            
            for (index, paragraph) in paragraphs.enumerated() {
                if index < expectedCharacters.count {
                    let character = expectedCharacters[index]
                    // 移除可能的角色标识符
                    let cleanContent = paragraph
                        .replacingOccurrences(of: "^\\[.*?\\]\\s*", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "^\(character.name)[：:\\s]+", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !cleanContent.isEmpty {
                        result.append((characterId: character.id, content: cleanContent))
                        print("🔄 段落解析找到: \(character.id) -> \(cleanContent.prefix(30))...")
                    }
                }
            }
        }
        
        print("🔄 备用解析完成，获得 \(result.count) 个角色回复")
        return result
    }
    
    /**
     * 验证和增强解析结果
     * 确保每个角色都有合理的回复内容
     */
    private func validateAndEnhanceResponses(
        _ responses: [(characterId: String, content: String)],
        expectedCharacters: [CharacterModel],
        originalResponse: String
    ) -> [(characterId: String, content: String)] {
        print("🔍 验证解析结果...")
        
        var validatedResponses = responses
        
        // 1. 过滤掉太短或无意义的回复
        validatedResponses = validatedResponses.filter { response in
            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let isValid = content.count >= 5 && // 至少5个字符
                         !content.contains("抱歉") && // 过滤错误信息
                         !content.contains("无法") &&
                         !content.contains("请稍后") &&
                         !content.lowercased().contains("error") &&
                         !content.lowercased().contains("sorry")
            
            if !isValid {
                print("⚠️ 过滤无效回复: \(response.characterId) -> \(content.prefix(30))...")
            }
            
            return isValid
        }
        
        // 2. 如果解析结果仍然为空，但API确实返回了内容，生成紧急回复
        if validatedResponses.isEmpty && !originalResponse.isEmpty && originalResponse.count > 50 {
            print("🚨 紧急情况：API返回了内容但解析完全失败，生成应急回复")
            
            // 为前两个角色生成基于原始内容的应急回复
            let emergencyCharacters = Array(expectedCharacters.prefix(2))
            for (index, character) in emergencyCharacters.enumerated() {
                let emergencyContent = generateEmergencyResponse(
                    for: character,
                    based: originalResponse,
                    index: index
                )
                validatedResponses.append((characterId: character.id, content: emergencyContent))
                print("🚨 生成应急回复: \(character.id) -> \(emergencyContent.prefix(30))...")
            }
        }
        
        // 3. 🔧 修复：允许多轮对话，不限制回复数量为角色数量
        // 移除之前的数量限制，保留所有有效回复
        print("📊 多轮对话模式：保留所有 \(validatedResponses.count) 个有效回复")
        
        print("✅ 验证完成，最终有效回复数: \(validatedResponses.count)")
        return validatedResponses
    }
    
    /**
     * 生成应急回复 - 当解析完全失败时使用
     * 基于API原始响应和角色特点生成合理的回复
     */
    private func generateEmergencyResponse(
        for character: CharacterModel,
        based originalResponse: String,
        index: Int
    ) -> String {
        // 提取原始响应中的关键词和情感
        let keywords = extractKeywords(from: originalResponse)
        let _ = analyzeSentiment(from: originalResponse) // 暂时不使用sentiment分析
        
        // 根据角色特点生成应急回复
        let baseResponses: [String]
        
        switch character.id {
        case "einstein", "爱因斯坦":
            baseResponses = [
                "从科学的角度来看，这个问题值得深入思考。",
                "想象力比知识更重要，让我们用不同的视角来看待这个问题。",
                "相对性理论告诉我们，观察者的位置决定了观察的结果。"
            ]
        case "davinci", "达芬奇":
            baseResponses = [
                "作为艺术家和科学家，我认为这个话题融合了美与真理。",
                "观察自然，我们可以找到所有问题的答案。",
                "艺术与科学在这里找到了完美的结合点。"
            ]
        case "shakespeare", "莎士比亚":
            baseResponses = [
                "人生如戏，这个话题正如我剧作中探讨的人性主题。",
                "语言的力量在于它能表达最深层的情感和思想。",
                "这让我想起了我在作品中描绘的人物内心世界。"
            ]
        case "kongzi", "孔子":
            baseResponses = [
                "君子应当在这个问题上保持中庸之道。",
                "学而时习之，这个话题值得我们反复思考。",
                "仁者见仁，智者见智，每个人都有自己的理解。"
            ]
        default:
            baseResponses = [
                "这是一个很有趣的观点，值得我们深入讨论。",
                "从我的角度来看，这个问题有多个层面需要考虑。",
                "我认为我们需要更全面地思考这个话题。"
            ]
        }
        
        // 添加基于关键词的个性化内容
        var selectedResponse = baseResponses[index % baseResponses.count]
        
        if let keyword = keywords.first {
            selectedResponse += "关于\(keyword)，我有不同的看法。"
        }
        
        return selectedResponse
    }
    
    /**
     * 从文本中提取关键词
     */
    private func extractKeywords(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 2 }
        
        return Array(Set(words)).prefix(3).map { String($0) }
    }
    
    /**
     * 简单的情感分析
     */
    private func analyzeSentiment(from text: String) -> String {
        let positiveWords = ["好", "棒", "优秀", "赞", "支持", "同意"]
        let negativeWords = ["不", "反对", "错误", "问题", "困难"]
        
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + text.components(separatedBy: word).count - 1
        }
        
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + text.components(separatedBy: word).count - 1
        }
        
        if positiveCount > negativeCount {
            return "positive"
        } else if negativeCount > positiveCount {
            return "negative"
        } else {
            return "neutral"
        }
    }
} 