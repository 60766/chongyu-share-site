import Foundation
import SwiftUI
import Combine

// 扩展String以支持正则表达式匹配
extension String {
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

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
        
        // 确保系统通知存在（包括新手指南）
        generateAdditionalSystemNotifications()
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
        #if DEBUG
        print("📨 NotificationService: 收到评论生成通知")
        print("📨 当前通知数量: \(self.notifications.count)")
        #endif
        
        guard let userInfo = notification.userInfo,
              let postId = userInfo["postID"] as? String,
              let commentsMap = userInfo["commentsMap"] as? [String: String] else {
            #if DEBUG
            print("❌ NotificationService: 评论生成通知数据无效")
            print("❌ userInfo: \(notification.userInfo ?? [:])")
            #endif
            return
        }
        
        // 检查是否为邀请的虚拟角色评论
        let isInvited = userInfo["isInvited"] as? Bool ?? false
        
        if isInvited {
            #if DEBUG
            print("🚫 NotificationService: 这是邀请虚拟角色的评论，跳过创建通知")
            #endif
            return
        }
        
        // 提取用户评论和原帖信息
        let userComment = userInfo["userComment"] as? String
        let originalPost = userInfo["originalPost"] as? String
        let originalPostAuthor = userInfo["originalPostAuthor"] as? String
        
        #if DEBUG
        print("📨 NotificationService: 处理\(commentsMap.count)个角色的评论通知")
        print("📝 用户评论: \(userComment ?? "无")")
        print("📝 用户评论是否为空: \(userComment?.isEmpty ?? true)")
        print("📝 用户评论长度: \(userComment?.count ?? 0)")
        print("📝 原帖ID: \(postId)")
        print("📝 角色评论: \(commentsMap)")
        #endif
        
        // 为每个AI生成的评论创建通知 - 🔧 移除延迟，立即创建通知
        DispatchQueue.main.async {
            for (characterId, commentContent) in commentsMap {
                #if DEBUG
                print("📨 NotificationService: 为角色\(characterId)创建评论通知")
                print("🔍 传递给createCommentNotification的userComment: '\(userComment ?? "nil")'")
                #endif
                self.createCommentNotification(
                    characterId: characterId,
                    content: commentContent,
                    postId: postId,
                    userComment: userComment,
                    originalPost: originalPost,
                    originalPostAuthor: originalPostAuthor
                )
            }
            #if DEBUG
            print("📨 NotificationService: 评论通知创建完成，新的通知数量: \(self.notifications.count)")
            #endif
        }
    }
    
    @objc private func handlePostLiked(_ notification: Notification) {
        #if DEBUG
        print("❤️ NotificationService: 收到点赞通知")
        #endif
        
        guard let userInfo = notification.userInfo,
              let postId = userInfo["postId"] as? String,
              let authorCharacterId = userInfo["authorCharacterId"] as? String else {
            #if DEBUG
            print("❌ NotificationService: 点赞通知数据无效")
            #endif
            return
        }
        
        #if DEBUG
        print("❤️ NotificationService: 为角色\(authorCharacterId)创建点赞感谢通知")
        #endif
        
        // 延迟生成点赞感谢通知
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
            self.createLikeNotification(
                characterId: authorCharacterId,
                postId: postId
            )
        }
    }
    
    @objc private func handleCharacterInteraction(_ notification: Notification) {
        #if DEBUG
        print("🤝 NotificationService: 收到角色互动通知")
        #endif
        
        guard let userInfo = notification.userInfo,
              let characterId = userInfo["characterId"] as? String else {
            #if DEBUG
            print("❌ NotificationService: 角色互动通知数据无效")
            #endif
            return
        }
        
        // 统计与角色的互动次数
        characterInteractionCount[characterId, default: 0] += 1
        saveInteractionCount()
        
        let currentCount = characterInteractionCount[characterId]!
        #if DEBUG
        print("🤝 NotificationService: 角色\(characterId)互动次数: \(currentCount)")
        #endif
        
        // 达到一定互动次数时生成关注通知
        if currentCount == 3 {
            #if DEBUG
            print("🤝 NotificationService: 角色\(characterId)互动达到3次，将生成关注通知")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 5...10)) {
                self.createFollowNotification(characterId: characterId)
            }
        }
    }
    
    // MARK: - 通知生成器
    
    private func createCommentNotification(characterId: String, content: String, postId: String, userComment: String? = nil, originalPost: String? = nil, originalPostAuthor: String? = nil) {
        guard let character = getCharacterInfo(characterId: characterId) else { return }
        
        #if DEBUG
        print("🔔 创建评论通知:")
        print("   角色: \(character.name)")
        print("   AI回复: \(content.prefix(30))...")
        print("   用户评论: \(userComment?.prefix(30) ?? "无")...")
        print("   用户评论完整内容: '\(userComment ?? "nil")'")
        print("   用户评论是否为nil: \(userComment == nil)")
        print("   用户评论是否为空: \(userComment?.isEmpty ?? true)")
        print("   原帖: \(originalPost?.prefix(42) ?? "无")...")
        print("   原帖作者: \(originalPostAuthor ?? "无")")
        #endif
        #if DEBUG
        print("   原帖内容长度: \(originalPost?.count ?? 0)")
        #endif
        
        let notification = NotificationModel(
            type: .comment,
            avatar: character.image,
            username: character.name,
            content: content,
            time: formatTimeAgo(Date()),
            isOnline: Bool.random(),
            actionText: "评论",
            character: character,
            previewContent: originalPost, // 直接使用完整的 originalPost
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: true,
            userComment: userComment,
            userPost: originalPost, // 确保 userPost 也是完整的
            originalPost: originalPost,
            originalPostAuthor: originalPostAuthor
        )
        
        #if DEBUG
        print("🔔 NotificationModel创建完成:")
        print("   NotificationModel.userComment: '\(notification.userComment ?? "nil")'")
        print("   NotificationModel.originalPost: '\(notification.originalPost ?? "nil")'")
        print("   NotificationModel.originalPostAuthor: '\(notification.originalPostAuthor ?? "nil")'")
        print("   NotificationModel.previewContent: '\(notification.previewContent ?? "nil")'")
        print("   NotificationModel.previewContent长度: \(notification.previewContent?.count ?? 0)")
        print("   是否应该显示用户上下文: \((notification.userComment != nil && !notification.userComment!.isEmpty) || (notification.userPost != nil && !notification.userPost!.isEmpty))")
        print("   是否应该显示原帖信息: \(notification.originalPost != nil && !notification.originalPost!.isEmpty && notification.userComment != nil)")
        #endif
        
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
    
    /**
     * 创建虚拟角色点赞通知（公开方法）
     * @param characterId 角色ID
     * @param characterName 角色名称
     * @param characterAvatar 角色头像
     * @param postId 帖子ID
     * @param postTitle 帖子标题
     * @param userComment 用户评论内容
     */
    func createLikeNotification(
        characterId: String,
        characterName: String,
        characterAvatar: String,
        postId: String,
        postTitle: String,
        userComment: String? = nil
    ) {
        // 获取角色信息
        guard let character = getCharacterInfo(characterId: characterId) else {
            #if DEBUG
            print("❌ 无法获取角色\(characterId)的详细信息")
            #endif
            return
        }
        
        let notification = NotificationModel(
            type: .like,
            avatar: characterAvatar,
            username: characterName,
            content: nil,  // 不显示额外文字，只显示点赞动作
            time: formatTimeAgo(Date()),
            isOnline: Bool.random(),
            actionText: "点赞",
            character: character,
            previewContent: nil,  // 不显示原帖内容，只显示用户评论
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "like",
            isGenerated: true,
            userComment: userComment,  // 保留用户评论，会在userContextView中显示
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        )
        
        addNotification(notification)
        #if DEBUG
        print("📨 创建虚拟角色点赞通知: \(characterName)点赞了您的内容")
        #endif
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
        postTitle: String,
        userComment: String? = nil  // 🔧 添加用户评论参数
    ) {
        #if DEBUG
        print("💬 NotificationService: 直接创建评论通知")
        print("   角色: \(characterName)")
        print("   评论内容: \(commentContent.prefix(30))...")
        print("   用户评论: \(userComment?.prefix(30) ?? "无")...")  // 🔧 添加调试信息
        #endif
        
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
            previewContent: postTitle, // 确保这里也是完整的 postTitle
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: false,
            userComment: userComment,  // 🔧 设置用户评论
            userPost: nil,
            originalPost: nil,
            originalPostAuthor: nil
        )
        
        addNotification(notification)
    }
    
    /**
     * 为用户自己的评论创建通知
     * 这样用户可以在通知中心看到自己发表的评论
     */
    func createUserCommentNotification(
        commentContent: String,
        postId: String,
        postTitle: String
    ) {
        #if DEBUG
        print("👤 NotificationService: 创建用户评论通知")
        print("   评论内容: \(commentContent.prefix(30))...")
        #endif
        
        let notification = NotificationModel(
            type: .comment,
            avatar: "person.circle.fill", // 用户头像
            username: "当前用户",
            content: commentContent,
            time: formatTimeAgo(Date()),
            isOnline: true, // 用户总是在线
            actionText: "评论了",
            character: nil, // 用户不是角色
            previewContent: postTitle, // 确保这里是完整的 postTitle
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "user_comment",
            isGenerated: false,
            userComment: commentContent, // 标记为用户评论
            userPost: nil,
            originalPost: postTitle,
            originalPostAuthor: "当前用户"
        )
        
        addNotification(notification)
    }
    
    /**
     * 为用户回复他人评论创建通知
     */
    func createUserReplyNotification(
        replyContent: String,
        replyToUsername: String,
        postId: String,
        postTitle: String
    ) {
        #if DEBUG
        print("👤 NotificationService: 创建用户回复通知")
        print("   回复内容: \(replyContent.prefix(30))...")
        print("   回复对象: \(replyToUsername)")
        #endif
        
        let notification = NotificationModel(
            type: .comment,
            avatar: "person.circle.fill", // 用户头像
            username: "当前用户",
            content: replyContent,
            time: formatTimeAgo(Date()),
            isOnline: true, // 用户总是在线
            actionText: "回复了 \(replyToUsername)",
            character: nil, // 用户不是角色
            previewContent: postTitle, // 确保这里是完整的 postTitle
            relatedPostId: postId,
            relatedCommentId: nil,
            triggeredByAction: "user_reply",
            isGenerated: false,
            userComment: replyContent, // 标记为用户回复
            userPost: nil,
            originalPost: postTitle,
            originalPostAuthor: "当前用户"
        )
        
        addNotification(notification)
    }
    
    // MARK: - 系统通知生成
    
    func generateSystemWelcomeNotification() {
        let systemCharacters = ["einstein", "shakespeare", "davinci", "curie"]
        let _ = systemCharacters.randomElement()!
        
        let notification = NotificationModel(
            type: .system,
            avatar: "assistant_avatar",
            username: "虫遇小助手",
            content: "开始你的时空对话之旅吧！",
            time: formatTimeAgo(Date()),
            isOnline: false,
            actionText: nil,
            character: NotificationModel.CharacterInfo(
                name: "虫遇小助手",
                era: "现代",
                category: .all,
                image: "assistant_avatar"
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
    
    // 添加更多系统通知的方法
    func generateAdditionalSystemNotifications() {
        #if DEBUG
        print("🔍 NotificationService: 开始生成系统通知，当前通知数量: \(notifications.count)")
        #endif
        
        // 检查是否已经有欢迎通知了
        let hasWelcomeNotification = notifications.contains { $0.type == .system && $0.username == "虫遇小助手" }
        #if DEBUG
        print("🔍 NotificationService: 是否已有欢迎通知: \(hasWelcomeNotification)")
        #endif
        
        if !hasWelcomeNotification {
            // 生成欢迎通知
            generateSystemWelcomeNotification()
            #if DEBUG
            print("✅ NotificationService: 已生成欢迎通知")
            #endif
        }
        
        // 检查是否已经有新手指南通知了
        let hasGuideNotification = notifications.contains { $0.type == .system && $0.username == "功能指南" }
        #if DEBUG
        print("🔍 NotificationService: 是否已有新手指南通知: \(hasGuideNotification)")
        #endif
        
        if !hasGuideNotification {
            // 生成功能指南通知
            let guideNotification = NotificationModel(
                type: .system,
                avatar: "sparkles",
                username: "功能指南",
                content: """
                🌟 欢迎来到虫遇！这里有丰富的功能等你探索：
                
                🕳️ 生成帖子：右滑首帖 → 「探索虫洞深处」 → 「启动虫洞捕捉」。多个角色会发布自己的感悟和朋友圈，分享不同视角的生活体验。
                
                可选方向（一次最多生成12篇）：
                • 虫洞共鸣：不同次元角色围绕你的主题展开对话
                • 日常心情：发布各自时代的真实感受和生活情绪体验
                • 古潮新语：用各自智慧和思想体系分享对现代话题的深度见解
                • 穿越吐槽：各种角色以各自时代视角，对现代事物发表有梗有料的幽默吐槽
                • 时空记事：分享各自时代的重要时刻和亲历历史的真实感受
                
                ⚡ 一键生成：点击主页右侧彩球，让AI为你精心调配四种风味（日常心情、古潮新语、穿越吐槽、时空记事），12篇内容一次满足，比例还能按你喜好调整！
                
                ✍️ 发布动态：点击底部中间的发布按钮，编辑文字/图片，可选择互动角色后发布，角色会根据自己的视角给你点赞和有趣的回复
                
                💬 互动评论：在任何帖子下评论和点赞，角色会以独特视角回复，虚拟角色点赞用于成就系统，你的点赞记录可在空间页面查看
                
                📤 精彩分享：在角色详情页或对话页面使用分享功能，生成精美卡片分享到微信朋友圈，展示你与历史人物的对话瞬间
                
                💫 角色对话：在探索中选择角色进入详情，开始与 TA 一对一对话
                
                🎨 角色调校：在角色详情页点击个性化调节按钮，可调整角色的表达方式、语言风格、情感程度等5个维度，让每个历史人物更符合你的对话偏好
                
                🎭 梦幻联动：在探索页面点击「梦幻联动」，选择主题与参与角色，开启多人对话
                
                🎨 创建角色：在探索页面点击「创建角色」，快速创建新角色开始对话
                
                🏆 成就系统：通过与角色互动、获得虚拟角色点赞等行为解锁各种成就徽章，在空间页面查看你的成就收藏
                
                🎬 次元回放：用AI温柔地解读你与历史人物的互动轨迹，发现你在寻找什么、思考什么、成长什么，看见那个在时空中探索的真实自己
                
                💰 虫洞币充值：虫洞币是所有AI功能的基础货币，包括角色对话、内容生成、智能回复等都需要消耗虫洞币。在空间页面点击右上角钻石图标查看余额并充值，支持四档套餐（6-68元）
                
                现在开始，让思绪如光，穿越时空的边界......
                """,
                time: formatTimeAgo(Date()),
                isOnline: false,
                actionText: nil,
                character: nil, // 系统通知不需要角色信息
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
            
            addNotification(guideNotification)
            #if DEBUG
            print("✅ NotificationService: 已生成功能指南通知")
            #endif
        }
        
        // 检查是否已经有版本更新通知了
        let hasUpdateNotification = notifications.contains { $0.type == .system && $0.username == "版本更新" }
        
        if !hasUpdateNotification {
            // 生成更新通知
            let updateNotification = NotificationModel(
                type: .system,
                avatar: "arrow.up.circle",
                username: "版本更新",
                content: "新增了更多历史人物，快来探索吧！",
                time: formatTimeAgo(Date().addingTimeInterval(-7200)), // 2小时前
                isOnline: false,
                actionText: nil,
                character: nil, // 系统通知不需要角色信息
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
            
            addNotification(updateNotification)
        }
    }
    
    // MARK: - 辅助方法
    
    private func getCharacterEra(_ characterId: String) -> String {
        // 从CharacterSystem中查找角色的era信息
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        if let character = allCharacters.first(where: { $0.id == characterId }) {
            return character.era
        }
        
        // 如果找不到，返回默认值
        return "未知时代"
    }
    
    private func addNotification(_ notification: NotificationModel) {
        // 添加调试输出
        #if DEBUG
        print("🔔 NotificationService: 添加新通知")
        print("   类型: \(notification.type)")
        print("   发送者: \(notification.character?.name ?? "用户")")
        print("   内容: \(notification.content?.prefix(30) ?? "无内容")...")
        print("   当前通知总数: \(notifications.count + 1)")
        #endif
        
        DispatchQueue.main.async {
            // 检查是否存在重复通知 - 使用更严格的去重条件
            let isDuplicate = self.notifications.contains { existingNotification in
                // 对于系统通知，使用username来区分
                if notification.type == .system {
                    return existingNotification.type == .system && 
                           existingNotification.username == notification.username
                }
                
                // 对于其他通知，使用原来的逻辑
                let basicMatch = existingNotification.character?.name == notification.character?.name &&
                       existingNotification.type == notification.type &&
                               existingNotification.relatedPostId == notification.relatedPostId
                
                // 评论通知需要额外检查内容是否相同
                if notification.type == .comment {
                    return basicMatch && existingNotification.content == notification.content
                }
                
                return basicMatch
            }
            
            if isDuplicate {
                #if DEBUG
                print("⚠️ NotificationService: 发现重复通知，跳过添加")
                print("   角色: \(notification.character?.name ?? "未知")")
                print("   类型: \(notification.type)")
                print("   帖子ID: \(notification.relatedPostId ?? "未知")")
                #endif
                return
            }
            
            // 确保在主线程上更新并触发 @Published 通知
            self.objectWillChange.send()
            self.notifications.insert(notification, at: 0)
            self.saveNotifications()
            #if DEBUG
            print("✅ NotificationService: 通知已添加，当前总数: \(self.notifications.count)")
            #endif
        }
    }
    
    private func getCharacterInfo(characterId: String) -> NotificationModel.CharacterInfo? {
        // 🔧 修复：优先从CharacterSystem获取角色信息，包括用户创建的角色
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        // 🔧 修复：使用不区分大小写的比较，因为ID可能有大小写差异
        var character = allCharacters.first(where: { $0.id.lowercased() == characterId.lowercased() })
        
        // 如果CharacterSystem中没有找到，尝试多种方式查找用户创建的角色
        if character == nil {
            // 方法1: 检查是否是custom_开头的ID，从UserDefaults获取
            if characterId.lowercased().hasPrefix("custom_") {
                if let data = UserDefaults.standard.data(forKey: "CustomCharactersData"),
                   let characterDicts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    
                    // 🔧 修复：使用不区分大小写的ID匹配，支持多种ID格式
                    let characterDict = characterDicts.first(where: {
                        let id = ($0["id"] as? String ?? "").lowercased()
                        let targetId = characterId.lowercased()
                        // 支持完全匹配、去掉custom_前缀匹配、添加custom_前缀匹配
                        return id == targetId || 
                               id == targetId.replacingOccurrences(of: "custom_", with: "") ||
                               "custom_\(id)" == targetId
                    })
                    
                    if let characterDict = characterDict,
                       let name = characterDict["name"] as? String,
                       let profession = characterDict["profession"] as? String,
                       let era = characterDict["era"] as? String {
                        
                        // 创建临时的CharacterIdentity对象，保持原始ID的大小写
                        let finalId = (characterDict["id"] as? String ?? characterId).hasPrefix("custom_") ? 
                            (characterDict["id"] as? String ?? characterId) : "custom_\(characterDict["id"] as? String ?? characterId)"
                        
                        // 🔧 修复：对于用户创建的角色，直接使用角色ID作为头像路径，Avatar组件会处理加载
                        // 这样Avatar组件可以使用角色ID从文档目录加载头像
                        let avatarPath = finalId
                        
                        // 🔧 修复：创建CharacterIdentity而不是AppCharacter
                        character = CharacterSystem.CharacterIdentity(
                            id: finalId,
                            name: name,
                            type: .historical, // 用户创建的角色暂时使用historical类型
                            era: era,
                            primaryField: profession,
                            briefDescription: characterDict["bio"] as? String ?? "",
                            avatarName: avatarPath, // 使用角色ID，Avatar组件会处理加载
                            region: "",
                            contentAffinities: [:],
                            subtype: "myCreation"
                        )
                    }
                }
            }
            
            // 方法2: 如果还是没找到，尝试去掉或添加custom_前缀再次查找
            if character == nil {
                let alternativeId: String
                if characterId.lowercased().hasPrefix("custom_") {
                    alternativeId = String(characterId.dropFirst(7)) // 去掉"custom_"
                } else {
                    alternativeId = "custom_\(characterId)"
                }
                
                // 在CharacterSystem中查找
                character = allCharacters.first(where: { $0.id.lowercased() == alternativeId.lowercased() })
                
                // 如果还是没找到，从UserDefaults查找
                if character == nil {
                    if let data = UserDefaults.standard.data(forKey: "CustomCharactersData"),
                       let characterDicts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        
                        let characterDict = characterDicts.first(where: {
                            let id = ($0["id"] as? String ?? "").lowercased()
                            let targetId = alternativeId.lowercased()
                            return id == targetId || 
                                   id == targetId.replacingOccurrences(of: "custom_", with: "") ||
                                   "custom_\(id)" == targetId
                        })
                        
                        if let characterDict = characterDict,
                           let name = characterDict["name"] as? String,
                           let profession = characterDict["profession"] as? String,
                           let era = characterDict["era"] as? String {
                            
                            let finalId = (characterDict["id"] as? String ?? alternativeId).hasPrefix("custom_") ? 
                                (characterDict["id"] as? String ?? alternativeId) : "custom_\(characterDict["id"] as? String ?? alternativeId)"
                            
                            // 🔧 修复：对于用户创建的角色，直接使用角色ID作为头像路径
                            let avatarPath = finalId
                            
                            character = CharacterSystem.CharacterIdentity(
                                id: finalId,
                                name: name,
                                type: .historical,
                                era: era,
                                primaryField: profession,
                                briefDescription: characterDict["bio"] as? String ?? "",
                                avatarName: avatarPath,
                                region: "",
                                contentAffinities: [:],
                                subtype: "myCreation"
                            )
                        }
                    }
                }
            }
        }
        
        guard let character = character else {
            #if DEBUG
            print("⚠️ NotificationService: 未找到角色ID: \(characterId)")
            #endif
            return nil
        }
        
        // 根据角色类型映射到通知类别
        let category: CharacterCategory = {
            // 用户创建的角色
            if character.id.hasPrefix("custom_") || character.subtype == "myCreation" {
                return .myCreation
            }
            
            switch character.type {
            case .historical:
                // 根据领域进一步分类
                if character.primaryField.contains("科学") || character.primaryField.contains("物理") || character.primaryField.contains("数学") ||
                   character.primaryField.contains("艺术") || character.primaryField.contains("画") {
                    // 科学家和艺术家合并到历史人物
                    return .historical
                } else if character.primaryField.contains("诗") || character.primaryField.contains("文学") || character.primaryField.contains("作家") {
                    return .writer
                } else {
                    return .historical
                }
            case .literary:
                return .writer
            case .movie, .tv:
                return .filmCharacter
            case .anime, .game, .scifi, .fantasy:
                return .animeCharacter
            case .mythological:
                return .mythCharacter
            default:
                return .historical
            }
        }()
        
        // 🔧 修复：对于用户创建的角色，直接使用角色ID作为头像路径，Avatar组件会处理加载
        // 对于预设角色，使用CharacterAvatarService获取头像路径
        let avatarPath: String
        if character.id.hasPrefix("custom_") || character.subtype == "myCreation" {
            // 用户创建的角色：直接使用角色ID，Avatar组件会从文档目录加载
            avatarPath = character.id
        } else {
            // 预设角色：使用CharacterAvatarService获取头像路径
            avatarPath = CharacterAvatarService.shared.getAvatarName(for: character.id)
        }
        
        return NotificationModel.CharacterInfo(
            name: character.name,
            era: character.era,
            category: category,
            image: avatarPath
        )
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - 数据持久化
    
    // 清理重复的通知
    func cleanupDuplicateNotifications() {
        var cleanedNotifications: [NotificationModel] = []
        
        for notification in notifications {
            let isDuplicate = cleanedNotifications.contains { existingNotification in
                // 对于系统通知，使用username来区分
                if notification.type == .system {
                    return existingNotification.type == .system && 
                           existingNotification.username == notification.username
                }
                
                // 对于其他通知，使用原来的逻辑
                let basicMatch = existingNotification.character?.name == notification.character?.name &&
                               existingNotification.type == notification.type &&
                               existingNotification.relatedPostId == notification.relatedPostId
                
                if notification.type == .comment {
                    return basicMatch && existingNotification.content == notification.content
                }
                
                return basicMatch
            }
            
            if !isDuplicate {
                cleanedNotifications.append(notification)
            } else {
                #if DEBUG
                print("🗑️ 清理重复通知: \(notification.character?.name ?? "未知") - \(notification.type)")
                #endif
            }
        }
        
        if cleanedNotifications.count != notifications.count {
            #if DEBUG
            print("🧹 清理完成，从 \(notifications.count) 条通知减少到 \(cleanedNotifications.count) 条")
            #endif
            notifications = cleanedNotifications
            saveNotifications()
        }
    }
    
    private func saveNotifications() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(notifications)
            UserDefaults.standard.set(data, forKey: notificationsKey)
        } catch {
            Logger.error("保存通知失败", error: error, log: Logger.data)
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
            #if DEBUG
            print("📂 加载了 \(notifications.count) 条本地通知")
            #endif
            
            // 🔧 修复：加载后修复角色信息（如果角色名称是角色ID格式）
            fixCharacterInfoInNotifications()
            
            // 加载后清理重复通知
            cleanupDuplicateNotifications()
        } catch {
            Logger.error("加载通知失败", error: error, log: Logger.data)
            notifications = []
        }
    }
    
    // 🔧 修复：修复通知中的角色信息
    private func fixCharacterInfoInNotifications() {
        var hasChanges = false
        
        for index in notifications.indices {
            let notification = notifications[index]
            
            // 检查角色名称是否是角色ID格式（custom_开头或看起来像ID）
            let characterName = notification.character?.name ?? notification.username
            // 🔧 增强检测：更准确地识别角色ID格式
            let isCharacterId = characterName.lowercased().hasPrefix("custom_") || 
                               characterName.lowercased().hasPrefix("user_avatar_") ||
                               (characterName.count > 8 && characterName.uppercased().contains("CUSTOM")) ||
                               (characterName.matches(pattern: "^custom_[A-F0-9]{8,}$"))
            
            if isCharacterId {
                // 尝试重新获取角色信息
                if let fixedCharacter = getCharacterInfo(characterId: characterName) {
                    // 更新通知的角色信息
                    // 如果username也是角色ID，更新为正确的名称
                    if notification.username == characterName || notification.username.lowercased().hasPrefix("custom_") {
                        // 注意：NotificationModel是struct，需要重新创建
                        notifications[index] = NotificationModel(
                            id: notification.id,
                            type: notification.type,
                            avatar: fixedCharacter.image,
                            username: fixedCharacter.name,
                            content: notification.content,
                            time: notification.time,
                            createdAt: notification.createdAt,
                            isOnline: notification.isOnline,
                            actionText: notification.actionText,
                            character: fixedCharacter,
                            previewContent: notification.previewContent,
                            relatedPostId: notification.relatedPostId,
                            relatedCommentId: notification.relatedCommentId,
                            triggeredByAction: notification.triggeredByAction,
                            isGenerated: notification.isGenerated,
                            userComment: notification.userComment,
                            userPost: notification.userPost,
                            originalPost: notification.originalPost,
                            originalPostAuthor: notification.originalPostAuthor
                        )
                        hasChanges = true
                        #if DEBUG
                        print("🔧 修复通知角色信息: \(characterName) -> \(fixedCharacter.name)")
                        #endif
                    } else {
                        // 只更新character字段和avatar字段
                        notifications[index] = NotificationModel(
                            id: notification.id,
                            type: notification.type,
                            avatar: fixedCharacter.image,
                            username: notification.username,
                            content: notification.content,
                            time: notification.time,
                            createdAt: notification.createdAt,
                            isOnline: notification.isOnline,
                            actionText: notification.actionText,
                            character: fixedCharacter,
                            previewContent: notification.previewContent,
                            relatedPostId: notification.relatedPostId,
                            relatedCommentId: notification.relatedCommentId,
                            triggeredByAction: notification.triggeredByAction,
                            isGenerated: notification.isGenerated,
                            userComment: notification.userComment,
                            userPost: notification.userPost,
                            originalPost: notification.originalPost,
                            originalPostAuthor: notification.originalPostAuthor
                        )
                        hasChanges = true
                        #if DEBUG
                        print("🔧 修复通知角色信息（仅character）: \(characterName) -> \(fixedCharacter.name)")
                        #endif
                    }
                } else {
                    #if DEBUG
                    print("⚠️ 无法获取角色信息: \(characterName)")
                    #endif
                }
            }
        }
        
        if hasChanges {
            saveNotifications()
            #if DEBUG
            print("✅ 已修复通知中的角色信息")
            #endif
        }
    }
    
    private func saveInteractionCount() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(characterInteractionCount)
            UserDefaults.standard.set(data, forKey: interactionCountKey)
        } catch {
            Logger.error("保存互动统计失败", error: error, log: Logger.data)
        }
    }
    
    private func loadInteractionCount() {
        guard let data = UserDefaults.standard.data(forKey: interactionCountKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            characterInteractionCount = try decoder.decode([String: Int].self, from: data)
        } catch {
            Logger.error("加载互动统计失败", error: error, log: Logger.data)
        }
    }
    
    // MARK: - 公共接口
    
    /**
     * 清除所有通知（重装应用效果）
     */
    func clearAllNotifications() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.notifications.removeAll()
            self.saveNotifications()
            #if DEBUG
            print("🗑️ 已清空所有通知")
            #endif
        }
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
    
    // MARK: - 公共方法
    
    // 手动清理重复通知
    func manualCleanupDuplicates() {
        DispatchQueue.main.async {
            self.cleanupDuplicateNotifications()
        }
    }
    
    // 清除所有通知并重新生成系统通知
    func resetSystemNotifications() {
        DispatchQueue.main.async {
            #if DEBUG
            print("🔄 重置系统通知...")
            #endif
            // 清除所有通知
            self.notifications.removeAll()
            self.saveNotifications()
            
            // 重新生成系统通知
            self.generateAdditionalSystemNotifications()
            #if DEBUG
            print("✅ 系统通知重置完成，当前通知数量: \(self.notifications.count)")
            #endif
        }
    }
    
    // 修复系统通知内容
    func fixSystemNotificationContent() {
        DispatchQueue.main.async {
            #if DEBUG
            print("🔧 修复系统通知内容...")
            #endif
            
            // 找到虫遇小助手通知并修复内容
            for i in 0..<self.notifications.count {
                if self.notifications[i].type == .system && self.notifications[i].username == "虫遇小助手" {
                    // 创建正确的虫遇小助手通知
                    let correctedNotification = NotificationModel(
                        type: .system,
                        avatar: "assistant_avatar",
                        username: "虫遇小助手",
                        content: "开始你的时空对话之旅吧！",
                        time: self.formatTimeAgo(Date()),
                        isOnline: false,
                        actionText: nil,
                        character: NotificationModel.CharacterInfo(
                            name: "虫遇小助手",
                            era: "现代",
                            category: .all,
                            image: "assistant_avatar"
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
                    
                    self.notifications[i] = correctedNotification
                    #if DEBUG
                    print("✅ 已修复虫遇小助手通知内容")
                    #endif
                    break
                }
            }
            
            // 找到功能指南通知并修复内容
            for i in 0..<self.notifications.count {
                if self.notifications[i].type == .system && self.notifications[i].username == "功能指南" {
                    let correctedGuide = NotificationModel(
                        type: .system,
                        avatar: "sparkles",
                        username: "功能指南",
                        content: """
                🌟 欢迎来到虫遇！这里有丰富的功能等你探索：
                
                🕳️ 生成帖子：右滑首帖 → 「探索虫洞深处」 → 「启动虫洞捕捉」。多个角色会发布自己的感悟和朋友圈，分享不同视角的生活体验。
                
                可选方向（一次最多生成12篇）：
                • 虫洞共鸣：不同次元角色围绕你的主题展开对话
                • 日常心情：发布各自时代的真实感受和生活情绪体验
                • 古潮新语：用各自智慧和思想体系分享对现代话题的深度见解
                • 穿越吐槽：各种角色以各自时代视角，对现代事物发表有梗有料的幽默吐槽
                • 时空记事：分享各自时代的重要时刻和亲历历史的真实感受
                
                ⚡ 一键生成：点击主页右侧彩球，让AI为你精心调配四种风味（日常心情、古潮新语、穿越吐槽、时空记事），12篇内容一次满足，比例还能按你喜好调整！
                
                ✍️ 发布动态：点击底部中间的发布按钮，编辑文字/图片，可选择互动角色后发布，角色会根据自己的视角给你点赞和有趣的回复
                
                💬 互动评论：在任何帖子下评论和点赞，角色会以独特视角回复，虚拟角色点赞用于成就系统，你的点赞记录可在空间页面查看
                
                📤 精彩分享：在角色详情页或对话页面使用分享功能，生成精美卡片分享到微信朋友圈，展示你与历史人物的对话瞬间
                
                💫 角色对话：在探索中选择角色进入详情，开始与 TA 一对一对话
                
                🎨 角色调校：在角色详情页点击个性化调节按钮，可调整角色的表达方式、语言风格、情感程度等5个维度，让每个历史人物更符合你的对话偏好
                
                🎭 梦幻联动：在探索页面点击「梦幻联动」，选择主题与参与角色，开启多人对话
                
                🎨 创建角色：在探索页面点击「创建角色」，快速创建新角色开始对话
                
                🏆 成就系统：通过与角色互动、获得虚拟角色点赞等行为解锁各种成就徽章，在空间页面查看你的成就收藏
                
                🎬 次元回放：用AI温柔地解读你与历史人物的互动轨迹，发现你在寻找什么、思考什么、成长什么，看见那个在时空中探索的真实自己
                
                💰 虫洞币充值：虫洞币是所有AI功能的基础货币，包括角色对话、内容生成、智能回复等都需要消耗虫洞币。在空间页面点击右上角钻石图标查看余额并充值，支持四档套餐（6-68元）
                
                现在开始，让思绪如光，穿越时空的边界......
                """,
                        time: self.formatTimeAgo(Date()),
                        isOnline: false,
                        actionText: nil,
                        character: nil,
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
                    
                    self.notifications[i] = correctedGuide
                    #if DEBUG
                    print("✅ 已修复功能指南通知内容")
                    #endif
                    break
                }
            }
            
            self.saveNotifications()
            #if DEBUG
            print("✅ 系统通知内容修复完成")
            #endif
        }
    }
}

// MARK: - 通知模型已在NotificationModel.swift中定义Codable扩展 