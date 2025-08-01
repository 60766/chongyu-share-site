import SwiftUI

/**
 * 头像视图组件
 * 用于显示用户头像，支持图像和占位符
 * 使用统一的Avatar组件
 */
struct AvatarView: View {
    // 评论数据
    let comment: DetailedCommentModel
    // 头像服务
    let avatarService: CharacterAvatarService
    // 头像尺寸
    var size: CGFloat = 40
    
    var body: some View {
        // 使用统一的Avatar组件
        if comment.isVirtualCharacter, let characterID = comment.characterID {
            // 虚拟角色使用角色ID作为头像
            Avatar(
                url: characterID,
                name: comment.username,
                category: avatarService.getCharacterCategoryTag(for: characterID),
                size: size
            )
            .overlay(
                        Circle()
                    .stroke(avatarService.getCharacterTagColor(for: characterID).opacity(0.2), lineWidth: 1)
            )
            .onAppear {
                print("🔍 AvatarView - 显示虚拟角色头像: \(characterID), 用户名: \(comment.username)")
            }
        } else {
            // 普通用户使用userAvatar
            Avatar(
                url: comment.userAvatar,
                name: comment.username,
                size: size
            )
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
            .onAppear {
                print("🔍 AvatarView - 显示普通用户头像: \(comment.userAvatar), 用户名: \(comment.username)")
            }
        }
    }
}

#Preview("头像预览") {
    VStack(spacing: 20) {
        // 普通用户头像
        AvatarView(
            comment: DetailedCommentModel(
                username: "用户123",
                userAvatar: "person.circle.fill",
                content: "这是评论内容",
                datePosted: Date(),
                isVirtualCharacter: false
            ),
            avatarService: CharacterAvatarService.shared
        )
        
        // 历史人物头像
        AvatarView(
            comment: DetailedCommentModel(
                username: "爱因斯坦",
                userAvatar: "einstein",
                content: "这是评论内容",
                datePosted: Date(),
                isVirtualCharacter: true,
                characterID: "einstein"
            ),
            avatarService: CharacterAvatarService.shared
        )
        
        // 没有头像资源的历史人物
        AvatarView(
            comment: DetailedCommentModel(
                username: "阿育王",
                userAvatar: "ayuwang",
                content: "这是评论内容",
                datePosted: Date(),
                isVirtualCharacter: true,
                characterID: "ayuwang"
            ),
            avatarService: CharacterAvatarService.shared
        )
    }
    .padding()
} 