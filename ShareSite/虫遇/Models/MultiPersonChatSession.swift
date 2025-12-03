import Foundation
import SwiftData

/**
 * 多人聊天会话数据模型
 * 存储多人聊天的基本信息和会话历史
 */
@Model
final class MultiPersonChatSession: Identifiable {
    /// 会话ID
    var id: String
    /// 会话主题
    var topic: String
    /// 参与者角色ID列表
    var participantIds: [String]
    /// 参与者名称列表（用于显示）
    var participantNames: [String]
    /// 聊天模式
    var chatMode: String
    /// 聊天主题
    var chatTheme: String
    /// 用户角色
    var userRole: String
    /// 消息数量
    var messageCount: Int
    /// 最后活跃时间
    var lastActiveTime: Date
    /// 创建时间
    var createdAt: Date
    /// 更新时间
    var updatedAt: Date
    /// 是否已完成
    var isCompleted: Bool
    
    /**
     * 初始化多人聊天会话
     */
    init(
        id: String = UUID().uuidString,
        topic: String,
        participantIds: [String],
        participantNames: [String],
        chatMode: String,
        chatTheme: String,
        userRole: String,
        messageCount: Int = 0,
        lastActiveTime: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.id = id
        self.topic = topic
        self.participantIds = participantIds
        self.participantNames = participantNames
        self.chatMode = chatMode
        self.chatTheme = chatTheme
        self.userRole = userRole
        self.messageCount = messageCount
        self.lastActiveTime = lastActiveTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isCompleted = isCompleted
    }
}

/**
 * 多人聊天消息数据模型
 * 存储多人聊天中的具体消息
 */
@Model
final class MultiPersonChatMessage: Identifiable {
    /// 消息ID
    var id: String
    /// 会话ID
    var sessionId: String
    /// 角色ID
    var characterId: String
    /// 角色名称
    var characterName: String
    /// 消息内容
    var content: String
    /// 时间戳
    var timestamp: Date
    /// 是否为用户消息
    var isUserMessage: Bool
    /// 消息类型（text, guidance等）
    var messageType: String
    
    /**
     * 初始化多人聊天消息
     */
    init(
        id: String = UUID().uuidString,
        sessionId: String,
        characterId: String,
        characterName: String,
        content: String,
        timestamp: Date = Date(),
        isUserMessage: Bool = false,
        messageType: String = "text"
    ) {
        self.id = id
        self.sessionId = sessionId
        self.characterId = characterId
        self.characterName = characterName
        self.content = content
        self.timestamp = timestamp
        self.isUserMessage = isUserMessage
        self.messageType = messageType
    }
} 