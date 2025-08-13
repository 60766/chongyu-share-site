import Foundation
import SwiftUI
import Combine

/**
 * 本地通知服务
 * 基于用户真实行为生成对应的通知，完全本地存储
 */
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    // 通知列表
    @Published var notifications: [NotificationModel] = []
    
    // 用户交互统计（用于生成关注通知）
    private var characterInteractionCount: [String: Int] = [:]
    
    // 通知存储键
    private let notificationsKey = "LocalNotifications"
    private let interactionCountKey = "CharacterInteractionCount"
    
    private init() {
        loadNotifications()
        loadInteractionCount()
        
        // 监听应用内的用户行为
        setupBehaviorListeners()
    }
    
    // MARK: - 行为监听器
    
    private func setupBehaviorListeners() {
        // 监听评论生成通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommentGenerated(_:)),
            name: NSNotification.Name("CommentsGenerated"),
            object: nil
        )
        
        // 监听点赞行为通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostLiked(_:)),
            name: NSNotification.Name("PostLiked"),
            object: nil
        )
        
        // 监听用户与角色互动
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCharacterInteraction(_:)),
            name: NSNotification.Name("CharacterInteraction"),
            object: nil
        )
    }
    
    // MARK: - 行为处理器
    
    @objc private func handleCommentGenerated(_ notification: Notification) {
        print("📨 NotificationService: 收到评论生成通知")
        
        guard let userInfo = notification.userInfo,
              let postId = userInfo["postID"] as? String,
              let commentsMap = userInfo["commentsMap"] as? [String: String] else {
            print("❌ NotificationService: 评论生成通知数据无效")
            return
        }
        
        // 提取用户评论和原帖信息
        let userComment = userInfo["userComment"] as? String
        let originalPost = userInfo["originalPost"] as? String
        let originalPostAuthor = userInfo["originalPostAuthor"] as? String
        
        print("📨 NotificationService: 处理\(commentsMap.count)个角色的评论通知")
        print("📝 用户评论: \(userComment ?? "无")")
        print("📄 原帖内容: \(originalPost ?? "无")")
        print("👤 原帖作者: \(originalPostAuthor ?? "无")")
        print("🔍 UserInfo 完整内容: \(userInfo)")
        
        // 为每个AI生成的评论创建通知
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...3)) {
            for (characterId, commentContent) in commentsMap {
                print("📨 NotificationService: 为角色\(characterId)创建评论通知")
                self.createCommentNotification(
                    characterId: characterId,
                    content: commentContent,
                    postId: postId,
                    userComment: userComment,
                    originalPost: originalPost,
                    originalPostAuthor: originalPostAuthor
                )
            }
        }
    }
    
    @objc private func handlePostLiked(_ notification: Notification) {
        print("❤️ NotificationService: 收到点赞通知")
        
        guard let userInfo = notification.userInfo,
              let postId = userInfo["postId"] as? String,
              let authorCharacterId = userInfo["authorCharacterId"] as? String else {
            print("❌ NotificationService: 点赞通知数据无效")
            return
        }
        
        print("❤️ NotificationService: 为角色\(authorCharacterId)创建点赞感谢通知")
        
        // 延迟生成点赞感谢通知
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
            self.createLikeNotification(
                characterId: authorCharacterId,
                postId: postId
            )
        }
    }
    
    @objc private func handleCharacterInteraction(_ notification: Notification) {
        print("🤝 NotificationService: 收到角色互动通知")
        
        guard let userInfo = notification.userInfo,
              let characterId = userInfo["characterId"] as? String else {
            print("❌ NotificationService: 角色互动通知数据无效")
            return
        }
        
        // 统计与角色的互动次数
        characterInteractionCount[characterId, default: 0] += 1
        saveInteractionCount()
        
        let currentCount = characterInteractionCount[characterId]!
        print("🤝 NotificationService: 角色\(characterId)互动次数: \(currentCount)")
        
        // 达到一定互动次数时生成关注通知
        if currentCount == 3 {
            print("🤝 NotificationService: 角色\(characterId)互动达到3次，将生成关注通知")
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 5...10)) {
                self.createFollowNotification(characterId: characterId)
            }
        }
    }
    
    // MARK: - 通知生成器
    
    private func createCommentNotification(characterId: String, content: String, postId: String, userComment: String? = nil, originalPost: String? = nil, originalPostAuthor: String? = nil) {
        guard let character = getCharacterInfo(characterId: characterId) else { return }
        
        print("🔔 创建评论通知:")
        print("   角色: \(character.name)")
        print("   AI回复: \(content.prefix(30))...")
        print("   用户评论: \(userComment?.prefix(30) ?? "无")...")
        print("   原帖: \(originalPost?.prefix(30) ?? "无")...")
        print("   原帖作者: \(originalPostAuthor ?? "无")")
        print("   📝 完整用户评论: \(userComment ?? "无")")
        print("   📄 完整原帖内容: \(originalPost ?? "无")")
        
        let notification = NotificationModel(
            type: .comment,
            avatar: character.image,
            username: character.name,
            content: content, // 使用完整内容，显示组件会处理长度
            time: formatTimeAgo(Date()),
            isOnline: Bool.random(),
            actionText: "评论",
            character: character,
            previewContent: nil, // 不使用previewContent，因为我们有更详细的上下文
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: true,
            userComment: userComment,
            userPost: nil,
            originalPost: originalPost,
            originalPostAuthor: originalPostAuthor
        )
        
        addNotification(notification)
    }
    
    private func createLikeNotification(characterId: String, postId: String) {
        guard let character = getCharacterInfo(characterId: characterId) else { return }
        
        let thankMessages = [
            "谢谢你的认可！",
            "很高兴你喜欢我的分享",
            "你的点赞让我很开心",
            "感谢你的支持！"
        ]
        
        let notification = NotificationModel(
            type: .like,
            avatar: character.image,
            username: character.name,
            content: thankMessages.randomElement(),
            time: formatTimeAgo(Date()),
            isOnline: Bool.random(),
            actionText: "点赞",
            character: character,
            previewContent: nil,
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "like",
            isGenerated: true,
            userComment: nil,
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        )
        
        addNotification(notification)
    }
    
    private func createFollowNotification(characterId: String) {
        guard let character = getCharacterInfo(characterId: characterId) else { return }
        
        let notification = NotificationModel(
            type: .follow,
            avatar: character.image,
            username: character.name,
            content: nil,
            time: formatTimeAgo(Date()),
            isOnline: Bool.random(),
            actionText: "关注",
            character: character,
            previewContent: nil,
            relatedPostId: nil,
            relatedCommentId: nil,
            triggeredByAction: "interaction",
            isGenerated: true,
            userComment: nil,
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        )
        
        addNotification(notification)
    }
    
    // MARK: - 直接创建通知方法
    
    func createCommentNotification(
        characterId: String,
        characterName: String,
        characterAvatar: String,
        commentContent: String,
        postId: String,
        postTitle: String
    ) {
        print("💬 NotificationService: 直接创建评论通知")
        print("   角色: \(characterName)")
        print("   评论内容: \(commentContent.prefix(30))...")
        
        let notification = NotificationModel(
            type: .comment,
            avatar: characterAvatar,
            username: characterName,
            content: commentContent,
            time: formatTimeAgo(Date()),
            isOnline: Bool.random(),
            actionText: "回复了你",
            character: NotificationModel.CharacterInfo(
                name: characterName,
                era: getCharacterEra(characterId),
                category: .historical,
                image: characterAvatar
            ),
            previewContent: postTitle,
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: false,
            userComment: nil,
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        )
        
        addNotification(notification)
    }
    
    // MARK: - 系统通知生成
    
    func generateSystemWelcomeNotification() {
        let systemCharacters = ["einstein", "shakespeare", "davinci", "curie"]
        let character = systemCharacters.randomElement()!
        
        let notification = NotificationModel(
            type: .system,
            avatar: "system",
            username: "系统通知 欢迎来到虫遇",
            content: "开始你的时空对话之旅吧！",
            time: formatTimeAgo(Date()),
            isOnline: false,
            actionText: nil,
            character: NotificationModel.CharacterInfo(
                name: "系统",
                era: "现代",
                category: .all,
                image: character
            ),
            previewContent: nil,
            relatedPostId: nil,
            relatedCommentId: nil,
            triggeredByAction: "system",
            isGenerated: false,
            userComment: nil,
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        )
        
        addNotification(notification)
    }
    
    // MARK: - 辅助方法
    
    private func getCharacterEra(_ characterId: String) -> String {
        switch characterId.lowercased() {
        case "kongzi": return "春秋时期"
        case "einstein": return "现代"
        case "shakespeare": return "文艺复兴"
        case "davinci": return "文艺复兴"
        case "curie": return "现代"
        case "newton": return "近代"
        case "mozart": return "古典主义"
        case "aristotle": return "古希腊"
        case "plato": return "古希腊"
        case "socrates": return "古希腊"
        default: return "未知时代"
        }
    }
    
    private func addNotification(_ notification: NotificationModel) {
        // 添加调试输出
        print("🔔 NotificationService: 添加新通知")
        print("   类型: \(notification.type)")
        print("   发送者: \(notification.character.name)")
        print("   内容: \(notification.content?.prefix(30) ?? "无内容")...")
        print("   当前通知总数: \(notifications.count + 1)")
        
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            self.saveNotifications()
        }
    }
    
    private func getCharacterInfo(characterId: String) -> NotificationModel.CharacterInfo? {
        // 这里需要根据实际的角色数据获取角色信息
        // 暂时返回示例数据，实际使用时需要查询角色数据库
        let sampleCharacters: [String: NotificationModel.CharacterInfo] = [
            "einstein": NotificationModel.CharacterInfo(
                name: "爱因斯坦",
                era: "20世纪",
                category: .scientist,
                image: "einstein"
            ),
            "shakespeare": NotificationModel.CharacterInfo(
                name: "莎士比亚",
                era: "16-17世纪",
                category: .writer,
                image: "shakespeare"
            ),
            "davinci": NotificationModel.CharacterInfo(
                name: "达芬奇",
                era: "文艺复兴",
                category: .artist,
                image: "davinci"
            )
        ]
        
        return sampleCharacters[characterId]
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - 数据持久化
    
    private func saveNotifications() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(notifications)
            UserDefaults.standard.set(data, forKey: notificationsKey)
        } catch {
            print("❌ 保存通知失败: \(error)")
        }
    }
    
    private func loadNotifications() {
        guard let data = UserDefaults.standard.data(forKey: notificationsKey) else {
            // 首次使用，生成欢迎通知
            generateSystemWelcomeNotification()
            return
        }
        
        do {
            let decoder = JSONDecoder()
            notifications = try decoder.decode([NotificationModel].self, from: data)
            print("📂 加载了 \(notifications.count) 条本地通知")
        } catch {
            print("❌ 加载通知失败: \(error)")
            notifications = []
        }
    }
    
    private func saveInteractionCount() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(characterInteractionCount)
            UserDefaults.standard.set(data, forKey: interactionCountKey)
        } catch {
            print("❌ 保存互动统计失败: \(error)")
        }
    }
    
    private func loadInteractionCount() {
        guard let data = UserDefaults.standard.data(forKey: interactionCountKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            characterInteractionCount = try decoder.decode([String: Int].self, from: data)
        } catch {
            print("❌ 加载互动统计失败: \(error)")
        }
    }
    
    // MARK: - 公共接口
    
    /**
     * 清除所有通知（重装应用效果）
     */
    func clearAllNotifications() {
        notifications.removeAll()
        characterInteractionCount.removeAll()
        UserDefaults.standard.removeObject(forKey: notificationsKey)
        UserDefaults.standard.removeObject(forKey: interactionCountKey)
    }
    
    /**
     * 获取未读通知数量（可选功能）
     */
    func getUnreadCount() -> Int {
        // 简单实现：最近1小时的通知算作未读
        let _ = Date().addingTimeInterval(-3600)
        return notifications.filter { _ in
            // 这里需要解析time字段或添加创建时间字段
            true // 暂时返回所有
        }.count
    }
    
    /**
     * 添加测试通知（公开方法，用于测试）
     */
    func addTestNotification(_ notification: NotificationModel) {
        addNotification(notification)
    }
    
    /**
     * 添加包含用户评论的测试通知
     */
    func addTestNotificationWithUserComment() {
        let testNotification = NotificationModel(
            type: .comment,
            avatar: "hawking",
            username: "霍金",
            content: "你的观点很有意思！黑洞确实是宇宙中最神秘的现象之一。我在研究中发现，黑洞不仅会吞噬物质，还会通过霍金辐射慢慢蒸发。",
            time: formatTimeAgo(Date()),
            isOnline: true,
            actionText: "评论",
            character: NotificationModel.CharacterInfo(
                name: "霍金",
                era: "现代",
                category: .scientist,
                image: "hawking"
            ),
            previewContent: nil,
            relatedPostId: "test_post",
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: true,
            userComment: "老师，我对黑洞的理论很感兴趣，请问黑洞真的会永远存在吗？",
            userPost: nil,
            originalPost: "在探索宇宙深处的过程中，我们发现了许多令人震撼的现象。黑洞作为宇宙中最极端的天体，挑战着我们对时空的理解。",
            originalPostAuthor: "爱因斯坦"
        )
        
        addNotification(testNotification)
        print("✅ 已添加包含用户评论的测试通知")
    }
}

// MARK: - 通知模型已在NotificationModel.swift中定义Codable扩展 