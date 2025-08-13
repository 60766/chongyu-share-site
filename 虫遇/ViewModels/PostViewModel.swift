import Foundation
import Combine
import SwiftUI

// 导入CommentStore类
typealias CommentStore = ContentGeneratorService.CommentStore

/**
 * 帖子生成错误类型
 */
enum PostGenerationError: Error {
    case invalidTypeIndex
    case failedToGeneratePosts
    case contentGenerationFailed
}

/**
 * 帖子视图模型
 * 处理帖子数据和用户交互
 */
class PostViewModel: ObservableObject {
    // 单例实例 - 在应用内共享帖子数据
    static let shared = PostViewModel()
    
    // 帖子数据
    @Published var posts: [UserPostModel] = [] {
        didSet {
            // 当帖子数据变化时，保存持久化的存根数据，确保可以恢复
            savePersistentPostsStub()
            // 同步 comments 为当前 post 的完整树结构
            if let currentPost = posts.first {
                self.comments = currentPost.getTopLevelComments()
            }
        }
    }
    
    // 用户交互状态
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // 服务依赖
    private let virtualCharacterService = VirtualCharacterService.shared
    // 内容生成服务
    private let contentGeneratorService = ContentGeneratorService.shared
    
    // 历史人物认知模型
    private let cognitionModel = HistoricalFigureCognitionModel.shared
    
    // 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // 持久化数据的键
    private let postsStubKey = "persistedPostsStub"
    
    // 评论数据
    @Published var comments: [DetailedCommentModel] = []
    
    /**
     * 初始化视图模型
     * 加载示例帖子数据
     */
    init() {
        // 首先尝试从持久化存储恢复帖子
        if !tryRestorePersistedPosts() {
            // 如果没有持久化的帖子，加载示例帖子
            loadSamplePosts()
        }
        
        // 监听 PostCommentsUpdated 通知，强制刷新 comments
        NotificationCenter.default.addObserver(forName: NSNotification.Name("PostCommentsUpdated"), object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            // 自动推断当前展示的 postId（假设只有一个帖子或第一个帖子为当前）
            if let currentPostId = self.posts.first?.id,
               let _ = self.posts.firstIndex(where: { $0.id == currentPostId }) {
                // 触发UI刷新
                self.objectWillChange.send()
                // 如果你有 @Published var comments: [DetailedCommentModel]，请同步刷新
                // self.comments = self.posts[currentPostIndex].comments
            }
        }
    }
    
    /**
     * 保存帖子存根到 UserDefaults，作为恢复机制
     * 存储帖子ID和时间戳等最小信息，而不是完整帖子
     */
    private func savePersistentPostsStub() {
        guard !posts.isEmpty else { 
            // 如果帖子为空，清除存根
            UserDefaults.standard.removeObject(forKey: postsStubKey)
            return
        }
        
        // 创建帖子存根 - 只保存必要的恢复信息
        let postsStub: [[String: Any]] = posts.map { post in
            [
                "id": post.id.uuidString,
                "timestamp": post.datePosted.timeIntervalSince1970,
                "hasData": true
            ]
        }
        
        // 保存到UserDefaults
        UserDefaults.standard.set(postsStub, forKey: postsStubKey)
    }
    
    /**
     * 尝试从持久化存储恢复帖子
     * 返回是否成功恢复
     */
    private func tryRestorePersistedPosts() -> Bool {
        guard let postsStub = UserDefaults.standard.array(forKey: postsStubKey) as? [[String: Any]],
              !postsStub.isEmpty else {
            return false
        }
        
        // 判断是否需要恢复 - 只有在当前没有帖子时才恢复
        guard posts.isEmpty else {
            return true
        }
        
        // 防止在恢复过程中内存错误，我们使用示例帖子作为基础数据
        let samplePosts = ModelData.samplePosts
        
        if !samplePosts.isEmpty {
            self.posts = samplePosts
            
            // 使用存根信息验证数据完整性
            // 如果存在不匹配的情况，可能需要重新加载示例数据
            if verifyPostsIntegrity(using: postsStub) {
                return true
            } else {
                return true // 仍然返回true因为我们已经加载了示例数据
            }
        } else {
            return false
        }
    }
    
    /**
     * 验证帖子数据完整性
     * 使用存根信息检查当前帖子列表是否完整
     */
    private func verifyPostsIntegrity(using postsStub: [[String: Any]]) -> Bool {
        let stubIds = postsStub.compactMap { $0["id"] as? String }
        let currentIds = posts.map { $0.id.uuidString }
        
        // 简单验证 - 检查帖子数量是否一致
        if stubIds.count != currentIds.count {
            return false
        }
        
        // 高级验证可以在这里添加，例如检查特定帖子的ID是否存在等
        
        return true
    }
    
    /**
     * 检查并确保帖子数据存在
     * 当应用切换到前台或视图重新出现时调用
     */
    func ensureDataExists() {
        // 如果当前没有帖子，尝试恢复或加载示例数据
        if posts.isEmpty {
            print("📦 检测到帖子列表为空，尝试恢复数据")
            if !tryRestorePersistedPosts() {
                print("📦 恢复失败，加载示例帖子")
                loadSamplePosts()
            }
            
            // 强制通知UI更新
            DispatchQueue.main.async {
                self.objectWillChange.send()
                print("📦 已触发UI更新信号")
            }
        } else {
            print("📦 当前有\(posts.count)个帖子，无需恢复")
        }
    }
    
    /**
     * 加载示例帖子
     */
    private func loadSamplePosts() {
        self.posts = ModelData.samplePosts
    }
    
    /**
     * 点赞帖子
     * @param post 帖子对象
     */
    func likePost(_ post: UserPostModel) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 切换点赞状态
            let isLiked = !posts[index].isLikedByCurrentUser
            // 更新点赞状态和点赞数
            var updatedPost = posts[index].toggleLike(isLiked: isLiked)
            
            // 更新点赞数（点赞+1，取消点赞-1）
            if isLiked {
                updatedPost = updatedPost.updateLikes(delta: 1)
            } else {
                updatedPost = updatedPost.updateLikes(delta: -1)
            }
            
            posts[index] = updatedPost
            
            // 模拟网络请求更新点赞状态
            // 在实际应用中，应该调用API更新服务器数据
        }
    }
    
    /**
     * 收藏帖子
     * @param post 帖子对象
     */
    func bookmarkPost(_ post: UserPostModel) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 切换收藏状态
            let isBookmarked = !posts[index].isBookmarkedByCurrentUser
            posts[index] = posts[index].toggleBookmark(isBookmarked: isBookmarked)
            
            // 模拟网络请求更新收藏状态
            // 在实际应用中，应该调用API更新服务器数据
        }
    }
    
    /**
     * 添加用户评论
     * @param post 帖子对象
     * @param content 评论内容
     * @param replyToCommentID 回复的评论ID（可选）
     */
    func addUserComment(to post: UserPostModel, content: String, replyToCommentID: UUID? = nil) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ addUserComment: 后台任务超时")
        }
        
        // 格式化评论内容，确保文本格式正确
        let formattedContent = UserPostModel.formatContent(content)
        
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 如果有父评论ID（回复），使用带parentCommentId参数的方法
            if let parentId = replyToCommentID {
                // 查找要回复的评论，获取其用户名
                let replyToUsername: String
                if let comment = getCommentById(commentId: parentId, in: posts[index].comments) {
                    replyToUsername = comment.username
                } else {
                    replyToUsername = "未知用户"
                }
                
                // 创建用户回复评论
                let userReply = DetailedCommentModel(
                    username: "当前用户",
                    userAvatar: "current_user_avatar",
                    content: formattedContent,
                    datePosted: Date(),
                    isVirtualCharacter: false,
                    characterID: nil,
                    parentCommentId: parentId,
                    replyToUsername: replyToUsername
                )
                
                // 保存用户回复的ID，用于后续添加虚拟角色回复
                let userReplyId = userReply.id
                print("📝 创建用户回复，ID: \(userReplyId)")
                
                // 创建帖子的可变副本
                let updatedPost = post
                
                // 添加用户回复到父评论
                updatedPost.addReplyToParent(parentId: parentId, reply: userReply)
                
                // 更新帖子
                posts[index] = updatedPost
                
                print("✅ 已添加用户回复到评论，回复ID: \(userReplyId)")
                
                // 准备要生成回复的角色列表
                var charactersToRespond: [String] = []
                
                // 如果是回复某个评论，查找该评论是否来自虚拟角色，并让该角色回复
                if let comment = getCommentById(commentId: parentId, in: posts[index].comments),
                   comment.isVirtualCharacter,
                   let characterID = comment.characterID {
                    // 添加被回复的角色
                    print("🤖 被回复的虚拟角色将回应用户")
                    charactersToRespond.append(characterID)
                    
                    // 发送角色互动通知给通知系统
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CharacterInteraction"),
                        object: nil,
                        userInfo: ["characterId": characterID]
                    )
                    
                    // 一次性生成回复 - AI回复应该回复到用户所回复的同一个父评论
                    generateBatchReplies(
                        characterIDs: charactersToRespond, 
                        to: formattedContent, 
                        in: post,
                        replyToId: parentId, // 使用原始的parentId，而不是userReplyId
                        replyToUsername: replyToUsername, // 使用实际的回复对象用户名
                        backgroundTaskID: backgroundTaskID
                    )
                }
            } else {
                // 创建顶级评论
                let newComment = DetailedCommentModel(
                    username: "当前用户",
                    userAvatar: "current_user_avatar",
                    content: formattedContent,
                    datePosted: Date(),
                    isVirtualCharacter: false,
                    characterID: nil
                )
                
                // 保存顶级评论的ID，用于后续回复
                let userCommentId = newComment.id
                
                // 添加评论到帖子
                posts[index].comments.insert(newComment, at: 0)
                
                print("✅ 已添加用户评论，评论ID: \(userCommentId)")
                
                // 准备要生成回复的角色列表
                var charactersToRespond: [String] = []
                
                // 1. 首先，添加帖子作者到回复列表（如果是虚拟角色）
                let postAuthor = posts[index].username
                let authorCharacterId = getCharacterIdByName(postAuthor)
                
                if let authorCharacterId = authorCharacterId {
                    print("🤖 帖子作者将回复用户评论，作者：\(postAuthor), ID：\(authorCharacterId)")
                    charactersToRespond.append(authorCharacterId)
                    
                    // 发送角色互动通知给通知系统
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CharacterInteraction"),
                        object: nil,
                        userInfo: ["characterId": authorCharacterId]
                    )
                }
                
                // 2. 添加1-2个随机角色
                var availableCharacters = ["einstein", "shakespeare", "davinci", "kongzi", "newton", "libai"]
                
                // 排除作者（如果有）
                if let authorId = authorCharacterId {
                    availableCharacters.removeAll { $0 == authorId.lowercased() }
                }
                
                // 随机选择1-2个角色
                let replyCount = Int.random(in: 1...2)
                let selectedCharacters = Array(availableCharacters.shuffled().prefix(replyCount))
                charactersToRespond.append(contentsOf: selectedCharacters)
                
                // 一次性生成所有角色的回复
                generateBatchReplies(
                    characterIDs: charactersToRespond, 
                    to: formattedContent, 
                    in: post,
                    replyToId: userCommentId, // AI回复嵌套在用户评论下
                    replyToUsername: "当前用户", // AI回复用户的顶级评论
                    backgroundTaskID: backgroundTaskID
                )
            }
        } else {
            // 帖子不存在，结束后台任务
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
        }
    }
    
    /**
     * 为多个角色批量生成回复
     * @param characterIDs 角色ID列表
     * @param to 回复的内容
     * @param in 帖子对象
     * @param replyToId 回复到的评论ID
     * @param replyToUsername 回复到的用户名
     * @param backgroundTaskID 后台任务ID
     */
    private func generateBatchReplies(characterIDs: [String], to content: String, in post: UserPostModel, replyToId: UUID, replyToUsername: String, backgroundTaskID: UIBackgroundTaskIdentifier) {
        // 如果没有角色需要回应，直接结束
        if characterIDs.isEmpty {
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
            return
        }
        
        print("🔄 准备批量生成\(characterIDs.count)个角色的回复")
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: characterIDs,
            postId: post.id.uuidString,
            postContent: post.content,
            postAuthor: post.username
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                print("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                
                // 获取帖子索引
                guard let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) else {
                    print("❌ 无法找到帖子，无法添加批量生成的回复")
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                    return
                }
                
                // 为了模拟自然对话，确定响应时间和顺序
                // 第一个角色（通常是被回复角色或帖子作者）响应较快
                let firstCharacterId = characterIDs.first!
                let otherCharacterIds = Array(characterIDs.dropFirst())
                
                // 第一个角色回复
                if let content = commentsMap[firstCharacterId] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.0)) {
                        // 创建虚拟角色回复
                        let virtualReply = DetailedCommentModel(
                            username: self.getCharacterName(for: firstCharacterId),
                            userAvatar: self.getCharacterAvatar(for: firstCharacterId),
                            content: content,
                            datePosted: Date().addingTimeInterval(Double.random(in: 30...60)),
                            isVirtualCharacter: true,
                            characterID: firstCharacterId,
                            parentCommentId: replyToId,
                            replyToUsername: replyToUsername
                        )
                        
                        // 添加到帖子
                        print("📝 添加\(firstCharacterId)的回复到评论ID: \(replyToId)")
                        self.posts[postIndex].addReplyToParent(parentId: replyToId, reply: virtualReply)
                        
                        // 发送通知刷新UI
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PostCommentsUpdated"),
                            object: nil,
                            userInfo: ["postID": post.id.uuidString]
                        )
                        
                        // 发送评论生成通知给通知系统
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CommentsGenerated"),
                            object: nil,
                            userInfo: [
                                "postID": post.id.uuidString,
                                "commentsMap": [firstCharacterId: content],
                                "isInvited": false
                            ]
                        )
                        
                        // 添加震动反馈
                        self.hapticFeedback()
                    }
                }
                
                // 其他角色回复（延迟更长）
                for (index, characterID) in otherCharacterIds.enumerated() {
                    if let content = commentsMap[characterID] {
                        // 添加累加的延迟，让回复看起来更自然
                        let delay = Double.random(in: 3.0...5.0) + Double(index) * 1.5
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            // 创建虚拟角色回复
                            let virtualReply = DetailedCommentModel(
                                username: self.getCharacterName(for: characterID),
                                userAvatar: self.getCharacterAvatar(for: characterID),
                                content: content,
                                datePosted: Date().addingTimeInterval(Double.random(in: 60...180)),
                                isVirtualCharacter: true,
                                characterID: characterID,
                                parentCommentId: replyToId,
                                replyToUsername: replyToUsername
                            )
                            
                            // 添加到帖子
                            print("📝 添加\(characterID)的回复到评论ID: \(replyToId)")
                            self.posts[postIndex].addReplyToParent(parentId: replyToId, reply: virtualReply)
                            
                            // 发送通知刷新UI
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PostCommentsUpdated"),
                                object: nil,
                                userInfo: ["postID": post.id.uuidString]
                            )
                            
                            // 发送评论生成通知给通知系统
                            NotificationCenter.default.post(
                                name: NSNotification.Name("CommentsGenerated"),
                                object: nil,
                                userInfo: [
                                    "postID": post.id.uuidString,
                                    "commentsMap": [characterID: content],
                                    "isInvited": false
                                ]
                            )
                            
                            // 添加震动反馈
                            self.hapticFeedback()
                            
                            // 如果是最后一个角色的回复，结束后台任务
                            if index == otherCharacterIds.count - 1 {
                                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                    print("🏁 所有虚拟角色回复任务已完成")
                                }
                            }
                        }
                    }
                }
                
                // 如果没有其他角色，在第一个角色回复后结束任务
                if otherCharacterIds.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                            UIApplication.shared.endBackgroundTask(backgroundTaskID)
                            print("🏁 虚拟角色回复任务已完成")
                        }
                    }
                }
                
            case .failure(let error):
                print("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }
        }
    }
    
    /**
     * 逐个生成角色回复（作为批量生成失败时的备用方案）
     */
    private func generateRepliesOneByOne(characters: [String], post: UserPostModel, originalCommentId: UUID) {
        for (index, characterID) in characters.enumerated() {
            // 添加延迟，让回复看起来更自然
            let delay = Double.random(in: 2.0...4.0) + Double(index) * 2.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                if let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) {
                    // 获取原始评论内容，用于生成回复
                    let commentContent = self.getCommentContent(commentId: originalCommentId, in: post)
                    
                    self.generateVirtualCharacterReply(
                        characterID: characterID,
                        toComment: commentContent,
                        inPost: post.content,
                        completion: { result in
                            if case .success(let content) = result {
                                print("✅ 单独生成角色回复 - \(self.getCharacterName(for: characterID)): \(content.prefix(30))...")
                                
                                // 创建虚拟角色回复
                                let virtualReply = DetailedCommentModel(
                                    username: self.getCharacterName(for: characterID),
                                    userAvatar: self.getCharacterAvatar(for: characterID),
                                    content: content,
                                    datePosted: Date().addingTimeInterval(Double.random(in: 60...180)),
                                    isVirtualCharacter: true,
                                    characterID: characterID,
                                    parentCommentId: originalCommentId,
                                    replyToUsername: "当前用户"
                                )
                                
                                // 添加到帖子
                                print("📝 添加虚拟角色回复到用户评论ID: \(originalCommentId)")
                                self.posts[postIndex].addReplyToParent(parentId: originalCommentId, reply: virtualReply)
                                
                                // 发送通知刷新UI
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("PostCommentsUpdated"),
                                    object: nil,
                                    userInfo: ["postID": post.id.uuidString]
                                )
                                
                                // 添加震动反馈
                                self.hapticFeedback()
                            }
                        }
                    )
                }
            }
        }
    }
    
    /**
     * 根据ID获取评论
     * @param commentId 评论ID
     * @param comments 评论数组
     * @return 评论对象，如果未找到则返回nil
     */
    private func getCommentById(commentId: UUID, in comments: [DetailedCommentModel]) -> DetailedCommentModel? {
        // 递归查找评论
        for comment in comments {
            if comment.id == commentId {
                return comment
            }
            
            // 在回复中查找
            if !comment.replies.isEmpty {
                if let foundComment = getCommentById(commentId: commentId, in: comment.replies) {
                    return foundComment
                }
            }
        }
        
        return nil
    }
    
    /**
     * 获取评论内容
     * @param commentId 评论ID
     * @param post 帖子对象
     * @return 评论内容
     */
    private func getCommentContent(commentId: UUID, in post: UserPostModel) -> String {
        if let comment = getCommentById(commentId: commentId, in: post.comments) {
            return comment.content
        }
        return "这条评论很有趣" // 默认文本，以防找不到评论
    }
    
    /**
     * 点赞评论
     * @param post 帖子对象
     * @param comment 评论对象
     */
    func likeComment(in post: UserPostModel, comment: DetailedCommentModel) {
        if let postIndex = posts.firstIndex(where: { $0.id == post.id }),
           let commentIndex = posts[postIndex].comments.firstIndex(where: { $0.id == comment.id }) {
            // 更新评论点赞数
            // 在实际应用中，应该实现切换点赞状态的逻辑
            let updatedComment = posts[postIndex].comments[commentIndex].updatedLikes()
            
            // 创建新的评论数组
            var newComments = posts[postIndex].comments
            newComments[commentIndex] = updatedComment
            
            // 创建新的帖子对象并替换原帖子
            let updatedPost = UserPostModel(
                id: posts[postIndex].id,
                username: posts[postIndex].username,
                userAvatar: posts[postIndex].userAvatar,
                content: posts[postIndex].content,
                images: posts[postIndex].images,
                datePosted: posts[postIndex].datePosted,
                likes: posts[postIndex].likes,
                comments: newComments,
                isLikedByCurrentUser: posts[postIndex].isLikedByCurrentUser,
                isBookmarkedByCurrentUser: posts[postIndex].isBookmarkedByCurrentUser
            )
            
            // 更新帖子数组
            posts[postIndex] = updatedPost
        }
    }
    
    /**
     * 生成虚拟角色回复
     * @param characterID 角色ID
     * @param comment 用户评论
     * @param postContent 帖子内容
     * @param completion 完成回调
     */
    func generateVirtualCharacterReply(
        characterID: String,
        toComment comment: String,
        inPost postContent: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🤖 开始生成虚拟角色回复: 角色=\(characterID)")
        
        // 创建一个临时的UUID作为帖子ID，用于inviteCharactersToComment方法
        let tempPostId = UUID().uuidString
        
        // 创建一个通知观察者变量
        let notificationName = NSNotification.Name("CharacterReplyGenerated")
        
        // 使用类型注解来声明观察者变量
        var observer: NSObjectProtocol?
        
        // 创建闭包
        let observerBlock: (Notification) -> Void = { [weak self] notification in
            // 检查通知是否包含我们需要的信息
            guard let _ = self,
                  let userInfo = notification.userInfo,
                  let notificationCharacterID = userInfo["characterID"] as? String,
                  let reply = userInfo["reply"] as? String,
                  notificationCharacterID == characterID else {
                return
            }
            
            // 收到匹配的角色回复，移除观察者并调用完成回调
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
            completion(.success(reply))
        }
        
        // 设置观察者
        observer = NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: .main,
            using: observerBlock
        )
        
        // 设置一个超时计时器，确保不会无限等待
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
            completion(.failure(NSError(domain: "PostViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成回复超时"])))
        }
        
        // 使用统一的inviteCharactersToComment方法
        VirtualCharacterService.shared.inviteCharactersToComment(
            characterIDs: [characterID],
            postId: tempPostId,
            postAuthor: nil
        )
    }
    
    /**
     * 获取帖子的相关评论作为上下文
     */
    private func getRelevantComments(for postId: UUID, limit: Int) -> [String] {
        // 使用布尔测试直接检查是否存在匹配的帖子
        guard posts.contains(where: { $0.id == postId }) else { return [] }
        
        // 获取匹配的帖子
        let post = posts.first { $0.id == postId }!
        
        // 获取最近的评论
        let comments = post.comments
        let recentComments = Array(comments.prefix(limit))
        
        // 转换为字符串数组
        return recentComments.map { "\($0.username): \($0.content)" }
    }
    
    /**
     * 生成虚拟角色评论
     * @param post 帖子
     * @param character 角色
     */
    func generateVirtualCharacterComment(for post: UserPostModel, from character: PHCharacterModel) {
        // 使用角色名作为ID
        let characterID = character.name.lowercased()
        
        // 使用布尔测试直接检查帖子是否存在
        guard posts.contains(where: { $0.id == post.id }) else { return }
        
        print("🚀 开始生成虚拟角色评论 - 角色ID: \(characterID), 帖子内容: \"\(String(post.content.prefix(50)))...\"")
        
        // 检查API配置
        if let apiKey = APIConfigManager.shared.apiKey {
            print("✅ API密钥已配置: \(apiKey.prefix(5))...")
            print("🌐 当前API端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        } else {
            print("⚠️ 警告: API密钥未配置，将导致API调用失败")
        }
        
        // 使用统一的inviteCharactersToComment方法，确保所有角色评论生成都使用相同的批量生成流程
        virtualCharacterService.inviteCharactersToComment(
            characterIDs: [characterID],
            postId: post.id.uuidString,
            postAuthor: post.username
        )
        
        print("📝 已请求生成角色评论，通知已发送")
    }
    
    /**
     * 获取角色头像
     * @param characterID 角色ID
     * @return 角色头像系统图标名称
     */
    private func getCharacterAvatar(for characterID: String) -> String {
        // 使用CharacterAvatarService获取头像名称
        return CharacterAvatarService.shared.getAvatarName(for: characterID)
    }
    
    /**
     * 获取角色名称
     * @param characterID 角色ID
     * @return 角色名称
     */
    private func getCharacterName(for characterID: String) -> String {
        switch characterID {
        case "einstein":
            return "爱因斯坦"
        case "shakespeare":
            return "莎士比亚"
        case "davinci":
            return "达芬奇"
        case "goku":
            return "孙悟空"
        case "holmes":
            return "福尔摩斯"
        case "naruto":
            return "漩涡鸣人"
        case "kongzi":
            return "孔子"
        case "newton":
            return "牛顿"
        case "libai":
            return "李白"
        default:
            return "虚拟角色"
        }
    }
    
    /**
     * 根据用户评论自动触发虚拟角色的回复
     * @param postIndex 帖子索引
     * @param content 用户评论内容
     */
    func autoGenerateVirtualReplies(postIndex: Int, to content: String) {
        // 在实际应用中，这里可以实现更复杂的逻辑：
        // 1. 分析用户评论内容，确定应该由哪个角色回复
        // 2. 使用NLP技术确定评论的主题和情感
        // 3. 根据评论与角色专业领域的相关度选择响应的角色
        
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ PostViewModel: 自动生成回复的后台任务超时")
        }
        
        print("🔄 PostViewModel: 创建自动生成回复后台任务，ID: \(backgroundTaskID)")
        
        // 确保帖子索引有效
        guard postIndex >= 0 && postIndex < posts.count else {
            print("⚠️ 无效的帖子索引: \(postIndex)")
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
            return
        }
        
        // 获取帖子内容和ID
        let post = posts[postIndex]
        let postContent = post.content
        let postId = post.id
        
        // 此处简单实现：随机选择1-2个角色回复
        let characters = ["einstein", "shakespeare", "davinci", "goku", "holmes", "naruto"]
        let randomCharacters = Array(characters.shuffled().prefix(Int.random(in: 1...2)))
        
        // 使用批量API调用生成回复
        print("🚀 开始批量生成\(randomCharacters.count)个角色的回复")
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: randomCharacters,
            postId: postId.uuidString,
            postContent: postContent,
            postAuthor: post.username
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                print("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                
                // 为每个角色添加回复，添加一定的延迟使回复看起来更自然
                for (index, (characterID, commentContent)) in commentsMap.enumerated() {
                    // 添加累加的延迟，让回复看起来更自然
                    let delay = Double.random(in: 1.5...3.0) + Double(index) * 1.5
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // 创建虚拟角色回复
                        let virtualReply = DetailedCommentModel(
                            username: self.getCharacterName(for: characterID),
                            userAvatar: self.getCharacterAvatar(for: characterID),
                            content: commentContent,
                            datePosted: Date().addingTimeInterval(Double.random(in: 30...120)),
                            isVirtualCharacter: true,
                            characterID: characterID
                        )
                        
                        // 使用addComment方法添加到帖子，确保应用过滤逻辑
                        print("📝 添加\(characterID)的回复到帖子")
                        self.posts[postIndex].addComment(virtualReply)
                        
                        // 发送通知刷新UI
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PostCommentsUpdated"),
                            object: nil,
                            userInfo: ["postID": postId.uuidString]
                        )
                        
                        // 添加震动反馈
                        self.hapticFeedback()
                        
                        // 如果是最后一个角色的回复，结束后台任务
                        if index == commentsMap.count - 1 {
                            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                print("🏁 所有虚拟角色回复任务已完成")
                            }
                        }
                    }
                }
                
            case .failure(let error):
                print("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                
                // 结束后台任务
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }
        }
    }
    
    func handleSmartCommentReply(postIndex: Int, commentIndex: Int, replyContent: String) {
        // 验证索引有效
        guard postIndex >= 0, postIndex < posts.count,
              commentIndex >= 0, commentIndex < posts[postIndex].comments.count else {
            print("错误: 无效的帖子或评论索引")
            return
        }
        
        // 获取要回复的评论
        let originalComment = posts[postIndex].comments[commentIndex]
        
        // 创建用户回复评论
        let userReply = DetailedCommentModel(
            id: UUID(),
            username: "当前用户",
            userAvatar: "user_avatar",
            content: replyContent,
            datePosted: Date(),
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: originalComment.id,
            replyToUsername: originalComment.username
        )
        
        // 添加用户回复
        posts[postIndex].comments.append(userReply)
        print("✅ 用户回复已添加")
        
        // 获取帖子内容用于生成回复
        let postContent = posts[postIndex].content
        let post = posts[postIndex]
        
        // 添加后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ 后台任务超时")
        }
        
        // 准备要生成回复的角色列表
        var charactersToRespond: [String] = []
        
        // 1. 如果原评论来自虚拟角色，添加该角色
        if originalComment.isVirtualCharacter, let characterID = originalComment.characterID {
            print("🤖 被回复的角色将回应用户")
            charactersToRespond.append(characterID)
        }
        // 如果回复的是帖子作者，添加作者
        else if originalComment.username == post.username {
            if let authorCharacterId = getCharacterIdByName(post.username) {
                print("🤖 帖子作者将回应用户回复")
                charactersToRespond.append(authorCharacterId)
            }
        }
        
        // 2. 随机决定是否让其他角色也参与评论(50%几率)
        if Bool.random() {
            print("🤖 另一个虚拟角色将加入讨论")
            
            // 获取所有可用角色ID
            var availableCharacters = ["einstein", "shakespeare", "davinci", "kongzi", "libai"]
            
            // 排除已经回复的角色
            if let originalCharacterID = originalComment.characterID?.lowercased() {
                availableCharacters.removeAll { $0 == originalCharacterID }
            }
            
            // 排除帖子作者(如果作者不是被回复的角色)
            if let authorCharacterId = getCharacterIdByName(post.username)?.lowercased(),
               originalComment.characterID?.lowercased() != authorCharacterId {
                availableCharacters.removeAll { $0 == authorCharacterId }
            }
            
            // 如果还有可用角色，随机选择一个
            if !availableCharacters.isEmpty {
                let selectedCharacter = availableCharacters.randomElement()!
                charactersToRespond.append(selectedCharacter)
            }
        }
        
        // 如果没有角色需要回应，直接结束
        if charactersToRespond.isEmpty {
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
            return
        }
        
        print("🔄 准备批量生成\(charactersToRespond.count)个角色的回复")
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: charactersToRespond,
            postId: post.id.uuidString,
            postContent: postContent,
            postAuthor: post.username
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                print("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                
                // 为每个角色添加回复，添加一定的延迟使回复看起来更自然
                for (index, (characterID, content)) in commentsMap.enumerated() {
                    // 根据角色类型添加不同的延迟
                    var delay: Double
                    if index == 0 && originalComment.characterID == characterID {
                        // 被回复的角色回复较快
                        delay = Double.random(in: 1.5...3.0)
                    } else {
                        // 其他角色回复较慢
                        delay = Double.random(in: 4.0...7.0)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // 创建虚拟角色回复
                        let virtualReply = DetailedCommentModel(
                            username: self.getCharacterName(for: characterID),
                            userAvatar: self.getCharacterAvatar(for: characterID),
                            content: content,
                            datePosted: Date().addingTimeInterval(Double.random(in: 30...120)),
                            isVirtualCharacter: true,
                            characterID: characterID,
                            parentCommentId: userReply.id, // 回复到用户的回复
                            replyToUsername: "当前用户"
                        )
                        
                        // 添加到帖子
                        print("📝 添加\(characterID)的回复到用户回复ID: \(userReply.id)")
                        self.posts[postIndex].addReplyToParent(parentId: userReply.id, reply: virtualReply)
                        
                        // 发送通知刷新UI
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PostCommentsUpdated"),
                            object: nil,
                            userInfo: ["postID": post.id.uuidString]
                        )
                        
                        // 添加震动反馈
                        self.hapticFeedback()
                        
                        // 如果是最后一个角色的回复，结束后台任务
                        if index == commentsMap.count - 1 {
                            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                print("🏁 所有虚拟角色回复任务已完成")
                            }
                        }
                    }
                }
                
            case .failure(let error):
                print("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                
                // 回退到逐个生成回复
                for (index, characterID) in charactersToRespond.enumerated() {
                    let delay = (index == 0) ? Double.random(in: 1.5...3.0) : Double.random(in: 4.0...7.0)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // 使用API生成虚拟角色的回复
                        self.generateVirtualCharacterReply(
                            characterID: characterID,
                            toComment: replyContent,
                            inPost: postContent,
                            completion: { result in
                                if case .success(let content) = result {
                                    print("✅ 单独生成角色回复 - \(self.getCharacterName(for: characterID)): \(content.prefix(30))...")
                                    
                                    // 创建虚拟角色回复
                                    let virtualReply = DetailedCommentModel(
                                        username: self.getCharacterName(for: characterID),
                                        userAvatar: self.getCharacterAvatar(for: characterID),
                                        content: content,
                                        datePosted: Date().addingTimeInterval(Double.random(in: 30...120)),
                                        isVirtualCharacter: true,
                                        characterID: characterID,
                                        parentCommentId: userReply.id,
                                        replyToUsername: "当前用户"
                                    )
                                    
                                    // 添加到帖子
                                    self.posts[postIndex].addReplyToParent(parentId: userReply.id, reply: virtualReply)
                                    
                                    // 发送通知刷新UI
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PostCommentsUpdated"),
                                        object: nil,
                                        userInfo: ["postID": post.id.uuidString]
                                    )
                                    
                                    // 添加震动反馈
                                    self.hapticFeedback()
                                    
                                    // 如果是最后一个角色的回复，结束后台任务
                                    if index == charactersToRespond.count - 1 {
                                        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                            UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                            print("🏁 所有虚拟角色回复任务已完成")
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    /**
     * 根据角色ID获取角色名称
     * @param characterID 角色ID
     * @return 角色名称
     */
    private func getCharacterNameById(_ id: String) -> String? {
        return getCharacterName(for: id)
    }
    
    /**
     * 根据角色名称获取角色ID
     * @param name 角色名称
     * @return 角色ID
     */
    private func getCharacterIdByName(_ name: String) -> String? {
        switch name {
        case "爱因斯坦": return "einstein"
        case "莎士比亚": return "shakespeare"
        case "达芬奇": return "davinci"
        case "孔子": return "kongzi"
        case "牛顿": return "newton"
        case "李白": return "libai"
        case "福尔摩斯": return "holmes"
        case "孙悟空": return "sunwukong"
        case "漩涡鸣人": return "naruto"
        default: return nil
        }
    }
    
    /**
     * 处理评论回复
     * @param postId 帖子ID
     * @param commentId 评论ID
     * @param commentContent 评论内容
     * @param replyTo 回复给的用户名
     */
    func handleCommentReply(postId: UUID, commentId: UUID, commentContent: String, replyTo: String) {
        print("🔄 处理评论回复: postId=\(postId), commentId=\(commentId), content=\(commentContent)")
        
        // 查找帖子
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else {
            print("❌ 未找到帖子: \(postId)")
            return
        }
        
        // 找到帖子
        let post = posts[postIndex]
        
        // 平铺所有评论以便查找目标评论
        let flattenedComments = getFlattenedComments(forPost: postId)
        
        // 查找被回复的评论
        guard let targetComment = flattenedComments.first(where: { $0.id == commentId }) else {
            print("❌ 未找到评论: \(commentId)")
            return
        }
        
        // 打印目标评论的结构，帮助调试
        print("📊 目标评论结构:")
        targetComment.printStructure()
        
        print("📝 创建用户回复，回复给: \(replyTo)")
        
        // 创建用户回复评论
        let userReply = DetailedCommentModel(
            username: "当前用户",
            userAvatar: "person.circle.fill",
            content: commentContent,
            datePosted: Date(),
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: commentId, // 设置父评论ID为被回复的评论ID
            replyToUsername: replyTo    // 设置回复用户名
        )
        
        // 保存用户回复的ID，用于后续添加虚拟角色回复
        let userReplyId = userReply.id
        print("📝 创建用户回复，ID: \(userReplyId)")
        
        // 创建帖子的可变副本
        let updatedPost = post
        
        // 添加用户回复到父评论
        updatedPost.addReplyToParent(parentId: commentId, reply: userReply)
        
        // 更新帖子
        posts[postIndex] = updatedPost
        
        // 检查更新是否成功
        let updatedFlattenedComments = getFlattenedComments(forPost: updatedPost.id)
        if let updatedTargetComment = updatedFlattenedComments.first(where: { $0.id == commentId }),
           let addedReply = updatedTargetComment.replies.first(where: { $0.id == userReplyId }) {
            print("✅ 成功添加回复，检查到回复ID: \(addedReply.id)")
            print("📊 更新后的评论结构:")
            updatedTargetComment.printStructure()
        } else {
            print("⚠️ 回复可能未成功添加到嵌套结构中")
        }
        
        // 发送通知刷新UI
        NotificationCenter.default.post(
            name: NSNotification.Name("PostCommentsUpdated"),
            object: nil,
            userInfo: ["postID": postId.uuidString]
        )
        
        // 确保UI刷新
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshPostComments"),
            object: nil
        )
        
        // 收集需要回复的角色ID
        var characterIDsToReply: [String] = []
        
        // 检查是否回复的是虚拟角色的评论
        if targetComment.isVirtualCharacter, let characterID = targetComment.characterID {
            print("🔍 找到虚拟角色评论，添加到回复列表，角色ID: \(characterID)")
            characterIDsToReply.append(characterID)
        }
        
        // 如果是回复帖子作者且对方是虚拟角色
        if targetComment.username == post.username && post.characterID != nil,
           let characterID = post.characterID, !characterIDsToReply.contains(characterID) {
            print("🔍 回复帖子作者，添加到回复列表，角色ID: \(characterID)")
            characterIDsToReply.append(characterID)
        }
        
        // 如果没有角色需要回复
        if characterIDsToReply.isEmpty {
            print("⚠️ 没有找到需要回复的虚拟角色，跳过生成回复")
            return
        }
        
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ 生成批量回复的后台任务超时")
        }
        
        // 使用批量API调用生成回复
        print("🚀 开始批量生成\(characterIDsToReply.count)个角色的回复")
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: characterIDsToReply,
            postId: postId.uuidString,
            postContent: post.content,
            postAuthor: post.username
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                print("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                
                // 获取帖子索引
                guard let postIndex = self.posts.firstIndex(where: { $0.id == postId }) else {
                    print("❌ 无法找到帖子，无法添加批量生成的回复")
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                    return
                }
                
                // 为了模拟自然对话，确定响应时间和顺序
                // 第一个角色（通常是被回复角色或帖子作者）响应较快
                let firstCharacterId = characterIDsToReply.first!
                let otherCharacterIds = Array(characterIDsToReply.dropFirst())
                
                // 第一个角色回复
                if let content = commentsMap[firstCharacterId] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.0)) {
                        // 创建虚拟角色回复
                        let virtualReply = DetailedCommentModel(
                            username: self.getCharacterName(for: firstCharacterId),
                            userAvatar: self.getCharacterAvatar(for: firstCharacterId),
                            content: content,
                            datePosted: Date().addingTimeInterval(Double.random(in: 30...60)),
                            isVirtualCharacter: true,
                            characterID: firstCharacterId,
                            parentCommentId: userReplyId, // 回复用户评论ID
                            replyToUsername: "当前用户"   // 明确设置回复对象
                        )
                        
                        // 添加到帖子 - 添加到用户评论下
                        print("📝 添加\(firstCharacterId)的回复到用户评论ID: \(userReplyId)")
                        self.posts[postIndex].addReplyToParent(parentId: userReplyId, reply: virtualReply)
                        
                        // 发送通知刷新UI
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PostCommentsUpdated"),
                            object: nil,
                            userInfo: ["postID": postId.uuidString]
                        )
                        
                        // 添加震动反馈
                        self.hapticFeedback()
                    }
                }
                
                // 其他角色回复（延迟更长）
                for (index, characterID) in otherCharacterIds.enumerated() {
                    if let content = commentsMap[characterID] {
                        // 添加累加的延迟，让回复看起来更自然
                        let delay = Double.random(in: 3.0...5.0) + Double(index) * 1.5
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            // 创建虚拟角色回复
                            let virtualReply = DetailedCommentModel(
                                username: self.getCharacterName(for: characterID),
                                userAvatar: self.getCharacterAvatar(for: characterID),
                                content: content,
                                datePosted: Date().addingTimeInterval(Double.random(in: 60...180)),
                                isVirtualCharacter: true,
                                characterID: characterID,
                                parentCommentId: userReplyId, // 回复用户的评论，而不是原始评论
                                replyToUsername: "当前用户"   // 明确设置回复对象
                            )
                            
                            // 添加到帖子
                            print("📝 添加\(characterID)的回复到用户评论ID: \(userReplyId)")
                            self.posts[postIndex].addReplyToParent(parentId: userReplyId, reply: virtualReply)
                            
                            // 发送通知刷新UI
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PostCommentsUpdated"),
                                object: nil,
                                userInfo: ["postID": postId.uuidString]
                            )
                            
                            // 添加震动反馈
                            self.hapticFeedback()
                            
                            // 如果是最后一个角色的回复，结束后台任务
                            if index == otherCharacterIds.count - 1 {
                                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                    print("🏁 所有虚拟角色回复任务已完成")
                                }
                            }
                        }
                    }
                }
                
                // 如果没有其他角色，在第一个角色回复后结束任务
                if otherCharacterIds.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                            UIApplication.shared.endBackgroundTask(backgroundTaskID)
                            print("🏁 虚拟角色回复任务已完成")
                        }
                    }
                }
                
            case .failure(let error):
                print("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                
                // 备用方案：使用原来的单独API调用方法
                print("🔄 使用备用方案，单独生成回复")
                
                // 检查是否回复的是虚拟角色的评论
                if targetComment.isVirtualCharacter,
                   let characterID = targetComment.characterID {
                    print("🔍 找到虚拟角色评论，准备生成回复，角色ID: \(characterID)")
                    
                    // 使用API生成虚拟角色回复
                    self.generateVirtualCharacterReply(
                        characterID: characterID,
                        toComment: commentContent,
                        inPost: post.content,
                        completion: { [weak self] result in
                            guard let self = self else { return }
                            
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let replyContent):
                                    print("✅ API生成回复成功: \(replyContent.prefix(50))...")
                                    
                                    // 添加虚拟角色的回复
                                    let characterName = self.getCharacterName(for: characterID)
                                    let characterAvatar = self.getCharacterAvatar(for: characterID)
                                    
                                    // 创建虚拟角色回复，回复用户的评论
                                    let virtualReply = DetailedCommentModel(
                                        username: characterName,
                                        userAvatar: characterAvatar,
                                        content: replyContent,
                                        datePosted: Date().addingTimeInterval(Double.random(in: 30...120)),
                                        isVirtualCharacter: true,
                                        characterID: characterID,
                                        parentCommentId: userReplyId, // 回复用户的评论ID
                                        replyToUsername: "当前用户"   // 明确设置回复对象
                                    )
                                    
                                    // 添加到帖子 - 添加到用户评论下
                                    if let postIndex = self.posts.firstIndex(where: { $0.id == postId }) {
                                        print("📝 添加虚拟角色回复到用户评论下，用户评论ID: \(userReplyId)")
                                        
                                        // 使用临时变量来创建帖子副本
                                        let updatedPost = self.posts[postIndex]
                                        updatedPost.addReplyToParent(parentId: userReplyId, reply: virtualReply)
                                        
                                        // 更新帖子数组
                                        self.posts[postIndex] = updatedPost
                                        
                                        print("✅ 已添加API生成的虚拟角色回复到原始评论下")
                                    }
                                    
                                    // 添加震动反馈
                                    self.hapticFeedback()
                                    
                                case .failure(let error):
                                    print("❌ API生成回复失败: \(error.localizedDescription)")
                                    // API失败时不再使用模板回复，直接跳过
                                    print("⚠️ API失败，跳过回复生成")
                                }
                                
                                // 发送通知，刷新评论UI
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("PostCommentsUpdated"),
                                    object: nil,
                                    userInfo: ["postID": postId.uuidString]
                                )
                                
                                // 确保UI刷新
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("RefreshPostComments"),
                                    object: nil
                                )
                            }
                        }
                    )
                }
                
                // 结束后台任务
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }
        }
    }
    
    /**
     * 查找当前用户的最后一条评论ID
     * @param inPost 帖子ID
     * @return 当前用户最后评论的ID，如果未找到则返回nil
     */
    func findLastCommentFromCurrentUser(inPost postId: UUID) -> UUID? {
        // 使用布尔测试直接检查是否存在匹配的帖子
        guard posts.contains(where: { $0.id == postId }) else {
            print("❌ findLastCommentFromCurrentUser: 未找到帖子")
            return nil
        }
        
        // 获取所有评论（包括嵌套回复）的平铺列表
        let allComments = getFlattenedComments(forPost: postId)
        
        // 倒序遍历所有评论，找到当前用户的最后一条评论
        for comment in allComments.reversed() {
            if comment.username == "当前用户" {
                print("✅ 找到当前用户的最后一条评论，ID: \(comment.id)")
                return comment.id
            }
        }
        
        print("❌ 未找到当前用户的评论")
        return nil
    }
    
    /**
     * 添加震动反馈
     */
    func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /**
     * 获取帖子的所有评论（包括嵌套回复）
     * @param forPost 帖子ID
     * @return 所有评论的平铺列表
     */
    func getFlattenedComments(forPost postId: UUID) -> [DetailedCommentModel] {
        // 查找帖子
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else {
            print("❌ getFlattenedComments: 未找到帖子")
            return []
        }
        
        let post = posts[postIndex]
        var flattenedComments: [DetailedCommentModel] = []
        
        // 递归函数用于遍历评论树
        func traverseComments(_ comments: [DetailedCommentModel]) {
            for comment in comments {
                flattenedComments.append(comment)
                // 递归处理回复
                if !comment.replies.isEmpty {
                    traverseComments(comment.replies)
                }
            }
        }
        
        // 从顶层评论开始遍历
        traverseComments(post.comments)
        return flattenedComments
    }
    
    /**
     * 生成虫洞共鸣帖子
     * 基于用户提供的情境和期望生成历史人物的见解
     */
    func generateResonancePosts(situation: String, expectation: String, keyword: String? = nil) async throws -> [UserPostModel] {
        print("🔄 开始生成虫洞共鸣帖子 - 使用角色系统")
        
        // 构建话题
        let topic = "关于[\(situation)]，期望[\(expectation)]\(keyword != nil ? "，关键词[\(keyword!)]" : "")"
        
        // 获取虫洞共鸣配置的生成数量
        let count = ExplorationCountManager.shared.getCount(for: .resonance)
        print("📊 虫洞共鸣配置的生成数量: \(count)篇")
        
        do {
            // 使用generateSingleTypeContent方法代替generateRandomContent
            // 这个方法会自动生成带有评论的内容并将评论保存到CommentStore中
            let contentItems = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ContentItem], Error>) in
                ContentGeneratorService.shared.generateSingleTypeContent(contentType: .resonance, topic: topic, count: count)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("⚠️ 生成共鸣帖子失败: \(error)")
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { items in
                            print("✅ 成功生成\(items.count)篇虫洞共鸣内容")
                            continuation.resume(returning: items)
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            print("📝 将生成的\(contentItems.count)篇内容转换为帖子模型")
            
            // 转换为帖子模型
            var userPosts: [UserPostModel] = []
            for item in contentItems {
                // 从CommentStore获取评论
                let commentItems = CommentStore.shared.getComments(forContentID: item.id)
                print("📝 为内容ID=\(item.id)获取到\(commentItems.count)条评论")
                
                // 使用优化的评论转换方法
                let comments = convertCommentItems(commentItems: commentItems)
                
                let userPost = UserPostModel(
                    id: UUID(uuidString: item.id) ?? UUID(),
                    username: item.characterName,
                    userAvatar: item.characterAvatar ?? "person.circle.fill",
                    content: item.content,
                    images: [],
                    datePosted: item.timestamp,
                    likes: item.likes,
                    comments: comments, // 使用转换后的评论
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false,
                    contentType: ContentGeneratorService.ContentType.resonance.rawValue,
                    source: "wormhole" // 添加来源标识，表示来自虫洞探索
                )
                userPosts.append(userPost)
            }
            
            // 如果没有生成任何帖子，返回备用帖子
            if userPosts.isEmpty {
                print("⚠️ 警告：生成虫洞共鸣帖子失败，使用备用帖子")
                return createBackupResonancePosts(situation: situation, expectation: expectation, keyword: keyword, count: count)
            }
            
            return userPosts
        } catch {
            print("❌ 生成虫洞共鸣帖子时出错: \(error.localizedDescription)")
            return createBackupResonancePosts(situation: situation, expectation: expectation, keyword: keyword, count: count)
        }
    }
    
    /**
     * 创建备用虫洞共鸣帖子
     * 当API生成失败时使用
     */
    private func createBackupResonancePosts(
        situation: String,
        expectation: String,
        keyword: String? = nil,
        count: Int = 1
    ) -> [UserPostModel] {
        print("📝 创建备用虫洞共鸣帖子，数量: \(count)")
        
        var backupPosts: [UserPostModel] = []
        let historicalFigures = [
            ("爱因斯坦", "atom"),
            ("莎士比亚", "book.fill"),
            ("孔子", "person.bust"),
            ("达芬奇", "paintpalette"),
            ("居里夫人", "testtube.2"),
            ("牛顿", "function")
        ]
        
        // 根据请求的count创建相应数量的备用帖子
        for _ in 0..<min(count, historicalFigures.count) {
            // 随机选择一个历史人物
            let figureIndex = Int.random(in: 0..<historicalFigures.count)
            let (figureName, figureAvatar) = historicalFigures[figureIndex]
            
            // 创建一个评论
            let emergencyComment = DetailedCommentModel(
                id: UUID(),
                username: "爱因斯坦",
                userAvatar: "atom",
                content: "在思考\(situation)这个问题时，我认为最重要的是保持开放的心态。我们需要超越常规思维，从\(expectation)的角度寻找新的可能性。",
                datePosted: Date().addingTimeInterval(-1800),
                isVirtualCharacter: true,
                characterID: "einstein",
                parentCommentId: nil,
                replyToUsername: nil,
                likes: 15
            )
            
            let keywordText = keyword != nil ? "关于'\(keyword!)'，" : ""
            let emergencyPost = UserPostModel(
                id: UUID(),
                username: figureName,
                userAvatar: figureAvatar,
                content: "在人生的舞台上，我们常常面临\(situation)的困境。正如我在作品中所探讨的，每个人都在寻找自己的答案和意义。\(keywordText)我想分享一些思考：生活的本质不在于寻找确定的答案，而在于享受探索的过程。",
                images: [],
                datePosted: Date().addingTimeInterval(-Double(backupPosts.count) * 300), // 设置不同的时间
                likes: 25,
                comments: [emergencyComment],
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false,
                contentType: ContentGeneratorService.ContentType.resonance.rawValue,
                source: "wormhole" // 添加来源标识，表示来自虫洞探索
            )
            
            backupPosts.append(emergencyPost)
        }
            
        return backupPosts
    }
    
    /**
     * 根据类型索引异步生成内容
     * 解决递归调用问题的新方法
     */
    func generatePostsByTypeIndexAsync(typeIndex: Int) async throws -> [UserPostModel] {
        print("🔄 开始异步生成帖子: 类型索引=\(typeIndex)")
        
        // 获取ContentType
        let contentType = convertTypeIndexToContentType(typeIndex)
        
        // 获取内容生成数量
        let count = ExplorationCountManager.shared.getCount(for: contentType)
        print("📊 使用[类型=\(contentType.rawValue)]的生成数量: \(count)")
        
        // 使用带评论的内容生成方法
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[UserPostModel], Error>) in
            // 使用generateSingleTypeContent方法生成内容
            ContentGeneratorService.shared.generateSingleTypeContent(contentType: contentType, topic: nil, count: count)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("⚠️ 生成\(contentType.rawValue)内容失败: \(error)")
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { items in
                        print("✅ 成功生成\(items.count)篇\(contentType.rawValue)内容")
                        
                        // 将ContentItem转换为UserPostModel
                        var userPosts: [UserPostModel] = []
                        for item in items {
                            // 从CommentStore获取评论
                            let commentItems = CommentStore.shared.getComments(forContentID: item.id)
                            print("📝 为内容ID=\(item.id)获取到\(commentItems.count)条评论")
                            
                            // 使用优化的评论转换方法
                            let comments = self.convertCommentItems(commentItems: commentItems)
                            
                            let userPost = UserPostModel(
                                id: UUID(uuidString: item.id) ?? UUID(),
                                username: item.characterName,
                                userAvatar: item.characterAvatar ?? "person.circle.fill",
                                content: item.content,
                                images: [],
                                datePosted: item.timestamp,
                                likes: item.likes,
                                comments: comments, // 使用转换后的评论
                                isLikedByCurrentUser: false,
                                isBookmarkedByCurrentUser: false,
                                contentType: contentType.rawValue,
                                source: "wormhole" // 添加来源标识，表示来自虫洞探索
                            )
                            userPosts.append(userPost)
                        }
                        
                        // 如果没有生成任何帖子，返回备用帖子
                        if userPosts.isEmpty {
                            print("⚠️ 警告：生成\(contentType.rawValue)帖子失败，使用备用帖子")
                            let backupPosts = self.createBackupPosts(for: contentType)
                            continuation.resume(returning: backupPosts)
                        } else {
                            continuation.resume(returning: userPosts)
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 生成单条内容
     */
    func generateSinglePost(for characterID: String, contentType: ContentGeneratorService.ContentType) async throws -> UserPostModel {
        print("🔄 开始生成单条帖子: 角色ID=\(characterID), 内容类型=\(contentType.rawValue)")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UserPostModel, Error>) in
            ContentGeneratorService.shared.generateContent(for: characterID, contentType: contentType)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { result in
                        // 从CommentStore获取评论
                        let commentItems = CommentStore.shared.getComments(forContentID: result.id)
                        
                        // 使用优化的评论转换方法
                        let comments = self.convertCommentItems(commentItems: commentItems)
                        
                        let userPost = UserPostModel(
                            id: UUID(uuidString: result.id) ?? UUID(),
                            username: result.characterName,
                            userAvatar: result.characterAvatar ?? "person.circle.fill",
                            content: result.content,
                            images: [],
                            datePosted: result.timestamp,
                            likes: result.likes,
                            comments: comments,
                            isLikedByCurrentUser: false,
                            isBookmarkedByCurrentUser: false,
                            contentType: contentType.rawValue,
                            source: "wormhole" // 添加来源标识，表示来自虫洞探索
                        )
                        
                        continuation.resume(returning: userPost)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 根据内容类型生成帖子
     * @param typeIndex 内容类型索引
     * @param count 可选的生成数量参数，如果为nil则从ExplorationCountManager获取
     * @param withComments 是否生成评论
     * @param commentsPerPost 每个帖子的评论数
     * @return [UserPostModel] 生成的帖子数组
     */
    func generatePostsByCreationType(typeIndex: Int, count: Int? = nil, withComments: Bool = false, commentsPerPost: Int = 3) async throws -> [UserPostModel] {
        // 获取ContentType
        let contentType = convertTypeIndexToContentType(typeIndex)
        
        // 从ExplorationCountManager获取生成数量，如果提供了count参数，则使用提供的值
        let actualCount = count ?? ExplorationCountManager.shared.getCount(for: contentType)
        
        print("📊 为类型[\(contentType.rawValue)]生成帖子，数量: \(actualCount)，\(withComments ? "带评论" : "不带评论")")
        
        if withComments {
            // 使用现有的generatePostsWithComments方法生成带评论的帖子
            return try await generatePostsWithComments(
                typeIndex: typeIndex,
                count: actualCount,
                topic: nil,
                commentersCount: commentsPerPost
            )
        } else {
            // 使用新的异步内容生成方法避免递归调用
            return try await generatePostsByTypeIndexAsync(typeIndex: typeIndex)
        }
    }
    
    /**
     * 为内容项生成评论
     */
    func generateCommentsForContentItem(item: ContentItem, count: Int) async throws -> [DetailedCommentModel] {
        // 获取随机角色来做评论
        let characters = CharacterSystem.shared.getRandomCharacters(count: count, excludeID: item.characterID)
        
        var comments: [DetailedCommentModel] = []
        for character in characters {
            let commentText = await ContentGeneratorService.shared.generateQuickComment(
                forContent: item.content,
                byCharacter: character
            )
            
            let comment = DetailedCommentModel(
                id: UUID(),
                username: character.name,
                userAvatar: character.avatarName,
                content: commentText,
                datePosted: Date().addingTimeInterval(-Double.random(in: 600...3600)),
                isVirtualCharacter: true,
                characterID: character.id,
                parentCommentId: nil,
                likes: Int.random(in: 0...50)
            )
            comments.append(comment)
        }
        
        return comments
    }
    
    /**
     * 创建备用帖子
     */
    private func createBackupPosts(for contentType: ContentGeneratorService.ContentType) -> [UserPostModel] {
        print("📝 创建备用帖子")
        
        // 创建一个备用帖子
        var username = "历史人物"
        var avatar = "person.circle.fill" // 使用系统图标作为默认头像
        var content = "思考是人类最伟大的能力，无论在哪个时代。"
        
        switch contentType {
        case .mood:
            username = "李白"
            avatar = "libai"
            content = "【日常心情】今日小酌，独坐山亭。云卷云舒，月上树梢，倒影入酒杯。一生漂泊，竟是为了此刻的宁静与美好。自斟自饮之间，写下几句不成形的诗。大概这就是所谓的人生吧，孤独中寻找内心的欢喜。🌙"
        case .ancient2modern:
            username = "爱因斯坦"
            avatar = "einstein"
            content = "如果我生活在今天的社会，我会对信息技术的发展感到惊叹。量子计算与量子力学有着深刻联系，但更令我着迷的是，普通人获取知识的门槛如此之低，使科学民主化成为可能。我的相对论需要数年才能被少数专家理解，而现在，知识可以瞬间传遍全球。（现代解读：科技使知识传播速度加快，但理解深度仍需时间）"
        case .creativeIdea:
            username = "达芬奇"
            avatar = "davinci"
            content = "设计灵感：观察鸟翼与气流互动，我设想一种可收缩的翼型装置，能根据气流强度自动调整形态。或许人类飞行器不该模仿鸟的形态，而应理解飞行的原理。相似地，绘画也不是复制视觉，而是理解光影本质。自然是最伟大的设计师。"
        case .timelineEvent:
            username = "莎士比亚"
            avatar = "shakespeare"
            content = "【1601年，伦敦环球剧院】今日《哈姆雷特》首演，观众反应超出预期。扮演主角的伯贝奇出色诠释了王子的内心挣扎，特别是「生存还是毁灭」的独白，让全场屏息。看着观众被戏剧感染的面庞，我意识到：人类渴望在艺术中看见自己的影子，而好的戏剧正是映照灵魂的镜子。这部作品或许会比我想象的更加长久。"
        default:
            username = "历史人物"
            avatar = "person.circle.fill" // 确保默认头像是系统图标
            content = "在人生的旅途中，我们常常需要面对困境和挑战。保持学习的热情与乐趣，才能找到真正的解决之道。困难只是暂时的，而智慧的追求则是永恒的。"
        }
        
        // 创建一个评论
        let comment = DetailedCommentModel(
            id: UUID(),
            username: "尤达大师",
            userAvatar: "yoda", // 尤达大师有自己的头像
            content: "有见地，你的想法是。思考更深，我们必须。",
            datePosted: Date().addingTimeInterval(-1800),
            isVirtualCharacter: true,
            characterID: "yoda",
            parentCommentId: nil,
            replyToUsername: nil,
            likes: 15
        )
        
        let emergencyPost = UserPostModel(
            id: UUID(),
            username: username,
            userAvatar: avatar,
            content: content,
            images: [],
            datePosted: Date(),
            likes: 25,
            comments: [comment],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: ContentGeneratorService.ContentType.resonance.rawValue,
            source: "wormhole" // 添加来源标识，表示来自虫洞探索
        )
        
        return [emergencyPost]
    }
    
    /**
     * 添加帖子到数据模型
     * @param newPosts 要添加的帖子数组
     */
    func addPosts(_ newPosts: [UserPostModel]) {
        print("🌀 开始添加帖子到数据模型，帖子数量: \(newPosts.count)")
        
        // 为了避免重复添加，检查每个帖子的ID
        for post in newPosts {
            if !posts.contains(where: { $0.id == post.id }) {
                // 将新帖子插入到数组开头，而不是追加到末尾
                posts.insert(post, at: 0)
                print("✅ 添加帖子成功: \(post.id), 作者: \(post.username), 位置: 最前面")
            } else {
                print("⚠️ 跳过已存在的帖子: \(post.id)")
            }
        }
        
        print("🌀 帖子添加完成，当前总帖子数: \(posts.count)")
    }
    
    /**
     * 生成带初始评论的帖子
     * @param typeIndex 内容类型索引
     * @param topic 可选的主题
     * @param commentersCount 评论者数量
     * @return (post: UserPostModel, comments: [DetailedCommentModel]) 生成的帖子对象和评论数组
     */
    func generatePostWithInitialComments(typeIndex: Int, topic: String? = nil, commentersCount: Int = 3) async throws -> (post: UserPostModel, comments: [DetailedCommentModel]) {
        // 创建本地取消令牌集合，避免资源泄漏
        var localCancellables = Set<AnyCancellable>()
        
        print("🔄 开始生成带初始评论的帖子: 类型索引=\(typeIndex), 评论数=\(commentersCount)")
        
        // 确保typeIndex在有效范围内
        guard typeIndex >= 0 && typeIndex < ContentTypeManager.shared.contentTypes.count else {
            print("❌ 无效的类型索引: \(typeIndex)")
            throw PostGenerationError.invalidTypeIndex
        }
        
        // 获取内容类型
        let contentType = convertTypeIndexToContentType(typeIndex)
        print("👉 已转换内容类型: \(contentType.rawValue)")
        
        return try await withCheckedThrowingContinuation { continuation in
            // 使用ContentGeneratorService生成带评论的内容
            contentGeneratorService.generateRandomContentWithComments(contentType: contentType, topic: topic)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 生成带评论的内容失败: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                            // 清理本地取消令牌
                            localCancellables.removeAll()
                        }
                    },
                    receiveValue: { result in
                        print("✅ 成功生成带评论的内容: 评论数=\(result.comments.count)")
                        
                        // 将ContentItem转换为UserPostModel
                        let post = self.convertContentItemToUserPost(result.contentItem)
                        print("📝 创建帖子: ID=\(post.id), 作者=\(post.username)")
                        
                        // 将CommentItem转换为DetailedCommentModel
                        let comments = result.comments.map { commentItem -> DetailedCommentModel in
                            print("✅ 添加评论: 来自=\(commentItem.characterName), 内容=\(commentItem.content.prefix(30))...")
                            return DetailedCommentModel(
                                id: UUID(uuidString: commentItem.id) ?? UUID(),
                                username: commentItem.characterName,
                                userAvatar: commentItem.characterAvatar ?? "person.circle.fill",
                                content: commentItem.content,
                                datePosted: commentItem.timestamp,
                                isVirtualCharacter: true,
                                characterID: commentItem.characterId,
                                parentCommentId: commentItem.parentCommentId != nil ? UUID(uuidString: commentItem.parentCommentId!) : nil,
                                replyToUsername: nil,
                                likes: commentItem.likes,
                                isLikedByCurrentUser: Bool.random()
                            )
                        }
                        
                        print("🎉 生成完成: 帖子=1, 评论=\(comments.count)")
                        
                        // 继续执行
                        continuation.resume(returning: (post, comments))
                        
                        // 清理本地取消令牌
                        localCancellables.removeAll()
                    }
                )
                .store(in: &localCancellables)
        }
    }
    
    /**
     * 生成带评论的多个帖子
     * @param typeIndex 内容类型索引
     * @param count 生成的帖子数量
     * @param topic 可选的主题
     * @param commentersCount 每个帖子的评论者数量
     * @return [UserPostModel] 生成的帖子数组
     */
    func generatePostsWithComments(typeIndex: Int, count: Int = 1, topic: String? = nil, commentersCount: Int = 3) async throws -> [UserPostModel] {
        var generatedPosts: [UserPostModel] = []
        
        print("🌟 开始生成\(count)个带评论的帖子: 类型索引=\(typeIndex), 每个帖子评论数=\(commentersCount)")
        
        // 逐个生成帖子和评论
        for i in 0..<count {
            do {
                print("📝 生成第\(i+1)个帖子...")
                let result = try await generatePostWithInitialComments(typeIndex: typeIndex, topic: topic, commentersCount: commentersCount)
                
                // 将生成的评论添加到帖子中
                let post = result.post
                post.comments = result.comments
                
                print("✅ 成功添加\(result.comments.count)条评论到帖子")
                generatedPosts.append(post)
            } catch {
                print("❌ 生成带评论的帖子失败: \(error.localizedDescription)")
                // 继续生成下一个帖子
                continue
            }
        }
        
        // 如果没有成功生成任何帖子，抛出错误
        if generatedPosts.isEmpty {
            print("⚠️ 未能生成任何帖子")
            throw PostGenerationError.failedToGeneratePosts
        }
        
        print("🎉 成功生成\(generatedPosts.count)个带评论的帖子")
        return generatedPosts
    }
    
    /**
     * 将类型索引转换为ContentType
     */
    private func convertTypeIndexToContentType(_ typeIndex: Int) -> ContentGeneratorService.ContentType {
        return ContentTypeManager.shared.getContentType(for: typeIndex) ?? .resonance
    }
    
    /**
     * 将ContentItem转换为UserPostModel
     */
    func convertContentItemToUserPost(_ item: ContentItem) -> UserPostModel {
        // 直接使用item中的所有属性，确保原始内容不被修改
        let post = UserPostModel(
            id: UUID(uuidString: item.id) ?? UUID(),
            username: item.characterName,
            userAvatar: item.characterAvatar != nil ? item.characterAvatar! : "person.circle.fill",
            content: item.content,
            images: [],
            datePosted: item.timestamp,
            likes: item.likes,
            comments: [],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: item.contentType,
            characterID: item.characterID,
            source: "wormhole" // 添加来源标识，表示来自虫洞探索
        )
        
        // 打印日志，便于调试内容传递
        print("🔍 转换ContentItem为UserPost: 类型=\(item.contentType), 内容长度=\(item.content.count)字")
        if item.contentType == "古潮新语" {
            print("📝 古潮新语原始内容: \(item.content)")
        }
        
        return post
    }
    
    /**
     * 生成帖子
     * @param contentType 内容类型
     * @param count 生成数量
     * @param source 来源标识
     * @return [UserPostModel] 生成的帖子数组
     */
    func generatePosts(contentType: ContentGeneratorService.ContentType, count: Int, source: String? = nil) async throws -> [UserPostModel] {
        print("📊 开始生成\(count)篇\(contentType.rawValue)内容，来源: \(source ?? "未指定")")
        
        return try await withCheckedThrowingContinuation { continuation in
            // 使用ContentGeneratorService生成内容
            ContentGeneratorService.shared.generateSingleTypeContent(
                contentType: contentType,
                count: count
            )
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 生成内容失败: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { items in
                        print("✅ 成功生成\(items.count)篇\(contentType.rawValue)内容")
                        
                        // 将ContentItem转换为UserPostModel
                        var userPosts: [UserPostModel] = []
                        for item in items {
                            // 从CommentStore获取评论
                            let commentItems = CommentStore.shared.getComments(forContentID: item.id)
                            print("📝 为内容ID=\(item.id)获取到\(commentItems.count)条评论")
                            
                            // 将CommentItem转换为DetailedCommentModel
                            let comments = commentItems.map { commentItem -> DetailedCommentModel in
                                return DetailedCommentModel(
                                    id: UUID(uuidString: commentItem.id) ?? UUID(),
                                    username: commentItem.characterName,
                                    userAvatar: commentItem.characterAvatar ?? "person.circle.fill",
                                    content: commentItem.content,
                                    datePosted: commentItem.timestamp,
                                    isVirtualCharacter: true,
                                    characterID: commentItem.characterId,
                                    parentCommentId: commentItem.parentCommentId != nil ? UUID(uuidString: commentItem.parentCommentId!) : nil,
                                    replyToUsername: nil,
                                    likes: commentItem.likes,
                                    isLikedByCurrentUser: Bool.random()
                                )
                            }
                            
                            let userPost = UserPostModel(
                                id: UUID(uuidString: item.id) ?? UUID(),
                                username: item.characterName,
                                userAvatar: item.characterAvatar ?? "person.circle.fill",
                                content: item.content,
                                images: [],
                                datePosted: item.timestamp,
                                likes: item.likes,
                                comments: comments, // 使用从CommentStore获取的评论
                                isLikedByCurrentUser: false,
                                isBookmarkedByCurrentUser: false,
                                contentType: contentType.rawValue,
                                source: source // 添加来源标识
                            )
                            userPosts.append(userPost)
                        }
                        
                        // 如果没有生成任何帖子，返回备用帖子
                        if userPosts.isEmpty {
                            print("⚠️ 警告：生成\(contentType.rawValue)帖子失败，使用备用帖子")
                            let backupPosts = self.createBackupPosts(for: contentType)
                            
                            // 为备用帖子添加来源标识
                            for i in 0..<backupPosts.count {
                                backupPosts[i].source = source
                            }
                            
                            continuation.resume(returning: backupPosts)
                        } else {
                            continuation.resume(returning: userPosts)
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 添加回复到特定评论
     * 这个方法是公开的，可以被外部调用
     * @param parentId 父评论ID
     * @param reply 回复评论模型
     */
    func addReplyToComment(parentId: UUID, reply: DetailedCommentModel) {
        print("📝 ViewModel: 添加回复到评论ID: \(parentId)")
        print("📝 回复内容: \"\(reply.content.prefix(30))...\"")
        print("📝 回复者: \(reply.username), 父评论ID: \(reply.parentCommentId?.uuidString ?? "nil")")
        
        // 查找包含目标评论的帖子
        for (postIndex, post) in posts.enumerated() {
            print("🔍 检查帖子[\(postIndex)], ID: \(post.id)")
            
            // 尝试查找评论 (先平铺所有评论进行查找)
            let allComments = getFlattenedComments(forPost: post.id)
            if let targetComment = allComments.first(where: { $0.id == parentId }) {
                print("✅ 找到目标评论在帖子[\(postIndex)]中，评论用户名: \(targetComment.username)")
                
                // 创建帖子的可变副本
                let updatedPost = post
                
                // 直接使用帖子模型的方法添加回复
                updatedPost.addReplyToParent(parentId: parentId, reply: reply)
                
                // 更新帖子数组
                posts[postIndex] = updatedPost
                
                // 输出回复是否成功添加的验证信息
                let updatedFlattenedComments = getFlattenedComments(forPost: updatedPost.id)
                if let updatedParentComment = updatedFlattenedComments.first(where: { $0.id == parentId }) {
                    print("📊 添加回复后，目标评论现在有 \(updatedParentComment.replies.count) 条回复")
                    
                    // 验证回复是否存在
                    let replyExists = updatedParentComment.replies.contains { $0.id == reply.id }
                    print(replyExists ? "✅ 验证成功: 回复已正确添加" : "❌ 验证失败: 回复未找到")
                }
                
                // 触发UI更新通知
                objectWillChange.send()
                
                print("🔄 已发送ViewModel更新通知")
                return
            }
        }
        
        print("⚠️ 未找到对应的父评论ID: \(parentId)，无法添加回复")
    }
    
    /**
     * 递归查找嵌套评论并添加回复
     * @param comments 评论数组引用
     * @param parentId 父评论ID
     * @param reply 要添加的回复
     * @return 是否成功添加回复
     */
    private func findAndAddReplyToNestedComment(comments: inout [DetailedCommentModel], parentId: UUID, reply: DetailedCommentModel) -> Bool {
        for i in 0..<comments.count {
            // 检查当前评论是否是目标父评论
            if comments[i].id == parentId {
                comments[i].replies.append(reply)
                print("🔍 ViewModel: 找到目标评论，ID: \(parentId)，用户名: \(comments[i].username)，添加回复成功")
                return true
            }
            
            // 递归检查当前评论的回复
            if !comments[i].replies.isEmpty {
                var updatedReplies = comments[i].replies
                if findAndAddReplyToNestedComment(comments: &updatedReplies, parentId: parentId, reply: reply) {
                    comments[i].replies = updatedReplies
                    print("🔍 ViewModel: 在评论 \(comments[i].id) (\(comments[i].username)) 的回复中找到目标评论，添加回复成功")
                    return true
                }
            }
        }
        
        return false
    }
    
    /**
     * 将CommentItem转换为DetailedCommentModel的辅助方法
     * 确保正确处理嵌套关系
     */
    private func convertCommentItems(commentItems: [CommentItem]) -> [DetailedCommentModel] {
        print("🔄 开始转换评论，总数：\(commentItems.count)条")
        
        // 第一步：创建所有评论的映射，供后续处理引用
        var commentMap = [String: DetailedCommentModel]()
        var topLevelComments = [DetailedCommentModel]()
        
        // 第二步：先创建所有DetailedCommentModel实例
        let initialComments = commentItems.map { commentItem -> (DetailedCommentModel, String?) in
            let comment = DetailedCommentModel(
                id: UUID(uuidString: commentItem.id) ?? UUID(),
                username: commentItem.characterName,
                userAvatar: commentItem.characterAvatar ?? "person.circle.fill",
                content: commentItem.content,
                datePosted: commentItem.timestamp,
                isVirtualCharacter: true,
                characterID: commentItem.characterId,
                parentCommentId: nil, // 先设置为nil，后续处理
                replyToUsername: nil, // 先设置为nil，后续处理
                likes: commentItem.likes,
                isLikedByCurrentUser: Bool.random()
            )
            
            // 保存评论ID映射
            commentMap[commentItem.id] = comment
            
            return (comment, commentItem.parentCommentId)
        }
        
        // 第三步：构建评论层次结构
        for (index, (comment, parentId)) in initialComments.enumerated() {
            if let parentId = parentId, let parentComment = commentMap[parentId] {
                // 这是一条回复评论
                print("📝 评论#\(index+1) ID=\(comment.id)是\(parentComment.username)的回复")
                
                // 设置父评论ID和回复用户名
                var mutableComment = comment
                mutableComment.parentCommentId = parentComment.id
                mutableComment.replyToUsername = parentComment.username
                
                // 将回复添加到父评论的replies数组中
                var updatedParent = parentComment
                updatedParent.replies.append(mutableComment)
                commentMap[parentId] = updatedParent // 更新映射中的父评论
                
                // 打印调试信息
                print("✅ 已将回复添加到父评论，父评论ID=\(parentId)，父评论用户=\(updatedParent.username)，现有回复数=\(updatedParent.replies.count)")
            } else {
                // 这是一条顶级评论
                topLevelComments.append(comment)
                print("📝 评论#\(index+1) ID=\(comment.id)是顶级评论，用户=\(comment.username)")
            }
        }
        
        // 第四步：从commentMap中获取更新后的顶级评论
        var finalTopLevelComments: [DetailedCommentModel] = []
        for comment in topLevelComments {
            if let updatedComment = commentMap[comment.id.uuidString] {
                finalTopLevelComments.append(updatedComment)
            } else {
                finalTopLevelComments.append(comment)
            }
        }
        
        // 打印最终结构
        print("📊 评论层次结构:")
        for (index, comment) in finalTopLevelComments.enumerated() {
            print("📊 顶级评论[\(index)]: ID=\(comment.id), 用户=\(comment.username), 回复数=\(comment.replies.count)")
            for (replyIndex, reply) in comment.replies.enumerated() {
                print("  └─ 回复[\(replyIndex)]: ID=\(reply.id), 用户=\(reply.username), 回复给=\(reply.replyToUsername ?? "未知")")
            }
        }
        
        print("✅ 评论转换完成: \(finalTopLevelComments.count)条顶级评论，包含嵌套回复")
        
        // 返回所有顶级评论，它们的replies数组中已经包含了各自的回复
        return finalTopLevelComments
    }
    
    /**
     * 生成历史人物对话帖子
     * 基于用户提供的话题生成两个历史人物之间的对话
     */
    func generateDialoguePosts(topic: String) async throws -> [UserPostModel] {
        print("🔄 开始生成历史对话帖子: 话题=\(topic)")
        
        // 获取对话生成配置
        let count = ExplorationCountManager.shared.getCount(for: .resonance) // 使用存在的类型
        print("📊 对话配置的生成数量: \(count)篇")
        
        do {
            // 注意：这里应该添加对话生成功能，临时使用resonance内容生成
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[(ContentItem, [CommentItem])], Error>) in
                ContentGeneratorService.shared.generateRandomContent(contentType: .resonance, count: count, topic: topic)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { contentItems in
                            // 模拟结果格式，每个内容项配一个空的评论数组
                            let result = contentItems.map { ($0, [CommentItem]()) }
                            continuation.resume(returning: result)
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            print("✅ 成功生成\(result.count)篇历史对话内容")
            
            // 转换为帖子模型
            var userPosts: [UserPostModel] = []
            for (item, commentItems) in result {
                print("📝 处理对话内容ID=\(item.id)，包含\(commentItems.count)条评论")
                
                // 使用优化的评论转换方法
                let comments = convertCommentItems(commentItems: commentItems)
                
                let userPost = UserPostModel(
                    id: UUID(uuidString: item.id) ?? UUID(),
                    username: item.characterName,
                    userAvatar: item.characterAvatar ?? "person.circle.fill",
                    content: item.content,
                    images: [],
                    datePosted: item.timestamp,
                    likes: item.likes,
                    comments: comments, // 使用转换后的评论
                    isLikedByCurrentUser: false,
                    isBookmarkedByCurrentUser: false,
                    contentType: ContentGeneratorService.ContentType.resonance.rawValue, // 使用存在的类型
                    source: "wormhole" // 添加来源标识，表示来自虫洞探索
                )
                userPosts.append(userPost)
            }
            
            // 如果没有生成任何帖子，返回备用帖子
            if userPosts.isEmpty {
                print("⚠️ 警告：生成历史对话帖子失败，使用备用帖子")
                return createBackupPosts(for: .resonance) // 使用虫洞共鸣备用帖子
            }
            
            return userPosts
        } catch {
            print("❌ 生成历史对话帖子时出错: \(error)")
            return createBackupPosts(for: .resonance) // 使用虫洞共鸣备用帖子
        }
    }
    
    // 在添加新评论、回复、点赞等操作后，务必同步刷新comments
    func refreshComments() {
        if let currentPost = posts.first {
            self.comments = currentPost.getTopLevelComments()
        }
    }

    /**
     * 获取用户关注的角色，并根据互动频率排序
     * @return 排序后的角色模型数组
     */
    func getFollowedCharactersSortedByInteraction() -> [CharacterModel] {
        // 1. 获取用户关注的角色名称列表
        let followedUsernames = UserDefaults.standard.stringArray(forKey: "FollowedUsers") ?? []
        
        // 2. 获取所有角色的互动分数
        let interactionScores = UserInterestTracker.shared.interestModel.figureCounts
        
        // 3. 获取所有已知的角色模型
        let allCharacters = CharacterModel.allCharacters // 使用所有角色，包括虚构角色
        
        // 4. 根据互动分数对所有角色进行排序
        let sortedByInteraction = allCharacters.sorted { (charA, charB) -> Bool in
            let scoreA = interactionScores[charA.name] ?? 0
            let scoreB = interactionScores[charB.name] ?? 0
            return scoreA > scoreB
        }
        
        // 5. 如果有关注的角色，优先显示关注的角色
        if !followedUsernames.isEmpty {
            let followedCharacters = allCharacters.filter { character in
                followedUsernames.contains(character.name)
            }
            
            // 根据互动分数排序关注的角色
            let sortedFollowed = followedCharacters.sorted { (charA, charB) -> Bool in
                let scoreA = interactionScores[charA.name] ?? 0
                let scoreB = interactionScores[charB.name] ?? 0
                return scoreA > scoreB
            }
            
            return sortedFollowed
        } else {
            // 如果没有关注的角色，返回基于互动分数排序的角色
            return Array(sortedByInteraction.prefix(5))
        }
    }
}
