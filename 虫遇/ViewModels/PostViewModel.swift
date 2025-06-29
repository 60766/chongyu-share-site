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
        
        // 格式化评论内容，确保文本格式正确
        let formattedContent = UserPostModel.formatContent(content)
        
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 如果有父评论ID（回复），使用带parentCommentId参数的方法
            if let parentId = replyToCommentID {
                // 获取被回复的评论，以获取用户名
                let replyToName = getCommentById(commentId: parentId, in: posts[index].comments)?.username
                
                posts[index].addComment(
                    username: "当前用户",
                    userAvatar: "current_user_avatar",
                    content: formattedContent,
                    parentCommentId: parentId,
                    replyToName: replyToName
                )
                
                // 如果是回复某个评论，查找该评论是否来自虚拟角色，并让该角色回复
                if let comment = getCommentById(commentId: parentId, in: posts[index].comments),
                   comment.isVirtualCharacter,
                   let characterID = comment.characterID {
                    // 让被回复的虚拟角色回复用户
                    self.generateVirtualCharacterReply(
                        characterID: characterID,
                        toComment: formattedContent,
                        inPost: post.content,
                        completion: { result in
                            if case .success(let content) = result {
                                print("✅ 虚拟角色回复已生成: \(content.prefix(30))...")
                                
                                // 添加一些延迟，使回复看起来更自然
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...3.0)) {
                                    if let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) {
                                        // 查找用户最新的评论ID
                                        if let userCommentId = self.findLastCommentFromCurrentUser(inPost: post.id) {
                                            // 创建虚拟角色回复
                                            let virtualReply = DetailedCommentModel(
                                                username: self.getCharacterName(for: characterID),
                                                userAvatar: self.getCharacterAvatar(for: characterID),
                                                content: content,
                                                isVirtualCharacter: true,
                                                characterID: characterID,
                                                parentCommentId: userCommentId,
                                                replyToUsername: "当前用户",
                                                replyToName: "当前用户"
                                            )
                                            
                                            // 添加到帖子
                                            self.posts[postIndex].addReplyToComment(parentId: userCommentId, reply: virtualReply)
                                            
                                            // 发送通知刷新UI
                                            NotificationCenter.default.post(
                                                name: NSNotification.Name("PostCommentsUpdated"),
                                                object: nil,
                                                userInfo: ["postID": post.id.uuidString]
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    )
                }
            } else {
                // 直接添加评论到主帖子
                posts[index].addComment(
                    username: "当前用户",
                    userAvatar: "current_user_avatar",
                    content: formattedContent
                )
                
                // 找到用户评论的ID，用于后续回复
                if let userCommentId = findLastCommentFromCurrentUser(inPost: post.id) {
                    
                    // 1. 首先，让帖子作者回复用户评论
                    let postAuthor = posts[index].username
                    let authorCharacterId = getCharacterIdByName(postAuthor)
                    
                    // 如果帖子作者是虚拟角色，获取其characterID
                    if let authorCharacterId = authorCharacterId {
                        print("🤖 帖子作者将回复用户评论，作者：\(postAuthor), ID：\(authorCharacterId)")
                        
                        // 帖子作者回复用户评论
                        self.generateVirtualCharacterReply(
                            characterID: authorCharacterId,
                            toComment: formattedContent,
                            inPost: post.content,
                            completion: { [weak self] result in
                                guard let self = self else { return }
                                
                                if case .success(let content) = result {
                                    print("✅ 帖子作者回复已生成: \(content.prefix(30))...")
                                    
                                    // 添加一些延迟，使回复看起来更自然
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.0)) {
                                        if let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) {
                                            // 创建作者的回复
                                            let authorReply = DetailedCommentModel(
                                                username: postAuthor,
                                                userAvatar: self.getCharacterAvatar(for: authorCharacterId),
                                                content: content,
                                                isVirtualCharacter: true,
                                                characterID: authorCharacterId,
                                                parentCommentId: userCommentId,
                                                replyToUsername: "当前用户",
                                                replyToName: "当前用户"
                                            )
                                            
                                            // 添加作者回复
                                            self.posts[postIndex].addReplyToComment(parentId: userCommentId, reply: authorReply)
                                            
                                            // 发送通知刷新UI
                                            NotificationCenter.default.post(
                                                name: NSNotification.Name("PostCommentsUpdated"),
                                                object: nil,
                                                userInfo: ["postID": post.id.uuidString]
                                            )
                                            
                                            // 2. 之后，随机选择1-2个其他虚拟角色参与评论
                                            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3.0...5.0)) {
                                                self.addRandomCharacterReplies(to: post, originalCommentId: userCommentId, authorId: authorCharacterId)
                                            }
                                        }
                                    }
                                }
                            }
                        )
                    } else {
                        // 如果帖子作者不是虚拟角色，随机选择虚拟角色评论
                        print("📝 帖子作者不是虚拟角色，随机选择角色评论")
                        addRandomCharacterReplies(to: post, originalCommentId: userCommentId, authorId: nil)
                    }
                }
            }
        }
    }
    
    /**
     * 添加随机虚拟角色回复
     * @param post 帖子对象
     * @param originalCommentId 原始评论ID
     * @param authorId 帖子作者ID（用于排除）
     */
    private func addRandomCharacterReplies(to post: UserPostModel, originalCommentId: UUID, authorId: String?) {
        // 所有可用的虚拟角色
        var availableCharacters = ["einstein", "shakespeare", "davinci", "confucius", "newton", "libai"]
        
        // 如果有作者ID，排除作者
        if let authorId = authorId {
            availableCharacters.removeAll { $0 == authorId.lowercased() }
        }
        
        // 随机选择1-2个角色回复
        let replyCount = Int.random(in: 1...2)
        let selectedCharacters = Array(availableCharacters.shuffled().prefix(replyCount))
        
        for (index, characterID) in selectedCharacters.enumerated() {
            // 添加延迟，让回复看起来更自然
            let delay = Double.random(in: 2.0...4.0) + Double(index) * 2.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                if let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) {
                    // 获取原始评论内容，用于生成回复
                    let commentContent = self.getCommentContent(commentId: originalCommentId, in: post)
                    
                    // 获取被回复的用户名，用于显示
                    let replyToName = self.getCommentById(commentId: originalCommentId, in: self.posts[postIndex].comments)?.username ?? "当前用户"
                    
                    self.generateVirtualCharacterReply(
                        characterID: characterID,
                        toComment: commentContent,
                        inPost: post.content,
                        completion: { result in
                            if case .success(let content) = result {
                                print("✅ 额外角色回复已生成 - \(self.getCharacterName(for: characterID)): \(content.prefix(30))...")
                                
                                // 创建虚拟角色回复
                                let virtualReply = DetailedCommentModel(
                                    username: self.getCharacterName(for: characterID),
                                    userAvatar: self.getCharacterAvatar(for: characterID),
                                    content: content,
                                    isVirtualCharacter: true,
                                    characterID: characterID,
                                    parentCommentId: originalCommentId,
                                    replyToUsername: "当前用户",
                                    replyToName: replyToName
                                )
                                
                                // 添加到帖子
                                self.posts[postIndex].addReplyToComment(parentId: originalCommentId, reply: virtualReply)
                                
                                // 发送通知刷新UI
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("PostCommentsUpdated"),
                                    object: nil,
                                    userInfo: ["postID": post.id.uuidString]
                                )
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
     * @param toComment 被回复的评论内容
     * @param inPost 帖子内容
     * @param completion 完成回调
     */
    func generateVirtualCharacterReply(
        characterID: String,
        toComment comment: String,
        inPost postContent: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("🤖 开始生成虚拟角色回复: 角色=\(characterID)")
        
        // 从VirtualCharacterService生成回复
        VirtualCharacterService.shared.generateCharacterComment(
            characterID: characterID,
            userComment: comment,
            postContent: postContent
        ) { result in
            switch result {
            case .success(let content):
                print("✅ VirtualCharacterService生成回复成功")
                completion(.success(content))
            case .failure(let error):
                print("❌ VirtualCharacterService生成回复失败: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    /**
     * 获取帖子的相关评论作为上下文
     */
    private func getRelevantComments(for postIndex: Int, limit: Int) -> [String] {
        guard postIndex < posts.count else { return [] }
        
        // 获取最近的评论
        let comments = posts[postIndex].comments
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
        
        // 获取帖子索引
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        print("🚀 开始生成虚拟角色评论 - 角色ID: \(characterID), 帖子内容: \"\(String(post.content.prefix(50)))...\"")
        
        // 检查API配置
        if let apiKey = APIConfigManager.shared.apiKey {
            print("✅ API密钥已配置: \(apiKey.prefix(5))...")
            print("🌐 当前API端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        } else {
            print("⚠️ 警告: API密钥未配置，将导致API调用失败")
        }
        
        // 使用VirtualCharacterService生成评论
        virtualCharacterService.generateCharacterComment(
            characterID: characterID,
            forPost: post.content
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ API生成评论失败: \(error.localizedDescription)")
                    
                    // 切换API端点
                    print("🔄 尝试切换API端点...")
                    APIConfigManager.shared.switchEndpoint()
                    
                    // 不再创建备用回复，只记录错误
                    print("❌ API生成失败，不创建任何评论")
                }
            },
            receiveValue: { commentContent in
                print("✅ API生成评论成功: \"\(String(commentContent.prefix(50)))...\"")
                print("💾 评论内容完整: \"\(commentContent)\"")
                
                // 不再添加API生成标记，直接使用原始内容
                let finalContent = commentContent
                
                // 添加评论到帖子
                let comment = DetailedCommentModel(
                    id: UUID(),
            username: character.name,
                    userAvatar: character.avatar,
                    content: finalContent,
            datePosted: Date(),
            isVirtualCharacter: true,
            characterID: characterID
        )
        
                self.posts[postIndex].comments.append(comment)
                
                print("📝 已添加API生成的评论到帖子，通知UI刷新")
                
                // 发送通知以刷新UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                    object: nil,
                    userInfo: ["postID": post.id.uuidString]
                )
            }
        )
        .store(in: &cancellables)
    }
    
    /**
     * 获取角色头像
     * @param characterID 角色ID
     * @return 角色头像系统图标名称
     */
    private func getCharacterAvatar(for characterID: String) -> String {
        switch characterID {
        case "einstein":
            return "atom" // 原子图标适合爱因斯坦
        case "shakespeare":
            return "book.fill" // 书籍图标适合莎士比亚
        case "davinci":
            return "paintpalette.fill" // 绘画图标适合达芬奇
        case "goku":
            return "person.fill.viewfinder" // 人物图标适合孙悟空
        case "holmes":
            return "magnifyingglass" // 放大镜适合福尔摩斯
        case "naruto":
            return "tornado" // 螺旋适合鸣人
        case "confucius":
            return "scroll.fill" // 卷轴适合孔子
        case "newton":
            return "arrow.down.circle.fill" // 下降箭头适合牛顿
        case "libai":
            return "text.book.closed.fill" // 诗集适合李白
        default:
            return "person.circle.fill" // 通用人物图标
        }
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
        case "confucius":
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
        
        // 此处简单实现：随机选择1-2个角色回复
        let characters = ["einstein", "shakespeare", "davinci", "goku", "holmes", "naruto"]
        let randomCharacters = Array(characters.shuffled().prefix(Int.random(in: 1...2)))
        
        // 使用DispatchGroup来跟踪所有任务的完成
        let group = DispatchGroup()
        
        for characterID in randomCharacters {
            // 避免重复回复
            // 添加随机延迟，模拟真实场景，但在后台线程中执行
            group.enter()
            DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 1...3)) {
                self.generateVirtualCharacterReply(
                    characterID: characterID,
                    toComment: content,
                    inPost: self.posts[postIndex].content,
                    completion: { result in
                        // 处理完成回调
                        group.leave()
                    }
                )
            }
        }
        
        // 在所有任务完成后结束后台任务
        group.notify(queue: .main) {
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                print("🏁 所有虚拟角色回复任务已完成")
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
        
        // 获取帖子和用户回复索引
        let post = posts[postIndex]
        let _ = posts[postIndex].comments.count - 1
        
        // 添加后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            print("⚠️ 后台任务超时")
        }
        
        // 1. 首先，让被回复的角色回应用户（如果原评论来自虚拟角色）
        if originalComment.isVirtualCharacter, let characterID = originalComment.characterID {
            print("🤖 被回复的角色将回应用户")
            // 添加延迟以模拟真实场景
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...3.0)) { [weak self] in
                guard let self = self else { return }
                // 使用API生成虚拟角色的回复
                self.generateVirtualCharacterReply(
                    characterID: characterID,
                    toComment: replyContent,
                    inPost: post.content,
                    completion: { result in
                        if case .success(let content) = result {
                            print("✅ 角色回复生成成功: \(content.prefix(30))...")
                        }
                    }
                )
            }
        }
        // 如果回复的是帖子作者，让作者回复
        else if originalComment.username == post.username {
            if let authorCharacterId = getCharacterIdByName(post.username) {
                print("🤖 帖子作者将回应用户回复")
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.0...3.5)) { [weak self] in
                    guard let self = self else { return }
                    self.generateVirtualCharacterReply(
                        characterID: authorCharacterId,
                        toComment: replyContent,
                        inPost: post.content,
                        completion: { result in
                            if case .success(let content) = result {
                                print("✅ 帖子作者回复生成成功: \(content.prefix(30))...")
                            }
                        }
                    )
                }
            }
        }
        
        // 2. 随机决定是否让其他角色也参与评论(50%几率)
        if Bool.random() {
            print("🤖 另一个虚拟角色将加入讨论")
            
            // 获取所有可用角色ID
            var availableCharacters = ["einstein", "shakespeare", "davinci", "confucius", "libai"]
            
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
                
                // 添加更长的延迟，让这个回复显得更自然
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 4.0...7.0)) { [weak self] in
                    guard let self = self else { return }
                    
                    // 使用API生成虚拟角色的回复
                    self.generateVirtualCharacterReply(
                        characterID: selectedCharacter,
                        toComment: replyContent,
                        inPost: post.content,
                        completion: { result in
                            if case .success(let content) = result {
                                print("✅ 额外角色回复生成成功: \(content.prefix(30))...")
                            }
                            
                            // 在任务完成时结束后台任务
                            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                print("🏁 所有虚拟角色回复任务已完成")
                            }
                        }
                    )
                }
                } else {
                // 如果没有其他可用角色，直接结束后台任务
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }
                } else {
            // 如果不添加额外角色，直接结束后台任务
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
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
        case "孔子": return "confucius"
        case "牛顿": return "newton"
        case "李白": return "libai"
        case "福尔摩斯": return "holmes"
        case "孙悟空": return "goku"
        case "漩涡鸣人": return "naruto"
        default: return nil
        }
    }
    
    /**
     * 处理评论回复
     * 处理用户对评论的回复，包括生成虚拟角色回复
     * @param postId 帖子ID
     * @param commentId 评论ID
     * @param commentContent 评论内容
     * @param replyTo 回复用户名
     */
    func handleCommentReply(postId: UUID, commentId: UUID, commentContent: String, replyTo: String) {
        print("🔄 处理评论回复: postId=\(postId), commentId=\(commentId), content=\(commentContent)")
        
        // 查找帖子
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else {
            print("❌ 未找到帖子: \(postId)")
            return
        }
        
        // 找到帖子和对应的评论
        let post = posts[postIndex]
        
        // 添加用户评论
        post.addReplyToComment(parentId: commentId, reply: DetailedCommentModel(
            username: "当前用户",
            userAvatar: "person.circle.fill",
            content: commentContent,
            parentCommentId: commentId,
            replyToUsername: replyTo
        ))
        
        print("✅ 已添加用户回复到评论")
        
        // 检查是否回复的是虚拟角色的评论
        let flattenedComments = self.getFlattenedComments(forPost: postId)
        guard let parentComment = flattenedComments.first(where: { $0.id == commentId }),
              parentComment.isVirtualCharacter,
              let characterID = parentComment.characterID else {
            print("⚠️ 非虚拟角色评论，跳过生成回复")
            return
        }
        
        print("🔍 找到虚拟角色评论，准备生成回复，角色ID: \(characterID)")
        
        // 使用API生成虚拟角色回复
        generateVirtualCharacterReply(
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
                        
                        // 添加API生成的回复到当前用户的评论下
                        if let userCommentId = self.findLastCommentFromCurrentUser(inPost: postId) {
                            // 创建虚拟角色回复
                            let virtualReply = DetailedCommentModel(
                                username: characterName,
                                userAvatar: characterAvatar,
                                content: replyContent,
                                isVirtualCharacter: true,
                                characterID: characterID,
                                parentCommentId: userCommentId,
                                replyToUsername: "当前用户"
                            )
                            
                            // 添加到帖子
                            post.addReplyToComment(parentId: userCommentId, reply: virtualReply)
                            
                            print("✅ 已添加API生成的虚拟角色回复")
                            
                            // 添加震动反馈
                            self.hapticFeedback()
                } else {
                            print("❌ 未找到当前用户的评论ID")
                        }
                        
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
    
    /**
     * 查找当前用户的最后一条评论ID
     * @param inPost 帖子ID
     * @return 当前用户最后评论的ID，如果未找到则返回nil
     */
    func findLastCommentFromCurrentUser(inPost postId: UUID) -> UUID? {
        // 查找帖子
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else {
            print("❌ findLastCommentFromCurrentUser: 未找到帖子")
            return nil
        }
        
        let post = posts[postIndex]
        
        // 倒序遍历评论，找到当前用户的最后一条评论
        for comment in post.comments.reversed() {
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
            
            // 转换ContentItem为UserPostModel
            var userPosts: [UserPostModel] = []
            for item in contentItems {
                // 从CommentStore获取评论
                let commentItems = CommentStore.shared.getComments(forContentID: item.id)
                print("📝 为内容ID=\(item.id)获取到\(commentItems.count)条评论")
                
                // 将CommentItem转换为DetailedCommentModel
                let comments = commentItems.map { commentItem -> DetailedCommentModel in
                    return DetailedCommentModel(
                        id: UUID(),
                        username: commentItem.characterName,
                        userAvatar: commentItem.characterAvatar ?? "default_avatar",
                        content: commentItem.content,
                        datePosted: commentItem.timestamp,
                        isVirtualCharacter: true,
                        characterID: commentItem.characterID,
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
                            
                            // 将CommentItem转换为DetailedCommentModel
                            let comments = commentItems.map { commentItem -> DetailedCommentModel in
                                return DetailedCommentModel(
                                    id: UUID(),
                                    username: commentItem.characterName,
                                    userAvatar: commentItem.characterAvatar ?? "default_avatar",
                                    content: commentItem.content,
                                    datePosted: commentItem.timestamp,
                                    isVirtualCharacter: true,
                                    characterID: commentItem.characterID,
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
        var avatar = "person.circle.fill"
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
            username = "孔子"
            avatar = "confucius"
            content = "在人生的旅途中，我们常常需要面对困境和挑战。正如我常对弟子所言，「知之者不如好之者，好之者不如乐之者」。无论遇到何种难题，保持学习的热情与乐趣，才能找到真正的解决之道。困难只是暂时的，而智慧的追求则是永恒的。"
        }
        
        // 创建一个评论
        let comment = DetailedCommentModel(
            id: UUID(),
            username: "尤达大师",
            userAvatar: "yoda",
            content: "有见地，你的想法是。思考更深，我们必须。",
            datePosted: Date().addingTimeInterval(-1800),
            isVirtualCharacter: true,
            characterID: "yoda",
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
                                id: UUID(),
                                username: commentItem.characterName,
                                userAvatar: commentItem.characterAvatar ?? "default_avatar",
                                content: commentItem.content,
                                datePosted: commentItem.timestamp,
                                isVirtualCharacter: true,
                                characterID: commentItem.characterID,
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
                                    id: UUID(),
                                    username: commentItem.characterName,
                                    userAvatar: commentItem.characterAvatar ?? "default_avatar",
                                    content: commentItem.content,
                                    datePosted: commentItem.timestamp,
                                    isVirtualCharacter: true,
                                    characterID: commentItem.characterID,
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
}
