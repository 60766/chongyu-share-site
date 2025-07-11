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
    @Published var comments: [DetailedCommentModel] = []
    let isLikedByCurrentUser: Bool
    let isBookmarkedByCurrentUser: Bool
    var contentType: String?
    var characterID: String?
    // 添加来源属性，用于区分不同来源的帖子（例如：onekey-一键生成，wormhole-虫洞探索）
    var source: String?
    
    // 用于Codable的编码键
    enum CodingKeys: String, CodingKey {
        case id, username, userAvatar, content, images, datePosted, likes, comments, isLikedByCurrentUser, isBookmarkedByCurrentUser, contentType, characterID, source
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
        comments: [DetailedCommentModel],
        isLikedByCurrentUser: Bool,
        isBookmarkedByCurrentUser: Bool,
        contentType: String? = nil,
        characterID: String? = nil,
        source: String? = nil
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
        self.contentType = contentType
        self.characterID = characterID
        self.source = source
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
        let commentsArray = try container.decode([DetailedCommentModel].self, forKey: .comments)
        _comments = Published(initialValue: commentsArray)
        
        isLikedByCurrentUser = try container.decode(Bool.self, forKey: .isLikedByCurrentUser)
        isBookmarkedByCurrentUser = try container.decode(Bool.self, forKey: .isBookmarkedByCurrentUser)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        characterID = try container.decodeIfPresent(String.self, forKey: .characterID)
        source = try container.decodeIfPresent(String.self, forKey: .source)
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
        try container.encodeIfPresent(contentType, forKey: .contentType)
        try container.encodeIfPresent(characterID, forKey: .characterID)
        try container.encodeIfPresent(source, forKey: .source)
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
        lhs.isBookmarkedByCurrentUser == rhs.isBookmarkedByCurrentUser &&
        lhs.contentType == rhs.contentType &&
        lhs.characterID == rhs.characterID &&
        lhs.source == rhs.source
    }
    
    /// 点赞评论
    func likeComment(commentId: UUID) {
        // 优先在顶级评论中查找
        if let index = comments.firstIndex(where: { $0.id == commentId }) {
            comments[index].isLikedByCurrentUser.toggle()
            if comments[index].isLikedByCurrentUser {
                comments[index].likes += 1
            } else {
                comments[index].likes = max(0, comments[index].likes - 1)
            }
            return
        }
        
        // 递归查找回复
        var updatedComments = comments
        if findAndLikeReply(in: &updatedComments, commentId: commentId) {
            comments = updatedComments
        }
    }
    
    /// 递归查找并点赞回复
    private func findAndLikeReply(in replies: inout [DetailedCommentModel], commentId: UUID) -> Bool {
        for i in 0..<replies.count {
            if replies[i].id == commentId {
                replies[i].isLikedByCurrentUser.toggle()
                if replies[i].isLikedByCurrentUser {
                    replies[i].likes += 1
                } else {
                    replies[i].likes = max(0, replies[i].likes - 1)
                }
                return true
            }
            
            if !replies[i].replies.isEmpty {
                var updatedReplies = replies[i].replies
                if findAndLikeReply(in: &updatedReplies, commentId: commentId) {
                    replies[i].replies = updatedReplies
                    return true
                }
            }
        }
        
        return false
    }
    
    /// 添加评论或回复
    func addComment(username: String, userAvatar: String, content: String, parentCommentId: UUID? = nil, replyToUsername: String? = nil, isVirtualCharacter: Bool = false, characterID: String? = nil) {
        // 创建一个新的评论ID或使用提供的ID
        let commentId = UUID()
        
        print("🔵 创建新评论 - ID: \(commentId), 用户: \(username), 是否为回复: \(parentCommentId != nil)")
        
        let newComment = DetailedCommentModel(
            id: commentId,
            username: username,
            userAvatar: userAvatar,
            content: content,
            isVirtualCharacter: isVirtualCharacter,
            characterID: characterID,
            parentCommentId: parentCommentId,
            replyToUsername: replyToUsername
        )
        
        if let parentId = parentCommentId {
            print("🔵 添加为回复 - 父评论ID: \(parentId)")
            addReplyToParent(parentId: parentId, reply: newComment)
        } else {
            print("🔵 添加为顶级评论")
            comments.insert(newComment, at: 0)
            
            // 打印当前评论数量
            print("📊 添加后顶级评论数量: \(comments.count)")
            
            // 发送通知刷新UI - 确保在主线程发送
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                    object: nil,
                    userInfo: ["postID": self.id.uuidString, "commentID": commentId.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostComments"),
                    object: nil,
                    userInfo: ["commentID": commentId.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentAdded"),
                    object: nil,
                    userInfo: ["commentID": commentId.uuidString]
                )
            }
        }
    }
    
    /// 添加回复到指定的父评论
    func addReplyToParent(parentId: UUID, reply: DetailedCommentModel) {
        print("🔍 尝试添加回复到父评论 - 父评论ID: \(parentId), 回复ID: \(reply.id)")
        
        // 优先在顶级评论中查找父评论
        if let index = comments.firstIndex(where: { $0.id == parentId }) {
            print("✅ 在顶级评论中找到父评论 - 索引: \(index), 用户名: \(comments[index].username)")
            
            // 创建评论的可变副本
            var updatedComment = comments[index]
            
            // 添加回复到该评论的replies数组
            updatedComment.replies.insert(reply, at: 0)
            
            // 更新原始数组中的评论
            comments[index] = updatedComment
            
            // 打印回复数量
            print("📊 该父评论现在有 \(comments[index].replies.count) 条回复")
            print("📊 回复内容: \"\(reply.content.prefix(30))...\"")
            
            // 发送通知刷新UI - 确保在主线程发送
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                    object: nil,
                    userInfo: ["postID": self.id.uuidString, "commentID": reply.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostComments"),
                    object: nil,
                    userInfo: ["commentID": reply.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentAdded"),
                    object: nil,
                    userInfo: ["commentID": reply.id.uuidString]
                )
                
                // 延迟再次发送通知，确保UI更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshPostComments"),
                        object: nil,
                        userInfo: ["commentID": reply.id.uuidString]
                    )
                }
            }
            return
        }
        
        // 在嵌套回复中查找父评论
        var found = false
        var updatedComments = comments
        
        for i in 0..<updatedComments.count {
            var updatedReplies = updatedComments[i].replies
            if findAndAddReplyToNestedComment(comments: &updatedReplies, parentId: parentId, reply: reply) {
                print("✅ 在评论 \(updatedComments[i].id) (\(updatedComments[i].username)) 的回复中找到目标评论并添加了回复")
                
                // 更新原始评论的回复数组
                updatedComments[i].replies = updatedReplies
                found = true
                break
            }
        }
        
        if found {
            // 更新评论数组
            comments = updatedComments
            
            // 打印更新后的评论结构
            print("📊 更新后评论结构:")
            for (index, comment) in comments.enumerated() {
                print("📊 顶级评论[\(index)]: ID=\(comment.id), 用户名=\(comment.username), 回复数=\(comment.replies.count)")
                comment.printStructure()
            }
            
            // 发送通知刷新UI - 确保在主线程发送
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                    object: nil,
                    userInfo: ["postID": self.id.uuidString, "commentID": reply.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostComments"),
                    object: nil,
                    userInfo: ["commentID": reply.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentAdded"),
                    object: nil,
                    userInfo: ["commentID": reply.id.uuidString]
                )
                
                // 延迟再次发送通知，确保UI更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshPostComments"),
                        object: nil,
                        userInfo: ["commentID": reply.id.uuidString]
                    )
                }
            }
        } else {
            print("❌ 未找到父评论，将作为顶级评论添加")
            // 如果没有找到父评论，将回复作为顶级评论添加
            var newTopLevelComment = reply
            newTopLevelComment.parentCommentId = nil // 清除父评论ID
            comments.insert(newTopLevelComment, at: 0)
            
            // 发送通知刷新UI - 确保在主线程发送
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                    object: nil,
                    userInfo: ["postID": self.id.uuidString, "commentID": reply.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostComments"),
                    object: nil,
                    userInfo: ["commentID": reply.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentAdded"),
                    object: nil,
                    userInfo: ["commentID": reply.id.uuidString]
                )
                
                // 延迟再次发送通知，确保UI更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshPostComments"),
                        object: nil,
                        userInfo: ["commentID": reply.id.uuidString]
                    )
                }
            }
        }
    }
    
    /**
     * 递归查找嵌套评论并添加回复
     * @param comments 评论数组引用
     * @param parentId 父评论ID
     * @param reply 要添加的回复
     * @return 是否成功添加回复
     */
    private func findAndAddReplyToNestedComment(comments: inout [DetailedCommentModel], parentId: UUID, reply: DetailedCommentModel) -> Bool {
        print("🔍 递归查找父评论ID: \(parentId)，当前层级评论数: \(comments.count)")
        
        for i in 0..<comments.count {
            // 检查当前评论是否是目标父评论
            if comments[i].id == parentId {
                print("✅ 找到目标父评论，ID: \(parentId)，用户名: \(comments[i].username)")
                
                // 创建评论的可变副本
                var updatedComment = comments[i]
                
                // 添加回复到该评论的replies数组
                updatedComment.replies.insert(reply, at: 0)
                
                // 更新原始数组中的评论
                comments[i] = updatedComment
                
                print("✅ 成功添加回复，父评论目前有\(comments[i].replies.count)条回复")
                return true
            }
            
            // 递归检查当前评论的回复
            if !comments[i].replies.isEmpty {
                print("👉 检查评论 \(comments[i].id) (\(comments[i].username)) 的\(comments[i].replies.count)条回复")
                
                var updatedReplies = comments[i].replies
                if findAndAddReplyToNestedComment(comments: &updatedReplies, parentId: parentId, reply: reply) {
                    // 创建评论的可变副本并更新
                    var updatedComment = comments[i]
                    updatedComment.replies = updatedReplies
                    comments[i] = updatedComment
                    
                    print("✅ 在评论 \(comments[i].id) (\(comments[i].username)) 的回复中找到目标评论并添加了回复")
                    
                    // 打印更新后的结构
                    print("📊 更新后的回复结构:")
                    comments[i].printStructure()
                    
                    return true
                }
            }
        }
        
        print("❌ 在当前层级未找到ID为 \(parentId) 的评论")
        return false
    }
    
    /// 获取顶级评论（不包含回复）
    func getTopLevelComments() -> [DetailedCommentModel] {
        return comments
    }
    
    /// 获取评论总数（包括回复）
    func getTotalCommentsCount() -> Int {
        var count = comments.count
        
        for comment in comments {
            count += countReplies(in: comment.replies)
        }
        
        return count
    }
    
    /// 递归计算回复数量
    private func countReplies(in replies: [DetailedCommentModel]) -> Int {
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
            isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
            contentType: contentType,
            characterID: characterID,
            source: source
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
            isBookmarkedByCurrentUser: isBookmarked,
            contentType: contentType,
            characterID: characterID,
            source: source
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
    
    /**
     * 更新评论之间的嵌套关系
     * 确保所有回复评论都正确指向其父评论
     * 特别用于一键生成的帖子，确保评论嵌套关系正确
     */
    func updateCommentRelationships() {
        print("🔄 开始更新评论嵌套关系 - 帖子ID: \(id), 评论数: \(comments.count)")
        
        // 如果评论数量少于2，不需要处理嵌套关系
        if comments.count < 2 {
            print("⏩ 评论数量少于2，跳过处理")
            return
        }
        
        // 创建用户名到评论ID的映射，用于快速查找
        var usernameToCommentMap: [String: UUID] = [:]
        
        // 第一次遍历，建立用户名到评论ID的映射
        for comment in comments {
            usernameToCommentMap[comment.username] = comment.id
        }
        
        // 第二次遍历，处理回复评论的parentCommentId
        var updatedComments = comments
        for i in 0..<updatedComments.count {
            if let replyToUsername = updatedComments[i].replyToUsername {
                // 如果有replyToUsername但没有parentCommentId，尝试设置parentCommentId
                if updatedComments[i].parentCommentId == nil {
                    if let parentId = usernameToCommentMap[replyToUsername] {
                        updatedComments[i].parentCommentId = parentId
                        print("✅ 为评论 \(updatedComments[i].id) 设置父评论ID: \(parentId)")
                    }
                }
            }
        }
        
        // 更新评论数组
        comments = updatedComments
        
        // 更新评论列表结构
        // 获取所有顶级评论（不包含回复）
        var topLevelComments: [DetailedCommentModel] = []
        var replyComments: [DetailedCommentModel] = []
        
        // 将评论分为顶级评论和回复评论
        for comment in comments {
            if comment.parentCommentId == nil {
                var commentCopy = comment
                commentCopy.replies = [] // 清空回复列表，后面重新组织
                topLevelComments.append(commentCopy)
            } else {
                replyComments.append(comment)
            }
        }
        
        // 将所有回复添加到对应的主评论下
        for reply in replyComments {
            if let parentId = reply.parentCommentId {
                // 找到顶级父评论
                if let index = topLevelComments.firstIndex(where: { $0.id == parentId }) {
                    topLevelComments[index].replies.append(reply)
                    print("✅ 将评论 \(reply.id) 添加到父评论 \(parentId) 的回复列表中")
                }
            }
        }
        
        // 排序回复（按时间倒序，最新的在前面）
        for i in 0..<topLevelComments.count {
            topLevelComments[i].replies.sort { $0.datePosted > $1.datePosted }
        }
        
        // 更新评论数组，只保留顶级评论，回复评论只存在于顶级评论的replies属性中
        // 这样可以避免回复评论在UI中重复显示
        comments = topLevelComments
        print("✅ 评论嵌套关系更新完成，更新后顶级评论数: \(comments.count)")
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
            isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
            contentType: contentType,
            characterID: characterID,
            source: source
        )
    }
    
    /**
     * 添加评论对象
     * 直接添加一个DetailedCommentModel对象作为评论
     */
    func addComment(_ comment: DetailedCommentModel) {
        print("🔵 添加评论对象 - ID: \(comment.id), 用户: \(comment.username), 是否为回复: \(comment.parentCommentId != nil)")
        
        if let parentId = comment.parentCommentId {
            print("🔵 添加为回复 - 父评论ID: \(parentId)")
            addReplyToParent(parentId: parentId, reply: comment)
        } else {
            print("🔵 添加为顶级评论")
            comments.insert(comment, at: 0)
            
            // 打印当前评论数量
            print("📊 添加后顶级评论数量: \(comments.count)")
            
            // 发送通知刷新UI - 确保在主线程发送
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                    object: nil,
                    userInfo: ["postID": self.id.uuidString, "commentID": comment.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshPostComments"),
                    object: nil,
                    userInfo: ["commentID": comment.id.uuidString]
                )
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentAdded"),
                    object: nil,
                    userInfo: ["commentID": comment.id.uuidString]
                )
            }
        }
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
        
        // 6. 移除内容末尾可能的字数统计信息，如"(132字，中等长度)"
        formattedContent = formattedContent.replacingOccurrences(
            of: "\\(\\d+字[，,]\\s*(短|中等|较长|长)长度\\)",
            with: "",
            options: .regularExpression
        )
        
        // 7. 移除以"注："或"注:"开头的注释性说明段落
        formattedContent = formattedContent.replacingOccurrences(
            of: "\n\n注[：:][^\n]+(\n[^\n]+)*$",
            with: "",
            options: .regularExpression
        )
        
        // 8. 移除开头可能的"注："或"注:"说明
        formattedContent = formattedContent.replacingOccurrences(
            of: "^注[：:][^\n]+(\n[^\n]+)*\n\n",
            with: "",
            options: .regularExpression
        )
        
        // 9. 移除内容中的零散括号描述，如"(羽毛笔突然溅开个墨点)"、"(执壶空见了见)"等
        formattedContent = formattedContent.replacingOccurrences(
            of: "\\([^()]{3,30}\\)",
            with: "",
            options: .regularExpression
        )
        
        // 10. 移除末尾可能存在的简短括号注释
        formattedContent = formattedContent.replacingOccurrences(
            of: "\\([^()]{3,50}\\)$",
            with: "",
            options: .regularExpression
        )
        
        // 返回格式化后的内容
        return formattedContent
    }
}

// MARK: - 静态样例数据
extension UserPostModel {
    /// 生成样例帖子数据
    static let samplePosts: [UserPostModel] = [
        UserPostModel(
            username: "爱因斯坦",
            userAvatar: "einstein",
            content: "刚刚完成了一个关于相对论的新思考实验，感觉非常兴奋！思考时间和空间如何相互关联真是奇妙。",
            images: ["science1"],
            datePosted: Date().addingTimeInterval(-86400), // 1天前
            likes: 42,
            comments: [],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: nil,
            characterID: nil,
            source: nil
        ),
        UserPostModel(
            username: "莎士比亚",
            userAvatar: "shakespeare",
            content: "今日灵感涌现，写下新剧本开篇。\"生存还是毁灭，这是个问题。\"总感觉这句台词会流传很久。",
            images: ["writing1"],
            datePosted: Date().addingTimeInterval(-172800), // 2天前
            likes: 37,
            comments: [],
            isLikedByCurrentUser: true,
            isBookmarkedByCurrentUser: true,
            contentType: nil,
            characterID: nil,
            source: nil
        ),
        UserPostModel(
            username: "达芬奇",
            userAvatar: "davinci",
            content: "今天在研究鸟类飞行时有了新发现。或许人类也能借助正确的工具飞上天空？正在设计一个飞行器草图。",
            images: ["art1", "science2"],
            datePosted: Date().addingTimeInterval(-259200), // 3天前
            likes: 28,
            comments: [],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: nil,
            characterID: nil,
            source: nil
        )
    ]
} 