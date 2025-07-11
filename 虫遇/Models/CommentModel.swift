import Foundation

/**
 * 详细评论模型类
 * 代表用户或虚拟角色发表的评论
 */
struct DetailedCommentModel: Identifiable, Hashable, Codable {
    // 唯一标识符
    var id: UUID
    
    // 基本信息
    var username: String
    var content: String
    var datePosted: Date
    var userAvatar: String
    
    // 虚拟角色相关属性
    var isVirtualCharacter: Bool
    var characterID: String?
    
    // 评论回复相关
    var parentCommentId: UUID? = nil
    var replyToUsername: String? = nil
    var replies: [DetailedCommentModel] = []
    
    // 交互状态
    var likes: Int = 0
    var isLikedByCurrentUser: Bool = false
    
    // MARK: - 初始化方法
    
    init(
        id: UUID = UUID(),
        username: String,
        userAvatar: String,
        content: String,
        datePosted: Date = Date(),
        isVirtualCharacter: Bool = false,
        characterID: String? = nil,
        parentCommentId: UUID? = nil,
        replyToUsername: String? = nil,
        replies: [DetailedCommentModel] = [],
        likes: Int = 0,
        isLikedByCurrentUser: Bool = false
    ) {
        self.id = id
        self.username = username
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.datePosted = datePosted
        self.userAvatar = userAvatar
        self.isVirtualCharacter = isVirtualCharacter
        self.characterID = characterID
        self.parentCommentId = parentCommentId
        self.replyToUsername = replyToUsername
        self.replies = replies
        self.likes = likes
        self.isLikedByCurrentUser = isLikedByCurrentUser
    }
    
    // MARK: - 辅助方法
    
    /// 添加回复到当前评论
    mutating func addReply(_ reply: DetailedCommentModel) {
        replies.append(reply)
        // 按时间倒序排序回复
        replies.sort { $0.datePosted > $1.datePosted }
    }
    
    /// 更新点赞状态
    func toggleLike() -> DetailedCommentModel {
        var newComment = self
        newComment.isLikedByCurrentUser.toggle()
        if newComment.isLikedByCurrentUser {
            newComment.likes += 1
        } else if newComment.likes > 0 {
            newComment.likes -= 1
        }
        return newComment
    }
    
    /// 增加点赞数量
    func updatedLikes() -> DetailedCommentModel {
        var newComment = self
        newComment.likes += 1
        return newComment
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
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: DetailedCommentModel, rhs: DetailedCommentModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Debug Helpers
    
    /// 打印评论及其嵌套结构，帮助调试
    func printStructure(indent: Int = 0) {
        let indentation = String(repeating: "  ", count: indent)
        print("\(indentation)📝 评论ID: \(id.uuidString.prefix(8)), 用户: \(username)")
        
        if let parentCommentId = parentCommentId {
            print("\(indentation)  ↪️ 父评论ID: \(parentCommentId.uuidString.prefix(8))")
        }
        
        if let replyToUsername = replyToUsername {
            print("\(indentation)  ↪️ 回复给: \(replyToUsername)")
        }
        
        if !replies.isEmpty {
            print("\(indentation)  ⤵️ \(replies.count)条回复:")
            replies.forEach { $0.printStructure(indent: indent + 1) }
        }
    }
}

/**
 * 简化版评论模型
 * 用于列表展示和基本评论功能
 */
struct CommentModel: Identifiable, Hashable, Codable {
    var id: String
    var avatarName: String?
    var userName: String
    var content: String
    var likes: Int = 0
    
    // MARK: - 初始化方法
    
    init(
        id: String = UUID().uuidString,
        avatarName: String? = nil,
        userName: String,
        content: String,
        likes: Int = 0
    ) {
        self.id = id
        self.avatarName = avatarName
        self.userName = userName
        self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.likes = likes
    }
} 