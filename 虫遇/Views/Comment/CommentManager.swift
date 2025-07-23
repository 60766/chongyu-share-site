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
        var parentCommentId: UUID? = nil
        
        print("🔄 开始提交评论 - 内容: \"\(processedContent.prefix(30))...\"")
        print("🔄 是否为回复: \(replyingToComment != nil)")
        
        if let replyTo = replyingToComment {
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
            
            // 记录父评论ID，确保保持展开状态
            parentCommentId = replyTo.id
            
            print("✅ 已添加回复评论 - ID: \(newCommentId), 回复给: \(replyTo.username), 内容: \"\(processedContent.prefix(30))...\"")
            print("✅ 父评论ID: \(replyTo.id)")
            
            // 检查是否回复的是虚拟角色的评论
            if replyTo.isVirtualCharacter {
                print("🤖 检测到回复的是虚拟角色评论，将触发针对性回复")
                
                // 获取虚拟角色ID
                if let characterID = replyTo.characterID {
                    // 使用Task异步生成虚拟角色的回复
                    Task {
                        await generateVirtualCharacterReplyToUser(
                            characterID: characterID,
                            userComment: processedContent,
                            parentCommentID: replyTo.id,
                            replyToUsername: currentUsername,
                            originalComment: replyTo.content
                        )
                    }
                }
            } else {
                // 如果回复的不是虚拟角色，走普通的虚拟角色回复生成逻辑
                Task {
                    print("🤖 开始生成虚拟角色回复")
                    await generateVirtualReply()
                }
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
            
            // 生成虚拟角色回复
            // 对于每条用户评论，都进行回复生成
            Task {
                print("🤖 开始生成虚拟角色回复")
                await generateVirtualReply()
            }
        }
        
        // 重置状态
        isRestoringDraft = true // 标记为恢复草稿状态，避免触发保存
        commentText = ""
        
        // 保存当前回复对象的引用，确保在清除replyingToComment前保存其信息
        let savedReplyingToComment = replyingToComment
        
        isRestoringDraft = false // 重置标记
        replyingToComment = nil
        
        // 清除草稿
        clearDraft()
        
        // 更新评论列表
        updateCommentLists()
        
        // 打印当前评论数量
        print("📊 提交后顶级评论数量: \(topLevelComments.count)")
        print("📊 提交后总评论数量: \(allComments.count)")
        
        // 在闭包外部准备所有需要的数据，避免在闭包中引用self
        let parentCommentIdString: String? = savedReplyingToComment?.parentCommentId?.uuidString ?? savedReplyingToComment?.id.uuidString
        let topParentId: UUID? = savedReplyingToComment?.parentCommentId ?? savedReplyingToComment?.id
        
        // 立即发送展开评论通知，确保评论区域不会折叠
        if let topParentId = topParentId {
            // 立即发送展开评论通知，不等待异步操作
            NotificationCenter.default.post(
                name: NSNotification.Name("ExpandComment"),
                object: nil,
                userInfo: [
                    "commentId": topParentId.uuidString,
                    "forceExpand": true,
                    "preventCollapse": true
                ]
            )
            
            print("📣 立即发送ExpandComment通知，确保父评论ID: \(topParentId) 保持展开状态")
        }
        
        // 如果是回复评论，还需要确保新评论也被展开
        if parentCommentId != nil {
            NotificationCenter.default.post(
                name: NSNotification.Name("ExpandComment"),
                object: nil,
                userInfo: [
                    "commentId": newCommentId.uuidString,
                    "forceExpand": true,
                    "preventCollapse": true
                ]
            )
            
            print("📣 立即发送ExpandComment通知，确保新评论ID: \(newCommentId) 保持展开状态")
        }
        
        // 发送通知，告知不要滚动页面位置
        NotificationCenter.default.post(
            name: NSNotification.Name("MaintainScrollPosition"),
            object: nil
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 发送对象变更通知
            self.objectWillChange.send()
            
            // 发送刷新评论列表通知，添加preventScroll参数
            print("📣 发送RefreshCommentsList通知")
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshCommentsList"),
                object: nil,
                userInfo: [
                    "keepExpandState": true,
                    "preventCollapse": true,
                    "newCommentId": newCommentId.uuidString,
                    "parentCommentId": parentCommentIdString as Any,
                    "preventScroll": true
                ]
            )
            
            // 如果是回复评论，发送一个特定的通知来确保父评论保持展开状态
            if let topParentId = topParentId {
                // 发送展开评论通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("ExpandComment"),
                    object: nil,
                    userInfo: [
                        "commentId": topParentId.uuidString,
                        "preventCollapse": true,
                        "preventScroll": true
                    ]
                )
                
                print("📣 发送ExpandComment通知，确保父评论ID: \(topParentId) 保持展开状态")
            }
            
            // 延迟一小段时间后再次发送通知，确保评论显示正常但不滚动
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshCommentsWithoutScrolling"),
                    object: nil,
                    userInfo: ["preventScroll": true]
                )
            }
            
            // 延迟一小段时间后再次发送对象变更通知，确保UI完全更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self else { return }
                self.objectWillChange.send()
                
                // 再次发送展开评论通知，确保评论区域不会折叠
                if let topParentId = topParentId {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ExpandComment"),
                        object: nil,
                        userInfo: [
                            "commentId": topParentId.uuidString,
                            "preventCollapse": true,
                            "preventScroll": true
                        ]
                    )
                }
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
     * 对用户评论进行回复
     */
    func generateVirtualReply() async {
        // 添加超时控制
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10秒超时
            return false
        }
        
        let replyTask = Task {
            do {
                // 获取当前帖子的所有评论
                let allComments = currentPost.comments
                
                // 查找最新的用户评论（非虚拟角色评论）
                if let latestUserComment = allComments
                    .filter({ !$0.isVirtualCharacter && $0.isCurrentUser })
                    .sorted(by: { $0.datePosted > $1.datePosted })
                    .first {
                    
                    print("🤖 找到最新用户评论: \(latestUserComment.content)")
                    
                    // 获取可用的虚拟角色列表
                    let availableCharacters = CharacterDataManager.shared.getAllCharacterIds()
                    
                    // 随机选择1-2个虚拟角色进行回复
                    let replyCount = Int.random(in: 1...2)
                    var selectedCharacters = Set<String>()
                    
                    // 确保不重复选择角色
                    while selectedCharacters.count < replyCount && selectedCharacters.count < availableCharacters.count {
                        if let randomCharacter = availableCharacters.randomElement() {
                            selectedCharacters.insert(randomCharacter)
                        }
                    }
                    
                    print("🤖 已选择 \(selectedCharacters.count) 个角色生成回复")
                    
                    // 为每个选定的角色生成回复
                    for characterID in selectedCharacters {
                        // 添加延迟，使回复看起来更自然
                        try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 1.0...3.0) * 1_000_000_000))
                        
                        // 检查任务是否已取消
                        if Task.isCancelled {
                            print("⚠️ 虚拟角色回复生成任务已取消")
                            return
                        }
                        
                        // 生成回复
                        await generateVirtualCharacterReplyToUser(
                            characterID: characterID,
                            userComment: latestUserComment.content,
                            parentCommentID: latestUserComment.id,
                            replyToUsername: latestUserComment.username,
                            originalComment: latestUserComment.content
                        )
                    }
                    
                    return true
                } else {
                    print("⚠️ 未找到最新用户评论，无法生成虚拟角色回复")
                    return false
                }
            } catch {
                print("❌ 生成虚拟角色回复时发生错误: \(error.localizedDescription)")
                return false
            }
        }
        
        // 等待任务完成或超时
        let result = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                return await replyTask.value
            }
            
            group.addTask {
                return await timeoutTask.value
            }
            
            // 获取第一个完成的任务结果
            if let result = await group.next() {
                // 取消所有剩余任务
                timeoutTask.cancel()
                replyTask.cancel()
                return result
            }
            
            return false
        }
        
        if !result {
            print("⚠️ 生成虚拟角色回复超时或失败")
        }
    }
    
    /**
     * 生成虚拟角色对用户评论的回复
     * 针对特定虚拟角色对特定用户评论进行回复
     */
    @MainActor
    func generateVirtualCharacterReplyToUser(
        characterID: String,
        userComment: String,
        parentCommentID: UUID,
        replyToUsername: String,
        originalComment: String
    ) async {
        // 添加超时控制
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10秒超时
            return false
        }
        
        let replyTask = Task {
            do {
                print("🤖 开始生成虚拟角色回复 - 角色: \(characterID), 回复给: \(replyToUsername)")
                
                // 获取角色信息
                let characterName = CharacterDataManager.shared.getName(for: characterID) ?? characterID
                let characterAvatar = getCharacterAvatar(for: characterID)
                
                // 使用SingleCharacterCommentService生成回复
                let content = try await SingleCharacterCommentService.shared.generateComment(
                    characterID: characterID,
                    postId: currentPost.id.uuidString,
                    postContent: currentPost.content,
                    postAuthor: currentPost.username,
                    userComment: userComment,
                    targetUsername: replyToUsername
                )
                
                // 检查任务是否已取消
                if Task.isCancelled {
                    print("⚠️ 虚拟角色回复生成任务已取消")
                    return false
                }
                
                // 创建虚拟角色回复
                let virtualReply = DetailedCommentModel(
                    username: characterName,
                    userAvatar: characterAvatar,
                    content: content,
                    datePosted: Date().addingTimeInterval(Double.random(in: 15...60)),
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
                
                // 发送通知，告知UI虚拟角色回复已添加，需要更新显示
                NotificationCenter.default.post(
                    name: NSNotification.Name("VirtualCharacterReplyAdded"),
                    object: nil,
                    userInfo: [
                        "parentCommentID": parentCommentID.uuidString,
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
                        "parentCommentId": parentCommentID.uuidString,
                        "immediateDisplay": true,
                        "preserveExpandState": true
                    ]
                )
                
                print("✅ 虚拟角色回复已添加 - 角色: \(characterName), 回复给: \(replyToUsername)")
                return true
            } catch {
                print("❌ 生成虚拟角色回复失败: \(error.localizedDescription)")
                return false
            }
        }
        
        // 等待任务完成或超时
        let result = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                return await replyTask.value
            }
            
            group.addTask {
                return await timeoutTask.value
            }
            
            // 获取第一个完成的任务结果
            if let result = await group.next() {
                // 取消所有剩余任务
                timeoutTask.cancel()
                replyTask.cancel()
                return result
            }
            
            return false
        }
        
        if !result {
            print("⚠️ 生成虚拟角色回复超时或失败")
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
