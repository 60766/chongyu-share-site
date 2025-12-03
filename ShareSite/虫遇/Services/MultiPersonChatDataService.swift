import Foundation
import SwiftData
import SwiftUI

/**
 * 多人聊天数据管理服务
 * 负责多人聊天会话和消息的数据持久化操作
 */
class MultiPersonChatDataService {
    static let shared = MultiPersonChatDataService()
    
    init() {}
    
    // MARK: - 会话管理
    
    /**
     * 创建新的多人聊天会话
     */
    func createChatSession(
        topic: String,
        participants: [CharacterModel],
        chatMode: ChatMode,
        chatTheme: String,
        userRole: UserRole,
        modelContext: ModelContext
    ) -> MultiPersonChatSession {
        let session = MultiPersonChatSession(
            topic: topic,
            participantIds: participants.map { $0.id },
            participantNames: participants.map { $0.name },
            chatMode: chatMode.rawValue,
            chatTheme: chatTheme,
            userRole: userRole.rawValue
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            print("✅ 多人聊天会话已创建: \(session.id)")
        } catch {
            print("❌ 创建多人聊天会话失败: \(error.localizedDescription)")
        }
        
        return session
    }
    
    /**
     * 获取所有聊天会话历史
     */
    func getChatSessions(modelContext: ModelContext) -> [MultiPersonChatSession] {
        do {
            let descriptor = FetchDescriptor<MultiPersonChatSession>(
                sortBy: [SortDescriptor(\.lastActiveTime, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ 获取聊天会话失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /**
     * 更新会话最后活跃时间和消息数量
     */
    func updateSessionActivity(
        sessionId: String,
        messageCount: Int,
        modelContext: ModelContext
    ) {
        do {
            let predicate = #Predicate<MultiPersonChatSession> { session in
                session.id == sessionId
            }
            let descriptor = FetchDescriptor<MultiPersonChatSession>(predicate: predicate)
            
            if let session = try modelContext.fetch(descriptor).first {
                session.lastActiveTime = Date()
                session.messageCount = messageCount
                session.updatedAt = Date()
                
                try modelContext.save()
                print("✅ 会话活跃度已更新: \(sessionId)")
            }
        } catch {
            print("❌ 更新会话活跃度失败: \(error.localizedDescription)")
        }
    }
    
    /**
     * 删除聊天会话
     */
    func deleteChatSession(sessionId: String, modelContext: ModelContext) {
        do {
            // 删除会话相关的所有消息
            let messagesPredicate = #Predicate<MultiPersonChatMessage> { message in
                message.sessionId == sessionId
            }
            let messagesDescriptor = FetchDescriptor<MultiPersonChatMessage>(predicate: messagesPredicate)
            let messages = try modelContext.fetch(messagesDescriptor)
            
            for message in messages {
                modelContext.delete(message)
            }
            
            // 删除会话
            let sessionPredicate = #Predicate<MultiPersonChatSession> { session in
                session.id == sessionId
            }
            let sessionDescriptor = FetchDescriptor<MultiPersonChatSession>(predicate: sessionPredicate)
            
            if let session = try modelContext.fetch(sessionDescriptor).first {
                modelContext.delete(session)
                try modelContext.save()
                print("✅ 聊天会话已删除: \(sessionId)")
            }
        } catch {
            print("❌ 删除聊天会话失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 消息管理
    
    /**
     * 保存聊天消息
     */
    func saveChatMessage(
        sessionId: String,
        characterId: String,
        characterName: String,
        content: String,
        isUserMessage: Bool,
        messageType: String = "text",
        modelContext: ModelContext
    ) -> MultiPersonChatMessage {
        let message = MultiPersonChatMessage(
            sessionId: sessionId,
            characterId: characterId,
            characterName: characterName,
            content: content,
            isUserMessage: isUserMessage,
            messageType: messageType
        )
        
        modelContext.insert(message)
        
        do {
            try modelContext.save()
            
            // 更新会话的消息计数
            updateMessageCount(sessionId: sessionId, modelContext: modelContext)
            
            print("✅ 聊天消息已保存: \(message.id)")
        } catch {
            print("❌ 保存聊天消息失败: \(error.localizedDescription)")
        }
        
        return message
    }
    
    /**
     * 获取会话的所有消息
     */
    func getChatMessages(sessionId: String, modelContext: ModelContext) -> [MultiPersonChatMessage] {
        do {
            let predicate = #Predicate<MultiPersonChatMessage> { message in
                message.sessionId == sessionId
            }
            let descriptor = FetchDescriptor<MultiPersonChatMessage>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ 获取聊天消息失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /**
     * 更新会话的消息计数
     */
    private func updateMessageCount(sessionId: String, modelContext: ModelContext) {
        do {
            let predicate = #Predicate<MultiPersonChatMessage> { message in
                message.sessionId == sessionId
            }
            let descriptor = FetchDescriptor<MultiPersonChatMessage>(predicate: predicate)
            let messageCount = try modelContext.fetch(descriptor).count
            
            updateSessionActivity(sessionId: sessionId, messageCount: messageCount, modelContext: modelContext)
        } catch {
            print("❌ 更新消息计数失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 数据转换
    
    /**
     * 将多人聊天会话转换为ChatHistoryItem
     */
    func convertToChatHistoryItem(_ session: MultiPersonChatSession) -> ChatHistoryItem {
        // 如果没有设置主题或主题为空，则显示"自由对话"
        let displayTopic = session.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "自由对话" : session.topic
        
        return ChatHistoryItem(
            topic: displayTopic,
            participants: session.participantNames,
            messageCount: session.messageCount,
            lastActiveTime: session.lastActiveTime,
            chatId: session.id
        )
    }
    
    /**
     * 获取指定会话
     */
    func getChatSession(sessionId: String, modelContext: ModelContext) -> MultiPersonChatSession? {
        let descriptor = FetchDescriptor<MultiPersonChatSession>(
            predicate: #Predicate<MultiPersonChatSession> { session in
                session.id == sessionId
            }
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            return sessions.first
        } catch {
            print("❌ 获取会话失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
     * 将多人聊天消息转换为ChatMessage
     */
    func convertToChatMessage(_ dbMessage: MultiPersonChatMessage) -> ChatMessage {
        return ChatMessage(
            characterId: dbMessage.characterId,
            content: dbMessage.content,
            timestamp: dbMessage.timestamp,
            isUserMessage: dbMessage.isUserMessage
        )
    }
    
    /**
     * 批量转换消息
     */
    func convertToChatMessages(_ dbMessages: [MultiPersonChatMessage]) -> [ChatMessage] {
        return dbMessages.map { convertToChatMessage($0) }
    }
} 