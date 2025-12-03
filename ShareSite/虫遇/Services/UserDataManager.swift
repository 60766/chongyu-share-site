import Foundation
import SwiftUI
import SwiftData

/// 用户数据管理服务
/// 负责处理用户数据的备份、清理、导出等功能
class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    private init() {
        setupLogoutListener()
    }
    
    // MARK: - 数据清理
    
    /// 清除所有用户数据
    func clearAllUserData() {
        print("🧹 开始清除用户数据...")
        
        // 1. 清除用户资料
        clearUserProfile()
        
        // 2. 清除自定义角色
        clearCustomCharacters()
        
        // 3. 清除聊天记录（如果有的话）
        clearChatHistory()
        
        // 4. 清除其他用户偏好设置
        clearUserPreferences()
        
        print("🧹 用户数据清除完成")
    }
    
    /// 清除用户资料
    private func clearUserProfile() {
        let keysToRemove = [
            "user_profile_username",
            "user_profile_personal_signature",
            "user_profile_avatar_name",
            "user_profile_level",
            "user_profile_experience",
            "user_profile_level_title",
            "user_profile_last_level_update"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // 通知用户资料管理器重置
        DispatchQueue.main.async {
            UserProfileManager.shared.resetToDefault()
        }
        
        print("✅ 已清除用户资料")
    }
    
    /// 清除自定义角色
    private func clearCustomCharacters() {
        // 获取所有自定义角色的键
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        let customCharacterKeys = allKeys.filter { key in
            key.hasPrefix("custom_character_") || 
            key.hasPrefix("character_avatar_") ||
            key == "custom_characters_list"
        }
        
        for key in customCharacterKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        print("✅ 已清除自定义角色数据")
    }
    
    /// 清除聊天记录
    private func clearChatHistory() {
        // 如果有聊天记录存储，在这里清除
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        let chatKeys = allKeys.filter { key in
            key.hasPrefix("chat_") || 
            key.hasPrefix("conversation_") ||
            key.hasPrefix("message_")
        }
        
        for key in chatKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        print("✅ 已清除聊天记录")
    }
    
    /// 清除用户偏好设置
    private func clearUserPreferences() {
        let keysToRemove = [
            "theme_preference",
            "notification_settings",
            "privacy_settings",
            "app_usage_stats"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        print("✅ 已清除用户偏好设置")
    }
    
    // MARK: - 数据备份和导出
    
    /// 导出用户数据
    /// - Parameter modelContext: SwiftData的ModelContext，用于获取私聊和多人对话数据
    func exportUserData(modelContext: ModelContext? = nil) -> [String: Any] {
        print("🔄 开始导出用户核心数据...")
        var exportData: [String: Any] = [:]
        
        // 1. 个人档案（简洁版）
        let profileManager = UserProfileManager.shared
        let profile: [String: Any] = [
            "nickname": profileManager.username,
            "signature": profileManager.personalSignature,
            "level": profileManager.userLevel,
            "levelTitle": profileManager.levelTitle,
            "joinDate": formatDate(AppAccountManager.shared.accountCreationDate)
        ]
        exportData["profile"] = profile
        print("👤 个人档案: \(profile)")
        
        // 2. 我的创作
        var myCreations: [String: Any] = [:]
        
        // 获取所有帖子（用户发的 + AI生成的）
        let allPosts = getAllPosts()
        let postsData = allPosts.map { post in
            var postData: [String: Any] = [
                "id": post.id.uuidString,
                "content": post.content,
                "username": post.username,
                "userAvatar": post.userAvatar, // 保存头像信息
                "date": formatDate(post.datePosted),
                "likes": post.likes,
                "type": post.contentType ?? "动态",
                "source": post.source ?? "unknown",
                "characterID": post.characterID ?? "",
                "isUserPost": isUserCreatedPost(post),
                "isLikedByCurrentUser": post.isLikedByCurrentUser, // 保存点赞状态
                "isBookmarkedByCurrentUser": post.isBookmarkedByCurrentUser, // 保存收藏状态
                "comments": getCommentsData(from: post.comments)
            ]
            
            // 添加角色名称（如果是角色发的帖子）
            if let characterID = post.characterID, !characterID.isEmpty {
                if let characterName = getCharacterName(from: characterID) {
                    postData["characterName"] = characterName
                }
            }
            
            // 如果用户名是虚拟角色名称，也记录为角色名称
            if isVirtualCharacterName(post.username) {
                postData["characterName"] = post.username
                postData["isCharacterPost"] = true
            }
            
            // 添加帖子图片数据（base64编码）
            if !post.images.isEmpty {
                print("📸 [备份] 帖子 \(post.id.uuidString) 有 \(post.images.count) 张图片: \(post.images)")
                var postImages: [[String: Any]] = []
                for imageId in post.images {
                    if let imageData = loadPostImage(imageId: imageId) {
                        postImages.append([
                            "id": imageId,
                            "imageData": imageData
                        ])
                        print("✅ [备份] 已备份帖子图片: \(imageId), base64长度: \(imageData.count)")
                    } else {
                        print("⚠️ [备份] 无法加载帖子图片: \(imageId)")
                    }
                }
                if !postImages.isEmpty {
                    postData["images"] = post.images // 保留图片ID列表
                    postData["postImages"] = postImages // 添加图片数据
                    print("✅ [备份] 帖子图片备份完成: \(postImages.count)/\(post.images.count) 张")
                } else {
                    print("⚠️ [备份] 帖子 \(post.id.uuidString) 没有成功备份任何图片")
                }
            }
            
            return postData
        }
        myCreations["posts"] = postsData
        
        // 统计信息
        let userPostsCount = postsData.filter { ($0["isUserPost"] as? Bool) == true }.count
        let aiPostsCount = postsData.count - userPostsCount
        let totalComments = postsData.reduce(0) { total, post in
            total + ((post["comments"] as? [[String: Any]])?.count ?? 0)
        }
        
        // 获取自定义角色（简化版）
        let customCharacters = getSimplifiedCustomCharacters()
        myCreations["customCharacters"] = customCharacters
        
        exportData["myCreations"] = myCreations
        print("✍️ 我的创作: \(postsData.count) 篇帖子（用户: \(userPostsCount), AI: \(aiPostsCount)）, \(totalComments) 条评论, \(customCharacters.count) 个自定义角色")
        
        // 3. 成长记录
        let highlights: [String: Any] = [
            "totalPosts": postsData.count,
            "userPosts": userPostsCount,
            "aiPosts": aiPostsCount,
            "totalComments": totalComments,
            "totalCustomCharacters": customCharacters.count,
            "currentLevel": profileManager.userLevel,
            "experience": profileManager.userExperience,
            "memberDays": calculateMemberDays(),
            "dialogueCount": calculateDialogueCount(),
            "explorationDays": calculateExplorationDays()
        ]
        exportData["highlights"] = highlights
        print("📈 成长记录: \(highlights)")
        
        // 4. 成就系统数据
        let achievementsData = getAchievementsData()
        exportData["achievements"] = achievementsData
        print("🏆 成就系统: \(achievementsData.count) 个成就已导出")
        
        // 5. 私聊对话数据
        if let conversationsData = getConversationsData(modelContext: modelContext) {
            exportData["conversations"] = conversationsData
            print("💬 私聊对话: \(conversationsData["totalConversations"] as? Int ?? 0) 个对话, \(conversationsData["totalMessages"] as? Int ?? 0) 条消息")
        }
        
        // 6. 多人对话数据
        if let multiChatData = getMultiPersonChatData(modelContext: modelContext) {
            exportData["multiPersonChats"] = multiChatData
            print("👥 多人对话: \(multiChatData["totalSessions"] as? Int ?? 0) 个会话, \(multiChatData["totalMessages"] as? Int ?? 0) 条消息")
        }
        
        // 7. 导出点赞记录
        if let likesData = UserDefaults.standard.data(forKey: "UserLikes_v1") {
            do {
                if let likesArray = try JSONSerialization.jsonObject(with: likesData) as? [[String: Any]] {
                    exportData["likes"] = likesArray
                    print("✅ [备份] 已备份 \(likesArray.count) 条点赞记录")
                } else {
                    // 尝试使用JSONDecoder解码
                    let decoder = JSONDecoder()
                    if let likesRecords = try? decoder.decode([LikeRecord].self, from: likesData) {
                        let encoder = JSONEncoder()
                        encoder.dateEncodingStrategy = .iso8601
                        if let encodedData = try? encoder.encode(likesRecords),
                           let likesArray = try? JSONSerialization.jsonObject(with: encodedData) as? [[String: Any]] {
                            exportData["likes"] = likesArray
                            print("✅ [备份] 已备份 \(likesArray.count) 条点赞记录")
                        }
                    }
                }
            } catch {
                print("⚠️ [备份] 备份点赞记录失败: \(error)")
            }
        }
        
        // 8. 导出关注角色
        if let followedData = getFollowedCharactersBackupData() {
            exportData["followedCharacters"] = followedData
            let count = followedData["count"] as? Int ?? 0
            print("🤝 关注角色: 已备份 \(count) 个关注对象")
        } else {
            print("🤝 关注角色: 当前没有关注任何角色")
        }
        
        // 9. 导出信息
        exportData["exportInfo"] = [
            "exportDate": formatDate(Date()),
            "version": "3.3",
            "description": "包含所有帖子（用户+AI）、完整评论数据、成就系统数据、私聊对话、多人对话和点赞记录"
        ]
        
        print("📤 用户核心数据导出完成")
        return exportData
    }
    
    /// 获取所有帖子（用户发的 + AI生成的）
    private func getAllPosts() -> [UserPostModel] {
        return PostViewModel.shared.posts
    }
    
    /// 判断是否为用户创建的帖子
    private func isUserCreatedPost(_ post: UserPostModel) -> Bool {
        let currentUsername = UserProfileManager.shared.username
        
        // AI生成的帖子（onekey、wormhole）不算用户帖子
        if post.source == "onekey" || post.source == "wormhole" {
            return false
        }
        
        // 虚拟角色名称发的帖子不算用户帖子
        if isVirtualCharacterName(post.username) {
            return false
        }
        
        // 有角色ID的帖子通常是AI生成的，不算用户帖子
        if let characterID = post.characterID, !characterID.isEmpty {
            // 除非是用户自己发的帖子，并且明确标记为用户创建
            // 这里简化处理：有characterID的帖子都算AI生成的
            return false
        }
        
        // 只有用户名匹配当前用户，且不是虚拟角色，且不是AI生成来源的才算用户帖子
        return post.username == currentUsername
    }
    
    /// 检查是否为虚拟角色名称
    private func isVirtualCharacterName(_ name: String) -> Bool {
        let virtualCharacterNames = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白", "AI助手"]
        return virtualCharacterNames.contains(name)
    }
    
    /// 备份关注的角色数据
    private func getFollowedCharactersBackupData() -> [String: Any]? {
        let followedNames = FollowManager.shared.getFollowedUsers()
        guard !followedNames.isEmpty else { return nil }
        
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        let charactersData: [[String: Any]] = followedNames.map { entry in
            if let match = allCharacters.first(where: { $0.name == entry || $0.id == entry }) {
                return [
                    "id": match.id,
                    "name": match.name
                ]
            } else {
                // 兼容自定义角色或未匹配的名称
                return [
                    "id": entry,
                    "name": entry,
                    "isCustom": true
                ]
            }
        }
        
        return [
            "count": followedNames.count,
            "characters": charactersData,
            "rawList": followedNames
        ]
    }
    
    /// 获取评论数据（包括用户评论和AI评论）
    private func getCommentsData(from comments: [DetailedCommentModel]) -> [[String: Any]] {
        return comments.map { comment in
            var commentData: [String: Any] = [
                "id": comment.id.uuidString,
                "content": comment.content,
                "username": comment.username,
                "date": formatDate(comment.datePosted),
                "likes": comment.likes,
                "isVirtualCharacter": comment.isVirtualCharacter,
                "characterID": comment.characterID ?? ""
            ]
            
            // 如果是虚拟角色评论，添加角色名称
            if comment.isVirtualCharacter {
                if let characterID = comment.characterID, !characterID.isEmpty {
                    if let characterName = getCharacterName(from: characterID) {
                        commentData["characterName"] = characterName
                    } else {
                        // 如果找不到角色名称，使用用户名作为角色名称
                        commentData["characterName"] = comment.username
                    }
                } else {
                    // 如果没有characterID，用户名可能就是角色名称
                    commentData["characterName"] = comment.username
                }
            }
            
            // 如果是回复，添加回复信息
            if let parentId = comment.parentCommentId {
                commentData["parentCommentId"] = parentId.uuidString
            }
            if let replyTo = comment.replyToUsername {
                commentData["replyToUsername"] = replyTo
            }
            
            // 递归获取子回复
            if !comment.replies.isEmpty {
                commentData["replies"] = getCommentsData(from: comment.replies)
            }
            
            return commentData
        }
    }
    
    /// 根据角色ID获取角色名称
    private func getCharacterName(from characterID: String) -> String? {
        // 方法1: 从CharacterDataManager获取（历史人物等）
        if let characterName = CharacterDataManager.shared.getName(for: characterID) {
            return characterName
        }
        
        // 方法2: 从UserDefaults的自定义角色中查找
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let characterKeys = allKeys.filter { $0.hasPrefix("custom_character_") }
        
        for key in characterKeys {
            if let characterData = userDefaults.dictionary(forKey: key) {
                if let id = characterData["id"] as? String, id == characterID {
                    return characterData["name"] as? String
                }
            }
        }
        
        // 方法3: 如果characterID本身就是角色名称（某些情况下）
        // 检查是否是已知的虚拟角色名称
        if isVirtualCharacterName(characterID) {
            return characterID
        }
        
        return nil
    }
    
    /// 获取自定义角色信息（完整版，用于备份）
    private func getSimplifiedCustomCharacters() -> [[String: Any]] {
        var characters: [[String: Any]] = []
        
        let userDefaults = UserDefaults.standard
        
        // 方法1: 从 CustomCharactersData 键获取（新格式）
        if let data = userDefaults.data(forKey: "CustomCharactersData") {
            do {
                if let characterArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for characterData in characterArray {
                        let characterId = characterData["id"] as? String ?? UUID().uuidString
                        
                        // 复制所有字段，确保不丢失任何数据
                        var character: [String: Any] = [:]
                        for (key, value) in characterData {
                            // 跳过不能序列化的类型，稍后单独处理
                            if !(value is NSNull) {
                                character[key] = value
                            }
                        }
                        
                        // 确保必要字段存在
                        character["id"] = characterId
                        if character["name"] == nil {
                            character["name"] = characterData["name"] as? String ?? "未命名角色"
                        }
                        
                        // 兼容 description 和 bio 字段
                        if let bio = characterData["bio"] as? String, character["description"] == nil {
                            character["description"] = bio
                        }
                        if let description = characterData["description"] as? String, character["bio"] == nil {
                            character["bio"] = description
                        }
                        
                        // 处理 createdDate
                        if let createdDate = characterData["createdDate"] as? Date {
                            character["createdDate"] = formatDate(createdDate)
                        } else if let createdDateString = characterData["createdDate"] as? String {
                            character["createdDate"] = createdDateString
                        } else {
                            character["createdDate"] = formatDate(Date())
                        }
                        
                        // 添加头像图片数据（base64编码）
                        if let avatarData = loadCharacterAvatar(characterId: characterId) {
                            character["avatarImageData"] = avatarData
                            print("✅ 已备份角色头像: \(characterId)")
                        }
                        
                        characters.append(character)
                    }
                }
            } catch {
                print("⚠️ 解析 CustomCharactersData 失败: \(error)")
            }
        }
        
        // 方法2: 从 custom_character_ 前缀的键获取（旧格式，兼容性）
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let characterKeys = allKeys.filter { $0.hasPrefix("custom_character_") && !$0.contains("restored_") }
        
        for key in characterKeys {
            if let characterData = userDefaults.dictionary(forKey: key) {
                    // 检查是否已经在方法1中添加过（通过ID匹配）
                    let characterId = characterData["id"] as? String ?? UUID().uuidString
                    if !characters.contains(where: { ($0["id"] as? String) == characterId }) {
                        var character: [String: Any] = [
                            "id": characterId,
                    "name": characterData["name"] as? String ?? "未命名角色",
                    "description": characterData["description"] as? String ?? "",
                    "personality": characterData["personality"] as? String ?? "",
                            "avatar": characterData["avatar"] as? String ?? "",
                    "createdDate": formatDate(characterData["createdDate"] as? Date ?? Date())
                ]
                        
                        // 添加头像图片数据（base64编码）
                        if let avatarData = loadCharacterAvatar(characterId: characterId) {
                            character["avatarImageData"] = avatarData
                            print("✅ 已备份角色头像: \(characterId)")
                        }
                        
                        // 添加其他可能存在的字段
                        if let achievements = characterData["achievements"] as? [String] {
                            character["achievements"] = achievements
                        }
                        if let mainWorks = characterData["mainWorks"] as? [String] {
                            character["mainWorks"] = mainWorks
                        }
                        if let background = characterData["background"] as? String {
                            character["background"] = background
                        }
                        
                        characters.append(character)
                    }
            }
        }
        
        return characters.sorted { 
            ($0["createdDate"] as? String ?? "") > ($1["createdDate"] as? String ?? "")
        }
    }
    
    /// 加载帖子图片数据（base64编码）
    private func loadPostImage(imageId: String) -> String? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ [备份] 无法获取Documents目录")
            return nil
        }
        
        // 图片保存在 PostImages/ 子目录中（与ImageManager保持一致）
        // 路径格式：Documents/PostImages/{id}.jpg
        let imagePath = documentsDirectory.appendingPathComponent("PostImages/\(imageId).jpg")
        
        // 检查文件是否存在
        if fileManager.fileExists(atPath: imagePath.path) {
            print("✅ [备份] 找到帖子图片文件: PostImages/\(imageId).jpg")
            return loadImageFromURL(imagePath)
        }
        
        // 如果PostImages目录下没有，尝试直接在Documents目录下查找（兼容旧格式）
        let alternativePath = documentsDirectory.appendingPathComponent("\(imageId).jpg")
        if fileManager.fileExists(atPath: alternativePath.path) {
            print("✅ [备份] 找到帖子图片文件（旧格式）: \(imageId).jpg")
            return loadImageFromURL(alternativePath)
        }
        
        print("⚠️ [备份] 帖子图片文件不存在: PostImages/\(imageId).jpg 或 \(imageId).jpg")
        return nil
    }
    
    /// 从URL加载图片并转换为base64
    private func loadImageFromURL(_ url: URL) -> String? {
        // 读取图片数据
        guard let imageData = try? Data(contentsOf: url) else {
            print("⚠️ [备份] 无法读取图片文件: \(url.path)")
            return nil
        }
        
        // 转换为base64编码
        let base64String = imageData.base64EncodedString()
        print("✅ [备份] 成功加载图片: \(url.lastPathComponent), 大小: \(imageData.count) bytes")
        return base64String
    }
    
    /// 加载角色头像图片数据（base64编码）
    private func loadCharacterAvatar(characterId: String) -> String? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ [备份] 无法获取Documents目录")
            return nil
        }
        
        let avatarURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: avatarURL.path) else {
            print("⚠️ [备份] 头像文件不存在: \(avatarURL.path)")
            return nil
        }
        
        // 读取图片数据
        guard let imageData = try? Data(contentsOf: avatarURL) else {
            print("⚠️ [备份] 无法读取头像文件: \(avatarURL.path)")
            return nil
        }
        
        // 转换为base64编码
        let base64String = imageData.base64EncodedString()
        print("✅ [备份] 成功加载头像: \(characterId), 大小: \(imageData.count) bytes, base64长度: \(base64String.count)")
        return base64String
    }
    
    /// 获取私聊对话数据
    private func getConversationsData(modelContext: ModelContext?) -> [String: Any]? {
        guard let modelContext = modelContext else {
            print("⚠️ [备份] ModelContext不可用，跳过私聊对话备份")
            return nil
        }
        
        do {
            // 获取所有对话
            let conversationDescriptor = FetchDescriptor<SDConversation>(
                sortBy: [SortDescriptor(\.lastMessageTime, order: .reverse)]
            )
            let conversations = try modelContext.fetch(conversationDescriptor)
            
            // 获取所有消息
            let messageDescriptor = FetchDescriptor<Message>(
                sortBy: [SortDescriptor(\.timestamp)]
            )
            let allMessages = try modelContext.fetch(messageDescriptor)
            
            // 按对话分组消息
            var conversationsData: [[String: Any]] = []
            for conversation in conversations {
                let messages = allMessages.filter { $0.conversationId == conversation.id }
                
                let messagesData = messages.map { message in
                    [
                        "id": message.id,
                        "content": message.content,
                        "isFromUser": message.isFromUser,
                        "timestamp": formatFullDate(message.timestamp) ?? "",
                        "isRead": message.isRead,
                        "tags": message.tags
                    ] as [String: Any]
                }
                
                // 获取角色名称
                let characterName = CharacterDataManager.shared.getName(for: conversation.characterId) ?? conversation.characterId
                
                conversationsData.append([
                    "id": conversation.id,
                    "characterId": conversation.characterId,
                    "characterName": characterName,
                    "lastMessageContent": conversation.lastMessageContent,
                    "lastMessageTime": formatFullDate(conversation.lastMessageTime) ?? "",
                    "messageCount": conversation.messageCount,
                    "createdAt": formatFullDate(conversation.createdAt) ?? "",
                    "messages": messagesData
                ])
            }
            
            return [
                "conversations": conversationsData,
                "totalConversations": conversationsData.count,
                "totalMessages": allMessages.count
            ]
        } catch {
            print("❌ [备份] 获取私聊对话数据失败: \(error)")
            return nil
        }
    }
    
    /// 获取多人对话数据
    private func getMultiPersonChatData(modelContext: ModelContext?) -> [String: Any]? {
        guard let modelContext = modelContext else {
            print("⚠️ [备份] ModelContext不可用，跳过多人对话备份")
            return nil
        }
        
        do {
            // 获取所有多人对话会话
            let sessionDescriptor = FetchDescriptor<MultiPersonChatSession>(
                sortBy: [SortDescriptor(\.lastActiveTime, order: .reverse)]
            )
            let sessions = try modelContext.fetch(sessionDescriptor)
            
            // 获取所有多人对话消息
            let messageDescriptor = FetchDescriptor<MultiPersonChatMessage>(
                sortBy: [SortDescriptor(\.timestamp)]
            )
            let allMessages = try modelContext.fetch(messageDescriptor)
            
            // 按会话分组消息
            var sessionsData: [[String: Any]] = []
            for session in sessions {
                let messages = allMessages.filter { $0.sessionId == session.id }
                
                let messagesData = messages.map { message in
                    [
                        "id": message.id,
                        "content": message.content,
                        "characterId": message.characterId,
                        "characterName": message.characterName,
                        "isUserMessage": message.isUserMessage,
                        "messageType": message.messageType,
                        "timestamp": formatFullDate(message.timestamp) ?? ""
                    ] as [String: Any]
                }
                
                sessionsData.append([
                    "id": session.id,
                    "topic": session.topic,
                    "participantIds": session.participantIds,
                    "participantNames": session.participantNames,
                    "chatMode": session.chatMode,
                    "chatTheme": session.chatTheme,
                    "userRole": session.userRole,
                    "messageCount": session.messageCount,
                    "lastActiveTime": formatFullDate(session.lastActiveTime) ?? "",
                    "createdAt": formatFullDate(session.createdAt) ?? "",
                    "isCompleted": session.isCompleted,
                    "messages": messagesData
                ])
            }
            
            return [
                "sessions": sessionsData,
                "totalSessions": sessionsData.count,
                "totalMessages": allMessages.count
            ]
        } catch {
            print("❌ [备份] 获取多人对话数据失败: \(error)")
            return nil
        }
    }
    
    /// 计算成为会员的天数
    private func calculateMemberDays() -> Int {
        let creationDate = AppAccountManager.shared.accountCreationDate
        let daysBetween = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day ?? 0
        return max(daysBetween, 1) // 至少1天
    }
    
    /// 计算次元对话数（用户发送的消息总数）
    private func calculateDialogueCount() -> Int {
        // 从SwiftData中获取用户发送的消息数量
        // 注意：这里需要ModelContext，但UserDataManager没有，所以暂时返回0
        // 实际应该从ProfileView或通过依赖注入获取
        // 为了简化，我们可以从PostViewModel统计互动
        let posts = PostViewModel.shared.posts
        let userPosts = posts.filter { isUserCreatedPost($0) }
        // 简单估算：用户帖子数 + 评论数
        let userComments = posts.flatMap { $0.comments }.filter { !$0.isVirtualCharacter }
        return userPosts.count + userComments.count
    }
    
    /// 计算探索天数（从最早的活动时间到现在）
    private func calculateExplorationDays() -> Int {
        let posts = PostViewModel.shared.posts
        let earliestDate: Date? = posts.map { $0.datePosted }.min()
        
        // 如果没有任何数据，返回0天
        guard let startDate = earliestDate else {
            return 0
        }
        
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(days, 1) // 至少返回1天（如果有数据的话）
    }
    
    /// 格式化日期为易读格式
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化日期为完整格式（包含时间）
    private func formatFullDate(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 获取成就系统数据
    private func getAchievementsData() -> [String: Any] {
        let evaluator = AchievementEvaluator.shared
        
        // 获取所有成就数据
        let achievementsList = evaluator.achievements.map { achievement in
            [
                "id": achievement.id,
                "name": achievement.name,
                "description": achievement.description,
                "icon": achievement.icon,
                "type": achievement.type.rawValue,
                "currentProgress": achievement.currentProgress,
                "targetProgress": achievement.targetProgress,
                "level": achievement.level.rawValue,
                "isUnlocked": achievement.isUnlocked,
                "unlockedAt": formatFullDate(achievement.unlockedAt) ?? "",
                "isPinned": achievement.isPinned,
                "progressPercentage": achievement.progressPercentage
            ] as [String: Any]
        }
        
        // 获取固定的成就ID列表
        let pinnedAchievements = UserDefaults.standard.stringArray(forKey: "PinnedAchievements") ?? []
        
        return [
            "achievements": achievementsList,
            "pinnedAchievementIds": pinnedAchievements,
            "totalCount": achievementsList.count,
            "unlockedCount": achievementsList.filter { ($0["isUnlocked"] as? Bool) == true }.count,
            "pinnedCount": pinnedAchievements.count
        ]
    }
    
    /// 统计用户项目数量
    func countUserItems() -> [String: Int] {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        return [
            "customCharacters": allKeys.filter { $0.hasPrefix("custom_character_") }.count,
            "chatSessions": allKeys.filter { $0.hasPrefix("chat_") }.count,
            "totalItems": allKeys.count
        ]
    }
    
    // MARK: - 数据恢复
    
    /// 恢复用户数据（从备份）
    /// - Parameter backupData: 备份数据
    /// - Parameter modelContext: SwiftData的ModelContext，用于恢复私聊和多人对话数据（可选）
    func restoreUserData(from backupData: [String: Any], modelContext: ModelContext? = nil) -> Bool {
        // 检查备份数据格式（account字段是可选的，因为新版本可能没有）
        guard let profileData = backupData["profile"] as? [String: Any] else {
            print("❌ 备份数据格式无效：缺少 profile 字段")
            print("📋 备份数据包含的字段: \(backupData.keys.joined(separator: ", "))")
            return false
        }
        
        print("📥 [恢复] 开始恢复用户数据...")
        
        // 恢复用户资料
        let userDefaults = UserDefaults.standard
        
        // 兼容新旧版本的字段名
        if let username = profileData["username"] as? String {
            userDefaults.set(username, forKey: "user_profile_username")
            print("✅ [恢复] 用户名: \(username)")
        } else if let nickname = profileData["nickname"] as? String {
            userDefaults.set(nickname, forKey: "user_profile_username")
            print("✅ [恢复] 用户名: \(nickname)")
        }
        
        if let signature = profileData["personalSignature"] as? String {
            userDefaults.set(signature, forKey: "user_profile_personal_signature")
            print("✅ [恢复] 个人签名")
        } else if let signature = profileData["signature"] as? String {
            userDefaults.set(signature, forKey: "user_profile_personal_signature")
            print("✅ [恢复] 个人签名")
        }
        
        if let avatarName = profileData["avatarImageName"] as? String {
            userDefaults.set(avatarName, forKey: "user_profile_avatar_name")
            print("✅ [恢复] 头像")
        }
        
        // 恢复等级和经验（累加而不是覆盖）
        let currentLevel = userDefaults.integer(forKey: "user_profile_level")
        let currentExperience = userDefaults.integer(forKey: "user_profile_experience")
        
        if let backupLevel = profileData["userLevel"] as? Int {
            // 取两者中的较大值（等级不应该降低）
            let newLevel = max(currentLevel, backupLevel)
            userDefaults.set(newLevel, forKey: "user_profile_level")
            print("✅ [恢复] 等级: 当前 \(currentLevel) + 备份 \(backupLevel) = 最终 \(newLevel)")
        } else if let backupLevel = profileData["level"] as? Int {
            let newLevel = max(currentLevel, backupLevel)
            userDefaults.set(newLevel, forKey: "user_profile_level")
            print("✅ [恢复] 等级: 当前 \(currentLevel) + 备份 \(backupLevel) = 最终 \(newLevel)")
        }
        
        if let backupExperience = profileData["userExperience"] as? Int {
            // 累加经验值
            let newExperience = currentExperience + backupExperience
            userDefaults.set(newExperience, forKey: "user_profile_experience")
            print("✅ [恢复] 经验值: 当前 \(currentExperience) + 备份 \(backupExperience) = 最终 \(newExperience)")
        } else if let backupExperience = profileData["experience"] as? Int {
            let newExperience = currentExperience + backupExperience
            userDefaults.set(newExperience, forKey: "user_profile_experience")
            print("✅ [恢复] 经验值: 当前 \(currentExperience) + 备份 \(backupExperience) = 最终 \(newExperience)")
        }
        
        // 恢复自定义角色
        if let myCreations = backupData["myCreations"] as? [String: Any],
           let characters = myCreations["customCharacters"] as? [[String: Any]] {
            restoreCustomCharacters(characters)
        }
        
        // 恢复成就系统数据
        if let achievementsData = backupData["achievements"] as? [String: Any] {
            restoreAchievementsData(from: achievementsData)
        }
        
        // 恢复帖子数据
        if let myCreations = backupData["myCreations"] as? [String: Any],
           let posts = myCreations["posts"] as? [[String: Any]] {
            restorePostImages(posts: posts)
            restorePostsData(posts: posts)
        }
        
        // 恢复私聊对话数据
        if let conversationsData = backupData["conversations"] as? [String: Any] {
            restoreConversationsData(from: conversationsData, modelContext: modelContext)
        }
        
        // 恢复多人对话数据
        if let multiChatData = backupData["multiPersonChats"] as? [String: Any] {
            restoreMultiPersonChatData(from: multiChatData, modelContext: modelContext)
        }
        
        // 恢复点赞记录
        if let likesData = backupData["likes"] as? [[String: Any]] {
            restoreLikesData(likes: likesData)
        }
        
        // 恢复关注角色
        if let followedData = backupData["followedCharacters"] {
            restoreFollowedCharacters(from: followedData)
        } else if let legacyFavorites = backupData["favoriteCharacters"] as? [String] {
            restoreFollowedCharacters(from: legacyFavorites)
        }
        
        print("📥 用户数据恢复完成")
        return true
    }
    
    /// 恢复成就系统数据
    private func restoreAchievementsData(from achievementsData: [String: Any]) {
        let evaluator = AchievementEvaluator.shared
        var restoredCount = 0
        var pinnedCount = 0
        
        // 恢复成就列表
        if let achievementsList = achievementsData["achievements"] as? [[String: Any]] {
            for achievementData in achievementsList {
                guard let id = achievementData["id"] as? String else { continue }
                
                // 查找对应的成就
                if let index = evaluator.achievements.firstIndex(where: { $0.id == id }) {
                    let currentProgress = achievementData["currentProgress"] as? Int ?? 0
                    let targetProgress = achievementData["targetProgress"] as? Int ?? 0
                    let levelString = achievementData["level"] as? String ?? "青铜"
                    let level = AchievementLevel(rawValue: levelString) ?? .bronze
                    let isUnlocked = achievementData["isUnlocked"] as? Bool ?? false
                    let unlockedAtString = achievementData["unlockedAt"] as? String
                    let unlockedAt = parseFullDate(unlockedAtString)
                    let isPinned = achievementData["isPinned"] as? Bool ?? false
                    
                    // 更新成就数据
                    let original = evaluator.achievements[index]
                    evaluator.achievements[index] = CYAchievement(
                        id: original.id,
                        name: original.name,
                        description: original.description,
                        icon: original.icon,
                        type: original.type,
                        currentProgress: currentProgress,
                        targetProgress: targetProgress,
                        level: level,
                        isUnlocked: isUnlocked,
                        unlockedAt: unlockedAt,
                        isPinned: isPinned
                    )
                    restoredCount += 1
                    if isPinned {
                        pinnedCount += 1
                    }
                }
            }
        }
        
        // 恢复固定的成就ID列表
        if let pinnedIds = achievementsData["pinnedAchievementIds"] as? [String] {
            UserDefaults.standard.set(pinnedIds, forKey: "PinnedAchievements")
            pinnedCount = pinnedIds.count
            // 注意：isPinned 状态已经在上面恢复成就数据时设置了
            // 这里只需要保存到 UserDefaults，下次启动时会自动刷新
        }
        
        // 触发UI更新
        DispatchQueue.main.async {
            evaluator.objectWillChange.send()
        }
        
        print("✅ 成就系统数据恢复完成")
        print("   - 恢复了 \(restoredCount) 个成就的进度")
        print("   - 恢复了 \(pinnedCount) 个固定成就")
    }
    
    /// 解析完整日期字符串
    private func parseFullDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.date(from: dateString)
    }
    
    /// 恢复自定义角色数据
    private func restoreCustomCharacters(_ characters: [[String: Any]]) {
        print("📥 [恢复] 开始恢复自定义角色，备份数据中有 \(characters.count) 个角色")
        
        let userDefaults = UserDefaults.standard
        
        // 加载现有的自定义角色列表
        var existingCharacters: [[String: Any]] = []
        if let data = userDefaults.data(forKey: "CustomCharactersData") {
            do {
                if let charactersArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    existingCharacters = charactersArray
                    print("📥 [恢复] 当前已有 \(existingCharacters.count) 个自定义角色")
                }
            } catch {
                print("⚠️ [恢复] 加载现有自定义角色失败: \(error)")
            }
        } else {
            print("📥 [恢复] 当前没有自定义角色")
        }
        
        // 将备份的角色添加到现有列表中（避免重复）
        var restoredAvatarCount = 0
        var newlyRestoredCount = 0
        var updatedCount = 0
        
        for characterData in characters {
            guard let characterId = characterData["id"] as? String else {
                print("⚠️ [恢复] 跳过无效的角色数据（缺少ID）")
                continue
            }
            
            // 检查是否已存在（通过ID匹配）
            if let existingIndex = existingCharacters.firstIndex(where: { ($0["id"] as? String) == characterId }) {
                // 角色已存在，但可能需要更新数据（使用备份中的完整数据）
                print("🔄 [恢复] 角色已存在，更新数据: \(characterData["name"] as? String ?? "未命名"), ID: \(characterId)")
                
                // 恢复头像图片文件（如果备份中有）
                if let avatarImageData = characterData["avatarImageData"] as? String {
                    saveCharacterAvatar(characterId: characterId, base64Data: avatarImageData)
                    restoredAvatarCount += 1
                    print("✅ [恢复] 已恢复角色头像: \(characterId)")
                }
                
                // 移除头像图片数据（不保存到UserDefaults，已单独保存为文件）
                var characterToSave: [String: Any] = [:]
                
                // 复制所有字段，但移除 avatarImageData
                for (key, value) in characterData {
                    if key != "avatarImageData" {
                        characterToSave[key] = value
                    }
                }
                
                // 确保 createdDate 格式正确
                if let createdDateString = characterToSave["createdDate"] as? String {
                    characterToSave["createdDate"] = createdDateString
                } else if let createdDate = characterToSave["createdDate"] as? Date {
                    characterToSave["createdDate"] = formatDate(createdDate)
                } else {
                    characterToSave["createdDate"] = formatDate(Date())
                }
                
                // 确保所有必要的字段都存在
                if characterToSave["id"] == nil {
                    characterToSave["id"] = characterId
                }
                if characterToSave["name"] == nil {
                    characterToSave["name"] = "未命名角色"
                }
                if characterToSave["description"] == nil && characterToSave["bio"] == nil {
                    characterToSave["bio"] = ""
                }
                if let description = characterToSave["description"] as? String, characterToSave["bio"] == nil {
                    characterToSave["bio"] = description
                }
                if let bio = characterToSave["bio"] as? String, characterToSave["description"] == nil {
                    characterToSave["description"] = bio
                }
                if characterToSave["personality"] == nil {
                    characterToSave["personality"] = ""
                }
                if characterToSave["avatar"] == nil {
                    characterToSave["avatar"] = ""
                }
                if characterToSave["era"] == nil {
                    characterToSave["era"] = ""
                }
                if characterToSave["profession"] == nil {
                    characterToSave["profession"] = ""
                }
                if characterToSave["category"] == nil {
                    characterToSave["category"] = "historical"
                }
                if characterToSave["achievements"] == nil {
                    characterToSave["achievements"] = []
                }
                if characterToSave["mainWorks"] == nil {
                    characterToSave["mainWorks"] = []
                }
                if characterToSave["region"] == nil {
                    characterToSave["region"] = ""
                }
                if characterToSave["universe"] == nil {
                    characterToSave["universe"] = ""
                }
                if characterToSave["famousQuotes"] == nil {
                    characterToSave["famousQuotes"] = []
                }
                
                // 更新现有角色数据
                existingCharacters[existingIndex] = characterToSave
                updatedCount += 1
                print("✅ [恢复] 已更新角色数据: \(characterToSave["name"] as? String ?? "未命名")")
            } else {
                // 新角色，添加到列表
                print("📥 [恢复] 恢复自定义角色: \(characterData["name"] as? String ?? "未命名"), ID: \(characterId)")
                
                // 恢复头像图片文件
                if let avatarImageData = characterData["avatarImageData"] as? String {
                    saveCharacterAvatar(characterId: characterId, base64Data: avatarImageData)
                    restoredAvatarCount += 1
                    print("✅ [恢复] 已恢复角色头像: \(characterId)")
                }
                
                // 移除头像图片数据（不保存到UserDefaults，已单独保存为文件）
                var characterToSave: [String: Any] = [:]
                
                // 复制所有字段，但移除 avatarImageData
                for (key, value) in characterData {
                    if key != "avatarImageData" {
                        characterToSave[key] = value
                    }
                }
                
                // 确保 createdDate 格式正确（如果是字符串，保持不变；如果是 Date，转换为字符串）
                if let createdDateString = characterToSave["createdDate"] as? String {
                    // 已经是字符串，保持不变
                    characterToSave["createdDate"] = createdDateString
                } else if let createdDate = characterToSave["createdDate"] as? Date {
                    // 如果是 Date，转换为字符串
                    characterToSave["createdDate"] = formatDate(createdDate)
                } else {
                    // 如果没有 createdDate，使用当前日期
                    characterToSave["createdDate"] = formatDate(Date())
                }
                
                // 确保所有必要的字段都存在（匹配 CreateCharacterView 中的字段）
                if characterToSave["id"] == nil {
                    characterToSave["id"] = characterId
                }
                if characterToSave["name"] == nil {
                    characterToSave["name"] = "未命名角色"
                }
                if characterToSave["description"] == nil && characterToSave["bio"] == nil {
                    characterToSave["bio"] = ""
                }
                // 兼容 description 和 bio 字段
                if let description = characterToSave["description"] as? String, characterToSave["bio"] == nil {
                    characterToSave["bio"] = description
                }
                if let bio = characterToSave["bio"] as? String, characterToSave["description"] == nil {
                    characterToSave["description"] = bio
                }
                if characterToSave["personality"] == nil {
                    characterToSave["personality"] = ""
                }
                if characterToSave["avatar"] == nil {
                    characterToSave["avatar"] = ""
                }
                
                // 确保其他字段存在（匹配 CreateCharacterView 的保存格式）
                if characterToSave["era"] == nil {
                    characterToSave["era"] = ""
                }
                if characterToSave["profession"] == nil {
                    characterToSave["profession"] = ""
                }
                if characterToSave["category"] == nil {
                    characterToSave["category"] = "historical"
                }
                if characterToSave["achievements"] == nil {
                    characterToSave["achievements"] = []
                }
                if characterToSave["mainWorks"] == nil {
                    characterToSave["mainWorks"] = []
                }
                if characterToSave["region"] == nil {
                    characterToSave["region"] = ""
                }
                if characterToSave["universe"] == nil {
                    characterToSave["universe"] = ""
                }
                if characterToSave["famousQuotes"] == nil {
                    characterToSave["famousQuotes"] = []
                }
                
                print("📥 [恢复] 准备保存角色: \(characterToSave["name"] as? String ?? "未命名"), ID: \(characterId)")
                print("📋 [恢复] 角色字段: \(characterToSave.keys.joined(separator: ", "))")
                print("📋 [恢复] 关键字段检查: name=\(characterToSave["name"] != nil), bio=\(characterToSave["bio"] != nil), avatar=\(characterToSave["avatar"] != nil), era=\(characterToSave["era"] != nil), profession=\(characterToSave["profession"] != nil), category=\(characterToSave["category"] != nil)")
                existingCharacters.append(characterToSave)
                newlyRestoredCount += 1
            }
        }
        
        // 保存更新后的角色列表
        do {
            let data = try JSONSerialization.data(withJSONObject: existingCharacters, options: [])
            userDefaults.set(data, forKey: "CustomCharactersData")
            
            // 同步保存，确保数据立即写入
            userDefaults.synchronize()
            
            print("✅ [恢复] 自定义角色恢复完成: 恢复了 \(newlyRestoredCount) 个新角色，更新了 \(updatedCount) 个现有角色（共 \(existingCharacters.count) 个）")
            if restoredAvatarCount > 0 {
                print("   - 恢复了 \(restoredAvatarCount) 个头像文件")
            }
            
            // 验证保存是否成功
            if let verifyData = userDefaults.data(forKey: "CustomCharactersData"),
               let verifyArray = try? JSONSerialization.jsonObject(with: verifyData) as? [[String: Any]] {
                print("✅ [恢复] 验证保存成功: UserDefaults中有 \(verifyArray.count) 个角色")
            } else {
                print("⚠️ [恢复] 验证保存失败: 无法读取保存的数据")
            }
            
            // 发送通知，让UI刷新自定义角色列表
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("CustomCharactersRestored"), object: nil)
            }
        } catch {
            print("❌ [恢复] 保存恢复的自定义角色失败: \(error)")
            print("   错误详情: \(error.localizedDescription)")
        }
    }
    
    /// 保存角色头像图片文件
    private func saveCharacterAvatar(characterId: String, base64Data: String) {
        guard let imageData = Data(base64Encoded: base64Data) else {
            print("⚠️ 无法解码base64头像数据: \(characterId)")
            return
        }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ 无法获取Documents目录")
            return
        }
        
        let avatarURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
        
        do {
            // 确保目录存在
            let directoryURL = avatarURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }
            
            // 写入图片数据
            try imageData.write(to: avatarURL)
            print("✅ 头像恢复成功: \(avatarURL.lastPathComponent)")
        } catch {
            print("❌ 保存头像文件失败: \(error.localizedDescription)")
        }
    }
    
    /// 恢复帖子图片
    private func restorePostImages(posts: [[String: Any]]) {
        var restoredCount = 0
        
        for post in posts {
            guard let postImages = post["postImages"] as? [[String: Any]] else {
                continue
            }
            
            for imageData in postImages {
                guard let imageId = imageData["id"] as? String,
                      let base64Data = imageData["imageData"] as? String else {
                    continue
                }
                
                // 恢复图片文件
                savePostImage(imageId: imageId, base64Data: base64Data)
                restoredCount += 1
            }
        }
        
        if restoredCount > 0 {
            print("✅ 帖子图片恢复完成: 恢复了 \(restoredCount) 张图片")
        }
    }
    
    /// 保存帖子图片文件
    private func savePostImage(imageId: String, base64Data: String) {
        guard let imageData = Data(base64Encoded: base64Data) else {
            print("⚠️ 无法解码base64帖子图片数据: \(imageId)")
            return
        }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ 无法获取Documents目录")
            return
        }
        
        // 图片保存在 PostImages/ 子目录中（与ImageManager保持一致）
        let imageDirectory = documentsDirectory.appendingPathComponent("PostImages")
        let imageURL = imageDirectory.appendingPathComponent("\(imageId).jpg")
        
        do {
            // 确保PostImages目录存在
            if !fileManager.fileExists(atPath: imageDirectory.path) {
                try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            }
            
            // 写入图片数据
            try imageData.write(to: imageURL)
            print("✅ 帖子图片恢复成功: PostImages/\(imageId).jpg")
        } catch {
            print("❌ 保存帖子图片文件失败: \(error.localizedDescription)")
        }
    }
    
    /// 恢复帖子数据到PostViewModel
    private func restorePostsData(posts: [[String: Any]]) {
        print("📥 [恢复] 开始恢复帖子数据，共 \(posts.count) 条")
        
        // 先加载现有的帖子数据（合并而不是覆盖）
        var existingUserPosts: [UserPostModel] = []
        var existingAIPosts: [UserPostModel] = []
        
        // 加载现有用户帖子
        if let userPostsData = UserDefaults.standard.data(forKey: "UserPosts_v1") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                existingUserPosts = try decoder.decode([UserPostModel].self, from: userPostsData)
                print("📥 [恢复] 当前已有 \(existingUserPosts.count) 条用户帖子")
            } catch {
                print("⚠️ [恢复] 加载现有用户帖子失败: \(error)")
            }
        }
        
        // 加载现有AI帖子
        if let aiPostsData = UserDefaults.standard.data(forKey: "AIPosts_v1") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                existingAIPosts = try decoder.decode([UserPostModel].self, from: aiPostsData)
                print("📥 [恢复] 当前已有 \(existingAIPosts.count) 条AI帖子")
            } catch {
                print("⚠️ [恢复] 加载现有AI帖子失败: \(error)")
            }
        }
        
        var restoredUserPosts: [UserPostModel] = []
        var restoredAIPosts: [UserPostModel] = []
        
        for postData in posts {
            guard let idString = postData["id"] as? String,
                  let uuid = UUID(uuidString: idString),
                  let content = postData["content"] as? String,
                  let username = postData["username"] as? String else {
                print("⚠️ [恢复] 跳过无效的帖子数据")
                continue
            }
            
            // 检查是否已存在（通过ID匹配）
            let alreadyExists = existingUserPosts.contains(where: { $0.id == uuid }) || 
                               existingAIPosts.contains(where: { $0.id == uuid })
            
            if alreadyExists {
                print("⏩ [恢复] 帖子已存在，跳过: \(uuid)")
                continue
            }
            
            // 解析日期
            let dateString = postData["date"] as? String ?? ""
            let date = parseFullDate(dateString) ?? Date()
            
            // 解析其他字段
            let likes = postData["likes"] as? Int ?? 0
            let contentType = postData["type"] as? String
            let source = postData["source"] as? String
            let characterID = postData["characterID"] as? String
            let isUserPost = postData["isUserPost"] as? Bool ?? false
            
            // 解析图片
            let images = postData["images"] as? [String] ?? []
            
            // 解析头像（优先从备份数据中获取）
            var userAvatar = postData["userAvatar"] as? String
            
            // 如果没有备份头像，根据帖子类型设置
            if userAvatar == nil {
                if isUserPost {
                    // 用户帖子：使用用户头像
                    let avatarName = UserDefaults.standard.string(forKey: "user_profile_avatar_name") ?? "default_avatar"
                    userAvatar = avatarName
                } else if let characterID = characterID, !characterID.isEmpty {
                    // 角色帖子：使用角色头像
                    // 使用CharacterAvatarService获取角色头像
                    let avatarName = CharacterAvatarService.shared.getAvatarName(for: characterID)
                    // 如果返回的头像名称不为空，使用它；否则使用角色ID
                    if !avatarName.isEmpty {
                        userAvatar = avatarName
                    } else {
                        // 如果找不到角色头像，尝试使用角色ID
                        userAvatar = characterID.lowercased()
                    }
                } else {
                    // 其他情况使用默认头像
                    userAvatar = "person.circle.fill"
                }
            }
            
            // 解析评论
            var comments: [DetailedCommentModel] = []
            if let commentsData = postData["comments"] as? [[String: Any]] {
                comments = restoreCommentsData(from: commentsData)
            }
            
            // 解析点赞和收藏状态
            let isLikedByCurrentUser = postData["isLikedByCurrentUser"] as? Bool ?? false
            let isBookmarkedByCurrentUser = postData["isBookmarkedByCurrentUser"] as? Bool ?? false
            
            // 创建UserPostModel
            let post = UserPostModel(
                id: uuid,
                username: username,
                userAvatar: userAvatar ?? "person.circle.fill",
                content: content,
                images: images,
                datePosted: date,
                likes: likes,
                comments: comments,
                isLikedByCurrentUser: isLikedByCurrentUser,
                isBookmarkedByCurrentUser: isBookmarkedByCurrentUser,
                contentType: contentType,
                characterID: characterID,
                source: source
            )
            
            // 根据来源分类
            if isUserPost {
                restoredUserPosts.append(post)
            } else {
                restoredAIPosts.append(post)
            }
        }
        
        // 合并现有帖子和恢复的帖子
        let mergedUserPosts = existingUserPosts + restoredUserPosts
        let mergedAIPosts = existingAIPosts + restoredAIPosts
        
        // 按时间排序（最新的在前）
        let sortedUserPosts = mergedUserPosts.sorted { $0.datePosted > $1.datePosted }
        let sortedAIPosts = mergedAIPosts.sorted { $0.datePosted > $1.datePosted }
        
        // 保存合并并排序后的帖子到UserDefaults
        if !sortedUserPosts.isEmpty {
            savePostsToUserDefaults(posts: sortedUserPosts, key: "UserPosts_v1")
            print("✅ [恢复] 用户帖子合并完成: 原有 \(existingUserPosts.count) 条 + 恢复 \(restoredUserPosts.count) 条 = 共 \(sortedUserPosts.count) 条（已按时间排序）")
        }
        
        if !sortedAIPosts.isEmpty {
            savePostsToUserDefaults(posts: sortedAIPosts, key: "AIPosts_v1")
            print("✅ [恢复] AI帖子合并完成: 原有 \(existingAIPosts.count) 条 + 恢复 \(restoredAIPosts.count) 条 = 共 \(sortedAIPosts.count) 条（已按时间排序）")
        }
        
        // 通知PostViewModel重新加载
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("PostsDataRestored"), object: nil)
        }
    }
    
    /// 将帖子保存到UserDefaults
    private func savePostsToUserDefaults(posts: [UserPostModel], key: String) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(posts)
            UserDefaults.standard.set(data, forKey: key)
            print("✅ [恢复] 帖子已保存到UserDefaults: \(key)")
        } catch {
            print("❌ [恢复] 保存帖子到UserDefaults失败: \(error)")
        }
    }
    
    /// 恢复评论数据
    private func restoreCommentsData(from commentsData: [[String: Any]]) -> [DetailedCommentModel] {
        var comments: [DetailedCommentModel] = []
        
        for commentData in commentsData {
            guard let idString = commentData["id"] as? String,
                  let uuid = UUID(uuidString: idString),
                  let username = commentData["username"] as? String,
                  let content = commentData["content"] as? String else {
                continue
            }
            
            let userAvatar = commentData["userAvatar"] as? String ?? "person.circle.fill"
            let likes = commentData["likes"] as? Int ?? 0
            let dateString = commentData["date"] as? String ?? ""
            let date = parseFullDate(dateString) ?? Date()
            let isLiked = commentData["isLiked"] as? Bool ?? false
            let isVirtualCharacter = commentData["isVirtualCharacter"] as? Bool ?? false
            let characterID = commentData["characterID"] as? String
            
            // 递归恢复回复
            var replies: [DetailedCommentModel] = []
            if let repliesData = commentData["replies"] as? [[String: Any]] {
                replies = restoreCommentsData(from: repliesData)
            }
            
            let comment = DetailedCommentModel(
                id: uuid,
                username: username,
                userAvatar: userAvatar,
                content: content,
                datePosted: date,
                isVirtualCharacter: isVirtualCharacter,
                characterID: characterID,
                replies: replies,
                likes: likes,
                isLikedByCurrentUser: isLiked
            )
            
            comments.append(comment)
        }
        
        return comments
    }
    
    /// 恢复私聊对话数据
    private func restoreConversationsData(from conversationsData: [String: Any], modelContext: ModelContext?) {
        guard let modelContext = modelContext else {
            if let conversations = conversationsData["conversations"] as? [[String: Any]] {
                print("⚠️ [恢复] 检测到 \(conversations.count) 个私聊对话，但ModelContext不可用，跳过恢复")
            }
            return
        }
        
        guard let conversations = conversationsData["conversations"] as? [[String: Any]] else {
            print("⚠️ [恢复] 私聊对话数据格式无效：缺少 conversations 字段")
            print("📋 [恢复] 私聊对话数据包含的字段: \(conversationsData.keys.joined(separator: ", "))")
            return
        }
        
        print("📥 [恢复] 开始恢复 \(conversations.count) 个私聊对话")
        var restoredConversations = 0
        var restoredMessages = 0
        
        // 获取当前用户ID
        let currentUserId = AppAccountManager.shared.appAccountToken
        
        for conversationData in conversations {
            guard let conversationId = conversationData["id"] as? String,
                  let characterId = conversationData["characterId"] as? String,
                  let messagesData = conversationData["messages"] as? [[String: Any]] else {
                continue
            }
            
            // 恢复消息（先按时间排序，确保消息顺序正确）
            let sortedMessagesData = messagesData.sorted { (msg1, msg2) -> Bool in
                let timestamp1String = msg1["timestamp"] as? String ?? ""
                let timestamp2String = msg2["timestamp"] as? String ?? ""
                let timestamp1 = parseFullDate(timestamp1String) ?? Date()
                let timestamp2 = parseFullDate(timestamp2String) ?? Date()
                return timestamp1 < timestamp2 // 按时间升序排列
            }
            
            // 检查对话是否已存在
            let fetchDescriptor = FetchDescriptor<SDConversation>(
                predicate: #Predicate { $0.id == conversationId }
            )
            
            let existingConversations = try? modelContext.fetch(fetchDescriptor)
            let existingConversation = existingConversations?.first
            
            if let existing = existingConversation {
                // 对话已存在，合并消息（只添加不存在的消息）
                print("🔄 [恢复] 对话已存在，合并消息: \(conversationId)")
                
                // 获取现有消息ID列表
                let existingMessagesDescriptor = FetchDescriptor<Message>(
                    predicate: #Predicate { $0.conversationId == conversationId }
                )
                let existingMessages = try? modelContext.fetch(existingMessagesDescriptor)
                let existingMessageIds = Set(existingMessages?.map { $0.id } ?? [])
                
                var newMessageCount = 0
                var latestMessageTime = existing.lastMessageTime
                var latestMessageContent = existing.lastMessageContent
                
                for messageData in sortedMessagesData {
                    guard let messageId = messageData["id"] as? String,
                          let content = messageData["content"] as? String else {
                        continue
                    }
                    
                    // 检查消息是否已存在
                    if existingMessageIds.contains(messageId) {
                        print("⏩ [恢复] 消息已存在，跳过: \(messageId)")
                        continue
                    }
                    
                    let isFromUser = messageData["isFromUser"] as? Bool ?? false
                    let timestampString = messageData["timestamp"] as? String ?? ""
                    let timestamp = parseFullDate(timestampString) ?? Date()
                    let isRead = messageData["isRead"] as? Bool ?? false
                    let tags = messageData["tags"] as? [String] ?? []
                    
                    // 更新最新消息时间和内容
                    if timestamp > latestMessageTime {
                        latestMessageTime = timestamp
                        latestMessageContent = content
                    }
                    
                    // 设置发送者和接收者ID
                    let senderId = isFromUser ? currentUserId : characterId
                    let receiverId = isFromUser ? characterId : currentUserId
                    
                    let message = Message(
                        id: messageId,
                        conversationId: conversationId,
                        senderId: senderId,
                        receiverId: receiverId,
                        content: content,
                        isFromUser: isFromUser,
                        timestamp: timestamp,
                        isRead: isRead,
                        tags: tags
                    )
                    
                    modelContext.insert(message)
                    restoredMessages += 1
                    newMessageCount += 1
                }
                
                // 更新对话信息
                existing.lastMessageContent = latestMessageContent
                existing.lastMessageTime = latestMessageTime
                existing.messageCount = (existingMessages?.count ?? 0) + newMessageCount
                existing.updatedAt = latestMessageTime
                
                print("✅ [恢复] 对话已更新: 新增 \(newMessageCount) 条消息")
            } else {
                // 创建新对话
                let lastMessageContent = conversationData["lastMessageContent"] as? String ?? ""
                let lastMessageTimeString = conversationData["lastMessageTime"] as? String ?? ""
                let lastMessageTime = parseFullDate(lastMessageTimeString) ?? Date()
                let messageCount = sortedMessagesData.count
                let createdAtString = conversationData["createdAt"] as? String ?? ""
                let createdAt = parseFullDate(createdAtString) ?? Date()
                
                let conversation = SDConversation(
                    id: conversationId,
                    characterId: characterId,
                    userId: currentUserId,
                    lastMessageContent: lastMessageContent,
                    lastMessageTime: lastMessageTime,
                    messageCount: messageCount,
                    createdAt: createdAt,
                    updatedAt: lastMessageTime
                )
                
                modelContext.insert(conversation)
                
                // 恢复消息
                for messageData in sortedMessagesData {
                    guard let messageId = messageData["id"] as? String,
                          let content = messageData["content"] as? String else {
                        continue
                    }
                    
                    let isFromUser = messageData["isFromUser"] as? Bool ?? false
                    let timestampString = messageData["timestamp"] as? String ?? ""
                    let timestamp = parseFullDate(timestampString) ?? Date()
                    let isRead = messageData["isRead"] as? Bool ?? false
                    let tags = messageData["tags"] as? [String] ?? []
                    
                    // 设置发送者和接收者ID
                    let senderId = isFromUser ? currentUserId : characterId
                    let receiverId = isFromUser ? characterId : currentUserId
                    
                    let message = Message(
                        id: messageId,
                        conversationId: conversationId,
                        senderId: senderId,
                        receiverId: receiverId,
                        content: content,
                        isFromUser: isFromUser,
                        timestamp: timestamp,
                        isRead: isRead,
                        tags: tags
                    )
                    
                    modelContext.insert(message)
                    restoredMessages += 1
                }
                
                restoredConversations += 1
            }
        }
        
        // 保存更改
        do {
            try modelContext.save()
            print("✅ [恢复] 私聊对话恢复完成: \(restoredConversations) 个对话, \(restoredMessages) 条消息")
            
            // 发送通知，让UI刷新私聊对话列表
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("ConversationsRestored"), object: nil)
            }
        } catch {
            print("❌ [恢复] 保存私聊对话失败: \(error)")
            print("   错误详情: \(error.localizedDescription)")
        }
    }
    
    /// 恢复多人对话数据
    private func restoreMultiPersonChatData(from multiChatData: [String: Any], modelContext: ModelContext?) {
        guard let modelContext = modelContext else {
            if let sessions = multiChatData["sessions"] as? [[String: Any]] {
                print("⚠️ [恢复] 检测到 \(sessions.count) 个多人对话会话，但ModelContext不可用，跳过恢复")
            }
            return
        }
        
        guard let sessions = multiChatData["sessions"] as? [[String: Any]] else {
            print("⚠️ [恢复] 多人对话数据格式无效：缺少 sessions 字段")
            print("📋 [恢复] 多人对话数据包含的字段: \(multiChatData.keys.joined(separator: ", "))")
            return
        }
        
        print("📥 [恢复] 开始恢复 \(sessions.count) 个多人对话会话")
        var restoredSessions = 0
        var updatedSessions = 0
        var restoredMessages = 0
        
        for sessionData in sessions {
            guard let sessionId = sessionData["id"] as? String,
                  let topic = sessionData["topic"] as? String else {
                print("⚠️ [恢复] 跳过无效的多人对话会话数据")
                continue
            }
            
            // 解析参与者信息（可能为空）
            let participantIds = sessionData["participantIds"] as? [String] ?? []
            let participantNames = sessionData["participantNames"] as? [String] ?? []
            let messagesData = sessionData["messages"] as? [[String: Any]] ?? []
            
            print("📥 [恢复] 处理多人对话会话: \(topic), ID: \(sessionId), 消息数: \(messagesData.count)")
            
            // 恢复消息（先按时间排序，确保消息顺序正确）
            let sortedMessagesData = messagesData.sorted { (msg1, msg2) -> Bool in
                let timestamp1String = msg1["timestamp"] as? String ?? ""
                let timestamp2String = msg2["timestamp"] as? String ?? ""
                let timestamp1 = parseFullDate(timestamp1String) ?? Date()
                let timestamp2 = parseFullDate(timestamp2String) ?? Date()
                return timestamp1 < timestamp2 // 按时间升序排列
            }
            
            // 检查会话是否已存在
            let fetchDescriptor = FetchDescriptor<MultiPersonChatSession>(
                predicate: #Predicate { $0.id == sessionId }
            )
            
            let existingSessions = try? modelContext.fetch(fetchDescriptor)
            let existingSession = existingSessions?.first
            
            if let existing = existingSession {
                // 会话已存在，合并消息（只添加不存在的消息）
                print("🔄 [恢复] 会话已存在，合并消息: \(sessionId)")
                
                // 获取现有消息ID列表
                let existingMessagesDescriptor = FetchDescriptor<MultiPersonChatMessage>(
                    predicate: #Predicate<MultiPersonChatMessage> { message in
                        message.sessionId == sessionId
                    }
                )
                let existingMessages = try? modelContext.fetch(existingMessagesDescriptor)
                let existingMessageIds = Set(existingMessages?.map { $0.id } ?? [])
                
                var newMessageCount = 0
                var latestMessageTime = existing.lastActiveTime
                
                for messageData in sortedMessagesData {
                    guard let messageId = messageData["id"] as? String,
                          let characterId = messageData["characterId"] as? String,
                          let characterName = messageData["characterName"] as? String,
                          let content = messageData["content"] as? String else {
                        continue
                    }
                    
                    // 检查消息是否已存在
                    if existingMessageIds.contains(messageId) {
                        print("⏩ [恢复] 多人对话消息已存在，跳过: \(messageId)")
                        continue
                    }
                    
                    let timestampString = messageData["timestamp"] as? String ?? ""
                    let timestamp = parseFullDate(timestampString) ?? Date()
                    let isUserMessage = messageData["isUserMessage"] as? Bool ?? false
                    let messageType = messageData["messageType"] as? String ?? "text"
                    
                    // 更新最新消息时间
                    if timestamp > latestMessageTime {
                        latestMessageTime = timestamp
                    }
                    
                    let message = MultiPersonChatMessage(
                        id: messageId,
                        sessionId: sessionId,
                        characterId: characterId,
                        characterName: characterName,
                        content: content,
                        timestamp: timestamp,
                        isUserMessage: isUserMessage,
                        messageType: messageType
                    )
                    
                    modelContext.insert(message)
                    restoredMessages += 1
                    newMessageCount += 1
                }
                
                // 更新会话信息
                existing.messageCount = (existingMessages?.count ?? 0) + newMessageCount
                existing.lastActiveTime = latestMessageTime
                existing.updatedAt = latestMessageTime
                
                updatedSessions += 1
                print("✅ [恢复] 会话已更新: 新增 \(newMessageCount) 条消息（会话现有 \(existing.messageCount) 条消息）")
            } else {
                // 创建新会话
                let chatMode = sessionData["chatMode"] as? String ?? "free"
                let chatTheme = sessionData["chatTheme"] as? String ?? "default"
                let userRole = sessionData["userRole"] as? String ?? "observer"
                let messageCount = sortedMessagesData.count
                let lastActiveTimeString = sessionData["lastActiveTime"] as? String ?? ""
                let lastActiveTime = parseFullDate(lastActiveTimeString) ?? Date()
                let createdAtString = sessionData["createdAt"] as? String ?? ""
                let createdAt = parseFullDate(createdAtString) ?? Date()
                let isCompleted = sessionData["isCompleted"] as? Bool ?? false
                
                let session = MultiPersonChatSession(
                    id: sessionId,
                    topic: topic,
                    participantIds: participantIds,
                    participantNames: participantNames,
                    chatMode: chatMode,
                    chatTheme: chatTheme,
                    userRole: userRole,
                    messageCount: messageCount,
                    lastActiveTime: lastActiveTime,
                    createdAt: createdAt,
                    updatedAt: lastActiveTime,
                    isCompleted: isCompleted
                )
                
                modelContext.insert(session)
                
                // 恢复消息
                for messageData in sortedMessagesData {
                    guard let messageId = messageData["id"] as? String,
                          let characterId = messageData["characterId"] as? String,
                          let characterName = messageData["characterName"] as? String,
                          let content = messageData["content"] as? String else {
                        continue
                    }
                    
                    let timestampString = messageData["timestamp"] as? String ?? ""
                    let timestamp = parseFullDate(timestampString) ?? Date()
                    let isUserMessage = messageData["isUserMessage"] as? Bool ?? false
                    let messageType = messageData["messageType"] as? String ?? "text"
                    
                    let message = MultiPersonChatMessage(
                        id: messageId,
                        sessionId: sessionId,
                        characterId: characterId,
                        characterName: characterName,
                        content: content,
                        timestamp: timestamp,
                        isUserMessage: isUserMessage,
                        messageType: messageType
                    )
                    
                    modelContext.insert(message)
                    restoredMessages += 1
                }
                
                restoredSessions += 1
            }
        }
        
        // 保存更改
        do {
            try modelContext.save()
            print("✅ [恢复] 多人对话恢复完成: 恢复了 \(restoredSessions) 个新会话，更新了 \(updatedSessions) 个现有会话，共恢复/更新 \(restoredMessages) 条消息")
            
            // 发送通知，让UI刷新多人对话列表
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("MultiPersonChatSessionsRestored"), object: nil)
            }
        } catch {
            print("❌ [恢复] 保存多人对话失败: \(error)")
            print("   错误详情: \(error.localizedDescription)")
        }
    }
    
    /// 恢复点赞记录数据
    private func restoreLikesData(likes: [[String: Any]]) {
        print("📥 [恢复] 开始恢复点赞记录，共 \(likes.count) 条")
        
        // 先加载现有的点赞记录
        var existingLikes: [LikeRecord] = []
        if let likesData = UserDefaults.standard.data(forKey: "UserLikes_v1") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                existingLikes = try decoder.decode([LikeRecord].self, from: likesData)
                print("📥 [恢复] 当前已有 \(existingLikes.count) 条点赞记录")
            } catch {
                print("⚠️ [恢复] 加载现有点赞记录失败: \(error)")
            }
        }
        
        var restoredCount = 0
        
        for likeData in likes {
            guard let postId = likeData["postId"] as? String,
                  let typeString = likeData["type"] as? String,
                  let type = LikeRecordType(rawValue: typeString) else {
                print("⚠️ [恢复] 跳过无效的点赞记录数据")
                continue
            }
            
            // 检查是否已存在（通过postId和type匹配）
            let alreadyExists = existingLikes.contains(where: { $0.postId == postId && $0.type == type })
            
            if !alreadyExists {
                // 解析其他字段
                let title = likeData["title"] as? String ?? ""
                let content = likeData["content"] as? String ?? ""
                let authorName = likeData["authorName"] as? String ?? ""
                let authorAvatar = likeData["authorAvatar"] as? String ?? "person.circle.fill"
                let characterName = likeData["characterName"] as? String
                
                // 解析时间戳
                let timestamp: Date
                if let timestampString = likeData["timestamp"] as? String {
                    timestamp = parseFullDate(timestampString) ?? Date()
                } else if let timestampDouble = likeData["timestamp"] as? Double {
                    timestamp = Date(timeIntervalSince1970: timestampDouble)
                } else {
                    timestamp = Date()
                }
                
                let likeCount = likeData["likeCount"] as? Int ?? 0
                
                // 创建LikeRecord
                let likeRecord = LikeRecord(
                    postId: postId,
                    type: type,
                    title: title,
                    content: content,
                    authorName: authorName,
                    authorAvatar: authorAvatar,
                    characterName: characterName,
                    timestamp: timestamp,
                    likeCount: likeCount
                )
                
                existingLikes.append(likeRecord)
                restoredCount += 1
            } else {
                print("⏩ [恢复] 点赞记录已存在，跳过: \(postId)")
            }
        }
        
        // 保存合并后的点赞记录
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(existingLikes)
            UserDefaults.standard.set(data, forKey: "UserLikes_v1")
            
            print("✅ [恢复] 点赞记录恢复完成: 原有 \(existingLikes.count - restoredCount) 条 + 恢复 \(restoredCount) 条 = 共 \(existingLikes.count) 条")
            
            // 通知UserLikeService重新加载
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("LikesDataRestored"), object: nil)
            }
        } catch {
            print("❌ [恢复] 保存点赞记录失败: \(error)")
        }
    }
    
    /// 恢复关注角色数据
    private func restoreFollowedCharacters(from data: Any) {
        var usernames: [String] = []
        
        if let dict = data as? [String: Any] {
            if let characters = dict["characters"] as? [[String: Any]] {
                let allCharacters = CharacterSystem.shared.getAllCharacters()
                for entry in characters {
                    if let name = entry["name"] as? String, !name.isEmpty {
                        usernames.append(name)
                    } else if let id = entry["id"] as? String,
                              let matchedName = allCharacters.first(where: { $0.id == id })?.name {
                        usernames.append(matchedName)
                    }
                }
            }
            if usernames.isEmpty, let rawList = dict["rawList"] as? [String] {
                usernames = rawList
            }
        } else if let list = data as? [String] {
            usernames = list
        }
        
        usernames = usernames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !usernames.isEmpty else {
            print("ℹ️ [恢复] 没有关注角色数据需要恢复")
            return
        }
        
        FollowManager.shared.importFollowedUsers(usernames)
        
        for name in usernames {
            NotificationCenter.default.post(
                name: Notification.Name("FollowStatusChanged"),
                object: nil,
                userInfo: ["username": name, "isFollowed": true]
            )
        }
        
        print("✅ [恢复] 关注角色: 已恢复 \(usernames.count) 个关注对象")
    }
    
    // MARK: - 监听器设置
    
    private var logoutObserver: NSObjectProtocol?
    
    /// 设置退出登录监听器
    private func setupLogoutListener() {
        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userAccountLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearAllUserData()
        }
    }
    
    deinit {
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - UserProfileManager 扩展
extension UserProfileManager {
    /// 重置为默认值
    func resetToDefault() {
        DispatchQueue.main.async {
            self.username = "次元指挥官"
            self.personalSignature = "探索无限次元，寻找智慧宝藏 ✨"
            self.avatarImage = nil
            self.avatarImageName = "default_avatar"
            self.userLevel = 1
            self.userExperience = 0
            self.levelTitle = "时空新手"
            self.lastLevelUpdateTime = Date()
            
            // 发送重置通知
            NotificationCenter.default.post(name: .userProfileReset, object: nil)
        }
    }
}

// MARK: - 通知扩展
extension Notification.Name {
    static let userProfileReset = Notification.Name("userProfileReset")
    static let userDataExported = Notification.Name("userDataExported")
    static let userDataRestored = Notification.Name("userDataRestored")
} 