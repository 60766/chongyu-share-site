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
    func addComment(username: String, userAvatar: String, content: String, parentCommentId: UUID? = nil, replyToUsername: String? = nil, isVirtualCharacter: Bool = false, characterID: String? = nil, userId: String? = nil, isCurrentUser: Bool = false, commentId: UUID? = nil) {
        // 🔧 使用提供的ID或生成新的ID
        let finalCommentId = commentId ?? UUID()
        print("🔵 创建新评论 - ID: \(finalCommentId), 用户: \(username), 是否为回复: \(parentCommentId != nil)")
        print("🔧 评论ID来源: \(commentId != nil ? "外部提供" : "内部生成")")
        let userIdentifier = userId ?? UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        if isCurrentUser {
            UserDefaults.standard.set(userIdentifier, forKey: "current_user_id")
        }
        let newComment = DetailedCommentModel(
            id: finalCommentId,  // 🔧 使用确定的ID
            username: username,
            userAvatar: userAvatar,
            content: content,
            userId: userIdentifier,
            isCurrentUser: isCurrentUser,
            isVirtualCharacter: isVirtualCharacter,
            characterID: characterID,
            parentCommentId: parentCommentId,  // 确保正确设置父评论ID
            replyToUsername: replyToUsername
        )
        
        if let parentId = parentCommentId {
            print("🔵 添加为回复 - 父评论ID: \(parentId)")
            
            // 在顶级评论中查找父评论
            if let index = comments.firstIndex(where: { $0.id == parentId }) {
                print("✅ 在顶级评论中找到父评论 - 索引: \(index)")
                
                // 添加回复到父评论的replies数组
                comments[index].replies.insert(newComment, at: 0)
                print("📊 添加回复到父评论 - 回复数: \(comments[index].replies.count)")
            } else {
                // 在所有评论的嵌套回复中查找父评论
                var found = false
                for i in 0..<comments.count {
                    if findAndAddReply(in: &comments[i].replies, parentId: parentId, reply: newComment) {
                        found = true
                        print("✅ 在嵌套回复中找到父评论并添加回复")
                        break
                    }
                }
                
                // 如果没有找到父评论，检查是否为虚拟角色
                if !found {
                    if !isVirtualCharacter {
                        print("⚠️ 未找到父评论，作为顶级评论添加")
                        comments.insert(newComment, at: 0)
                    } else {
                        // 🔧 修复：虚拟角色回复找不到父评论时，不应该添加到顶级评论列表
                        // 这会导致重复显示问题
                        print("❌ 阻止虚拟角色回复成为顶级评论 - 角色: \(username), 找不到父评论ID: \(parentId)")
                        print("🔧 原因：虚拟角色回复应该只作为回复存在，不应该成为顶级评论")
                    }
                }
            }
        } else {
            // 如果是顶级评论，添加到comments数组的开头
            print("🔵 添加为顶级评论")
            comments.insert(newComment, at: 0)
        }
        
        // 简化通知机制 - 只发送对象变更通知
        DispatchQueue.main.async {
            // 直接发送对象变更通知，让SwiftUI自动刷新
            self.objectWillChange.send()
        }
    }

    /// 递归查找并添加回复
    private func findAndAddReply(in replies: inout [DetailedCommentModel], parentId: UUID, reply: DetailedCommentModel) -> Bool {
        // 在当前层级查找父评论
        if let index = replies.firstIndex(where: { $0.id == parentId }) {
            // 找到父评论，添加回复到其replies数组的末尾
            replies[index].replies.append(reply)
            return true
        }
        
        // 递归检查更深层次
        for i in 0..<replies.count {
            var nestedReplies = replies[i].replies
            if findAndAddReply(in: &nestedReplies, parentId: parentId, reply: reply) {
                replies[i].replies = nestedReplies
                return true
            }
        }
        
        return false
    }
    
    /// 添加回复到指定的父评论
    func addReplyToParent(parentId: UUID, reply: DetailedCommentModel) {
        print("🔍 尝试添加回复到父评论 - 父评论ID: \(parentId), 回复ID: \(reply.id)")
        
        // 优先在顶级评论中查找父评论
        if let index = comments.firstIndex(where: { $0.id == parentId }) {
            print("✅ 在顶级评论中找到父评论 - 索引: \(index), 用户名: \(comments[index].username)")
            
            // 添加回复到该评论的replies数组的末尾
            comments[index].replies.append(reply)
            
            // 打印回复数量
            print("📊 该父评论现在有 \(comments[index].replies.count) 条回复")
            print("📊 回复内容: \"\(reply.content.prefix(30))...\"")
            
            // 简化通知机制 - 只发送对象变更通知
            DispatchQueue.main.async {
                // 直接发送对象变更通知，让SwiftUI自动刷新
                self.objectWillChange.send()
            }
            return
        }
        
        // 在所有评论的回复中递归查找父评论
        var found = false
        
        // 遍历每个顶级评论
        for i in 0..<comments.count {
            if findAndAddReply(in: &comments[i].replies, parentId: parentId, reply: reply) {
                found = true
                print("✅ 在嵌套回复中找到父评论并添加回复")
                
                // 简化通知机制 - 只发送对象变更通知
                DispatchQueue.main.async {
                    // 直接发送对象变更通知，让SwiftUI自动刷新
                    self.objectWillChange.send()
                }
                break
            }
        }
        
        // 如果没有找到父评论，将回复作为顶级评论添加
        if !found {
            // 🔧 关键修复：虚拟角色回复绝对不能成为顶级评论
            if reply.isVirtualCharacter {
                // 虚拟角色回复找不到父评论时，不应该添加到顶级评论列表
                // 这会导致重复显示问题
                print("❌ 阻止虚拟角色回复成为顶级评论 - 角色: \(reply.username), 找不到父评论ID: \(parentId)")
                print("🔧 原因：虚拟角色回复应该只作为回复存在，不应该成为顶级评论")
                print("🔧 解决方案：丢弃这条回复，避免重复显示")
                return
            }
            
            // 只有非虚拟角色的用户评论才能在找不到父评论时作为顶级评论添加
            print("⚠️ 未找到父评论，作为顶级评论添加")
            var newTopLevelComment = reply
            newTopLevelComment.parentCommentId = nil // 清除父评论ID，因为找不到父评论
            comments.append(newTopLevelComment) // 改为append，保持时间顺序
            
            // 简化通知机制 - 只发送对象变更通知
            DispatchQueue.main.async {
                // 直接发送对象变更通知，让SwiftUI自动刷新
                self.objectWillChange.send()
            }
        }
    }
    
    /// 获取顶级评论（不包含回复）
    func getTopLevelComments() -> [DetailedCommentModel] {
        return comments.filter { comment in
            // 必须是顶级评论（parentCommentId为nil）
            guard comment.parentCommentId == nil else { 
                return false 
            }
            
            // 🔧 修复：只过滤真正的回复，不过滤用户评论
            if comment.isVirtualCharacter {
                // 如果虚拟角色评论有replyToUsername，说明是回复，不应该显示在主列表
                if comment.replyToUsername != nil {
                    print("🚫 过滤虚拟角色回复（有replyToUsername）：\(comment.username) -> \(comment.replyToUsername!)")
                    return false
                }
                
                // 🔧 关键修复：移除时间窗口检查，避免过滤用户刚发布的评论
                // 时间窗口检查会导致用户刚发布的评论被错误过滤
                // 现在只依赖replyToUsername来判断是否为回复
                
                // 虚拟角色的顶级评论（邀请评论）应该显示
                print("✅ 保留虚拟角色顶级评论：\(comment.username)")
            }
            
            return true
        }
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
        
        // 创建评论ID到评论的映射，用于快速查找
        var commentIdMap: [UUID: DetailedCommentModel] = [:]
        var usernameToCommentMap: [String: UUID] = [:]
        
        // 第一次遍历，建立映射关系
        for comment in comments {
            commentIdMap[comment.id] = comment
            usernameToCommentMap[comment.username] = comment.id
        }
        
        // 第二次遍历，处理回复评论的parentCommentId
        var updatedComments = comments
        for i in 0..<updatedComments.count {
            // 如果有replyToUsername但没有parentCommentId，尝试设置parentCommentId
            if let replyToUsername = updatedComments[i].replyToUsername, 
               updatedComments[i].parentCommentId == nil {
                if let parentId = usernameToCommentMap[replyToUsername] {
                    updatedComments[i].parentCommentId = parentId
                    print("✅ 为评论 \(updatedComments[i].id) 设置父评论ID: \(parentId)")
                }
            }
        }
        
        // 将评论分为顶级评论和回复评论
        var topLevelComments: [DetailedCommentModel] = []
        var replyComments: [DetailedCommentModel] = []
        
        for comment in updatedComments {
            if comment.parentCommentId == nil {
                // 这是顶级评论
                var commentCopy = comment
                commentCopy.replies = [] // 清空回复列表，后面重新组织
                topLevelComments.append(commentCopy)
            } else {
                // 这是回复评论
                replyComments.append(comment)
            }
        }
        
        // 将所有回复添加到对应的父评论下
        for reply in replyComments {
            if let parentId = reply.parentCommentId {
                // 先检查父评论是否在顶级评论中
                if let index = topLevelComments.firstIndex(where: { $0.id == parentId }) {
                    // 父评论在顶级评论中，直接添加
                    topLevelComments[index].replies.append(reply)
                    print("✅ 将回复 \(reply.id) 添加到顶级父评论 \(parentId)")
                } else {
                    // 父评论可能是另一个回复，需要递归查找
                    var found = false
                    for i in 0..<topLevelComments.count {
                        if addReplyToNestedParent(in: &topLevelComments[i].replies, parentId: parentId, reply: reply) {
                            found = true
                            print("✅ 将回复 \(reply.id) 添加到嵌套父评论 \(parentId)")
                            break
                        }
                    }
                    
                    // 如果没有找到父评论，检查是否为虚拟角色回复
                    if !found {
                        if reply.isVirtualCharacter {
                            // 虚拟角色回复找不到父评论时，丢弃该回复，不要转换为顶级评论
                            print("❌ 虚拟角色回复找不到父评论，丢弃回复 - 角色: \(reply.username), 父评论ID: \(parentId)")
                        } else {
                            // 只有非虚拟角色的回复才能转换为顶级评论
                            print("⚠️ 未找到父评论 \(parentId)，将用户回复 \(reply.id) 作为顶级评论添加")
                        var replyAsTopLevel = reply
                        replyAsTopLevel.parentCommentId = nil // 清除父评论ID
                        topLevelComments.append(replyAsTopLevel)
                        }
                    }
                }
            }
        }
        
        // 对每个顶级评论的回复进行排序
        for i in 0..<topLevelComments.count {
            // 首先按照对话流排序
            topLevelComments[i].replies = sortRepliesByConversationFlow(topLevelComments[i].replies)
        }
        
        // 更新评论数组
        comments = topLevelComments
        print("✅ 评论嵌套关系更新完成，更新后顶级评论数: \(comments.count)")
        
        // 打印评论结构，帮助调试
        for comment in comments {
            comment.printStructure()
        }
    }
    
    /// 递归添加回复到嵌套父评论
    private func addReplyToNestedParent(in replies: inout [DetailedCommentModel], parentId: UUID, reply: DetailedCommentModel) -> Bool {
        // 在当前层级查找父评论
        if let index = replies.firstIndex(where: { $0.id == parentId }) {
            // 找到父评论，添加回复到其replies数组的末尾
            replies[index].replies.append(reply)
            return true
        }
        
        // 递归查找更深层级
        for i in 0..<replies.count {
            var nestedReplies = replies[i].replies
            if addReplyToNestedParent(in: &nestedReplies, parentId: parentId, reply: reply) {
                replies[i].replies = nestedReplies
                return true
            }
        }
        
        return false
    }
    
    /// 按照对话流排序回复
    private func sortRepliesByConversationFlow(_ replies: [DetailedCommentModel]) -> [DetailedCommentModel] {
        // 创建回复ID到回复的映射
        var replyMap: [UUID: DetailedCommentModel] = [:]
        for reply in replies {
            replyMap[reply.id] = reply
        }
        
        // 按照对话流排序
        return replies.sorted { reply1, reply2 in
            // 规则1：如果reply2是对reply1的直接回复，reply2应该排在reply1后面
            if reply2.parentCommentId == reply1.id {
                return true
            }
            
            // 规则2：如果reply1是对reply2的直接回复，reply1应该排在reply2后面
            if reply1.parentCommentId == reply2.id {
                return false
            }
            
            // 规则3：如果reply2回复的是reply1的用户，reply2应该排在reply1后面
            if reply2.replyToUsername == reply1.username {
                return true
            }
            
            // 规则4：如果reply1回复的是reply2的用户，reply1应该排在reply2后面
            if reply1.replyToUsername == reply2.username {
                return false
            }
            
            // 规则5：处理同一对话链 - 如果两条回复都回复了同一个人，按时间排序
            if let replyTo1 = reply1.replyToUsername, 
               let replyTo2 = reply2.replyToUsername,
               replyTo1 == replyTo2 {
                // 如果都是回复同一个人，按时间倒序排列（新的在上方）
                return reply1.datePosted > reply2.datePosted
            }
            
            // 规则6：同一发送者的多条消息按时间排序
            if reply1.username == reply2.username {
                // 同一用户的多条消息，按时间倒序排列（新的在上方）
                return reply1.datePosted > reply2.datePosted
            }
            
            // 规则7：虚拟角色回复优先显示
            if reply1.isVirtualCharacter && !reply2.isVirtualCharacter {
                return true
            }
            
            if !reply1.isVirtualCharacter && reply2.isVirtualCharacter {
                return false
            }
            
            // 默认规则：按时间倒序排列（新的在上方）
            return reply1.datePosted > reply2.datePosted
        }
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
            // 关键：强制刷新 comments 数组，确保 UI 刷新
            self.comments = self.comments.map { $0 } // 触发 SwiftUI 刷新
        } else {
            // 允许非虚拟角色和邀请的虚拟角色发表顶级评论
            // 邀请的虚拟角色评论特征：isVirtualCharacter=true 且 replyToUsername=nil
            let isInvitedVirtualComment = comment.isVirtualCharacter && comment.replyToUsername == nil
            
            if !comment.isVirtualCharacter || isInvitedVirtualComment {
                if isInvitedVirtualComment {
                    print("🔵 添加邀请虚拟角色的顶级评论 - 角色: \(comment.username)")
                } else {
                    print("🔵 添加用户顶级评论")
                }
            comments.insert(comment, at: 0)
            // 打印当前评论数量
            print("📊 添加后顶级评论数量: \(comments.count)")
            // 简化通知机制 - 只发送对象变更通知
            DispatchQueue.main.async {
                // 直接发送对象变更通知，让SwiftUI自动刷新
                self.objectWillChange.send()
                }
            } else {
                print("❌ 阻止虚拟角色回复作为顶级评论 - 角色: \(comment.username), replyToUsername: \(comment.replyToUsername ?? "nil")")
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