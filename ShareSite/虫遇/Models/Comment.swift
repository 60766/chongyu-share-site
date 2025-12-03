import Foundation
import SwiftData

/**
 * 评论模型类，表示对帖子的评论
 */
@Model
final class Comment: Identifiable {
    /// 评论ID
    var id: String
    /// 帖子ID
    var postId: String
    /// 评论内容
    var content: String
    /// 评论用户（可选，符合CloudKit要求）
    @Relationship var user: User?
    /// 评论时间
    var createdAt: Date
    /// 点赞数
    var likeCount: Int
    /// 是否已点赞
    var isLiked: Bool
    /// 父评论ID（回复时使用）
    var parentId: String?
    
    /**
     * 初始化一个评论实例
     * @param id - 评论唯一标识
     * @param postId - 帖子ID
     * @param content - 评论内容
     * @param user - 评论用户
     * @param createdAt - 创建时间
     * @param likeCount - 点赞数
     * @param isLiked - 是否已点赞
     * @param parentId - 父评论ID
     */
    init(
        id: String = UUID().uuidString,
        postId: String,
        content: String,
        user: User? = nil,
        createdAt: Date = Date(),
        likeCount: Int = 0,
        isLiked: Bool = false,
        parentId: String? = nil
    ) {
        self.id = id
        self.postId = postId
        self.content = content
        self.user = user
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.parentId = parentId
    }
} 