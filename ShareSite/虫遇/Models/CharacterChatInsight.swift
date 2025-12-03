import Foundation
import SwiftData

/**
 * 角色聊天画像数据模型
 * 基于用户与单个角色的一对一聊天生成的个性化画像
 */
struct CharacterChatInsight: Codable, Identifiable {
    let id: String
    /// 画像标题（简短有趣，<=12字）
    let title: String
    /// 一句话总结（80-120字，轻松自然）
    let summary: String
    /// 个性标签（最多3个）
    let tags: [String]
    /// 最近关注点（1-2句话）
    let recentFocus: String
    /// 下一步建议（1句话）
    let nextSuggestion: String
    /// 生成时间
    let generatedAt: Date
    /// 角色ID
    let characterId: String
    /// 角色名称
    let characterName: String
    
    init(
        id: String = UUID().uuidString,
        title: String,
        summary: String,
        tags: [String],
        recentFocus: String,
        nextSuggestion: String,
        generatedAt: Date = Date(),
        characterId: String,
        characterName: String
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.tags = tags
        self.recentFocus = recentFocus
        self.nextSuggestion = nextSuggestion
        self.generatedAt = generatedAt
        self.characterId = characterId
        self.characterName = characterName
    }
}

/**
 * 画像缓存模型（用于SwiftData持久化）
 */
@Model
final class CharacterChatInsightCache {
    /// 缓存ID（conversationId）
    var id: String
    /// 角色ID
    var characterId: String
    /// 角色名称
    var characterName: String
    /// 画像数据（JSON编码）
    var insightData: Data
    /// 生成时间
    var generatedAt: Date
    /// 基于的消息数量
    var messageCount: Int
    /// 最后一条消息的时间戳（用于判断是否需要更新）
    var lastMessageTimestamp: Date
    
    init(
        id: String = UUID().uuidString,
        characterId: String = "",
        characterName: String = "",
        insightData: Data = Data(),
        generatedAt: Date = Date(),
        messageCount: Int = 0,
        lastMessageTimestamp: Date = Date()
    ) {
        self.id = id
        self.characterId = characterId
        self.characterName = characterName
        self.insightData = insightData
        self.generatedAt = generatedAt
        self.messageCount = messageCount
        self.lastMessageTimestamp = lastMessageTimestamp
    }
}

/**
 * AI响应的JSON格式
 */
struct CharacterChatInsightResponse: Codable {
    let title: String
    let summary: String
    let tags: [String]
    let recentFocus: String
    let nextSuggestion: String
}

