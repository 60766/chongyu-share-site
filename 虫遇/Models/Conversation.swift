import Foundation
import SwiftData

/**
 * 对话模型类，表示用户与角色的对话会话
 * 注意：已将此类型重命名为SDConversation，以避免与UIConversation结构体命名冲突
 * 所有与SwiftData相关的操作应使用此SDConversation类型
 */
@Model
final class SDConversation: Identifiable {
    /// 对话ID
    var id: String
    /// 角色ID
    var characterId: String
    /// 用户ID
    var userId: String
    /// 最后一条消息内容
    var lastMessageContent: String
    /// 最后一条消息时间
    var lastMessageTime: Date
    /// 消息数量
    var messageCount: Int
    /// 创建时间
    var createdAt: Date
    /// 更新时间
    var updatedAt: Date
    
    /**
     * 初始化一个对话实例
     * @param id - 对话唯一标识
     * @param characterId - 角色ID
     * @param userId - 用户ID
     * @param lastMessageContent - 最后一条消息内容
     * @param lastMessageTime - 最后一条消息时间
     * @param messageCount - 消息数量
     * @param createdAt - 创建时间
     * @param updatedAt - 更新时间
     */
    init(
        id: String = UUID().uuidString,
        characterId: String,
        userId: String,
        lastMessageContent: String = "",
        lastMessageTime: Date = Date(),
        messageCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.characterId = characterId
        self.userId = userId
        self.lastMessageContent = lastMessageContent
        self.lastMessageTime = lastMessageTime
        self.messageCount = messageCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/**
 * UI对话模型结构体
 * 用于视图层显示对话信息，避免直接在视图中使用SwiftData模型
 */
struct UIConversation: Identifiable {
    /// 对话ID
    var id: String
    /// 角色ID
    var characterId: String
    /// 用户ID
    var userId: String
    /// 最后一条消息内容
    var lastMessageContent: String
    /// 最后一条消息时间
    var lastMessageTime: Date
    /// 消息数量
    var messageCount: Int
    
    /**
     * 初始化一个UI对话实例
     * @param id - 对话唯一标识
     * @param characterId - 角色ID
     * @param userId - 用户ID
     * @param lastMessageContent - 最后一条消息内容
     * @param lastMessageTime - 最后一条消息时间
     * @param messageCount - 消息数量
     */
    init(
        id: String = UUID().uuidString,
        characterId: String,
        userId: String,
        lastMessageContent: String = "",
        lastMessageTime: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.characterId = characterId
        self.userId = userId
        self.lastMessageContent = lastMessageContent
        self.lastMessageTime = lastMessageTime
        self.messageCount = messageCount
    }
    
    /**
     * 从SwiftData模型转换为UI模型
     * @param sdConversation - SwiftData对话模型
     */
    init(from sdConversation: SDConversation) {
        self.id = sdConversation.id
        self.characterId = sdConversation.characterId
        self.userId = sdConversation.userId
        self.lastMessageContent = sdConversation.lastMessageContent
        self.lastMessageTime = sdConversation.lastMessageTime
        self.messageCount = sdConversation.messageCount
    }
} 