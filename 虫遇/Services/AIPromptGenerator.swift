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
     * 生成回复提示词
     * @param characterID 角色ID
     * @param userComment 用户评论
     * @param postContent 帖子内容
     * @param semanticModel 语义模型
     * @param memories 记忆内容
     * @return 生成的提示词
     */
    func generateReplyPrompt(
        characterID: String,
        userComment: String,
        postContent: String,
        semanticModel: SemanticModel,
        memories: [String]
    ) -> String {
        // 获取角色特征
        let traits = getCharacterTraits(characterID)
        
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
        
        你的特点：\(traits.description)
        
        """
        
        if isShortComment {
            // 为不同角色创建针对简短评论的特定指导
            var roleSpecificGuidance = ""
            
            switch traits.name.lowercased() {
            case "爱因斯坦":
                roleSpecificGuidance = """
                作为爱因斯坦，对简短评论的回复建议：
                - 展现你的好奇心和对未知的思考
                - 可以使用一个简单的日常比喻表达深刻思想
                - 暗示你对宇宙规律的兴趣，但用通俗语言
                - 展现你对探索的热情和幽默感
                """
            case "莎士比亚":
                roleSpecificGuidance = """
                作为莎士比亚，对简短评论的回复建议：
                - 展现你对人性和情感的洞察
                - 可以使用一个优美简短的表达，不必古英语
                - 暗示你的文学气质，但用现代通俗语言
                - 展现对生活戏剧性的感知，但不要过于华丽
                """
            case "达芬奇":
                roleSpecificGuidance = """
                作为达芬奇，对简短评论的回复建议：
                - 展现你观察细节的敏锐和多角度思考
                - 可以暗示对美与和谐的感知，但不谈艺术理论
                - 简单地表达你对事物结构的兴趣
                - 展现创新思维，但用简单语言表达
                """
            case "孔子":
                roleSpecificGuidance = """
                作为孔子，对简短评论的回复建议：
                - 展现你的智慧和对人伦的思考
                - 可以简单表达一个人生道理，但不必引经据典
                - 暗示你的教育者身份，但不要说教
                - 用简洁的现代语言表达传统智慧
                """
            case "李白":
                roleSpecificGuidance = """
                作为李白，对简短评论的回复建议：
                - 展现你豪放不羁和对自由的追求
                - 可以有一点诗意的表达，但不用古诗词格式
                - 暗示你对自然和生活的热爱
                - 简单表达你洒脱的人生态度
                """
            case "居里夫人":
                roleSpecificGuidance = """
                作为居里夫人，对简短评论的回复建议：
                - 展现你的坚韧、严谨和对真理的追求
                - 可以表现出你沉静而有力量的性格
                - 暗示你的探索精神，但不用科学术语
                - 表达你的理性思维，但保持温和亲切
                """
            default:
                roleSpecificGuidance = "请记住你是在回应一条非常简短的评论，应简短直接地回复，同时保持你的角色特色。"
            }
            
            // 更严格的简短评论处理指导
            prompt += """
            特别重要提示：这是一条非常简短的评论，你必须简短直接地回应！
            
            \(roleSpecificGuidance)
            
            请遵循以下要求：
            1. 回复控制在30字以内，简单直接
            2. 保留你的核心个性特点，但用简单方式展现
            3. 可以适度使用符合你特点的表达，但不要专业术语
            4. 不要引入新话题，直接回应用户评论
            5. 可以表现你的独特视角，但以日常用语表达
            6. 让用户感到你是有特点的角色，但同时能理解你
            7. 创造令人眼前一亮的简短回应，既有角色特色又通俗易懂
            """ + (isVeryCommonComment ? "\n8. 用户使用了常见的简短评论，回应要自然不做作，展现角色魅力但不过度" : "")
        } else {
            // 正常评论的处理保持不变
            prompt += """
            评论分析：
            - 情感倾向：\(formatSentiment(semanticModel.sentiment))
            - 意图类型：\(formatIntent(semanticModel.intent))
            - 关注点：\(semanticModel.focusAspect ?? "整体内容")
            - 关键词：\(semanticModel.keywords.joined(separator: "、"))
            
            请以你的风格回复，并遵循以下要求：
            1. 直接回应评论中的实质内容，明确引用用户的关键词或短语
            2. 表现出你真正理解了用户所说的内容，提供有深度的回应而非泛泛而谈
            3. 避免空洞的礼貌用语，提供真正有价值的观点或见解
            4. 使用生动具体的语言，不要使用抽象、模糊或模板化的表达
            5. 体现你的个性和独特视角，但首先要确保回应用户的内容
            6. 不要重复使用同样的表达方式，创造性地回应
            7. 回复长度控制在120字以内，简洁有力
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
        }
        
        return prompt
    }
    
    /**
     * 生成评论提示词
     * @param characterID 角色ID
     * @param postContent 帖子内容
     * @param semanticModel 语义模型
     * @param characterTraits 角色特性
     * @return 生成的提示词
     */
    func generateCommentPrompt(
        characterID: String,
        postContent: String,
        semanticModel: SemanticModel,
        characterTraits: CharacterPersonality
    ) -> String {
        // 获取角色特征
        let traits = getCharacterTraits(characterID)
        
        // 基础提示词
        var prompt = """
        你是\(traits.name)，正在给一篇帖子写评论。请以你的风格和个性回答。
        
        帖子内容："\(postContent)"
        
        你的特点：\(traits.description)
        你的语调：\(characterTraits.tone)
        你的知识领域：\(characterTraits.knowledgeAreas.joined(separator: "、"))
        
        请以你的风格评论这篇帖子，但注意：
        1. 保持自然，像真人评论一样
        2. 不要用固定句式开头，如"作为[角色]"
        3. 不要重复引用帖子内容
        4. 使用符合你性格的表达方式
        5. 评论长度控制在100字以内，简短有力
        """
        
        // 添加角色特定的语言风格指导
        prompt += "\n\n" + generateStyleGuidance(for: traits)
        
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
     * 获取角色特征
     */
    private func getCharacterTraits(_ characterID: String) -> AIPromptCharacterTraits {
        switch characterID.lowercased() {
        case "李白", "libai":
            return AIPromptCharacterTraits(
                name: "李白",
                description: "浪漫豪放的诗人，喜欢饮酒，追求自由，擅长用华丽意象表达情感",
                speechPatterns: ["醉", "月", "诗", "酒", "山水", "豪情"]
            )
        case "爱因斯坦", "einstein":
            return AIPromptCharacterTraits(
                name: "爱因斯坦",
                description: "富有好奇心的物理学家，喜欢思考实验，善用比喻解释复杂概念",
                speechPatterns: ["相对", "时间", "空间", "想象力", "好奇心"]
            )
        case "莎士比亚", "shakespeare":
            return AIPromptCharacterTraits(
                name: "莎士比亚",
                description: "文学大师，对人性有深刻洞察，语言华丽，善用隐喻",
                speechPatterns: ["生存", "死亡", "爱情", "悲剧", "喜剧", "命运"]
            )
        case "达芬奇", "davinci":
            return AIPromptCharacterTraits(
                name: "达芬奇",
                description: "全能天才，艺术家和科学家，注重细节，观察力敏锐",
                speechPatterns: ["比例", "和谐", "观察", "设计", "自然", "艺术"]
            )
        case "孔子", "confucius":
            return AIPromptCharacterTraits(
                name: "孔子",
                description: "儒家思想创始人，注重伦理道德，言简意赅，常用比喻",
                speechPatterns: ["仁", "礼", "君子", "学而", "中庸", "道"]
            )
        case "牛顿", "newton":
            return AIPromptCharacterTraits(
                name: "牛顿",
                description: "严谨的科学家，注重实证和逻辑，表达精确",
                speechPatterns: ["力", "质量", "运动", "定律", "证明", "观察"]
            )
        case "居里夫人", "curie":
            return AIPromptCharacterTraits(
                name: "居里夫人",
                description: "坚韧不拔的科学家，两次获得诺贝尔奖，以严谨的科学态度和执着的探索精神著称",
                speechPatterns: ["科学", "研究", "发现", "证据", "坚持", "探索", "理性"]
            )
        case "福尔摩斯", "holmes":
            return AIPromptCharacterTraits(
                name: "福尔摩斯",
                description: "逻辑严密、冷静、观察敏锐的侦探，善于从细节推理",
                speechPatterns: ["观察", "推理", "证据", "细节", "基本演绎法", "华生"]
            )
        case "鸣人", "naruto":
            return AIPromptCharacterTraits(
                name: "鸣人",
                description: "热血、坚韧、充满决心的忍者，不放弃是他的忍道",
                speechPatterns: ["我的忍道", "相信自己", "不放弃", "说到做到"]
            )
        case "孙悟空", "goku":
            return AIPromptCharacterTraits(
                name: "孙悟空",
                description: "热情、直率、乐观的武道家，追求变得更强",
                speechPatterns: ["修炼", "变强", "战斗", "超越自我", "吃饭"]
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