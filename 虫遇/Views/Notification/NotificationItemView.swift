import SwiftUI

/**
 * 通知项组件
 * 用于显示单个通知项，支持评论、点赞、关注、系统通知等类型
 */
struct NotificationItemView: View {
    // 通知模型
    var notification: NotificationModel
    // 动画状态
    @State private var animateContent = false
    
    // 默认用户角色信息（用于用户自己的评论）
    private var defaultUserCharacter: NotificationModel.CharacterInfo {
        NotificationModel.CharacterInfo(
            name: "当前用户",
            era: "现代",
            category: .historical,
            image: "person.circle.fill"
        )
    }
    
    // 获取有效的角色信息（如果为nil则使用默认用户角色）
    private var effectiveCharacter: NotificationModel.CharacterInfo {
        notification.character ?? defaultUserCharacter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            notificationHeader
            
            // 用户触发内容 - 只有在有真实内容时才显示
            if shouldShowUserContext {
                userContextView
            }
            
            if let content = notification.content {
                notificationContent(content)
            }
            
            if let previewContent = notification.previewContent {
                notificationPreview(previewContent)
            }
            
            // 原帖信息（如果存在且重要性较低）
            if shouldShowOriginalPost {
                originalPostView
            }
        }
        .background(cardBackground)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 0.5)
        .padding(.horizontal, 14)
        .padding(.vertical, notification.type == .like ? 4 : 6) // 增大卡片间距
    }
    
    // 分解复杂视图 - 通知头部
    private var notificationHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            NotificationCharacterView(
                character: effectiveCharacter,
                isOnline: notification.isOnline
            )
            
            VStack(alignment: .leading, spacing: notification.type == .like ? 4 : 2) {
                headerTopRow
                    .padding(.top, notification.type == .like ? -2 : 0) // 点赞通知的角色名字和标签往上移动
                headerBottomRow
            }
            .padding(.top, notification.type == .like ? 6 : 3) // 点赞通知增加顶部内边距
            
            // 点赞按钮单独放置，与头像对齐
            if notification.type == .like && notification.canRespond {
                Spacer()
                VStack {
                    Spacer()
                    responseButton
                        .padding(.top, 4) // 点赞图标往下移动
                    Spacer()
                }
                .frame(height: 50) // 与头像高度一致
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12) // 统一垂直内边距
    }
    
    // 头部第一行
    private var headerTopRow: some View {
                    HStack {
                        Text(effectiveCharacter.name)
                .font(effectiveCharacter.fontStyle(weight: .semibold))
                            .foregroundColor(.primary)
                        
            eraTag
                        
                        Spacer()
                        
                        Text(formatTimeDisplay(notification.time))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.75))
        }
                    }
                    
    // 时代标签
    private var eraTag: some View {
        Text(effectiveCharacter.era)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(effectiveCharacter.category.color.opacity(0.06))
                    .overlay(
                        Capsule()
                            .stroke(effectiveCharacter.category.color.opacity(0.15), lineWidth: 0.5)
                    )
            )
            .foregroundColor(effectiveCharacter.category.color.opacity(0.8))
    }
    
    // 头部第二行
    private var headerBottomRow: some View {
        HStack(alignment: notification.type == .like ? .top : .center, spacing: 8) {
            notificationText
            
            Spacer()
            
            // 非点赞通知才在这里显示响应按钮
            if notification.canRespond && notification.type != .like {
                responseButton
            }
        }
    }
    
    // 通知文本
    private var notificationText: some View {
        Group {
                        switch notification.type {
                        case .comment:
                            Text("\(effectiveCharacter.speechStyle)回复了你")
                        case .like:
                            Text("点赞了你的评论")
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
                if !buttonIcon.isEmpty {
                    Image(systemName: buttonIcon)
                        .font(.system(size: notification.type == .like ? 15 : 11, weight: .semibold))
                }
                                    
                // 点赞类型只显示图标，不显示文字
                if notification.type != .like {
                    Text(notification.responseButtonText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }
            .padding(.horizontal, notification.type == .like ? 13 : 14)
            .padding(.vertical, notification.type == .like ? 13 : 7)
            .background(
                // 点赞按钮使用圆形背景，其他使用胶囊背景
                notification.type == .like ? 
                    AnyView(Circle()
                        .fill(notification.typeColor.opacity(0.06))
                        .overlay(
                            Circle()
                                .stroke(notification.typeColor.opacity(0.2), lineWidth: 0.5)
                        )
                    ) : 
                    AnyView(buttonBackground)
            )
            .foregroundColor(notification.typeColor.opacity(0.8))
        }
        .buttonStyle(NotificationScaleButtonStyle())
    }
    
    // 按钮图标
    private var buttonIcon: String {
        switch notification.type {
        case .comment: return "" // 移除评论的箭头图标
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
                .font(effectiveCharacter.fontStyle)
                .foregroundColor(Color.warmTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading) // 固定背景宽度
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
                .fill(effectiveCharacter.category.color.opacity(0.025))
                                
                                if UIImage(named: effectiveCharacter.backgroundPattern) != nil {
                                    Image(effectiveCharacter.backgroundPattern)
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
                effectiveCharacter.category.color.opacity(0.1),
                effectiveCharacter.category.color.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
            }
            
    // 通知预览
    private func notificationPreview(_ previewContent: String) -> some View {
        // 🔍 调试：检查实际接收到的内容
        let _ = print("🔍 notificationPreview 接收到的内容:")
        let _ = print("🔍   内容长度: \(previewContent.count)")
        let _ = print("🔍   实际内容: '\(previewContent)'")
        
        // 添加省略号提示这不是完整内容
        let displayContent = previewContent + "..."
        
        return HStack(alignment: .top, spacing: 10) {
            Capsule()
                .fill(previewBorder)
                .frame(width: 3, height: 44) // 固定竖条高度为两行文本的高度
                    
            Text(displayContent)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .lineSpacing(2)
                .lineLimit(2) // 限制为两行
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 44, alignment: .top) // 固定文本区域高度
                    
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
    
    // 卡片背景 - 使用和今日互动卡片一样的白色背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gray.opacity(0.06), lineWidth: 0.5)
            )
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
    
    // 是否显示用户触发内容 - 统一逻辑
    private var shouldShowUserContext: Bool {
        let shouldShow = (notification.userComment != nil && !notification.userComment!.isEmpty) || 
                         (notification.originalPost != nil && !notification.originalPost!.isEmpty) // 检查originalPost
        
        print("🔍 NotificationItemView.shouldShowUserContext - 统一逻辑")
        print("🔍   shouldShow结果: \(shouldShow)")
        
        return shouldShow
    }
    
    // 是否显示原帖信息 - 统一逻辑（始终不显示，保持UI一致性）
    private var shouldShowOriginalPost: Bool {
        return false  // 统一不显示原帖信息，保持UI一致性
    }
    
    // 用户触发内容视图 - 强制显示用户评论，增加调试信息
    private var userContextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 调试信息
            let _ = print("🔍 NotificationItemView.userContextView 渲染")
            let _ = print("🔍   notification.userComment: '\(notification.userComment ?? "nil")'")
            let _ = print("🔍   notification.originalPost: '\(notification.originalPost ?? "nil")'")
            let _ = print("🔍   notification.type: \(notification.type)")
            let _ = print("🔍   notification.username: '\(notification.username)'")
            
            // 优先显示用户评论
            if let userComment = notification.userComment, !userComment.isEmpty {
                contextCard(
                    prefix: "",
                    content: userComment,
                    isUserContent: true
                )
            // 如果没有用户评论，但有原帖内容，则显示原帖
            } else if let originalPost = notification.originalPost, !originalPost.isEmpty {
                contextCard(
                    prefix: "",
                    content: originalPost,
                    isUserContent: false // 原帖不是用户内容
                )
            } else {
                // 🔧 修复：不显示预设内容，而是显示明确的状态
                contextCard(
                    prefix: "",
                    content: "你发表了评论",
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
            // 添加调试信息
            let _ = print("🔍 originalPostView 渲染")
            let _ = print("🔍   notification.originalPost存在: \(notification.originalPost != nil)")
            let _ = print("🔍   notification.originalPost内容: '\(notification.originalPost ?? "nil")'")
            let _ = print("🔍   notification.originalPostAuthor: '\(notification.originalPostAuthor ?? "nil")'")
            let _ = print("🔍   notification.userComment存在: \(notification.userComment != nil)")
            let _ = print("🔍   shouldShowOriginalPost: \(shouldShowOriginalPost)")
            
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
            // 左侧指示线 - 点赞通知适度弱化指示线
            Rectangle()
                .fill(isUserContent ? (notification.type == .like ? Color.gray.opacity(0.3) : Color.warmAccentSecondary.opacity(0.4)) : Color.gray.opacity(0.3))
                .frame(width: notification.type == .like ? 2.5 : 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: prefix.isEmpty ? 0 : 4) {
                if !prefix.isEmpty {
                Text(prefix)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
                }
                
                Text(content)
                    .font(.system(
                        size: notification.type == .like ? 13 : 14, 
                        weight: notification.type == .like ? .regular : .regular, 
                        design: .rounded
                    ))
                    // 点赞通知适度弱化文字颜色
                    .foregroundColor(notification.type == .like ? .secondary.opacity(0.7) : .primary.opacity(0.8))
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .lineLimit(notification.type == .like ? 1 : 2) // 点赞通知只显示一行
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, notification.type == .like ? 5 : 8) // 点赞通知减小内边距
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isUserContent ? (notification.type == .like ? Color.gray.opacity(0.04) : Color.warmAccentSecondary.opacity(0.08)) : Color.gray.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isUserContent ? (notification.type == .like ? Color.gray.opacity(0.08) : Color.warmAccentSecondary.opacity(0.15)) : Color.gray.opacity(0.08), lineWidth: 0.5)
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
    
    // 时间显示格式化
    private func formatTimeDisplay(_ timeString: String) -> String {
        // 如果是"0秒后"或类似的即时时间，显示空字符串而不是"刚刚"
        if timeString.contains("0秒") || timeString == "刚刚" {
            return ""
        }
        // 其他情况保持原样
        return timeString
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
            
            // 角色头像图片或占位符
            if UIImage(named: character.image) != nil {
                Image(character.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .onAppear {
                        print("✅ 通知头像加载成功: \(character.image)")
                    }
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
                    
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(character.category.color.opacity(0.8))
                }
                .onAppear {
                    print("❌ 通知头像加载失败: \(character.image)，使用字母头像")
                }
            }
            
            // 类别图标已移除 - 简化头像设计
            
            // 在线状态指示器已移除 - 在通知场景下不太必要
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
    
    // 默认用户角色信息（用于用户自己的评论）
    private var defaultUserCharacter: NotificationModel.CharacterInfo {
        NotificationModel.CharacterInfo(
            name: "当前用户",
            era: "现代",
            category: .historical,
            image: "person.circle.fill"
        )
    }
    
    // 获取有效的角色信息（如果为nil则使用默认用户角色）
    private var effectiveCharacter: NotificationModel.CharacterInfo {
        notification.character ?? defaultUserCharacter
    }
    
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
                NotificationCharacterView(character: effectiveCharacter, isOnline: false)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(effectiveCharacter.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.9))
                    
                    HStack(spacing: 8) {
                        Text(effectiveCharacter.era)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.75))
                        
                        Text(effectiveCharacter.category.displayName)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(effectiveCharacter.category.color.opacity(0.06))
                                    .overlay(
                                        Capsule()
                                            .stroke(effectiveCharacter.category.color.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                            .foregroundColor(effectiveCharacter.category.color.opacity(0.8))
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
                                            Color.warmAccentSecondary.opacity(0.9),
                                            Color.warmAccentSecondary.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.warmAccentSecondary.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(NotificationScaleButtonStyle())
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.warmAccentSecondary.opacity(0.04))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 0.5)
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