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
        print("🚀 开始生成次元回放报告 - 时间范围: \(timeRange.description)")
        isGenerating = true
        errorMessage = nil
        
        // 1. 收集用户数据
        let (userData, allChatMessages) = collectUserData(timeRange: timeRange, modelContext: modelContext)
        
        print("📊 数据收集完成:")
        print("  - 帖子数: \(userData.posts.count)")
        print("  - 评论数: \(userData.comments.count)")
        print("  - 聊天数: \(userData.chats.count)")
        print("  - 事件数: \(userData.events.count)")
        
        // 2. 构建AI提示词
        let prompt = buildPrompt(userData: userData, timeRange: timeRange, allChatMessages: allChatMessages)
        print("📝 AI提示词长度: \(prompt.count) 字符")
        
        // 3. 调用AI
        print("🌐 开始调用AI服务...")
        aiNetworkService.sendRequest(prompt: prompt)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isGenerating = false
                    if case .failure(let error) = completion {
                        print("❌ 次元回放生成失败: \(error.localizedDescription)")
                        self?.errorMessage = "生成失败: \(error.localizedDescription)"
                    } else {
                        print("✅ 次元回放API调用完成")
                    }
                },
                receiveValue: { [weak self] response in
                    print("📥 收到AI响应，长度: \(response.count) 字符")
                    print("📄 响应预览: \(String(response.prefix(100)))...")
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
        let allUserPosts = PostViewModel.shared.posts.filter { post in
            // 时间过滤
            let isInTimeRange = post.datePosted >= startDate && post.datePosted <= endDate
            // 排除虚拟角色的帖子 - 通过username判断
            let isUserPost = !allCharacterNames.contains(post.username) && post.username != "AI助手"
            return isInTimeRange && isUserPost
        }
        
        // 使用随机时间点选择帖子
        let userPosts = selectContentByRandomTimePoints(
            allContent: allUserPosts,
            timeRange: timeRange,
            maxCount: 5,
            getDate: { $0.datePosted }
        )
        
        // 收集用户评论（从所有帖子中筛选用户的评论）
        let allPosts = PostViewModel.shared.posts
        let allUserCommentsWithPosts: [(comment: DetailedCommentModel, post: UserPostModel)] = allPosts.flatMap { post in
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
        
        // 使用随机时间点选择评论（包含上下文）
        let userCommentsWithPosts = selectCommentsWithContext(
            allComments: allUserCommentsWithPosts,
            timeRange: timeRange,
            maxCount: 5
        )
        
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
     * 构建AI提示词 - 虫遇回忆版本 (优化版)
     */
    private func buildPrompt(userData: UserDataDigest, timeRange: TimeRange, allChatMessages: [ChatContextItem]) -> String {
        let topCharacters = Array(Set(userData.chats.map { $0.characterName })).prefix(3)
        
        // 构建角色关系描述
        let characterRelationships = buildCharacterRelationships(normalChats: userData.chats.filter { $0.characterId != "user_observer" }, topCharacters: topCharacters)
        
        // 构建情感体验数据
        let emotionalExperiences = buildEmotionalExperiences(userData: userData, 
                                                            normalChats: userData.chats.filter { $0.characterId != "user_observer" }, 
                                                            observedChats: userData.chats.filter { $0.characterId == "user_observer" })
        
        // 使用已经通过随机时间点选择的用户动态和评论
        let limitedPosts = userData.posts
        let limitedComments = userData.comments
        
        let postsContent = limitedPosts.map { post in
            var postInfo = "• \(post.content)"
            if post.receivedLikes > 0 {
                postInfo += "（收到\(post.receivedLikes)个赞）"
            }
            if !post.characterReplies.isEmpty {
                postInfo += "（\(post.characterReplies.joined(separator: "、"))回复了）"
            }
            return postInfo
        }.joined(separator: "\n")
        
        let commentsContent = limitedComments.map { comment in
            var commentInfo = "• \(comment.content)"
            if let targetAuthor = comment.targetPostAuthor, let targetContent = comment.targetPostContent {
                commentInfo += "（回复\(targetAuthor)的动态：\(String(targetContent.prefix(20)))...）"
            }
            if !comment.repliedCharacters.isEmpty {
                commentInfo += "（\(comment.repliedCharacters.joined(separator: "、"))回复了此评论）"
            }
            return commentInfo
        }.joined(separator: "\n")
        
        let chatContent = buildOptimizedChatContexts(userData: userData, allChatMessages: allChatMessages, timeRange: timeRange)
        
        return """
        写一份用户的虫遇回忆，参考网易云年度总结的风格。
        
        用户过去\(timeRange.description)的数据：
        - \(emotionalExperiences)
        - 主要聊天角色：\(characterRelationships)
        
        【用户发布的动态】
        \(postsContent)
        
        【用户发表的评论】
        \(commentsContent)
        
        【具体对话内容】
        \(chatContent)
        
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
        // 特殊处理：如果是 currentUser，返回用户名
        if message.receiverId == "currentUser" {
            return "用户"
        }
        
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
        
        // 显示最近的对话（最多显示8条消息）
        let recentMessages = Array(sortedMessages.suffix(8))
        
        // 只在开头显示一个时间戳表示时间范围
        if let firstMessage = recentMessages.first {
            result += "[\(formatDate(firstMessage.timestamp))] 对话记录：\n"
        }
        
        for message in recentMessages {
            let speaker = message.isUserMessage ? "你" : message.characterName
            result += "\(speaker)：\(message.content)\n"
        }
        
        return result + "\n"
    }
    
    /**
     * 解析并保存报告
     */
    private func parseAndSaveReport(response: String, userData: UserDataDigest) {
        print("🔄 开始解析并保存次元回放报告...")
        
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
        
        print("📋 报告统计:")
        print("  - ID: \(report.id)")
        print("  - 时间范围: \(report.timeRange.description)")
        print("  - 内容长度: \(report.content.count) 字符")
        print("  - 统计数据: posts=\(report.stats.postsCount), comments=\(report.stats.commentsCount), chats=\(report.stats.chatsCount), characters=\(report.stats.charactersCount)")
        
        currentReport = report
        saveReportToCache(report)
        print("✅ 次元回放报告生成并保存完成!")
    }
    
    /**
     * 缓存报告 - 增强可靠性，确保内容持久保存
     */
    private func saveReportToCache(_ report: ThoughtJourneyReport) {
        do {
            let data = try JSONEncoder().encode(report)
            let key = "thought_journey_\(report.timeRange.key)"
            
            // 🔧 主存储
            UserDefaults.standard.set(data, forKey: key)
            
            // 🔧 备份存储 - 防止意外丢失
            let backupKey = "\(key)_backup"
            UserDefaults.standard.set(data, forKey: backupKey)
            
            // 🔧 元数据存储 - 记录保存时间和版本信息
            let metadata = [
                "savedAt": Date().timeIntervalSince1970,
                "contentLength": report.content.count,
                "version": "1.0"
            ] as [String : Any]
            UserDefaults.standard.set(metadata, forKey: "\(key)_meta")
            
            // 🔧 同步保存到磁盘
            UserDefaults.standard.synchronize()
            
            print("✅ 次元回放报告已保存并备份:")
            print("  - 时间范围: \(report.timeRange.description)")
            print("  - 内容长度: \(report.content.count) 字符") 
            print("  - 生成时间: \(formatDate(report.generatedAt))")
            print("  - 存储键: \(key)")
            print("  - 备份键: \(backupKey)")
            
        } catch {
            print("❌ 保存报告失败: \(error)")
            // 尝试直接保存简化版本
            let fallbackData = report.content.data(using: .utf8) ?? Data()
            let fallbackKey = "thought_journey_fallback_\(report.timeRange.key)"
            UserDefaults.standard.set(fallbackData, forKey: fallbackKey)
            print("⚠️ 已保存报告内容的备用版本到: \(fallbackKey)")
        }
    }
    
    /**
     * 获取缓存的报告
     * 移除过期检查，确保内容持久保存直到用户主动生成新内容
     * 增强容错机制，支持备份恢复
     */
    func getCachedReport(for timeRange: TimeRange) -> ThoughtJourneyReport? {
        let key = "thought_journey_\(timeRange.key)"
        let backupKey = "\(key)_backup"
        let metaKey = "\(key)_meta"
        
        // 🔧 尝试从主存储加载
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let report = try JSONDecoder().decode(ThoughtJourneyReport.self, from: data)
                print("✅ 从主存储成功加载次元回放报告: \(timeRange.description)")
                print("  - 生成时间: \(formatDate(report.generatedAt))")
                print("  - 内容长度: \(report.content.count) 字符")
                return report
            } catch {
                print("❌ 主存储解析失败: \(error)")
            }
        }
        
        // 🔧 尝试从备份存储加载
        if let backupData = UserDefaults.standard.data(forKey: backupKey) {
            do {
                let report = try JSONDecoder().decode(ThoughtJourneyReport.self, from: backupData)
                print("✅ 从备份存储成功恢复次元回放报告: \(timeRange.description)")
                print("  - 生成时间: \(formatDate(report.generatedAt))")
                print("  - 内容长度: \(report.content.count) 字符")
                
                // 🔧 恢复主存储
                UserDefaults.standard.set(backupData, forKey: key)
                UserDefaults.standard.synchronize()
                print("🔄 已从备份恢复主存储")
                
                return report
            } catch {
                print("❌ 备份存储解析失败: \(error)")
            }
        }
        
        // 🔧 尝试从备用存储加载（仅文本内容）
        let fallbackKey = "thought_journey_fallback_\(timeRange.key)"
        if let fallbackData = UserDefaults.standard.data(forKey: fallbackKey),
           let content = String(data: fallbackData, encoding: .utf8) {
            print("⚠️ 从备用存储恢复次元回放内容: \(timeRange.description)")
            
            // 创建最小化报告对象
            let fallbackReport = ThoughtJourneyReport(
                id: UUID(),
                timeRange: timeRange,
                generatedAt: Date(), // 使用当前时间作为生成时间
                content: content,
                stats: ThoughtJourneyReport.Stats(
                    postsCount: 0,
                    commentsCount: 0,
                    chatsCount: 0,
                    charactersCount: 0
                )
            )
            
            print("🔄 已从备用存储创建报告对象，内容长度: \(content.count) 字符")
            return fallbackReport
        }
        
        // 🔧 检查元数据，用于调试
        if let metadata = UserDefaults.standard.dictionary(forKey: metaKey) {
            print("📊 发现次元回放元数据:")
            print("  - 保存时间: \(Date(timeIntervalSince1970: metadata["savedAt"] as? Double ?? 0))")
            print("  - 内容长度: \(metadata["contentLength"] as? Int ?? 0)")
            print("  - 版本: \(metadata["version"] as? String ?? "未知")")
        }
        
        print("📂 未找到任何缓存的次元回放报告: \(timeRange.description)")
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
    
    /**
     * 构建优化版聊天上下文 - 限制数量，优先最近内容，减少时间戳
     */
    private func buildOptimizedChatContexts(userData: UserDataDigest, allChatMessages: [ChatContextItem], timeRange: TimeRange) -> String {
        print("🔍 构建优化版聊天上下文:")
        print("  - userData.chats数量: \(userData.chats.count)")
        print("  - allChatMessages数量: \(allChatMessages.count)")
        
        if userData.chats.isEmpty {
            print("  - 结果: 无对话记录")
            return "无对话记录"
        }
        
        // 1. 过滤有价值的聊天消息
        let meaningfulChats = filterMeaningfulChats(userData.chats)
        print("  - 过滤后有价值的聊天: \(meaningfulChats.count)条")
        
        // 2. 分类聊天记录
        var oneOnOneChats: [UserDataDigest.ChatData] = []
        var groupChatSessions: [String: [UserDataDigest.ChatData]] = [:]
        
        for chat in meaningfulChats {
            if chat.characterId == "user_observer" || chat.sessionTheme != nil {
                // 梦幻联动：观察者记录或有sessionTheme的都是多人对话
                // 保持原始sessionId，不要修改
                if let sessionId = chat.sessionId {
                    groupChatSessions[sessionId, default: []].append(chat)
                } else {
                    // 如果没有sessionId，使用临时ID但记录原始信息
                    let tempSessionId = "group_\(chat.id)"
                    groupChatSessions[tempSessionId, default: []].append(chat)
                }
            } else {
                // 其他都是一对一聊天（包括原来的private_和没有sessionId的）
                oneOnOneChats.append(chat)
            }
        }
        
        print("  - 一对一聊天记录: \(oneOnOneChats.count)条")
        print("  - 多人对话会话数: \(groupChatSessions.count)个")
        
        var contextParts: [String] = []
        
        // 3. 处理多人对话（梦幻联动）- 只选择有用户回复的，最多2个
        let groupChatsWithUserReplies = groupChatSessions.filter { (sessionId, sessionChats) in
            // 检查是否有用户回复（非观察者的用户消息）
            return sessionChats.contains { $0.characterId != "user_observer" }
        }
        
        let sortedGroupChats = groupChatsWithUserReplies.sorted { (session1, session2) in
            // 按活跃度排序
            return session1.value.count > session2.value.count
        }
        
        // 使用随机时间点选择多人对话会话
        let selectedGroupChats = selectChatSessionsByRandomTimePoints(
            allSessions: Array(sortedGroupChats),
            timeRange: timeRange,
            maxCount: 2
        )
        for (sessionId, sessionChats) in selectedGroupChats {
            let sessionContext = buildGroupChatSessionContext(
                sessionId: sessionId,
                chats: sessionChats,
                allChatMessages: allChatMessages
            )
            if !sessionContext.isEmpty {
                contextParts.append(sessionContext)
            }
        }
        
        // 4. 处理一对一聊天 - 按角色分组并选择最活跃的4个
        var oneOnOneSessions: [String: [UserDataDigest.ChatData]] = [:]
        for chat in oneOnOneChats {
            // 按角色分组，确保每个角色的对话作为一个会话
            let sessionKey = chat.characterId
            oneOnOneSessions[sessionKey, default: []].append(chat)
        }
        
        let sortedOneOnOneSessions = oneOnOneSessions.sorted { $0.value.count > $1.value.count }
        // 使用随机时间点选择一对一聊天会话
        let selectedOneOnOneSessions = selectChatSessionsByRandomTimePoints(
            allSessions: Array(sortedOneOnOneSessions),
            timeRange: timeRange,
            maxCount: 4
        )
        
        for (characterId, sessionChats) in selectedOneOnOneSessions {
            // 为一对一聊天构建sessionId
            let sessionId = sessionChats.first?.sessionId ?? "oneOnOne_\(characterId)"
            
            let sessionContext = buildOptimizedSessionContext(
                sessionId: sessionId,
                chats: sessionChats,
                allChatMessages: allChatMessages,
                maxMessages: 8,
                isFirstSession: false
            )
            if !sessionContext.isEmpty {
                contextParts.append(sessionContext)
            }
        }
        
        let result = contextParts.joined(separator: "\n")
        print("  - 最终包含: 多人对话(有用户回复)\(selectedGroupChats.count)个, 一对一聊天\(selectedOneOnOneSessions.count)个")
        print("  - 生成的上下文长度: \(result.count) 字符")
        
        return result
    }
    
    /**
     * 过滤有价值的聊天消息
     */
    private func filterMeaningfulChats(_ chats: [UserDataDigest.ChatData]) -> [UserDataDigest.ChatData] {
        return chats.filter { chat in
            let content = chat.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 观察者记录（多人聊天观看记录）始终保留
            if chat.characterId == "user_observer" {
                return true
            }
            
            // 过滤条件
            guard content.count >= 2 else { return false } // 至少2个字符
            
            // 排除纯数字、纯符号、简单回应
            let excludePatterns = [
                "^[0-9]+$",              // 纯数字
                "^[好嗯啊哦呃]{1,3}$",      // 简单回应
                "^[。，！？…]{1,5}$",       // 纯标点
                "^在吗$",
                "^你好$",
                "^再见$",
                "^谢谢$",
                "^[哈]{2,}$"             // 纯笑声
            ]
            
            for pattern in excludePatterns {
                if content.range(of: pattern, options: .regularExpression) != nil {
                    return false
                }
            }
            
            return true
        }
    }
    
    private func buildGroupChatSessionContext(
        sessionId: String,
        chats: [UserDataDigest.ChatData],
        allChatMessages: [ChatContextItem]
    ) -> String {
        guard let firstChat = chats.first else { return "" }
        
        print("    🔍 构建多人对话会话上下文:")
        print("      - sessionId: \(sessionId)")
        print("      - chats数量: \(chats.count)")
        print("      - allChatMessages总数: \(allChatMessages.count)")
        
        var sessionInfo = ""
        
        // 添加会话标题
        if let sessionTheme = firstChat.sessionTheme, !sessionTheme.isEmpty {
            sessionInfo += "【梦幻联动：\(sessionTheme)】\n"
        } else {
            sessionInfo += "【梦幻联动讨论】\n"
        }
        
        // 检查是否有观察者记录
        let observerChat = chats.first { $0.characterId == "user_observer" }
        if let observer = observerChat {
            sessionInfo += "\(observer.content)\n"
        }
        
        // 获取该会话的完整对话消息
        let sessionMessages = allChatMessages.filter { $0.sessionId == sessionId }
            .sorted { $0.timestamp < $1.timestamp }
        
        print("      - 匹配到的sessionMessages数量: \(sessionMessages.count)")
        
        // 从用户发送的消息开始提取，最多10条消息
        var extractedMessages: [ChatContextItem] = []
        
        // 找到最后一条用户消息的位置
        if let lastUserMessageIndex = sessionMessages.lastIndex(where: { $0.isUserMessage }) {
            // 从用户消息开始（包括那条用户消息），提取最多10条消息
            let startIndex = lastUserMessageIndex
            let endIndex = min(startIndex + 9, sessionMessages.count - 1)
            extractedMessages = Array(sessionMessages[startIndex...endIndex])
        }
        
        print("      - 提取的消息数量: \(extractedMessages.count)")
        
        // 如果没有匹配到消息，尝试其他匹配方式
        if sessionMessages.isEmpty {
            print("      - 尝试其他匹配方式...")
            // 打印前几个allChatMessages的sessionId用于调试
            for (index, msg) in allChatMessages.prefix(5).enumerated() {
                print("      - allChatMessages[\(index)].sessionId: \(msg.sessionId)")
            }
        }
        
        if !extractedMessages.isEmpty {
            // 只在开头显示一个时间戳表示时间范围
            if let firstMessage = extractedMessages.first {
                sessionInfo += "[\(formatDate(firstMessage.timestamp))] 对话内容：\n"
            } else {
                sessionInfo += "对话内容：\n"
            }
            
            var lastContent = ""
            var duplicateCount = 0
            
            for message in extractedMessages {
                let speaker = message.isUserMessage ? "你" : message.characterName
                let content = message.content
                
                // 去重逻辑
                if content == lastContent {
                    duplicateCount += 1
                    if duplicateCount >= 2 { continue }
                } else {
                    duplicateCount = 0
                    lastContent = content
                }
                
                sessionInfo += "\(speaker)：\(content)\n"
            }
        } else {
            print("      - 警告: 没有找到用户回复的消息，跳过此会话")
        }
        
        print("      - 生成的sessionInfo长度: \(sessionInfo.count)")
        return sessionInfo + "\n"
    }
    
    /**
     * 构建优化版单个会话上下文
     */
    private func buildOptimizedSessionContext(
        sessionId: String,
        chats: [UserDataDigest.ChatData],
        allChatMessages: [ChatContextItem],
        maxMessages: Int,
        isFirstSession: Bool
    ) -> String {
        guard let firstChat = chats.first else { return "" }
        
        var sessionInfo = ""
        
        // 判断是否为观察者记录
        if firstChat.characterId == "user_observer" {
            if let sessionTheme = firstChat.sessionTheme, !sessionTheme.isEmpty {
                sessionInfo += "【梦幻联动：\(sessionTheme)】\n"
            } else {
                sessionInfo += "【梦幻联动讨论】\n"
            }
            // 观察者记录只显示内容，不显示时间戳
            sessionInfo += "\(firstChat.content)\n\n"
        } else {
            // 正常的用户参与记录
            if let sessionTheme = firstChat.sessionTheme, !sessionTheme.isEmpty {
                sessionInfo += "【梦幻联动：\(sessionTheme)】\n"
            } else if sessionId.hasPrefix("private_") {
                sessionInfo += "【与\(firstChat.characterName)的私聊】\n"
            } else {
                sessionInfo += "【与\(firstChat.characterName)的对话】\n"
            }
            
            // 获取该会话的完整对话
            let sessionMessages: [ChatContextItem]
            if sessionId.hasPrefix("private_") {
                let conversationId = sessionId.replacingOccurrences(of: "private_", with: "")
                sessionMessages = allChatMessages.filter { $0.sessionId == conversationId }
            } else {
                sessionMessages = allChatMessages.filter { $0.sessionId == sessionId }
            }
            
            // 按时间排序并取最近的消息
            let sortedMessages = sessionMessages.sorted { $0.timestamp < $1.timestamp }
            let recentMessages = Array(sortedMessages.suffix(maxMessages))
            
            if recentMessages.isEmpty {
                sessionInfo += "暂无对话记录\n"
            } else {
                // 只在第一个会话显示一个时间戳作为时间参考
                if isFirstSession && !recentMessages.isEmpty {
                    sessionInfo += "[\(formatDate(recentMessages.first!.timestamp))] 开始\n"
                }
                
                // 去重：避免连续重复的相同内容
                var lastContent = ""
                var duplicateCount = 0
                
                for message in recentMessages {
                    let speaker = message.isUserMessage ? "你" : message.characterName
                    let content = message.content
                    
                    // 去重逻辑
                    if content == lastContent {
                        duplicateCount += 1
                        if duplicateCount >= 2 { continue } // 跳过重复内容
                    } else {
                        duplicateCount = 0
                        lastContent = content
                    }
                    
                    sessionInfo += "\(speaker)：\(content)\n"
                }
            }
            
            sessionInfo += "\n"
        }
        
        return sessionInfo
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

// MARK: - 随机时间点选择扩展

extension ThoughtJourneyService {
    /**
     * 基于随机时间点选择内容组（包含上下文）
     * @param allContent 所有符合时间范围的内容
     * @param timeRange 时间范围
     * @param maxCount 最大选择数量
     * @param getDate 获取内容日期的闭包
     * @return 选中的内容数组
     */
    private func selectContentByRandomTimePoints<T>(
        allContent: [T],
        timeRange: TimeRange,
        maxCount: Int,
        getDate: (T) -> Date
    ) -> [T] {
        guard !allContent.isEmpty else { return [] }
        
        // 如果内容总数不超过限制，直接返回所有内容
        if allContent.count <= maxCount {
            return allContent
        }
        
        // 根据目标数量调整时间点数量，确保每个时间点能选择2-3个相关内容
        let timePointCount = max(1, maxCount / 3) // 每个时间点平均选择3个内容
        let randomTimePoints = generateRandomTimePoints(for: timeRange, count: timePointCount)
        
        var selectedContent: [T] = []
        var usedContent = Set<Int>() // 记录已使用的内容索引，避免重复选择
        
        print("🎲 随机时间点内容组选择 - 时间范围: \(timeRange.description)")
        print("  - 总内容数: \(allContent.count)")
        print("  - 目标选择数: \(maxCount)")
        print("  - 时间点数: \(timePointCount)")
        print("  - 随机时间点: \(randomTimePoints.map { formatDateForRandomSelection($0) })")
        
        // 为每个随机时间点选择内容组
        for timePoint in randomTimePoints {
            guard selectedContent.count < maxCount else { break }
            
            // 选择该时间点的内容组
            let contentGroup = selectContentGroupAroundTimePoint(
                timePoint: timePoint,
                allContent: allContent,
                usedContent: usedContent,
                maxGroupSize: min(3, maxCount - selectedContent.count),
                getDate: getDate
            )
            
            // 添加内容组到结果中
            for (content, index) in contentGroup {
                selectedContent.append(content)
                usedContent.insert(index)
            }
            
            if !contentGroup.isEmpty {
                print("  ✅ 时间点 \(formatDateForRandomSelection(timePoint)): 选中 \(contentGroup.count) 条相关内容")
            }
        }
        
        print("  - 最终选中: \(selectedContent.count) 条内容")
        return selectedContent
    }
    
    /**
     * 围绕指定时间点选择内容组
     * @param timePoint 目标时间点
     * @param allContent 所有内容
     * @param usedContent 已使用的内容索引
     * @param maxGroupSize 内容组最大大小
     * @param getDate 获取日期的闭包
     * @return 选中的内容组 [(内容, 索引)]
     */
    private func selectContentGroupAroundTimePoint<T>(
        timePoint: Date,
        allContent: [T],
        usedContent: Set<Int>,
        maxGroupSize: Int,
        getDate: (T) -> Date
    ) -> [(content: T, index: Int)] {
        guard maxGroupSize > 0 else { return [] }
        
        // 计算所有内容与时间点的距离
        var contentWithDistance: [(content: T, index: Int, distance: TimeInterval)] = []
        
        for (index, content) in allContent.enumerated() {
            if usedContent.contains(index) { continue }
            
            let contentDate = getDate(content)
            let distance = abs(contentDate.timeIntervalSince(timePoint))
            contentWithDistance.append((content: content, index: index, distance: distance))
        }
        
        // 按距离排序，选择最近的几个内容
        contentWithDistance.sort { $0.distance < $1.distance }
        
        let selectedGroup = Array(contentWithDistance.prefix(maxGroupSize))
        return selectedGroup.map { (content: $0.content, index: $0.index) }
    }
    
    /**
     * 选择评论及其上下文（包含原帖内容）
     * @param allComments 所有评论及其关联帖子
     * @param timeRange 时间范围
     * @param maxCount 最大选择数量
     * @return 选中的评论及帖子组合
     */
    private func selectCommentsWithContext(
        allComments: [(comment: DetailedCommentModel, post: UserPostModel)],
        timeRange: TimeRange,
        maxCount: Int
    ) -> [(comment: DetailedCommentModel, post: UserPostModel)] {
        guard !allComments.isEmpty else { return [] }
        
        if allComments.count <= maxCount {
            return allComments
        }
        
        // 按帖子分组评论
        let commentsByPost = Dictionary(grouping: allComments) { $0.post.id }
        
        // 生成随机时间点（减少时间点数量，每个时间点选择更多相关内容）
        let timePointCount = max(1, maxCount / 2) // 每个时间点平均选择2条评论
        let randomTimePoints = generateRandomTimePoints(for: timeRange, count: timePointCount)
        
        var selectedComments: [(comment: DetailedCommentModel, post: UserPostModel)] = []
        var usedPostIds = Set<UUID>()
        
        print("🎲 随机时间点评论组选择 - 时间范围: \(timeRange.description)")
        print("  - 总评论数: \(allComments.count)")
        print("  - 涉及帖子数: \(commentsByPost.count)")
        print("  - 目标选择数: \(maxCount)")
        print("  - 时间点数: \(timePointCount)")
        
        for timePoint in randomTimePoints {
            guard selectedComments.count < maxCount else { break }
            
            // 找到距离时间点最近的评论
            var bestCommentGroup: [(comment: DetailedCommentModel, post: UserPostModel)] = []
            var bestDistance: TimeInterval = .infinity
            var bestPostId: UUID = UUID()
            
            for (postId, commentsInPost) in commentsByPost {
                if usedPostIds.contains(postId) { continue }
                
                // 找到该帖子中距离时间点最近的评论
                if let nearestComment = commentsInPost.min(by: { comment1, comment2 in
                    let distance1 = abs(comment1.comment.datePosted.timeIntervalSince(timePoint))
                    let distance2 = abs(comment2.comment.datePosted.timeIntervalSince(timePoint))
                    return distance1 < distance2
                }) {
                    let distance = abs(nearestComment.comment.datePosted.timeIntervalSince(timePoint))
                    
                    if distance < bestDistance {
                        bestDistance = distance
                        bestPostId = postId
                        
                        // 选择该帖子下最多2条评论（包含最近的那条）
                        let sortedComments = commentsInPost.sorted { 
                            abs($0.comment.datePosted.timeIntervalSince(timePoint)) < 
                            abs($1.comment.datePosted.timeIntervalSince(timePoint))
                        }
                        bestCommentGroup = Array(sortedComments.prefix(min(2, maxCount - selectedComments.count)))
                    }
                }
            }
            
            // 添加最佳评论组
            if !bestCommentGroup.isEmpty {
                selectedComments.append(contentsOf: bestCommentGroup)
                usedPostIds.insert(bestPostId)
                
                print("  ✅ 时间点 \(formatDateForRandomSelection(timePoint)): 选中帖子 \(bestPostId.uuidString) 的 \(bestCommentGroup.count) 条评论")
            }
        }
        
        print("  - 最终选中: \(selectedComments.count) 条评论")
        return selectedComments
    }
    
    /**
     * 为指定时间范围生成随机时间点
     */
    private func generateRandomTimePoints(for timeRange: TimeRange, count: Int) -> [Date] {
        let startDate = timeRange.startDate
        let endDate = timeRange.endDate
        let timeInterval = endDate.timeIntervalSince(startDate)
        
        var timePoints: [Date] = []
        
        for _ in 0..<count {
            // 生成随机时间偏移量（0到总时间间隔之间）
            let randomOffset = Double.random(in: 0...timeInterval)
            let randomDate = startDate.addingTimeInterval(randomOffset)
            timePoints.append(randomDate)
        }
        
        // 按时间排序，让输出更有逻辑性
        return timePoints.sorted()
    }
    
    /**
     * 格式化日期用于调试输出（随机时间点选择专用）
     */
    private func formatDateForRandomSelection(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    /**
     * 基于随机时间点选择聊天会话（增强上下文）
     * @param allSessions 所有会话（键值对数组）
     * @param timeRange 时间范围
     * @param maxCount 最大选择数量
     * @return 选中的会话数组
     */
    private func selectChatSessionsByRandomTimePoints(
        allSessions: [(key: String, value: [UserDataDigest.ChatData])],
        timeRange: TimeRange,
        maxCount: Int
    ) -> [(key: String, value: [UserDataDigest.ChatData])] {
        guard !allSessions.isEmpty else { return [] }
        
        // 如果会话总数不超过限制，直接返回所有会话
        if allSessions.count <= maxCount {
            return allSessions
        }
        
        // 减少时间点数量，每个时间点选择更多会话
        let timePointCount = max(1, maxCount / 2) // 每个时间点平均选择2个会话
        let randomTimePoints = generateRandomTimePoints(for: timeRange, count: timePointCount)
        
        var selectedSessions: [(key: String, value: [UserDataDigest.ChatData])] = []
        var usedSessionIndices = Set<Int>()
        
        print("🎲 随机时间点聊天会话组选择 - 时间范围: \(timeRange.description)")
        print("  - 总会话数: \(allSessions.count)")
        print("  - 目标选择数: \(maxCount)")
        print("  - 时间点数: \(timePointCount)")
        print("  - 随机时间点: \(randomTimePoints.map { formatDateForRandomSelection($0) })")
        
        // 为每个随机时间点选择会话组
        for timePoint in randomTimePoints {
            guard selectedSessions.count < maxCount else { break }
            
            // 选择距离该时间点最近的几个会话
            var sessionCandidates: [(session: (key: String, value: [UserDataDigest.ChatData]), index: Int, distance: TimeInterval)] = []
            
            for (index, session) in allSessions.enumerated() {
                // 跳过已使用的会话
                if usedSessionIndices.contains(index) { continue }
                
                // 计算会话的时间（使用会话中最新的消息时间）
                guard let latestChatDate = session.value.max(by: { $0.date < $1.date })?.date else { continue }
                
                let distance = abs(latestChatDate.timeIntervalSince(timePoint))
                sessionCandidates.append((session: session, index: index, distance: distance))
            }
            
            // 按距离排序，选择最近的几个会话
            sessionCandidates.sort { $0.distance < $1.distance }
            let groupSize = min(2, maxCount - selectedSessions.count, sessionCandidates.count)
            
            for i in 0..<groupSize {
                let candidate = sessionCandidates[i]
                selectedSessions.append(candidate.session)
                usedSessionIndices.insert(candidate.index)
            }
            
            if groupSize > 0 {
                print("  ✅ 时间点 \(formatDateForRandomSelection(timePoint)): 选中 \(groupSize) 个相关会话")
            }
        }
        
        print("  - 最终选中: \(selectedSessions.count) 个会话")
        return selectedSessions
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