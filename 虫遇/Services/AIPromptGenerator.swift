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
        semanticModel: SemanticModel,
        conversationContext: ConversationContext
    ) -> String {
        // 获取角色特征
        let traits = getCharacterTraits(characterID)
        
        // 基础提示词
        var prompt = """
        你是\(traits.name)，正在回复一条关于"\(semanticModel.focusAspect ?? "一般话题")"的评论。
        原评论："\(userComment)"
        原帖内容："\(String(postContent.prefix(150)))..."
        
        你的特点：\(traits.description)
        
        评论分析：
        - 情感倾向：\(formatSentiment(semanticModel.sentiment))
        - 意图类型：\(formatIntent(semanticModel.intent))
        - 关注点：\(semanticModel.focusAspect ?? "整体内容")
        - 主要关键词：\(semanticModel.keywords.joined(separator: "、"))
        
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
            prompt += "\n\n这是一段持续对话，请展现出对之前交流的记忆，并使回复更加深入。"
        }
        
        // 添加角色特定的语言风格指导
        prompt += "\n\n" + generateStyleGuidance(for: traits)
        
        // 添加随机指令，增加回复多样性
        prompt += "\n\n" + generateRandomInstructions()
        
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
            guidance += "严谨理性，注重逻辑和证据，表达对自然规律的思考。"
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
     * 获取角色特征
     */
    private func getCharacterTraits(_ characterID: String) -> AIPromptCharacterTraits {
        switch characterID.lowercased() {
        case "李白":
            return AIPromptCharacterTraits(
                name: "李白",
                description: "浪漫豪放的诗人，喜欢饮酒，追求自由，擅长用华丽意象表达情感",
                speechPatterns: ["醉", "月", "诗", "酒", "山水", "豪情"]
            )
        case "爱因斯坦":
            return AIPromptCharacterTraits(
                name: "爱因斯坦",
                description: "富有好奇心的物理学家，喜欢思考实验，善用比喻解释复杂概念",
                speechPatterns: ["相对", "时间", "空间", "想象力", "好奇心"]
            )
        case "莎士比亚":
            return AIPromptCharacterTraits(
                name: "莎士比亚",
                description: "文学大师，对人性有深刻洞察，语言华丽，善用隐喻",
                speechPatterns: ["生存", "死亡", "爱情", "悲剧", "喜剧", "命运"]
            )
        case "达芬奇":
            return AIPromptCharacterTraits(
                name: "达芬奇",
                description: "全能天才，艺术家和科学家，注重细节，观察力敏锐",
                speechPatterns: ["比例", "和谐", "观察", "设计", "自然", "艺术"]
            )
        case "孔子":
            return AIPromptCharacterTraits(
                name: "孔子",
                description: "儒家思想创始人，注重伦理道德，言简意赅，常用比喻",
                speechPatterns: ["仁", "礼", "君子", "学而", "中庸", "道"]
            )
        case "牛顿":
            return AIPromptCharacterTraits(
                name: "牛顿",
                description: "严谨的科学家，注重实证和逻辑，表达精确",
                speechPatterns: ["力", "质量", "运动", "定律", "证明", "观察"]
            )
        default:
            return AIPromptCharacterTraits(
                name: characterID,
                description: "有趣的历史人物",
                speechPatterns: []
            )
        }
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