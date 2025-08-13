import SwiftUI

/**
 * 通知项组件
 * 用于显示单个通知项，支持评论、点赞、关注、系统通知等类型
 */
struct NotificationItemView: View {
    // 通知模型
    let notification: NotificationModel
    // 动画状态
    @State private var animateContent = false
    @State private var showCharacterDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 添加调试清除按钮
            if notification.username == "测试按钮" {
                Button("🧹 清除所有通知") {
                    NotificationService.shared.clearAllNotifications()
                }
                .foregroundColor(.red)
                .padding()
            }
            
            notificationHeader
            
            // 新增：语境信息（用户触发内容）
            if shouldShowUserContext {
                userContextView
            }
            
            if let content = notification.content {
                notificationContent(content)
            }
            
            if let previewContent = notification.previewContent {
                notificationPreview(previewContent)
            }
            
            // 新增：原帖信息（如果存在且重要性较低）
            if shouldShowOriginalPost {
                originalPostView
            }
        }
        .background(cardBackground)
        .overlay(typeIndicator)
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }
    
    // 分解复杂视图 - 通知头部
    private var notificationHeader: some View {
        HStack(alignment: .top, spacing: 14) {
                NotificationCharacterView(
                    character: notification.character,
                    isOnline: notification.isOnline
                )
                
            VStack(alignment: .leading, spacing: 6) {
                headerTopRow
                headerBottomRow
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
    
    // 头部第一行
    private var headerTopRow: some View {
                    HStack {
                        Text(notification.character.name)
                .font(notification.character.fontStyle.weight(.semibold))
                            .foregroundColor(.primary)
                        
            eraTag
                        
                        Spacer()
                        
                        Text(notification.time)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.75))
        }
                    }
                    
    // 时代标签
    private var eraTag: some View {
        Text(notification.character.era)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(notification.character.category.color.opacity(0.06))
                    .overlay(
                        Capsule()
                            .stroke(notification.character.category.color.opacity(0.15), lineWidth: 0.5)
                    )
            )
            .foregroundColor(notification.character.category.color.opacity(0.8))
    }
    
    // 头部第二行
    private var headerBottomRow: some View {
        HStack(alignment: .center, spacing: 8) {
                        Image(systemName: notification.typeIcon)
                .foregroundColor(notification.typeColor.opacity(0.65))
                .font(.system(size: 13, weight: .medium))
            
            notificationText
            
            Spacer()
            
            if notification.canRespond {
                responseButton
            }
        }
    }
    
    // 通知文本
    private var notificationText: some View {
        Group {
                        switch notification.type {
                        case .comment:
                            Text("\(notification.character.speechStyle)评论了你的动态")
                        case .like:
                            Text("\(notification.character.speechStyle)喜欢了你的作品")
                        case .follow:
                            Text("通过时空虫洞关注了你")
                        case .system:
                            Text("")
                        }
        }
        .font(.system(size: 14, weight: .regular, design: .rounded))
        .foregroundColor(.secondary.opacity(0.8))
    }
    
    // 响应按钮
    private var responseButton: some View {
                            Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
                            }) {
            HStack(spacing: 5) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 11, weight: .semibold))
                                    
                                    Text(notification.responseButtonText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(buttonBackground)
            .foregroundColor(notification.typeColor.opacity(0.8))
                            }
                            .buttonStyle(NotificationScaleButtonStyle())
                        }
    
    // 按钮图标
    private var buttonIcon: String {
        switch notification.type {
        case .comment: return "arrowshape.turn.up.left.fill"
        case .like: return "heart.fill"
        default: return "person.badge.plus"
        }
    }
    
    // 按钮背景
    private var buttonBackground: some View {
        Capsule()
            .fill(notification.typeColor.opacity(0.06))
            .overlay(
                Capsule()
                    .stroke(notification.typeColor.opacity(0.2), lineWidth: 0.5)
            )
    }
    
    // 通知内容
    private func notificationContent(_ content: String) -> some View {
                VStack(alignment: .leading, spacing: 8) {
                    Text(content)
                .font(notification.character.fontStyle.weight(.regular))
                .foregroundColor(.primary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .padding(18)
                .background(contentBackground)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .scaleEffect(animateContent ? 1.0 : 0.96)
        .opacity(animateContent ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
    }
    
    // 内容背景
    private var contentBackground: some View {
                            ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(notification.character.category.color.opacity(0.025))
                                
                                if UIImage(named: notification.character.backgroundPattern) != nil {
                                    Image(notification.character.backgroundPattern)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                    .opacity(0.04)
                                        .blendMode(.overlay)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(contentBorder, lineWidth: 0.5)
                        )
                }
    
    // 内容边框
    private var contentBorder: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                notification.character.category.color.opacity(0.1),
                notification.character.category.color.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
            }
            
    // 通知预览
    private func notificationPreview(_ previewContent: String) -> some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(previewBorder)
                .frame(width: 3, height: 28)
                    
                    Text(previewContent)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .lineSpacing(1)
                        .padding(.vertical, 12)
                    
                    Spacer()
                }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
                .padding(.top, notification.content == nil ? 8 : 0)
            }
    
    // 预览边框
    private var previewBorder: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.4),
                Color.gray.opacity(0.2)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // 卡片背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.regularMaterial)
            .opacity(0.6)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
            )
        .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gray.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.01), radius: 1, x: 0, y: 1)
    }
    
    // 类型指示器
    private var typeIndicator: some View {
            VStack {
            Capsule()
                .fill(typeIndicatorGradient)
                .frame(width: 32, height: 3)
                .padding(.top, 8)
                Spacer()
            }
    }
    
    // 类型指示器渐变
    private var typeIndicatorGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                notification.typeColor.opacity(0.6),
                notification.typeColor.opacity(0.4)
            ]),
            startPoint: .leading,
            endPoint: .trailing
                )
    }
    
    // MARK: - 新增：语境信息相关
    
    // 是否显示用户触发内容
    private var shouldShowUserContext: Bool {
        return notification.userComment != nil || notification.userPost != nil
    }
    
    // 是否显示原帖信息
    private var shouldShowOriginalPost: Bool {
        // 只要有原帖信息就显示，不依赖于是否有用户评论
        return notification.originalPost != nil && notification.originalPostAuthor != nil
    }
    
    // 用户触发内容视图
    private var userContextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let userComment = notification.userComment {
                contextCard(
                    prefix: "你说：",
                    content: userComment,
                    isUserContent: true
                )
            }
            
            if let userPost = notification.userPost {
                contextCard(
                    prefix: "你发布：",
                    content: userPost,
                    isUserContent: true
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }
    
    // 原帖信息视图
    private var originalPostView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let originalPost = notification.originalPost,
               let originalAuthor = notification.originalPostAuthor {
                contextCard(
                    prefix: "原帖（\(originalAuthor)）：",
                    content: originalPost,
                    isUserContent: false
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }
    
    // 语境信息卡片组件
    private func contextCard(prefix: String, content: String, isUserContent: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // 左侧指示线
            Rectangle()
                .fill(isUserContent ? Color.blue.opacity(0.4) : Color.gray.opacity(0.3))
                .frame(width: 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(prefix)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
                
                Text(truncateText(content, maxLength: isUserContent ? 30 : 40))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isUserContent ? Color.blue.opacity(0.04) : Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isUserContent ? Color.blue.opacity(0.1) : Color.gray.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
    
    // 文本截取工具方法
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
    }
}

/**
 * 通知角色头像视图
 * 适配器模式：将NotificationModel.CharacterInfo转换为适合CharacterAvatarView的视图
 */
struct NotificationCharacterView: View {
    var character: NotificationModel.CharacterInfo
    var isOnline: Bool
    
    var body: some View {
        ZStack {
            // 背景圆形 - 更精致的层次
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            character.category.color.opacity(0.08),
                            character.category.color.opacity(0.04)
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(character.category.color.opacity(0.1), lineWidth: 0.5)
                )
            
            // 角色头像图片或占位符
            if UIImage(named: character.image) != nil {
                Image(character.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.gray.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                        )
                    
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(character.category.color.opacity(0.8))
                }
            }
            
            // 类别图标 - 更精致的设计
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            character.category.color.opacity(0.9),
                            character.category.color.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .overlay(
                    Image(systemName: character.category.icon)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: character.category.color.opacity(0.3), radius: 2, x: 0, y: 1)
                .offset(x: 17, y: 17)
            
            // 在线状态指示器 - 更精致的设计
            if isOnline {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.9),
                                Color.green.opacity(0.7)
                            ]),
                            center: .center,
                            startRadius: 1,
                            endRadius: 5
                        )
                    )
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color.green.opacity(0.4), radius: 2, x: 0, y: 1)
                    .offset(x: -17, y: -17)
            }
        }
        .frame(width: 50, height: 50)
    }
}

/**
 * 系统通知视图
 * 专门用于显示系统通知
 */
struct SystemNotificationView: View {
    var notification: NotificationModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                // 系统通知图标 - 更精致的设计
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.06),
                                Color.purple.opacity(0.02)
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.purple.opacity(0.1), lineWidth: 0.5)
                    )
                    .overlay(
                        Image(systemName: "clock.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.purple.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("虫洞通知")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("系统")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.06))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.orange.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                    }
                    
                    Text(notification.time)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.75))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            
            Text("有新的时空旅者加入平台")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.9))
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            
            // 新角色信息
            HStack(spacing: 14) {
                NotificationCharacterView(character: notification.character, isOnline: false)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.character.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.9))
                    
                    HStack(spacing: 8) {
                        Text(notification.character.era)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.75))
                        
                        Text(notification.character.category.displayName)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(notification.character.category.color.opacity(0.06))
                                    .overlay(
                                        Capsule()
                                            .stroke(notification.character.category.color.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                            .foregroundColor(notification.character.category.color.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // 触觉反馈
                    let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                    impactFeedback.impactOccurred()
                    // 查看角色
                }) {
                    Text("探索")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.9),
                                            Color.blue.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(NotificationScaleButtonStyle())
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .opacity(0.6)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 3)
        .shadow(color: Color.black.opacity(0.01), radius: 1, x: 0, y: 1)
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }
}

/**
 * 通知项目的缩放按钮样式 - 优化触感
 */
struct NotificationScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// 预览
#Preview {
    VStack {
        NotificationItemView(
            notification: NotificationModel.sampleNotifications[0]
        )
        
        NotificationItemView(
            notification: NotificationModel.sampleNotifications[1]
        )
        
        NotificationItemView(
            notification: NotificationModel.sampleNotifications[2]
        )
        
        SystemNotificationView(
            notification: NotificationModel.sampleNotifications[3]
        )
    }
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
    .padding(.vertical)
} 