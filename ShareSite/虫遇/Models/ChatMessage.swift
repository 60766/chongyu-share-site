import Foundation

/// 聊天消息数据模型
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let characterId: String
    let content: String
    let timestamp: Date
    var isThinking: Bool = false  // 表示角色是否处于"思考中"状态
    var isUserMessage: Bool = false  // 表示是否为用户引导消息
    
    // 实现Equatable协议
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.characterId == rhs.characterId &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp &&
               lhs.isThinking == rhs.isThinking &&
               lhs.isUserMessage == rhs.isUserMessage
    }
}

// MARK: - 示例数据

extension ChatMessage {
    static func sampleMessages(characters: [CharacterModel]) -> [ChatMessage] {
        guard !characters.isEmpty else { return [] }
        
        let now = Date()
        var messages: [ChatMessage] = []
        
        // 第一个角色的消息
        if let firstCharacter = characters.first {
            messages.append(
                ChatMessage(
                    characterId: firstCharacter.id,
                    content: "大家好！今天我们来讨论一个有趣的话题。",
                    timestamp: now.addingTimeInterval(-60)
                )
            )
        }
        
        // 第二个角色的消息
        if characters.count > 1 {
            messages.append(
                ChatMessage(
                    characterId: characters[1].id,
                    content: "我很期待这次讨论，相信会有很多思想的碰撞！",
                    timestamp: now.addingTimeInterval(-30)
                )
            )
        }
        
        // 用户引导消息示例
        messages.append(
            ChatMessage(
                characterId: "user",
                content: "请讨论一下科学与艺术的关系。",
                timestamp: now.addingTimeInterval(-20),
                isUserMessage: true
            )
        )
        
        // 第三个角色的思考状态
        if characters.count > 2 {
            messages.append(
                ChatMessage(
                    characterId: characters[2].id,
                    content: "",
                    timestamp: now,
                    isThinking: true
                )
            )
        }
        
        return messages
    }
} 