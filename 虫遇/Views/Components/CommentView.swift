import SwiftUI

/**
 * 评论视图组件
 * 显示单条评论，支持点赞、回复等操作
 * 采用极简设计风格，优化阅读体验
 */
struct CommentView: View {
    // 评论数据
    let comment: DetailedCommentModel
    
    // 所有评论数据，用于查找回复
    var allComments: [DetailedCommentModel]? = nil
    
    // 回调函数
    var onReply: (DetailedCommentModel) -> Void
    var onLike: (DetailedCommentModel) -> Void
    
    // 本地状态
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var showOptions: Bool = false
    @State private var isPressed: Bool = false
    
    // 是否是回复评论
    private var isReply: Bool {
        return comment.parentCommentId != nil
    }
    
    // 查找当前评论的回复
    private var replies: [DetailedCommentModel] {
        guard let allComments = allComments else { return [] }
        return allComments.filter { $0.parentCommentId == comment.id }
    }
    
    // 初始化函数
    init(comment: DetailedCommentModel, allComments: [DetailedCommentModel]? = nil, onReply: @escaping (DetailedCommentModel) -> Void = { _ in }, onLike: @escaping (DetailedCommentModel) -> Void = { _ in }) {
        self.comment = comment
        self.allComments = allComments
        self.onReply = onReply
        self.onLike = onLike
        
        // 初始化本地状态，默认为未点赞
        _isLiked = State(initialValue: false)
        _likeCount = State(initialValue: comment.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 评论内容容器 - 移除多余的阴影和边框，使设计更简洁
            VStack(alignment: .leading, spacing: 8) {
                // 用户信息区
                HStack(alignment: .center, spacing: 10) {
                    // 用户头像
                    if !comment.userAvatar.isEmpty, let avatar = UIImage(named: comment.userAvatar) {
                        Image(uiImage: avatar)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        comment.isVirtualCharacter ? 
                                            Color.orange.opacity(0.3) : 
                                            Color.clear, 
                                        lineWidth: 1.0 // 减少边框宽度
                                    )
                            )
                            .shadow(
                                color: comment.isVirtualCharacter ? 
                                    Color.orange.opacity(0.1) : // 减轻阴影
                                    Color.clear, 
                                radius: 1, // 减少阴影大小
                                x: 0, 
                                y: 0
                            )
                    } else {
                        // 默认头像
                        ZStack {
                            Circle()
                                .fill(comment.isVirtualCharacter ? 
                                      Color.orange.opacity(0.08) : // 极淡的背景
                                      Color.gray.opacity(0.08))
                                .frame(width: 36, height: 36)
                            
                            Text(String(comment.username.prefix(1).uppercased()))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    comment.isVirtualCharacter ? 
                                        .orange.opacity(0.8) : 
                                        Color(.systemGray)
                                )
                        }
                        .shadow(
                            color: comment.isVirtualCharacter ? 
                                Color.orange.opacity(0.1) : // 极淡的阴影
                                Color.clear, 
                            radius: 1, // 极小的阴影半径
                            x: 0, 
                            y: 0
                        )
                    }
                    
                    // 用户信息
                    VStack(alignment: .leading, spacing: 2) {
                        // 用户名和标识
                        HStack(alignment: .center, spacing: 6) {
                            // 用户名
                            Text(comment.username)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(
                                    comment.isVirtualCharacter ? 
                                        .primary : 
                                        Color(.systemGray)
                                )
                            
                            // 历史人物标识 - 精简设计
                            if comment.isVirtualCharacter {
                                HStack(spacing: 2) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 9)) // 更小的图标
                                    
                                    Text("历史人物")
                                        .font(.system(size: 9, weight: .medium)) // 更小的字体
                                }
                                .padding(.horizontal, 4) // 减小内边距
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.08)) // 更淡的背景色
                                )
                                .foregroundColor(.orange.opacity(0.8)) // 稍微柔和的橙色
                            }
                        }
                        
                        // 如果是回复评论，显示回复对象
                        if isReply {
                            if let replyToName = comment.replyToName {
                                Text("回复 @\(replyToName)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue.opacity(0.8))
                            } else if let replyToUsername = comment.replyToUsername {
                                Text("回复 @\(replyToUsername)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                        }
                        
                        // 评论时间
                        Text(timeAgoString(from: comment.datePosted))
                            .font(.system(size: 12))
                            .foregroundColor(Color(.systemGray3))
                    }
                    
                    Spacer()
                    
                    // 更多操作按钮 - 精简样式
                    Button(action: {
                        hapticFeedback(style: .light)
                        showOptions.toggle()
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .medium)) // 稍小的图标
                            .foregroundColor(Color(.systemGray3))
                            .padding(6)
                            .contentShape(Circle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // 评论内容 - 增强排版和阅读体验
                Text(comment.content)
                    .font(.system(size: 15))
                    .foregroundColor(
                        comment.isVirtualCharacter ? 
                            .primary : 
                            Color.primary.opacity(0.9)
                    )
                    .lineSpacing(4) // 优化行间距
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                
                // 底部操作栏 - 极简风格
                HStack(spacing: 20) {
                    // 点赞按钮
                    Button(action: {
                        toggleLike()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 13)) // 更小的图标
                                .foregroundColor(
                                    isLiked ? 
                                        .red.opacity(0.9) : // 柔和的红色
                                        Color(.systemGray3)
                                )
                                .scaleEffect(isLiked ? 1.05 : 1.0) // 减小动画幅度
                            
                            Text("\(likeCount)")
                                .font(.system(size: 13))
                                .foregroundColor(
                                    isLiked ? 
                                        .red.opacity(0.8) : 
                                        Color(.systemGray3)
                                )
                        }
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.97)) // 减小缩放幅度
                    
                    // 回复按钮
                    Button(action: {
                        hapticFeedback(style: .light)
                        onReply(comment)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 13))
                                .foregroundColor(Color(.systemGray3))
                            
                            Text("回复")
                                .font(.system(size: 13))
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.97)) // 减小缩放幅度
                    
                    Spacer()
                    
                    // 精华标识 - 简化设计
                    if comment.likes > 30 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11)) // 更小的图标
                            
                            Text("精华")
                                .font(.system(size: 11)) // 更小的文本
                        }
                        .foregroundColor(Color.orange.opacity(0.8)) // 柔和的橙色
                        .padding(.horizontal, 7) // 减小内边距
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.08)) // 更淡的背景色
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(
                comment.isVirtualCharacter ? 
                    Color.orange.opacity(0.02) : // 极淡的背景色差异
                    Color(.systemBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        comment.isVirtualCharacter ? 
                            Color.orange.opacity(0.08) : // 极淡的边框
                            Color(.systemGray5).opacity(0.6), // 更淡的边框
                        lineWidth: 0.5 // 极细的边框
                    )
            )
            
            // 显示回复评论
            if !isReply && !replies.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(replies, id: \.id) { reply in
                        CommentView(comment: reply, onReply: onReply, onLike: onLike)
                            .padding(.leading, 24) // 缩进回复评论
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            // 点赞选项
            Button(action: {
                toggleLike()
            }) {
                Label(
                    isLiked ? "取消点赞" : "点赞",
                    systemImage: isLiked ? "heart.slash" : "heart"
                )
            }
            
            // 回复选项
            Button(action: {
                onReply(comment)
            }) {
                Label("回复", systemImage: "arrowshape.turn.up.left")
            }
        }
        .actionSheet(isPresented: $showOptions) {
            ActionSheet(
                title: Text("评论操作"),
                message: nil,
                buttons: [
                    .default(Text(isLiked ? "取消点赞" : "点赞")) {
                        toggleLike()
                    },
                    .default(Text("回复")) {
                        onReply(comment)
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
    
    /**
     * 触感反馈
     */
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /**
     * 切换点赞状态
     */
    private func toggleLike() {
        // 触感反馈
        hapticFeedback(style: .light)
        
        // 更新状态 - 使用更快的动画
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            isLiked.toggle()
            likeCount += isLiked ? 1 : -1
        }
        
        // 调用回调
        onLike(comment)
    }
    
    /**
     * 将时间转换为友好的文本格式
     */
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year >= 1 { return "\(year)年前" }
        if let month = components.month, month >= 1 { return "\(month)月前" }
        if let week = components.weekOfYear, week >= 1 { return "\(week)周前" }
        if let day = components.day, day >= 1 { return "\(day)天前" }
        if let hour = components.hour, hour >= 1 { return "\(hour)小时前" }
        if let minute = components.minute, minute >= 1 { return "\(minute)分钟前" }
        return "刚刚"
    }
}

/**
 * 评论列表视图
 */
struct CommentListContainer: View {
    let comments: [DetailedCommentModel]
    let onReply: (DetailedCommentModel) -> Void
    let onLike: (DetailedCommentModel) -> Void
    
    // 触觉反馈
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    // 使用TabBarManager获取底部安全区域高度
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 缓存虚拟角色评论数量避免频繁计算
    private var virtualCommentCount: Int {
        comments.filter { $0.isVirtualCharacter }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 评论标题
            HStack {
                Text("评论")
                    .font(DesignSystem.Typography.title3.weight(.bold))
                
                Text("(\(comments.count))")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                // 虚拟角色评论数量
                if virtualCommentCount > 0 {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "sparkles")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(.orange)
                        
                        Text("\(virtualCommentCount)位历史人物参与")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.s)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(DesignSystem.Radius.m)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.vertical, DesignSystem.Spacing.m)
            
            if comments.isEmpty {
                // 空状态
                VStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                    
                    Text("暂无评论")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("快来发表第一条评论吧")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.top, DesignSystem.Spacing.xs)
                        
                    Button(action: {
                        feedbackGenerator.impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("写评论")
                        }
                        .font(DesignSystem.Typography.subheadline)
                        .padding(.horizontal, DesignSystem.Spacing.l)
                        .padding(.vertical, DesignSystem.Spacing.s)
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.Radius.l)
                    }
                    .padding(.top, DesignSystem.Spacing.m)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
            } else {
                // 评论列表 - 使用LazyVStack优化性能
                LazyVStack(spacing: 0) {
                    // 在每次更新时保持评论ID稳定，避免重新创建视图
                    ForEach(comments) { comment in
                        CommentView(
                            comment: comment,
                            onReply: onReply,
                            onLike: onLike
                        )
                        // 每个评论项后添加分隔线，提高可读性
                        if comment.id != comments.last?.id {
                            Divider()
                                .padding(.horizontal, DesignSystem.Spacing.l)
                        }
                    }
                    
                    // 底部安全区域填充 - 确保所有内容可见
                    Color.clear
                        .frame(height: 60)
                        .id("commentsBottomSpacer")
                }
            }
        }
        .background(DesignSystem.Colors.background)
        .onAppear {
            // 准备触觉反馈
            feedbackGenerator.prepare()
        }
    }
}

/**
 * 预览
 */
struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            // 普通用户评论
            CommentView(
                comment: DetailedCommentModel(
                    username: "用户123",
                    userAvatar: "person.circle.fill",
                    content: "这是一条普通用户评论，评论内容可以很长很长很长很长很长很长很长很长很长很长很长很长很长很长。",
                    datePosted: Date().addingTimeInterval(-3600),
                    isVirtualCharacter: false,
                    characterID: nil,
                    likes: 5
                ),
                onReply: { _ in },
                onLike: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
            
            // 历史人物评论
            CommentView(
                comment: DetailedCommentModel(
                    username: "爱因斯坦",
                    userAvatar: "einstein",
                    content: "这是一条历史人物评论，带有特殊样式。相对论改变了我们对时间和空间的认识。",
                    datePosted: Date().addingTimeInterval(-7200),
                    isVirtualCharacter: true,
                    characterID: "einstein",
                    likes: 120
                ),
                onReply: { _ in },
                onLike: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
        }
    }
} 