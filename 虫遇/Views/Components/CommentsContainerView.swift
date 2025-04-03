import SwiftUI

/**
 * 评论容器视图
 * 实现混合式展示策略：
 * 1. 直接展示最精彩的1-2条历史人物评论
 * 2. 折叠显示其余评论
 * 3. 智能排序展示评论
 */
struct CommentsContainerView: View {
    // 评论数据
    let comments: [UserCommentModel]
    
    // 展示控制
    @State private var showAllComments: Bool = false
    @State private var expandedCommentId: String? = nil
    @State private var animateButton: Bool = false
    
    // 事件回调
    let onReply: (UserCommentModel) -> Void
    let onLike: (UserCommentModel) -> Void
    let onViewAllComments: () -> Void
    
    // 默认显示的评论数量
    let defaultCommentsToShow: Int = 2
    
    // 筛选出精彩评论(历史人物且点赞高)
    private var featuredComments: [UserCommentModel] {
        comments
            .filter { $0.isVirtualCharacter && $0.likes > 30 }
            .sorted(by: { $0.likes > $1.likes })
            .prefix(defaultCommentsToShow)
            .map { $0 }
    }
    
    // 是否有更多评论需要展开
    private var hasMoreComments: Bool {
        comments.count > featuredComments.count
    }
    
    // 计算剩余评论数量
    private var remainingCommentsCount: Int {
        comments.count - featuredComments.count
    }
    
    // 计算包含回复的完整评论列表
    private var commentsWithReplies: [UserCommentModel] {
        comments
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 评论统计信息
            HStack {
                Text("评论")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("(\(comments.count))")
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray))
                
                Spacer()
                
                // 虚拟角色参与统计
                let virtualCount = comments.filter { $0.isVirtualCharacter }.count
                if virtualCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("\(virtualCount)位历史人物参与")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if comments.isEmpty {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.bottom, 4)
                    
                    Text("暂无评论")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("快来发表第一条评论吧")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 使用新的评论列表组件
                CommentsListView(
                    comments: commentsWithReplies,
                    onReply: onReply,
                    onLike: onLike
                )
                .padding(.vertical, 8)
                
                // 评论区底部（如有更多评论）
                if hasMoreComments && !showAllComments {
                    // 查看更多评论按钮
                    Button(action: {
                        hapticFeedback(style: .light)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animateButton = true
                            showAllComments = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            animateButton = false
                        }
                    }) {
                        HStack {
                            Text("查看全部\(remainingCommentsCount)条评论")
                                .font(.system(size: 14, weight: .medium))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13))
                                .rotationEffect(showAllComments ? .degrees(180) : .degrees(0))
                                .animation(.spring(), value: showAllComments)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .scaleEffect(animateButton ? 0.98 : 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(Color(.systemGroupedBackground).opacity(0.5))
    }
    
    /**
     * 触感反馈
     */
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

/**
 * 预览
 */
struct CommentsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建测试数据
        let comments = [
            // 虚拟角色评论
            UserCommentModel(
                username: "爱因斯坦",
                userAvatar: "person.circle.fill",
                content: "从相对论的角度来看，时间确实是一个相对的概念。在高速运动的情况下，时间会变慢，这就是著名的钟慢效应。",
                datePosted: Date().addingTimeInterval(-3600),
                likes: 128,
                isVirtualCharacter: true,
                characterID: "einstein"
            ),
            UserCommentModel(
                username: "莎士比亚",
                userAvatar: "person.circle.fill",
                content: "啊，时间！你是最伟大的魔术师，让一切都在你的魔法中流转。让我们珍惜每一刻，因为时间就像沙漏中的沙，一去不复返。",
                datePosted: Date().addingTimeInterval(-7200),
                likes: 95,
                isVirtualCharacter: true,
                characterID: "shakespeare"
            ),
            // 普通用户评论
            UserCommentModel(
                username: "思考者",
                userAvatar: "person.circle.fill",
                content: "感谢分享！我想补充一下关于这个话题的另一个观点...",
                datePosted: Date().addingTimeInterval(-86400),
                likes: 15,
                isVirtualCharacter: false,
                characterID: nil
            ),
            UserCommentModel(
                username: "科学爱好者",
                userAvatar: "person.circle.fill",
                content: "这个解释非常清晰，让我对相对论有了更深的理解！",
                datePosted: Date().addingTimeInterval(-43200),
                likes: 8,
                isVirtualCharacter: false,
                characterID: nil
            ),
            UserCommentModel(
                username: "文学爱好者",
                userAvatar: "person.circle.fill",
                content: "莎士比亚的比喻真是太精彩了，文学就是能用优美的语言表达深刻的道理。",
                datePosted: Date().addingTimeInterval(-21600),
                likes: 12,
                isVirtualCharacter: false,
                characterID: nil
            )
        ]
        
        CommentsContainerView(
            comments: comments,
            onReply: { _ in },
            onLike: { _ in },
            onViewAllComments: {}
        )
        .previewLayout(.sizeThatFits)
        .padding(.vertical)
    }
} 