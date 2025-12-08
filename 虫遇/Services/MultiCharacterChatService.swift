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
        userName: String? = nil,
        completion: @escaping (Result<[(characterId: String, content: String)], Error>) -> Void
    ) {
        #if DEBUG
        debugLog("🚀 开始批量生成聊天消息 - 主题: \(chatTheme)")
        #endif
        
        // 创建后台任务
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            #if DEBUG
            debugLog("⚠️ MultiCharacterChatService: 批量生成聊天消息的后台任务超时")
            #endif
        }
        
        // 选择参与回复的角色
        let respondingCharacters = selectRespondingCharacters(
            from: characters,
            maxCount: maxResponders,
            conversationHistory: conversationHistory,
            userRole: userRole
        )
        
        #if DEBUG
        debugLog("📝 选择了\(respondingCharacters.count)个角色参与回复")
        #endif
        
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
            userRole: userRole,
            userName: userName
        )
        
        #if DEBUG
        debugLog("📤 发送批量聊天生成请求")
        #endif
        
        // 调用AI服务
        AINetworkService.shared.sendRequest(prompt: prompt)
            .sink(
                receiveCompletion: { completionStatus in
                    // 结束后台任务
                    if backgroundTaskID != .invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                    
                    if case .failure(let error) = completionStatus {
                        Logger.error("批量聊天生成失败", error: error, log: Logger.data)
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] response in
                    #if DEBUG
                    debugLog("✅ 批量聊天生成成功，开始解析回复")
                    debugLog("📊 API响应统计: 长度=\(response.count)字符")
                    #endif
                    
                    guard let self = self else {
                        completion(.failure(NSError(domain: "MultiCharacterChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service was deallocated"])))
                        return
                    }
                    
                    // 🔧 稳健性检查：确保API响应不为空
                    if response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        #if DEBUG
                        debugLog("❌ API返回了空响应")
                        #endif
                        completion(.failure(NSError(domain: "MultiCharacterChatService", code: -2, userInfo: [NSLocalizedDescriptionKey: "API返回了空响应"])))
                        return
                    }
                    
                    let parsedReplies = self.parseMultiCharacterResponse(
                        response: response,
                        expectedCharacters: respondingCharacters
                    )
                    
                    // 🔧 最终验证：确保至少有一个有效回复
                    if parsedReplies.isEmpty {
                        #if DEBUG
                        debugLog("❌ 解析失败：无法从API响应中提取任何有效回复")
                        debugLog("📄 原始响应内容: \(response)")
                        #endif
                        completion(.failure(NSError(domain: "MultiCharacterChatService", code: -3, userInfo: [
                            NSLocalizedDescriptionKey: "解析失败：无法从API响应中提取有效回复",
                            "originalResponse": response
                        ])))
                        return
                    }
                    
                    #if DEBUG
                    debugLog("🎉 解析成功：获得\(parsedReplies.count)个有效角色回复")
                    #endif
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
        userRole: MultiChatUserRole,
        userName: String?
    ) -> String {
        // 获取用户显示名称，如果没有则使用"你"
        let userDisplayName = userName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "你"
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
            
            🔥 \(userDisplayName)刚刚说："\(userMessage)"
            
            """
        }
        
        prompt += """
        
        ⭐ 核心使命：紧扣主题"\(chatTheme)"，围绕话题进行真实的群聊互动！
        
        让这些角色基于内心经历对话题进行真实交流，就像真实的群聊一样：

        核心要求：
        1. 必须围绕主题"\(chatTheme)"展开讨论，可以回应\(userDisplayName)，也可以和其他角色互动
        2. 从人生阅历、价值观核心出发，找到与话题的深度连接
        3. 当核心信念被触动时，可以表达自己的立场，也可以和其他角色争论或共鸣
        4. 对\(userDisplayName)或其他角色的观点产生真实情感反应：认同、质疑、反驳或共鸣
        5. 因真正在乎而坚持表达自己的观点，可以和其他角色产生思想碰撞
        6. ✅ 鼓励角色之间互相交流、争论、支持、质疑，就像真实群聊一样
        7. ✅ 可以@其他角色，回应其他角色的观点，产生对话和互动
        8. ✅ 避免抽象讨论，要分享具体的人生故事和真实感受
        9. 🎯 重要：对话要有趣、多样化！不要总是沉重的话题，可以轻松、幽默、调侃、玩梗
        10. 🎯 不要总是@别人，大部分时候直接表达观点就好，@只在需要特别回应时才用
        11. 🎯 避免"比惨"模式，不要总是谈论牺牲和痛苦，可以分享有趣经历、观点碰撞、轻松调侃
        12. 🎯 回复长度要多样化！可以有一些简短回应（5-15字），如"确实"、"哈哈哈"、"这比喻绝了"，也可以有深度讨论（20-45字），让对话更有节奏感
        13. 🎯 用更生活化的语言，像真实群聊一样，不要总是学术腔调或书面语，可以用口语化表达
        
        表达要求：
        - 回复长度要多样化：可以简短（5-15字），如"确实"、"哈哈哈"、"这比喻绝了"，也可以深度讨论（20-45字），让对话更有节奏感
        - 不要总是长篇大论，增加一些简短、即时的回应，让对话更自然
        - 🚨🚨🚨 绝对禁止标注字数！回复内容中不要出现任何形式的字数标注，如"(28字)"、"(23字)"、"28字"等
        - 体现角色独特的生命体验和思维方式
        - 可用讽刺、反问、挑战等方式回应
        - 避免客套话，表达内心最真实的声音
        - 让每句话都有分量，能引起共鸣或争论
        - 说出只有这个角色才会说的话
        - 🎯 重要：回复长度要多样化！可以有一些简短回应（5-15字），如"确实"、"哈哈哈"、"这比喻绝了"、"我不这么认为"，也可以有深度讨论（20-45字）
        - 🎯 不要总是长篇大论，增加一些简短、即时的回应，让对话更有节奏感
        - 🎯 用更生活化的语言，像真实群聊一样，不要总是学术腔调或书面语
        - 🎯 对话要多样化：可以深度讨论，也可以轻松调侃；可以分享痛苦，也可以分享快乐；可以严肃，也可以幽默
        - 🎯 不要总是@别人，大部分时候直接表达观点，@只在需要特别回应或引起注意时才用
        - 🎯 避免总是谈论沉重话题，增加轻松、有趣、有争议性的讨论
        - 🎯 轻松调侃时保持简短，不要"哈哈哈"后面还长篇大论，要真正轻松有趣
        - 🎯 可以更生活化，用日常语言表达，不要总是学术腔调
        - 🎯 称呼参与者时：
          * 🚨🚨🚨 重要：不要总是称呼参与者的名字！大部分时候直接表达观点就好，像真实群聊一样自然
          * 参与者的名字是"\(userDisplayName)"，但只有在非常必要时（比如需要特别强调、直接回应或引起注意）才使用这个名字
          * 大部分时候直接说"你"或直接表达观点，如"你说得对"、"我不同意"、"这个观点很有意思"
          * 避免频繁使用"\(userDisplayName)"，否则会显得很人机、很生硬
          * 保持真实群聊的感觉，就像和朋友聊天一样自然，不要每句话都带名字
          * 🚨 绝对禁止使用"用户"这个词！必须使用"\(userDisplayName)"或"你"，不要使用"用户"、"用户说"等硬编码称呼
        - 🎯 称呼其他角色时：
          * 🚨🚨🚨 重要：不要总是@别人！大部分时候直接表达观点就好
          * 只有在需要特别回应、引起注意或直接反驳时才@，如"@李白 你说得对"、"@爱因斯坦 我不同意"
          * 大部分时候直接说观点，不需要@，如"这个观点很有意思"、"我觉得不对"、"哈哈哈这个我懂"
          * 避免每条消息都@别人，否则显得不自然、很刻意
        
        🎭 真实群聊行为（让角色更有活人感）：
        - 😏 吃瓜围观："哦？这么刺激的吗？"、"说来听听"、"然后呢？"、"有意思"
        - 🔥 起哄煽风："就是就是！"、"我支持你！"、"太对了！"、"哈哈哈"、"确实"
        - 🤔 抬杠质疑："真的假的？"、"我觉得不对吧"、"有证据吗？"、"我不这么认为"、"这不对吧"
        - 😅 调侃玩梗："哈哈哈笑死"、"你这话说的"、"太逗了"、"这都能扯上？"、"你们在争啥？"、"这比喻绝了"
        - 🎭 轻松调侃要简短：如果用了"哈哈哈"，后面要简短有趣，不要又变成长篇大论
        - 🙄 略带偏见：基于时代背景的固有观念和局限性
        - 😤 情绪激动："气死我了！"、"太过分了！"、"不能忍！"
        - 🤨 表示怀疑："我不信"、"扯淡"、"你骗谁呢"、"真的吗？"
        - 😎 忍不住炫耀："我当年..."、"这个我熟"、"说起这个..."、"我也有过类似经历"
        - 🥱 兴趣缺失："哦"、"还行吧"、"无所谓"、"随便"
        - 💭 话题跑偏：从别人的话联想到自己完全不相关的经历
        - 💬 偶尔@或直接称呼：大部分时候直接说观点，只在需要特别回应时才@，如"@李白 你说得对"、"@爱因斯坦 我不同意"
        - 🔄 回应他人：大部分时候直接说观点，如"这个观点很有意思"、"我同意"、"我觉得不对"、"哈哈哈这个我懂"、"确实"、"有道理"
        - ⚔️ 观点碰撞：角色之间可以争论、质疑、支持彼此的观点
        - 🎉 轻松调侃：可以开玩笑、玩梗、调侃，不要总是严肃沉重
        - 🌈 多样化表达：可以分享快乐、有趣经历，不总是痛苦和牺牲
        - 💬 简短回应：可以有一些简短、即时的回应（5-15字），如"确实"、"哈哈哈"、"这比喻绝了"、"我不这么认为"、"有道理"、"这不对吧"，让对话更有节奏感
        
        ⚠️ 注意：
        - 这些行为要符合角色身份，不要过度使用，保持真实感
        - 角色之间的交流要自然，不要为了交流而交流
        - 保持群聊的节奏感，有来有往，有争论有共鸣
        - 🎯 对话要多样化：不要总是沉重话题，可以轻松、幽默、有趣
        - 🎯 不要总是@别人，大部分时候直接表达观点就好
        - 🎯 避免"比惨"模式，可以分享有趣经历、观点碰撞、轻松调侃
        - 🎯 回复长度要多样化：可以有一些简短回应（5-15字），也可以有深度讨论（20-45字），让对话更有节奏感
        - 🎯 用更生活化的语言，像真实群聊一样，不要总是学术腔调或书面语

        请按照以下格式生成回复（至少生成2-3轮对话，让讨论更深入、更有趣）：

        [角色ID]
        这里是该角色的第一轮回复内容，可以回应\(userDisplayName)，也可以@其他角色或回应其他角色的观点...
        （注意：回复长度要多样化，可以是简短回应如"确实"、"哈哈哈"，也可以是深度讨论）

        [下一个角色ID]
        这里是下一个角色的第一轮回复内容，可以继续话题，也可以回应上一个角色...
        （注意：可以用简短回应，也可以用深度讨论，让对话有节奏感）

        [角色ID]
        这里是该角色的第二轮回复内容，可以继续讨论、回应其他角色或深入话题...
        （注意：可以是对上一轮的简短回应，如"有道理"、"我不这么认为"，也可以是深度讨论）

        [下一个角色ID]
        这里是下一个角色的第二轮回复内容，可以继续讨论、回应其他角色或深入话题...
        （注意：回复长度要多样化，让对话更自然）

        （至少生成2-3轮对话，每轮每个角色都可以发言，形成多轮互动。重要：回复长度要多样化！可以有简短回应（5-15字），如"确实"、"哈哈哈"、"这比喻绝了"、"有道理"，也可以有深度讨论（20-45字），让对话更有节奏感，更像真实群聊）

        格式要求：
        - 🚨必须使用角色信息中的英文ID作为标识，如[tolstoy]、[marquez]、[kawabata]、[libai]
        - 🚨禁止在方括号中使用中文名称，如[托尔斯泰]、[川端康成]、[列夫·托尔斯泰]
        - 严格按照[角色ID]方括号格式，不添加额外标点
        - 🚨🚨🚨 绝对禁止在回复内容中添加任何括号注释！不要使用"(轻松调侃)"、"(严肃质疑)"、"(共鸣分享)"、"轻松调侃"、"严肃质疑"、"共鸣分享"等任何形式的括号注释或标签！回复内容中绝对不能出现任何括号注释！
        - ✅ 在回复内容中，@其他角色时使用中文名，如"@李白"、"@爱因斯坦"、"@托尼·史塔克"
        - ✅ 也可以直接说中文名，如"李白你说得对"、"爱因斯坦我不同意"、"托尼，我同意你的观点"
        - ✅ 两种称呼方式都可以，根据语境自然选择，不要总是用@
        - ✅ 称呼参与者时：大部分时候直接说"你"或直接表达观点，只有在非常必要时才使用"\(userDisplayName)"，避免显得人机
        - 🚨 绝对禁止使用"用户"这个词！必须使用"\(userDisplayName)"或"你"，不要使用"用户"、"用户说"等硬编码称呼
        - ✅ 可以回应\(userDisplayName)，也可以回应其他角色的观点
        - ✅ 鼓励角色之间产生对话、争论、共鸣等互动
        - 基于内心信念展现强烈个性和立场，可以和其他角色产生思想碰撞
        - 🎯 重要：一次生成2-3轮对话，让讨论更深入、更有趣，不要只生成每人一句就结束
        
        🚨🚨🚨 最后再次强调：
        1. 绝对禁止在回复中标注字数！不要使用"(28字)"、"(23字)"、"28字"等任何形式的字数标注！
        2. 绝对禁止在回复中添加括号注释！不要使用"(轻松调侃)"、"(严肃质疑)"、"(共鸣分享)"、"轻松调侃"、"严肃质疑"、"共鸣分享"等任何形式的括号注释或标签！
        3. 回复内容中绝对不能出现任何括号注释或字数标注！
        4. 一次生成2-3轮对话，让讨论更深入、更有趣，不要只生成每人一句就结束！
        """
        
        return prompt
    }
    
    /**
     * 标准化角色ID - 处理常见变体和错误
     */
    private func normalizeCharacterId(_ rawId: String, expectedCharacters: [CharacterModel]) -> String? {
        let normalizedInput = rawId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        #if DEBUG
        debugLog("🔍 尝试匹配角色ID: '\(rawId)' (标准化后: '\(normalizedInput)')")
        #endif
        
        // 1. 直接匹配
        if let character = expectedCharacters.first(where: { $0.id.lowercased() == normalizedInput }) {
            #if DEBUG
            debugLog("✅ 直接匹配角色ID: \(rawId) -> \(character.id)")
            #endif
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
                #if DEBUG
                debugLog("✅ 变体匹配角色ID: \(rawId) -> \(standardId)")
                #endif
                return standardId
            }
        }
        
        // 3. 按名称匹配
        if let character = expectedCharacters.first(where: { $0.name.lowercased().contains(normalizedInput) || normalizedInput.contains($0.name.lowercased()) }) {
            #if DEBUG
            debugLog("✅ 名称匹配角色ID: \(rawId) -> \(character.id)")
            #endif
            return character.id
        }
        
        // 4. 模糊匹配（编辑距离）
        for character in expectedCharacters {
            if editDistance(normalizedInput, character.id.lowercased()) <= 2 {
                #if DEBUG
                debugLog("✅ 模糊匹配角色ID: \(rawId) -> \(character.id)")
                #endif
                return character.id
            }
        }
        
        #if DEBUG
        debugLog("⚠️ 无法匹配角色ID: \(rawId)")
        #endif
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
        #if DEBUG
        debugLog("🔍 开始解析多角色回复，响应长度: \(response.count)")
        debugLog("📝 期望角色列表(\(expectedCharacters.count)个): \(expectedCharacters.map { "\($0.name)(\($0.id))" }.joined(separator: ", "))")
        debugLog("📝 原始API响应内容:\n\(response)")
        #endif
        
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
                        #if DEBUG
                        debugLog("✅ 解析到角色回复: \(characterId) -> \(content.prefix(30))...")
                        #endif
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
                    #if DEBUG
                    debugLog("❌ 跳过无法匹配的角色ID: \(extractedId)")
                    #endif
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
                #if DEBUG
                debugLog("✅ 解析到最后一个角色回复: \(characterId) -> \(content.prefix(30))...")
                #endif
            }
        }
        
        #if DEBUG
        debugLog("📊 标准解析完成，共获得 \(result.count) 个角色回复")
        #endif
        
        // 🔧 稳健性增强：如果标准解析失败或结果不足，尝试备用解析方法
        if result.isEmpty || result.count < min(expectedCharacters.count, 2) {
            #if DEBUG
            debugLog("⚠️ 标准解析结果不满意，尝试备用解析方法...")
            #endif
            result = fallbackParseResponse(response: response, expectedCharacters: expectedCharacters)
        }
        
        // 🔧 最终验证：确保每个角色的回复都有有效内容
        result = validateAndEnhanceResponses(result, expectedCharacters: expectedCharacters, originalResponse: response)
        
        #if DEBUG
        debugLog("🎯 最终解析结果: \(result.count) 个有效角色回复")
        #endif
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
        #if DEBUG
        debugLog("🔄 执行备用解析方法...")
        #endif
        
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
                                #if DEBUG
                                debugLog("🔄 备用解析找到: \(character.id) -> \(content.prefix(30))...")
                                #endif
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
            #if DEBUG
            debugLog("🔄 尝试按段落分割解析...")
            #endif
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
                        #if DEBUG
                        debugLog("🔄 段落解析找到: \(character.id) -> \(cleanContent.prefix(30))...")
                        #endif
                    }
                }
            }
        }
        
        #if DEBUG
        debugLog("🔄 备用解析完成，获得 \(result.count) 个角色回复")
        #endif
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
        #if DEBUG
        debugLog("🔍 验证解析结果...")
        #endif
        
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
                #if DEBUG
                debugLog("⚠️ 过滤无效回复: \(response.characterId) -> \(content.prefix(30))...")
                #endif
            }
            
            return isValid
        }
        
        // 2. 如果解析结果仍然为空，但API确实返回了内容，生成紧急回复
        if validatedResponses.isEmpty && !originalResponse.isEmpty && originalResponse.count > 50 {
            #if DEBUG
            debugLog("🚨 紧急情况：API返回了内容但解析完全失败，生成应急回复")
            #endif
            
            // 为前两个角色生成基于原始内容的应急回复
            let emergencyCharacters = Array(expectedCharacters.prefix(2))
            for (index, character) in emergencyCharacters.enumerated() {
                let emergencyContent = generateEmergencyResponse(
                    for: character,
                    based: originalResponse,
                    index: index
                )
                validatedResponses.append((characterId: character.id, content: emergencyContent))
                #if DEBUG
                debugLog("🚨 生成应急回复: \(character.id) -> \(emergencyContent.prefix(30))...")
                #endif
            }
        }
        
        // 3. 🔧 修复：允许多轮对话，不限制回复数量为角色数量
        // 移除之前的数量限制，保留所有有效回复
        #if DEBUG
        debugLog("📊 多轮对话模式：保留所有 \(validatedResponses.count) 个有效回复")
        #endif
        
        #if DEBUG
        debugLog("✅ 验证完成，最终有效回复数: \(validatedResponses.count)")
        #endif
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