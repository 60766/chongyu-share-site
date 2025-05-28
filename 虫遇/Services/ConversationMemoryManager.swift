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