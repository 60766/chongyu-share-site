import SwiftUI

/**
 * 获取角色对应的颜色 - 工具函数
 */
func getCharacterColor(for id: String) -> Color {
    switch id {
    case "einstein": return .blue
    case "shakespeare": return .purple
    case "davinci": return .green
    case "goku", "sunwukong", "naruto": return .orange
    case "holmes": return .indigo
    case "confucius": return .green
    case "libai": return .orange
    case "newton": return .teal
    default: return .teal
    }
}

/**
 * 获取角色类别 - 工具函数
 */
func getCharacterCategory(for id: String) -> String {
    switch id {
    case "einstein": return "科学家"
    case "shakespeare": return "文学家"
    case "davinci": return "艺术家"
    case "confucius": return "哲学家"
    case "libai": return "诗人"
    case "newton": return "科学家"
    case "goku", "sunwukong", "naruto": return "动漫角色"
    case "holmes": return "小说人物"
    default: return "历史人物"
    }
}

/**
 * 根据角色ID获取标签颜色
 */
func getTagColor(for characterID: String?) -> Color {
    guard let id = characterID?.lowercased() else { return .teal }
    
    switch id {
    case "einstein": return .blue
    case "shakespeare": return .purple
    case "davinci": return .green
    case "goku", "sunwukong", "naruto": return .orange
    case "holmes": return .indigo
    case "confucius": return .green
    case "libai": return .orange
    case "newton": return .teal
    default: return .teal
    }
}

/**
 * 获取角色类别标签文本
 */
func getCharacterTag(for characterID: String?) -> String {
    guard let id = characterID?.lowercased() else { return "历史人物" }
    
    switch id {
    case "einstein", "newton": return "科学家"
    case "shakespeare", "libai": return "文学家"
    case "davinci": return "艺术家"
    case "confucius": return "哲学家"
    case "goku", "sunwukong", "naruto": return "动漫角色"
    case "holmes": return "小说人物"
    default: return "历史人物"
    }
}

/**
 * 评论列表视图 - 小红书风格
 * 只有一层嵌套，默认折叠子评论，通过@用户名标记回复关系
 */
struct CommentsListView: View {
    // 评论数据 - 只接收顶级评论
    let comments: [DetailedCommentModel]
    
    // 回调函数
    let onReply: ((DetailedCommentModel) -> Void)?
    let onLike: ((DetailedCommentModel) -> Void)?
    
    // 状态变量
    @State private var likedComments = Set<UUID>()
    @State private var expandedComments = Set<UUID>() // 跟踪已展开的评论
    
    // 添加强制刷新状态
    @State private var refreshTrigger = false
    
    // 添加计数器来追踪刷新次数
    @State private var refreshCounter = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 评论列表
            LazyVStack(alignment: .leading, spacing: 0) {
                if comments.isEmpty {
                    // 无评论时使用统一的EmptyCommentsView组件
                    EmptyCommentsView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20) // 增加垂直间距
                } else {
                    // 显示所有顶级评论
                    ForEach(comments) { comment in
                        CommentThreadView(
                            comment: comment,
                            replyAction: { commentId in
                                // 找到对应的评论并调用回调
                                if let comment = findComment(id: commentId, in: comments) {
                                    onReply?(comment)
                                }
                            }
                        )
                        
                        if comment.id != comments.last?.id {
                            Divider()
                                .padding(.horizontal, 20) // 增加水平间距
                                .padding(.vertical, 4) // 增加分隔线周围的间距
                        }
                    }
                }
            }
            // 使用id强制刷新视图，添加refreshCounter来确保每次都刷新
            .id("comments-list-\(comments.count)-\(refreshTrigger)-\(refreshCounter)")
        }
        .background(Color(.systemBackground).opacity(0.98)) // 添加轻微的背景色
        .onAppear {
            // 添加通知监听
            setupNotifications()
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // 递归查找评论
    private func findComment(id: UUID, in comments: [DetailedCommentModel]) -> DetailedCommentModel? {
        for comment in comments {
            if comment.id == id {
                return comment
            }
            
            if let found = findComment(id: id, in: comment.replies) {
                return found
            }
        }
        return nil
    }
    
    // 设置通知监听
    private func setupNotifications() {
        // 监听评论更新通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PostCommentsUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            print("📢 CommentsListView收到PostCommentsUpdated通知")
            
            // 检查是否有批次ID
            if let userInfo = notification.userInfo,
               let batchId = userInfo["batchId"] as? String {
                
                // 检查是否已经处理过这个批次
                let processedKey = "comments_list_processed_\(batchId)"
                if UserDefaults.standard.bool(forKey: processedKey) {
                    print("⚠️ CommentsListView已处理过批次ID: \(batchId)，跳过重复刷新")
                    return
                }
                
                // 标记此批次已处理
                UserDefaults.standard.set(true, forKey: processedKey)
                print("✅ CommentsListView处理批次ID: \(batchId)")
            }
            
            // 触发视图刷新
            refreshTrigger.toggle()
            refreshCounter += 1
        }
        
        // 监听刷新评论通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshPostComments"),
            object: nil,
            queue: .main
        ) { notification in
            print("📢 CommentsListView收到RefreshPostComments通知")
            
            // 检查是否有批次ID
            if let userInfo = notification.userInfo,
               let batchId = userInfo["batchId"] as? String {
                
                // 检查是否已经处理过这个批次
                let processedKey = "comments_list_refresh_\(batchId)"
                if UserDefaults.standard.bool(forKey: processedKey) {
                    print("⚠️ CommentsListView已处理过刷新批次ID: \(batchId)，跳过重复刷新")
                    return
                }
                
                // 标记此批次已处理
                UserDefaults.standard.set(true, forKey: processedKey)
                print("✅ CommentsListView处理刷新批次ID: \(batchId)")
            }
            
            // 触发视图刷新
            refreshTrigger.toggle()
            refreshCounter += 1
        }
        
        // 监听评论添加通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CommentAdded"),
            object: nil,
            queue: .main
        ) { notification in
            print("📢 CommentsListView收到CommentAdded通知")
            
            // 检查是否有批次ID
            if let userInfo = notification.userInfo,
               let batchId = userInfo["batchId"] as? String {
                
                // 检查是否已经处理过这个批次
                let processedKey = "comments_list_added_\(batchId)"
                if UserDefaults.standard.bool(forKey: processedKey) {
                    print("⚠️ CommentsListView已处理过添加批次ID: \(batchId)，跳过重复刷新")
                    return
                }
                
                // 标记此批次已处理
                UserDefaults.standard.set(true, forKey: processedKey)
                print("✅ CommentsListView处理添加批次ID: \(batchId)")
            }
            
            // 触发视图刷新
            refreshTrigger.toggle()
            refreshCounter += 1
        }
    }
}

/**
 * 评论区头部视图
 */
struct CommentHeaderView: View {
    let commentCount: Int
    
    var body: some View {
        HStack {
            Text("评论")
                .font(.system(size: 16, weight: .medium))
            
            Text("(\(commentCount))")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Menu {
                Button(action: {
                    // 按时间排序
                }) {
                    Label("按时间", systemImage: "clock")
                }
                
                Button(action: {
                    // 按热度排序
                }) {
                    Label("按热度", systemImage: "flame")
                }
            } label: {
                HStack(spacing: 4) {
                    Text("最新")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 20) // 增加水平间距
        .padding(.vertical, 14) // 增加垂直间距
        .background(Color(.systemBackground))
        .overlay(
            Divider()
                .padding(.horizontal, 20), // 增加分隔线水平间距
            alignment: .bottom
        )
    }
}

/**
 * 评论线程视图 - 处理单个评论及其所有回复
 */
struct CommentThreadView: View {
    let comment: DetailedCommentModel
    let replyAction: (UUID) -> Void
    
    // 状态变量
    @State private var refreshTrigger: Bool = false
    @State private var refreshCounter: Int = 0
    @State private var likedComments = Set<UUID>()
    @State private var expandedComments = Set<UUID>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // 增加垂直间距
            // 主评论
            CommentItemView(
                comment: comment,
                replyAction: replyAction,
                isLiked: likedComments.contains(comment.id),
                showExpandButton: !comment.replies.isEmpty,
                replyCount: comment.replies.count,
                isExpanded: expandedComments.contains(comment.id),
                onToggleExpand: {
                    toggleExpand(for: comment.id)
                },
                onLike: {
                    toggleLike(for: comment.id)
                }
            )
            
            // 显示回复
            if expandedComments.contains(comment.id) && !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(comment.replies) { reply in
                        if reply.id != comment.replies.first?.id {
                            Divider()
                                .padding(.leading, 48) // 增加左侧间距
                                .padding(.trailing, 16)
                                .padding(.vertical, 2) // 添加垂直间距
                        }
                        
                        // 回复内容
                        CommentItemView(
                            comment: reply,
                            replyAction: replyAction,
                            isLiked: likedComments.contains(reply.id),
                            showExpandButton: !reply.replies.isEmpty,
                            replyCount: reply.replies.count,
                            isExpanded: expandedComments.contains(reply.id),
                            onToggleExpand: {
                                toggleExpand(for: reply.id)
                            },
                            onLike: {
                                toggleLike(for: reply.id)
                            }
                        )
                        
                        // 嵌套回复
                        if expandedComments.contains(reply.id) && !reply.replies.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(reply.replies) { nestedReply in
                                    if nestedReply.id != reply.replies.first?.id {
                                        Divider()
                                            .padding(.leading, 48) // 增加左侧间距
                                            .padding(.trailing, 16)
                                            .padding(.vertical, 2) // 添加垂直间距
                                    }
                                    
                                    CommentItemView(
                                        comment: nestedReply,
                                        replyAction: replyAction,
                                        isLiked: likedComments.contains(nestedReply.id),
                                        showExpandButton: !nestedReply.replies.isEmpty,
                                        replyCount: nestedReply.replies.count,
                                        isExpanded: expandedComments.contains(nestedReply.id),
                                        onToggleExpand: {
                                            toggleExpand(for: nestedReply.id)
                                        },
                                        onLike: {
                                            toggleLike(for: nestedReply.id)
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 2) // 增加垂直间距
                            .padding(.leading, 20) // 增加左侧间距
                        }
                    }
                }
                .padding(.vertical, 6) // 增加垂直间距
                .padding(.leading, 0)
                .background(
                    RoundedRectangle(cornerRadius: 12) // 增加圆角
                        .fill(Color(.systemGray6).opacity(0.5)) // 轻微调整背景色透明度
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12) // 增加圆角
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1) // 调整边框颜色和宽度
                )
                .padding(.horizontal, 20) // 增加水平间距
                .padding(.bottom, 6) // 增加底部间距
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)).animation(.spring(response: 0.35, dampingFraction: 0.7)),
                    removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)).animation(.easeOut(duration: 0.25))
                ))
                .id("replies-\(comment.id)-\(comment.replies.count)-\(refreshCounter)")
            }
        }
        .padding(.vertical, 4) // 增加垂直间距
        .onAppear {
            // 设置通知监听
            setupNotifications()
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // 切换展开状态
    private func toggleExpand(for commentId: UUID) {
        withAnimation {
            if expandedComments.contains(commentId) {
                expandedComments.remove(commentId)
            } else {
                expandedComments.insert(commentId)
            }
        }
    }
    
    // 切换点赞状态
    private func toggleLike(for commentId: UUID) {
        withAnimation {
            if likedComments.contains(commentId) {
                likedComments.remove(commentId)
            } else {
                likedComments.insert(commentId)
                // 添加触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    // 设置通知监听
    private func setupNotifications() {
        // 监听评论更新通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshComments"),
            object: nil,
            queue: .main
        ) { notification in
            print("收到刷新评论通知")
            
            // 检查是否有批次ID
            if let userInfo = notification.userInfo,
               let batchId = userInfo["batchId"] as? String {
                
                // 检查是否已经处理过这个批次
                let processedKey = "thread_processed_\(batchId)_\(comment.id.uuidString)"
                if UserDefaults.standard.bool(forKey: processedKey) {
                    print("⚠️ CommentThreadView已处理过批次ID: \(batchId)，跳过重复刷新")
                    return
                }
                
                // 标记此批次已处理
                UserDefaults.standard.set(true, forKey: processedKey)
                print("✅ CommentThreadView处理批次ID: \(batchId)")
            }
            
            refreshCounter += 1
        }
        
        // 监听评论添加通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CommentAdded"),
            object: nil,
            queue: .main
        ) { notification in
            print("收到评论添加通知")
            
            // 检查是否有批次ID
            if let userInfo = notification.userInfo,
               let batchId = userInfo["batchId"] as? String {
                
                // 检查是否已经处理过这个批次
                let processedKey = "thread_added_\(batchId)_\(comment.id.uuidString)"
                if UserDefaults.standard.bool(forKey: processedKey) {
                    print("⚠️ CommentThreadView已处理过添加批次ID: \(batchId)，跳过重复刷新")
                    return
                }
                
                // 标记此批次已处理
                UserDefaults.standard.set(true, forKey: processedKey)
                print("✅ CommentThreadView处理添加批次ID: \(batchId)")
            }
            
            refreshCounter += 1
        }
    }
}

/**
 * 单个评论项视图
 */
struct CommentItemView: View {
    let comment: DetailedCommentModel
    let replyAction: (UUID) -> Void
    
    // 添加必要的参数
    var isLiked: Bool = false
    var showExpandButton: Bool = false
    var replyCount: Int = 0
    var isExpanded: Bool = false
    var onToggleExpand: (() -> Void)? = nil
    var onLike: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) { // 增加水平间距
                // 用户头像
                if comment.userAvatar.contains("person") {
                    // 系统图标
                    Image(systemName: comment.userAvatar)
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .frame(width: 38, height: 38) // 增加头像尺寸
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                } else {
                    // 自定义图片
                    Image(comment.userAvatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38) // 增加头像尺寸
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) { // 增加垂直间距
                    // 用户信息行
                    HStack(alignment: .center, spacing: 8) { // 增加水平间距
                        // 用户名
                        Text(comment.username)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(comment.isVirtualCharacter ? getCharacterColor(for: comment.characterID ?? "") : .primary)
                        
                        // 角色标签
                        if comment.isVirtualCharacter, let characterID = comment.characterID {
                            CategoryBadge(characterID: characterID)
                        }
                        
                        Spacer()
                        
                        // 时间标签
                        Text(comment.getFormattedTimeAgo())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    
                    // 显示回复对象
                    if let replyToUsername = comment.replyToUsername {
                        HStack(spacing: 4) {
                            Text("回复")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            Text(replyToUsername)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 2)
                    }
                    
                    // 评论内容
                    Text(comment.content)
                        .font(.system(size: 15))
                        .foregroundColor(Color.primary.opacity(0.8))
                        .lineSpacing(5)
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 交互按钮
                    HStack(spacing: 24) {
                        // 展开/收起回复按钮
                        if showExpandButton {
                            Button(action: {
                                onToggleExpand?()
                            }) {
                                HStack(spacing: 4) {
                                    Text(isExpanded ? "收起" : "查看\(replyCount)条回复")
                                        .font(.system(size: 13))
                                    
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(isExpanded ? .gray.opacity(0.8) : .blue.opacity(0.9))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 4) // 从6减小到4
                        }
                        
                        Spacer()
                        
                        // 回复按钮
                        Button(action: {
                            replyAction(comment.id)
                            
                            // 发送通知，让CommentInputView获取焦点并弹出键盘
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FocusCommentInput"),
                                object: nil
                            )
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 13))
                                Text("回复")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.gray.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4) // 从6减小到4
                        
                        // 点赞按钮
                        Button(action: {
                            onLike?()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 13))
                                if comment.likes > 0 {
                                    Text("\(comment.likes)")
                                        .font(.system(size: 13))
                                }
                            }
                            .foregroundColor(isLiked ? .red : .gray.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4) // 从6减小到4
                    }
                    .padding(.top, 6) // 从10减小到6
                }
            }
            .padding(.horizontal, 20) // 增加水平间距
            .padding(.vertical, 12) // 增加垂直间距
        }
        .background(Color(.systemBackground).opacity(0.5))
        .contentShape(Rectangle())
    }
}

/**
 * 用户头像视图
 */
struct UserAvatarView: View {
    let avatar: String
    let username: String
    let isVirtualCharacter: Bool
    let characterID: String?
    
    var body: some View {
        if !avatar.isEmpty, let avatarImage = UIImage(named: avatar) {
            Image(uiImage: avatarImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isVirtualCharacter ? 
                                getCharacterColor(for: characterID ?? "").opacity(0.4) : 
                                Color.clear, 
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        } else {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(username.prefix(1).uppercased()))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
    }
}

/**
 * 角色类别标签
 */
struct CategoryBadge: View {
    let characterID: String
    
    var body: some View {
        let category = getCharacterCategory(for: characterID)
        let color = getCharacterColor(for: characterID)
        
        Text(category)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// 预览
struct CommentsListView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一些示例评论和回复以测试显示效果
        let mainComment = DetailedCommentModel(
            username: "爱因斯坦",
            userAvatar: "einstein", 
            content: "想象力比知识更重要。知识是有限的，而想象力概括着世界上的一切。",
            datePosted: Date().addingTimeInterval(-7200),
            isVirtualCharacter: true,
            characterID: "einstein",
            likes: 42
        )
        
        let reply1 = DetailedCommentModel(
            username: "牛顿",
            userAvatar: "newton",
            content: "我完全同意，爱因斯坦。正是想象力使科学不断向前发展。",
            datePosted: Date().addingTimeInterval(-3600),
            isVirtualCharacter: true,
            characterID: "newton",
            parentCommentId: mainComment.id,
            replyToUsername: "爱因斯坦",
            likes: 28
        )
        
        let reply2 = DetailedCommentModel(
            username: "用户123",
            userAvatar: "",
            content: "爱因斯坦先生，能否详细解释一下相对论的基本原理？",
            datePosted: Date().addingTimeInterval(-1800),
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: mainComment.id,
            replyToUsername: "爱因斯坦",
            likes: 15
        )
        
        let reply3 = DetailedCommentModel(
            username: "爱因斯坦",
            userAvatar: "einstein",
            content: "相对论的核心是时空的相对性。你面前的时钟与以接近光速运动的时钟相比会走得更快，这种现象叫做'时间膨胀'。",
            datePosted: Date().addingTimeInterval(-1500),
            isVirtualCharacter: true,
            characterID: "einstein",
            parentCommentId: reply2.id,
            replyToUsername: "用户123",
            likes: 35
        )
        
        var commentWithReplies = mainComment
        commentWithReplies.replies = [reply1, reply2, reply3]
        
        return CommentsListView(
            comments: [commentWithReplies],
            onReply: { _ in },
            onLike: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 