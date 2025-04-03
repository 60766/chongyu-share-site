import SwiftUI

/**
 * 获取角色对应的颜色 - 工具函数
 */
func getCharacterColor(for id: String) -> Color {
    switch id {
    case "einstein": return .blue
    case "shakespeare": return .purple
    case "davinci": return .green
    case "goku", "naruto": return .orange
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
    case "goku", "naruto": return "动漫角色"
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
    let comments: [UserCommentModel]
    
    // 回调函数
    let onReply: ((UserCommentModel) -> Void)?
    let onLike: ((UserCommentModel) -> Void)?
    
    // 状态变量
    @State private var likedComments = Set<UUID>()
    @State private var expandedComments = Set<UUID>() // 跟踪已展开的评论
    
    var body: some View {
        VStack(spacing: 0) {
            // 评论列表 - 移除重复的评论区头部
            LazyVStack(alignment: .leading, spacing: 0) {
                if comments.isEmpty {
                    // 无评论时显示提示
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("暂无评论")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("成为第一个评论的人吧")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    // 显示所有顶级评论
                    ForEach(comments) { comment in
                        CommentThreadView(
                            comment: comment,
                            onReply: onReply,
                            onLike: onLike,
                            likedComments: $likedComments,
                            isExpanded: expandedComments.contains(comment.id),
                            onToggleExpand: {
                                withAnimation {
                                    toggleExpand(for: comment.id)
                                }
                            }
                        )
                        
                        if comment.id != comments.last?.id {
                            Divider()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2) // 减小分隔线周围的间距
                        }
                    }
                }
            }
        }
    }
    
    // 切换评论展开状态
    private func toggleExpand(for commentId: UUID) {
        if expandedComments.contains(commentId) {
            expandedComments.remove(commentId)
        } else {
            expandedComments.insert(commentId)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Divider()
                .padding(.horizontal, 16),
            alignment: .bottom
        )
    }
}

/**
 * 评论线程视图 - 处理单个评论及其所有回复
 */
struct CommentThreadView: View {
    let comment: UserCommentModel
    let onReply: ((UserCommentModel) -> Void)?
    let onLike: ((UserCommentModel) -> Void)?
    @Binding var likedComments: Set<UUID>
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主评论 - 只有在有回复的情况下才传递展开按钮参数
            CommentItemView(
                comment: comment,
                onReply: onReply,
                onLike: { commentToLike in
                    toggleLike(for: commentToLike.id)
                    onLike?(commentToLike)
                },
                isLiked: likedComments.contains(comment.id),
                showExpandButton: !comment.replies.isEmpty,
                replyCount: comment.replies.count,
                isExpanded: isExpanded,
                onToggleExpand: onToggleExpand
            )
            
            // 回复列表 - 条件显示
            if isExpanded && !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // 所有回复平铺显示
                    ForEach(comment.replies) { reply in
                        if reply.id != comment.replies.first?.id {
                            Divider()
                                .padding(.leading, 44)
                                .padding(.trailing, 16)
                        }
                        
                        // 回复内容 - 嵌套回复不显示展开按钮
                        CommentItemView(
                            comment: reply,
                            onReply: onReply,
                            onLike: { commentToLike in
                                toggleLike(for: commentToLike.id)
                                onLike?(commentToLike)
                            },
                            isLiked: likedComments.contains(reply.id)
                        )
                        
                        // 处理二级回复(作为@引用方式在回复内容中展示)
                        ForEach(getAllNestedReplies(for: reply)) { nestedReply in
                            if nestedReply.id != getAllNestedReplies(for: reply).first?.id {
                                Divider()
                                    .padding(.leading, 44)
                                    .padding(.trailing, 16)
                            }
                            
                            CommentItemView(
                                comment: nestedReply,
                                onReply: onReply,
                                onLike: { commentToLike in
                                    toggleLike(for: commentToLike.id)
                                    onLike?(commentToLike)
                                },
                                isLiked: likedComments.contains(nestedReply.id)
                            )
                        }
                    }
                }
                .padding(.vertical, 4) // 减小垂直间距
                .padding(.leading, 0) // 移除缩进
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6).opacity(0.4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 4) // 减小底部间距
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)).animation(.spring(response: 0.35, dampingFraction: 0.7)),
                    removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)).animation(.easeOut(duration: 0.25))
                ))
            }
        }
        .padding(.vertical, 2) // 减小整体垂直间距
    }
    
    // 获取所有嵌套回复(二级及以上)
    private func getAllNestedReplies(for reply: UserCommentModel) -> [UserCommentModel] {
        return reply.replies
    }
    
    // 切换评论点赞状态
    private func toggleLike(for commentId: UUID) {
        if likedComments.contains(commentId) {
            likedComments.remove(commentId)
        } else {
            likedComments.insert(commentId)
        }
    }
}

/**
 * 单个评论项视图
 */
struct CommentItemView: View {
    let comment: UserCommentModel
    let onReply: ((UserCommentModel) -> Void)?
    let onLike: ((UserCommentModel) -> Void)?
    let isLiked: Bool
    
    // 新增参数，用于展示展开/收起回复按钮
    var showExpandButton: Bool = false
    var replyCount: Int = 0
    var isExpanded: Bool = false
    var onToggleExpand: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 用户头像
                UserAvatarView(avatar: comment.userAvatar, username: comment.username, isVirtualCharacter: comment.isVirtualCharacter, characterID: comment.characterID)
                    .frame(width: 36, height: 36) // 固定大小
                
                VStack(alignment: .leading, spacing: 4) {
                    // 用户信息行
                    HStack(alignment: .center, spacing: 6) {
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
                        Text(getTimeAgo(from: comment.datePosted))
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
                        .lineSpacing(4)
                        .padding(.top, 6)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 交互按钮
                    HStack(spacing: 20) {
                        // 展开/收起回复按钮 - 现在放到最左边
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
                        }
                        
                        Spacer()
                        
                        // 回复和点赞按钮放到最右边
                        // 回复按钮
                        Button(action: {
                            onReply?(comment)
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
                        
                        // 点赞按钮
                        Button(action: {
                            onLike?(comment)
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
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10) // 减小垂直间距
        }
        .background(Color(.systemBackground).opacity(0.5))
        .contentShape(Rectangle())
    }
    
    // 辅助方法：获取时间描述
    private func getTimeAgo(from date: Date) -> String {
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
                .frame(width: 32, height: 32)
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
                .frame(width: 32, height: 32)
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
        let mainComment = UserCommentModel(
            username: "爱因斯坦",
            userAvatar: "einstein", 
            content: "想象力比知识更重要。知识是有限的，而想象力概括着世界上的一切。",
            datePosted: Date().addingTimeInterval(-7200),
            likes: 42,
            isVirtualCharacter: true,
            characterID: "einstein"
        )
        
        let reply1 = UserCommentModel(
            username: "牛顿",
            userAvatar: "newton",
            content: "我完全同意，爱因斯坦。正是想象力使科学不断向前发展。",
            datePosted: Date().addingTimeInterval(-3600),
            likes: 28,
            isVirtualCharacter: true,
            characterID: "newton",
            parentCommentId: mainComment.id,
            replyToUsername: "爱因斯坦"
        )
        
        let reply2 = UserCommentModel(
            username: "用户123",
            userAvatar: "",
            content: "爱因斯坦先生，能否详细解释一下相对论的基本原理？",
            datePosted: Date().addingTimeInterval(-1800),
            likes: 15,
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: mainComment.id,
            replyToUsername: "爱因斯坦"
        )
        
        let reply3 = UserCommentModel(
            username: "爱因斯坦",
            userAvatar: "einstein",
            content: "相对论的核心是时空的相对性。你面前的时钟与以接近光速运动的时钟相比会走得更快，这种现象叫做'时间膨胀'。",
            datePosted: Date().addingTimeInterval(-1500),
            likes: 35,
            isVirtualCharacter: true,
            characterID: "einstein",
            parentCommentId: reply2.id,
            replyToUsername: "用户123"
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