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
        
        // 使用动态尺寸渲染并应用圆角
        let cardHeight = cardView.calculateOptimalHeight()
        let rawImage = cardView.asUIImage(size: CGSize(width: 350, height: cardHeight))
        return rawImage.withRoundedCorners(radius: 24)
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
            
            // 使用动态尺寸渲染并应用圆角
            let cardHeight = cardView.calculateOptimalHeight()
            let rawImage = cardView.asUIImage(size: CGSize(width: 350, height: cardHeight))
            return rawImage.withRoundedCorners(radius: 24)
        }
    }
    
    /// 生成合并对话卡片（将多条消息合并到一张卡片上）
    static func generateMergedCard(
        messages: [Message],
        character: CYChatCharacter,
        characterThemeColor: Color
    ) -> UIImage {
        
        let cardView = ChatMergedCardView(
            messages: messages,
            character: character,
            characterThemeColor: characterThemeColor
        )
        
        // 使用动态尺寸渲染并应用圆角
        let cardHeight = cardView.calculateOptimalHeight()
        let rawImage = cardView.asUIImage(size: CGSize(width: 350, height: cardHeight))
        return rawImage.withRoundedCorners(radius: 24)
    }
}

/**
 * 聊天分享卡片视图（与多人聊天样式完全一致）
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
    
    // 计算最佳高度（针对单条消息优化，更加紧凑）
    func calculateOptimalHeight() -> CGFloat {
        // 1. 固定高度部分
        let headerHeight: CGFloat = 36  // 顶部固定高度
        let footerHeight: CGFloat = 70  // 底部固定高度
        let contentVerticalPadding: CGFloat = 16 // 内容区域上下padding
        
        // 2. 单条消息的精确高度计算
        let avatarHeight: CGFloat = 35 // 头像高度
        let nameHeight: CGFloat = 16   // 名称标签高度
        
        // 3. 估算文本高度
        let textLength = message.content.count
        let charactersPerLine: CGFloat = 20 // 每行约20个字符（考虑中文）
        let estimatedLines = max(2, ceil(CGFloat(textLength) / charactersPerLine))
        let textHeight = estimatedLines * 17 + 12 // 17 = 13pt字体 + 2pt行间距 + 2pt额外空间，+12为文本padding
        
        // 4. VStack间距（名称和文本之间）
        let vStackSpacing: CGFloat = 5 // 实际代码中的spacing
        
        // 5. 消息内容区域高度（取头像和内容的最大值）
        let contentHeight = nameHeight + vStackSpacing + textHeight
        let messageContentHeight = max(avatarHeight, contentHeight)
        
        // 6. 计算总高度
        let totalHeight = headerHeight + 
                         footerHeight + 
                         contentVerticalPadding + 
                         messageContentHeight
        
        // 7. 设置合理的高度范围（单条消息更紧凑）
        let minHeight: CGFloat = 260  // 降低最小高度
        let maxHeight: CGFloat = 800  // 单条消息不会太长
        
        return max(minHeight, min(maxHeight, totalHeight))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 简化的顶部区域 - 固定高度
            headerSection
                .frame(height: 36)  // 固定顶部高度
            
            // 主要内容区域 - 对话消息（动态高度）
            contentSection
            
            // 底部水印区域 - 固定高度
            footerSection
                .frame(height: 70)  // 固定底部高度
        }
        .frame(width: 350, height: calculateOptimalHeight())
        .background(
            ZStack {
                // 主渐变（从上到下）- 参考主页面的梦幻渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFF0F5"),  // 更亮的粉白色
                        Color(hex: "FFE8F0"),  // 亮粉色
                        Color(hex: "F0E8FF"),  // 亮紫色
                        Color(hex: "E8F4FF"),  // 亮蓝色
                        Color(hex: "FFE8D4")   // 淡橙色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 顶部水平渐变层（从左到右的色彩变化）
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFE8F0").opacity(0.4),  // 左侧粉色
                        Color(hex: "FFD4E5").opacity(0.3),  // 粉红色
                        Color.clear,                         // 中间透明
                        Color(hex: "E8F4FF").opacity(0.3),  // 淡蓝色
                        Color(hex: "F0E8FF").opacity(0.4)   // 右侧紫色
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                // 左上角明亮色彩点缀
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),           // 亮白色中心
                        Color(hex: "FFFEF5").opacity(0.5),  // 极淡的奶白色
                        Color(hex: "FFF9E6").opacity(0.3),  // 非常淡的奶白色
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 200
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: "9A8BB0").opacity(0.15), radius: 25, x: 0, y: 12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // 简化的顶部区域（与MultiChatShareCardView保持一致）
    private var headerSection: some View {
        VStack(spacing: 4) {
            // 对话主题 - 显示角色名称
            Text("与\(character.name)的对话")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)  // 限制一行，避免撑高
                .padding(.horizontal, 20)
                .padding(.top, 8)  // 顶部固定间距
            
            Spacer(minLength: 0)
            
            // 简单分割线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)  // 底部固定间距
        }
    }
    
    // 主要内容区域（与MultiChatShareCardView保持一致）
    private var contentSection: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isFromUser {
                // 角色头像 - 使用CharacterAvatarService确保头像正确渲染
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    size: 35,
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(characterThemeColor.opacity(0.3), lineWidth: 1.5)
                )
            } else {
                // 用户消息：显示真实用户头像
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 5) {
                // 发送者名称
                if !message.isFromUser {
                    Text(character.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(characterThemeColor)
                        .padding(.bottom, 2)
                } else {
                    // 用户消息：显示真实用户名
                    HStack {
                        Spacer()
                        Text(UserProfileManager.shared.getCurrentUsername())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "B8B5FF"))
                            .padding(.bottom, 2)
                    }
                }
                
                // 消息内容
                Text(formatMessageContent(message.content))
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            // 主背景
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "B8B5FF"),
                                            Color(hex: "A8A5FF"),
                                            Color(hex: "9B98FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color(hex: "FAFBFF"),
                                            Color(hex: "F5F7FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // 装饰性边框
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            characterThemeColor.opacity(0.2),
                                            characterThemeColor.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: message.isFromUser 
                            ? Color(hex: "B8B5FF").opacity(0.25)
                            : characterThemeColor.opacity(0.15),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
            }
            
            if message.isFromUser {
                // 用户消息：显示真实用户头像
                Group {
                    if let userAvatar = UserProfileManager.shared.getCurrentAvatarImage() {
                        Image(uiImage: userAvatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                    } else {
                        // 如果没有自定义头像，尝试加载默认头像
                        let avatarName = UserProfileManager.shared.getCurrentAvatarName()
                        if let defaultAvatar = UIImage(named: avatarName) {
                            Image(uiImage: defaultAvatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        } else {
                            // 如果都没有，显示默认图标
                            Circle()
                                .fill(Color(hex: "B8B5FF"))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: "B8B5FF").opacity(0.3), lineWidth: 1.5)
                )
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)  // 减少上下padding，让卡片更紧凑
    }
    
    // 底部信息区域（与MultiChatShareCardView保持一致）
    private var footerSection: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            // 品牌标识（移除时间显示）
            HStack(spacing: 0) {
                Text("虫遇APP")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "9A8BB0"))
                
                Text(" - 打破次元壁，与万千角色对话")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 16)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }
    
    // 格式化消息内容
    private func formatMessageContent(_ content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 大幅放宽单条消息的长度限制
        if trimmedContent.count > 500 {
            let truncated = String(trimmedContent.prefix(480))
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

// SwiftUI View 转 UIImage 扩展（支持动态尺寸）
extension View {
    func asUIImage(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // 使用传入的动态尺寸
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = UIColor.clear
        
        // 强制布局
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        // 使用高质量渲染
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// 添加String扩展来估算文本高度
extension String {
    func estimatedTextHeight(width: CGFloat, font: UIFont, lineSpacing: CGFloat) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: self, attributes: attributes)
        let boundingRect = attributedString.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return ceil(boundingRect.height)
    }
}

/**
 * 单人聊天合并卡片视图（显示多条消息的对话）
 */
struct ChatMergedCardView: View {
    let messages: [Message]
    let character: CYChatCharacter
    let characterThemeColor: Color
    
    // 计算最佳高度
    func calculateOptimalHeight() -> CGFloat {
        let headerHeight: CGFloat = 32
        let footerHeight: CGFloat = 60
        let contentVerticalPadding: CGFloat = 24
        
        var totalMessageHeight: CGFloat = 0
        
        for message in messages {
            let avatarHeight: CGFloat = 35
            let nameHeight: CGFloat = 16
            
            let textLength = message.content.count
            let charactersPerLine: CGFloat = 20
            let estimatedLines = max(2, ceil(CGFloat(textLength) / charactersPerLine))
            let textHeight = estimatedLines * 17 + 12
            
            let vStackSpacing: CGFloat = 4
            let contentHeight = nameHeight + vStackSpacing + textHeight
            let messageHeight = max(avatarHeight, contentHeight) + 8
            
            totalMessageHeight += messageHeight
        }
        
        let messageSpacing: CGFloat = 8
        let spacingHeight = CGFloat(max(0, messages.count - 1)) * messageSpacing
        
        let totalHeight = headerHeight + footerHeight + contentVerticalPadding + totalMessageHeight + spacingHeight
        
        let minHeight: CGFloat = 180
        let maxHeight: CGFloat = 3000
        
        return max(minHeight, min(maxHeight, totalHeight))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            simplifiedHeaderSection
                .frame(height: 32)
            
            contentSection
            
            footerSection
                .frame(height: 60)
        }
        .frame(width: 350, height: calculateOptimalHeight())
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFF0F5"),
                        Color(hex: "FFE8F0"),
                        Color(hex: "F0E8FF"),
                        Color(hex: "E8F4FF"),
                        Color(hex: "FFE8D4")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "FFE8F0").opacity(0.4),
                        Color(hex: "FFD4E5").opacity(0.3),
                        Color.clear,
                        Color(hex: "E8F4FF").opacity(0.3),
                        Color(hex: "F0E8FF").opacity(0.4)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color(hex: "FFFEF5").opacity(0.5),
                        Color(hex: "FFF9E6").opacity(0.3),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: 200
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: characterThemeColor.opacity(0.15), radius: 25, x: 0, y: 12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var simplifiedHeaderSection: some View {
        VStack(spacing: 2) {
            // 对话主题 - 显示角色名称
            Text("与\(character.name)的对话")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 20)
                .padding(.top, 6)
            
            Spacer(minLength: 0)
            
            // 简单分割线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 2)
        }
    }
    
    private var contentSection: some View {
        VStack(spacing: 8) {
            ForEach(messages, id: \.id) { message in
                messageRow(message)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func messageRow(_ message: Message) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isFromUser {
                // 角色头像（左侧）- 使用CharacterAvatarService确保头像正确渲染
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    size: 35,
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(characterThemeColor.opacity(0.3), lineWidth: 1.5)
                )
            } else {
                // 用户消息：头像在右侧，先留空
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 5) {
                // 发送者名称
                if !message.isFromUser {
                    Text(character.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(characterThemeColor)
                        .padding(.bottom, 2)
                } else {
                    // 用户消息：显示真实用户名
                    HStack {
                        Spacer()
                        Text(UserProfileManager.shared.getCurrentUsername())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "B8B5FF"))
                            .padding(.bottom, 2)
                    }
                }
                
                // 消息内容（带气泡）
                Text(formatMessageContent(message.content))
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            // 主背景
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "B8B5FF"),
                                            Color(hex: "A8A5FF"),
                                            Color(hex: "9B98FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color(hex: "FAFBFF"),
                                            Color(hex: "F5F7FF")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // 装饰性边框
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    message.isFromUser
                                    ? LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        gradient: Gradient(colors: [
                                            characterThemeColor.opacity(0.2),
                                            characterThemeColor.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: message.isFromUser 
                            ? Color(hex: "B8B5FF").opacity(0.25)
                            : characterThemeColor.opacity(0.15),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
            }
            
            if message.isFromUser {
                // 用户消息：显示真实用户头像（右侧）
                Group {
                    if let userAvatar = UserProfileManager.shared.getCurrentAvatarImage() {
                        Image(uiImage: userAvatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                    } else {
                        // 如果没有自定义头像，尝试加载默认头像
                        let avatarName = UserProfileManager.shared.getCurrentAvatarName()
                        if let defaultAvatar = UIImage(named: avatarName) {
                            Image(uiImage: defaultAvatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                        } else {
                            // 如果都没有，显示默认图标
                            Circle()
                                .fill(Color(hex: "B8B5FF"))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: "B8B5FF").opacity(0.3), lineWidth: 1.5)
                )
            } else {
                Spacer()
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            // 上方较小的spacer，让文字靠上
            Spacer(minLength: 4)
                .frame(maxHeight: 8)
            
            // 品牌标识（移除时间显示）
            HStack(spacing: 0) {
                Text("虫遇APP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "9A8BB0"))
                
                Text(" - 打破次元壁，与万千角色对话")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)
            
            // 下方较大的spacer，让底部空间更大
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 20)
    }
    
    private func formatMessageContent(_ content: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 对于合并卡片，大幅放宽长度限制
        if trimmedContent.count > 300 {
            let truncated = String(trimmedContent.prefix(280))
            return truncated + "..."
        }
        
        return trimmedContent
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
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
}
