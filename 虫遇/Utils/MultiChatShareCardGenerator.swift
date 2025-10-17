import SwiftUI
import UIKit

/**
 * 多人聊天分享卡片生成器
 * 用于生成多人对话的精美分享卡片
 */
class MultiChatShareCardGenerator {
    
    /// 生成分享卡片图片
    static func generateCard(
        message: ChatMessage,
        character: CharacterModel,
        theme: String
    ) -> UIImage {
        
        let cardView = MultiChatShareCardView(
            message: message,
            character: character,
            theme: theme
        )
        
        return cardView.asUIImage()
    }
    
    /// 批量生成分享卡片
    static func generateCards(
        messages: [ChatMessage],
        characters: [CharacterModel],
        theme: String
    ) -> [UIImage] {
        
        return messages.enumerated().map { index, message in
            let character = characters.first(where: { $0.id == message.characterId }) ?? characters.first!
            
            let cardView = MultiChatShareCardView(
                message: message,
                character: character,
                theme: theme,
                cardIndex: index + 1,
                totalCards: messages.count
            )
            
            return cardView.asUIImage()
        }
    }
    
    /// 生成合并对话卡片（将多条消息合并到一张卡片上）
    static func generateMergedCard(
        messages: [ChatMessage],
        characters: [CharacterModel],
        theme: String
    ) -> UIImage {
        
        let cardView = MultiChatMergedCardView(
            messages: messages,
            characters: characters,
            theme: theme
        )
        
        return cardView.asUIImage()
    }
}

/**
 * 多人聊天合并卡片视图（显示多条消息的对话）
 */
struct MultiChatMergedCardView: View {
    let messages: [ChatMessage]
    let characters: [CharacterModel]
    let theme: String
    
    var body: some View {
        VStack(spacing: 0) {
            // 简化的顶部区域
            simplifiedHeaderSection
            
            // 主要内容区域 - 对话列表
            contentSection
            
            // 底部水印区域
            footerSection
        }
        .frame(width: 350)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color(hex: "FAFBFC")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
    
    // 简化的顶部区域
    private var simplifiedHeaderSection: some View {
        VStack(spacing: 8) {
            // 对话主题（如果有）
            if !theme.isEmpty {
                Text(theme)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // 简单分割线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // 底部水印区域（保留下方的统一实现，移除此处重复定义）
    // 已合并到文件后半部分的 footerSection 定义中
    
    // 参与角色展示
    private var participantsSection: some View {
        let uniqueCharacters = getUniqueCharacters()
        
        return HStack(spacing: 8) {
            ForEach(Array(uniqueCharacters.enumerated()), id: \.offset) { index, character in
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    category: character.category.rawValue,
                    size: 30,
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(getCharacterColor(for: character).opacity(0.3), lineWidth: 1.5)
                )
                
                if index < uniqueCharacters.count - 1 {
                    Text(character.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if messages.contains(where: { $0.isUserMessage }) {
                Text("引导者")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // 主要内容区域 - 对话列表（移除高度限制）
    private var contentSection: some View {
        VStack(spacing: 8) {
            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                messageRow(message: message, index: index)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // 单条消息行
    private func messageRow(message: ChatMessage, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUserMessage {
                // 角色头像
                if let character = characters.first(where: { $0.id == message.characterId }) {
                    CharacterAvatarService.shared.getAvatarView(
                        for: character.id,
                        name: character.name,
                        category: character.category.rawValue,
                        size: 35,
                        useCaching: true
                    )
                    .overlay(
                        Circle()
                            .stroke(getCharacterColor(for: character).opacity(0.3), lineWidth: 1.5)
                    )
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 35, height: 35)
                }
            } else {
                Spacer()
            }
            
            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 4) {
                // 发送者名称
                if !message.isUserMessage {
                    if let character = characters.first(where: { $0.id == message.characterId }) {
                        Text(character.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(getCharacterColor(for: character))
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("引导者")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "B8B5FF"))
                    }
                }
                
                // 消息内容
                Text(formatMessageContent(message.content))
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                message.isUserMessage
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "B8B5FF").opacity(0.8),
                                        Color(hex: "C7C4FF").opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        getMessageBackgroundColor(for: message).opacity(0.1),
                                        getMessageBackgroundColor(for: message).opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(message.isUserMessage ? .white : .primary)
            }
            
            if message.isUserMessage {
                Circle()
                    .fill(Color(hex: "B8B5FF"))
                    .frame(width: 35, height: 35)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
            } else {
                Spacer()
            }
        }
    }
    
    // 底部信息区域
    private var footerSection: some View {
        VStack(spacing: 8) {
            // 时间戳
            if let firstMessage = messages.first {
                Text(formatTime(firstMessage.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // 品牌标识
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "9A8BB0"))
                
                Text("虫遇APP - 穿越时空，与历史对话")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // 获取唯一角色列表
    private func getUniqueCharacters() -> [CharacterModel] {
        let characterIds = Set(messages.compactMap { $0.isUserMessage ? nil : $0.characterId })
        return characterIds.compactMap { id in
            characters.first(where: { $0.id == id })
        }
    }
    
    // 获取角色主题色
    private func getCharacterColor(for character: CharacterModel) -> Color {
        switch character.category {
        case .scientist:
            return Color(hex: "4A90E2")
        case .philosopher:
            return Color(hex: "9A8BB0")
        case .artist:
            return Color(hex: "F5A623")
        case .writer:
            return Color(hex: "50E3C2")
        case .animeCharacter:
            return Color(hex: "BD10E0")
        case .gameCharacter:
            return Color(hex: "B8E986")
        case .movieCharacter:
            return Color(hex: "7ED321")
        case .tvCharacter:
            return Color(hex: "F8E71C")
        case .mythCharacter:
            return Color(hex: "417505")
        case .fictionCharacter:
            return Color(hex: "9013FE")
        case .vtuber:
            return Color(hex: "FF6B9D")
        case .historical:
            return Color(hex: "8B4513")
        case .all:
            return Color(hex: "9A8BB0")
        }
    }
    
    // 获取消息背景色
    private func getMessageBackgroundColor(for message: ChatMessage) -> Color {
        if let character = characters.first(where: { $0.id == message.characterId }) {
            return getCharacterColor(for: character)
        }
        return Color(hex: "9A8BB0")
    }
    
    // 格式化消息内容
    private func formatMessageContent(_ content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 对于合并卡片，稍微放宽长度限制
        if trimmedContent.count > 120 {
            let truncated = String(trimmedContent.prefix(100))
            return truncated + "..."
        }
        
        return trimmedContent
    }
    
    // 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

/**
 * 多人聊天分享卡片视图
 */
struct MultiChatShareCardView: View {
    let message: ChatMessage
    let character: CharacterModel
    let theme: String
    let cardIndex: Int?
    let totalCards: Int?
    
    init(
        message: ChatMessage,
        character: CharacterModel,
        theme: String,
        cardIndex: Int? = nil,
        totalCards: Int? = nil
    ) {
        self.message = message
        self.character = character
        self.theme = theme
        self.cardIndex = cardIndex
        self.totalCards = totalCards
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部品牌区域
            headerSection
            
            // 主要内容区域
            contentSection
            
            // 底部信息区域
            footerSection
        }
        .frame(width: 350, height: 500)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color(hex: "FAFBFC")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
    
    // 顶部品牌区域
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                // 虫遇Logo和标题
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "9A8BB0"))
                    
                    Text("虫遇 - 多人对话")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 卡片序号（如果有多张卡片）
                if let cardIndex = cardIndex, let totalCards = totalCards, totalCards > 1 {
                    Text("\(cardIndex)/\(totalCards)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            
            // 对话主题
            if !theme.isEmpty {
                Text(theme)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "9A8BB0").opacity(0.1))
                    )
            }
            
            // 分割线
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "9A8BB0").opacity(0.3),
                            Color(hex: "9A8BB0").opacity(0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // 主要内容区域
    private var contentSection: some View {
        VStack(spacing: 16) {
            // 角色信息
            if !message.isUserMessage {
                HStack(spacing: 12) {
                    // 角色头像
                    CharacterAvatarService.shared.getAvatarView(
                        for: character.id,
                        name: character.name,
                        category: character.category.rawValue,
                        size: 50,
                        useCaching: true
                    )
                    .overlay(
                        Circle()
                            .stroke(getCharacterColor().opacity(0.3), lineWidth: 2)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(character.category.displayName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            // 消息内容
            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 8) {
                // 消息气泡
                Text(formatMessageContent(message.content))
                    .font(.system(size: 16, weight: .medium))
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                message.isUserMessage
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "B8B5FF"),
                                        Color(hex: "C7C4FF")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        getCharacterColor().opacity(0.1),
                                        getCharacterColor().opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(message.isUserMessage ? .white : .primary)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // 发送者标识
                if message.isUserMessage {
                    HStack {
                        Spacer()
                        Text("引导者")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // 底部信息区域
    private var footerSection: some View {
        VStack(spacing: 8) {
            // 时间戳
            Text(formatTime(message.timestamp))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            // 品牌标识
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "9A8BB0"))
                
                Text("虫遇APP - 穿越时空，与历史对话")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // 获取角色主题色
    private func getCharacterColor() -> Color {
        // 根据角色类别返回不同的主题色
        switch character.category {
        case .scientist:
            return Color(hex: "4A90E2")
        case .philosopher:
            return Color(hex: "9A8BB0")
        case .artist:
            return Color(hex: "F5A623")
        case .writer:
            return Color(hex: "50E3C2")
        case .animeCharacter:
            return Color(hex: "BD10E0")
        case .gameCharacter:
            return Color(hex: "B8E986")
        case .movieCharacter:
            return Color(hex: "7ED321")
        case .tvCharacter:
            return Color(hex: "F8E71C")
        case .mythCharacter:
            return Color(hex: "417505")
        case .fictionCharacter:
            return Color(hex: "9013FE")
        case .vtuber:
            return Color(hex: "FF6B9D")
        case .historical:
            return Color(hex: "8B4513")
        case .all:
            return Color(hex: "9A8BB0")
        }
    }
    
    // 格式化消息内容
    private func formatMessageContent(_ content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果内容过长，进行截取
        if trimmedContent.count > 200 {
            let truncated = String(trimmedContent.prefix(180))
            return truncated + "..."
        }
        
        return trimmedContent
    }
    
    // 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let sampleMessage = ChatMessage(
        characterId: "confucius",
        content: "学而时习之，不亦说乎？有朋自远方来，不亦乐乎？人不知而不愠，不亦君子乎？",
        timestamp: Date()
    )
    
    let sampleCharacter = CharacterModel(
        id: "confucius",
        name: "孔子",
        avatar: "confucius",
        era: "春秋时期",
        profession: "思想家、教育家",
        bio: "中国古代思想家、教育家，儒家学说的创立者",
        category: .philosopher
    )
    
    MultiChatShareCardView(
        message: sampleMessage,
        character: sampleCharacter,
        theme: "探讨教育的本质",
        cardIndex: 1,
        totalCards: 3
    )
    // traits: .sizeThatFitsLayout will handle sizing
}
