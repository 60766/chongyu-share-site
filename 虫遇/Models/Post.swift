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
    var user: User
    /// 相关角色ID - 使用ID替代直接关联
    var characterId: String
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
     * @param characterId - 相关角色ID
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
        characterId: String,
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
        self.characterId = characterId
        self.responses = responses
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.updatedAt = updatedAt
    }
}

/**
 * UI帖子模型结构体
 * 用于视图层显示帖子信息，避免直接在视图中使用SwiftData模型
 */
struct UIPost: Identifiable {
    /// 帖子ID
    var id: String
    /// 帖子内容
    var content: String
    /// 发布时间
    var createdAt: Date
    /// 发布用户
    var user: User
    /// 相关角色ID
    var characterId: String
    /// 角色关联信息（可选，用于显示角色相关信息）
    var character: Character?
    /// 角色回复内容
    var responses: [String]
    /// 点赞数
    var likeCount: Int
    /// 评论数
    var commentCount: Int
    /// 当前用户是否已点赞
    var isLiked: Bool
    
    /**
     * 初始化一个UI帖子实例
     * @param id - 帖子唯一标识
     * @param content - 帖子内容
     * @param createdAt - 创建时间
     * @param user - 发布用户
     * @param characterId - 相关角色ID
     * @param character - 相关角色（可选）
     * @param responses - 角色回复
     * @param likeCount - 点赞数
     * @param commentCount - 评论数
     * @param isLiked - 是否已点赞
     */
    init(
        id: String = UUID().uuidString,
        content: String,
        createdAt: Date = Date(),
        user: User,
        characterId: String,
        character: Character? = nil,
        responses: [String] = [],
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.user = user
        self.characterId = characterId
        self.character = character
        self.responses = responses
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
    }
    
    /**
     * 从SwiftData模型转换为UI模型
     * @param post - SwiftData帖子模型
     * @param character - 关联的角色（可选）
     */
    init(from post: Post, character: Character? = nil) {
        self.id = post.id
        self.content = post.content
        self.createdAt = post.createdAt
        self.user = post.user
        self.characterId = post.characterId
        self.character = character
        self.responses = post.responses
        self.likeCount = post.likeCount
        self.commentCount = post.commentCount
        self.isLiked = post.isLiked
    }
}