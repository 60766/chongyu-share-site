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
                            // 根据是否有用户评论内容来判断是对评论还是对帖子的点赞
                            if notification.userComment != nil && !notification.userComment!.isEmpty {
                            Text("点赞了你的评论")
                            } else {
                                Text("点赞了你的动态")
                            }
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
        

        
        return shouldShow
    }
    
    // 是否显示原帖信息 - 统一逻辑（始终不显示，保持UI一致性）
    private var shouldShowOriginalPost: Bool {
        return false  // 统一不显示原帖信息，保持UI一致性
    }
    
    // 用户触发内容视图 - 强制显示用户评论，增加调试信息
    private var userContextView: some View {
        VStack(alignment: .leading, spacing: 8) {

            
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
    var scrollProxy: ScrollViewProxy
    @State private var isExpanded: Bool = false
    @State private var scrollPositionBeforeExpansion: String?
    
    // 根据通知类型获取对应的图标
    private var notificationIcon: String {
        switch notification.username {
        case "功能指南":
            return "sparkles"
        case "版本更新":
            return "arrow.up.circle"
        default:
            return notification.avatar.isEmpty ? "bell" : notification.avatar
        }
    }
    
    // 根据通知类型获取对应的颜色
    private var notificationColor: Color {
        switch notification.username {
        case "功能指南":
            return .blue
        case "版本更新":
            return .green
        default:
            return .purple
        }
    }
    
    // 获取简短摘要（前两行内容）
    private var shortSummary: String {
        let content = notification.content ?? "系统通知"
        let lines = content.components(separatedBy: .newlines)
        if lines.count <= 2 {
            return content
        }
        return lines.prefix(2).joined(separator: "\n")
    }
    
    // 判断内容是否需要折叠（内容行数大于3行或字符数超过150个）
    private var needsCollapse: Bool {
        let content = notification.content ?? "系统通知"
        let lines = content.components(separatedBy: .newlines)
        return lines.count > 3 || content.count > 150
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                // 系统通知图标 - 根据类型显示不同图标和颜色
                Group {
                    if notification.username == "虫遇小助手" {
                        // 虫遇小助手使用真实头像
                        if !notification.avatar.isEmpty && notification.avatar != "bell" {
                            Image(notification.avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .background(
                                    Circle()
                                        .fill(notificationColor.opacity(0.08))
                                )
                        } else {
                            // 备用头像
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                            notificationColor.opacity(0.08),
                                            notificationColor.opacity(0.03)
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                                    Image(systemName: notificationIcon)
                            .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(notificationColor.opacity(0.7))
                                )
                        }
                    } else {
                        // 其他系统通知使用原来的系统图标
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                        notificationColor.opacity(0.08),
                                        notificationColor.opacity(0.03)
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                                Image(systemName: notificationIcon)
                            .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(notificationColor.opacity(0.7))
                    )
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.username)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    
                    Text(notification.time)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            
            VStack(alignment: .leading, spacing: 8) {
                // 为功能指南添加荧光笔标记效果
                if notification.username == "功能指南" {
                    HighlightedGuideText(
                        content: needsCollapse && !isExpanded ? shortSummary : (notification.content ?? "系统通知"),
                        isCollapsed: needsCollapse && !isExpanded
                    )
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
                } else {
                    Text(needsCollapse && !isExpanded ? shortSummary : (notification.content ?? "系统通知"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.primary.opacity(0.65))
                        .lineLimit(needsCollapse && !isExpanded ? 3 : nil)
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
            
                // 展开/收起按钮 - 只有需要折叠的内容才显示，放在右边
                if needsCollapse {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            if !isExpanded {
                                // 展开前记录当前滚动位置
                                scrollPositionBeforeExpansion = "\(notification.id)-system"
                            }
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                            
                            // 如果是收起操作，恢复到展开前的位置
                            if !isExpanded, let savedPosition = scrollPositionBeforeExpansion {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scrollProxy.scrollTo(savedPosition, anchor: .top)
                                    }
                                    scrollPositionBeforeExpansion = nil
                                }
                            }
                            
                            // 触觉反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "收起" : "展开详情")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(notificationColor.opacity(0.8))
                        
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(notificationColor.opacity(0.8))
                                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(notificationColor.opacity(0.08))
                                    .overlay(
                                        Capsule()
                                            .stroke(notificationColor.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
                        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                    // 为功能指南添加彩色渐变背景
                    notification.username == "功能指南" ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.08),
                            Color.purple.opacity(0.06),
                            Color.pink.opacity(0.05),
                            Color.orange.opacity(0.04)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) : 
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.warmAccentSecondary.opacity(0.04),
                            Color.warmAccentSecondary.opacity(0.04)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    // 为功能指南添加彩色边框
                    notification.username == "功能指南" ? 
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.15),
                            Color.purple.opacity(0.12),
                            Color.pink.opacity(0.10),
                            Color.orange.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) : 
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.06),
                            Color.gray.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), 
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: notification.username == "功能指南" ? 
                Color.blue.opacity(0.12) : .black.opacity(0.08), 
            radius: 3, x: 0, y: 2
        )
        .shadow(
            color: notification.username == "功能指南" ? 
                Color.purple.opacity(0.08) : .black.opacity(0.04), 
            radius: 1, x: 0, y: 0.5
        )
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
        
        ScrollViewReader { proxy in
        SystemNotificationView(
                notification: NotificationModel.sampleNotifications[3],
                scrollProxy: proxy
        )
        }
    }
    .background(Color(red: 246/255, green: 248/255, blue: 250/255))
    .padding(.vertical)
}

/**
 * 荧光笔标记文本组件
 * 为功能指南添加彩色背景标记效果
 */
struct HighlightedGuideText: View {
    let content: String
    let isCollapsed: Bool
    
    // 定义荧光笔颜色
    private let highlightColors: [String: Color] = [
        "生成帖子": Color(red: 1.0, green: 0.88, blue: 0.4),      // 荧光黄
        "一键生成": Color(red: 0.4, green: 1.0, blue: 0.6),      // 荧光绿
        "发布动态": Color(red: 0.4, green: 0.85, blue: 1.0),     // 荧光蓝
        "互动评论": Color(red: 0.7, green: 0.4, blue: 1.0),      // 荧光紫
        "精彩分享": Color(red: 1.0, green: 0.6, blue: 0.4),      // 荧光橙
        "角色对话": Color(red: 1.0, green: 0.7, blue: 0.8),      // 荧光粉
        "角色调校": Color(red: 0.6, green: 1.0, blue: 0.8),      // 荧光薄荷绿
        "梦幻联动": Color(red: 0.8, green: 0.6, blue: 1.0),      // 荧光淡紫
        "创建角色": Color(red: 1.0, green: 0.8, blue: 0.6),      // 荧光桃色
        "次元回放": Color(red: 0.5, green: 0.9, blue: 1.0),      // 荧光天蓝
        "成就系统": Color(red: 1.0, green: 0.9, blue: 0.5),      // 荧光柠檬黄
        "虫洞币充值": Color(red: 0.9, green: 0.5, blue: 1.0)     // 荧光紫红
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let lines = content.components(separatedBy: .newlines)
            
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    createHighlightedLine(line, lineIndex: index)
                        .padding(.bottom, getLineSpacing(for: line))
                }
            }
        }
    }
    
    @ViewBuilder
    private func createHighlightedLine(_ line: String, lineIndex: Int) -> some View {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // 检查是否包含功能关键词 - 优先匹配更长的关键词
        let highlightedKeyword = highlightColors.keys
            .filter { keyword in trimmedLine.contains(keyword) }
            .sorted { $0.count > $1.count }
            .first
        
        if let keyword = highlightedKeyword,
           let color = highlightColors[keyword] {
            // 创建带荧光笔效果的文本
            HStack(alignment: .top, spacing: 0) {
                Text(createAttributedString(for: trimmedLine, keyword: keyword, color: color))
                    .font(getFontStyle(for: trimmedLine))
                    .lineLimit(isCollapsed ? 3 : nil)
                    .lineSpacing(2)
                Spacer()
            }
        } else {
            // 普通文本 - 根据内容类型调整样式
            HStack(alignment: .top, spacing: 0) {
                Text(trimmedLine)
                    .font(getFontStyle(for: trimmedLine))
                    .foregroundColor(getTextColor(for: trimmedLine))
                    .lineLimit(isCollapsed ? 3 : nil)
                    .lineSpacing(2)
                Spacer()
            }
        }
    }
    
    // 获取动态间距 - 创造呼吸感
    private func getLineSpacing(for line: String) -> CGFloat {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // 标题类型 - 更大间距
        if trimmedLine.contains("欢迎来到虫遇") {
            return 20
        }
        
        // 可选方向 - 下方不要间距
        if trimmedLine.contains("可选方向") {
            return 0
        }
        
        // 大功能分类 - 增加更多间距（所有主要功能都保持一致）
        if trimmedLine.contains("一键生成") || trimmedLine.contains("发布动态") || 
           trimmedLine.contains("互动评论") || trimmedLine.contains("精彩分享") ||
           trimmedLine.contains("角色对话") || trimmedLine.contains("角色调校") ||
           trimmedLine.contains("梦幻联动") || trimmedLine.contains("创建角色") ||
           trimmedLine.contains("次元回放") || trimmedLine.contains("成就系统") ||
           trimmedLine.contains("虫洞币充值") {
            return 20
        }
        
        // 列表项 - 小间距，但最后一个列表项需要更大间距
        if trimmedLine.hasPrefix("•") {
            // 如果是时空记事（一键生成前的最后一个列表项），给更大间距
            if trimmedLine.contains("时空记事") {
                return 20
            }
            return 6
        }
        
        // 普通段落 - 标准间距
        return 8
    }
    
    // 获取字体样式 - 创造层次感
    private func getFontStyle(for line: String) -> Font {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // 主标题
        if trimmedLine.contains("欢迎来到虫遇") {
            return .system(size: 16, weight: .semibold, design: .rounded)
        }
        
        // 副标题
        if trimmedLine.contains("可选方向") {
            return .system(size: 15, weight: .medium, design: .rounded)
        }
        
        // 功能标题
        if trimmedLine.contains("一键生成") || trimmedLine.contains("发布动态") || 
           trimmedLine.contains("互动评论") || trimmedLine.contains("精彩分享") ||
           trimmedLine.contains("角色对话") || trimmedLine.contains("角色调校") ||
           trimmedLine.contains("梦幻联动") || trimmedLine.contains("创建角色") ||
           trimmedLine.contains("次元回放") || trimmedLine.contains("成就系统") ||
           trimmedLine.contains("虫洞币充值") {
            return .system(size: 15, weight: .medium, design: .rounded)
        }
        
        // 列表项
        if trimmedLine.hasPrefix("•") {
            return .system(size: 14, weight: .regular, design: .rounded)
        }
        
        // 普通文本
        return .system(size: 15, weight: .regular, design: .rounded)
    }
    
    // 获取文字颜色 - 增强对比度
    private func getTextColor(for line: String) -> Color {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // 主标题 - 最深色
        if trimmedLine.contains("欢迎来到虫遇") {
            return .primary.opacity(0.9)
        }
        
        // 副标题和功能标题 - 深色
        if trimmedLine.contains("可选方向") || 
           trimmedLine.contains("一键生成") || trimmedLine.contains("发布动态") || 
           trimmedLine.contains("互动评论") || trimmedLine.contains("精彩分享") ||
           trimmedLine.contains("角色对话") || trimmedLine.contains("角色调校") ||
           trimmedLine.contains("梦幻联动") || trimmedLine.contains("创建角色") ||
           trimmedLine.contains("次元回放") || trimmedLine.contains("成就系统") ||
           trimmedLine.contains("虫洞币充值") {
            return .primary.opacity(0.8)
        }
        
        // 列表项 - 中等色
        if trimmedLine.hasPrefix("•") {
            return .primary.opacity(0.7)
        }
        
        // 普通文本 - 标准色
        return .primary.opacity(0.65)
    }
    
    private func createAttributedString(for text: String, keyword: String, color: Color) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // 设置默认样式
        attributedString.foregroundColor = .primary.opacity(0.65)
        
        // 查找并高亮关键词
        if let range = attributedString.range(of: keyword) {
            attributedString[range].backgroundColor = color.opacity(0.3)
            attributedString[range].foregroundColor = .primary.opacity(0.85)
            attributedString[range].font = .system(size: 15, weight: .medium, design: .rounded)
        }
        
        return attributedString
    }
} 