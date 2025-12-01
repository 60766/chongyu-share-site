import SwiftUI

/// 聊天消息气泡组件
struct ChatBubble: View {
    let message: ChatMessage
    let character: CharacterModel
    let colorIndex: Int // 新增：由外部指定颜色索引，确保每个角色使用不同颜色
    

    
    // 为不同虚拟角色设置不同的彩色背景，便于区分
    private var bubbleColor: Color {
        // 使用传入的颜色索引，确保每个角色使用不同颜色
        let colors = [
            Color(hex: "E3D5FF"), // 明显紫色
            Color(hex: "D5E8FF"), // 明显蓝色
            Color(hex: "FFE8C5"), // 明显橙黄色
            Color(hex: "FFD5E8")  // 明显粉色
        ]
        return colors[colorIndex % colors.count]
    }

    // 作为描边的强调色，增强视觉区分
    private var accentStrokeColor: Color {
        let accents = [
            Color(hex: "B8A3E8"), // 紫色描边
            Color(hex: "A3C8E8"), // 蓝色描边
            Color(hex: "E8C89A"), // 橙黄描边
            Color(hex: "E8A3C8")  // 粉色描边
        ]
        return accents[colorIndex % accents.count].opacity(0.7)
    }
    
    // 优雅的名称颜色 - 使用统一的深色调确保可读性
    private var nameColor: Color {
        Color(hex: "6B7280") // 现代灰色，优雅且易读
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) { // 恢复适当的头像和消息间距
            // 头像 - 使用CharacterAvatarService支持首字母显示
            CharacterAvatarService.shared.getAvatarView(
                for: character.id,
                name: character.name,
                category: character.category.rawValue,
                size: 36,
                useCaching: true
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 3) {
                // 角色名称
                Text(character.name)
                    .font(.system(size: 14, weight: .semibold)) // 增加字重和大小
                    .foregroundColor(nameColor)
                
                // 消息内容或思考状态
                if message.isThinking {
                    HStack(spacing: 6) {
                        Text("正在思考")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "9CA3AF")) // 更淡的灰色
                        
                        // 动态省略号
                        ThinkingDots()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            // 近白色基底，融合系统材质，保证质感与层次
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.75))
                                .background(.ultraThinMaterial)
                            // 增强角色色调叠加至 15%，保留色彩倾向
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(bubbleColor.opacity(0.15))
                            // 发丝级描边，用去饱和强调色，提升边界定义
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(accentStrokeColor, lineWidth: 0.5)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 15))
                        .lineSpacing(5) // 增加行间距提升可读性
                        .padding(.horizontal, 14) // 稍微增加水平内边距
                        .padding(.vertical, 10) // 增加垂直内边距
                        .foregroundColor(.primary)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.8))
                                    .background(.thinMaterial)
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(bubbleColor.opacity(0.15))
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(accentStrokeColor, lineWidth: 0.5)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // 参考单人聊天的圆角大小
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1) // 添加微妙阴影
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ShowToast"),
                                    object: nil,
                                    userInfo: ["message": "已复制消息内容"]
                                )
                            } label: {
                                Label("复制消息内容", systemImage: "doc.on.doc")
                            }
                        }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4) // 测试：更明显的紧凑间距，让头像几乎贴边
        .padding(.vertical, 4)
    }
}

/// 思考中的动态省略号
struct ThinkingDots: View {
    @State private var animationStep = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "9CA3AF").opacity(animationStep == index ? 0.8 : 0.3))
                    .frame(width: 5, height: 5) // 稍微增大尺寸
                    .scaleEffect(animationStep == index ? 1.2 : 1.0) // 添加缩放动画
                    .animation(.easeInOut(duration: 0.3), value: animationStep)
            }
        }
        .onAppear {
            // 创建定时器
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    animationStep = (animationStep + 1) % 3
                }
            }
        }
        .onDisappear {
            // 清理定时器
            timer?.invalidate()
            timer = nil
        }
    }
}

struct ChatBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // 普通消息
            ChatBubble(
                message: ChatMessage(
                    characterId: "einstein",
                    content: "这是一条测试消息，用于展示气泡的样式和布局。",
                    timestamp: Date()
                ),
                character: CharacterModel.sampleCharacters[0],
                colorIndex: 0
            )
            
            // 思考中的消息
            ChatBubble(
                message: ChatMessage(
                    characterId: "curie",
                    content: "",
                    timestamp: Date(),
                    isThinking: true
                ),
                character: CharacterModel.sampleCharacters[4],
                colorIndex: 1
            )
        }
        .previewLayout(.sizeThatFits)
    }
} 

// MARK: - 用户消息气泡组件

/// 用户消息气泡（用于显示用户的引导消息或参与消息）
struct UserMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // 消息内容（仅文本区域支持长按复制）
                Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 15))
                    .lineSpacing(5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "B8B5FF"),
                                Color(hex: "C7C4FF")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(hex: "C7C4FF").opacity(0.25), radius: 4, x: 0, y: 2)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowToast"),
                                object: nil,
                                userInfo: ["message": "已复制消息内容"]
                            )
                        } label: {
                            Label("复制消息内容", systemImage: "doc.on.doc")
                        }
                    }
                
                // 时间戳
                Text(formatTime(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            
            // 用户头像 - 使用统一的Avatar组件和UserProfileManager数据
            Avatar(
                url: UserProfileManager.shared.getCurrentAvatarURL(),
                name: UserProfileManager.shared.getCurrentUsername(),
                size: 32
            )
                .padding(.top, 2)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 用户扮演角色消息气泡组件

/// 用户扮演角色时的消息气泡（右侧显示，显示角色头像）
struct UserRolePlayingBubble: View {
    let message: ChatMessage
    let character: CharacterModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // 角色名称 + 扮演标识
                HStack(spacing: 4) {
                    Text("🎭")
                        .font(.system(size: 11))
                    Text(character.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "A78DC7"))
                }
                
                // 消息内容（仅文本区域支持长按复制）
                Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 15))
                    .lineSpacing(5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "8B7BCF"),
                                Color(hex: "A78DC7")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color(hex: "A78DC7").opacity(0.25), radius: 4, x: 0, y: 2)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowToast"),
                                object: nil,
                                userInfo: ["message": "已复制消息内容"]
                            )
                        } label: {
                            Label("复制消息内容", systemImage: "doc.on.doc")
                        }
                    }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            
            // 角色头像 - 使用CharacterAvatarService支持首字母显示
            CharacterAvatarService.shared.getAvatarView(
                for: character.id,
                name: character.name,
                category: character.category.rawValue,
                size: 36,
                useCaching: true
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal, 4) // 测试：更明显的紧凑间距，让头像几乎贴边
        .padding(.vertical, 4)
    }
} 