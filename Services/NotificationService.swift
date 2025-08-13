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
        guard let userInfo = notification.userInfo,
              let postId = userInfo["postID"] as? String,
              let commentsMap = userInfo["commentsMap"] as? [String: String] else {
            return
        }
        
        // 为每个AI生成的评论创建通知
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...3)) {
            for (characterId, commentContent) in commentsMap {
                self.createCommentNotification(
                    characterId: characterId,
                    content: commentContent,
                    postId: postId
                )
            }
        }
    }
    
    @objc private func handlePostLiked(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let postId = userInfo["postId"] as? String,
              let authorCharacterId = userInfo["authorCharacterId"] as? String else {
            return
        }
        
        // 延迟生成点赞感谢通知
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
            self.createLikeNotification(
                characterId: authorCharacterId,
                postId: postId
            )
        }
    }
    
    @objc private func handleCharacterInteraction(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let characterId = userInfo["characterId"] as? String else {
            return
        }
        
        // 统计与角色的互动次数
        characterInteractionCount[characterId, default: 0] += 1
        saveInteractionCount()
        
        // 达到一定互动次数时生成关注通知
        if characterInteractionCount[characterId]! == 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 5...10)) {
                self.createFollowNotification(characterId: characterId)
            }
        }
    }
    
    // MARK: - 通知生成器
    
    private func createCommentNotification(characterId: String, content: String, postId: String) {
        guard let character = getCharacterInfo(characterId: characterId) else { return }
        
        let notification = NotificationModel(
            type: .comment,
            avatar: character.image,
            username: character.name,
            content: content.count > 50 ? String(content.prefix(50)) + "..." : content,
            time: formatTimeAgo(Date()),
            isOnline: Bool.random(),
            actionText: "评论",
            character: character,
            previewContent: content,
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: true
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
            isGenerated: true
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
            isGenerated: true
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
            isGenerated: false
        )
        
        addNotification(notification)
    }
    
    // MARK: - 辅助方法
    
    private func addNotification(_ notification: NotificationModel) {
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            
            // 限制通知数量，保持性能
            if self.notifications.count > 100 {
                self.notifications = Array(self.notifications.prefix(100))
            }
            
            self.saveNotifications()
            
            print("📱 生成新通知: \(notification.username) - \(notification.type)")
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
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return notifications.filter { 
            // 这里需要解析time字段或添加创建时间字段
            true // 暂时返回所有
        }.count
    }
}

// MARK: - NotificationModel 扩展

extension NotificationModel: Codable {
    enum CodingKeys: String, CodingKey {
        case type, avatar, username, content, time, isOnline, actionText
        case character, previewContent, relatedPostId, relatedCommentId
        case triggeredByAction, isGenerated
        case userComment, userPost, originalPost, originalPostAuthor
    }
}

extension NotificationModel.CharacterInfo: Codable {}
extension NotificationModel.NotificationType: Codable {} 