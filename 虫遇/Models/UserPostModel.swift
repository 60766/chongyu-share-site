import Foundation
import SwiftUI

/**
 * 用户评论模型
 * 处理普通用户和历史角色的评论数据
 */
struct UserCommentModel: Identifiable, Codable, Equatable, Hashable {
    /// 评论唯一ID
    var id = UUID()
    /// 评论用户名
    var username: String
    /// 用户头像
    var userAvatar: String
    /// 评论内容
    var content: String
    /// 发布时间
    var datePosted: Date
    /// 点赞数
    var likes: Int = 0
    /// 是否为虚拟角色评论
    var isVirtualCharacter: Bool = false
    /// 虚拟角色ID（如果是虚拟角色）
    var characterID: String? = nil
    /// 父评论ID（如果是回复）
    var parentCommentId: UUID? = nil
    /// 被回复的用户名
    var replyToUsername: String? = nil
    /// 回复列表 - 包含所有对这条评论的直接回复
    var replies: [UserCommentModel] = []
    
    /// 添加回复到当前评论
    mutating func addReply(_ reply: UserCommentModel) {
        replies.append(reply)
        // 按时间倒序排序回复
        replies.sort { $0.datePosted > $1.datePosted }
    }
    
    /// 创建对当前评论的回复
    func createReply(username: String, userAvatar: String, content: String, isVirtualCharacter: Bool = false, characterID: String? = nil) -> UserCommentModel {
        return UserCommentModel(
            username: username,
            userAvatar: userAvatar,
            content: content,
            datePosted: Date(),
            isVirtualCharacter: isVirtualCharacter,
            characterID: characterID,
            parentCommentId: self.id,
            replyToUsername: self.username
        )
    }
    
    // 实现 Equatable 协议的 == 操作符
    static func == (lhs: UserCommentModel, rhs: UserCommentModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.username == rhs.username &&
        lhs.userAvatar == rhs.userAvatar &&
        lhs.content == rhs.content &&
        lhs.datePosted == rhs.datePosted &&
        lhs.likes == rhs.likes &&
        lhs.isVirtualCharacter == rhs.isVirtualCharacter &&
        lhs.characterID == rhs.characterID
    }
    
    // 模拟用户评论数据
    static let sampleComments: [UserCommentModel] = [
        // 普通用户评论
        UserCommentModel(
            username: "思考者",
            userAvatar: "person.circle.fill",
            content: "感谢分享！我想补充一下关于这个话题的另一个观点...",
            datePosted: Date().addingTimeInterval(-24 * 60 * 60),
            likes: 15,
            isVirtualCharacter: false,
            characterID: nil
        ),
        // 莎士比亚评论
        UserCommentModel(
            username: "莎士比亚",
            userAvatar: "shakespeare",
            content: "啊，时间！你是最伟大的魔术师，让一切都在你的魔法中流转。让我们珍惜每一刻，因为生命短暂如梦幻...",
            datePosted: Date().addingTimeInterval(-2 * 60 * 60),
            likes: 95,
            isVirtualCharacter: true,
            characterID: "shakespeare"
        ),
        // 科学爱好者评论
        UserCommentModel(
            username: "科学迷",
            userAvatar: "person.circle.fill",
            content: "这个观点非常有见地，我从来没有想过这个角度！",
            datePosted: Date().addingTimeInterval(-5 * 60 * 60),
            likes: 12,
            isVirtualCharacter: false,
            characterID: nil
        ),
        // 历史爱好者评论
        UserCommentModel(
            username: "历史爱好者",
            userAvatar: "person.circle.fill",
            content: "我认为这种解读有些过度简化了当时的历史背景，不过依然是有启发性的思考。",
            datePosted: Date().addingTimeInterval(-12 * 60 * 60),
            likes: 8,
            isVirtualCharacter: false,
            characterID: nil
        )
    ]
}

/**
 * 用户帖子模型
 * 处理包含评论的完整帖子数据
 */
class UserPostModel: ObservableObject, Identifiable, Codable, Hashable {
    let id: UUID
    let username: String
    let userAvatar: String
    let content: String
    let images: [String]
    let datePosted: Date
    var likes: Int
    @Published var comments: [UserCommentModel] = []
    let isLikedByCurrentUser: Bool
    let isBookmarkedByCurrentUser: Bool
    
    // 用于Codable的编码键
    enum CodingKeys: String, CodingKey {
        case id, username, userAvatar, content, images, datePosted, likes, comments, isLikedByCurrentUser, isBookmarkedByCurrentUser
    }
    
    // 初始化方法
    init(
        id: UUID = UUID(),
        username: String,
        userAvatar: String,
        content: String,
        images: [String],
        datePosted: Date,
        likes: Int,
        comments: [UserCommentModel],
        isLikedByCurrentUser: Bool,
        isBookmarkedByCurrentUser: Bool
    ) {
        self.id = id
        self.username = username
        self.userAvatar = userAvatar
        self.content = content
        self.images = images
        self.datePosted = datePosted
        self.likes = likes
        self.comments = comments
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.isBookmarkedByCurrentUser = isBookmarkedByCurrentUser
    }
    
    // MARK: - Decodable 协议实现
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        userAvatar = try container.decode(String.self, forKey: .userAvatar)
        content = try container.decode(String.self, forKey: .content)
        images = try container.decode([String].self, forKey: .images)
        datePosted = try container.decode(Date.self, forKey: .datePosted)
        likes = try container.decode(Int.self, forKey: .likes)
        
        // 特别处理@Published属性
        let commentsArray = try container.decode([UserCommentModel].self, forKey: .comments)
        _comments = Published(initialValue: commentsArray)
        
        isLikedByCurrentUser = try container.decode(Bool.self, forKey: .isLikedByCurrentUser)
        isBookmarkedByCurrentUser = try container.decode(Bool.self, forKey: .isBookmarkedByCurrentUser)
    }
    
    // MARK: - Encodable 协议实现
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(userAvatar, forKey: .userAvatar)
        try container.encode(content, forKey: .content)
        try container.encode(images, forKey: .images)
        try container.encode(datePosted, forKey: .datePosted)
        try container.encode(likes, forKey: .likes)
        
        // 特别处理@Published属性
        try container.encode(comments, forKey: .comments)
        
        try container.encode(isLikedByCurrentUser, forKey: .isLikedByCurrentUser)
        try container.encode(isBookmarkedByCurrentUser, forKey: .isBookmarkedByCurrentUser)
    }
    
    // MARK: - Hashable 协议实现
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 实现 Equatable 协议的 == 操作符
    static func == (lhs: UserPostModel, rhs: UserPostModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.username == rhs.username &&
        lhs.userAvatar == rhs.userAvatar &&
        lhs.content == rhs.content &&
        lhs.images == rhs.images &&
        lhs.datePosted == rhs.datePosted &&
        lhs.likes == rhs.likes &&
        lhs.comments == rhs.comments &&
        lhs.isLikedByCurrentUser == rhs.isLikedByCurrentUser &&
        lhs.isBookmarkedByCurrentUser == rhs.isBookmarkedByCurrentUser
    }
    
    /// 对评论点赞
    func likeComment(commentId: UUID) {
        // 查找并更新顶级评论
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].likes += 1
            return
        }
        
        // 如果不是顶级评论，则递归查找回复中的评论
        for i in 0..<comments.count {
            if findAndLikeReply(in: &comments[i].replies, commentId: commentId) {
                return
            }
        }
    }
    
    /// 递归查找并点赞回复
    private func findAndLikeReply(in replies: inout [UserCommentModel], commentId: UUID) -> Bool {
        for i in 0..<replies.count {
            if replies[i].id == commentId {
                replies[i].likes += 1
                return true
            }
            
            if findAndLikeReply(in: &replies[i].replies, commentId: commentId) {
                return true
            }
        }
        return false
    }
    
    /// 添加评论或回复
    func addComment(username: String, userAvatar: String, content: String, parentCommentId: UUID? = nil, replyToUsername: String? = nil, isVirtualCharacter: Bool = false, characterID: String? = nil) {
        let newComment = UserCommentModel(
            username: username,
            userAvatar: userAvatar,
            content: content,
            datePosted: Date(),
            isVirtualCharacter: isVirtualCharacter,
            characterID: characterID,
            parentCommentId: parentCommentId,
            replyToUsername: replyToUsername
        )
        
        // 如果是回复，则添加到对应的父评论中
        if let parentId = parentCommentId {
            addReplyToParent(parentId: parentId, reply: newComment)
        } else {
            // 直接添加到顶级评论列表
            comments.append(newComment)
            // 保持顶级评论按时间倒序排序（最新的在前面）
            comments.sort { $0.datePosted > $1.datePosted }
        }
        
        // 保存更新后的数据
        saveData()
    }
    
    /// 添加回复到指定的父评论
    private func addReplyToParent(parentId: UUID, reply: UserCommentModel) {
        // 优先在顶级评论中查找父评论
        if let index = comments.firstIndex(where: { $0.id == parentId }) {
            comments[index].addReply(reply)
            return
        }
        
        // 如果顶级评论中没有找到，则在所有回复中递归查找
        for i in 0..<comments.count {
            if findAndAddReply(to: &comments[i].replies, parentId: parentId, reply: reply) {
                return
            }
        }
    }
    
    /// 递归查找父评论并添加回复
    private func findAndAddReply(to replies: inout [UserCommentModel], parentId: UUID, reply: UserCommentModel) -> Bool {
        for i in 0..<replies.count {
            if replies[i].id == parentId {
                replies[i].addReply(reply)
                return true
            }
            
            if findAndAddReply(to: &replies[i].replies, parentId: parentId, reply: reply) {
                return true
            }
        }
        return false
    }
    
    /// 获取顶级评论（不包含回复）
    func getTopLevelComments() -> [UserCommentModel] {
        return comments
    }
    
    /// 获取评论总数（包括所有评论和回复）
    func getTotalCommentsCount() -> Int {
        var total = comments.count
        
        // 递归计算所有回复
        for comment in comments {
            total += countReplies(in: comment.replies)
        }
        
        return total
    }
    
    /// 递归计算回复数量
    private func countReplies(in replies: [UserCommentModel]) -> Int {
        var count = replies.count
        
        for reply in replies {
            count += countReplies(in: reply.replies)
        }
        
        return count
    }
    
    /**
     * 切换点赞状态
     * 返回更新后的帖子实例，不修改原始实例
     */
    func toggleLike(isLiked: Bool) -> UserPostModel {
        let updatedLikeCount = isLiked ? likes + 1 : max(0, likes - 1)
        
        return UserPostModel(
            id: id,
            username: username,
            userAvatar: userAvatar,
            content: content,
            images: images,
            datePosted: datePosted,
            likes: updatedLikeCount,
            comments: comments,
            isLikedByCurrentUser: isLiked,
            isBookmarkedByCurrentUser: isBookmarkedByCurrentUser
        )
    }
    
    /**
     * 切换收藏状态
     * 返回更新后的帖子实例，不修改原始实例
     */
    func toggleBookmark(isBookmarked: Bool) -> UserPostModel {
        return UserPostModel(
            id: id,
            username: username,
            userAvatar: userAvatar,
            content: content,
            images: images,
            datePosted: datePosted,
            likes: likes,
            comments: comments,
            isLikedByCurrentUser: isLikedByCurrentUser,
            isBookmarkedByCurrentUser: isBookmarked
        )
    }
    
    // 获取格式化的时间文本
    func getFormattedTimeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: datePosted, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)周前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
    
    /// 保存更新后的数据
    func saveData() {
        // 实现保存数据的逻辑
        // 在实际应用中，这里可能会将数据保存到本地存储或发送到服务器
        
        // 例如，可以触发一个通知，表示数据已更新
        NotificationCenter.default.post(name: NSNotification.Name("PostDataUpdated"), object: nil)
        
        // 打印日志
        print("数据已保存：\(self.id)")
    }
}

/**
 * UserCommentModel 扩展 - 额外功能
 */
extension UserCommentModel {
    /**
     * 更新点赞数
     * @return 更新后的评论对象
     */
    func updatedLikes(delta: Int = 1) -> UserCommentModel {
        return UserCommentModel(
            username: self.username,
            userAvatar: self.userAvatar,
            content: self.content,
            datePosted: self.datePosted,
            likes: self.likes + delta,
            isVirtualCharacter: self.isVirtualCharacter,
            characterID: self.characterID
        )
    }
    
    // 获取格式化的时间文本，与UserPostModel保持一致的显示方式
    func getFormattedTimeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: datePosted, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)周前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}

/**
 * UserPostModel 扩展 - 额外功能
 */
extension UserPostModel {
    /**
     * 格式化帖子内容文本
     * 确保内容文本格式正确，移除可能导致排版问题的特殊字符
     * @param content 原始内容文本
     * @return 格式化后的内容文本
     */
    static func formatContent(_ content: String) -> String {
        // 移除或替换可能导致排版问题的特殊字符
        var formattedContent = content
        
        // 替换转义的引号为正常引号
        formattedContent = formattedContent.replacingOccurrences(of: "\\\"", with: "\"")
        
        // 处理中文引号（使用ASCII码表示法）
        formattedContent = formattedContent.replacingOccurrences(of: "\u{201c}", with: "\"") // 左双引号
        formattedContent = formattedContent.replacingOccurrences(of: "\u{201d}", with: "\"") // 右双引号
        
        // 标准化段落处理 - 确保段落之间有一致的分隔
        
        // 1. 先规范化所有换行，将多个连续换行替换为两个换行（标准段落分隔）
        formattedContent = formattedContent.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // 2. 确保引用格式统一
        // 检测"某人说："这种模式并确保其后有换行
        let quotePattern = "([^，。：\"\\.,:;?!\\s]+)(说：|曰：|言：|道：)"
        formattedContent = formattedContent.replacingOccurrences(
            of: quotePattern,
            with: "$1$2\n",
            options: .regularExpression
        )
        
        // 3. 确保冒号后的引用内容另起一行
        formattedContent = formattedContent.replacingOccurrences(
            of: "：([^\n])",
            with: "：\n$1",
            options: .regularExpression
        )
        
        // 4. 长内容分段处理 - 如果内容较长且没有明确段落，尝试在自然段落位置添加分隔
        if !formattedContent.contains("\n\n") && formattedContent.count > 80 {
            // 在句号后添加段落分隔（如果后面跟着空格且不是行尾）
            formattedContent = formattedContent.replacingOccurrences(
                of: "([。！？!?])(\\s)(?!$|\\n)",
                with: "$1\n\n",
                options: .regularExpression
            )
        }
        
        // 5. 确保最终内容格式一致 - 开头和结尾不应有多余空行
        formattedContent = formattedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 返回格式化后的内容
        return formattedContent
    }
    
    /**
     * 更新点赞数
     * @param delta 点赞数变化量
     * @return 更新后的帖子
     */
    func updateLikes(delta: Int) -> UserPostModel {
        return UserPostModel(
            id: id,
            username: username,
            userAvatar: userAvatar,
            content: content,
            images: images,
            datePosted: datePosted,
            likes: likes + delta,
            comments: comments,
            isLikedByCurrentUser: isLikedByCurrentUser,
            isBookmarkedByCurrentUser: isBookmarkedByCurrentUser
        )
    }
} 