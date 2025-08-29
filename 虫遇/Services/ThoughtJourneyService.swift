import Foundation
import SwiftData
import Combine

/**
 * 虫遇回忆服务
 * 基于现有数据生成用户的次元相遇回忆录
 */
class ThoughtJourneyService: ObservableObject {
    static let shared = ThoughtJourneyService()
    
    @Published var isGenerating = false
    @Published var currentReport: ThoughtJourneyReport?
    @Published var errorMessage: String?
    
    private let aiNetworkService = AINetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /**
     * 生成虫遇回忆报告
     */
    func generateReport(timeRange: TimeRange, modelContext: ModelContext) {
        isGenerating = true
        errorMessage = nil
        
        // 1. 收集用户数据
        let (userData, allChatMessages) = collectUserData(timeRange: timeRange, modelContext: modelContext)
        
        // 2. 构建AI提示词
        let prompt = buildPrompt(userData: userData, timeRange: timeRange, allChatMessages: allChatMessages)
        
        // 3. 调用AI
        aiNetworkService.sendRequest(prompt: prompt)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isGenerating = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "生成失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    self?.parseAndSaveReport(response: response, userData: userData)
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 收集用户数据
     */
    private func collectUserData(timeRange: TimeRange, modelContext: ModelContext) -> (UserDataDigest, [ChatContextItem]) {
        let startDate = timeRange.startDate
        let endDate = timeRange.endDate
        
        // 收集用户帖子（需要排除虚拟角色发布的帖子）
        let allCharacterNames = CharacterDataManager.shared.getAllCharactersInfo().map { $0.name }
        let userPosts = PostViewModel.shared.posts.filter { post in
            // 时间过滤
            let isInTimeRange = post.datePosted >= startDate && post.datePosted <= endDate
            // 排除虚拟角色的帖子 - 通过username判断
            let isUserPost = !allCharacterNames.contains(post.username) && post.username != "AI助手"
            return isInTimeRange && isUserPost
        }
        
        // 收集用户评论（从所有帖子中筛选用户的评论）
        let allPosts = PostViewModel.shared.posts
        let userCommentsWithPosts: [(comment: DetailedCommentModel, post: UserPostModel)] = allPosts.flatMap { post in
            post.comments.filter { comment in
                // 时间过滤
                let isInTimeRange = comment.datePosted >= startDate && comment.datePosted <= endDate
                // 只要是用户的评论：非虚拟角色 且 (标记为当前用户 或 用户名为"当前用户")
                let isUserComment = !comment.isVirtualCharacter && 
                                  (comment.isCurrentUser || comment.username == "当前用户")
                return isInTimeRange && isUserComment
            }.map { comment in
                (comment: comment, post: post)
            }
        }
        
        // 收集聊天对话（包括一对一聊天和多人聊天）
        var allMultiChatMessages: [MultiPersonChatMessage] = []
        var userMultiChatMessages: [MultiPersonChatMessage] = []
        var allOneOnOneMessages: [Message] = []
        var userOneOnOneMessages: [Message] = []
        
        // 1. 收集多人聊天消息
        do {
            let multiChatPredicate = #Predicate<MultiPersonChatMessage> { message in
                message.timestamp >= startDate && 
                message.timestamp <= endDate
            }
            let multiChatDescriptor = FetchDescriptor<MultiPersonChatMessage>(
                predicate: multiChatPredicate,
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            allMultiChatMessages = try modelContext.fetch(multiChatDescriptor)
            
            // 详细调试每条多人聊天消息
            print("🔍 多人聊天消息详情:")
            for (index, message) in allMultiChatMessages.enumerated() {
                print("  消息\(index): characterId=\(message.characterId), characterName=\(message.characterName), isUserMessage=\(message.isUserMessage), content=\(message.content.prefix(20))...")
            }
            
            userMultiChatMessages = allMultiChatMessages.filter { $0.isUserMessage }
            
            print("✅ 多人聊天消息: 总计\(allMultiChatMessages.count)条, 用户消息\(userMultiChatMessages.count)条")
        } catch {
            print("❌ 获取多人聊天消息失败: \(error)")
        }
        
        // 2. 收集一对一聊天消息  
        do {
            let oneOnOnePredicate = #Predicate<Message> { message in
                message.timestamp >= startDate && 
                message.timestamp <= endDate
            }
            let oneOnOneDescriptor = FetchDescriptor<Message>(
                predicate: oneOnOnePredicate,
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            allOneOnOneMessages = try modelContext.fetch(oneOnOneDescriptor)
            userOneOnOneMessages = allOneOnOneMessages.filter { $0.isFromUser }
            
            print("✅ 一对一聊天消息: 总计\(allOneOnOneMessages.count)条, 用户消息\(userOneOnOneMessages.count)条")
        } catch {
            print("❌ 获取一对一聊天消息失败: \(error)")
        }
        
        // 收集通知事件
        let notifications = NotificationService.shared.notifications.filter { notification in
            notification.createdAt >= startDate && notification.createdAt <= endDate
        }
        
        // 合并所有聊天数据
        let totalUserChatMessages = userMultiChatMessages.count + userOneOnOneMessages.count
        let totalChatMessages = allMultiChatMessages.count + allOneOnOneMessages.count
        
        // 调试信息
        print("📊 数据收集完成:")
        print("  - 用户帖子: \(userPosts.count)篇")
        print("  - 用户评论: \(userCommentsWithPosts.count)条") 
        print("  - 用户聊天消息: \(totalUserChatMessages)条")
        print("  - 聊天对话总数: \(totalChatMessages)条")
        print("  - 通知事件: \(notifications.count)个")
        print("  - 多人聊天详情: 总计\(allMultiChatMessages.count)条, 用户\(userMultiChatMessages.count)条")
        print("  - 一对一聊天详情: 总计\(allOneOnOneMessages.count)条, 用户\(userOneOnOneMessages.count)条")
        
        // 打印多人聊天的会话ID
        let multiChatSessions = Set(allMultiChatMessages.map { $0.sessionId })
        print("  - 多人聊天会话ID: \(Array(multiChatSessions))")
        
        // 打印一对一聊天的conversationId
        let oneOnOneSessions = Set(allOneOnOneMessages.map { $0.conversationId })
        print("  - 一对一聊天会话ID: \(Array(oneOnOneSessions))")
        
        let userDataDigest = UserDataDigest(
            timeRange: timeRange,
            posts: userPosts.map { post in
                // 计算用户收到的点赞数（来自通知）
                let receivedLikes = notifications.filter { 
                    $0.type == .like && $0.relatedPostId == post.id.uuidString 
                }.count
                
                // 找出回复此帖子的角色
                let characterReplies = post.comments.compactMap { comment in
                    comment.isVirtualCharacter ? comment.username : nil
                }
                
                return UserDataDigest.PostData(
                    id: post.id.uuidString,
                    content: post.content,
                    date: post.datePosted,
                    likes: post.likes,
                    characterId: post.characterID,
                    imagesCount: post.images.count,
                    receivedLikes: receivedLikes,
                    characterReplies: Array(Set(characterReplies)) // 去重
                )
            },
            comments: userCommentsWithPosts.map { item in
                let comment = item.comment
                let targetPost = item.post
                
                // 找到回复此评论的角色
                let repliedCharacters = allPosts.flatMap { post in
                    post.comments.filter { $0.parentCommentId == comment.id && $0.isVirtualCharacter }
                        .map { $0.username }
                }
                
                return UserDataDigest.CommentData(
                    id: comment.id.uuidString,
                    content: comment.content,
                    date: comment.datePosted,
                    likes: comment.likes,
                    targetPostId: targetPost.id.uuidString,
                    targetPostContent: String(targetPost.content.prefix(50)),
                    targetPostAuthor: targetPost.username,
                    repliedCharacters: Array(Set(repliedCharacters))
                )
            },
            chats: {
                var allChats: [UserDataDigest.ChatData] = []
                
                // 处理多人聊天数据：区分有用户参与和无用户参与的情况
                let multiChatSessions = Dictionary(grouping: allMultiChatMessages) { $0.sessionId }
                
                for (sessionId, sessionMessages) in multiChatSessions {
                    let sessionUserMessages = sessionMessages.filter { $0.isUserMessage }
                    let sessionTheme = getSessionTheme(for: sessionId, using: modelContext)
                    
                    if sessionUserMessages.isEmpty {
                        // 情况1：用户只是观察者，创建一个观察记录
                        let participantNames = Array(Set(sessionMessages.map { $0.characterName }))
                        let observationContent = "观看了\(participantNames.joined(separator: "、"))的讨论"
                        
                        allChats.append(UserDataDigest.ChatData(
                            id: "observation_\(sessionId)",
                            content: observationContent,
                            date: sessionMessages.map { $0.timestamp }.min() ?? Date(),
                            characterId: "user_observer",
                            characterName: "观察者",
                            sessionId: sessionId,
                            sessionTheme: sessionTheme,
                            conversationContext: []
                        ))
                    } else {
                        // 情况2：用户有参与，添加用户消息
                        allChats += sessionUserMessages.map { message in
                            // 获取完整对话上下文
                            let contextMessages = sessionMessages.sorted { $0.timestamp < $1.timestamp }
                            let conversationContext = contextMessages.map { msg in
                                "\(msg.isUserMessage ? "你" : msg.characterName): \(msg.content)"
                            }
                            
                            return UserDataDigest.ChatData(
                                id: message.id,
                                content: message.content,
                                date: message.timestamp,
                                characterId: message.characterId,
                                characterName: message.characterName,
                                sessionId: message.sessionId,
                                sessionTheme: sessionTheme,
                                conversationContext: conversationContext
                            )
                        }
                    }
                }
                
                // 添加一对一聊天数据
                allChats += userOneOnOneMessages.map { message in
                    // 从conversationId获取角色信息
                    let characterName = getCharacterNameFromMessage(message)
                    
                    // 获取对话上下文（前后几条消息）
                    let contextMessages = allOneOnOneMessages.filter { $0.conversationId == message.conversationId }
                        .sorted { $0.timestamp < $1.timestamp }
                    
                    let messageIndex = contextMessages.firstIndex { $0.id == message.id } ?? 0
                    let contextRange = max(0, messageIndex - 2)...min(contextMessages.count - 1, messageIndex + 2)
                    let conversationContext = contextRange.compactMap { index in
                        let msg = contextMessages[index]
                        return "\(msg.isFromUser ? "你" : characterName): \(msg.content)"
                    }
                    
                    return UserDataDigest.ChatData(
                        id: message.id,
                        content: message.content,
                        date: message.timestamp,
                        characterId: message.receiverId, // 接收者就是角色
                        characterName: characterName,
                        sessionId: "private_\(message.conversationId)", // 为一对一聊天创建唯一会话ID
                        sessionTheme: nil,
                        conversationContext: conversationContext
                    )
                }
                
                // 按时间排序
                return allChats.sorted { $0.date < $1.date }
            }(),
            events: notifications.map { notification in
                UserDataDigest.EventData(
                    type: "\(notification.type)",
                    date: notification.createdAt,
                    userComment: notification.userComment,
                    originalPost: notification.originalPost
                )
            }
        )
        
        // 合并所有聊天消息用于上下文分析
        let allChatMessages = combineAllChatMessages(
            multiChatMessages: allMultiChatMessages,
            oneOnOneMessages: allOneOnOneMessages
        )
        
        return (userDataDigest, allChatMessages)
    }
    
    /**
     * 构建AI提示词 - 虫遇回忆版本
     */
    private func buildPrompt(userData: UserDataDigest, timeRange: TimeRange, allChatMessages: [ChatContextItem]) -> String {
        let topCharacters = Array(Set(userData.chats.map { $0.characterName })).prefix(3)
        
        // 构建对话上下文 - 按会话分组显示完整对话
        _ = buildChatContexts(allChatMessages: allChatMessages, userChats: userData.chats)
        
        // 统计不同类型的对话
        let normalChats = userData.chats.filter { $0.characterId != "user_observer" }
        let observedChats = userData.chats.filter { $0.characterId == "user_observer" }
        
        // 构建角色关系描述
        let characterRelationships = buildCharacterRelationships(normalChats: normalChats, topCharacters: topCharacters)
        
        // 构建情感体验数据
        let emotionalExperiences = buildEmotionalExperiences(userData: userData, normalChats: normalChats, observedChats: observedChats)
        
        return """
        写一份用户的虫遇回忆，参考网易云年度总结的风格。
        
        用户过去\(timeRange.description)的数据：
        - \(emotionalExperiences)
        - 主要聊天角色：\(characterRelationships)
        
        【用户发布的动态】
        \(userData.posts.map { post in
            var postInfo = "• [\(formatDate(post.date))] \(post.content)"
            if post.receivedLikes > 0 {
                postInfo += "（收到\(post.receivedLikes)个赞）"
            }
            if !post.characterReplies.isEmpty {
                postInfo += "（\(post.characterReplies.joined(separator: "、"))回复了）"
            }
            return postInfo
        }.joined(separator: "\n"))
        
        【用户发表的评论】
        \(userData.comments.map { comment in
            var commentInfo = "• [\(formatDate(comment.date))] \(comment.content)"
            if let targetAuthor = comment.targetPostAuthor, let targetContent = comment.targetPostContent {
                commentInfo += "（回复\(targetAuthor)的动态：\(String(targetContent.prefix(30)))...）"
            }
            if !comment.repliedCharacters.isEmpty {
                commentInfo += "（\(comment.repliedCharacters.joined(separator: "、"))回复了此评论）"
            }
            return commentInfo
        }.joined(separator: "\n"))
        
        【具体对话内容】
        \(buildDetailedChatContexts(userData: userData, allChatMessages: allChatMessages))
        
                 要求：
         1. 用简单直白的话，不要文艺腔
         2. 重点说用户做了什么，和哪个角色发生了什么有趣的事
         3. 从对话中挑选最有意思或最能代表用户性格的瞬间
         4. 语调轻松自然，像朋友在聊天
         5. 让用户看完觉得"哈哈，确实是我"
         6. 不要编造时间，不要说"周一、周二"等具体时间
         7. 严格禁用所有科技词汇：二进制、量子、算法、数据流、虚拟现实、加密、解码、程序、代码、系统等
         8. 绝对禁止编造对话：不能写"你回他xxx"、"你说xxx"等用户没有实际说过的话
         
         参考格式：
         - "这\(timeRange.description)你..."
         - "最有意思的是..."
         - "还记得你和XX..."
         - "看来你..."
         
         重点：
         - 用户要能看懂，要有记忆感，不要过度包装
         - 只写用户真实做过的事，绝对不能编造用户没说过的话
         - 直接引用对话内容，不要加自己的理解
         - 如果用户没有回复某个话题，就不要写用户回复了什么
         - 严格按照提供的对话记录，不能添加任何虚构内容
        """
    }
    
    /**
     * 构建聊天对话上下文
     */
    private func buildChatContexts(allChatMessages: [ChatContextItem], userChats: [UserDataDigest.ChatData]) -> String {
        // 按会话ID分组
        let sessionGroups = Dictionary(grouping: allChatMessages) { $0.sessionId }
        
        var contexts: [String] = []
        
        for (_, messages) in sessionGroups {
            // 只显示包含用户消息的会话
            let hasUserMessage = messages.contains { $0.isUserMessage }
            guard hasUserMessage else { continue }
            
            // 按时间排序
            let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
            
            // 构建对话片段（限制长度避免prompt过长）
            let messageTexts = sortedMessages.prefix(10).map { message in
                let speaker = message.isUserMessage ? "你" : message.characterName
                return "\(speaker)：\(message.content)"
            }
            
            if !messageTexts.isEmpty {
                contexts.append("【对话片段】\n\(messageTexts.joined(separator: "\n"))")
            }
        }
        
        return contexts.isEmpty ? "无对话记录" : contexts.joined(separator: "\n\n")
    }
    
    /**
     * 获取一对一消息的角色名称
     */
    private func getCharacterNameFromMessage(_ message: Message) -> String {
        // 尝试通过receiverId获取角色名称
        let characterName = CharacterDataManager.shared.getName(for: message.receiverId) ?? message.receiverId
        return characterName
    }
    
    /**
     * 合并所有聊天消息（用于上下文分析）
     * 注意：这里不创建SwiftData对象，而是使用数据结构来避免ID冲突
     */
    private func combineAllChatMessages(
        multiChatMessages: [MultiPersonChatMessage],
        oneOnOneMessages: [Message]
    ) -> [ChatContextItem] {
        var combined: [ChatContextItem] = []
        
        // 转换多人聊天消息为上下文项
        for message in multiChatMessages {
            combined.append(ChatContextItem(
                sessionId: message.sessionId,
                characterId: message.characterId,
                characterName: message.characterName,
                content: message.content,
                timestamp: message.timestamp,
                isUserMessage: message.isUserMessage,
                messageType: message.messageType
            ))
        }
        
        // 转换一对一聊天消息为上下文项
        for message in oneOnOneMessages {
            let characterName = getCharacterNameFromMessage(message)
            combined.append(ChatContextItem(
                sessionId: message.conversationId,
                characterId: message.isFromUser ? "user" : message.receiverId,
                characterName: message.isFromUser ? "用户" : characterName,
                content: message.content,
                timestamp: message.timestamp,
                isUserMessage: message.isFromUser,
                messageType: "text"
            ))
        }
        
        // 按时间排序
        return combined.sorted { $0.timestamp < $1.timestamp }
    }
    
    /**
     * 安全获取会话主题
     */
    private func getSessionTheme(for sessionId: String, using modelContext: ModelContext) -> String? {
        do {
            let sessions = try modelContext.fetch(FetchDescriptor<MultiPersonChatSession>())
            let session = sessions.first { $0.id == sessionId }
            guard let session = session else { return nil }
            return !session.chatTheme.isEmpty ? session.chatTheme : session.topic
        } catch {
            print("❌ 获取会话主题失败: \(error)")
            return nil
        }
    }
    
    /**
     * 格式化日期
     */
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
    
    /**
     * 构建详细的聊天上下文
     */
    private func buildDetailedChatContexts(userData: UserDataDigest, allChatMessages: [ChatContextItem]) -> String {
        print("🔍 构建详细聊天上下文:")
        print("  - userData.chats数量: \(userData.chats.count)")
        print("  - allChatMessages数量: \(allChatMessages.count)")
        
        if userData.chats.isEmpty {
            print("  - 结果: 无对话记录")
            return "无对话记录"
        }
        
        // 打印所有用户聊天数据
        for (index, chat) in userData.chats.enumerated() {
            print("  - 用户聊天\(index): sessionId=\(chat.sessionId ?? "nil"), characterName=\(chat.characterName), content=\(chat.content.prefix(20))...")
        }
        
        // 按会话ID分组
        let sessionGroups = Dictionary(grouping: userData.chats) { chat in
            // 确保每个对话都有唯一的分组标识
            if let sessionId = chat.sessionId {
                return sessionId
            } else {
                // 为一对一聊天创建唯一标识
                return "private_\(chat.characterId)_\(chat.id)"
            }
        }
        
        print("  - 分组后的会话数: \(sessionGroups.count)")
        for (_, chats) in sessionGroups {
            print("    * 会话: \(chats.count)条消息")
        }
        
        var contextStrings: [String] = []
        
        for (_, chats) in sessionGroups {
            if let firstChat = chats.first {
                var sessionInfo = ""
                
                // 判断是否为观察者记录
                if firstChat.characterId == "user_observer" {
                    // 观察者记录：显示主题和参与角色
                    if let sessionTheme = firstChat.sessionTheme, !sessionTheme.isEmpty {
                        sessionInfo += "【梦幻联动：\(sessionTheme)】\n"
                    } else {
                        sessionInfo += "【梦幻联动讨论】\n"
                    }
                    sessionInfo += "[\(formatDate(firstChat.date))] \(firstChat.content)\n\n"
                } else {
                    // 正常的用户参与记录
                    if let sessionTheme = firstChat.sessionTheme, !sessionTheme.isEmpty {
                        sessionInfo += "【梦幻联动：\(sessionTheme)】\n"
                    } else if firstChat.sessionId?.hasPrefix("private_") == true {
                        sessionInfo += "【与\(firstChat.characterName)的私聊】\n"
                    } else {
                        sessionInfo += "【与\(firstChat.characterName)的对话】\n"
                    }
                    
                    // 构建完整的对话上下文
                    let fullConversation = buildFullConversationContext(
                        for: firstChat.sessionId ?? "unknown", 
                        characterName: firstChat.characterName,
                        allChatMessages: allChatMessages,
                        userChats: chats
                    )
                    
                    sessionInfo += fullConversation
                }
                
                contextStrings.append(sessionInfo)
            }
        }
        
        return contextStrings.joined(separator: "\n")
    }
    
    /**
     * 构建完整的对话上下文
     */
    private func buildFullConversationContext(
        for sessionId: String, 
        characterName: String,
        allChatMessages: [ChatContextItem],
        userChats: [UserDataDigest.ChatData]
    ) -> String {
        print("    🔍 构建会话\(sessionId)的完整上下文:")
        print("      - 角色: \(characterName)")
        print("      - allChatMessages总数: \(allChatMessages.count)")
        
        // 获取该会话的所有消息（包括用户和角色的）
        let sessionMessages: [ChatContextItem]
        
        if sessionId.hasPrefix("private_") {
            // 一对一聊天：按conversationId匹配
            let conversationId = sessionId.replacingOccurrences(of: "private_", with: "")
            print("      - 一对一聊天，匹配conversationId: \(conversationId)")
            sessionMessages = allChatMessages.filter { $0.sessionId == conversationId }
        } else {
            // 多人聊天：按sessionId匹配
            print("      - 多人聊天，匹配sessionId: \(sessionId)")
            sessionMessages = allChatMessages.filter { $0.sessionId == sessionId }
        }
        
        print("      - 找到该会话的消息数: \(sessionMessages.count)")
        
        // 按时间排序
        let sortedMessages = sessionMessages.sorted { $0.timestamp < $1.timestamp }
        
        if sortedMessages.isEmpty {
            return "暂无对话记录\n"
        }
        
        var result = ""
        
        // 显示最近的对话（最多显示10条消息）
        let recentMessages = Array(sortedMessages.suffix(10))
        for message in recentMessages {
            let speaker = message.isUserMessage ? "你" : message.characterName
            result += "[\(formatDate(message.timestamp))] \(speaker)：\(message.content)\n"
        }
        
        return result + "\n"
    }
    
    /**
     * 解析并保存报告
     */
    private func parseAndSaveReport(response: String, userData: UserDataDigest) {
        let report = ThoughtJourneyReport(
            id: UUID(),
            timeRange: userData.timeRange,
            generatedAt: Date(),
            content: response,
            stats: ThoughtJourneyReport.Stats(
                postsCount: userData.posts.count,
                commentsCount: userData.comments.count,
                chatsCount: userData.chats.count,
                charactersCount: Set(userData.chats.map { $0.characterName }).count
            )
        )
        
        currentReport = report
        saveReportToCache(report)
    }
    
    /**
     * 缓存报告
     */
    private func saveReportToCache(_ report: ThoughtJourneyReport) {
        do {
            let data = try JSONEncoder().encode(report)
            let key = "thought_journey_\(report.timeRange.key)"
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("❌ 保存报告失败: \(error)")
        }
    }
    
    /**
     * 获取缓存的报告
     */
    func getCachedReport(for timeRange: TimeRange) -> ThoughtJourneyReport? {
        let key = "thought_journey_\(timeRange.key)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        do {
            let report = try JSONDecoder().decode(ThoughtJourneyReport.self, from: data)
            // 检查是否过期（24小时）
            if Date().timeIntervalSince(report.generatedAt) < 24 * 60 * 60 {
                return report
            }
        } catch {
            print("❌ 解析缓存报告失败: \(error)")
        }
        return nil
    }
    
    // MARK: - 虫遇回忆辅助方法
    
    /**
     * 构建角色关系描述
     */
    private func buildCharacterRelationships(normalChats: [UserDataDigest.ChatData], topCharacters: ArraySlice<String>) -> String {
        if normalChats.isEmpty {
            return "暂无角色互动"
        }
        
        var relationships: [String] = []
        
        for characterName in topCharacters {
            let characterChats = normalChats.filter { $0.characterName == characterName }
            let chatCount = characterChats.count
            
            if chatCount > 0 {
                relationships.append("\(characterName)（\(chatCount)次对话）")
            }
        }
        
        return relationships.isEmpty ? "暂无角色互动" : relationships.joined(separator: "，")
    }
    
    /**
     * 构建情感体验数据
     */
    private func buildEmotionalExperiences(userData: UserDataDigest, normalChats: [UserDataDigest.ChatData], observedChats: [UserDataDigest.ChatData]) -> String {
        var experiences: [String] = []
        
        // 分享的想法（动态）
        if userData.posts.count > 0 {
            let totalLikes = userData.posts.reduce(0) { $0 + $1.receivedLikes }
            experiences.append("发布了\(userData.posts.count)条动态，收到\(totalLikes)个赞")
        }
        
        // 私密对话
        if normalChats.count > 0 {
            experiences.append("进行了\(normalChats.count)次私人对话")
        }
        
        // 观看体验
        if observedChats.count > 0 {
            experiences.append("观看了\(observedChats.count)场群聊")
        }
        
        return experiences.isEmpty ? "暂无互动记录" : experiences.joined(separator: "，")
    }
    

}

// MARK: - 数据模型

/**
 * 时间范围
 */
enum TimeRange: CaseIterable {
    case lastDay
    case lastWeek  
    case lastMonth
    
    var description: String {
        switch self {
        case .lastDay: return "1天"
        case .lastWeek: return "1周"
        case .lastMonth: return "1个月"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .lastDay:
            return calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .lastWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        }
    }
    
    var endDate: Date {
        return Date()
    }
    
    var key: String {
        switch self {
        case .lastDay: return "day"
        case .lastWeek: return "week"
        case .lastMonth: return "month"
        }
    }
}

/**
 * 用户数据摘要
 */
struct UserDataDigest {
    let timeRange: TimeRange
    let posts: [PostData]
    let comments: [CommentData]
    let chats: [ChatData]
    let events: [EventData]
    
    struct PostData {
        let id: String
        let content: String
        let date: Date
        let likes: Int
        let characterId: String?
        let imagesCount: Int
        let receivedLikes: Int // 用户收到的点赞数
        let characterReplies: [String] // 回复此帖子的角色
    }
    
    struct CommentData {
        let id: String
        let content: String
        let date: Date
        let likes: Int
        let targetPostId: String?
        let targetPostContent: String?
        let targetPostAuthor: String?
        let repliedCharacters: [String] // 回复了此评论的角色
    }
    
    struct ChatData {
        let id: String
        let content: String
        let date: Date
        let characterId: String
        let characterName: String
        let sessionId: String?
        let sessionTheme: String? // 梦幻联动的主题
        let conversationContext: [String] // 对话上下文
    }
    
    struct EventData {
        let type: String
        let date: Date
        let userComment: String?
        let originalPost: String?
    }
}

/**
 * 虫遇回忆报告
 */
struct ThoughtJourneyReport: Codable, Identifiable {
    let id: UUID
    let timeRange: TimeRange
    let generatedAt: Date
    let content: String
    let stats: Stats
    
    struct Stats: Codable {
        let postsCount: Int
        let commentsCount: Int
        let chatsCount: Int
        let charactersCount: Int
    }
}

// MARK: - TimeRange Codable支持
extension TimeRange: Codable {
    enum CodingKeys: String, CodingKey {
        case rawValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .rawValue)
        
        switch rawValue {
        case "day": self = .lastDay
        case "week": self = .lastWeek
        case "month": self = .lastMonth
        default: throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid TimeRange"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .rawValue)
    }
}

// MARK: - 聊天上下文项

/**
 * 聊天上下文项 - 普通数据结构，避免SwiftData ID冲突
 */
struct ChatContextItem {
    let sessionId: String
    let characterId: String
    let characterName: String
    let content: String
    let timestamp: Date
    let isUserMessage: Bool
    let messageType: String
} 