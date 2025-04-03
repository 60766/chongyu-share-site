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
    
    // 回调函数
    var onCommentTap: () -> Void
    var onShareTap: () -> Void
    
    // 动画状态
    @State private var likeScale: CGFloat = 1.0
    @State private var bookmarkScale: CGFloat = 1.0
    
    // 触觉反馈生成器
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.l) {
            // 点赞按钮
            Button(action: {
                // 触觉反馈
                feedbackGenerator.impactOccurred()
                
                // 视觉反馈 - 轻微缩放动画
                withAnimation(DesignSystem.Animations.quick) {
                    likeScale = 1.2
                    isLiked.toggle()
                    if isLiked {
                        likeCount += 1
                    } else {
                        likeCount -= 1
                    }
                }
                
                // 复原缩放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.Animations.quick) {
                        likeScale = 1.0
                    }
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(isLiked ? DesignSystem.Colors.like : DesignSystem.Colors.secondaryText)
                        .scaleEffect(likeScale)
                    
                    Text("\(likeCount)")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(isLiked ? DesignSystem.Colors.like : DesignSystem.Colors.secondaryText)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
                .padding(.horizontal, DesignSystem.Spacing.s)
                .background(
                    Capsule()
                        .fill(isLiked ? DesignSystem.Colors.like.opacity(0.1) : Color.clear)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 评论按钮
            Button(action: {
                feedbackGenerator.impactOccurred()
                onCommentTap()
            }) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "bubble.left")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("\(commentCount)")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
                .padding(.horizontal, DesignSystem.Spacing.s)
                .background(
                    Capsule()
                        .fill(Color.clear)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
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
                    .padding(DesignSystem.Spacing.s)
                    .background(
                        Circle()
                            .fill(isBookmarked ? DesignSystem.Colors.bookmark.opacity(0.1) : Color.clear)
                    )
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
                    .padding(DesignSystem.Spacing.s)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.05))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
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