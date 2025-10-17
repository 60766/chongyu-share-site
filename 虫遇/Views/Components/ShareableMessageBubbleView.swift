import SwiftUI

/**
 * 支持分享选择的消息气泡视图
 * 在分享模式下显示选择框，支持点击选择
 */
struct ShareableMessageBubbleView: View {
    let message: Message
    let characterThemeColor: Color
    let isShareMode: Bool
    let isSelected: Bool
    let onSelectionToggle: () -> Void
    
    @State private var messageStatus: MessageStatus = .delivered
    @State private var isWaitingForReply: Bool = false
    @State private var animationDots = "..."
    @State private var animationTimer: Timer? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 分享模式下的选择框
            if isShareMode {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? characterThemeColor : .gray.opacity(0.6))
                        .animation(.spring(response: 0.3), value: isSelected)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 原有的消息气泡内容
            messageContent
                .opacity(isShareMode ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isShareMode)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isShareMode {
                onSelectionToggle()
            }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        // 计算气泡状态
        let status = message.isFromUser
            ? messageStatus
            : .read // 角色的消息总是已读
        
        // 检查是否为等待消息
        let isWaitingMessage = !message.isFromUser && message.content == "..."
        
        Group {
            if message.isFromUser {
                // 用户消息：水平布局（消息气泡在左，头像在右）
                HStack(alignment: .top, spacing: 8) {
                    Spacer()
                    
                    // 用户消息气泡
                    Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 15))
                        .lineSpacing(5)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
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
                        .foregroundColor(.white)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            // 用户消息上部高光，增强视觉层次感
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                .blendMode(.overlay)
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color.clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                    
                    // 用户头像 - 使用统一的Avatar组件和UserProfileManager数据
                    Avatar(
                        url: UserProfileManager.shared.getCurrentAvatarURL(),
                        name: UserProfileManager.shared.getCurrentUsername(),
                        size: 32
                    )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                }
                .padding(.top, 4)
            } else {
                // 角色消息：保持原有水平布局
                HStack(alignment: isWaitingMessage ? .center : .top, spacing: 8) {
                    // 角色头像
                    ZStack {
                        // 背景装饰
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignSystem.Colors.background.opacity(0.98),
                                        DesignSystem.Colors.background.opacity(0.90)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                        
                        // 角色头像 - 使用Avatar组件
                        Avatar(url: message.senderId, name: "历史人物", size: 32)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    }
                    .padding(.top, isWaitingMessage ? 0 : 4)
                    
                    // 角色消息气泡
                    VStack(alignment: .leading, spacing: 2) {
                        // 消息内容
                        Group {
                            if isWaitingMessage {
                                // 简化的等待动画
                                HStack(spacing: 5) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(characterThemeColor)
                                            .frame(width: 5, height: 5)
                                            .scaleEffect(getAnimationScale(for: index))
                                            .animation(
                                                Animation.easeInOut(duration: 0.5)
                                                    .repeatForever()
                                                    .delay(0.15 * Double(index)),
                                                value: animationDots
                                            )
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                            } else {
                                Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.system(size: 15))
                                    .lineSpacing(5)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .foregroundColor(.primary)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.backgroundPrimary)
                                .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 0.5)
                        )
                        
                        // 消息状态指示器
                        if message.isFromUser {
                            HStack(spacing: 4) {
                                Spacer()
                                
                                // 时间戳
                                Text(formatTime(message.timestamp))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                // 消息状态图标
                                Image(systemName: getStatusIcon(for: status))
                                    .font(.system(size: 10))
                                    .foregroundColor(getStatusColor(for: status))
                            }
                            .padding(.trailing, 8)
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // 获取动画缩放值
    private func getAnimationScale(for index: Int) -> CGFloat {
        let baseScale: CGFloat = 0.5
        let maxScale: CGFloat = 1.0
        
        // 简化动画逻辑
        return animationDots.count > index ? maxScale : baseScale
    }
    
    // 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // 获取状态图标
    private func getStatusIcon(for status: MessageStatus) -> String {
        switch status {
        case .sending:
            return "clock"
        case .delivered:
            return "checkmark"
        case .read:
            return "checkmark.circle"
        }
    }
    
    // 获取状态颜色
    private func getStatusColor(for status: MessageStatus) -> Color {
        switch status {
        case .sending:
            return .gray
        case .delivered:
            return .blue
        case .read:
            return .green
        }
    }
}

// 消息状态枚举
enum MessageStatus {
    case sending
    case delivered
    case read
}

#Preview {
    let sampleMessage = Message(
        conversationId: "test",
        senderId: "user",
        receiverId: "character",
        content: "这是一条测试消息，用于预览消息气泡的显示效果。",
        isFromUser: true
    )
    
    return VStack(spacing: 20) {
        ShareableMessageBubbleView(
            message: sampleMessage,
            characterThemeColor: .blue,
            isShareMode: false,
            isSelected: false,
            onSelectionToggle: {}
        )
        
        ShareableMessageBubbleView(
            message: sampleMessage,
            characterThemeColor: .blue,
            isShareMode: true,
            isSelected: false,
            onSelectionToggle: {}
        )
        
        ShareableMessageBubbleView(
            message: sampleMessage,
            characterThemeColor: .blue,
            isShareMode: true,
            isSelected: true,
            onSelectionToggle: {}
        )
    }
    .padding()
}
