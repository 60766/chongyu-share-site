import Foundation
import SwiftUI
import Combine

/**
 * 用户点赞服务
 * 负责记录、存储和管理用户的点赞行为
 * 与现有的PostViewModel集成，提供轻量级的点赞记录功能
 */
class UserLikeService: ObservableObject {
    static let shared = UserLikeService()
    
    // 用户点赞记录列表
    @Published var userLikes: [LikeRecord] = []
    
    // 存储键
    private let userLikesKey = "UserLikes_v1"
    
    private init() {
        loadLikes()
        
        // 监听点赞行为
        setupLikeListeners()
        
        // 监听恢复通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLikesDataRestored(_:)),
            name: NSNotification.Name("LikesDataRestored"),
            object: nil
        )
    }
    
    @objc private func handleLikesDataRestored(_ notification: Notification) {
        loadLikes()
        #if DEBUG
        debugLog("🔄 UserLikeService: 已重新加载点赞记录，共 \(userLikes.count) 条")
        #endif
    }
    
    // MARK: - 监听器设置
    
    private func setupLikeListeners() {
        // 监听帖子点赞
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostLiked(_:)),
            name: NSNotification.Name("PostLiked"),
            object: nil
        )
        
        // 监听评论点赞
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommentLiked(_:)),
            name: NSNotification.Name("CommentLiked"),
            object: nil
        )
    }
    
    // MARK: - 点赞处理器
    
    @objc private func handlePostLiked(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let post = userInfo["post"] as? UserPostModel,
              let isLiked = userInfo["isLiked"] as? Bool else {
            return
        }
        
        if isLiked {
            recordLike(for: post)
        } else {
            removeLike(postId: post.id.uuidString, type: .post)
        }
    }
    
    @objc private func handleCommentLiked(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let comment = userInfo["comment"] as? DetailedCommentModel,
              let post = userInfo["post"] as? UserPostModel,
              let isLiked = userInfo["isLiked"] as? Bool else {
            #if DEBUG
            debugLog("❌ UserLikeService: handleCommentLiked 参数解析失败")
            #endif
            return
        }
        
        #if DEBUG
        debugLog("❤️ UserLikeService: 处理评论点赞 - 评论ID: \(comment.id), 是否点赞: \(isLiked)")
        #endif
        
        if isLiked {
            recordCommentLike(for: comment, in: post)
        } else {
            removeLike(postId: comment.id.uuidString, type: .comment)
        }
    }
    
    // MARK: - 公共接口
    
    /**
     * 记录帖子点赞
     */
    func recordLike(for post: UserPostModel) {
        let likeRecord = LikeRecord(
            postId: post.id.uuidString,
            type: .post,
            title: extractTitle(from: post.content),
            content: post.content,
            authorName: post.username,
            authorAvatar: post.userAvatar,
            characterName: getCharacterName(for: post.characterID),
            timestamp: Date(),
            likeCount: post.likes
        )
        
        addLikeRecord(likeRecord)
    }
    
    /**
     * 记录评论点赞
     */
    func recordCommentLike(for comment: DetailedCommentModel, in post: UserPostModel) {
        let likeRecord = LikeRecord(
            postId: comment.id.uuidString,
            type: .comment,
            title: "",
            content: comment.content,
            authorName: comment.username,
            authorAvatar: comment.userAvatar,
            characterName: getCharacterName(for: post.characterID),
            timestamp: Date(),
            likeCount: comment.likes
        )
        
        addLikeRecord(likeRecord)
    }
    
    /**
     * 获取用户的所有点赞记录
     */
    func getUserLikes() -> [LikeRecord] {
        return userLikes.sorted { $0.timestamp > $1.timestamp }
    }
    
    /**
     * 获取特定类型的点赞记录
     */
    func getUserLikes(type: LikeRecordType) -> [LikeRecord] {
        return userLikes.filter { $0.type == type }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    /**
     * 检查是否已点赞某个内容
     */
    func isLiked(postId: String, type: LikeRecordType) -> Bool {
        return userLikes.contains { $0.postId == postId && $0.type == type }
    }
    
    /**
     * 清除所有点赞记录
     */
    func clearAllLikes() {
        DispatchQueue.main.async {
            self.userLikes.removeAll()
            self.saveLikes()
            #if DEBUG
            debugLog("🗑️ 已清空所有点赞记录")
            #endif
        }
    }
    
    /**
     * 移除特定的点赞记录
     */
    func removeLikeRecord(_ record: LikeRecord) {
        DispatchQueue.main.async {
            self.userLikes.removeAll { $0.id == record.id }
            self.saveLikes()
            #if DEBUG
            debugLog("🗑️ 移除点赞记录: \(record.type.rawValue) - \(record.authorName)")
            #endif
            
            // 发送通知，告知其他组件点赞状态已改变
            if record.type == .post {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostLikeRemoved"),
                    object: nil,
                    userInfo: ["postId": record.postId]
                )
            } else if record.type == .comment {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentLikeRemoved"),
                    object: nil,
                    userInfo: ["commentId": record.postId]
                )
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func addLikeRecord(_ record: LikeRecord) {
        DispatchQueue.main.async {
            // 避免重复记录
            if !self.userLikes.contains(where: { $0.postId == record.postId && $0.type == record.type }) {
                self.userLikes.append(record)
                self.saveLikes()
                #if DEBUG
                debugLog("👍 记录点赞: \(record.type.rawValue) - \(record.authorName)")
                #endif
            }
        }
    }
    
    private func removeLike(postId: String, type: LikeRecordType) {
        DispatchQueue.main.async {
            self.userLikes.removeAll { $0.postId == postId && $0.type == type }
            self.saveLikes()
            #if DEBUG
            debugLog("👎 移除点赞记录: \(type.rawValue)")
            #endif
        }
    }
    
    private func extractTitle(from content: String) -> String {
        // 提取内容的前30个字符作为标题
        let maxLength = 30
        if content.count <= maxLength {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<index]) + "..."
    }
    
    private func getCharacterName(for characterId: String?) -> String? {
        guard let characterId = characterId else { return nil }
        
        // 从CharacterDataManager获取角色名称
        let characters = CharacterDataManager.shared.getAllCharactersInfo()
        return characters.first { $0.id == characterId }?.name
    }
    
    // MARK: - 持久化
    
    /**
     * 重新加载点赞数据（公共方法，用于视图刷新时调用）
     */
    func reloadLikes() {
        loadLikes()
        #if DEBUG
        debugLog("🔄 UserLikeService: 重新加载点赞记录，共 \(userLikes.count) 条")
        #endif
    }
    
    private func saveLikes() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(userLikes)
            UserDefaults.standard.set(data, forKey: userLikesKey)
            // 确保数据立即同步到磁盘
            UserDefaults.standard.synchronize()
            #if DEBUG
            debugLog("💾 保存了 \(userLikes.count) 条点赞记录")
            #endif
        } catch {
            #if DEBUG
            debugLog("❌ 保存点赞记录失败: \(error)")
            #endif
        }
    }
    
    private func loadLikes() {
        guard let data = UserDefaults.standard.data(forKey: userLikesKey) else {
            #if DEBUG
            debugLog("📂 首次使用，无点赞记录")
            #endif
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            userLikes = try decoder.decode([LikeRecord].self, from: data)
            #if DEBUG
            debugLog("📂 加载了 \(userLikes.count) 条点赞记录")
            #endif
        } catch {
            #if DEBUG
            debugLog("❌ 加载点赞记录失败: \(error)")
            #endif
            userLikes = []
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 