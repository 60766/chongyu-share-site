import Foundation
import SwiftData

/**
 * 消息模型类，表示用户与角色之间的对话消息
 */
@Model
final class Message {
    /// 消息ID
    var id: String
    /// 对话ID
    var conversationId: String
    /// 发送者ID（用户ID或角色ID）
    var senderId: String
    /// 接收者ID（用户ID或角色ID）
    var receiverId: String
    /// 消息内容
    var content: String
    /// 是否是用户发送的消息
    var isFromUser: Bool
    /// 发送时间
    var timestamp: Date
    /// 是否已读
    var isRead: Bool
    /// 相关标签
    var tags: [String]
    
    /**
     * 初始化一个消息实例
     * @param id - 消息唯一标识
     * @param conversationId - 对话ID
     * @param senderId - 发送者ID
     * @param receiverId - 接收者ID
     * @param content - 消息内容
     * @param isFromUser - 是否是用户发送的消息
     * @param timestamp - 发送时间
     * @param isRead - 是否已读
     * @param tags - 相关标签
     */
    init(
        id: String = UUID().uuidString,
        conversationId: String,
        senderId: String,
        receiverId: String,
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        isRead: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.isRead = isRead
        self.tags = tags
    }
} 