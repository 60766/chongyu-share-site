import SwiftUI
import UIKit
import Combine
import Foundation

/**
 * 评论管理器
 * 
 * 负责处理评论的提交、回复和显示逻辑
 * 处理用户评论和虚拟角色回复
 */
class CommentManager: ObservableObject {
    // 当前帖子
    @Published var currentPost: UserPostModel {
        didSet {
            // 当帖子变更时，更新评论列表
            if oldValue.id != currentPost.id {
                updateCommentLists()
                
                // 保存当前帖子的草稿到字典
                if !commentText.isEmpty {
                    draftDictionary[oldValue.id] = commentText
                }
                
                // 清除回复状态，确保切换帖子后不会保留上一个帖子的回复状态
                replyingToComment = nil
                
                // 加载新帖子的草稿
                loadDraftForCurrentPost()
            }
        }
    }
    // 所有评论（包括回复）
    @Published var allComments: [DetailedCommentModel] = []
    // 只包含顶级评论
    @Published var topLevelComments: [DetailedCommentModel] = []
    // 当前被回复的评论
    @Published var replyingToComment: DetailedCommentModel? = nil
    // 输入框内容
    @Published var commentText: String = "" {
        didSet {
            // 当文本变化时，自动处理草稿
            if oldValue != commentText && !isRestoringDraft {
                if commentText.isEmpty {
                    // 如果文本为空，直接清除草稿
                    clearDraft()
                } else {
                    // 否则保存草稿
                    debouncedSaveDraft()
                }
            }
        }
    }
    
    // 用户信息
    private let currentUsername: String
    private let currentUserAvatar: String
    
    // 虚拟角色服务
    private let virtualCharacterService = VirtualCharacterService.shared
    // 角色个性管理器
    private let personalityManager = CharacterPersonalityManager.shared
    
    // 取消订阅标记
    private var cancellables = Set<AnyCancellable>()
    
    // 草稿保存防抖计时器
    private var draftSaveTimer: Timer?
    
    // 标记是否正在恢复草稿，避免触发不必要的状态变化
    private var isRestoringDraft: Bool = false
    
    // 草稿字典 - 将帖子ID映射到对应草稿
    private var draftDictionary: [UUID: String] = [:]
    
    // 用户清除标记字典 - 记录哪些帖子的草稿被用户明确清除
    private var userClearedDictionary: [UUID: Bool] = [:]
    
    /**
     * 初始化评论管理器
     * @param post 当前帖子
     * @param username 当前用户名
     * @param userAvatar 当前用户头像
     */
    init(post: UserPostModel, username: String = "当前用户", userAvatar: String = "user_avatar") {
        self.currentPost = post
        self.currentUsername = username
        self.currentUserAvatar = userAvatar
        
        // 初始化评论列表
        updateCommentLists()
        
        // 加载所有已保存的草稿到内存字典
        loadAllDraftsFromUserDefaults()
        
        // 恢复当前帖子的草稿内容
        loadDraftForCurrentPost()
        
        // 添加对清除草稿通知的监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClearDraftNotification),
            name: NSNotification.Name("ClearCommentDraft"),
            object: nil
        )
        
        // 添加对批量生成评论通知的监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommentsGeneratedNotification),
            name: NSNotification.Name("CommentsGenerated"),
            object: nil
        )
    }
    
    /**
     * 从 UserDefaults 加载所有已保存的草稿到内存字典
     */
    private func loadAllDraftsFromUserDefaults() {
        draftDictionary.removeAll()
        userClearedDictionary.removeAll()
        
        // 获取所有 UserDefaults 键
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        
        // 查找所有草稿键
        for key in allKeys {
            if key.hasPrefix("comment_draft_") {
                // 提取帖子ID
                let idString = key.replacingOccurrences(of: "comment_draft_", with: "")
                if let uuid = UUID(uuidString: idString),
                   let draftText = UserDefaults.standard.string(forKey: key),
                   !draftText.isEmpty {
                    draftDictionary[uuid] = draftText
                }
            } else if key.hasPrefix("user_cleared_draft_") {
                // 提取帖子ID
                let idString = key.replacingOccurrences(of: "user_cleared_draft_", with: "")
                if let uuid = UUID(uuidString: idString) {
                    userClearedDictionary[uuid] = UserDefaults.standard.bool(forKey: key)
                }
            }
        }
        
        print("📝 已从 UserDefaults 加载 \(draftDictionary.count) 个草稿和 \(userClearedDictionary.count) 个清除标记")
    }
    
    /**
     * 加载当前帖子的草稿
     */
    private func loadDraftForCurrentPost() {
        isRestoringDraft = true
        
        // 检查用户是否已明确清除了当前帖子的草稿
        if userClearedDictionary[currentPost.id] == true {
            print("⚠️ 用户已明确清除该帖子的草稿，不恢复草稿")
            commentText = ""
            isRestoringDraft = false
            return
        }
        
        // 从内存字典中获取草稿
        if let draft = draftDictionary[currentPost.id] {
            commentText = draft
            print("📝 已加载帖子 \(currentPost.id.uuidString) 的草稿: \(draft.prefix(20))...")
        } else {
            commentText = ""
            print("📝 帖子 \(currentPost.id.uuidString) 没有草稿")
        }
        
        isRestoringDraft = false
    }
    
    // 处理清除草稿通知
    @objc private func handleClearDraftNotification() {
        DispatchQueue.main.async {
            self.clearDraftPublic()
        }
    }
    
    // 处理批量生成评论通知
    @objc private func handleCommentsGeneratedNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let userInfo = notification.userInfo,
                  let postID = userInfo["postID"] as? String,
                  self.currentPost.id.uuidString == postID,
                  let commentsMap = userInfo["commentsMap"] as? [String: String] else {
                print("⚠️ 无法处理批量生成评论通知：缺少必要信息或当前帖子不匹配")
                return
            }
            
            // 获取批次ID，用于防止重复处理
            let batchId = userInfo["batchId"] as? String ?? UUID().uuidString
            
            // 检查是否已经处理过这个批次
            let processedBatchKey = "processed_batch_\(batchId)"
            if UserDefaults.standard.bool(forKey: processedBatchKey) {
                print("⚠️ 批次ID \(batchId) 已被处理过，跳过重复处理")
                return
            }
            
            print("📥 接收到批量生成评论通知，共\(commentsMap.count)条评论，批次ID: \(batchId)")
            
            // 检查是否为邀请的角色评论
            let isInvited = userInfo["isInvited"] as? Bool ?? false
            
            if isInvited {
                // 邀请的角色评论应作为顶级评论添加
                for (characterID, content) in commentsMap {
                    // 创建虚拟角色评论
                    let virtualComment = DetailedCommentModel(
                        username: self.getCharacterName(for: characterID),
                        userAvatar: self.getCharacterAvatar(for: characterID),
                        content: content,
                        datePosted: Date().addingTimeInterval(Double.random(in: 15...60)),
                        isVirtualCharacter: true,
                        characterID: characterID
                    )
                    
                    // 添加到帖子作为顶级评论
                    self.currentPost.addComment(virtualComment)
                    
                    print("✅ 邀请的虚拟角色评论已添加为顶级评论 - 角色: \(characterID)")
                }
                
                // 更新评论列表
                self.updateCommentLists()
            } else {
                // 这是对用户评论的回复，已经在generateVirtualReply方法中处理
                print("ℹ️ 这是对用户评论的回复，将在generateVirtualReply方法中处理")
            }
            
            // 标记此批次已处理
            UserDefaults.standard.set(true, forKey: processedBatchKey)
        }
    }
    
    /**
     * 防抖保存草稿，避免频繁写入
     */
    private func debouncedSaveDraft() {
        // 取消之前的计时器
        draftSaveTimer?.invalidate()
        
        // 创建新的计时器，延迟0.5秒执行保存
        draftSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.saveDraft(self.commentText)
        }
    }
    
    /**
     * 保存评论草稿
     * @param text 要保存的草稿内容
     */
    private func saveDraft(_ text: String) {
        // 使用帖子ID作为唯一标识符
        let draftKey = "comment_draft_\(currentPost.id.uuidString)"
        let userClearedKey = "user_cleared_draft_\(currentPost.id.uuidString)"
        
        // 如果文本为空，则删除草稿
        if text.isEmpty {
            UserDefaults.standard.removeObject(forKey: draftKey)
            draftDictionary.removeValue(forKey: currentPost.id)
        } else {
            // 否则保存草稿到 UserDefaults 和内存字典
            UserDefaults.standard.set(text, forKey: draftKey)
            draftDictionary[currentPost.id] = text
            
            // 如果用户开始输入新内容，清除"用户已明确清除草稿"的标记
            UserDefaults.standard.removeObject(forKey: userClearedKey)
            userClearedDictionary[currentPost.id] = false
            
            // 立即同步UserDefaults，确保数据被保存
            UserDefaults.standard.synchronize()
        }
    }
    
    /**
     * 清除草稿
     */
    private func clearDraft() {
        // 使用帖子ID作为唯一标识符
        let draftKey = "comment_draft_\(currentPost.id.uuidString)"
        UserDefaults.standard.removeObject(forKey: draftKey)
        draftDictionary.removeValue(forKey: currentPost.id)
        
        // 设置用户已明确清除草稿的标记
        let userClearedKey = "user_cleared_draft_\(currentPost.id.uuidString)"
        UserDefaults.standard.set(true, forKey: userClearedKey)
        userClearedDictionary[currentPost.id] = true
        
        // 立即同步UserDefaults，确保数据被删除
        UserDefaults.standard.synchronize()
    }
    
    /**
     * 公开的清除草稿方法，允许外部组件调用
     */
    func clearDraftPublic() {
        clearDraft()
        
        // 同时清空输入框文本
        isRestoringDraft = true
        commentText = ""
        isRestoringDraft = false
        
        print("🗑️ 帖子 \(currentPost.id.uuidString) 的草稿已被外部组件清除")
    }
    
    /**
     * 更新评论列表（严格对话流排序）
     */
    func updateCommentLists() {
        let allCommentsArray = currentPost.comments
        print("==== DEBUG: currentPost.comments ====")
        for c in allCommentsArray {
            print("id=\(c.id), parentCommentId=\(String(describing: c.parentCommentId)), user=\(c.username), content=\(c.content)")
        }
        print("==== END ====")
        
        // 首先获取所有顶级评论并按时间倒序排序（新的在上方）
        let topLevelComments = allCommentsArray
            .filter { $0.parentCommentId == nil }
            .sorted { $0.datePosted > $1.datePosted }
        
        // 递归平铺：每个评论后紧跟所有直接回复它的评论（同级按时间正序）
        func flatten(comment: DetailedCommentModel) -> [DetailedCommentModel] {
            // 获取直接回复该评论的所有评论，并按时间正序排列
            let directReplies = allCommentsArray
                .filter { $0.parentCommentId == comment.id }
                .sorted { $0.datePosted < $1.datePosted }
            
            var result: [DetailedCommentModel] = [comment]
            
            // 对每个直接回复，递归获取其所有子回复
            for reply in directReplies {
                result.append(contentsOf: flatten(comment: reply))
            }
            
            return result
        }
        
        // 平铺所有顶级评论及其回复
        var flat: [DetailedCommentModel] = []
        for topComment in topLevelComments {
            flat.append(contentsOf: flatten(comment: topComment))
        }
        
        print("==== DEBUG: allComments (平铺后) ====")
        for c in flat {
            print("id=\(c.id), parentCommentId=\(String(describing: c.parentCommentId)), user=\(c.username), content=\(c.content)")
        }
        print("==== END ====")
        
        self.allComments = flat
        self.topLevelComments = topLevelComments
    }
    
    /**
     * 查找评论的根评论（顶级评论）
     * 用于将多层嵌套的回复组织到正确的顶级评论下
     */
    private func findRootComment(for comment: DetailedCommentModel, in allComments: [DetailedCommentModel]) -> DetailedCommentModel? {
        // 如果没有父评论ID，则自身就是根评论
        if comment.parentCommentId == nil {
            return comment
        }
        
        // 查找父评论
        if let parentComment = allComments.first(where: { $0.id == comment.parentCommentId }) {
            // 递归查找根评论
            return findRootComment(for: parentComment, in: allComments)
        }
        
        return nil
    }
    
    /**
     * 获取所有评论和回复的扁平列表
     */
    private func getAllCommentsFlattened() -> [DetailedCommentModel] {
        var result: [DetailedCommentModel] = []
        
        // 添加所有顶级评论
        for comment in topLevelComments {
            result.append(comment)
            // 递归添加所有回复
            result.append(contentsOf: flattenReplies(comment.replies))
        }
        
        return result
    }
    
    /**
     * 递归扁平化回复列表
     */
    private func flattenReplies(_ replies: [DetailedCommentModel]) -> [DetailedCommentModel] {
        var result: [DetailedCommentModel] = []
        
        for reply in replies {
            result.append(reply)
            result.append(contentsOf: flattenReplies(reply.replies))
        }
        
        return result
    }
    
    /**
     * 提交评论
     * 用户提交普通评论或回复评论
     * 修改后每次提交都会触发虚拟角色回复
     */
    func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ 评论内容为空，取消提交")
            return
        }
        
        // 处理评论内容
        let processedContent = commentText
        
        // 记录评论ID以便后续跟踪
        var newCommentId: UUID = UUID()
        
        // 记录当前展开状态，确保评论提交后保持展开状态
        // 移除未使用的变量
        
        print("🔄 开始提交评论 - 内容: \"\(processedContent.prefix(30))...\"")
        print("🔄 是否为回复: \(replyingToComment != nil)")
        
        // 先重置状态，避免UI卡住
        isRestoringDraft = true // 标记为恢复草稿状态，避免触发保存
        // 移除未使用的变量
        commentText = ""
        
        // 保存当前回复对象的引用，确保在清除replyingToComment前保存其信息
        let savedReplyingToComment = replyingToComment
        
        isRestoringDraft = false // 重置标记
        replyingToComment = nil
        
        // 清除草稿
        clearDraft()
        
        // 使用Task异步处理评论提交和虚拟角色回复生成
        Task { @MainActor in
            if let replyTo = savedReplyingToComment {
                // 添加回复 - 如果有回复对象，直接使用replyToUsername参数，不需要在内容中添加@
                newCommentId = UUID()
                currentPost.addComment(
                    username: currentUsername,
                    userAvatar: currentUserAvatar,
                    content: processedContent, // 不需要显式添加@前缀
                    parentCommentId: replyTo.id,
                    replyToUsername: replyTo.username, // 使用回复对象的用户名
                    userId: UserDefaults.standard.string(forKey: "current_user_id") ?? UIDevice.current.identifierForVendor?.uuidString,
                    isCurrentUser: true
                )
                
                print("✅ 已添加回复评论 - ID: \(newCommentId), 回复给: \(replyTo.username), 内容: \"\(processedContent.prefix(30))...\"")
                print("✅ 父评论ID: \(replyTo.id)")
                
                // 更新评论列表
                updateCommentLists()
                
                // 立即发送对象变更通知
                self.objectWillChange.send()
                
                // 立即发送展开评论通知，确保评论区域不会折叠
                let topParentId = replyTo.parentCommentId ?? replyTo.id
                NotificationCenter.default.post(
                    name: NSNotification.Name("ExpandComment"),
                    object: nil,
                    userInfo: [
                        "commentId": topParentId.uuidString,
                        "forceExpand": true,
                        "preventCollapse": true
                    ]
                )
                
                // 确保新评论也被展开
                NotificationCenter.default.post(
                    name: NSNotification.Name("ExpandComment"),
                    object: nil,
                    userInfo: [
                        "commentId": newCommentId.uuidString,
                        "forceExpand": true,
                        "preventCollapse": true
                    ]
                )
                
                print("📣 立即发送ExpandComment通知，确保父评论ID: \(topParentId) 保持展开状态")
                
                // 发送通知，告知不要滚动页面位置
                NotificationCenter.default.post(
                    name: NSNotification.Name("MaintainScrollPosition"),
                    object: nil
                )
                
                // 发送刷新评论列表通知，添加preventScroll参数
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshCommentsList"),
                    object: nil,
                    userInfo: [
                        "keepExpandState": true,
                        "preventCollapse": true,
                        "newCommentId": newCommentId.uuidString,
                        "parentCommentId": topParentId.uuidString,
                        "immediateDisplay": true
                    ]
                )
                
                // 强制刷新评论列表
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshComments"),
                    object: nil
                )
                
                // 检查是否回复的是虚拟角色的评论
                if replyTo.isVirtualCharacter {
                    print("🤖 检测到回复的是虚拟角色评论，将触发针对性回复")
                    
                    // 获取虚拟角色ID
                    if let characterID = replyTo.characterID {
                        // 异步生成虚拟角色的回复
                        await generateVirtualCharacterReplyToUser(
                            characterID: characterID,
                            userComment: processedContent,
                            parentCommentID: replyTo.id,
                            replyToUsername: currentUsername,
                            originalComment: replyTo.content
                        )
                    }
                } else {
                    // 如果回复的不是虚拟角色，走普通的虚拟角色回复生成逻辑
                    print("🤖 开始生成虚拟角色回复")
                    await generateVirtualReply()
                }
            } else {
                // 添加顶级评论 - 无需特殊处理
                newCommentId = UUID()
                currentPost.addComment(
                    username: currentUsername,
                    userAvatar: currentUserAvatar,
                    content: processedContent,
                    userId: UserDefaults.standard.string(forKey: "current_user_id") ?? UIDevice.current.identifierForVendor?.uuidString,
                    isCurrentUser: true
                )
                
                print("✅ 已添加顶级评论 - ID: \(newCommentId), 内容: \"\(processedContent.prefix(30))...\"")
                
                // 更新评论列表
                updateCommentLists()
                
                // 立即发送对象变更通知
                self.objectWillChange.send()
                
                // 发送通知，告知不要滚动页面位置
                NotificationCenter.default.post(
                    name: NSNotification.Name("MaintainScrollPosition"),
                    object: nil
                )
                
                // 发送刷新评论列表通知，确保新评论立即显示但不展开折叠
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshCommentsList"),
                    object: nil,
                    userInfo: [
                        "keepExpandState": true,
                        "preventCollapse": true,
                        "newCommentId": newCommentId.uuidString,
                        "immediateDisplay": true,
                        "preventScroll": true
                    ]
                )
                
                // 强制刷新评论列表
                NotificationCenter.default.post(
                    name: NSNotification.Name("ForceRefreshComments"),
                    object: nil
                )
                
                // 生成虚拟角色回复
                print("🤖 开始生成虚拟角色回复")
                await generateVirtualReply()
            }
        }
    }
    
    /**
     * 设置回复对象
     */
    func replyTo(comment: DetailedCommentModel) {
        replyingToComment = comment
        
        // 发送通知，告知不要滚动页面位置
        NotificationCenter.default.post(
            name: NSNotification.Name("MaintainScrollPosition"),
            object: nil
        )
        
        // 延迟一小段时间后再次发送通知，确保评论显示正常
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshCommentsWithoutScrolling"),
                object: nil,
                userInfo: ["preventScroll": true]
            )
        }
    }
    
    /**
     * 取消回复
     * 清除当前回复目标
     */
    func cancelReply() {
        self.replyingToComment = nil
    }
    
    /**
     * 生成虚拟角色回复
     * 优先选择帖子作者对最新评论做出回复，否则随机选择其他虚拟角色
     * 修改为支持对每条评论都做出回复，并确保回复不会太相似
     * 并且避免同一个角色对同一用户的不同评论进行重复回复
     * 帖子作者只回复一次，给其他虚拟角色留出回复空间
     */
    @MainActor
    func generateVirtualReply() async {
        // 获取最新评论
        guard let latestComment = allComments.max(by: { $0.datePosted < $1.datePosted }) else {
            return
        }
        
        // 如果最新评论来自虚拟角色，不进行回复
        if latestComment.isVirtualCharacter {
            print("🤖 最新评论来自虚拟角色，跳过回复")
            return
        }
        
        // 检查是否已经对此评论生成过回复
        let commentRepliedKey = "replied_to_comment_\(latestComment.id.uuidString)"
        if UserDefaults.standard.bool(forKey: commentRepliedKey) {
            print("🤖 已经对评论ID: \(latestComment.id.uuidString) 生成过回复，跳过")
            return
        }
        
        // 保存最新评论ID，确保回复到正确位置
        let targetCommentID = latestComment.id
        let targetUsername = latestComment.username
        let userCommentContent = latestComment.content  // 获取用户评论内容
        
        print("⭐️ 生成回复目标 - 评论ID: \(targetCommentID), 用户: \(targetUsername), 内容: \"\(latestComment.content.prefix(20))...\"")
        
        // 检查评论中是否包含@特定角色
        let mentionedCharacter = checkForMentionedCharacter(in: latestComment.content)
        
        // 获取帖子作者
        let postAuthorName = currentPost.username
        var authorCharacterId: String? = nil
        
        // 首先尝试从帖子的characterID属性获取
        if let postCharacterId = currentPost.characterID, !postCharacterId.isEmpty {
            authorCharacterId = postCharacterId
            print("👑 从帖子属性获取到作者角色ID: \(postCharacterId)")
        } else {
            // 使用CharacterDataManager获取所有角色信息
            let characterInfoList = CharacterDataManager.shared.getAllCharactersInfo()
            
            // 创建角色名称到ID的映射
            var characterMapping: [String: String] = [:]
            for info in characterInfoList {
                characterMapping[info.name] = info.id
            }
            
            // 然后尝试通过名称匹配
            if let id = characterMapping[postAuthorName] {
                authorCharacterId = id
                print("👑 通过名称匹配识别帖子作者是虚拟角色: \(postAuthorName) (ID: \(id))")
            }
        }
        
        // 记录已回复过此用户的角色，避免重复
        // 移除未使用的变量
        // let userRepliedCharactersKey = "replied_characters_to_\(targetUsername)"
        
        // 分开处理帖子作者和其他角色
        var authorCharacter: String? = nil
        var otherSelectedCharacters: [String] = []
        
        // 1. 如果帖子作者是虚拟角色，将其加入到回复列表
        if let authorId = authorCharacterId {
            authorCharacter = authorId
            print("👑 帖子作者将参与回复")
        }
        
        // 2. 处理@提及的角色
        if let mentionedCharacter = mentionedCharacter, mentionedCharacter != authorCharacter {
            otherSelectedCharacters.append(mentionedCharacter)
            print("👥 @提及的角色将参与回复: \(CharacterDataManager.shared.getName(for: mentionedCharacter) ?? mentionedCharacter)")
        }
        
        // 3. 从其他角色中随机选择，补足到总共4-5个角色（包括作者和@提及的）
        // 使用CharacterDataManager获取所有可用角色ID
        let allCharacterIds = CharacterDataManager.shared.getAllCharacterIds()
        let availableCharacters = allCharacterIds.filter { 
            $0 != authorCharacter && 
            !otherSelectedCharacters.contains($0) 
        }
        
        // 确定需要额外选择的角色数量
        let totalCharactersNeeded = 4 // 总共需要4个角色（包括作者）
        let additionalNeeded = max(0, totalCharactersNeeded - otherSelectedCharacters.count - (authorCharacter != nil ? 1 : 0))
        
        if additionalNeeded > 0 && !availableCharacters.isEmpty {
            // 随机选择额外角色
            let additionalCharacters = Array(availableCharacters.shuffled().prefix(additionalNeeded))
            otherSelectedCharacters.append(contentsOf: additionalCharacters)
            print("🎲 随机选择了\(additionalCharacters.count)个额外角色参与回复")
        }
        
        // 合并所有选定的角色，确保作者在列表中
        var allSelectedCharacters: [String] = []
        if let authorChar = authorCharacter {
            allSelectedCharacters.append(authorChar)
            print("👑 已将作者角色添加到回复列表")
        }

        // 添加其他角色，确保不重复添加作者
        for char in otherSelectedCharacters {
            if char != authorCharacter {
                allSelectedCharacters.append(char)
            }
        }
        
        // 确保总数不超过4个角色（包括作者）
        if allSelectedCharacters.count > 4 {
            // 如果有作者，保留作者和前3个其他角色
            if authorCharacter != nil {
                // 确保作者在列表的第一位
                var finalList: [String] = []
                finalList.append(authorCharacter!)
                
                // 添加其他角色，最多3个
                let remainingSlots = 3
                let otherChars = allSelectedCharacters.filter { $0 != authorCharacter }
                finalList.append(contentsOf: otherChars.prefix(remainingSlots))
                
                allSelectedCharacters = finalList
            } else {
                // 如果没有作者，直接取前4个
                allSelectedCharacters = Array(allSelectedCharacters.prefix(4))
            }
        }
        
        // 确保列表不为空
        if allSelectedCharacters.isEmpty && !availableCharacters.isEmpty {
            // 如果列表为空，随机选择4个角色
            allSelectedCharacters = Array(availableCharacters.shuffled().prefix(4))
            print("⚠️ 角色列表为空，随机选择了\(allSelectedCharacters.count)个角色")
        }
        
        print("👥 最终选择的回复角色: \(allSelectedCharacters.joined(separator: ", "))")
        print("🔍 是否包含帖子作者: \(authorCharacter != nil ? "是 - \(authorCharacter!)" : "否")")
        print("🔢 总共选择了\(allSelectedCharacters.count)个角色回复")
        
        // 记录用户评论，用于跟踪历史
        for character in allSelectedCharacters {
            let userCommentKey = "\(character)_latest_user_comment"
            UserDefaults.standard.set(latestComment.content, forKey: userCommentKey)
        }
        
        // 移除模拟打字延迟
        // do {
        //     try await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.5...2.0) * 1_000_000_000))
        // } catch {
        //     print("⚠️ 延迟模拟被中断")
        // }
        
        // 使用批量API生成回复
        print("🚀 开始批量生成\(allSelectedCharacters.count)个角色的回复")
        
        // 生成一个唯一的请求ID，用于跟踪这次请求
        let requestId = UUID().uuidString
        print("📝 生成请求ID: \(requestId)")
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                MultiCharacterCommentService.shared.generateMultiCharacterComments(
                    characterIDs: allSelectedCharacters,
                    postId: currentPost.id.uuidString,
                    postContent: currentPost.content,
                    postAuthor: currentPost.username,
                    userComment: userCommentContent,  // 添加用户评论内容参数
                    targetUsername: targetUsername,   // 添加目标用户名参数
                    authorCharacterId: authorCharacter, // 添加作者角色ID参数
                    completion: { [weak self] result in
                        guard let self = self else {
                            continuation.resume(throwing: NSError(domain: "CommentManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self reference lost"]))
                            return
                        }
                        
                        switch result {
                        case .success(let commentsMap):
                            print("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                            
                            // 标记此评论已被回复
                            UserDefaults.standard.set(true, forKey: commentRepliedKey)
                            
                            // 为每个角色添加回复，移除延迟
                            for (index, (characterID, content)) in commentsMap.enumerated() {
                                // 作者优先回复，其他角色依次回复
                                // 移除延迟
                                
                                // 记录角色回复，用于避免相似回复
                                let characterReplyKey = "\(characterID)_latest_replies"
                                var previousReplies = UserDefaults.standard.stringArray(forKey: characterReplyKey) ?? []
                                
                                // 最多保存最近3条回复历史
                                previousReplies.insert(content, at: 0)
                                if previousReplies.count > 3 {
                                    previousReplies = Array(previousReplies.prefix(3))
                                }
                                UserDefaults.standard.set(previousReplies, forKey: characterReplyKey)
                                
                                // 在主线程上立即执行
                                DispatchQueue.main.async {
                                    // 添加虚拟角色回复
                                    let characterAvatar = self.getCharacterAvatar(for: characterID)
                                    let characterDisplayName = CharacterDataManager.shared.getName(for: characterID) ?? characterID // 使用中文名称，如果找不到则使用ID
                                    
                                    // 创建虚拟角色评论
                                    let virtualReply = DetailedCommentModel(
                                        username: characterDisplayName, // 使用中文名称
                                        userAvatar: characterAvatar,
                                        content: content,
                                        datePosted: Date(), // 使用当前时间，不添加随机延迟
                                        isVirtualCharacter: true,
                                        characterID: characterID,
                                        parentCommentId: targetCommentID,
                                        replyToUsername: targetUsername // 添加回复给谁的信息
                                    )
                                    
                                    // 添加到帖子
                                    self.currentPost.addComment(virtualReply)
                                    
                                    // 更新评论列表
                                    self.updateCommentLists()
                                    
                                    // 如果是作者回复，标记作者已回复此评论
                                    if characterID == authorCharacter {
                                        let commentAuthorReplyKey = "author_replied_\(targetCommentID.uuidString)"
                                        UserDefaults.standard.set(true, forKey: commentAuthorReplyKey)
                                        print("✅ 帖子作者已回复此评论")
                                    }
                                    
                                    print("✅ 虚拟角色回复已添加 - 角色: \(CharacterDataManager.shared.getName(for: characterID) ?? characterID), 回复给: \(targetUsername), 评论ID: \(targetCommentID)")
                                    
                                    // 确保评论可见（展开评论链）
                                    self.ensureReplyVisible(commentId: targetCommentID)
                                    
                                    // 发送通知，告知UI虚拟角色回复已添加，需要更新显示
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("VirtualCharacterReplyAdded"),
                                        object: nil,
                                        userInfo: [
                                            "parentCommentID": targetCommentID.uuidString,
                                            "replyCommentID": virtualReply.id.uuidString,
                                            "characterID": characterID,
                                            "forceExpand": true,
                                            "preventCollapse": true,
                                            "immediateDisplay": true,
                                            "preserveExpandState": true
                                        ]
                                    )
                                    
                                    // 发送刷新评论列表通知，确保评论立即显示
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("RefreshCommentsList"),
                                        object: nil,
                                        userInfo: [
                                            "keepExpandState": true,
                                            "preventCollapse": true,
                                            "newCommentId": virtualReply.id.uuidString,
                                            "parentCommentId": targetCommentID.uuidString,
                                            "immediateDisplay": true,
                                            "preserveExpandState": true
                                        ]
                                    )
                                }
                            }
                            
                            continuation.resume()
                        case .failure(let error):
                            print("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    }
                )
            }
        } catch {
            print("❌ 批量API生成回复失败: \(error.localizedDescription)")
        }
    }
    
    /**
     * 生成虚拟角色对用户评论的回复
     * 专门处理用户回复虚拟角色评论的情况
     * 只有被回复的虚拟角色会回复用户
     */
    @MainActor
    func generateVirtualCharacterReplyToUser(
        characterID: String,
        userComment: String,
        parentCommentID: UUID,
        replyToUsername: String,
        originalComment: String
    ) async {
        print("🤖 开始生成虚拟角色(\(characterID))对用户回复的回应")
        
        // 检查是否已经对此评论生成过回复
        let commentRepliedKey = "replied_to_user_comment_\(parentCommentID.uuidString)_\(userComment.hash)"
        if UserDefaults.standard.bool(forKey: commentRepliedKey) {
            print("🤖 已经对用户回复生成过回应，跳过")
            return
        }
        
        // 获取角色名称
        let characterName = getCharacterName(for: characterID)
        let characterAvatar = getCharacterAvatar(for: characterID)
        
        // 获取角色特性 - 修复类型不匹配问题
        let characterTraits = personalityManager.getPersonality(for: characterID) ?? 
            CharacterPersonality(
                tone: "有智慧的",
                knowledgeAreas: ["历史", "文化"],
                speechPatterns: []
            )
        
        // 构建专门的提示词，用于生成对用户回复的回应
        let prompt = """
        请先判断用户的回复内容是否与帖子主题或上下文有关联：
        - 如果有关联，请结合帖子内容和上下文，按照下方要求生成回复。
        - 如果没有关联（用户只是单纯和你闲聊或提问），请直接根据你的个性、知识和风格自由回复用户，不必强行拉回帖子主题。

        你是\(characterName)，一个\(characterTraits.tone)的历史人物，专长领域是\(characterTraits.knowledgeAreas.joined(separator: "、"))。

        帖子主题："\(currentPost.content)"

        对话历史：
        - 你之前说："\(originalComment)"
        - 用户"\(replyToUsername)"回复你："\(userComment)"

        请以\(characterName)的身份回复，注意：
        1. 直接针对用户的回复内容做出个性化回应，表现出你对用户的关注
        2. 保持你的独特风格、语气和专业视角
        3. 考虑帖子主题和之前的对话，保持连贯性
        4. 回复长度控制在15-30字之间，简短有力
        5. 如果用户提问，给予简明的回答；如果用户表达观点，给予简短的回应
        6. 表现出适当的情感反应，增强对话的真实感
        7. 不要使用"作为[角色]"的开头，不要添加元分析或角色扮演描述

        直接输出\(characterName)的回复内容。
        """
        
        // 移除模拟打字延迟
        // do {
        //     try await Task.sleep(nanoseconds: UInt64(Double.random(in: 1.5...3.0) * 1_000_000_000))
        // } catch {
        //     print("⚠️ 延迟模拟被中断")
        // }
        
        // 使用Combine方式调用API
        return await withCheckedContinuation { continuation in
            AINetworkService.shared.sendRequest(prompt: prompt)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print("❌ 生成虚拟角色回复失败: \(error.localizedDescription)")
                        }
                        continuation.resume()
                    },
                    receiveValue: { [weak self] response in
                        guard let self = self else { return }
                        
                        // 清理API返回的内容
                        let cleanedResponse = self.cleanResponseContent(response)
                        print("✅ 生成虚拟角色回复成功: \"\(cleanedResponse.prefix(30))...\"")
                        
                        // 标记此评论已被回复
                        UserDefaults.standard.set(true, forKey: commentRepliedKey)
                        
                        // 在主线程上添加回复，移除延迟
                        DispatchQueue.main.async {
                            // 创建虚拟角色回复
                            let virtualReply = DetailedCommentModel(
                                username: characterName,
                                userAvatar: characterAvatar,
                                content: cleanedResponse,
                                datePosted: Date(), // 使用当前时间，不添加随机延迟
                                isVirtualCharacter: true,
                                characterID: characterID,
                                parentCommentId: parentCommentID,
                                replyToUsername: replyToUsername
                            )
                            
                            // 添加到帖子
                            self.currentPost.addComment(virtualReply)
                            
                            // 更新评论列表
                            self.updateCommentLists()
                            
                            // 确保评论可见（展开评论链）
                            self.ensureReplyVisible(commentId: parentCommentID)
                            
                            // 生成批次ID
                            let batchId = UUID().uuidString
                            
                            // 发送通知更新UI
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PostCommentsUpdated"),
                                object: nil,
                                userInfo: [
                                    "postID": self.currentPost.id.uuidString,
                                    "batchId": batchId, 
                                    "forceRefresh": true,
                                    "keepExpandState": true
                                ]
                            )
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("RefreshPostComments"),
                                object: nil,
                                userInfo: [
                                    "batchId": batchId, 
                                    "forceRefresh": true,
                                    "keepExpandState": true
                                ]
                            )
                            
                            // 发送特定通知，告知UI虚拟角色回复已添加到特定评论下
                            NotificationCenter.default.post(
                                name: NSNotification.Name("VirtualCharacterReplyAdded"),
                                object: nil,
                                userInfo: [
                                    "parentCommentID": parentCommentID.uuidString,
                                    "replyCommentID": virtualReply.id.uuidString,
                                    "characterID": characterID,
                                    "keepExpandState": true,
                                    "forceExpand": false,
                                    "preventCollapse": true,
                                    "immediateDisplay": true,
                                    "preserveExpandState": true
                                ]
                            )
                            
                            // 发送刷新评论列表通知，确保评论立即显示
                            NotificationCenter.default.post(
                                name: NSNotification.Name("RefreshCommentsList"),
                                object: nil,
                                userInfo: [
                                    "keepExpandState": true,
                                    "preventCollapse": true,
                                    "newCommentId": virtualReply.id.uuidString,
                                    "parentCommentId": parentCommentID.uuidString,
                                    "immediateDisplay": true,
                                    "preserveExpandState": true,
                                    "noAutoExpand": true
                                ]
                            )
                            
                            print("✅ 虚拟角色回复已添加 - 角色: \(characterName), 回复给: \(replyToUsername)")
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 获取角色头像
     * @param characterID 角色ID
     * @return 角色头像系统图标名称
     */
    private func getCharacterAvatar(for characterID: String) -> String {
        // 使用CharacterDataManager获取角色头像
        if let avatar = CharacterDataManager.shared.getAvatarName(for: characterID) {
            print("✅ 从CharacterDataManager获取头像: \(characterID) -> \(avatar)")
            return avatar
        }
        
        // 如果找不到，返回角色ID作为头像名称
        print("⚠️ 无法从CharacterDataManager获取头像，使用ID作为头像: \(characterID)")
        return characterID
    }
    
    /**
     * 检查评论中是否@了特定的虚拟角色
     * @param content 评论内容
     * @return 被@的角色ID，如果没有则返回nil
     */
    private func checkForMentionedCharacter(in content: String) -> String? {
        // 使用CharacterDataManager获取所有角色信息
        let characterInfoList = CharacterDataManager.shared.getAllCharactersInfo()
        
        // 创建角色名称到ID的映射
        var characterMapping: [String: String] = [:]
        for info in characterInfoList {
            characterMapping[info.name] = info.id
        }
        
        // 检查评论中是否包含@角色名
        for (characterName, characterId) in characterMapping {
            if content.contains("@\(characterName)") {
                return characterId
            }
        }
        
        return nil
    }
    
    // 获取角色名称
    private func getCharacterName(for characterId: String) -> String {
        // 使用CharacterDataManager获取角色名称
        if let name = CharacterDataManager.shared.getName(for: characterId) {
            return name
        }
        
        // 如果CharacterDataManager找不到，使用备用映射
        let characterNames: [String: String] = [
            "einstein": "爱因斯坦",
            "shakespeare": "莎士比亚",
            "davinci": "达芬奇",
            "confucius": "孔子",
            "curie": "居里夫人",
            "libai": "李白",
            "newton": "牛顿",
            "socrates": "苏格拉底",
            "holmes": "福尔摩斯",
            "nietzsche": "尼采",
            "sunwukong": "孙悟空",
            "darwin": "达尔文",
            "luxun": "鲁迅",
            "plato": "柏拉图",
            "dufu": "杜甫",
            "aristotle": "亚里士多德",
            "napoleon": "拿破仑",
            "picasso": "毕加索",
            "vangogh": "梵高",
            "quyuan": "屈原",
            "laozi": "老子",
            "mozart": "莫扎特",
            "beethoven": "贝多芬",
            "heraclitus": "赫拉克利特",
            "zhuangzi": "庄子",
            "marquez": "马尔克斯",
            "hawking": "霍金",
            "edison": "爱迪生",
            "tesla": "特斯拉",
            "kant": "康德",
            "hegel": "黑格尔",
            "baudelaire": "波德莱尔",
            "kafka": "卡夫卡",
            "smith": "亚当·斯密",
            "marx": "马克思",
            "camus": "加缪",
            "freud": "弗洛伊德",
            "jung": "荣格",
            "heidegger": "海德格尔",
            "xuzhimo": "徐志摩",
            "hemingway": "海明威",
            "bach": "巴赫",
            "turing": "图灵",
            "feynman": "费曼",
            "popper": "波普尔",
            "tagore": "泰戈尔",
            "schopenhauer": "叔本华",
            "dostoevsky": "陀思妥耶夫斯基",
            "lincoln": "林肯",
            "gandhi": "甘地",
            "beauvoir": "波伏娃",
            "yangming": "王阳明",
            "xiaobo": "王小波",
            "pascal": "帕斯卡",
            "russell": "罗素",
            "wittgenstein": "维特根斯坦",
            "sartre": "萨特",
            "wordsworth": "华兹华斯",
            "qingzhao": "李清照",
            "snake": "固蛇"
        ]
        
        // 如果在备用映射中找到，返回对应名称
        if let name = characterNames[characterId] {
            print("⚠️ 从备用映射获取角色名称: \(characterId) -> \(name)")
            return name
        }
        
        // 如果都找不到，返回角色ID
        print("⚠️ 无法获取角色名称，使用ID作为名称: \(characterId)")
        return characterId
    }
    
    /**
     * 清理API返回的内容
     * 移除可能的角色前缀和其他不需要的元素
     */
    private func cleanResponseContent(_ content: String) -> String {
        var cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除可能的角色名前缀，如"爱因斯坦："
        let characterNames = CharacterDataManager.shared.getAllCharactersInfo().map { $0.name }
        for name in characterNames {
            if cleanedContent.hasPrefix("\(name)：") || cleanedContent.hasPrefix("\(name):") {
                cleanedContent = cleanedContent.replacingOccurrences(of: "\(name)：", with: "")
                cleanedContent = cleanedContent.replacingOccurrences(of: "\(name):", with: "")
                break
            }
        }
        
        // 移除所有括号及其中的内容，支持中文和英文括号
        let bracketPatterns = [
            "\\([^\\)]*\\)",             // 英文小括号 (...)
            "（[^）]*）",                 // 中文小括号 （...）
            "\\[[^\\]]*\\]",             // 英文中括号 [...]
            "【[^】]*】",                // 中文中括号 【...】
            "\\{[^\\}]*\\}",             // 英文大括号 {...}
            "｛[^｝]*｝"                  // 中文大括号 ｛...｝
        ]
        
        for pattern in bracketPatterns {
            cleanedContent = cleanedContent.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }
        
        // 移除"注："及其后面的解释内容
        let notePatterns = [
            "注：[^\\n]*",               // "注："后面的内容
            "注:[^\\n]*",                // "注:"后面的内容
            "PS：[^\\n]*",               // "PS："后面的内容
            "PS:[^\\n]*",                // "PS:"后面的内容
            "P\\.S\\.：[^\\n]*",         // "P.S.："后面的内容
            "P\\.S\\.:[^\\n]*",          // "P.S.:"后面的内容
            "补充：[^\\n]*",             // "补充："后面的内容
            "补充:[^\\n]*"               // "补充:"后面的内容
        ]
        
        for pattern in notePatterns {
            cleanedContent = cleanedContent.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression
            )
        }
        
        // 移除多余的空格和换行
        cleanedContent = cleanedContent.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanedContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果清理后内容为空，返回一个默认回复
        if cleanedContent.isEmpty {
            cleanedContent = "我明白你的意思。"
        }
        
        return cleanedContent
    }
    
    /**
     * 生成强化提示，以提升回复质量
     * - Parameters:
     *   - comment: 用户评论
     *   - characterID: 角色ID
     *   - traits: 角色特性
     * - Returns: 强化后的提示
     */
    func enhancedPrompt(for comment: DetailedCommentModel, characterID: String, traits: AIPromptCharacterTraits) -> String {
        let commentContent = comment.content
        
        // 检查评论长度，如果非常短，则使用简短回复策略
        if commentContent.count <= 10 {
            // 对于特别短的评论（如"哈哈哈"、"666"等），给出更直接的指导
            let shortCommentPrompt = """
            用户发表了一条简短评论: "\(commentContent)"
            
            作为\(traits.name)，请直接针对这条评论回复：
            1. 必须直接回应用户的这条具体评论，不要谈论帖子内容
            2. 表现出真实对话的感觉，就像在日常交流一样
            3. 保持你的个性特点，但首要任务是回应用户的评论内容
            4. 禁止使用任何角色扮演式的描述，如"(微笑)"、"(思考中)"等
            5. 回复必须与用户的评论直接相关，不要自说自话或谈论无关话题
            6. 回复控制在15字以内，越简短越好
            7. 使用格式：\(traits.name)：[回复内容]，使用中文冒号
            8. 称呼用户时，避免直接使用"当前用户"这样的网名，而应使用更自然的方式：
               - 可以使用"朋友"、"你"等自然的称呼
               - 如果是回复问题，可以直接回答而不称呼
               - 如果是对话，可以用"您"表示尊重
            
            记住：你必须直接回应用户的评论内容，而不是谈论帖子或其他无关话题。
            """
            return shortCommentPrompt
        }
        
        let basePrompt = """
        用户发表了以下评论: "\(commentContent)"
        
        请以\(traits.description)的风格，作为\(traits.name)回复这条评论。
        
        回复要求:
        1. 必须直接回应用户的这条具体评论内容，而非帖子本身
        2. 把用户评论视为对话的开始，你需要接这个话茬，形成自然对话
        3. 理解用户评论的真实意图，给出有针对性的回应
        4. 体现你独特的思想和个性，但首要任务是回应用户评论
        5. 回复控制在20-40字之间，简短有力
        6. 使用通俗易懂的语言，将专业术语用生动比喻解释
        7. 严格禁止使用任何括号中的内容，如"(思考中)"、"(微笑)"等
        8. 评论格式必须为：\(traits.name)：[评论内容]，使用中文冒号
        9. 与其他角色回复形成思想碰撞，增加互动感和趣味性
        10. 称呼用户时，避免直接使用"当前用户"这样的网名，而应使用更自然的方式：
            - 可以使用"朋友"、"你"等自然的称呼
            - 如果是回复问题，可以直接回答而不称呼
            - 如果是对话，可以用"您"表示尊重
        11. 根据用户评论的类型调整风格：
            - 提问：给予有见地的回答，但不要长篇大论
            - 观点：可以赞同、质疑或补充，展现你的思维方式
            - 情感表达：回应情感，展现共鸣或独特视角
            - 闲聊：保持轻松友好，但仍有你的特色
        
        记住：你是在与用户直接对话，要让用户感受到真实的互动。
        不要自顾自地发表与用户评论无关的言论，这会让对话显得不自然。
        绝对不要在评论结尾添加任何解释性括号标注。
        """
        
        // 如果评论来自当前用户，添加额外的提示以确保回复的相关性
        if comment.username == currentUsername {
            return basePrompt + """
            
            额外提醒：这条评论来自与你正在交流的用户，必须确保你的回复与用户评论有明确的关联。
            你的回复应该像真实对话一样自然，而不是对帖子内容的评论。
            绝对不要使用任何括号内的内容，如注释、解释或理论分析。
            严格禁止直接称呼用户为"当前用户"。
            """
        }
        
        return basePrompt
    }
    
    /**
     * 聚焦到评论输入框
     * 发送通知让评论输入框获取焦点
     */
    func focusCommentInput() {
        // 发送通知让评论输入框获取焦点
        DispatchQueue.main.async {
            print("📣 发送FocusCommentInput通知")
            NotificationCenter.default.post(
                name: NSNotification.Name("FocusCommentInput"),
                object: nil
            )
            
            // 同时滚动到评论区域
            NotificationCenter.default.post(
                name: NSNotification.Name("ScrollToComments"),
                object: nil
            )
        }
    }
    
    /**
     * 递归查找嵌套回复
     * 支持多层嵌套回复的查找
     * @param comment 评论
     * @param commentId 要查找的评论ID
     */
    func findNestedReply(in comment: DetailedCommentModel, commentId: UUID) -> DetailedCommentModel? {
        // 检查当前评论是否是目标评论
        if comment.id == commentId {
            return comment
        }
        
        // 递归查找评论的回复
        for reply in comment.replies {
            if reply.id == commentId {
                return reply
            }
            
            // 递归查找回复的嵌套回复
            if let found = findNestedReply(in: reply, commentId: commentId) {
                return found
            }
        }
        
        return nil
    }
    
    /**
     * 确保展开特定回复的所有父级回复
     * 用于确保UI中显示嵌套回复
     * @param commentId 要展示的回复ID
     */
    func ensureReplyVisible(commentId: UUID) {
        // 首先在顶级评论中查找
        for comment in topLevelComments {
            if comment.id == commentId {
                // 目标是顶级评论，不需要特殊处理
                return
            }
            
            // 递归检查是否在嵌套回复中
            if checkAndExpandNestedReply(in: comment, targetId: commentId) {
                // 找到并已展开，退出循环
                break
            }
        }
    }
    
    /**
     * 递归检查并展开包含目标回复的嵌套回复链
     * @param comment 当前检查的评论
     * @param targetId 目标回复ID
     * @return 是否找到并展开
     */
    private func checkAndExpandNestedReply(in comment: DetailedCommentModel, targetId: UUID) -> Bool {
        // 直接检查一级回复
        for reply in comment.replies {
            if reply.id == targetId {
                // 找到目标回复，发送通知展开父评论
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ExpandComment"),
                        object: nil,
                        userInfo: ["commentId": comment.id.uuidString]
                    )
                }
                return true
            }
            
            // 递归检查嵌套回复
            if containsNestedReply(reply, targetId: targetId) {
                // 目标在这个回复的嵌套回复中，发送通知展开当前回复和父评论
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ExpandComment"),
                        object: nil,
                        userInfo: ["commentId": comment.id.uuidString]
                    )
                    
                    // 延迟一点时间再展开嵌套回复，确保UI已更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ExpandComment"),
                            object: nil,
                            userInfo: ["commentId": reply.id.uuidString]
                        )
                    }
                }
                return true
            }
        }
        
        return false
    }
    
    /**
     * 检查评论是否包含指定ID的嵌套回复
     * @param comment 要检查的评论
     * @param targetId 目标回复ID
     * @return 是否包含目标回复
     */
    private func containsNestedReply(_ comment: DetailedCommentModel, targetId: UUID) -> Bool {
        // 直接检查
        if comment.id == targetId {
            return true
        }
        
        // 递归检查
        for nestedReply in comment.replies {
            if nestedReply.id == targetId || containsNestedReply(nestedReply, targetId: targetId) {
                return true
            }
        }
        
        return false
    }
    
    /**
     * 对象销毁时确保草稿被正确处理
     */
    deinit {
        // 取消计时器
        draftSaveTimer?.invalidate()
        
        // 只有当评论文本不为空时才保存草稿
        if !commentText.isEmpty {
            saveDraft(commentText)
        }
        
        // 移除对清除草稿通知的监听
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ClearCommentDraft"),
            object: nil
        )
    }
    
    /**
     * 更新草稿内容
     * 公开方法，让外部可以直接更新草稿
     * @param text 新的草稿内容
     */
    func updateDraft(_ text: String) {
        // 标记为恢复草稿状态，避免触发额外的保存操作
        isRestoringDraft = true
        
        // 更新输入框内容
        self.commentText = text
        
        // 重置标记
        isRestoringDraft = false
        
        // 立即保存草稿，不使用防抖
        saveDraft(text)
    }
}

/**
 * 预览
 */
struct CommentManager_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一个临时视图来包装CommentManager
        VStack {
            Text("评论管理器预览")
                .font(.headline)
                .padding()
            
            Spacer()
            
            Text("CommentManager不是一个View，但已初始化为：")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text("CommentManager(post: ModelData.samplePosts[0])")
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .frame(height: 200)
        .onAppear {
            // 初始化CommentManager但不显示
            let _ = CommentManager(post: ModelData.samplePosts[0])
        }
    }
}
