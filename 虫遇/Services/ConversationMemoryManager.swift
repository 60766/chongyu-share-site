import Foundation

/**
 * 对话记忆管理器
 * 负责存储和检索对话历史，避免重复内容
 */
class ConversationMemoryManager {
    // 对话记录存储
    private var conversationMemory: [String: [ConversationEntry]] = [:]
    
    /**
     * 获取相关对话上下文
     */
    func getRelevantContext(
        postID: String,
        characterID: String,
        userComment: String,
        semanticModel: SemanticModel
    ) -> ConversationContext {
        let key = "\(postID)_\(characterID)"
        let entries = conversationMemory[key] ?? []
        
        // 找出与当前评论语义相关的历史记录
        let relevantEntries = entries
            .filter { entry in
                // 简单的相关性判断：关键词匹配
                let hasCommonKeywords = !Set(entry.keywords).intersection(Set(semanticModel.keywords)).isEmpty
                return hasCommonKeywords || entry.focusAspect == semanticModel.focusAspect
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
            
        // 提取已使用的表达和话题，用于避免重复
        let usedExpressions = Set(entries.flatMap { $0.keyPhrases })
        let discussedTopics = entries.compactMap { $0.focusAspect }
        
        return ConversationContext(
            relevantHistory: Array(relevantEntries),
            usedExpressions: usedExpressions,
            discussedTopics: Set(discussedTopics),
            conversationDepth: entries.count
        )
    }
    
    /**
     * 更新对话记忆
     */
    func updateMemory(
        postID: String,
        characterID: String,
        userComment: String,
        reply: String,
        semanticModel: SemanticModel
    ) {
        let key = "\(postID)_\(characterID)"
        
        // 提取回复中的关键短语
        let keyPhrases = extractKeyPhrases(from: reply)
        
        // 创建新的对话记录
        let entry = ConversationEntry(
            userComment: userComment,
            characterReply: reply,
            timestamp: Date(),
            keywords: semanticModel.keywords,
            focusAspect: semanticModel.focusAspect,
            keyPhrases: keyPhrases
        )
        
        // 添加到记忆中
        if conversationMemory[key] == nil {
            conversationMemory[key] = []
        }
        conversationMemory[key]?.append(entry)
        
        // 限制记忆大小
        if let entries = conversationMemory[key], entries.count > 10 {
            conversationMemory[key] = Array(entries.suffix(10))
        }
    }
    
    /**
     * 提取回复中的关键短语
     */
    private func extractKeyPhrases(from text: String) -> [String] {
        // 分句
        let sentences = text.components(separatedBy: ["。", "！", "？", "；", ".", "!", "?", ";"])
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // 如果句子较少，直接返回所有句子
        if sentences.count <= 3 {
            return sentences.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        
        // 否则选择较短的句子作为关键短语
        return sentences
            .filter { $0.count < 15 }
            .prefix(3)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    /**
     * 检查话题是否已讨论过
     */
    func isTopicDiscussed(postID: String, characterID: String, topic: String) -> Bool {
        let key = "\(postID)_\(characterID)"
        let entries = conversationMemory[key] ?? []
        
        return entries.contains { entry in
            entry.focusAspect == topic || entry.keywords.contains(topic)
        }
    }
    
    /**
     * 获取未讨论过的话题
     */
    func getNonDiscussedTopics(postID: String, characterID: String, possibleTopics: [String]) -> [String] {
        let key = "\(postID)_\(characterID)"
        let entries = conversationMemory[key] ?? []
        
        let discussedTopics = Set(entries.compactMap { $0.focusAspect })
        let discussedKeywords = Set(entries.flatMap { $0.keywords })
        
        return possibleTopics.filter { topic in
            !discussedTopics.contains(topic) && !discussedKeywords.contains(topic)
        }
    }
    
    /**
     * 根据键检索记忆
     * @param forKey 记忆键
     * @return 记忆内容数组
     */
    func retrieveMemories(forKey key: String) -> [String] {
        let entries = conversationMemory[key] ?? []
        return entries.map { "\($0.userComment) -> \($0.characterReply)" }
    }
    
    /**
     * 存储记忆
     * @param forKey 记忆键
     * @param content 记忆内容
     */
    func storeMemory(forKey key: String, content: String) {
        // 检查内容是否为提示词指令（增强提示词）
        if content.contains("请注意：") && 
           content.contains("必须直接回应用户评论的具体内容") {
            // 如果是提示词指令，只存储真实的用户评论部分
            if let userContent = content.components(separatedBy: "\n\n请注意：").first?.trimmingCharacters(in: .whitespacesAndNewlines),
               !userContent.isEmpty {
                // 创建简单记忆条目，只包含用户实际内容
                let entry = ConversationEntry(
                    userComment: userContent,
                    characterReply: "",
                    timestamp: Date(),
                    keywords: [],
                    focusAspect: nil,
                    keyPhrases: []
                )
                
                // 添加到记忆中
                if conversationMemory[key] == nil {
                    conversationMemory[key] = []
                }
                conversationMemory[key]?.append(entry)
            }
        } else {
            // 处理正常的对话记忆
            // 查找结构化的用户-角色对话模式："用户: 内容\n角色: 回复"
            if let components = extractUserAndCharacterContent(from: content) {
                let userComment = components.userComment
                let characterReply = components.characterReply
                let _ = components.characterID
                
                // 提取回复中的关键短语
                let keyPhrases = extractKeyPhrases(from: characterReply)
                
                // 创建更有信息量的对话记录
                let entry = ConversationEntry(
                    userComment: userComment,
                    characterReply: characterReply,
                    timestamp: Date(),
                    keywords: extractSimpleKeywords(from: userComment),
                    focusAspect: identifyMainTopic(in: userComment),
                    keyPhrases: keyPhrases
                )
                
                // 添加到记忆中
                if conversationMemory[key] == nil {
                    conversationMemory[key] = []
                }
                conversationMemory[key]?.append(entry)
            } else {
                // 对于不符合预期格式的内容，创建简单记忆条目
                let entry = ConversationEntry(
                    userComment: content,
                    characterReply: "",
                    timestamp: Date(),
                    keywords: [],
                    focusAspect: nil,
                    keyPhrases: []
                )
                
                // 添加到记忆中
                if conversationMemory[key] == nil {
                    conversationMemory[key] = []
                }
                conversationMemory[key]?.append(entry)
            }
        }
        
        // 限制记忆大小
        if let entries = conversationMemory[key], entries.count > 15 {
            conversationMemory[key] = Array(entries.suffix(15))
        }
    }
    
    /**
     * 从对话内容中提取用户评论和角色回复
     */
    private func extractUserAndCharacterContent(from content: String) -> (userComment: String, characterReply: String, characterID: String)? {
        // 首先尝试匹配基本格式："用户: 评论内容\n角色ID: 回复内容"
        let pattern = "用户: (.*?)\\n([^:]+): (.*)"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                let userComment = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let characterID = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                let characterReply = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 计算短评论-回复的匹配度
                let isShortComment = userComment.count <= 15
                let isProperLengthReply = isShortComment ? characterReply.count <= 40 : true
                
                // 检查是否使用了复杂比喻（仅对简短评论）
                let hasComplexMetaphor = isShortComment && (
                    characterReply.contains("如同") || 
                    characterReply.contains("仿佛") || 
                    characterReply.contains("宛如") || 
                    characterReply.contains("好比") ||
                    characterReply.contains("犹如") ||
                    (characterReply.contains("就像") && characterReply.count > 30)
                )
                
                // 记录匹配度数据，帮助优化系统
                if isShortComment {
                    let qualityAssessment = if hasComplexMetaphor {
                        "❌ 使用复杂比喻"
                    } else if !isProperLengthReply {
                        "❌ 回复过长"
                    } else {
                        "✅ 良好"
                    }
                    
                    print("🧠 记忆管理：检测到短评论(\(userComment.count)字) - 回复长度：\(characterReply.count)字，质量：\(qualityAssessment)")
                    
                    // 记录有问题的回复用于后续优化
                    if hasComplexMetaphor || !isProperLengthReply {
                        print("⚠️ 问题回复记录 - 用户评论: \"\(userComment)\" - 角色回复: \"\(characterReply.prefix(50))...\"")
                        
                        // 记录到统计信息
                        updateShortCommentStatistics(
                            userComment: userComment,
                            characterReply: characterReply,
                            characterID: characterID,
                            tooLong: !isProperLengthReply,
                            hasComplexLanguage: hasComplexMetaphor
                        )
                    }
                }
                
                return (userComment, characterReply, characterID)
            }
        }
        
        return nil
    }
    
    /**
     * 更新简短评论的统计信息
     * 用于监测和改进对简短评论的回复质量
     */
    private func updateShortCommentStatistics(
        userComment: String,
        characterReply: String,
        characterID: String,
        tooLong: Bool,
        hasComplexLanguage: Bool
    ) {
        // 获取统计键
        let statsKey = "short_comment_stats"
        
        // 获取现有统计数据
        var stats = UserDefaults.standard.dictionary(forKey: statsKey) as? [String: Int] ?? [:]
        
        // 更新总数
        let totalKey = "total_short_comments"
        stats[totalKey] = (stats[totalKey] ?? 0) + 1
        
        // 更新问题数
        if tooLong {
            let tooLongKey = "too_long_replies"
            stats[tooLongKey] = (stats[tooLongKey] ?? 0) + 1
        }
        
        if hasComplexLanguage {
            let complexKey = "complex_language_replies"
            stats[complexKey] = (stats[complexKey] ?? 0) + 1
        }
        
        // 按角色统计
        let characterKey = "character_\(characterID)_issues"
        stats[characterKey] = (stats[characterKey] ?? 0) + (tooLong || hasComplexLanguage ? 1 : 0)
        
        // 保存统计数据
        UserDefaults.standard.set(stats, forKey: statsKey)
    }
    
    /**
     * 从文本中提取简单关键词
     */
    private func extractSimpleKeywords(from text: String) -> [String] {
        // 移除常见停用词和标点
        let stopWords = ["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好", "自己", "这"]
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
                        .flatMap { $0.components(separatedBy: CharacterSet.punctuationCharacters) }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty && $0.count > 1 && !stopWords.contains($0) }
        
        // 返回最多5个关键词
        return Array(Set(words)).prefix(5).map { $0 }
    }
    
    /**
     * 识别文本中的主要话题
     */
    private func identifyMainTopic(in text: String) -> String? {
        // 简单实现，未来可以使用更复杂的NLP
        let keywords = extractSimpleKeywords(from: text)
        return keywords.first
    }
}

/**
 * 对话记录条目
 */
struct ConversationEntry {
    let userComment: String
    let characterReply: String
    let timestamp: Date
    let keywords: [String]
    let focusAspect: String?
    let keyPhrases: [String]
}

/**
 * 对话上下文
 */
struct ConversationContext {
    let relevantHistory: [ConversationEntry]
    let usedExpressions: Set<String>
    let discussedTopics: Set<String>
    let conversationDepth: Int
} 