import Foundation
import SwiftData

/**
 * 帖子模型类，表示用户分享的与角色的对话内容
 */
@Model
final class Post: Identifiable {
    /// 帖子ID
    var id: String
    /// 帖子内容
    var content: String
    /// 发布时间
    var createdAt: Date
    /// 发布用户
    @Relationship var user: User
    /// 相关角色
    @Relationship var character: Character
    /// 角色回复内容
    var responses: [String]
    /// 点赞数
    var likeCount: Int
    /// 评论数
    var commentCount: Int
    /// 当前用户是否已点赞
    var isLiked: Bool
    /// 更新时间
    var updatedAt: Date
    
    /**
     * 初始化一个帖子实例
     * @param id - 帖子唯一标识
     * @param content - 帖子内容
     * @param createdAt - 创建时间
     * @param user - 发布用户
     * @param character - 相关角色
     * @param responses - 角色回复
     * @param likeCount - 点赞数
     * @param commentCount - 评论数
     * @param isLiked - 是否已点赞
     * @param updatedAt - 更新时间
     */
    init(
        id: String = UUID().uuidString,
        content: String,
        createdAt: Date = Date(),
        user: User,
        character: Character,
        responses: [String] = [],
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.user = user
        self.character = character
        self.responses = responses
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.updatedAt = updatedAt
    }
}