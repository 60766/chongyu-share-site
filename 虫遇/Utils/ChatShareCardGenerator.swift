import SwiftUI
import UIKit

/**
 * 聊天分享卡片生成器
 * 用于生成精美的聊天消息分享卡片
 */
class ChatShareCardGenerator {
    
    /// 生成分享卡片图片
    static func generateCard(
        message: Message,
        character: CYChatCharacter,
        characterThemeColor: Color
    ) -> UIImage {
        
        let cardView = ChatShareCardView(
            message: message,
            character: character,
            characterThemeColor: characterThemeColor
        )
        
        return cardView.asUIImage()
    }
    
    /// 批量生成分享卡片
    static func generateCards(
        messages: [Message],
        character: CYChatCharacter,
        characterThemeColor: Color
    ) -> [UIImage] {
        
        return messages.enumerated().map { index, message in
            let cardView = ChatShareCardView(
                message: message,
                character: character,
                characterThemeColor: characterThemeColor,
                cardIndex: index + 1,
                totalCards: messages.count
            )
            
            return cardView.asUIImage()
        }
    }
}

/**
 * 聊天分享卡片视图
 */
struct ChatShareCardView: View {
    let message: Message
    let character: CYChatCharacter
    let characterThemeColor: Color
    let cardIndex: Int?
    let totalCards: Int?
    
    init(
        message: Message,
        character: CYChatCharacter,
        characterThemeColor: Color,
        cardIndex: Int? = nil,
        totalCards: Int? = nil
    ) {
        self.message = message
        self.character = character
        self.characterThemeColor = characterThemeColor
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
                        .foregroundColor(characterThemeColor)
                    
                    Text("虫遇 - 与历史对话")
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
            
            // 分割线
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            characterThemeColor.opacity(0.3),
                            characterThemeColor.opacity(0.1)
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
            if !message.isFromUser {
                HStack(spacing: 12) {
                    // 角色头像
                    AsyncImage(url: URL(string: character.avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(characterThemeColor.opacity(0.2))
                            .overlay(
                                Text(String(character.name.prefix(1)))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(characterThemeColor)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(characterThemeColor.opacity(0.3), lineWidth: 2)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(character.field)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            // 消息内容
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 8) {
                // 消息气泡
                Text(formatMessageContent(message.content))
                    .font(.system(size: 16, weight: .medium))
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                message.isFromUser
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
                                        Color(hex: "F8F9FA"),
                                        Color(hex: "F1F3F4")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // 发送者标识
                if message.isFromUser {
                    HStack {
                        Spacer()
                        Text("我")
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
                    .foregroundColor(characterThemeColor)
                
                Text("虫遇APP - 穿越时空，与历史对话")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
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

// SwiftUI View 转 UIImage 扩展
extension View {
    func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // 设置视图大小
        controller.view.frame = CGRect(x: 0, y: 0, width: 350, height: 500)
        controller.view.backgroundColor = UIColor.clear
        
        // 渲染为图片
        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        
        return renderer.image { context in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let sampleMessage = Message(
        conversationId: "test",
        senderId: "einstein",
        receiverId: "user",
        content: "你以为相对论是灵光乍现？那个追着光奔跑的邮局小职员，在伯尔尼的阁楼里啃了八年发霉面包才抓住时空的衣角。",
        isFromUser: false
    )
    
    let sampleCharacter = CYChatCharacter(
        id: "einstein",
        name: "爱因斯坦",
        introduction: "理论物理学家",
        field: "物理学",
        birthYear: "1879",
        deathYear: "1955",
        avatarUrl: "",
        eraTag: "现代",
        achievements: [],
        mainWorks: [],
        keyThoughts: []
    )
    
    return ChatShareCardView(
        message: sampleMessage,
        character: sampleCharacter,
        characterThemeColor: .blue,
        cardIndex: 1,
        totalCards: 3
    )
    // traits: .sizeThatFitsLayout will handle sizing
}
