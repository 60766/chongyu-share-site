import SwiftUI
import Foundation

/**
 * 评论头像测试视图
 * 专门用于测试评论中的头像显示效果
 * 对比PostCardView和CommentsListView中的头像显示
 */
struct CommentAvatarTestView: View {
    private let avatarService = CharacterAvatarService.shared
    
    // 测试角色列表
    private let testCharacters = [
        ("hermione", "赫敏", "fiction"),
        ("macbeth", "麦克白", "literature"),
        ("ayuwang", "阿育王", "historical"),
        ("daenerys", "丹妮莉丝", "fiction"),
        ("kongzi", "孔子", "philosopher")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("评论头像测试")
                    .font(.title)
                    .padding()
                
                Text("对比不同组件中的评论头像显示效果")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                // 显示所有测试角色
                ForEach(testCharacters, id: \.0) { character in
                    commentComparisonSection(
                        id: character.0,
                        name: character.1,
                        category: character.2
                    )
                }
            }
            .padding()
        }
    }
    
    // 单个角色的评论对比部分
    private func commentComparisonSection(id: String, name: String, category: String) -> some View {
        VStack(spacing: 20) {
            Text("\(name) (ID: \(id))")
                .font(.headline)
            
            // 模拟评论数据
            let comment = createTestComment(id: id, name: name)
            
            VStack(spacing: 20) {
                // 测试1: PostCardView中的评论头像
                VStack(alignment: .leading, spacing: 10) {
                    Text("PostCardView中的评论头像")
                        .font(.subheadline)
                    
                    HStack(alignment: .top, spacing: 12) {
                        // PostCardView中使用PostAvatar
                        Avatar(url: comment.characterID != nil ? "HistoricalFigures/\(comment.characterID!)" : comment.userAvatar,
                              name: comment.username,
                              category: category,
                              size: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.7), lineWidth: 1.5)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.username)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(comment.content)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 测试2: CommentsListView中的评论头像
                VStack(alignment: .leading, spacing: 10) {
                    Text("CommentsListView中的评论头像")
                        .font(.subheadline)
                    
                    HStack(alignment: .top, spacing: 12) {
                        // CommentsListView中使用Avatar
                        Avatar(url: comment.isVirtualCharacter ? 
                              (comment.characterID != nil ? "HistoricalFigures/\(comment.characterID!)" : comment.userAvatar) : 
                              comment.userAvatar,
                              name: comment.username,
                              category: category,
                              size: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.username)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(comment.content)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 测试3: 直接对比两种组件
                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Avatar(url: "HistoricalFigures/\(id)", name: name, category: category, size: 60)
                        Text("通用 Avatar")
                            .font(.caption)
                    }
                }
            }
            .padding()
            
            Divider()
                .padding(.vertical)
        }
    }
    
    // Helper method to create test comments
    private func createTestComment(id: String, name: String) -> DetailedCommentModel {
        return DetailedCommentModel(
            id: UUID(),
            username: name,
            userAvatar: id,
            content: "这是一条测试评论，用于测试头像显示效果。",
            isVirtualCharacter: true,
            characterID: id
        )
    }
}

// MARK: - 预览
struct CommentAvatarTestView_Previews: PreviewProvider {
    static var previews: some View {
        CommentAvatarTestView()
    }
} 