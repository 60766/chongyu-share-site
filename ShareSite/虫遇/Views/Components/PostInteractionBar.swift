import SwiftUI

/**
 * 帖子互动栏组件
 * 用于统一管理帖子的点赞、评论、收藏和分享功能
 */
struct PostInteractionBar: View {
    // 互动数据
    @Binding var isLiked: Bool
    @Binding var likeCount: Int
    var commentCount: Int
    @Binding var isBookmarked: Bool
    
    // 通知相关参数
    var postId: String?
    var authorCharacterId: String?
    
    // 帖子对象（用于发送正确的点赞通知）
    var post: UserPostModel?
    
    // 回调函数
    var onCommentTap: () -> Void
    var onShareTap: () -> Void
    var onInviteTap: (() -> Void)? = nil
    
    // 动画状态
    @State private var likeScale: CGFloat = 1.0
    @State private var bookmarkScale: CGFloat = 1.0
    
    // 触觉反馈生成器
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xl) {
            // 点赞按钮
            Button(action: {
                // 触觉反馈
                feedbackGenerator.impactOccurred()
                
                // 使用全局点赞状态管理器
                guard let post = post else { return }
                let newLikedState = LikeStateManager.shared.toggleLike(post.id.uuidString)
                
                // 视觉反馈 - 轻微缩放动画
                withAnimation(DesignSystem.Animations.quick) {
                    likeScale = 1.2
                    isLiked = newLikedState
                    if newLikedState {
                        likeCount += 1
                    } else {
                        likeCount -= 1
                    }
                        
                    // 发送正确格式的点赞通知给UserLikeService
                    // 创建更新后的帖子对象
                    let updatedPost = post.toggleLike(isLiked: newLikedState)
                    
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PostLiked"),
                        object: nil,
                        userInfo: [
                            "post": updatedPost,
                            "isLiked": newLikedState
                        ]
                    )
                    
                    // 发送虚拟角色点赞通知（如果需要）
                    if newLikedState, let postId = postId, let authorCharacterId = authorCharacterId {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("UserLikedCharacterPost"),
                                object: nil,
                                userInfo: [
                                    "postId": postId,
                                    "authorCharacterId": authorCharacterId
                                ]
                            )
                    }
                }
                
                // 复原缩放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.Animations.quick) {
                        likeScale = 1.0
                    }
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.s) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(isLiked ? DesignSystem.Colors.like : DesignSystem.Colors.secondaryText)
                        .scaleEffect(likeScale)
                    
                    Text("\(likeCount)")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(isLiked ? DesignSystem.Colors.like : DesignSystem.Colors.secondaryText)
                }
                .padding(.vertical, DesignSystem.Spacing.s)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .background(
                    Capsule()
                        .fill(isLiked ? DesignSystem.Colors.like.opacity(0.1) : Color.clear)
                )
                .contentShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
            // 评论按钮
            Button(action: {
                feedbackGenerator.impactOccurred()
                onCommentTap()
            }) {
                HStack(spacing: DesignSystem.Spacing.s) {
                    Image(systemName: "bubble.left")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("\(commentCount)")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.vertical, DesignSystem.Spacing.s)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .background(
                    Capsule()
                        .fill(Color.clear)
                )
                .contentShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 邀请历史人物按钮
            Button(action: {
                feedbackGenerator.impactOccurred()
                onInviteTap?()
            }) {
                Image(systemName: "infinity.circle")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(DesignSystem.Spacing.m)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.08))
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // 收藏按钮
            Button(action: {
                // 触觉反馈
                feedbackGenerator.impactOccurred()
                
                // 视觉反馈 - 轻微缩放动画
                withAnimation(DesignSystem.Animations.quick) {
                    bookmarkScale = 1.2
                    isBookmarked.toggle()
                }
                
                // 复原缩放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.Animations.quick) {
                        bookmarkScale = 1.0
                    }
                }
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(isBookmarked ? DesignSystem.Colors.bookmark : DesignSystem.Colors.secondaryText)
                    .scaleEffect(bookmarkScale)
                    .padding(DesignSystem.Spacing.m)
                    .background(
                        Circle()
                            .fill(isBookmarked ? DesignSystem.Colors.bookmark.opacity(0.1) : Color.clear)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // 分享按钮
            Button(action: {
                feedbackGenerator.impactOccurred()
                onShareTap()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(DesignSystem.Spacing.m)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.08))
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, DesignSystem.Spacing.l)
        .padding(.vertical, DesignSystem.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignSystem.Colors.cardBackground.opacity(0.98))
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        )
        .onAppear {
            // 预先准备触觉反馈，减少延迟
            feedbackGenerator.prepare()
        }
    }
}

/**
 * iOS 17 的预览
 */
@available(iOS 17.0, *)
#Preview("帖子互动栏") {
    VStack {
        PostInteractionBar(
            isLiked: .constant(false),
            likeCount: .constant(42),
            commentCount: 12,
            isBookmarked: .constant(false),
            postId: "sample_post_1",
            authorCharacterId: "einstein",
            onCommentTap: {},
            onShareTap: {}
        )
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        
        PostInteractionBar(
            isLiked: .constant(true),
            likeCount: .constant(43),
            commentCount: 12,
            isBookmarked: .constant(true),
            postId: "sample_post_2",
            authorCharacterId: "shakespeare",
            onCommentTap: {},
            onShareTap: {}
        )
        .padding()
        .background(DesignSystem.Colors.cardBackground)
    }
}

/**
 * 兼容iOS 17以下的预览
 */
struct PostInteractionBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PostInteractionBar(
                isLiked: .constant(false),
                likeCount: .constant(42),
                commentCount: 12,
                isBookmarked: .constant(false),
                postId: "preview_post",
                authorCharacterId: "davinci",
                onCommentTap: {},
                onShareTap: {}
            )
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            
            PostInteractionBar(
                isLiked: .constant(true),
                likeCount: .constant(43),
                commentCount: 12,
                isBookmarked: .constant(true),
                onCommentTap: {},
                onShareTap: {}
            )
            .padding()
            .background(DesignSystem.Colors.cardBackground)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("帖子互动栏")
    }
} 