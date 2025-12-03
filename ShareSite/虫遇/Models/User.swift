import Foundation
import SwiftData

/**
 * 用户模型类，表示应用的用户信息
 */
@Model
final class User {
    /// 用户ID
    var id: String
    /// 用户昵称
    var nickname: String
    /// 用户头像URL
    var avatarUrl: String
    /// 用户简介
    var intro: String?
    /// 关注数量
    var followingCount: Int
    /// 粉丝数量
    var followerCount: Int
    /// 获赞数量
    var likeCount: Int
    /// 创建时间
    var createdAt: Date
    /// 最后活跃时间
    var lastActive: Date
    
    /**
     * 初始化一个用户实例
     * @param id - 用户唯一标识
     * @param nickname - 用户昵称
     * @param avatarUrl - 头像URL
     * @param intro - 用户简介
     * @param followingCount - 关注数量
     * @param followerCount - 粉丝数量
     * @param likeCount - 获赞数量
     * @param createdAt - 创建时间
     * @param lastActive - 最后活跃时间
     */
    init(
        id: String = UUID().uuidString,
        nickname: String,
        avatarUrl: String = "",
        intro: String? = nil,
        followingCount: Int = 0,
        followerCount: Int = 0,
        likeCount: Int = 0,
        createdAt: Date = Date(),
        lastActive: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.avatarUrl = avatarUrl
        self.intro = intro
        self.followingCount = followingCount
        self.followerCount = followerCount
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.lastActive = lastActive
    }
}

/**
 * UI用户模型结构体
 * 用于视图层显示用户信息，避免直接在视图中使用SwiftData模型
 */
struct UIUser: Identifiable {
    /// 用户ID
    var id: String
    /// 用户昵称
    var nickname: String
    /// 用户头像URL
    var avatarUrl: String
    /// 用户简介
    var intro: String?
    /// 关注数量
    var followingCount: Int
    /// 粉丝数量
    var followerCount: Int
    /// 获赞数量
    var likeCount: Int
    /// 最后活跃时间
    var lastActive: Date
    
    /**
     * 初始化一个UI用户实例
     * @param id - 用户唯一标识
     * @param nickname - 用户昵称
     * @param avatarUrl - 头像URL
     * @param intro - 用户简介
     * @param followingCount - 关注数量
     * @param followerCount - 粉丝数量
     * @param likeCount - 获赞数量
     * @param lastActive - 最后活跃时间
     */
    init(
        id: String = UUID().uuidString,
        nickname: String,
        avatarUrl: String = "",
        intro: String? = nil,
        followingCount: Int = 0,
        followerCount: Int = 0,
        likeCount: Int = 0,
        lastActive: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.avatarUrl = avatarUrl
        self.intro = intro
        self.followingCount = followingCount
        self.followerCount = followerCount
        self.likeCount = likeCount
        self.lastActive = lastActive
    }
    
    /**
     * 从SwiftData模型转换为UI模型
     * @param user - SwiftData用户模型
     */
    init(from user: User) {
        self.id = user.id
        self.nickname = user.nickname
        self.avatarUrl = user.avatarUrl
        self.intro = user.intro
        self.followingCount = user.followingCount
        self.followerCount = user.followerCount
        self.likeCount = user.likeCount
        self.lastActive = user.lastActive
    }
} 