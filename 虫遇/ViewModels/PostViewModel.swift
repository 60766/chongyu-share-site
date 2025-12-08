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
            // 移除自动保存，改为在关键节点手动触发保存
            // savePersistentPostsStub() // 注释掉自动保存
            
            // 同步 comments 为当前 post 的完整树结构
            if let currentPost = posts.first {
                self.comments = currentPost.getTopLevelComments()
            }
            
            // ⚡️ 优化：只在非初始化阶段且有实际变化时检查数据一致性
            // 避免启动时频繁检查影响性能
            #if DEBUG
            if isInitialized && !oldValue.isEmpty {
                validateDataConsistency()
            }
            #endif
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
    
    // 存储键
    private let postsStubKey = "PostsStub_v1"
    private let userPostsKey = "UserPosts_v1" // 专门存储用户帖子的键
    private let aiPostsKey = "AIPosts_v1" // 新增：专门存储AI生成帖子的键
    
    // 评论数据（用于显示最新的帖子详情）
    @Published var comments: [DetailedCommentModel] = []
    
    // 数据一致性状态
    @Published var isDataConsistent: Bool = true
    private var lastSaveTimestamp: Date = Date()
    private var pendingSaveOperation: DispatchWorkItem?
    
    // ⚡️ 初始化完成标志（用于避免启动时频繁的数据一致性检查）
    private var isInitialized: Bool = false
    
    // ⚡️ 内容变化追踪器（用于避免不必要的UI刷新）
    private let changeTracker = ContentChangeTracker.shared
    
    // ⚡️ 保存失败提示防抖（避免频繁提示）
    private var lastSaveFailureTime: Date?
    private let saveFailureDebounceInterval: TimeInterval = 5.0 // 5秒内只提示一次
    
    /**
     * 初始化PostViewModel
     */
    init() {
        // 初始化时先设置一个空数组，确保didSet不会在初始化过程中被触发
        _ = [UserPostModel]()
        
        // ⚡️ 优化：先加载少量关键帖子，快速显示UI
        let samplePosts = ModelData.samplePosts
        
        // 🔒 修复：欢迎帖子始终显示，不过滤
        self.posts = samplePosts
        
        #if DEBUG
        debugLog("⚡️ PostViewModel快速初始化完成，先显示 \(samplePosts.count) 条示例帖子")
        #endif
        
        // 监听数据恢复通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PostsDataRestored"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            #if DEBUG
            debugLog("📥 PostViewModel: 收到数据恢复通知，重新加载帖子")
            #endif
            self?.reloadPostsFromUserDefaults()
        }
        
        // ⚡️ 异步加载完整数据，不阻塞UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let loadStartTime = CFAbsoluteTimeGetCurrent()
            
            // 1. 恢复用户帖子
            let userPosts = self.restoreUserPostsData()
            
            // 2. 恢复AI生成的帖子
            let aiPosts = self.restoreAIPostsData()
            
            // 3. 合并所有帖子并去重
            var allPostsDict: [UUID: UserPostModel] = [:]
            
            // 添加用户帖子（优先级最高）
            for post in userPosts {
                allPostsDict[post.id] = post
            }
            
            // 添加AI帖子（如果ID不冲突）
            for post in aiPosts {
                if allPostsDict[post.id] == nil {
                    allPostsDict[post.id] = post
                }
            }
            
            // 🔒 修复：欢迎帖子始终显示在最底部，不因已看过而消失
            for post in samplePosts {
                if allPostsDict[post.id] == nil {
                    allPostsDict[post.id] = post
                }
            }
            
            // 按时间倒序排列，但欢迎帖子始终在最底部
            let uniquePosts = Array(allPostsDict.values).sorted { post1, post2 in
                // 如果一个是欢迎帖子，另一个不是，欢迎帖子排在最后
                let isPost1Welcome = post1.source == "welcome"
                let isPost2Welcome = post2.source == "welcome"
                
                if isPost1Welcome && !isPost2Welcome {
                    return false // post1 是欢迎帖子，排在后面
                } else if !isPost1Welcome && isPost2Welcome {
                    return true // post2 是欢迎帖子，排在后面
                } else {
                    // 都是或都不是欢迎帖子，按时间倒序
                    return post1.datePosted > post2.datePosted
                }
            }
            
            let loadTime = (CFAbsoluteTimeGetCurrent() - loadStartTime) * 1000
            #if DEBUG
            debugLog("🚀 PostViewModel后台加载完成:")
            debugLog("   - 用户帖子: \(userPosts.count) 条")
            debugLog("   - AI帖子: \(aiPosts.count) 条") 
            debugLog("   - 示例帖子: \(samplePosts.count) 条")
            debugLog("   - 总计: \(uniquePosts.count) 条")
            debugLog("   - 加载耗时: \(String(format: "%.0f", loadTime))ms")
            #endif
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.posts = uniquePosts
                
                // ⚡️ 初始化所有帖子的内容哈希值
                self.changeTracker.updatePostHashes(uniquePosts)
                
                #if DEBUG
                debugLog("✅ UI已更新，显示全部 \(uniquePosts.count) 条帖子")
                #endif
                
                // ⚡️ 标记初始化完成（延迟1秒后才启用数据一致性检查）
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isInitialized = true
                }
            }
        }
        
        // 监听数据恢复通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PostsDataRestored"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            #if DEBUG
            debugLog("📥 PostViewModel: 收到数据恢复通知，重新加载帖子")
            #endif
            self?.reloadPostsFromUserDefaults()
        }
        
        // 监听 PostCommentsUpdated 通知，仅在内容真正变化时刷新
        NotificationCenter.default.addObserver(forName: NSNotification.Name("PostCommentsUpdated"), object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            
            // 获取通知中的帖子ID
            guard let userInfo = notification.userInfo,
                  let postIDString = userInfo["postID"] as? String,
                  let postID = UUID(uuidString: postIDString),
                  let postIndex = self.posts.firstIndex(where: { $0.id == postID }) else {
                return
            }
            
            let post = self.posts[postIndex]
            
            // ⚡️ 关键优化：检查内容是否真的发生变化
            if self.changeTracker.hasPostChanged(post) {
                // 内容发生变化，触发UI刷新
                self.objectWillChange.send()
                #if DEBUG
                debugLog("🔄 帖子内容已变化，触发UI刷新: \(postID.uuidString.prefix(8))")
                #endif
            } else {
                // 内容没有变化，跳过刷新
                #if DEBUG
                debugLog("⏭️ 帖子内容未变化，跳过UI刷新: \(postID.uuidString.prefix(8))")
                #endif
            }
        }
        
        // 🔧 监听保存帖子数据通知，确保虚拟角色评论和回复被持久化保存
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SavePostData"), object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            
            // 立即保存所有帖子数据
            self.saveUserPosts()
            self.saveAIPosts()
            #if DEBUG
            debugLog("💾 收到保存通知，已保存帖子数据")
            #endif
        }
    }
    
    /**
     * ⚡️ 智能发送帖子更新通知
     * 仅在内容真正发生变化时才发送通知，避免不必要的UI刷新
     */
    private func notifyPostUpdatedIfChanged(postID: UUID) {
        // 查找帖子
        guard let postIndex = posts.firstIndex(where: { $0.id == postID }) else {
            return
        }
        
        let post = posts[postIndex]
        
        // 检查内容是否真的发生变化
        if changeTracker.hasPostChanged(post) {
            // 内容发生变化，发送通知
            NotificationCenter.default.post(
                name: NSNotification.Name("PostCommentsUpdated"),
                object: nil,
                userInfo: ["postID": postID.uuidString]
            )
            #if DEBUG
            debugLog("🔄 帖子内容已变化，发送更新通知: \(postID.uuidString.prefix(8))")
            #endif
        } else {
            // 内容没有变化，跳过通知
            #if DEBUG
            debugLog("⏭️ 帖子内容未变化，跳过通知: \(postID.uuidString.prefix(8))")
            #endif
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
        
        // 新增：单独保存用户帖子和AI帖子的完整数据
        saveUserPosts()
        saveAIPosts()
    }
    
    /**
     * 保存用户帖子到持久化存储
     */
    func saveUserPosts() {
        let userPosts = posts.filter { $0.source == "user" }
        // 确保按时间排序（最新的在前）
        let sortedUserPosts = userPosts.sorted { $0.datePosted > $1.datePosted }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sortedUserPosts)
            UserDefaults.standard.set(data, forKey: userPostsKey)
            #if DEBUG
            debugLog("✅ 用户帖子保存成功: \(sortedUserPosts.count) 条")
            #endif
        } catch {
            // ⚡️ 优化：保存失败时记录错误并提示用户
            #if DEBUG
            debugLog("❌ 用户帖子保存失败: \(error.localizedDescription)")
            debugLog("   错误详情: \(error)")
            debugLog("   尝试保存的帖子数量: \(sortedUserPosts.count)")
            #endif
            
            // ⚡️ 显示用户友好的提示（带防抖，避免频繁提示）
            showSaveFailureToastIfNeeded(error: error, dataType: "帖子")
        }
    }
    
    /**
     * 保存AI生成的帖子到持久化存储
     */
    func saveAIPosts() {
        // AI生成的帖子包括：wormhole, onekey, virtual, ai等来源
        let aiPosts = posts.filter { post in
            guard let source = post.source else { return false }
            return source != "user" && source != "welcome" // 排除用户帖子和欢迎帖子
        }
        // 确保按时间排序（最新的在前）
        let sortedAIPosts = aiPosts.sorted { $0.datePosted > $1.datePosted }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sortedAIPosts)
            UserDefaults.standard.set(data, forKey: aiPostsKey)
            #if DEBUG
            debugLog("✅ AI帖子保存成功: \(sortedAIPosts.count) 条")
            #endif
        } catch {
            // ⚡️ 优化：保存失败时记录错误并提示用户
            #if DEBUG
            debugLog("❌ AI帖子保存失败: \(error.localizedDescription)")
            debugLog("   错误详情: \(error)")
            debugLog("   尝试保存的帖子数量: \(sortedAIPosts.count)")
            #endif
            
            // ⚡️ 显示用户友好的提示（带防抖，避免频繁提示）
            showSaveFailureToastIfNeeded(error: error, dataType: "内容")
        }
    }
    
    /**
     * ⚡️ 显示保存失败提示（只显示用户可解决的问题）
     * 只有存储空间不足和权限问题才提示用户，其他错误只记录日志
     */
    private func showSaveFailureToastIfNeeded(error: Error, dataType: String) {
        // 检查是否是用户可解决的错误
        let errorDescription = error.localizedDescription.lowercased()
        let isUserActionable: Bool
        let errorMessage: String
        
        // 只处理用户可控制的两种情况
        if errorDescription.contains("space") || 
           errorDescription.contains("存储") || 
           errorDescription.contains("disk") ||
           errorDescription.contains("full") {
            // 存储空间不足 - 用户可以清理空间
            isUserActionable = true
            errorMessage = "存储空间不足，请清理空间后重试"
        } else if errorDescription.contains("permission") || 
                  errorDescription.contains("权限") ||
                  errorDescription.contains("denied") {
            // 权限问题 - 用户可以在设置中允许
            isUserActionable = true
            errorMessage = "存储权限不足，请在设置中允许访问"
        } else {
            // 其他错误（数据格式错误、系统错误等）- 用户无法控制，不提示
            isUserActionable = false
            errorMessage = "" // ⚡️ 修复：确保errorMessage在所有分支都被初始化
            #if DEBUG
            debugLog("⚠️ \(dataType)保存失败，但用户无法解决，不显示提示")
            debugLog("   错误类型: \(type(of: error))")
            debugLog("   错误信息: \(error.localizedDescription)")
            #endif
        }
        
        // 只有用户可解决的错误才显示提示
        guard isUserActionable else {
            return
        }
        
        // 防抖：5秒内只提示一次
        let now = Date()
        if let lastTime = lastSaveFailureTime,
           now.timeIntervalSince(lastTime) < saveFailureDebounceInterval {
            // 距离上次提示太近，跳过
            return
        }
        lastSaveFailureTime = now
        
        // ⚡️ 修复：在闭包外确保errorMessage已初始化，然后捕获
        let finalErrorMessage = errorMessage
        // 在主线程显示Toast提示
        DispatchQueue.main.async {
            ToastManager.shared.showToast(message: finalErrorMessage)
        }
    }
    
    /**
     * 从持久化存储恢复用户帖子
     */
    private func restoreUserPosts() {
        guard let data = UserDefaults.standard.data(forKey: userPostsKey) else {
            #if DEBUG
            debugLog("🔍 没有找到持久化的用户帖子数据")
            #endif
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let userPosts = try decoder.decode([UserPostModel].self, from: data)
            
            // 将用户帖子按时间倒序添加到帖子列表的前面（最新的在最前面）
            let sortedUserPosts = userPosts.sorted { $0.datePosted > $1.datePosted }
            
            for post in sortedUserPosts {
                if !posts.contains(where: { $0.id == post.id }) {
                    posts.insert(post, at: 0)
                }
            }
            
            #if DEBUG
            debugLog("✅ 成功恢复 \(userPosts.count) 条用户帖子，当前总帖子数: \(posts.count)")
            #endif
        } catch {
            Logger.error("恢复用户帖子失败", error: error, log: Logger.data)
        }
    }
    
    /**
     * 从持久化存储恢复用户帖子数据（返回数据而不修改posts数组）
     */
    func restoreUserPostsData() -> [UserPostModel] {
        guard let data = UserDefaults.standard.data(forKey: userPostsKey) else {
            #if DEBUG
            debugLog("🔍 没有找到持久化的用户帖子数据")
            #endif
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let userPosts = try decoder.decode([UserPostModel].self, from: data)
            // 按时间倒序排列（最新的在前）
            let sortedPosts = userPosts.sorted { $0.datePosted > $1.datePosted }
            #if DEBUG
            debugLog("✅ 成功读取 \(sortedPosts.count) 条用户帖子（已按时间排序）")
            #endif
            return sortedPosts
        } catch {
            Logger.error("恢复用户帖子失败", error: error, log: Logger.data)
            return []
        }
    }
    
    /**
     * 从持久化存储恢复AI生成的帖子
     */
    private func restoreAIPosts() {
        guard let data = UserDefaults.standard.data(forKey: aiPostsKey) else {
            #if DEBUG
            debugLog("🔍 没有找到持久化的AI生成帖子数据")
            #endif
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let aiPosts = try decoder.decode([UserPostModel].self, from: data)
            
            // 将AI帖子按时间倒序添加到帖子列表（但在用户帖子之后）
            let sortedAIPosts = aiPosts.sorted { $0.datePosted > $1.datePosted }
            
            for post in sortedAIPosts {
                if !posts.contains(where: { $0.id == post.id }) {
                    posts.append(post) // AI帖子添加到末尾，保持用户帖子在前面
                }
            }
            
            #if DEBUG
            debugLog("✅ 成功恢复 \(aiPosts.count) 条AI生成帖子，当前总帖子数: \(posts.count)")
            
            // 打印恢复的AI帖子来源统计
            let sourceStats = Dictionary(grouping: aiPosts, by: { $0.source ?? "未知" })
            for (source, posts) in sourceStats {
                debugLog("   - 恢复 \(source): \(posts.count) 条")
            }
            #endif
        } catch {
            Logger.error("恢复AI生成帖子失败", error: error, log: Logger.data)
        }
    }
    
    /**
     * 从持久化存储恢复AI生成的帖子数据（返回数据而不修改posts数组）
     */
    func restoreAIPostsData() -> [UserPostModel] {
        guard let data = UserDefaults.standard.data(forKey: aiPostsKey) else {
            #if DEBUG
            debugLog("🔍 没有找到持久化的AI生成帖子数据")
            #endif
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let aiPosts = try decoder.decode([UserPostModel].self, from: data)
            // 按时间倒序排列（最新的在前）
            let sortedPosts = aiPosts.sorted { $0.datePosted > $1.datePosted }
            
            // 打印恢复的AI帖子来源统计
            let sourceStats = Dictionary(grouping: sortedPosts, by: { $0.source ?? "未知" })
            for (source, posts) in sourceStats {
                #if DEBUG
                debugLog("   - 读取 \(source): \(posts.count) 条")
                #endif
            }
            
            #if DEBUG
            debugLog("✅ 成功读取 \(sortedPosts.count) 条AI生成帖子（已按时间排序）")
            #endif
            return sortedPosts
        } catch {
            #if DEBUG
            debugLog("❌ 恢复AI生成帖子失败: \(error.localizedDescription)")
            #endif
            return []
        }
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
        
        // 🔒 修复：欢迎帖子始终显示，不过滤
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
            #if DEBUG
            debugLog("📦 检测到帖子列表为空，尝试恢复数据")
            #endif
            if !tryRestorePersistedPosts() {
                #if DEBUG
                debugLog("📦 恢复失败，加载示例帖子")
                #endif
                loadSamplePosts()
            }
            
            // 强制通知UI更新
            DispatchQueue.main.async {
                self.objectWillChange.send()
                #if DEBUG
                debugLog("📦 已触发UI更新信号")
                #endif
            }
        } else {
            #if DEBUG
            debugLog("📦 当前有\(posts.count)个帖子，无需恢复")
            #endif
        }
    }
    
    /**
     * 加载示例帖子
     */
    private func loadSamplePosts() {
        let samplePosts = ModelData.samplePosts
        
        // 🔒 修复：欢迎帖子始终显示，不过滤
        for samplePost in samplePosts {
            if !posts.contains(where: { $0.id == samplePost.id }) {
                posts.append(samplePost)
            }
        }
        
        #if DEBUG
        debugLog("📦 加载了示例帖子，当前总帖子数: \(posts.count)")
        #endif
    }
    
    /**
     * 点赞帖子
     * @param post 帖子对象
     */
    func likePost(_ post: UserPostModel) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            // 切换点赞状态
            let isLiked = !posts[index].isLikedByCurrentUser
            // toggleLike 方法已经包含了点赞数的更新逻辑，不需要再调用 updateLikes
            let updatedPost = posts[index].toggleLike(isLiked: isLiked)
            
            posts[index] = updatedPost
            
            // 发送点赞通知，供UserLikeService监听
            NotificationCenter.default.post(
                name: NSNotification.Name("PostLiked"),
                object: nil,
                userInfo: [
                    "post": updatedPost,
                    "isLiked": isLiked
                ]
            )
            
            // 保存更新后的点赞数到持久化存储
            saveUserPosts()
            saveAIPosts()
            
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
            #if DEBUG
            debugLog("⚠️ addUserComment: 后台任务超时")
            #endif
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
                    username: UserProfileManager.shared.getCurrentUsername(),
                    userAvatar: UserProfileManager.shared.getCurrentAvatarURL(),
                    content: formattedContent,
                    datePosted: Date(),
                    isVirtualCharacter: false,
                    characterID: nil,
                    parentCommentId: parentId,
                    replyToUsername: replyToUsername
                )
                
                // 保存用户回复的ID，用于后续添加虚拟角色回复
                let userReplyId = userReply.id
                #if DEBUG
                debugLog("📝 创建用户回复，ID: \(userReplyId)")
                #endif
                
                // 创建帖子的可变副本
                let updatedPost = post
                
                // 添加用户回复到父评论
                updatedPost.addReplyToParent(parentId: parentId, reply: userReply)
                
                // 更新帖子
                posts[index] = updatedPost
                
                #if DEBUG
                debugLog("✅ 已添加用户回复到评论，回复ID: \(userReplyId)")
                #endif
                
                // 准备要生成回复的角色列表
                var charactersToRespond: [String] = []
                
                // 如果是回复某个评论，查找该评论是否来自虚拟角色，并让该角色回复
                if let comment = getCommentById(commentId: parentId, in: posts[index].comments),
                   comment.isVirtualCharacter,
                   let characterID = comment.characterID {
                    // 添加被回复的角色
                    #if DEBUG
                    debugLog("🤖 被回复的虚拟角色将回应用户")
                    #endif
                    charactersToRespond.append(characterID)
                    
                    // 发送角色互动通知给通知系统
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CharacterInteraction"),
                        object: nil,
                        userInfo: ["characterId": characterID]
                    )
                    
                    // 一次性生成回复
                    generateBatchReplies(
                        characterIDs: charactersToRespond, 
                        to: formattedContent, 
                        in: post,
                        replyToId: userReplyId,
                        backgroundTaskID: backgroundTaskID
                    )
                }
            } else {
                // 创建顶级评论 - 使用UserProfileManager的数据
                let newComment = DetailedCommentModel(
                    username: UserProfileManager.shared.getCurrentUsername(),
                    userAvatar: UserProfileManager.shared.getCurrentAvatarURL(),
                    content: formattedContent,
                    datePosted: Date(),
                    isCurrentUser: true,
                    isVirtualCharacter: false,
                    characterID: nil
                )
                
                // 保存顶级评论的ID，用于后续回复
                let userCommentId = newComment.id
                
                // 🔧 保护现有评论，防止被意外清除
                let existingComments = posts[index].comments
                
                // 添加评论到帖子
                posts[index].comments.insert(newComment, at: 0)
                
                // 确保虚拟角色评论没有被清除
                let virtualComments = existingComments.filter { $0.isVirtualCharacter }
                for virtualComment in virtualComments {
                    if !posts[index].comments.contains(where: { $0.id == virtualComment.id }) {
                        #if DEBUG
                        debugLog("🛡️ 恢复被清除的虚拟角色评论: \(virtualComment.username)")
                        #endif
                        posts[index].comments.append(virtualComment)
                    }
                }
                
                #if DEBUG
                debugLog("✅ 已添加用户评论，评论ID: \(userCommentId)")
                #endif
                
                // 🆕 为用户评论创建通知
                NotificationService.shared.createUserCommentNotification(
                    commentContent: formattedContent,
                    postId: post.id.uuidString,
                    postTitle: post.content // 移除 .prefix(50).description
                )
                
                // 准备要生成回复的角色列表
                var charactersToRespond: [String] = []
                
                // 1. 首先，添加帖子作者到回复列表（如果是虚拟角色）
                let postAuthor = posts[index].username
                let authorCharacterId = getCharacterIdByName(postAuthor)
                
                if let authorCharacterId = authorCharacterId {
                    #if DEBUG
                    debugLog("🤖 帖子作者将回复用户评论，作者：\(postAuthor), ID：\(authorCharacterId)")
                    #endif
                    charactersToRespond.append(authorCharacterId)
                    
                    // 发送角色互动通知给通知系统
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CharacterInteraction"),
                        object: nil,
                        userInfo: ["characterId": authorCharacterId]
                    )
                }
                
                // 2. 使用角色轮换系统智能选择角色
                #if DEBUG
                debugLog("🔄 使用角色轮换系统选择回复角色")
                #endif
                CharacterRotationSystem.shared.beginNewGenerationSession()
                
                let replyCount = Int.random(in: 1...2)
                let rotationCharacters = CharacterRotationSystem.shared.getBalancedCharacters(count: replyCount)
                
                // 过滤掉作者角色（如果有）
                let filteredCharacters = rotationCharacters.filter { character in
                    guard let authorId = authorCharacterId else { return true }
                    return character.id.lowercased() != authorId.lowercased()
                }
                
                // 如果过滤后角色不足，重新选择更多角色
                var selectedCharacters = filteredCharacters.map { $0.id }
                if selectedCharacters.count < replyCount {
                    let additionalNeeded = replyCount - selectedCharacters.count
                    let additionalCharacters = CharacterRotationSystem.shared.getBalancedCharacters(count: additionalNeeded + 2)
                        .filter { character in
                            !selectedCharacters.contains(character.id) && 
                            character.id.lowercased() != (authorCharacterId?.lowercased() ?? "")
                        }
                        .prefix(additionalNeeded)
                    
                    selectedCharacters.append(contentsOf: additionalCharacters.map { $0.id })
                }
                
                charactersToRespond.append(contentsOf: selectedCharacters)
                
                // 一次性生成所有角色的回复
                generateBatchReplies(
                    characterIDs: charactersToRespond, 
                    to: formattedContent, 
                    in: post,
                    replyToId: userCommentId,
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
     * @param backgroundTaskID 后台任务ID
     */
    private func generateBatchReplies(characterIDs: [String], to content: String, in post: UserPostModel, replyToId: UUID, backgroundTaskID: UIBackgroundTaskIdentifier) {
        // 如果没有角色需要回应，直接结束
        if characterIDs.isEmpty {
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
            return
        }
        
        #if DEBUG
        debugLog("🔄 准备批量生成\(characterIDs.count)个角色的回复")
        debugLog("🔍 DEBUG: 传递给generateMultiCharacterComments的content参数: '\(content)'")
        debugLog("🔍 DEBUG: content长度: \(content.count)")
        debugLog("🔍 DEBUG: content是否为空: \(content.isEmpty)")
        #endif
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: characterIDs,
            postId: post.id.uuidString,
            postContent: post.content,
            postAuthor: post.username,
            userComment: content  // 🔧 重要修复：传递用户的评论内容
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                #if DEBUG
                debugLog("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                #endif
                
                // 获取帖子索引
                guard let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) else {
                    #if DEBUG
                    debugLog("❌ 无法找到帖子，无法添加批量生成的回复")
                    #endif
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                    return
                }
                
                // 为了模拟自然对话，确定响应时间和顺序
                // 第一个角色（通常是被回复角色或帖子作者）响应较快
                guard let firstCharacterId = characterIDs.first else {
                    #if DEBUG
                    Logger.warning("characterIDs为空，无法生成回复", log: Logger.business)
                    #endif
                    return
                }
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
                            replyToUsername: "当前用户"
                        )
                        
                        // 🔧 安全添加回复（带保护机制）
                        #if DEBUG
                        debugLog("📝 添加\(firstCharacterId)的回复到评论ID: \(replyToId)")
                        #endif
                        
                        // 确保帖子索引仍然有效
                        guard postIndex < self.posts.count else {
                            #if DEBUG
                            debugLog("⚠️ 帖子索引无效，跳过添加回复")
                            #endif
                            return
                        }
                        
                        // 检查父评论是否还存在
                        guard self.posts[postIndex].comments.contains(where: { $0.id == replyToId }) else {
                            #if DEBUG
                            debugLog("⚠️ 父评论不存在，跳过添加回复")
                            #endif
                            return
                        }
                        
                        self.posts[postIndex].addReplyToParent(parentId: replyToId, reply: virtualReply)
                        
                        // ⚡️ 智能发送通知（仅在内容变化时）
                        self.notifyPostUpdatedIfChanged(postID: post.id)
                        
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
                                replyToUsername: "当前用户"
                            )
                            
                            // 🔧 安全添加回复（带保护机制）
                            #if DEBUG
                            debugLog("📝 添加\(characterID)的回复到评论ID: \(replyToId)")
                            #endif
                            
                            // 确保帖子索引仍然有效
                            guard postIndex < self.posts.count else {
                                #if DEBUG
                                debugLog("⚠️ 帖子索引无效，跳过添加回复")
                                #endif
                                return
                            }
                            
                            // 检查父评论是否还存在
                            guard self.posts[postIndex].comments.contains(where: { $0.id == replyToId }) else {
                                #if DEBUG
                                debugLog("⚠️ 父评论不存在，跳过添加回复")
                                #endif
                                return
                            }
                            
                            self.posts[postIndex].addReplyToParent(parentId: replyToId, reply: virtualReply)
                            
                            // ⚡️ 智能发送通知（仅在内容变化时）
                            self.notifyPostUpdatedIfChanged(postID: post.id)
                            
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
                                    #if DEBUG
                                    debugLog("🏁 所有虚拟角色回复任务已完成")
                                    #endif
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
                            #if DEBUG
                            debugLog("🏁 虚拟角色回复任务已完成")
                            #endif
                        }
                    }
                }
                
            case .failure(let error):
                #if DEBUG
                debugLog("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                #endif
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
                                #if DEBUG
                                debugLog("✅ 单独生成角色回复 - \(self.getCharacterName(for: characterID)): \(content.prefix(30))...")
                                #endif
                                
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
                                #if DEBUG
                                debugLog("📝 添加虚拟角色回复到用户评论ID: \(originalCommentId)")
                                #endif
                                self.posts[postIndex].addReplyToParent(parentId: originalCommentId, reply: virtualReply)
                                
                                // ⚡️ 智能发送通知（仅在内容变化时）
                                self.notifyPostUpdatedIfChanged(postID: post.id)
                                
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
            // 使用 toggleLike 方法切换点赞状态，它会正确处理点赞数的增减
            let updatedComment = posts[postIndex].comments[commentIndex].toggleLike()
            
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
            
            // 发送评论点赞通知，供UserLikeService监听
            NotificationCenter.default.post(
                name: NSNotification.Name("CommentLiked"),
                object: nil,
                userInfo: [
                    "comment": updatedComment,
                    "post": updatedPost,
                    "isLiked": updatedComment.isLikedByCurrentUser
                ]
            )
            
            // 保存更新后的评论点赞数到持久化存储
            saveUserPosts()
            saveAIPosts()
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
        #if DEBUG
        debugLog("🤖 开始生成虚拟角色回复: 角色=\(characterID)")
        #endif
        
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
        guard posts.contains(where: { $0.id == postId }),
              let post = posts.first(where: { $0.id == postId }) else {
            return []
        }
        
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
        
        // 🔴🔴🔴 超级醒目的视图模型层日志 🔴🔴🔴
        #if DEBUG
        debugLog("📏 帖子完整长度: \(post.content.count)字符")
        #endif
        #if DEBUG
        debugLog("\n🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵")
        debugLog("📱📱📱 【PostViewModel】用户发帖后触发虚拟角色评论 📱📱📱")
        debugLog("🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵")
        debugLog("🚀 开始生成虚拟角色评论")
        debugLog("👤 目标角色ID: \(characterID)")
        debugLog("👤 目标角色名称: \(character.name)")
        debugLog("📄 帖子ID: \(post.id.uuidString)")
        debugLog("👥 帖子作者: \(post.username)")
        debugLog("📝 帖子内容: \"\(String(post.content.prefix(100)))...\"")
        #endif
        
        // 检查后端配置
        if APIConfigManager.shared.validateConfiguration() {
            #if DEBUG
            debugLog("\n✅ 后端配置检查通过")
            #endif
        } else {
            #if DEBUG
            debugLog("\n❌ ⚠️ 警告: 后端配置无效，API调用可能失败")
            #endif
        }
        
        #if DEBUG
        debugLog("🔵 ===== 开始服务调用 =====")
        #endif
        #if DEBUG
        debugLog("\n🔵 ===== 准备调用VirtualCharacterService =====")
        debugLog("📞 调用方法: inviteCharactersToComment")
        debugLog("📋 参数详情:")
        debugLog("  - characterIDs: [\(characterID)]")
        debugLog("  - postId: \(post.id.uuidString)")
        debugLog("  - postAuthor: \(post.username)")
        #endif
        
        // 使用统一的inviteCharactersToComment方法，确保所有角色评论生成都使用相同的批量生成流程
        virtualCharacterService.inviteCharactersToComment(
            characterIDs: [characterID],
            postId: post.id.uuidString,
            postAuthor: post.username
        )
        
        #if DEBUG
        debugLog("🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵")
        #endif
        #if DEBUG
        debugLog("🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵")
        debugLog("📤 已向VirtualCharacterService发送评论生成请求")
        debugLog("⏳ 等待虚拟角色评论生成完成...")
        #endif
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
            #if DEBUG
            debugLog("⚠️ PostViewModel: 自动生成回复的后台任务超时")
            #endif
        }
        
        #if DEBUG
        debugLog("🔄 PostViewModel: 创建自动生成回复后台任务，ID: \(backgroundTaskID)")
        #endif
        
        // 确保帖子索引有效
        guard postIndex >= 0 && postIndex < posts.count else {
            #if DEBUG
            debugLog("⚠️ 无效的帖子索引: \(postIndex)")
            #endif
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
            return
        }
        
        // 获取帖子内容和ID
        let post = posts[postIndex]
        let postContent = post.content
        let postId = post.id
        
        // 使用角色轮换系统选择角色回复
        #if DEBUG
        debugLog("🔄 使用角色轮换系统选择回复角色")
        #endif
        CharacterRotationSystem.shared.beginNewGenerationSession()
        
        let replyCount = Int.random(in: 1...2)
        let rotationCharacters = CharacterRotationSystem.shared.getBalancedCharacters(count: replyCount)
        let randomCharacters = rotationCharacters.map { $0.id }
        
        // 使用批量API调用生成回复
        #if DEBUG
        debugLog("🚀 开始批量生成\(randomCharacters.count)个角色的回复")
        #endif
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: randomCharacters,
            postId: postId.uuidString,
            postContent: postContent,
            postAuthor: post.username,
            userComment: content  // 🔧 重要修复：传递用户的评论内容
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                #if DEBUG
                debugLog("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                #endif
                
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
                        
                        // 添加到帖子
                        #if DEBUG
                        debugLog("📝 添加\(characterID)的回复到帖子")
                        #endif
                        self.posts[postIndex].comments.insert(virtualReply, at: 0)
                        
                        // ⚡️ 智能发送通知（仅在内容变化时）
                        self.notifyPostUpdatedIfChanged(postID: postId)
                        
                        // 添加震动反馈
                        self.hapticFeedback()
                        
                        // 如果是最后一个角色的回复，结束后台任务
                        if index == commentsMap.count - 1 {
                            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                #if DEBUG
                                debugLog("🏁 所有虚拟角色回复任务已完成")
                                #endif
                            }
                        }
                    }
                }
                
            case .failure(let error):
                #if DEBUG
                debugLog("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                #endif
                
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
            #if DEBUG
            debugLog("错误: 无效的帖子或评论索引")
            #endif
            return
        }
        
        // 获取要回复的评论
        let originalComment = posts[postIndex].comments[commentIndex]
        
        // 创建用户回复评论
        let userReply = DetailedCommentModel(
            id: UUID(),
            username: UserProfileManager.shared.getCurrentUsername(),
            userAvatar: UserProfileManager.shared.getCurrentAvatarURL(),
            content: replyContent,
            datePosted: Date(),
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: originalComment.id,
            replyToUsername: originalComment.username
        )
        
        // 添加用户回复
        posts[postIndex].comments.append(userReply)
        #if DEBUG
        debugLog("✅ 用户回复已添加")
        #endif
        
        // 获取帖子内容用于生成回复
        let postContent = posts[postIndex].content
        let post = posts[postIndex]
        
        // 添加后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            #if DEBUG
            debugLog("⚠️ 后台任务超时")
            #endif
        }
        
        // 准备要生成回复的角色列表
        var charactersToRespond: [String] = []
        
        // 1. 如果原评论来自虚拟角色，添加该角色
        if originalComment.isVirtualCharacter, let characterID = originalComment.characterID {
            #if DEBUG
            debugLog("🤖 被回复的角色将回应用户")
            #endif
            charactersToRespond.append(characterID)
        }
        // 如果回复的是帖子作者，添加作者
        else if originalComment.username == post.username {
            if let authorCharacterId = getCharacterIdByName(post.username) {
                #if DEBUG
                debugLog("🤖 帖子作者将回应用户回复")
                #endif
                charactersToRespond.append(authorCharacterId)
            }
        }
        
        // 2. 随机决定是否让其他角色也参与评论(50%几率)
        if Bool.random() {
            #if DEBUG
            debugLog("🤖 另一个虚拟角色将加入讨论")
            #endif
            
            // 使用角色轮换系统智能选择角色
            CharacterRotationSystem.shared.beginNewGenerationSession()
            
            // 获取一个额外的角色
            let additionalCharacters = CharacterRotationSystem.shared.getBalancedCharacters(count: 3)
            
            // 过滤掉已经回复的角色和帖子作者
            let filteredCharacters = additionalCharacters.filter { character in
                let characterId = character.id.lowercased()
                
                // 排除已经回复的角色
                if let originalCharacterID = originalComment.characterID?.lowercased(),
                   characterId == originalCharacterID {
                    return false
                }
                
                // 排除帖子作者
                if let authorCharacterId = getCharacterIdByName(post.username)?.lowercased(),
                   characterId == authorCharacterId {
                    return false
                }
                
                return true
            }
            
            // 如果还有可用角色，随机选择一个
            if let selectedCharacter = filteredCharacters.first {
                charactersToRespond.append(selectedCharacter.id)
                #if DEBUG
                debugLog("🤖 选择了角色: \(selectedCharacter.id) 加入讨论")
                #endif
            }
        }
        
        // 如果没有角色需要回应，直接结束
        if charactersToRespond.isEmpty {
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
            return
        }
        
        #if DEBUG
        debugLog("🔄 准备批量生成\(charactersToRespond.count)个角色的回复")
        #endif
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: charactersToRespond,
            postId: post.id.uuidString,
            postContent: postContent,
            postAuthor: post.username,
            userComment: replyContent  // 🔧 重要修复：传递用户的回复内容
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                #if DEBUG
                debugLog("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                #endif
                
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
                        #if DEBUG
                        debugLog("📝 添加\(characterID)的回复到用户回复ID: \(userReply.id)")
                        #endif
                        self.posts[postIndex].addReplyToParent(parentId: userReply.id, reply: virtualReply)
                        
                        // 🔧 重要修复：保存帖子数据到持久化存储
                        self.saveUserPosts()
                        self.saveAIPosts()
                        
                        // ⚡️ 智能发送通知（仅在内容变化时）
                        self.notifyPostUpdatedIfChanged(postID: post.id)
                        
                        // 添加震动反馈
                        self.hapticFeedback()
                        
                        // 如果是最后一个角色的回复，结束后台任务
                        if index == commentsMap.count - 1 {
                            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                #if DEBUG
                                debugLog("🏁 所有虚拟角色回复任务已完成")
                                #endif
                            }
                        }
                    }
                }
                
            case .failure(let error):
                #if DEBUG
                debugLog("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                #endif
                
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
                                    #if DEBUG
                                    debugLog("✅ 单独生成角色回复 - \(self.getCharacterName(for: characterID)): \(content.prefix(30))...")
                                    #endif
                                    
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
                                    
                                    // 🔧 重要修复：保存帖子数据到持久化存储
                                    self.saveUserPosts()
                                    self.saveAIPosts()
                                    
                                    // ⚡️ 智能发送通知（仅在内容变化时）
                                    self.notifyPostUpdatedIfChanged(postID: post.id)
                                    
                                    // 添加震动反馈
                                    self.hapticFeedback()
                                    
                                    // 如果是最后一个角色的回复，结束后台任务
                                    if index == charactersToRespond.count - 1 {
                                        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                            UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                            #if DEBUG
                                            debugLog("🏁 所有虚拟角色回复任务已完成")
                                            #endif
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
        #if DEBUG
        debugLog("🔄 处理评论回复: postId=\(postId), commentId=\(commentId), content=\(commentContent)")
        #endif
        
        // 查找帖子
        guard let postIndex = posts.firstIndex(where: { $0.id == postId }) else {
            #if DEBUG
            debugLog("❌ 未找到帖子: \(postId)")
            #endif
            return
        }
        
        // 找到帖子
        let post = posts[postIndex]
        
        // 平铺所有评论以便查找目标评论
        let flattenedComments = getFlattenedComments(forPost: postId)
        
        // 查找被回复的评论
        guard let targetComment = flattenedComments.first(where: { $0.id == commentId }) else {
            #if DEBUG
            debugLog("❌ 未找到评论: \(commentId)")
            #endif
            return
        }
        
        // 打印目标评论的结构，帮助调试
        #if DEBUG
        debugLog("📊 目标评论结构:")
        #endif
        targetComment.printStructure()
        
        #if DEBUG
        debugLog("📝 创建用户回复，回复给: \(replyTo)")
        #endif
        
        // 创建用户回复评论
        let userReply = DetailedCommentModel(
            username: UserProfileManager.shared.getCurrentUsername(),
            userAvatar: UserProfileManager.shared.getCurrentAvatarURL(),
            content: commentContent,
            datePosted: Date(),
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: commentId, // 设置父评论ID为被回复的评论ID
            replyToUsername: replyTo    // 设置回复用户名
        )
        
        // 保存用户回复的ID，用于后续添加虚拟角色回复
        let userReplyId = userReply.id
        #if DEBUG
        debugLog("📝 创建用户回复，ID: \(userReplyId)")
        #endif
        
        // 创建帖子的可变副本
        let updatedPost = post
        
        // 添加用户回复到父评论
        updatedPost.addReplyToParent(parentId: commentId, reply: userReply)
        
        // 更新帖子
        posts[postIndex] = updatedPost
        
        // 🆕 为用户回复创建通知
        NotificationService.shared.createUserReplyNotification(
            replyContent: commentContent,
            replyToUsername: replyTo,
            postId: postId.uuidString,
            postTitle: post.content // 移除 .prefix(50).description
        )
        
        // 检查更新是否成功
        let updatedFlattenedComments = getFlattenedComments(forPost: updatedPost.id)
        if let updatedTargetComment = updatedFlattenedComments.first(where: { $0.id == commentId }),
           let addedReply = updatedTargetComment.replies.first(where: { $0.id == userReplyId }) {
            #if DEBUG
            debugLog("📊 更新后的评论结构:")
            #endif
            #if DEBUG
            debugLog("✅ 成功添加回复，检查到回复ID: \(addedReply.id)")
            #endif
            updatedTargetComment.printStructure()
        } else {
            #if DEBUG
            debugLog("⚠️ 回复可能未成功添加到嵌套结构中")
            #endif
        }
        
        // ⚡️ 智能发送通知（仅在内容变化时）
        notifyPostUpdatedIfChanged(postID: postId)
        
        // 收集需要回复的角色ID
        var characterIDsToReply: [String] = []
        
        // 检查是否回复的是虚拟角色的评论
        if targetComment.isVirtualCharacter, let characterID = targetComment.characterID {
            #if DEBUG
            debugLog("🔍 找到虚拟角色评论，添加到回复列表，角色ID: \(characterID)")
            #endif
            characterIDsToReply.append(characterID)
        }
        
        // 如果是回复帖子作者且对方是虚拟角色
        if targetComment.username == post.username && post.characterID != nil,
           let characterID = post.characterID, !characterIDsToReply.contains(characterID) {
            #if DEBUG
            debugLog("🔍 回复帖子作者，添加到回复列表，角色ID: \(characterID)")
            #endif
            characterIDsToReply.append(characterID)
        }
        
        // 如果没有角色需要回复
        if characterIDsToReply.isEmpty {
            #if DEBUG
            debugLog("⚠️ 没有找到需要回复的虚拟角色，跳过生成回复")
            #endif
            return
        }
        
        // 创建后台任务，确保即使用户退出页面也能完成API调用
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            #if DEBUG
            debugLog("⚠️ 生成批量回复的后台任务超时")
            #endif
        }
        
        // 使用批量API调用生成回复
        #if DEBUG
        debugLog("🚀 开始批量生成\(characterIDsToReply.count)个角色的回复")
        #endif
        
        // 使用MultiCharacterCommentService一次性生成多个角色的回复
        MultiCharacterCommentService.shared.generateMultiCharacterComments(
            characterIDs: characterIDsToReply,
            postId: postId.uuidString,
            postContent: post.content,
            postAuthor: post.username,
            userComment: commentContent  // 🔧 重要修复：传递用户的回复内容
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let commentsMap):
                #if DEBUG
                debugLog("✅ 成功批量生成\(commentsMap.count)个角色的回复")
                #endif
                
                // 获取帖子索引
                guard let postIndex = self.posts.firstIndex(where: { $0.id == postId }) else {
                    #if DEBUG
                    debugLog("❌ 无法找到帖子，无法添加批量生成的回复")
                    #endif
                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    }
                    return
                }
                
                // 为了模拟自然对话，确定响应时间和顺序
                // 第一个角色（通常是被回复角色或帖子作者）响应较快
                guard let firstCharacterId = characterIDsToReply.first else {
                    #if DEBUG
                    Logger.warning("characterIDsToReply为空，无法生成回复", log: Logger.business)
                    #endif
                    return
                }
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
                            parentCommentId: commentId, // 使用原始评论ID作为父评论ID
                            replyToUsername: "当前用户"   // 明确设置回复对象
                        )
                        
                        // 添加到帖子 - 添加到原始评论下
                        #if DEBUG
                        debugLog("📝 添加\(firstCharacterId)的回复到评论ID: \(commentId)")
                        #endif
                        self.posts[postIndex].addReplyToParent(parentId: commentId, reply: virtualReply)
                        
                        // ⚡️ 智能发送通知（仅在内容变化时）
                        self.notifyPostUpdatedIfChanged(postID: postId)
                        
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
                                parentCommentId: commentId, // 使用原始评论ID作为父评论ID
                                replyToUsername: "当前用户"   // 明确设置回复对象
                            )
                            
                            // 添加到帖子
                            #if DEBUG
                            debugLog("📝 添加\(characterID)的回复到评论ID: \(commentId)")
                            #endif
                            self.posts[postIndex].addReplyToParent(parentId: commentId, reply: virtualReply)
                            
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
                                    #if DEBUG
                                    debugLog("🏁 所有虚拟角色回复任务已完成")
                                    #endif
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
                            #if DEBUG
                            debugLog("🏁 虚拟角色回复任务已完成")
                            #endif
                        }
                    }
                }
                
            case .failure(let error):
                #if DEBUG
                debugLog("❌ 批量生成角色回复失败: \(error.localizedDescription)")
                #endif
                
                // 备用方案：使用原来的单独API调用方法
                #if DEBUG
                debugLog("🔄 使用备用方案，单独生成回复")
                #endif
                
                // 检查是否回复的是虚拟角色的评论
                if targetComment.isVirtualCharacter,
                   let characterID = targetComment.characterID {
                    #if DEBUG
                    debugLog("🔍 找到虚拟角色评论，准备生成回复，角色ID: \(characterID)")
                    #endif
                    
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
                                    #if DEBUG
                                    debugLog("✅ API生成回复成功: \(replyContent.prefix(50))...")
                                    #endif
                                    
                                    // 添加虚拟角色的回复
                                    let characterName = self.getCharacterName(for: characterID)
                                    let characterAvatar = self.getCharacterAvatar(for: characterID)
                                    
                                    // 创建虚拟角色回复，直接回复到原始的评论，而不是用户的回复
                                    let virtualReply = DetailedCommentModel(
                                        username: characterName,
                                        userAvatar: characterAvatar,
                                        content: replyContent,
                                        datePosted: Date().addingTimeInterval(Double.random(in: 30...120)),
                                        isVirtualCharacter: true,
                                        characterID: characterID,
                                        parentCommentId: commentId, // 使用原始评论ID作为父评论ID
                                        replyToUsername: "当前用户"   // 明确设置回复对象
                                    )
                                    
                                    // 添加到帖子 - 添加到原始评论下
                                    if let postIndex = self.posts.firstIndex(where: { $0.id == postId }) {
                                        #if DEBUG
                                        debugLog("📝 添加虚拟角色回复到原始评论下，原始评论ID: \(commentId)")
                                        #endif
                                        
                                        // 使用临时变量来创建帖子副本
                                        let updatedPost = self.posts[postIndex]
                                        updatedPost.addReplyToParent(parentId: commentId, reply: virtualReply)
                                        
                                        // 更新帖子数组
                                        self.posts[postIndex] = updatedPost
                                        
                                        #if DEBUG
                                        debugLog("✅ 已添加API生成的虚拟角色回复到原始评论下")
                                        #endif
                                    }
                                    
                                    // 添加震动反馈
                                    self.hapticFeedback()
                                    
                                case .failure(let error):
                                    #if DEBUG
                                    debugLog("❌ API生成回复失败: \(error.localizedDescription)")
                                    #endif
                                    // API失败时不再使用模板回复，直接跳过
                                    #if DEBUG
                                    debugLog("⚠️ API失败，跳过回复生成")
                                    #endif
                                }
                                
                                // ⚡️ 智能发送通知（仅在内容变化时）
                                self.notifyPostUpdatedIfChanged(postID: postId)
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
            #if DEBUG
            debugLog("❌ findLastCommentFromCurrentUser: 未找到帖子")
            #endif
            return nil
        }
        
        // 获取所有评论（包括嵌套回复）的平铺列表
        let allComments = getFlattenedComments(forPost: postId)
        
        // 倒序遍历所有评论，找到当前用户的最后一条评论
        for comment in allComments.reversed() {
            if comment.username == "当前用户" {
                #if DEBUG
                debugLog("✅ 找到当前用户的最后一条评论，ID: \(comment.id)")
                #endif
                return comment.id
            }
        }
        
        #if DEBUG
        debugLog("❌ 未找到当前用户的评论")
        #endif
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
            #if DEBUG
            debugLog("❌ getFlattenedComments: 未找到帖子")
            #endif
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
        #if DEBUG
        debugLog("🔄 开始生成虫洞共鸣帖子 - 使用角色系统")
        #endif
        
        // 构建话题 - ⚡️ 安全修复：使用可选链替代强制解包
        let keywordPart = keyword.map { "，关键词[\($0)]" } ?? ""
        let topic = "关于[\(situation)]，期望[\(expectation)]\(keywordPart)"
        
        // 获取虫洞共鸣配置的生成数量
        let count = ExplorationCountManager.shared.getCount(for: .resonance)
        #if DEBUG
        debugLog("📊 虫洞共鸣配置的生成数量: \(count)篇")
        #endif
        
        do {
            // 使用generateSingleTypeContent方法代替generateRandomContent
            // 这个方法会自动生成带有评论的内容并将评论保存到CommentStore中
            let contentItems = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ContentItem], Error>) in
                ContentGeneratorService.shared.generateSingleTypeContent(contentType: .resonance, topic: topic, count: count)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                #if DEBUG
                                debugLog("⚠️ 生成共鸣帖子失败: \(error)")
                                #endif
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { items in
                            #if DEBUG
                            debugLog("✅ 成功生成\(items.count)篇虫洞共鸣内容")
                            #endif
                            continuation.resume(returning: items)
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            #if DEBUG
            debugLog("📝 将生成的\(contentItems.count)篇内容转换为帖子模型")
            #endif
            
            // 转换为帖子模型
            var userPosts: [UserPostModel] = []
            for item in contentItems {
                // 从CommentStore获取评论
                let commentItems = CommentStore.shared.getComments(forContentID: item.id)
                #if DEBUG
                debugLog("📝 为内容ID=\(item.id)获取到\(commentItems.count)条评论")
                #endif
                
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
                    characterID: item.characterID, // 🔒 修复：设置characterID以便正确显示角色信息
                    source: "wormhole" // 添加来源标识，表示来自虫洞探索
                )
                userPosts.append(userPost)
            }
            
            // 如果没有生成任何帖子，抛出错误
            if userPosts.isEmpty {
                #if DEBUG
                debugLog("⚠️ 警告：生成虫洞共鸣帖子失败，没有生成任何内容")
                #endif
                throw PostGenerationError.failedToGeneratePosts
            }
            
            return userPosts
        } catch {
            #if DEBUG
            debugLog("❌ 生成虫洞共鸣帖子时出错: \(error.localizedDescription)")
            #endif
            throw error
        }
    }
    
    /**
     * 根据类型索引异步生成内容
     * 解决递归调用问题的新方法
     */
    func generatePostsByTypeIndexAsync(typeIndex: Int) async throws -> [UserPostModel] {
        #if DEBUG
        debugLog("🔄 开始异步生成帖子: 类型索引=\(typeIndex)")
        #endif
        
        // 获取ContentType
        let contentType = convertTypeIndexToContentType(typeIndex)
        
        // 获取内容生成数量
        let count = ExplorationCountManager.shared.getCount(for: contentType)
        #if DEBUG
        debugLog("📊 使用[类型=\(contentType.rawValue)]的生成数量: \(count)")
        #endif
        
        // 使用带评论的内容生成方法
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[UserPostModel], Error>) in
            // 使用generateSingleTypeContent方法生成内容
            ContentGeneratorService.shared.generateSingleTypeContent(contentType: contentType, topic: nil, count: count)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            #if DEBUG
                            debugLog("⚠️ 生成\(contentType.rawValue)内容失败: \(error)")
                            #endif
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { items in
                        #if DEBUG
                        debugLog("✅ 成功生成\(items.count)篇\(contentType.rawValue)内容")
                        #endif
                        
                        // 将ContentItem转换为UserPostModel
                        var userPosts: [UserPostModel] = []
                        for item in items {
                            // 从CommentStore获取评论
                            let commentItems = CommentStore.shared.getComments(forContentID: item.id)
                            #if DEBUG
                            debugLog("📝 为内容ID=\(item.id)获取到\(commentItems.count)条评论")
                            #endif
                            
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
                        
                        // 如果没有生成任何帖子，抛出错误
                        if userPosts.isEmpty {
                            #if DEBUG
                            debugLog("⚠️ 警告：生成\(contentType.rawValue)帖子失败，没有生成任何内容")
                            #endif
                            continuation.resume(throwing: PostGenerationError.failedToGeneratePosts)
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
        #if DEBUG
        debugLog("🔄 开始生成单条帖子: 角色ID=\(characterID), 内容类型=\(contentType.rawValue)")
        #endif
        
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
                            characterID: result.characterID, // 🔒 修复：设置characterID以便正确显示角色信息
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
        
        #if DEBUG
        debugLog("📊 为类型[\(contentType.rawValue)]生成帖子，数量: \(actualCount)，\(withComments ? "带评论" : "不带评论")")
        #endif
        
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
        // 获取随机角色来做评论（使用CharacterModel以应用分类过滤）
        let allCharacters = CharacterModel.getAllCharacters() // 已应用分类过滤
        var availableCharacters = allCharacters.filter { $0.id != item.characterID }
        availableCharacters = Array(availableCharacters.shuffled().prefix(count))
        
        var comments: [DetailedCommentModel] = []
        for character in availableCharacters {
            // 将CharacterCategory映射到CharacterType
            let characterType: CharacterSystem.CharacterType = {
                switch character.category {
                case .historical:
                    return .historical
                case .philosopher:
                    return .historical // CharacterType没有philosopher，使用historical
                case .writer:
                    return .literary
                case .animeCharacter:
                    return .anime
                case .gameCharacter:
                    return .game
                case .filmCharacter:
                    return .movie // CharacterType没有filmCharacter，使用movie
                case .mythCharacter:
                    return .mythological
                case .myCreation:
                    return .historical // 用户创建的角色默认使用历史人物类型
                case .all:
                    return .historical
                }
            }()
            
            // 将CharacterModel转换为CharacterIdentity用于API调用
            let characterIdentity = CharacterSystem.CharacterIdentity(
                id: character.id,
                name: character.name,
                type: characterType,
                era: character.era,
                primaryField: character.profession,
                briefDescription: character.bio,
                avatarName: character.avatar,
                region: "",
                contentAffinities: [:],
                subtype: nil
            )
            
            let commentText = await ContentGeneratorService.shared.generateQuickComment(
                forContent: item.content,
                byCharacter: characterIdentity
            )
            
            let comment = DetailedCommentModel(
                id: UUID(),
                username: character.name,
                userAvatar: character.avatar,
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
     * 添加新帖子到列表
     * 优化版本：减少不必要的通知和刷新
     */
    func addPosts(_ newPosts: [UserPostModel]) {
        guard !newPosts.isEmpty else { return }
        
        #if DEBUG
        debugLog("📝 PostViewModel: 开始添加 \(newPosts.count) 个新帖子")
        #endif
        
        // 过滤出真正的新帖子（避免重复添加）
        let uniquePosts = newPosts.filter { newPost in
            !posts.contains { $0.id == newPost.id }
        }
        
        guard !uniquePosts.isEmpty else {
            #if DEBUG
            debugLog("📝 PostViewModel: 所有帖子都已存在，跳过添加")
            #endif
            return
        }
        
        // 将新帖子添加到列表前面（最新的在最前面）
        posts.insert(contentsOf: uniquePosts, at: 0)
        
        // 验证添加是否成功
        let newCount = posts.count
        let addedCount = uniquePosts.count
        #if DEBUG
        debugLog("📝 PostViewModel: 添加后帖子数量 = \(newCount)，实际增加 \(addedCount)")
        #endif
        
        // 检查第一篇帖子是否就是新添加的第一篇
        if let firstNewPost = uniquePosts.first, let firstPost = posts.first {
            let isFirstPostMatch = firstNewPost.id == firstPost.id
            #if DEBUG
            debugLog("📊 PostViewModel: 第一篇帖子ID匹配检查 = \(isFirstPostMatch ? "✅成功" : "❌失败")")
            #endif
        }
        
        // 🔧 优化：只发送一次精确的增量更新通知，不触发objectWillChange
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 发送精确的增量更新通知，包含新帖子的详细信息
            let userInfo: [String: Any] = [
                "newPostsCount": uniquePosts.count,
                "newPostIds": uniquePosts.map { $0.id.uuidString },
                "newPosts": uniquePosts, // 直接传递新帖子数据
                "timestamp": Date().timeIntervalSince1970,
                "updateType": "incremental"
            ]
            
            // 只发送一个通知，避免重复
            NotificationCenter.default.post(
                name: NSNotification.Name("PostsIncrementallyUpdated"),
                object: self,
                userInfo: userInfo
            )
            
            #if DEBUG
            debugLog("📱 PostViewModel: 已发送增量更新通知，添加了 \(uniquePosts.count) 个新帖子")
            #endif
        }
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
        
        #if DEBUG
        debugLog("🔄 开始生成带初始评论的帖子: 类型索引=\(typeIndex), 评论数=\(commentersCount)")
        #endif
        
        // 确保typeIndex在有效范围内
        guard typeIndex >= 0 && typeIndex < ContentTypeManager.shared.contentTypes.count else {
            #if DEBUG
            debugLog("❌ 无效的类型索引: \(typeIndex)")
            #endif
            throw PostGenerationError.invalidTypeIndex
        }
        
        // 获取内容类型
        let contentType = convertTypeIndexToContentType(typeIndex)
        #if DEBUG
        debugLog("👉 已转换内容类型: \(contentType.rawValue)")
        #endif
        
        return try await withCheckedThrowingContinuation { continuation in
            // 使用ContentGeneratorService生成带评论的内容
            contentGeneratorService.generateRandomContentWithComments(contentType: contentType, topic: topic)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            #if DEBUG
                            debugLog("❌ 生成带评论的内容失败: \(error.localizedDescription)")
                            #endif
                            continuation.resume(throwing: error)
                            // 清理本地取消令牌
                            localCancellables.removeAll()
                        }
                    },
                    receiveValue: { result in
                        #if DEBUG
                        debugLog("✅ 成功生成带评论的内容: 评论数=\(result.comments.count)")
                        #endif
                        
                        // 将ContentItem转换为UserPostModel
                        let post = self.convertContentItemToUserPost(result.contentItem)
                        #if DEBUG
                        debugLog("📝 创建帖子: ID=\(post.id), 作者=\(post.username)")
                        #endif
                        
                        // 将CommentItem转换为DetailedCommentModel
                        let comments = result.comments.map { commentItem -> DetailedCommentModel in
                            #if DEBUG
                            debugLog("✅ 添加评论: 来自=\(commentItem.characterName), 内容=\(commentItem.content.prefix(30))...")
                            #endif
                            return DetailedCommentModel(
                                id: UUID(uuidString: commentItem.id) ?? UUID(),
                                username: commentItem.characterName,
                                userAvatar: commentItem.characterAvatar ?? "person.circle.fill",
                                content: commentItem.content,
                                datePosted: commentItem.timestamp,
                                isVirtualCharacter: true,
                                characterID: commentItem.characterId,
                                // ⚡️ 安全修复：使用 flatMap 安全转换 UUID
parentCommentId: commentItem.parentCommentId.flatMap { UUID(uuidString: $0) },
                                replyToUsername: nil,
                                likes: commentItem.likes,
                                isLikedByCurrentUser: Bool.random()
                            )
                        }
                        
                        #if DEBUG
                        debugLog("🎉 生成完成: 帖子=1, 评论=\(comments.count)")
                        #endif
                        
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
        
        #if DEBUG
        debugLog("🌟 开始生成\(count)个带评论的帖子: 类型索引=\(typeIndex), 每个帖子评论数=\(commentersCount)")
        #endif
        
        // 逐个生成帖子和评论
        for i in 0..<count {
            do {
                #if DEBUG
                debugLog("📝 生成第\(i+1)个帖子...")
                #endif
                let result = try await generatePostWithInitialComments(typeIndex: typeIndex, topic: topic, commentersCount: commentersCount)
                
                // 将生成的评论添加到帖子中
                let post = result.post
                post.comments = result.comments
                
                #if DEBUG
                debugLog("✅ 成功添加\(result.comments.count)条评论到帖子")
                #endif
                generatedPosts.append(post)
            } catch {
                #if DEBUG
                debugLog("❌ 生成带评论的帖子失败: \(error.localizedDescription)")
                #endif
                // 继续生成下一个帖子
                continue
            }
        }
        
        // 如果没有成功生成任何帖子，抛出错误
        if generatedPosts.isEmpty {
            #if DEBUG
            debugLog("⚠️ 未能生成任何帖子")
            #endif
            throw PostGenerationError.failedToGeneratePosts
        }
        
        #if DEBUG
        debugLog("🎉 成功生成\(generatedPosts.count)个带评论的帖子")
        #endif
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
        #if DEBUG
        debugLog("🔍 转换ContentItem为UserPost: 类型=\(item.contentType), 内容长度=\(item.content.count)字")
        #endif
        if item.contentType == "古潮新语" {
            #if DEBUG
            debugLog("📝 古潮新语原始内容: \(item.content)")
            #endif
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
        #if DEBUG
        debugLog("📊 开始生成\(count)篇\(contentType.rawValue)内容，来源: \(source ?? "未指定")")
        #endif
        
        return try await withCheckedThrowingContinuation { continuation in
            // 使用ContentGeneratorService生成内容
            ContentGeneratorService.shared.generateSingleTypeContent(
                contentType: contentType,
                count: count
            )
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            #if DEBUG
                            debugLog("❌ 生成内容失败: \(error.localizedDescription)")
                            #endif
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { items in
                        #if DEBUG
                        debugLog("✅ 成功生成\(items.count)篇\(contentType.rawValue)内容")
                        #endif
                        
                        // 将ContentItem转换为UserPostModel
                        var userPosts: [UserPostModel] = []
                        for item in items {
                            // 从CommentStore获取评论
                            let commentItems = CommentStore.shared.getComments(forContentID: item.id)
                            #if DEBUG
                            debugLog("📝 为内容ID=\(item.id)获取到\(commentItems.count)条评论")
                            #endif
                            
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
                                    // ⚡️ 安全修复：使用 flatMap 安全转换 UUID
parentCommentId: commentItem.parentCommentId.flatMap { UUID(uuidString: $0) },
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
                        
                        // 如果没有生成任何帖子，抛出错误
                        if userPosts.isEmpty {
                            #if DEBUG
                            debugLog("⚠️ 警告：生成\(contentType.rawValue)帖子失败，没有生成任何内容")
                            #endif
                            continuation.resume(throwing: PostGenerationError.failedToGeneratePosts)
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
        #if DEBUG
        debugLog("📝 回复者: \(reply.username), 父评论ID: \(reply.parentCommentId?.uuidString ?? "nil")")
        #endif
        #if DEBUG
        debugLog("📝 ViewModel: 添加回复到评论ID: \(parentId)")
        debugLog("📝 回复内容: \"\(reply.content.prefix(30))...\"")
        #endif
        
        // 查找包含目标评论的帖子
        for (postIndex, post) in posts.enumerated() {
            #if DEBUG
            debugLog("🔍 检查帖子[\(postIndex)], ID: \(post.id)")
            #endif
            
            // 尝试查找评论 (先平铺所有评论进行查找)
            let allComments = getFlattenedComments(forPost: post.id)
            if let targetComment = allComments.first(where: { $0.id == parentId }) {
                #if DEBUG
                debugLog("✅ 找到目标评论在帖子[\(postIndex)]中，评论用户名: \(targetComment.username)")
                #endif
                
                // 创建帖子的可变副本
                let updatedPost = post
                
                // 直接使用帖子模型的方法添加回复
                updatedPost.addReplyToParent(parentId: parentId, reply: reply)
                
                // 更新帖子数组
                posts[postIndex] = updatedPost
                
                // 输出回复是否成功添加的验证信息
                let updatedFlattenedComments = getFlattenedComments(forPost: updatedPost.id)
                if let updatedParentComment = updatedFlattenedComments.first(where: { $0.id == parentId }) {
                    #if DEBUG
                    debugLog("📊 添加回复后，目标评论现在有 \(updatedParentComment.replies.count) 条回复")
                    #endif
                    
                    // 验证回复是否存在
                    let replyExists = updatedParentComment.replies.contains { $0.id == reply.id }
                    #if DEBUG
                    debugLog(replyExists ? "✅ 验证成功: 回复已正确添加" : "❌ 验证失败: 回复未找到")
                    #endif
                }
                
                // 触发UI更新通知
                objectWillChange.send()
                
                #if DEBUG
                debugLog("🔄 已发送ViewModel更新通知")
                #endif
                return
            }
        }
        
        #if DEBUG
        debugLog("⚠️ 未找到对应的父评论ID: \(parentId)，无法添加回复")
        #endif
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
                comments[i].replies.insert(reply, at: 0)
                #if DEBUG
                debugLog("🔍 ViewModel: 找到目标评论，ID: \(parentId)，用户名: \(comments[i].username)，添加回复成功")
                #endif
                return true
            }
            
            // 递归检查当前评论的回复
            if !comments[i].replies.isEmpty {
                var updatedReplies = comments[i].replies
                if findAndAddReplyToNestedComment(comments: &updatedReplies, parentId: parentId, reply: reply) {
                    comments[i].replies = updatedReplies
                    #if DEBUG
                    debugLog("🔍 ViewModel: 在评论 \(comments[i].id) (\(comments[i].username)) 的回复中找到目标评论，添加回复成功")
                    #endif
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
        #if DEBUG
        debugLog("🔄 开始转换评论，总数：\(commentItems.count)条")
        #endif
        
        // 第一步：创建所有评论的映射，供后续处理引用
        var commentMap = [String: DetailedCommentModel]()
        var topLevelComments = [DetailedCommentModel]()
        
        // 第二步：先创建所有DetailedCommentModel实例
        let initialComments = commentItems.map { commentItem -> (DetailedCommentModel, String?) in
            // 🔒 修复：对于用户创建的角色，确保characterID正确传递
            let characterID = commentItem.characterId
            let userAvatar: String = {
                // 如果characterID是custom_开头，使用characterID作为avatar（Avatar组件会处理）
                if characterID.hasPrefix("custom_") {
                    return characterID
                } else {
                    // 其他角色使用原始avatar值
                    return commentItem.characterAvatar ?? "person.circle.fill"
                }
            }()
            
            let comment = DetailedCommentModel(
                id: UUID(uuidString: commentItem.id) ?? UUID(),
                username: commentItem.characterName,
                userAvatar: userAvatar,
                content: commentItem.content,
                datePosted: commentItem.timestamp,
                isVirtualCharacter: true,
                characterID: characterID, // 🔒 确保characterID正确传递
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
                #if DEBUG
                debugLog("📝 评论#\(index+1) ID=\(comment.id)是\(parentComment.username)的回复")
                #endif
                
                // 设置父评论ID和回复用户名
                var mutableComment = comment
                mutableComment.parentCommentId = parentComment.id
                mutableComment.replyToUsername = parentComment.username
                
                // 将回复添加到父评论的replies数组中
                var updatedParent = parentComment
                updatedParent.replies.append(mutableComment)
                commentMap[parentId] = updatedParent // 更新映射中的父评论
                
                // 打印调试信息
                #if DEBUG
                debugLog("✅ 已将回复添加到父评论，父评论ID=\(parentId)，父评论用户=\(updatedParent.username)，现有回复数=\(updatedParent.replies.count)")
                #endif
            } else {
                // 这是一条顶级评论
                topLevelComments.append(comment)
                #if DEBUG
                debugLog("📝 评论#\(index+1) ID=\(comment.id)是顶级评论，用户=\(comment.username)")
                #endif
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
        #if DEBUG
        debugLog("📊 评论层次结构:")
        #endif
        for (index, comment) in finalTopLevelComments.enumerated() {
            #if DEBUG
            debugLog("📊 顶级评论[\(index)]: ID=\(comment.id), 用户=\(comment.username), 回复数=\(comment.replies.count)")
            #endif
            for (replyIndex, reply) in comment.replies.enumerated() {
                #if DEBUG
                debugLog("  └─ 回复[\(replyIndex)]: ID=\(reply.id), 用户=\(reply.username), 回复给=\(reply.replyToUsername ?? "未知")")
                #endif
            }
        }
        
        #if DEBUG
        debugLog("✅ 评论转换完成: \(finalTopLevelComments.count)条顶级评论，包含嵌套回复")
        #endif
        
        // 返回所有顶级评论，它们的replies数组中已经包含了各自的回复
        return finalTopLevelComments
    }
    
    /**
     * 生成历史人物对话帖子
     * 基于用户提供的话题生成两个历史人物之间的对话
     */
    func generateDialoguePosts(topic: String) async throws -> [UserPostModel] {
        #if DEBUG
        debugLog("🔄 开始生成历史对话帖子: 话题=\(topic)")
        #endif
        
        // 获取对话生成配置
        let count = ExplorationCountManager.shared.getCount(for: .resonance) // 使用存在的类型
        #if DEBUG
        debugLog("📊 对话配置的生成数量: \(count)篇")
        #endif
        
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
            
            #if DEBUG
            debugLog("✅ 成功生成\(result.count)篇历史对话内容")
            #endif
            
            // 转换为帖子模型
            var userPosts: [UserPostModel] = []
            for (item, commentItems) in result {
                #if DEBUG
                debugLog("📝 处理对话内容ID=\(item.id)，包含\(commentItems.count)条评论")
                #endif
                
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
            
            // 如果没有生成任何帖子，抛出错误
            if userPosts.isEmpty {
                #if DEBUG
                debugLog("⚠️ 警告：生成历史对话帖子失败，没有生成任何内容")
                #endif
                throw PostGenerationError.failedToGeneratePosts
            }
            
            return userPosts
        } catch {
            #if DEBUG
            debugLog("❌ 生成历史对话帖子时出错: \(error)")
            #endif
            throw error
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
    
    /**
     * 添加AI生成的帖子到列表（会触发持久化保存）
     * @param newPosts 要添加的新帖子数组
     */
    func addAIPosts(_ newPosts: [UserPostModel]) {
        let currentPosts = posts
        let updatedPosts = newPosts + currentPosts
        
        // 通过整体赋值触发didSet，确保持久化保存
        posts = updatedPosts
        
        #if DEBUG
        debugLog("✅ 添加了 \(newPosts.count) 条AI帖子，当前总帖子数: \(posts.count)")
        #endif
        
        // 打印新增帖子的来源统计
        let sourceStats = Dictionary(grouping: newPosts, by: { $0.source ?? "未知" })
        for (source, posts) in sourceStats {
            #if DEBUG
            debugLog("   - 新增 \(source): \(posts.count) 条")
            #endif
        }
    }
    
    /**
     * 添加用户帖子到列表（会触发持久化保存）
     * @param newPost 要添加的用户帖子
     */
    func addUserPost(_ newPost: UserPostModel) {
        var currentPosts = posts
        currentPosts.insert(newPost, at: 0)
        
        // 通过整体赋值触发didSet，确保持久化保存
        posts = currentPosts
        
        #if DEBUG
        debugLog("✅ 添加了1条用户帖子，当前总帖子数: \(posts.count)")
        #endif
    }
    
    /**
     * 为帖子生成虚拟角色回复
     * 当用户添加评论后，自动生成虚拟角色的回复
     * @param post 目标帖子
     * @param commentId 用户评论的ID
     */
    func generateVirtualCharacterReplyForPost(_ post: UserPostModel, commentId: UUID) {
        // 🔧 修复重复添加问题：注释掉PostViewModel中的重复逻辑
        // 现在由MultiCharacterCommentService统一处理，避免重复添加
        #if DEBUG
        debugLog("🔧 PostViewModel: 虚拟角色回复生成已由MultiCharacterCommentService统一处理，跳过重复生成")
        #endif
        return
        
        // 以下是原来的逻辑，现在已注释掉
        /*
        // 获取可用的虚拟角色ID列表
        let availableCharacterIds = self.getAvailableVirtualCharacterIds()
        
        // 随机选择1-3个角色进行回复
        let numberOfReplies = Int.random(in: 1...min(3, availableCharacterIds.count))
        let selectedCharacterIds = Array(availableCharacterIds.shuffled().prefix(numberOfReplies))
        
        #if DEBUG
        debugLog("🎭 为帖子生成虚拟角色回复，选择 \(numberOfReplies) 个角色")
        #endif
        
        // 为每个选中的角色生成回复
        for (index, characterID) in selectedCharacterIds.enumerated() {
            // 添加累加的延迟，让回复看起来更自然
            let delay = Double.random(in: 2.0...4.0) + Double(index) * 2.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                if let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) {
                    // 获取原始评论内容，用于生成回复
                    let commentContent = self.getCommentContent(commentId: commentId, in: post)
                    
                    self.generateVirtualCharacterReply(
                        characterID: characterID,
                        toComment: commentContent,
                        inPost: post.content,
                        completion: { result in
                            if case .success(let content) = result {
                                #if DEBUG
                                debugLog("✅ 单独生成角色回复 - \(self.getCharacterName(for: characterID)): \(content.prefix(30))...")
                                #endif
                                
                                // 创建虚拟角色回复
                                let virtualReply = DetailedCommentModel(
                                    username: self.getCharacterName(for: characterID),
                                    userAvatar: self.getCharacterAvatar(for: characterID),
                                    content: content,
                                    datePosted: Date().addingTimeInterval(Double.random(in: 60...180)),
                                    isVirtualCharacter: true,
                                    characterID: characterID,
                                    parentCommentId: commentId,
                                    replyToUsername: "当前用户"
                                )
                                
                                // 添加到帖子
                                #if DEBUG
                                debugLog("📝 添加虚拟角色回复到用户评论ID: \(commentId)")
                                #endif
                                self.posts[postIndex].addReplyToParent(parentId: commentId, reply: virtualReply)
                                
                                // ⚡️ 智能发送通知（仅在内容变化时）
                                self.notifyPostUpdatedIfChanged(postID: post.id)
                                
                                // 添加震动反馈
                                self.hapticFeedback()
                            }
                        }
                    )
                }
            }
        }
        */
    }
    
    /**
     * 添加单个新帖子（优化版本）
     * 专门用于用户发布新帖子，避免全量刷新
     */
    func addSinglePost(_ newPost: UserPostModel) {
        // 检查是否已存在
        guard !posts.contains(where: { $0.id == newPost.id }) else {
            return
        }
        
        // 将新帖子添加到列表前面
        posts.insert(newPost, at: 0)
        
        // 🎯 关键节点1：用户发布新帖子后立即保存
        saveAtCriticalPoint(reason: "用户发布新帖子")
        
        // 🔧 优化：只发送精确的单帖子更新通知，不触发objectWillChange
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 发送单帖子更新通知
            let userInfo: [String: Any] = [
                "newPostId": newPost.id.uuidString,
                "newPostContent": newPost.content.prefix(50),
                "newPost": newPost, // 直接传递新帖子数据
                "timestamp": Date().timeIntervalSince1970,
                "updateType": "singlePost"
            ]
            
            NotificationCenter.default.post(
                name: NSNotification.Name("SinglePostAdded"),
                object: self,
                userInfo: userInfo
            )
        }
    }
    
    /**
     * 删除帖子（永久删除，不可恢复）
     * @param postId 要删除的帖子ID
     */
    func deletePost(_ postId: UUID) {
        // 查找帖子索引
        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            #if DEBUG
            debugLog("⚠️ 未找到要删除的帖子: \(postId)")
            #endif
            return
        }
        
        let deletedPost = posts[index]
        
        // 从内存列表中移除
        posts.remove(at: index)
        
        #if DEBUG
        debugLog("✅ 已从内存删除帖子: \(deletedPost.id), 作者: \(deletedPost.username)")
        #endif
        
        // 🗑️ 从持久化存储中永久删除
        // 根据帖子来源，从对应的 UserDefaults 键中删除
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // 判断帖子类型并删除
            if deletedPost.source == "user" {
                // 用户帖子：从 UserPosts_v1 中删除
                self.removePostFromUserDefaults(postId: postId, key: self.userPostsKey)
            } else {
                // AI帖子：从 AIPosts_v1 中删除
                self.removePostFromUserDefaults(postId: postId, key: self.aiPostsKey)
            }
            
            // 同时从存根数据中删除
            self.removePostFromStub(postId: postId)
            
            #if DEBUG
            debugLog("🗑️ 已从持久化存储永久删除帖子: \(postId)")
            #endif
        }
        
        // 🎯 关键节点：删除帖子后立即保存（确保其他帖子数据同步）
        saveAtCriticalPoint(reason: "删除帖子")
        
        // 发送删除通知
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let userInfo: [String: Any] = [
                "deletedPostId": postId.uuidString,
                "timestamp": Date().timeIntervalSince1970,
                "updateType": "postDeleted"
            ]
            
            NotificationCenter.default.post(
                name: NSNotification.Name("PostDeleted"),
                object: self,
                userInfo: userInfo
            )
        }
    }
    
    /**
     * 从 UserDefaults 中删除指定帖子
     * @param postId 要删除的帖子ID
     * @param key UserDefaults 存储键
     */
    private func removePostFromUserDefaults(postId: UUID, key: String) {
        // 读取当前存储的帖子数据
        guard let data = UserDefaults.standard.data(forKey: key) else {
            // 如果数据不存在，尝试使用旧的数组格式
            if let postsData = UserDefaults.standard.array(forKey: key) as? [[String: Any]] {
                // 过滤掉要删除的帖子
                let filteredPosts = postsData.filter { dict in
                    if let idString = dict["id"] as? String,
                       let uuid = UUID(uuidString: idString) {
                        return uuid != postId
                    }
                    return true
                }
                UserDefaults.standard.set(filteredPosts, forKey: key)
                #if DEBUG
                debugLog("🗑️ 已从 \(key) 删除帖子（旧格式），剩余 \(filteredPosts.count) 条")
                #endif
            }
            return
        }
        
        // 尝试解码为 UserPostModel 数组
        let decoder = JSONDecoder()
        guard var posts = try? decoder.decode([UserPostModel].self, from: data) else {
            #if DEBUG
            debugLog("⚠️ 无法解码 \(key) 的数据，尝试其他方法")
            #endif
            // 尝试使用旧的数组格式
            if let postsData = UserDefaults.standard.array(forKey: key) as? [[String: Any]] {
                let filteredPosts = postsData.filter { dict in
                    if let idString = dict["id"] as? String,
                       let uuid = UUID(uuidString: idString) {
                        return uuid != postId
                    }
                    return true
                }
                UserDefaults.standard.set(filteredPosts, forKey: key)
                #if DEBUG
                debugLog("🗑️ 已从 \(key) 删除帖子（备用方法），剩余 \(filteredPosts.count) 条")
                #endif
            }
            return
        }
        
        // 过滤掉要删除的帖子
        posts = posts.filter { $0.id != postId }
        
        // 保存更新后的数据
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(posts) {
            UserDefaults.standard.set(encoded, forKey: key)
            #if DEBUG
            debugLog("🗑️ 已从 \(key) 永久删除帖子，剩余 \(posts.count) 条")
            #endif
        } else {
            #if DEBUG
            debugLog("⚠️ 无法编码帖子数据到 \(key)")
            #endif
        }
    }
    
    /**
     * 从存根数据中删除帖子
     * @param postId 要删除的帖子ID
     */
    private func removePostFromStub(postId: UUID) {
        guard let data = UserDefaults.standard.data(forKey: postsStubKey) else {
            return
        }
        
        // 尝试解码为字典
        if let stub = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           var postsArray = stub["posts"] as? [[String: Any]] {
            // 过滤掉要删除的帖子
            postsArray = postsArray.filter { dict in
                if let idString = dict["id"] as? String,
                   let uuid = UUID(uuidString: idString) {
                    return uuid != postId
                }
                return true
            }
            
            var updatedStub = stub
            updatedStub["posts"] = postsArray
            
            if let encoded = try? JSONSerialization.data(withJSONObject: updatedStub) {
                UserDefaults.standard.set(encoded, forKey: postsStubKey)
                #if DEBUG
                debugLog("🗑️ 已从存根数据删除帖子")
                #endif
            }
        }
    }
    
    // MARK: - 数据一致性验证和优化保存
    
    /**
     * 验证内存数据与持久化数据的一致性
     */
    private func validateDataConsistency() {
        guard !posts.isEmpty else {
            isDataConsistent = true
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // 读取持久化的用户帖子
            let savedUserPosts = self.restoreUserPostsData()
            let savedAIPosts = self.restoreAIPostsData()
            
            // 获取当前内存中的用户帖子和AI帖子
            let currentUserPosts = self.posts.filter { $0.source == "user" }
            let currentAIPosts = self.posts.filter { post in
                guard let source = post.source else { return false }
                return source != "user" && source != "welcome"
            }
            
            // 检查数据一致性
            let userPostsConsistent = self.arePostsEqual(currentUserPosts, savedUserPosts)
            let aiPostsConsistent = self.arePostsEqual(currentAIPosts, savedAIPosts)
            
            let consistent = userPostsConsistent && aiPostsConsistent
            
            DispatchQueue.main.async {
                self.isDataConsistent = consistent
                
                if !consistent {
                    #if DEBUG
                    debugLog("   - 内存AI帖子数: \(currentAIPosts.count), 持久化: \(savedAIPosts.count)")
                    #endif
                    #if DEBUG
                    debugLog("⚠️ 数据一致性检查失败:")
                    debugLog("   - 用户帖子一致性: \(userPostsConsistent)")
                    debugLog("   - AI帖子一致性: \(aiPostsConsistent)")
                    debugLog("   - 内存用户帖子数: \(currentUserPosts.count), 持久化: \(savedUserPosts.count)")
                    #endif
                    
                    // 触发同步保存
                    self.scheduleSaveOperation(reason: "数据不一致")
                }
            }
        }
    }
    
    /**
     * 比较两个帖子数组是否相等
     */
    private func arePostsEqual(_ posts1: [UserPostModel], _ posts2: [UserPostModel]) -> Bool {
        guard posts1.count == posts2.count else { return false }
        
        let ids1 = Set(posts1.map { $0.id })
        let ids2 = Set(posts2.map { $0.id })
        
        return ids1 == ids2
    }
    
    /**
     * 调度保存操作（防抖处理）
     */
    private func scheduleSaveOperation(reason: String) {
        // 取消之前的保存操作
        pendingSaveOperation?.cancel()
        
        // 创建新的保存操作
        pendingSaveOperation = DispatchWorkItem { [weak self] in
            self?.performSaveOperation(reason: reason)
        }
        
        // 延迟执行保存操作（防抖：500ms）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: pendingSaveOperation!)
    }
    
    /**
     * 执行实际的保存操作
     */
    private func performSaveOperation(reason: String) {
        guard !posts.isEmpty else {
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // 分别保存用户帖子和AI帖子
            self.saveUserPosts()
            self.saveAIPosts()
            
            // 保存简化的存根数据
            self.savePersistentPostsStub()
            
            DispatchQueue.main.async {
                self.lastSaveTimestamp = Date()
                self.isDataConsistent = true
            }
        }
    }
    
    /**
     * 在关键节点触发保存
     */
    func saveAtCriticalPoint(reason: String) {
        scheduleSaveOperation(reason: reason)
    }
    
    /// 从UserDefaults重新加载帖子数据
    private func reloadPostsFromUserDefaults() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 1. 恢复用户帖子
            let userPosts = self.restoreUserPostsData()
            
            // 2. 恢复AI生成的帖子
            let aiPosts = self.restoreAIPostsData()
            
            // 3. 合并所有帖子并去重
            var allPostsDict: [UUID: UserPostModel] = [:]
            
            // 添加用户帖子（优先级最高）
            for post in userPosts {
                allPostsDict[post.id] = post
            }
            
            // 添加AI帖子（如果ID不冲突）
            for post in aiPosts {
                if allPostsDict[post.id] == nil {
                    allPostsDict[post.id] = post
                }
            }
            
            // 按时间倒序排列
            let uniquePosts = Array(allPostsDict.values).sorted { $0.datePosted > $1.datePosted }
            
            #if DEBUG
            debugLog("🔄 PostViewModel: 重新加载完成，共 \(uniquePosts.count) 条帖子")
            #endif
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.posts = uniquePosts
                #if DEBUG
                debugLog("✅ PostViewModel: UI已更新，显示全部 \(uniquePosts.count) 条帖子")
                #endif
            }
        }
    }
    
    /**
     * 强制立即保存（用于应用退出等场景）
     */
    func forceSave(reason: String = "强制保存") {
        #if DEBUG
        debugLog("🚨 强制保存: \(reason)")
        #endif
        
        // 取消延迟保存
        pendingSaveOperation?.cancel()
        
        // 立即执行保存
        performSaveOperation(reason: reason)
    }
    
    /**
     * 获取数据一致性状态信息
     */
    func getDataConsistencyInfo() -> String {
        let timeSinceLastSave = Date().timeIntervalSince(lastSaveTimestamp)
        return """
        数据一致性状态: \(isDataConsistent ? "✅" : "❌")
        距离上次保存: \(String(format: "%.1f", timeSinceLastSave))秒
        内存帖子数: \(posts.count)
        待保存操作: \(pendingSaveOperation != nil ? "是" : "否")
        """
    }
}
