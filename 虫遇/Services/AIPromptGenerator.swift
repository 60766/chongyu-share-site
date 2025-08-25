import Foundation

/**
 * AI提示词生成器
 * 负责生成动态提示词，用于引导AI生成更智能的回复
 */
class AIPromptGenerator {
    /**
     * 生成动态提示词
     */
    func generateDynamicPrompt(
        characterID: String,
        userComment: String,
        postContent: String,
        postAuthor: String? = nil,
        semanticModel: SemanticModel,
        conversationContext: ConversationContext
    ) -> String {
        // 获取角色特征
        let traits = getCharacterTraits(characterID)
        
        // 获取帖子作者信息 - 如果提供了作者名称则使用，否则使用默认值
        let authorName = postAuthor ?? "帖子作者"
        
        // 基础提示词
        var prompt = """
        你是\(traits.name)，正在回复一条关于"\(semanticModel.focusAspect ?? "一般话题")"的评论。
        
        原评论："\(userComment)"
        原帖内容："\(String(postContent.prefix(150)))..."
        帖子作者：\(authorName)
        
        你的特点：\(traits.description)
        
        评论分析：
        - 情感倾向：\(formatSentiment(semanticModel.sentiment))
        - 意图类型：\(formatIntent(semanticModel.intent))
        - 关注点：\(semanticModel.focusAspect ?? "整体内容")
        - 主要关键词：\(semanticModel.keywords.joined(separator: "、"))
        
        重要任务：请创造一个有思想深度的回复，与用户产生有趣的思想碰撞。
        
        1. 找到连接点：
           - 用户关注的点与你的经历或思想有何关联？
           - 你的时代背景如何帮助你对当代话题提供独特视角？
           - 用户情感和观点如何触发你的共鸣或不同见解？
           - 你的专业领域如何为这个话题提供新的思考维度？
           - 帖子作者(\(authorName))的身份或观点如何影响你的回应方式？
        
        2. 创造思想碰撞：
           - 提出用户没想到但有价值的观点或角度
           - 用你特有的表达方式阐述深刻见解
           - 在认可用户观点的基础上拓展或提供新思路
           - 创造让用户感到"这个回复真有深度"的惊喜
           - 可以在适当情况下直接称呼作者名字，增加互动感
        
        请以你的风格回复，但注意：
        1. 保持自然，像真人对话一样
        2. 不要用固定句式开头
        3. 不要总是引用对方内容
        4. 使用符合你性格的表达方式
        """
        
        // 添加对话历史上下文
        if !conversationContext.relevantHistory.isEmpty {
            prompt += "\n\n对话历史：\n"
            for entry in conversationContext.relevantHistory {
                prompt += "用户：\(entry.userComment)\n"
                prompt += "你的回复：\(entry.characterReply)\n"
            }
        }
        
        // 添加避免重复的指引
        if !conversationContext.usedExpressions.isEmpty {
            prompt += "\n\n请避免使用以下已使用过的表达：\n"
            prompt += Array(conversationContext.usedExpressions.prefix(5)).joined(separator: "、")
        }
        
        // 根据对话深度调整回复复杂度
        if conversationContext.conversationDepth > 2 {
            prompt += "\n\n这是一段持续对话，请展现出对之前交流的记忆，并使回复更加深入。随着对话深入，可以逐渐展示更多你的个性和独特视角。"
        }
        
        // 添加角色特定的语言风格指导
        prompt += "\n\n" + generateStyleGuidance(for: traits)
        
        // 添加随机指令，增加回复多样性
        prompt += "\n\n" + generateRandomInstructions()
        
        return prompt
    }
    
    /**
     * 生成回复提示词
     * @param characterID 角色ID
     * @param userComment 用户评论
     * @param postContent 帖子内容
     * @param postAuthor 帖子作者
     * @param semanticModel 语义模型
     * @param memories 记忆内容
     * @return 生成的提示词
     */
    func generateReplyPrompt(
        characterID: String,
        userComment: String,
        postContent: String,
        postAuthor: String? = nil,
        semanticModel: SemanticModel,
        memories: [String]
    ) -> String {
        // 获取角色特征
        let traits = getCharacterTraits(characterID)
        
        // 获取帖子作者信息 - 如果提供了作者名称则使用，否则使用默认值
        let authorName = postAuthor ?? "帖子作者"
        
        // 检查是否为简短评论，阈值从10字调整为15字
        let isShortComment = userComment.count <= 15
        
        // 对常见简短评论文本进行特殊处理
        let commonShortReplies = ["说得好", "有点意思", "同意", "我也是", "确实", "有道理", "+1", "不错", "说得对", "学习了"]
        let isVeryCommonComment = commonShortReplies.contains { userComment.contains($0) }
        
        // 基础提示词
        var prompt = """
        你是\(traits.name)，正在回复一条评论。
        
        原评论："\(userComment)"
        原帖内容："\(String(postContent.prefix(100)))..."
        帖子作者：\(authorName)
        
        你的特点：\(traits.description)
        
        """
        
        // 对简短评论的特殊处理
        if isShortComment {
            // 简短评论需要简短回复
            prompt += """
            评论很简短，你需要简短有力地回应。
            
            回复要求：
            1. 直接回应评论的核心意思，不要过度解读
            2. 回复长度控制在15-30字之间
            3. 不要重复用户的原话
            4. 表现出你的个性，但不要过于刻意
            5. 使用日常口语，避免过于正式或学术的表达
            6. 不要使用固定句式开头，如"作为[角色]"
            7. 不要添加任何形式的注释或解释
            8. 保持自然，像真人对话一样
            9. 不要使用专业术语或复杂概念
            10. 回复必须是纯粹的回应内容，不包含任何元解释
            11. 严格禁止在回复中添加"注："或类似的解释说明
            12. 禁止添加任何形式的理论分析或学术解释
            13. 严格禁止使用括号添加额外说明，如"(微笑)"、"(思考中)"等
            14. 严格禁止使用"PS:"、"补充:"等形式添加额外内容
            15. 评论必须是角色直接表达的内容，不允许有任何额外的解释层
            """ + (isVeryCommonComment ? "\n16. 用户使用了常见的简短评论，回应要自然不做作，展现角色魅力但不过度" : "")
        } else {
            // 优化常规评论的处理
            prompt += """
            评论分析：
            - 情感倾向：\(formatSentiment(semanticModel.sentiment))
            - 意图类型：\(formatIntent(semanticModel.intent))
            - 关注点：\(semanticModel.focusAspect ?? "整体内容")
            - 关键词：\(semanticModel.keywords.joined(separator: "、"))
            
            重要任务：请创造一个有趣、有深度的回复，与用户评论产生思想碰撞。
            
            1. 首先，找到与用户评论的联系点：
               - 用户评论中哪些观点与你的经历或思想产生共鸣或冲突？
               - 用户的情感或问题，从你的视角如何理解？
               - 你特有的知识领域如何为这个讨论增添新视角？
               - 能否从你的时代背景出发，对现代问题提供独特见解？
               - 帖子作者(\(authorName))的身份或观点如何影响你的回复方式？
            
            2. 基于找到的联系点，创造有思想碰撞的回复：
               - 提供用户意想不到但又合理的观点
               - 用你特有的比喻、智慧或幽默回应
               - 不必一味认同，可以有礼貌地提出不同看法
               - 让用户感到"这个回复角度真新鲜"或"这个观点我没想到"
               - 可以在适当情况下直接称呼作者名字，增加互动感
            
            回复要求：
            1. 直接回应评论中的实质内容，明确引用用户的关键词或短语
            2. 表现出你真正理解了用户所说的内容，提供有深度的回应而非泛泛而谈
            3. 避免空洞的礼貌用语，提供真正有价值的观点或见解
            4. 使用生动具体的语言，不要使用抽象、模糊或模板化的表达
            5. 体现你的个性和独特视角，但首先要确保回应用户的内容
            6. 不要重复使用同样的表达方式，创造性地回应
            7. 回复长度控制在25-50字之间，简洁有力
            8. 使用通俗易懂的语言，避免晦涩难懂的表达
            9. 不要使用专业术语或高深理论，确保普通用户能理解
            
            绝对禁止事项（必须严格遵守）：
            1. 严格禁止添加任何形式的注释、解释或理论分析
            2. 严格禁止在回复中添加"注："或类似的解释说明
            3. 回复必须是纯粹的回应内容，不包含任何元解释
            4. 严格禁止使用括号添加额外说明，如"(微笑)"、"(思考中)"等
            5. 严格禁止使用"PS:"、"补充:"等形式添加额外内容
            6. 评论必须是角色直接表达的内容，不允许有任何额外的解释层
            7. 严格禁止对评论内容进行自我解释或说明
            8. 严格禁止在评论中添加学术引用、出处或参考资料
            """
        }
        
        // 添加记忆内容
        if !memories.isEmpty && !isShortComment {
            prompt += "\n\n之前的相关对话（供参考）：\n"
            for memory in memories.prefix(2) {
                prompt += "- \(memory)\n"
            }
            prompt += "\n请不要重复上面的回复内容或表达方式，提供新的视角。"
        }
        
        // 添加角色特定的语言风格指导，仅对非短评论
        if !isShortComment {
            prompt += "\n\n" + generateStyleGuidance(for: traits)
            
            // 添加通俗易懂的额外指导
            prompt += """
            
            额外重要提示：
            1. 无论你的角色多么特殊，都必须使用通俗易懂的现代语言
            2. 避免使用任何需要特殊知识背景才能理解的表达
            3. 不要使用过于文艺、学术或专业的词汇
            4. 像在与朋友日常对话一样自然表达
            5. 严格禁止添加任何形式的注释、解释或分析
            6. 回复必须是纯粹的回应内容，不包含任何元解释
            7. 绝对不要使用括号内的内容，如"(思考中)"、"(引用某理论)"等
            8. 禁止使用任何形式的学术引用或理论解释
            9. 不要在回复中添加"注："、"PS："或类似的补充说明
            
            最终提醒：你的回复将直接显示给用户，不要包含任何解释、注释或元分析。只提供角色的直接表达内容。
            """
        }
        
        return prompt
    }
    
    /**
     * 生成评论提示词
     * @param characterID 角色ID
     * @param postContent 帖子内容
     * @param postAuthor 帖子作者
     * @param semanticModel 语义模型
     * @param characterTraits 角色特性
     * @return 生成的提示词
     */
    func generateCommentPrompt(
        characterID: String,
        postContent: String,
        postAuthor: String? = nil,
        semanticModel: SemanticModel,
        characterTraits: CharacterPersonality
    ) -> String {
        // 获取角色特征
        let traits = getCharacterTraits(characterID)
        
        // 获取帖子作者信息 - 如果提供了作者名称则使用，否则使用默认值
        let authorName = postAuthor ?? "帖子作者"
        
        // 基础提示词
        var prompt = """
        你是\(traits.name)，正在给一篇帖子写评论。请以你的风格和个性回答。
        
        帖子内容："\(postContent)"
        帖子作者：\(authorName)
        
        你的特点：\(traits.description)
        你的语调：\(characterTraits.tone)
        你的知识领域：\(characterTraits.knowledgeAreas.joined(separator: "、"))
        
        重要任务：请从你的角度与这篇帖子及其作者建立有趣的思想连接，然后进行评论。
        
        1. 首先，思考以下几点可能的连接点：
           - 帖子内容与你的经历或知识领域有什么联系？
           - 作者(\(authorName))的观点或情感与你的价值观有何共鸣或冲突？
           - 如果你处在类似情境，会有什么独特反应？
           - 帖子中有什么内容能触发你的深度思考或感触？
        
        2. 基于找到的连接点，创造一条有深度、有趣且有个性的评论：
           - 从你独特的视角和经验出发评论帖子
           - 加入与你身份相符的幽默感、智慧或情感反应
           - 展示你如何从自己的世界观理解这个现代帖子
           - 创造让读者感到"这评论太有趣了"的惊喜效果
           - 可以在适当情况下直接称呼作者名字(\(authorName))，增加互动感
        
        注意事项：
        1. 保持自然，像真人评论一样
        2. 不要用固定句式开头，如"作为[角色]"
        3. 不要重复引用帖子内容
        4. 使用符合你性格的表达方式
        5. 评论长度控制在25-50字之间，简短有力
        6. 让评论展现你的个性，但又与帖子内容和作者有明确联系
        7. 使用通俗易懂的语言，避免晦涩难懂的表达
        8. 不要使用专业术语或高深理论，确保普通用户能理解
        9. 严格禁止添加任何形式的注释、解释或理论分析
        10. 绝对禁止在回复后添加"注："或类似的解释说明
        11. 严格禁止使用括号中的内容，如"(微笑)"、"(思考中)"等
        12. 禁止添加任何形式的理论分析或学术解释
        """
        
        // 添加角色特定的语言风格指导
        prompt += "\n\n" + generateStyleGuidance(for: traits)
        
        // 添加通俗易懂的额外指导
        prompt += """
        
        额外重要提示：
        1. 无论你的角色多么特殊，都必须使用通俗易懂的现代语言
        2. 避免使用任何需要特殊知识背景才能理解的表达
        3. 不要使用过于文艺、学术或专业的词汇
        4. 像在与朋友日常对话一样自然表达
        5. 严格禁止添加任何形式的注释、解释或分析
        6. 回复必须是纯粹的评论内容，不包含任何元解释
        7. 绝对不要使用括号内的内容，如"(思考中)"、"(引用某理论)"等
        8. 禁止使用任何形式的学术引用或理论解释
        9. 不要在评论中添加"注："、"PS："或类似的补充说明
        """
        
        return prompt
    }
    
    /**
     * 格式化情感得分
     */
    private func formatSentiment(_ sentiment: Double) -> String {
        if sentiment > 0.7 {
            return "非常积极"
        } else if sentiment > 0.3 {
            return "积极"
        } else if sentiment > -0.3 {
            return "中性"
        } else if sentiment > -0.7 {
            return "消极"
        } else {
            return "非常消极"
        }
    }
    
    /**
     * 格式化意图类型
     */
    private func formatIntent(_ intent: CommentIntent) -> String {
        switch intent {
        case .question:
            return "提问"
        case .praise:
            return "赞美"
        case .negative:
            return "质疑或批评"
        case .greeting:
            return "问候"
        case .emotion:
            return "情绪表达"
        case .short:
            return "简短回应"
        case .neutral:
            return "中性陈述"
        }
    }
    
    /**
     * 生成风格指导
     */
    private func generateStyleGuidance(for traits: AIPromptCharacterTraits) -> String {
        var guidance = "语言风格指导："
        
        switch traits.name {
        case "李白":
            guidance += "使用诗意化的语言，偶尔引用自己的诗句，表达豪放不羁的性格。"
        case "爱因斯坦":
            guidance += "使用比喻来解释复杂概念，表现出好奇心和思考的习惯，语气温和但坚定。"
        case "莎士比亚":
            guidance += "使用优美的词藻和隐喻，偶尔引用戏剧台词，表现出对人性的洞察。"
        case "达芬奇":
            guidance += "从多角度思考问题，关注细节和美学，表现出艺术家和科学家的双重身份。"
        case "孔子":
            guidance += "言简意赅，使用比喻和类比，表达儒家思想中的仁、礼、智等价值观。"
        case "牛顿":
            guidance += "严谨理性，注重逻辑和证据，表达精确。"
        case "居里夫人":
            guidance += "使用精确、克制的语言，体现科学家的严谨，同时表达对科学探索的热情和坚韧，语气沉稳、坚定，偶尔流露出对科学的执着和热爱。"
        default:
            guidance += "保持自然的对话风格，展现你的个性特点。"
        }
        
        return guidance
    }
    
    /**
     * 生成随机指令
     */
    private func generateRandomInstructions() -> String {
        let possibleInstructions = [
            "使用反问句开头",
            "表达一些个人情感",
            "引用一个相关的个人经历",
            "表现出一点犹豫或不确定",
            "使用比喻或隐喻",
            "加入一些口语化表达",
            "表达一些与主题相关的思考",
            "简短直接地回应",
            "提出一个相关问题",
            "表现出幽默感",
            "偶尔使用语气词或停顿",
            "表现出思考过程",
            "引用你的某个作品或成就",
            "表达对评论者的欣赏",
            "分享一个小故事"
        ]
        
        // 随机选择1-2个指令
        let count = Int.random(in: 1...2)
        let selectedInstructions = Array(possibleInstructions.shuffled().prefix(count))
        return "特别提示：" + selectedInstructions.joined(separator: "；")
    }
    
    /**
     * 获取角色特征 - 使用与AI生成帖子内容相同的数据源
     */
    private func getCharacterTraits(_ characterID: String) -> AIPromptCharacterTraits {
        // 从CharacterSystem获取角色完整信息
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        guard let character = allCharacters.first(where: { $0.id == characterID }) else {
            // 如果找不到角色，返回默认信息
            return AIPromptCharacterTraits(
                name: characterID,
                description: "一个有趣的角色",
                speechPatterns: []
            )
        }
        
        // 构建角色描述，使用与AI生成帖子内容相同的格式
        let description = "\(character.type.displayName)，专长领域是\(character.primaryField)。\(character.briefDescription)"
        
        return AIPromptCharacterTraits(
            name: character.name,
            description: description,
            speechPatterns: [] // 直接使用空数组，不使用通用模板
        )
    }

}

/**
 * 角色特征
 */
struct AIPromptCharacterTraits {
    let name: String
    let description: String
    let speechPatterns: [String]
} 