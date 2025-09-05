import SwiftUI
import Foundation
import UIKit
import Combine

/**
 * 全局CommentLoader管理器
 * 避免每个PostCardView都创建独立的CommentLoader实例
 */
class CommentLoaderManager: ObservableObject {
    static let shared = CommentLoaderManager()
    
    private var loaders: [UUID: CommentLoader] = [:]
    private let queue = DispatchQueue(label: "CommentLoaderManager", qos: .utility)
    
    private init() {

    }
    
    // 获取或创建CommentLoader
    func getLoader(for postID: UUID) -> CommentLoader {
        return queue.sync {
            if let existingLoader = loaders[postID] {
                return existingLoader
            } else {
    
                let newLoader = CommentLoader()
                loaders[postID] = newLoader
                return newLoader
            }
        }
    }
    
    // 清理未使用的Loader
    func cleanupUnusedLoaders(activePosts: Set<UUID>) {
        queue.async {
            let unusedKeys = self.loaders.keys.filter { !activePosts.contains($0) }
            for key in unusedKeys {

                self.loaders.removeValue(forKey: key)
            }
        }
    }
}

/**
 * 后台数据加载器
 * 用于将数据加载从UI线程分离，优化性能
 */
class CommentLoader: ObservableObject {
    @Published var loadedComments: [DetailedCommentModel] = []
    @Published var isLoading: Bool = false
    @Published var hasMoreComments: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isInitialized: Bool = false
    @Published var isPreloaded: Bool = false
    
    // 加载控制
    private var loadingTask: Task<Void, Never>? = nil
    private var allComments: [DetailedCommentModel] = []
    private var currentPage: Int = 1
    private var pageSize: Int = 10
    private var isInitialLoad: Bool = true
    private var currentPostID: UUID? = nil
    
    // 初始化
    init() {
        // 移除初始化日志，减少噪音
        setupNotifications()
    }
    
    deinit {
        // 保留清理日志，但只在debug模式下输出
        #if DEBUG

        #endif
        removeNotifications()
        cancelLoading()
    }
    
    // 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommentsUpdated(_:)),
            name: NSNotification.Name("PostCommentsUpdated"),
            object: nil
        )
        
        // 添加对角色回复生成完成的通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCharacterReplyGenerated(_:)),
            name: NSNotification.Name("CharacterReplyGenerated"),
            object: nil
        )
        
        // 添加对角色回复生成失败的通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCharacterReplyGenerationFailed(_:)),
            name: NSNotification.Name("CharacterReplyGenerationFailed"),
            object: nil
        )
        

    }
    
    // 移除通知监听
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("PostCommentsUpdated"),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("CharacterReplyGenerated"),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("CharacterReplyGenerationFailed"),
            object: nil
        )
        

    }
    
    // 取消加载任务
    private func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    // 处理评论更新通知
    @objc private func handleCommentsUpdated(_ notification: Notification) {
        // 提取通知中的帖子ID
        guard let userInfo = notification.userInfo,
              let postIDString = userInfo["postID"] as? String,
              let postID = UUID(uuidString: postIDString) else {
            return
        }
        
        // 🔧 修复：减少日志输出，只在真正需要时输出
        let shouldLog = currentPostID == postID
        
        if shouldLog {
    
        }
        
        // 检查是否与当前加载的帖子匹配
        if let currentID = currentPostID, currentID == postID {
            
            // 在主线程执行UI更新
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 刷新评论
                self.refreshComments()
            }
        }
    }
    
    // 处理角色回复生成完成的通知
    @objc private func handleCharacterReplyGenerated(_ notification: Notification) {
        // 提取通知中的帖子ID
        guard let userInfo = notification.userInfo,
              let postIDString = userInfo["postID"] as? String,
              let postID = UUID(uuidString: postIDString) else {
            return
        }
        
        // 🔧 修复：减少日志输出，只在真正需要时输出
        let shouldLog = currentPostID == postID
        
        if shouldLog {
    
        }
        
        // 检查是否与当前加载的帖子匹配
        if let currentID = currentPostID, currentID == postID {
            // 在主线程执行UI更新
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 刷新评论
                self.refreshComments()
            }
        }
    }
    
    // 处理角色回复生成失败的通知
    @objc private func handleCharacterReplyGenerationFailed(_ notification: Notification) {
        // 提取通知中的帖子ID和错误信息
        guard let userInfo = notification.userInfo,
              let postID = userInfo["postID"] as? String,
              let errorMessage = userInfo["error"] as? String else {
            return
        }
        
        // 🔧 修复：减少日志输出，只在真正需要时输出
        let shouldLog = currentPostID?.uuidString == postID
        
        if shouldLog {
    
            print("❌ 错误信息: \"\(errorMessage)\"")
        }
        
        // 检查是否与当前加载的帖子匹配
        if let currentID = currentPostID, currentID.uuidString == postID {
            if shouldLog {
    
            }
            
            // 在主线程执行UI更新
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 设置错误信息
                self.errorMessage = "生成角色评论失败: \(errorMessage)"
                
                if shouldLog {
        
                }
            }
        }
    }
    
    // 刷新评论内容 - 智能刷新，避免不必要的重复加载
    func refreshComments() {
        // 🔧 修复：减少日志输出，只在真正需要时输出
        let shouldLog = true // 刷新操作总是需要日志
        

        
        // 取消正在进行的加载任务
        loadingTask?.cancel()
        
        // 🔧 修复：检查评论数据是否真的发生了变化
        let currentCommentCount = loadedComments.count
        let totalCommentCount = allComments.count
        
        // 如果评论数量和内容都没有变化，跳过刷新
        if currentCommentCount == totalCommentCount && 
           currentCommentCount > 0 && 
           !hasCommentContentChanged() {
            if shouldLog {
    
            }
            return
        }
        
        if shouldLog {
    
        }
        
        // 重置加载状态
        currentPage = 1
        loadedComments = []
        isLoading = true
        
        // 创建刷新任务
        loadingTask = Task { @MainActor in
            // 模拟网络延迟，避免阻塞UI
            try? await Task.sleep(nanoseconds: 100_000) // 0.1毫秒
            
            // 检查任务是否被取消
            if Task.isCancelled {
                return
            }
            
            // 加载评论
            let refreshCount = min(pageSize, allComments.count)
            let refreshedComments = Array(allComments.prefix(refreshCount))
            
            // 更新UI状态
            self.loadedComments = refreshedComments
            self.hasMoreComments = allComments.count > refreshCount
            self.isLoading = false
            

        }
    }
    
    // 检查评论内容是否发生变化
    private func hasCommentContentChanged() -> Bool {
        // 如果评论数量不同，内容肯定发生了变化
        if loadedComments.count != allComments.count {
            return true
        }
        
        // 检查每条评论的内容是否发生变化
        for (index, loadedComment) in loadedComments.enumerated() {
            if index < allComments.count {
                let allComment = allComments[index]
                if loadedComment.content != allComment.content || 
                   loadedComment.username != allComment.username ||
                   loadedComment.isVirtualCharacter != allComment.isVirtualCharacter {
                    return true
                }
            } else {
                return true
            }
        }
        
        return false
    }
    
    // 初始化加载器
    func initialize(with comments: [DetailedCommentModel], postID: UUID? = nil) {
        // 🔧 修复：减少日志输出，只在真正需要时输出
        let shouldLog = !isInitialized || currentPostID != postID
        
        if shouldLog {
    
        }
        
        // 记录当前帖子ID
        if let id = postID {
            if shouldLog {
    
            }
            self.currentPostID = id
        } else {
            if shouldLog {
    
            }
            self.currentPostID = nil
        }
        
        self.allComments = comments
        self.loadedComments = []
        self.currentPage = 1
        self.hasMoreComments = !comments.isEmpty
        self.isInitialized = true
        self.errorMessage = nil
        
        // 记录评论数量信息
        if shouldLog {
    
            
            // 如果有虚拟角色评论，单独记录
            let virtualComments = comments.filter { $0.isVirtualCharacter }
            if !virtualComments.isEmpty {
    
            }
        }
        
        // 自动预加载评论
        if !comments.isEmpty {
            if shouldLog {
    
            }
            preloadFirstComments()
        } else {
            if shouldLog {
    
            }
        }
    }
    
    // 重置加载状态
    func resetLoading() {
        // 取消之前的加载任务
        loadingTask?.cancel()
        
        loadedComments = []
        currentPage = 1
        hasMoreComments = !allComments.isEmpty
        isLoading = false
        isPreloaded = false
        errorMessage = nil
    }
    
    // 预加载首批评论 - 无动画方式，优化性能
    private func preloadFirstComments() {
        // 取消之前的任务
        loadingTask?.cancel()
        
        // 如果已经预加载过，跳过
        if isPreloaded {
            return
        }
        
        // 🔧 优化：减少日志输出，只在真正需要时输出
        let shouldLog = !isPreloaded
        
        if shouldLog {

        }
        
        // 计算要预加载的评论数量
        let preloadCount = min(pageSize, allComments.count)
        
        if shouldLog {
    
        }
        
        // 创建预加载任务
        loadingTask = Task { @MainActor in
            // 模拟网络延迟，避免阻塞UI
            try? await Task.sleep(nanoseconds: 100_000) // 0.1毫秒
            
            // 检查任务是否被取消
            if Task.isCancelled {
                if shouldLog {
    
                }
                return
            }
            
            // 预加载首批评论
            let firstComments = Array(allComments.prefix(preloadCount))
            self.loadedComments = firstComments
            self.isPreloaded = true
            self.isLoading = false
        }
    }
    
    // 加载下一页评论
    func loadNextPage() {
        guard !isLoading && hasMoreComments else { return }
        
        // 🔧 优化：减少日志输出，只在真正需要时输出
        let shouldLog = !isLoading
        
        if shouldLog {
    
        }
        
        isLoading = true
        
        // 创建加载任务
        loadingTask = Task { @MainActor in
            // 模拟网络延迟，避免阻塞UI
            try? await Task.sleep(nanoseconds: 100_000) // 0.1毫秒
            
            // 检查任务是否被取消
            if Task.isCancelled {
                if shouldLog {
    
                }
                return
            }
            
            // 计算要加载的评论范围
            let startIndex = loadedComments.count
            let endIndex = min(startIndex + pageSize, allComments.count)
            let newComments = Array(allComments[startIndex..<endIndex])
            
            // 更新UI状态
            self.loadedComments.append(contentsOf: newComments)
            self.currentPage += 1
            self.hasMoreComments = endIndex < allComments.count
            self.isLoading = false
            
            if shouldLog {
                
            }
        }
    }
    
    /**
     * 加载评论 - 优化的渐进式加载方法
     * @param forPostID 帖子ID
     * @param resetPagination 是否重置分页（首次加载为true）
     */
    func loadComments(forPostID: String, resetPagination: Bool = false) {
        if isLoading { return }
        
        // 重置分页状态
        if resetPagination {
            currentPage = 1
            loadedComments = []
            hasMoreComments = false
            isInitialLoad = true
        }
        
        isLoading = true
        errorMessage = nil
        
        // 🔧 修复：使用真实的评论数据而不是模拟数据
        // 从 allComments 数组获取数据，这个数组应该与 PostViewModel 保持同步
        let availableComments = self.allComments
        
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + (isInitialLoad ? 0.5 : 0.8)) {
            var newComments: [DetailedCommentModel] = []
            
            // 内容量基于分页加载
            let start = (self.currentPage - 1) * self.pageSize
            let end = min(start + self.pageSize, availableComments.count)
            
            if start < availableComments.count {
                for i in start..<end {
                    if i < availableComments.count {
                        let comment = availableComments[i]
                        newComments.append(comment)
                    }
                }
                
                // 渐进式更新UI
                if self.isInitialLoad && !newComments.isEmpty {
                    // 首次加载时，先显示1-2条评论，然后再添加其余评论
                    let firstBatch = Array(newComments.prefix(min(2, newComments.count)))
                    self.loadedComments = firstBatch
                    
                    // 短暂延迟后加载剩余评论
                    if newComments.count > 2 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let remainingComments = Array(newComments.dropFirst(min(2, newComments.count)))
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.loadedComments.append(contentsOf: remainingComments)
                            }
                        }
                    }
                } else {
                    // 加载更多时直接添加所有新评论
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.loadedComments.append(contentsOf: newComments)
                    }
                }
                
                // 更新分页状态
                self.hasMoreComments = end < availableComments.count
                self.currentPage += 1
                self.isInitialLoad = false
            }
            
            self.isLoading = false
        }
    }
    
    // 添加评论（避免重复）
    func addComment(_ comment: DetailedCommentModel) {

        
        // 🔧 修复：检查是否已存在相同ID的评论，避免重复添加
        if allComments.contains(where: { $0.id == comment.id }) {

            return
        }
        
        // 添加到所有评论列表
        allComments.insert(comment, at: 0)
        
        // 添加到已加载的评论列表（确保显示在最前面）
        loadedComments.insert(comment, at: 0)
        
        // 更新分页状态
        hasMoreComments = allComments.count > loadedComments.count
        
        // 打印添加的评论信息
        let _ = comment.isVirtualCharacter ? "虚拟角色评论" : "用户评论"
        let _ = comment.isVirtualCharacter ? "(角色ID: \(comment.characterID ?? "未知"))" : ""

        
        // 如果有帖子ID，发送通知以更新其他可能显示此帖子的视图
        if let postID = currentPostID {
    
            
            // 在主线程上发送通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostCommentsUpdated"),
                    object: nil,
                    userInfo: ["postID": postID.uuidString]
                )
            }
        }
    }
    
    // 获取角色名称
    private func getCharacterName(for characterID: String) -> String {
        switch characterID.lowercased() {
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
    
    // 获取角色头像
    private func getCharacterAvatar(for characterID: String) -> String {
        switch characterID.lowercased() {
        case "einstein":
            return "atom" 
        case "shakespeare":
            return "book.fill"
        case "davinci":
            return "paintpalette.fill"
        case "goku":
            return "person.fill.viewfinder"
        case "holmes":
            return "magnifyingglass"
        case "naruto":
            return "tornado"
        case "confucius":
            return "scroll.fill"
        case "newton":
            return "arrow.down.circle.fill"
        case "libai":
            return "text.book.closed.fill"
        default:
            return "person.circle.fill"
        }
    }
    
    // 🔧 新增：清理重复评论的方法
    private func removeDuplicateComments(_ comments: [DetailedCommentModel]) -> [DetailedCommentModel] {
        var uniqueComments: [DetailedCommentModel] = []
        var seenIds = Set<UUID>()
        
        for comment in comments {
            if !seenIds.contains(comment.id) {
                uniqueComments.append(comment)
                seenIds.insert(comment.id)
            } else {
    
            }
        }
        
        return uniqueComments
    }
    
    // 获取当前帖子ID
    var postID: UUID? {
        return currentPostID
    }
    
    // 检查是否为指定帖子的加载器
    func isForPost(_ postID: UUID) -> Bool {
        return currentPostID == postID
    }
}

// 定义帖子显示模式枚举
enum DisplayMode {
    case preview     // 预览模式（默认），显示有限内容
    case detail      // 详情模式，显示全部内容
    case compact     // 紧凑模式，用于列表或网格视图
}

/**
 * 统一帖子卡片视图
 * 用于在应用中所有位置显示帖子内容，确保格式一致性
 */
struct PostCardView: View {
    // 帖子数据
    let post: UserPostModel
    
    // 环境对象
    @EnvironmentObject var viewModel: PostViewModel
    
    // 添加帖子来源枚举类型
    enum PostSource {
        case userGenerated   // 用户自己生成
        case aiGenerated     // AI生成
    }
    
    // 帖子来源
    var postSource: PostSource = .aiGenerated
    
    // 状态属性
    @State private var isExpanded: Bool = false
    @State private var showComments: Bool = false
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    @State private var showImageViewer: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var commentText: String = ""  // 新增：评论文本
    @State private var replyingTo: DetailedCommentModel? = nil  // 新增：回复对象
    @State private var isSharePresented: Bool = false // 新增：分享菜单展示状态
    @State private var showPostOptions: Bool = false // 新增：帖子选项展示状态
    
    // 新增：编辑帖子状态
    @State private var showEditPost: Bool = false
    
    // 点击回调
    var onPostTap: () -> Void = {}
    
    // 计算属性：判断是否为用户发布的动态
    private var isUserPost: Bool {
        // 获取所有虚拟角色名称
        let allCharacterNames = CharacterDataManager.shared.getAllCharactersInfo().map { $0.name }
        // 不是虚拟角色且不是AI助手的动态，认为是用户发布的
        return !allCharacterNames.contains(post.username) && post.username != "AI助手"
    }
    var onLikeToggle: ((Bool) -> Void)?
    var onCommentToggle: (() -> Void)?
    var onBookmarkToggle: ((Bool) -> Void)?
    var onShare: (() -> Void)?
    var onAddComment: ((UserPostModel, String, String?) -> Void)?
    
    // 用户自己帖子的操作回调
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onPin: ((Bool) -> Void)?
    
    // 显示选项
    var showUserInfo: Bool = true
    var maxPreviewLines: Int = 5
    var maxPreviewLength: Int = 250
    var showActions: Bool = true
    var showCommentSection: Bool = true
    var fullWidthImages: Bool = false
    var isDetailView: Bool = false
    var displayMode: DisplayMode = .preview
    var isOwnPost: Bool = false
    
    // 评论加载器 - 使用全局管理器
    @State private var commentLoader: CommentLoader?
    
    // 触觉反馈
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // 交互状态
    @State private var isTapped: Bool = false
    
    // 新增：智能内容显示计算属性
    private var shouldShowExpandButton: Bool {
        // 详情视图不需要展开按钮
        if isDetailView { return false }
        
        // 内容少于250字符，不需要展开按钮，直接完整显示
        // 这样中等长度内容（如200字左右）也会直接完整显示
        if post.content.count < maxPreviewLength { return false }
        
        // 估算行数，如果内容估计不超过显示行数，不需要展开按钮
        let estimatedLines = estimateTextLines(post.content)
        return estimatedLines > 15 // 设置更高的行数阈值，避免中等长度内容被截断
    }
    
    // 估算文本行数的辅助方法
    private func estimateTextLines(_ text: String) -> Int {
        // 使用更准确的文本行数估算
        let averageCharsPerLine = 35 // 根据字体大小调整
        return max(1, Int(ceil(Double(text.count) / Double(averageCharsPerLine))))
    }
    

    
    // 新增：评论预览获取逻辑
    private var previewComments: [DetailedCommentModel] {
        // 只在预览模式下限制评论数量
        if displayMode == .preview {
            // 🔧 修复：使用getTopLevelComments()而不是直接访问post.comments
            let topLevelComments = post.getTopLevelComments()
            
            // 获取一条历史人物的评论
            let virtualComments = topLevelComments.filter { $0.isVirtualCharacter }.prefix(1)
            
            // 获取一条高赞评论
            let featuredComments = topLevelComments
                .filter { $0.likes > 20 }
                .filter { comment in !virtualComments.contains(where: { $0.id == comment.id }) }
                .prefix(1)
            
            // 组合评论，限制为最多2条
            var result = Array(virtualComments)
            if result.count < 2 {
                result.append(contentsOf: featuredComments)
            }
            
            return result
        } else {
            // 在详情模式下不做限制，但一般也不会使用这个属性
            return []
        }
    }
    
    // 新增：是否应该显示完整评论区
    private var shouldShowFullComments: Bool {
        return displayMode == .detail && showComments && showCommentSection
    }
    
    // 新增：评论输入区域 - 优化体验
    @State private var isCommentSubmitting: Bool = false
    @State private var isFocusedOnComment: Bool = false
    
    // 初始化
    init(
        post: UserPostModel,
        onPostTap: @escaping () -> Void = {},
        onLikeToggle: ((Bool) -> Void)? = nil,
        onCommentToggle: (() -> Void)? = nil,
        onBookmarkToggle: ((Bool) -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onAddComment: ((UserPostModel, String, String?) -> Void)? = nil,
        showUserInfo: Bool = true,
        maxPreviewLines: Int = 5,
        maxPreviewLength: Int = 250,
        showActions: Bool = true,
        showCommentSection: Bool = true,
        fullWidthImages: Bool = false,
        isDetailView: Bool = false,
        displayMode: DisplayMode = .preview,
        isOwnPost: Bool = false,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onPin: ((Bool) -> Void)? = nil,
        postSource: PostSource = .aiGenerated
    ) {
        self.post = post
        self.onPostTap = onPostTap
        self.onLikeToggle = onLikeToggle
        self.onCommentToggle = onCommentToggle
        self.onBookmarkToggle = onBookmarkToggle
        self.onShare = onShare
        self.onAddComment = onAddComment
        self.showUserInfo = showUserInfo
        self.maxPreviewLines = maxPreviewLines
        self.maxPreviewLength = maxPreviewLength
        self.showActions = showActions
        self.showCommentSection = showCommentSection
        self.fullWidthImages = fullWidthImages
        self.isDetailView = isDetailView
        self.displayMode = displayMode
        self.isOwnPost = isOwnPost
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onPin = onPin
        self.postSource = postSource
        
        // 使用全局点赞状态管理器初始化状态
        _isLiked = State(initialValue: LikeStateManager.shared.isLiked(post.id.uuidString))
        _isBookmarked = State(initialValue: post.isBookmarkedByCurrentUser)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            // 用户信息部分
            if showUserInfo {
                userInfoSection
            }
            
            // 内容部分
            contentSection
                
            // 图片部分 - 只在有图片时显示
            if !post.images.isEmpty {
                imageGallerySection
            }
            
            // 评论预览部分 - 调整上方间距，减少空白
            if !post.comments.isEmpty && (displayMode == .preview || displayMode == .compact) && !isDetailView {
                virtualCommentPreviewSection
                    .padding(.top, -6) // 进一步减少与图片区域之间的间距 (原为-4)
            }
            
            // 添加简单分割线
            Divider().opacity(0.4).padding(.vertical, 4.0)
            
            // 操作按钮部分
            if showActions {
                actionButtonsSection
            }
            
            // 评论部分 - 仅在详情模式下显示完整评论区
            if shouldShowFullComments {
                populatedCommentSection
            }
        }
        .padding(.top, 12) // 减少顶部内边距,原来是默认值DesignSystem.Spacing.m(16)
        .padding([.bottom, .horizontal], DesignSystem.Spacing.m)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: DesignSystem.Borders.standard.width)
        )
        .shadow(
            color: DesignSystem.Shadows.cardShadow.color,
            radius: DesignSystem.Shadows.cardShadow.radius,
            x: DesignSystem.Shadows.cardShadow.x,
            y: DesignSystem.Shadows.cardShadow.y
        )
        .padding(.horizontal, DesignSystem.Spacing.s)
        .padding(.vertical, 8) // 减少外部垂直间距,原为10
        .contentShape(Rectangle()) // 确保整个区域可点击
        .onTapGesture {
            // 仅在预览模式下启用整卡点击，避免在详情模式下重复打开详情页
            if displayMode == .preview && !isDetailView {
                // 触觉反馈
                feedbackGenerator.impactOccurred(intensity: 0.5)
                onPostTap()
            }
        }
        .onAppear {
            // 🚀 性能优化：仅在必要时初始化CommentLoader
            if commentLoader == nil {
                commentLoader = CommentLoaderManager.shared.getLoader(for: post.id)
            }
            
            // 🚀 性能优化：只在详情模式下才预加载评论，避免不必要的网络请求
            if displayMode == .detail && showCommentSection {
                commentLoader?.loadNextPage()
            }
        }
        .onDisappear {
            // 可以在这里进行清理，但由于使用全局管理器，暂时不需要特殊处理
        }
        .wechatStyleImageViewer(
            isPresented: $showImageViewer,
            images: post.images,
            initialIndex: selectedImageIndex
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostLikeUpdated"))) { notification in
            // 监听帖子点赞更新通知，刷新当前卡片的点赞数
            if let postIdString = notification.userInfo?["postID"] as? String,
               postIdString == post.id.uuidString {
                
                print("❤️ PostCardView: 收到PostLikeUpdated通知，当前帖子点赞数需要更新")
                
                // 从PostViewModel获取最新的帖子数据并更新本地状态
                if let updatedPost = PostViewModel.shared.posts.first(where: { $0.id.uuidString == postIdString }) {
                    DispatchQueue.main.async {
                        // 更新本地点赞状态，触发UI刷新
                        isLiked = updatedPost.isLikedByCurrentUser
                        print("✅ PostCardView: 帖子卡片点赞数已更新: \(updatedPost.likes)")
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图组件
    
    // 用户信息区域
    private var userInfoSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // 用户头像 - 根据是否为用户发布的动态使用不同数据源
            if isUserPost {
                // 用户发布的动态使用UserProfileManager的数据
                Avatar(
                    url: UserProfileManager.shared.getCurrentAvatarURL(),
                    name: UserProfileManager.shared.getCurrentUsername(),
                    category: "",
                    size: 46.0
                )
            } else {
                // 其他用户或历史人物发布的动态使用原始数据
                Avatar(
                    url: post.userAvatar,
                    name: post.username,
                    category: post.username.contains("探索") ? "历史爱好者" : "",
                    size: 46.0
                )
            }
            
            // 用户信息 - 更紧凑的布局
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 用户名 - 根据是否为用户发布的动态使用不同数据源
                    Text(isUserPost ? UserProfileManager.shared.getCurrentUsername() : post.username)
                        .font(.system(size: 16.0, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    // 用户标签 - 统一标签样式
                    if post.username.contains("探索") {
                        userTagView("历史爱好者")
                    }
                    
                    Spacer()
                
                    // 根据帖子来源和是否为用户自己的帖子选择不同的选项按钮
                    if postSource == .userGenerated && isOwnPost {
                        // 用户自己的帖子显示编辑、删除、置顶选项
                        UserPostOptionsButton(
                        post: post,
                            onEdit: {
                                if let onEdit = onEdit {
                                    onEdit()
                                }
                            },
                            onDelete: {
                                if let onDelete = onDelete {
                                    onDelete()
                                }
                            },
                            onPin: { isPinned in
                                if let onPin = onPin {
                                    onPin(isPinned)
                                }
                            }
                        )
                    } else {
                        // AI生成的帖子显示关注、屏蔽选项
                        CustomPostOptionsButton(
                            post: post,
                            onDislikeCharacter: dislikeCharacter,
                        onFollowCharacter: { isFollowed in
                            // 关注角色的逻辑
                            feedbackGenerator.impactOccurred(intensity: 0.4)
                        }
                    )
                    }
                }
                
                // 发布时间与内容类型简化为一行，字体更小但确保可读性
                HStack(spacing: 6) {
                    Text(post.getFormattedTimeAgo())
                        .font(.system(size: 13.0, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    if !isDetailView {
                        // 内容类型指示器
                        Text("•")
                            .font(.system(size: 13.0))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        // 显示帖子来源信息
                        Text(postSource == .userGenerated ? "自己发布" : "AI生成")
                            .font(.system(size: 13.0, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text("•")
                            .font(.system(size: 13.0))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Text(post.images.isEmpty ? "文字" : "图文")
                            .font(.system(size: 13.0, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
        }
        .padding(.bottom, 6.0) // 减少底部间距,原来是10.0
    }
    
    // 内容区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) { // 减少内容的垂直间距 (原为8)
            // 帖子文本内容
            if !post.content.isEmpty {
                contentTextSection
            }
            
            // 如果是预览模式且内容被截断，显示"全文"按钮
            if shouldShowExpandButton && !isExpanded && displayMode == .preview {
                    Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = true
                    }
                }) {
                    Text("全文")
                        .font(.system(size: 15, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.top, 2) // 减少"全文"按钮的上方间距 (原为4)
                    }
                    .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 2) // 减少内容区域的底部间距 (原为8)
    }
    
    // 帖子文本内容视图
    private var contentTextSection: some View {
        Text(post.content)
            .font(.system(size: 16.0, weight: .regular))
            .foregroundColor(DesignSystem.Colors.primaryText)
            // 修复lineLimit条件，确保短内容显示完整
            .lineLimit(isExpanded || isDetailView || !shouldShowExpandButton ? nil : maxPreviewLines)
            .lineSpacing(5.0) // 减少行间距提高紧凑度（原为6.0）
            .fixedSize(horizontal: false, vertical: true) // 确保文本正确换行
    }
    
    // 图片画廊区域
    private var imageGallerySection: some View {
        Group {
            // 根据图片数量选择不同的布局
            switch post.images.count {
            case 1:
                // 单张图片布局 - 保持原比例但有最大尺寸限制
                singleImageScrollView(post.images[0])
                    .padding(.top, 2) // 减少图片区域的顶部内边距 (原为4或0)
                    .padding(.bottom, 2) // 减少图片区域的底部内边距 (原为4或0)
            case 2:
                // 两张图片布局 - 微信风格的方形网格
                wechatStyleGridLayout(columns: 2)
                    .padding(.top, 2) // 减少图片区域的顶部内边距 (原为4或0)
                    .padding(.bottom, 2) // 减少图片区域的底部内边距 (原为4或0)
            case 3:
                // 三张图片布局 - 微信风格的方形网格
                wechatStyleGridLayout(columns: 3)
                    .padding(.top, 2) // 减少图片区域的顶部内边距 (原为4或0)
                    .padding(.bottom, 2) // 减少图片区域的底部内边距 (原为4或0)
            case 4:
                // 四张图片布局 - 微信风格的2x2网格
                wechatStyleGridLayout(columns: 2)
                    .padding(.top, 2) // 减少图片区域的顶部内边距 (原为4或0)
                    .padding(.bottom, 2) // 减少图片区域的底部内边距 (原为4或0)
            case 5, 6:
                // 5-6张图片布局 - 微信风格的2行网格
                wechatStyleGridLayout(columns: 3)
                    .padding(.top, 2) // 减少图片区域的顶部内边距 (原为4或0)
                    .padding(.bottom, 2) // 减少图片区域的底部内边距 (原为4或0)
            case 7, 8, 9:
                // 7-9张图片布局 - 微信风格的3x3网格
                wechatStyleGridLayout(columns: 3)
                    .padding(.top, 2) // 减少图片区域的顶部内边距 (原为4或0)
                    .padding(.bottom, 2) // 减少图片区域的底部内边距 (原为4或0)
            default:
                Color.clear
            }
        }
    }
    
    // 单张图片视图 - 微信朋友圈风格，靠左对齐
    private func singleImageScrollView(_ imageName: String) -> some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                    Button(action: {
            selectedImageIndex = 0
            showImageViewer = true
            feedbackGenerator.impactOccurred(intensity: 0.5)
        }) {
                    if imageName.contains("_image_") {
                        // 用户上传的图片
                        PostImageView(
                            imageId: imageName,
                            contentMode: .fit,
                            height: calculateSingleImageHeight(for: imageName, width: geometry.size.width * 0.85),
                            cornerRadius: 3
                        )
                        .id("thumbnail_\(imageName)")
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
                    } else if let uiImage = UIImage(named: imageName) {
                        // 内置图片资源
                    Image(uiImage: uiImage)
                    .resizable()
                            .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: geometry.size.width * 0.85)
                            .frame(maxHeight: calculateSingleImageHeight(for: imageName, width: geometry.size.width * 0.85))
                            .id("thumbnail_\(imageName)")
                                .cornerRadius(3)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                    .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
                    } else {
                        // 占位图
                    generateMockImage(for: imageName)
                                .frame(maxWidth: geometry.size.width * 0.85)
                            .frame(height: 200)
                            .id("thumbnail_\(imageName)")
                                .cornerRadius(3)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
            }
        }
        .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .frame(height: calculateSingleImageHeight(for: imageName, width: (UIScreen.main.bounds.width - 40) * 0.85))
    }
    
    // 为单图计算适合的高度，保持图片原始比例但限制最大高度
    private func calculateSingleImageHeight(for imageName: String, width: CGFloat) -> CGFloat {
        // 用户上传的图片用固定高度
        if imageName.contains("_image_") {
            return 200.0 // 微信朋友圈单图高度约为200-220
        }
        
        // 获取图片
        guard let uiImage = UIImage(named: imageName) else { 
            return 200.0 // 默认高度
        }
        
        // 计算图片宽高比
        let aspectRatio = uiImage.size.width / uiImage.size.height
        
        // 基于宽度和比例计算高度，保持原始比例
        var calculatedHeight = width / aspectRatio
        
        // 微信朋友圈风格：限制最小和最大高度
        calculatedHeight = min(max(calculatedHeight, 120.0), 220.0) // 微信朋友圈的高度限制
        
        // 根据内容类型调整高度
        if aspectRatio > 2.0 {
            // 超宽图片限制高度
            calculatedHeight = min(calculatedHeight, 150.0)
        } else if aspectRatio < 0.5 {
            // 超窄图片提高高度
            calculatedHeight = min(calculatedHeight, 220.0)
        }
        
        return calculatedHeight
    }
    
    // 微信风格的网格布局 - 适用于2-9张图片
    private func wechatStyleGridLayout(columns: Int) -> some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let spacing: CGFloat = 2 // 微信风格的小间距
            
            // 计算每个图片的尺寸
            let itemWidth = (totalWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
            
            // 计算行数
            let rows = Int(ceil(Double(post.images.count) / Double(columns)))
            
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { column in
                            let index = row * columns + column
                            if index < post.images.count {
                Button(action: {
            selectedImageIndex = index
                    showImageViewer = true
            feedbackGenerator.impactOccurred(intensity: 0.5)
                }) {
                                    wechatStyleImageItem(post.images[index], size: itemWidth)
                                }
                                .buttonStyle(PlainButtonStyle())
                    } else {
                                // 占位，保持网格结构完整
                                Color.clear
                                    .frame(width: itemWidth, height: itemWidth)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: calculateWechatGridHeight(columns: columns))
    }
    
    // 微信风格的单个图片项 - 正方形裁剪
    private func wechatStyleImageItem(_ imageName: String, size: CGFloat) -> some View {
        Group {
            if imageName.contains("_image_") {
                // 用户上传的图片
                PostImageView(
                    imageId: imageName,
                    contentMode: .fill, // 使用fill以裁剪为正方形
                    cornerRadius: 3 // 微信风格的小圆角
                )
                .id("thumbnail_\(imageName)")
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 3)) // 确保内容被剪裁为圆角
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
            } else if let uiImage = UIImage(named: imageName) {
                // 内置图片
                Image(uiImage: uiImage)
                        .resizable()
                    .aspectRatio(contentMode: .fill) // 使用fill以裁剪为正方形
                    .frame(width: size, height: size)
                    .id("thumbnail_\(imageName)")
                    .cornerRadius(3) // 微信风格的小圆角
                    .clipShape(RoundedRectangle(cornerRadius: 3)) // 确保内容被剪裁为圆角
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    } else {
                // 占位图
                generateMockImage(for: imageName)
                    .frame(width: size, height: size)
                    .cornerRadius(3) // 微信风格的小圆角
                    .clipShape(RoundedRectangle(cornerRadius: 3)) // 确保内容被剪裁为圆角
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            }
        }
    }
    
    // 计算微信风格网格布局的高度
    private func calculateWechatGridHeight(columns: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40 // 考虑边距
        let spacing: CGFloat = 2 // 微信风格的小间距
        let itemWidth = (screenWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
        
        // 计算行数
        let rows = Int(ceil(Double(post.images.count) / Double(columns)))
        
        // 计算总高度 = 行数 * 单元格高度 + (行数-1) * 间距
        return (CGFloat(rows) * itemWidth) + (CGFloat(rows - 1) * spacing)
    }
    
    // 添加新方法：生成模拟图片
    private func generateMockImage(for imageName: String) -> some View {
        let imageType = getImageType(from: imageName)
        
        return ZStack {
            // 基于图片名称生成背景色
            getColorForImage(imageName)
                .opacity(0.15)
            
            VStack(spacing: 12) {
                // 基于图片类型选择图标
                Image(systemName: getIconForImageType(imageType))
                    .font(.system(size: 35))
                    .foregroundColor(getColorForImage(imageName))
                
                // 显示图片描述
                if let description = getImageDescription(for: imageName) {
                    Text(description)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .lineLimit(2)
                }
                
                // 添加加载状态指示器
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.3), value: imageType)
    }
    
    // 获取图片类型
    private func getImageType(from imageName: String) -> String {
        if imageName.contains("portrait") {
            return "portrait"
        } else if imageName.contains("landscape") {
            return "landscape"
        } else if imageName.contains("formula") || imageName.contains("manuscript") {
            return "document"
        } else if imageName.contains("einstein") {
            return "person"
        } else if imageName.contains("davinci") || imageName.contains("vitruvian") {
            return "art"
        } else if imageName.contains("libai") || imageName.contains("poetry") || imageName.contains("poem") {
            return "poetry"
        } else if imageName.contains("calligraphy") {
            return "calligraphy"
        } else if imageName.contains("mountain") || imageName.contains("river") {
            return "nature"
        }
        return "general"
    }
    
    // 为图片类型选择图标
    private func getIconForImageType(_ type: String) -> String {
        switch type {
        case "portrait":
            return "person.crop.rectangle.fill"
        case "landscape":
            return "photo.fill"
        case "document":
            return "doc.text.fill"
        case "person":
            return "person.fill"
        case "art":
            return "paintpalette.fill"
        case "poetry":
            return "text.book.closed.fill"
        case "calligraphy":
            return "pencil.tip.crop.circle.fill"
        case "nature":
            return "mountain.2.fill"
        default:
            return "photo.fill"
        }
    }
    
    // 根据图片名称获取颜色
    private func getColorForImage(_ imageName: String) -> Color {
        if imageName.contains("einstein") || imageName.contains("physics") || imageName.contains("formula") {
            return Color.blue
        } else if imageName.contains("davinci") || imageName.contains("vitruvian") {
            return Color.green
        } else if imageName.contains("libai") || imageName.contains("poetry") || imageName.contains("ancient") {
            return Color.orange
        } else if imageName.contains("workshop") {
            return Color.purple
        } else if imageName.contains("mountain") || imageName.contains("river") {
            return Color.teal
        }
        return Color.gray
    }
    
    // 计算图片高度 - 根据图片比例和内容调整
    private func calculateImageHeight(for imageName: String, width: CGFloat) -> CGFloat {
        // 获取图片
        guard let uiImage = UIImage(named: imageName) else { 
            return 200.0 // 默认高度
        }
        
        // 计算图片宽高比
        let aspectRatio = uiImage.size.width / uiImage.size.height
        
        // 基于宽度和比例计算高度
        var calculatedHeight = width / aspectRatio
        
        // 限制最小和最大高度
        calculatedHeight = min(max(calculatedHeight, 150.0), 280.0)
        
        // 根据内容类型调整高度 (可以根据图片名称或特征进行分类)
        if imageName.contains("landscape") || aspectRatio > 1.5 {
            // 横向风景图片
            calculatedHeight = min(calculatedHeight, 200.0)
        } else if imageName.contains("portrait") || aspectRatio < 0.7 {
            // 纵向人像图片
            calculatedHeight = min(calculatedHeight, 280.0)
        }
        
        return calculatedHeight
    }
    
    // 预先估计图片高度用于GeometryReader的框架
    private func estimatedImageHeight(for imageName: String) -> CGFloat {
        // 这里我们使用一个估算值，因为实际高度将在GeometryReader中计算
        // 在真实设备上，可以通过图片名称或图片本身的特性进行更智能的估算
        guard let uiImage = UIImage(named: imageName) else { 
            return 220.0 // 默认估算高度
        }
        
        let aspectRatio = uiImage.size.width / uiImage.size.height
        let screenWidth = UIScreen.main.bounds.width - 40 // 考虑边距
        let estimatedHeight = screenWidth / aspectRatio
        
        // 限制在合理范围内
        return min(max(estimatedHeight, 180.0), 300.0)
    }
    
    // 两张图片布局（小红书风格）
    private var twoImagesLayout: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let imageWidth = (totalWidth - 6) / 2 // 减去间距后平分宽度
            
            HStack(spacing: 6) {
                // 左侧图片
                Button(action: {
                    selectedImageIndex = 0
                    showImageViewer = true
                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                    feedbackGenerator.impactOccurred(intensity: 0.5)
                }) {
                    twoImageItem(post.images[0], width: imageWidth)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 右侧图片
                Button(action: {
                    selectedImageIndex = 1
                    showImageViewer = true
                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                    feedbackGenerator.impactOccurred(intensity: 0.5)
                }) {
                    twoImageItem(post.images[1], width: imageWidth)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(height: 200) // 固定高度更美观
    }
    
    // 两图布局的单个图片项
    private func twoImageItem(_ imageName: String, width: CGFloat) -> some View {
        Group {
            if imageName.contains("_image_") {
                // 用户上传的图片
                PostImageView(
                    imageId: imageName,
                    contentMode: .fill,
                    cornerRadius: 12 // 减小圆角
                )
                .frame(width: width, height: 150) // 从200减小到150
                .clipShape(RoundedRectangle(cornerRadius: 12)) // 确保内容被剪裁为圆角
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3) // 增强阴影效果
                .overlay(
                    RoundedRectangle(cornerRadius: 12) // 减小圆角
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
            } else if let uiImage = UIImage(named: imageName) {
                // 内置图片
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: 150) // 从200减小到150
                    .cornerRadius(12) // 减小圆角
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // 确保内容被剪裁为圆角
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3) // 增强阴影效果
                    .overlay(
                        RoundedRectangle(cornerRadius: 12) // 减小圆角
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .overlay(
                        // 仅在有描述时显示描述层
                        Group {
                            if let description = getImageDescription(for: imageName) {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Text(description)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(6)
                                            .padding(8)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                    )
                    } else {
                // 占位图
                generateMockImage(for: imageName)
                    .frame(width: width, height: 150) // 从200减小到150
                    .cornerRadius(12) // 减小圆角
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // 确保内容被剪裁为圆角
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3) // 增强阴影效果
                    .overlay(
                        RoundedRectangle(cornerRadius: 12) // 减小圆角
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            }
        }
    }
    
    // 三张图片布局（小红书风格）
    private var threeImagesLayout: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let smallImageWidth = (totalWidth * 0.33) - 3  // 右侧小图宽度
            let largeImageWidth = (totalWidth * 0.67) - 3  // 左侧大图宽度
            let smallImageHeight = (largeImageWidth / 2) - 3  // 右侧小图高度
            let largeImageHeight = largeImageWidth * 0.85  // 左侧大图高度（减小到原来的85%）
            
            HStack(spacing: 6) {
                // 左侧大图 - 保持比例并剪裁
                Button(action: {
                    selectedImageIndex = 0
                    showImageViewer = true
                    feedbackGenerator.impactOccurred(intensity: 0.5)
                }) {
                    wechatStyleImageItem(post.images[0], size: largeImageWidth)
                        .frame(width: largeImageWidth, height: largeImageHeight)
                }
                .buttonStyle(PlainButtonStyle())
                    .clipped()
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // 右侧两张小图垂直排列
                VStack(spacing: 6) {
                    Button(action: {
                        selectedImageIndex = 1
                        showImageViewer = true
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                    }) {
                        wechatStyleImageItem(post.images[1], size: smallImageWidth)
                            .frame(width: smallImageWidth, height: smallImageHeight)
                    }
                    .buttonStyle(PlainButtonStyle())
                        .clipped()
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Button(action: {
                        selectedImageIndex = 2
                        showImageViewer = true
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                    }) {
                        wechatStyleImageItem(post.images[2], size: smallImageWidth)
                            .frame(width: smallImageWidth, height: smallImageHeight)
                    }
                    .buttonStyle(PlainButtonStyle())
                        .clipped()
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: largeImageHeight)
        }
        .frame(height: getThreeImageLayoutHeight())
    }
    
    // 计算三张图片布局的高度 - 更精确计算
    private func getThreeImageLayoutHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40  // 考虑边距
        let largeImageWidth = (screenWidth * 0.67) - 3  // 左侧大图宽度
        return largeImageWidth * 0.85  // 减小到原来的85%
    }
    
    // 四张或更多图片布局（小红书风格）
    private var fourOrMoreImagesLayout: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let imageSize = (totalWidth - 6) / 2 // 两列布局，计算单个图片尺寸
            let imageHeight = imageSize * 0.85 // 减小高度至原来的85%，使图片更紧凑
            
            VStack(spacing: 6) {
                // 第一行
                HStack(spacing: 6) {
                    // 左上角图片
                    Button(action: {
                        selectedImageIndex = 0
                        showImageViewer = true
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                    }) {
                        gridImageItem(post.images[0], width: imageSize, height: imageHeight)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 右上角图片
                    Button(action: {
                        selectedImageIndex = 1
                        showImageViewer = true
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                    }) {
                        gridImageItem(post.images[1], width: imageSize, height: imageHeight)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 第二行
                HStack(spacing: 6) {
                    // 左下角图片
                    Button(action: {
                        selectedImageIndex = 2
                        showImageViewer = true
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                    }) {
                        gridImageItem(post.images[2], width: imageSize, height: imageHeight)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 右下角图片（如果有更多，显示+N）
                    Button(action: {
                        selectedImageIndex = 3
                        showImageViewer = true
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                    }) {
                    ZStack {
                            gridImageItem(post.images[3], width: imageSize, height: imageHeight)
                        
                        if post.images.count > 4 {
                            // 半透明蒙版
                                RoundedRectangle(cornerRadius: 12) // 减小圆角
                                    .fill(Color.black.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12)) // 确保蒙版也被剪裁为圆角
                            
                            // +N标识
                            VStack(spacing: 4) {
                                    Image(systemName: "photo.stack.fill")
                                        .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("+\(post.images.count - 4)")
                                        .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(height: getGridLayoutHeight())
    }
    
    // 计算网格布局的高度
    private func getGridLayoutHeight() -> CGFloat {
                let screenWidth = UIScreen.main.bounds.width - 40 // 考虑边距
        let imageSize = (screenWidth - 6) / 2 // 两列布局
        let imageHeight = imageSize * 0.85 // 减小高度至原来的85%
        return (imageHeight * 2) + 6 // 两行图片加上中间间距
    }
    
    // 网格布局的单个图片项
    private func gridImageItem(_ imageName: String, width: CGFloat, height: CGFloat) -> some View {
        Group {
            if imageName.contains("_image_") {
                // 用户上传的图片
                PostImageView(
                    imageId: imageName,
                    contentMode: .fill,
                    cornerRadius: 12 // 减小圆角
                )
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 12)) // 确保内容被剪裁为圆角
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3) // 增强阴影效果
            } else if let uiImage = UIImage(named: imageName) {
                // 内置图片
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .cornerRadius(12) // 减小圆角
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // 确保内容被剪裁为圆角
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3) // 增强阴影效果
                    } else {
                // 占位图
                generateMockImage(for: imageName)
                    .frame(width: width, height: height)
                    .cornerRadius(12) // 减小圆角
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // 确保内容被剪裁为圆角
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3) // 增强阴影效果
            }
        }
    }
    
    // 历史人物评论预览
    private var virtualCommentPreviewSection: some View {
        Group {
            if !post.comments.isEmpty && (displayMode == .preview || displayMode == .compact) && !isDetailView {
                // 简化版评论预览
                VStack(alignment: .leading, spacing: 8) {
                    // 评论统计信息
                    HStack {
                        // 移除评论数量显示，因为底部按钮区域已有显示
                        Spacer()
                
                        // 虚拟角色参与统计
                        // 🔧 修复：使用getTopLevelComments()统计虚拟角色，只计算顶级评论
                        let virtualCount = post.getTopLevelComments().filter { $0.isVirtualCharacter }.count
                        if virtualCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                    
                                Text("\(virtualCount)位历史人物参与")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                    .padding(.top, 4) // 添加顶部内边距使其更居中
                    .padding(.bottom, 0) // 将底部内边距从8减小到0
                    
                    // 获取一条精选评论
                    if let featuredComment = getFeaturedComment() {
                        HStack(alignment: .top, spacing: 8) {
                            // 用户头像 - 使用Avatar组件，并添加缓存和预加载机制
                            Avatar(
                                url: featuredComment.characterID ?? featuredComment.userAvatar,
                                name: featuredComment.username,
                                category: featuredComment.isVirtualCharacter ? CharacterAvatarService.shared.getCharacterCategoryTag(for: featuredComment.characterID ?? "") : "",
                                size: 30,
                                useCaching: true,
                                preloadPriority: .high
                            )
                                .frame(width: 30, height: 30)
                                .id("featuredAvatar_\(featuredComment.id.uuidString)")  // 添加固定ID防止重新渲染

                            VStack(alignment: .leading, spacing: 2) {
                                // 用户名和类型
                                HStack {
                                    Text(featuredComment.username)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    if featuredComment.isVirtualCharacter {
                                        Text(CharacterAvatarService.shared.getCharacterCategoryTag(for: featuredComment.characterID ?? ""))
                                            .font(.system(size: 10))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(CharacterAvatarService.shared.getCharacterTagColor(for: featuredComment.characterID ?? "").opacity(0.12))
                                            .foregroundColor(CharacterAvatarService.shared.getCharacterTagColor(for: featuredComment.characterID ?? ""))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                // 评论内容
                                Text(featuredComment.content)
                                    .font(.system(size: featuredComment.isVirtualCharacter ? 14.0 : 14, weight: featuredComment.isVirtualCharacter ? .regular : .regular))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.vertical, 4) // 增加垂直间距，使短评论看起来更美观
                                
                                // 添加点赞和回复信息
                                HStack(spacing: 8) {
                                    if featuredComment.likes > 0 {
                                        HStack(spacing: 2) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.red.opacity(0.8))
                                            
                                            Text("\(featuredComment.likes)")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if featuredComment.replies.count > 0 {
                                        HStack(spacing: 2) {
                                            Image(systemName: "bubble.left.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.blue.opacity(0.7))
                                            
                                            Text("\(featuredComment.replies.count)回复")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // 历史人物标识图标
                                    if featuredComment.isVirtualCharacter {
                                        HStack(spacing: 4) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 9))
                                                .foregroundColor(CharacterAvatarService.shared.getCharacterTagColor(for: featuredComment.characterID ?? ""))
                                            
                                            Text("历史人物")
                                                .font(.system(size: 10))
                                                .foregroundColor(CharacterAvatarService.shared.getCharacterTagColor(for: featuredComment.characterID ?? "").opacity(0.8))
                                        }
                                    } else {
                                        Text("点击查看更多")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary.opacity(0.7))
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(10)
                        .frame(minHeight: 90) // 设置最小高度确保短评论也有足够的高度
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignSystem.Colors.warmNestedBackground.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                        )
                    } else {
                        // 无精选评论时显示简单文本
                        VStack(spacing: 8) {
                            Text("\(post.comments.count)条评论")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            HStack {
                                Spacer()
                                
                                Text("点击参与讨论")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary.opacity(0.8))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        }
                        .frame(minHeight: 60) // 为无评论时设置最小高度
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignSystem.Colors.warmNestedBackground.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 0) // 减少垂直间距以消除额外空白
                .contentShape(Rectangle())
                .onTapGesture {
                    // 点击评论区跳转到详情页
                    onPostTap()
                }
            }
        }
        .padding(.top, 0) // 添加顶部0内边距以消除与图片区域之间的空白
    }
    
    // 获取精选评论 - 使用稳定的排序逻辑，避免头像闪烁
    private func getFeaturedComment() -> DetailedCommentModel? {
        // 使用getTopLevelComments()确保只显示真正的顶级评论
        let topLevelComments = post.getTopLevelComments()
        
        // 首先按照评论ID缓存精选评论，确保UI稳定性
        if let cachedCommentID = UserDefaults.standard.string(forKey: "FeaturedComment_\(post.id.uuidString)"),
           let cachedUUID = UUID(uuidString: cachedCommentID),
           let cachedComment = topLevelComments.first(where: { $0.id == cachedUUID }) {
            return cachedComment
        }
        
        // 稳定的排序逻辑：首先按照评论类型和回复数排序，然后按时间和ID排序
        let sortedComments = topLevelComments.sorted { comment1, comment2 in
            // 1. 优先级1：有回复的虚拟角色评论
            let c1HasReplies = comment1.isVirtualCharacter && !comment1.replies.isEmpty
            let c2HasReplies = comment2.isVirtualCharacter && !comment2.replies.isEmpty
            
            if c1HasReplies != c2HasReplies {
                return c1HasReplies
            }
            
            // 2. 优先级2：虚拟角色评论
            if comment1.isVirtualCharacter != comment2.isVirtualCharacter {
                return comment1.isVirtualCharacter
            }
            
            // 3. 优先级3：按发布时间排序（较早的优先）
            if comment1.datePosted != comment2.datePosted {
                return comment1.datePosted < comment2.datePosted
            }
            
            // 4. 最后按ID排序，确保完全稳定
            return comment1.id.uuidString < comment2.id.uuidString
        }
        
        // 保存选择的评论ID以确保稳定性
        if let selectedComment = sortedComments.first {
            UserDefaults.standard.set(selectedComment.id.uuidString, forKey: "FeaturedComment_\(post.id.uuidString)")
            return selectedComment
        }
        
        return nil
    }
    
    // 评论按钮区
    private func commentButtonSection(for comment: DetailedCommentModel) -> some View {
        HStack(spacing: 20) {
            // 点赞按钮
            Button(action: {
                feedbackGenerator.impactOccurred(intensity: 0.3)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 14.0))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Text("\(comment.likes)")
                        .font(.system(size: 13.0))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.95))
            
            // 回复按钮
            Button(action: {
                feedbackGenerator.impactOccurred(intensity: 0.3)
                onPostTap() // 点击后跳转到详情页
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 13.0))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Text("回复")
                        .font(.system(size: 13.0))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.95))
            
                        Spacer()
            
            // 精华标识
            if comment.likes > 30 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    
                    Text("精华")
                            .font(.system(size: 12))
                }
                .foregroundColor(Color.orange)
                    .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
    
    /**
     * 将时间转换为友好的文本格式
     */
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year >= 1 {
            return "\(year)年前"
        }
        
        if let month = components.month, month >= 1 {
            return "\(month)个月前"
        }
        
        if let week = components.weekOfYear, week >= 1 {
            return "\(week)周前"
        }
        
        if let day = components.day, day >= 1 {
            return "\(day)天前"
        }
        
        if let hour = components.hour, hour >= 1 {
            return "\(hour)小时前"
        }
        
        if let minute = components.minute, minute >= 1 {
            return "\(minute)分钟前"
        }
        
        return "刚刚"
    }
    
    // MARK: - 评论行子组件
    
    // 评论按钮区域
    private func buttonSection(for comment: DetailedCommentModel) -> some View {
        HStack(spacing: 20) { // 增加按钮间距
            // 点赞按钮
            Button(action: {
                // 触觉反馈
                feedbackGenerator.impactOccurred(intensity: 0.4)
                
                // 这里可以添加点赞逻辑
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "heart")
                        .font(.system(size: 14.0))
                
                    Text("\(comment.likes)")
                        .font(.system(size: 14.0))
            }
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 回复按钮
            Button(action: {
                // 触觉反馈
                feedbackGenerator.impactOccurred(intensity: 0.4)
                
                // 回复操作
                if let onCommentToggle = onCommentToggle {
                    onCommentToggle()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 14.0))
                    
                Text("回复")
                        .font(.system(size: 14.0))
                }
                .foregroundColor(DesignSystem.Colors.comment)
                .padding(.horizontal, 6.0)
                .padding(.vertical, 3.0)
                .background(
                    RoundedRectangle(cornerRadius: 6.0)
                        .fill(DesignSystem.Colors.comment.opacity(0.08))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 精华标识
            if comment.likes > 30 {
                featuredBadge
            }
            
            Spacer()
        }
        .padding(.top, 8.0) // 增加顶部间距
    }
    
    // 精华评论标识
    private var featuredBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 10.0))
            
            Text("精华")
                .font(.system(size: 12.0))
        }
        .foregroundColor(Color(hex: "D6B857")) // 调整为更柔和的金色
        .padding(.horizontal, 6.0)
        .padding(.vertical, 3.0)
        .background(Color(hex: "D6B857").opacity(0.1))
        .cornerRadius(8.0)
    }
    
    // 角色名言视图
    private func characterQuoteView(for characterID: String) -> some View {
        HStack {
            Spacer()
            
            Text(getCharacterQuote(for: characterID))
                .font(.system(size: 11.0).italic())
                .foregroundColor(getCharacterColor(for: characterID))
                .padding(.horizontal, 10.0)
                .padding(.vertical, 4.0)
                .background(getCharacterColor(for: characterID).opacity(0.05))
                .cornerRadius(10.0)
        }
        .padding(.top, 8.0)
        .padding(.trailing, 10.0)
    }
    
    // 获取角色经典名言
    private func getCharacterQuote(for characterID: String) -> String {
        switch characterID {
        case "einstein":
            return "想象力比知识更重要"
        case "shakespeare":
            return "生活如戏剧，我们皆为演员"
        case "davinci":
            return "艺术永不眠，科学永不止"
        case "confucius":
            return "学而不思则罔，思而不学则殆"
        case "curie":
            return "科学的路上没有平坦的大道"
        default:
            return "智慧穿越时空"
        }
    }
    
    // 评论背景
    private func commentBackground(for comment: DetailedCommentModel) -> some View {
        Group {
            if comment.isVirtualCharacter {
                getCharacterColor(for: comment.characterID ?? "").opacity(0.03)
                    } else {
                DesignSystem.Colors.secondaryBackground // 使用设计系统定义的嵌套背景色
            }
        }
    }
    
    // 评论左侧边框
    private func commentLeftBorder(for comment: DetailedCommentModel) -> some View {
        Group {
            if comment.isVirtualCharacter {
                HStack {
                    Rectangle()
                        .fill(getCharacterColor(for: comment.characterID ?? "").opacity(0.5))
                        .frame(width: 2.0)
                        .padding(.vertical, 6.0)
                    Spacer()
                }
            } else {
                Color.clear.frame(width: 0.0, height: 0.0)
            }
        }
    }
    
    // 评论边框
    private func commentBorder(for comment: DetailedCommentModel) -> some View {
        RoundedRectangle(cornerRadius: 12.0)
            .stroke(
                comment.isVirtualCharacter ?
                getCharacterColor(for: comment.characterID ?? "").opacity(0.1) :
                Color.gray.opacity(0.1),
                lineWidth: 0.5
            )
    }
    
    // 图片查看器
    private var imageViewerSheet: some View {
        // 使用新的微信风格图片查看器
        WeChatStyleImageViewer(
            images: post.images,
            initialIndex: selectedImageIndex,
            isPresented: $showImageViewer
        )
    }
    
    // MARK: - 辅助函数
    
    // 格式化日期为相对时间
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // 切换点赞状态
    private func toggleLike() {
        // 添加按钮按下效果
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            isTapped = true
        }
        
        // 还原按钮状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                isTapped = false
            }
        }
        
        // 使用全局点赞状态管理器
        let newLikedState = LikeStateManager.shared.toggleLike(post.id.uuidString)
        isLiked = newLikedState
        
        // 触觉反馈
        feedbackGenerator.impactOccurred(intensity: 0.4)
        
        // 发送通知给UserLikeService记录点赞行为
        let updatedPost = post.toggleLike(isLiked: newLikedState)
        NotificationCenter.default.post(
            name: NSNotification.Name("PostLiked"),
            object: nil,
            userInfo: [
                "post": updatedPost,
                "isLiked": newLikedState
            ]
        )
        
        // 回调（如果有的话）
        if let onLikeToggle = onLikeToggle {
            onLikeToggle(newLikedState)
        }
    }
    
    // 切换评论显示状态
    private func toggleComments() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showComments.toggle()
        }
        
        // 如果是打开评论区，加载评论数据
        if showComments {
            // 🔧 修复：使用guard let安全处理commentLoader
            guard let loader = commentLoader else { return }
            
            // 如果是首次加载或者评论为空，触发加载
            if loader.loadedComments.isEmpty {
                // 加载评论数据
                loader.loadComments(forPostID: post.id.uuidString, resetPagination: true)
            }
        }
    }
    
    // 切换收藏状态
    private func toggleBookmark() {
        isBookmarked.toggle()
        
        // 触觉反馈
        feedbackGenerator.impactOccurred(intensity: 0.5)
        
        // 回调
        if let onBookmarkToggle = onBookmarkToggle {
            onBookmarkToggle(isBookmarked)
        }
    }
    
    // 拆分复杂表达式 - 修复第623行的问题
    // 单独定义评论行子组件
    private func CommentRow(comment: DetailedCommentModel, onReply: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                // 用户头像
                avatarView(for: comment)
                
                VStack(alignment: .leading, spacing: 2) {
                    // 用户名和标签
                    HStack(spacing: 6) {
                        Text(comment.username)
                            .font(.system(size: 15.0, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        if comment.characterID != nil {
                            Text(CharacterAvatarService.shared.getCharacterCategoryTag(for: comment.characterID ?? ""))
                                .font(.system(size: 12.0, weight: .regular))
                                .padding(.horizontal, 6.0)
                                .padding(.vertical, 2.0)
                                .background(CharacterAvatarService.shared.getCharacterTagColor(for: comment.characterID ?? "").opacity(0.1))
                                .foregroundColor(CharacterAvatarService.shared.getCharacterTagColor(for: comment.characterID ?? ""))
                                .cornerRadius(6.0)
                        }
                    }
                    
                    // 时间指示
                    Text("2小时前")
                        .font(.system(size: 12.0, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                
                Spacer()
            }
            
            // 评论内容
            Text(comment.content)
                .font(.system(size: 15.0))
                .foregroundColor(.primary)
                .lineSpacing(4.0)
                .fixedSize(horizontal: false, vertical: true)
            
            // 修复第623行的问题，将复杂表达式拆分
            buttonSection(for: comment)
        }
        .padding(12.0)
        .background(getCommentBackground(for: comment))
        .cornerRadius(12.0)
        .overlay(getCommentLeftBorder(for: comment))
        .onTapGesture {
            onReply()
        }
    }
    
    // 修复从第721行开始的错误，将它们移入正确的上下文
    // 获取评论背景色
    private func getCommentBackground(for comment: DetailedCommentModel) -> some View {
        Group {
            if comment.isVirtualCharacter {
                getCharacterColor(for: comment.characterID ?? "").opacity(0.03)
            } else {
                DesignSystem.Colors.secondaryBackground // 使用设计系统定义的嵌套背景色
            }
        }
    }
    
    // 获取评论左侧边框
    private func getCommentLeftBorder(for comment: DetailedCommentModel) -> some View {
        Group {
            if comment.isVirtualCharacter {
                HStack {
                    Rectangle()
                        .fill(getCharacterColor(for: comment.characterID ?? "").opacity(0.5))
                        .frame(width: 2.0)
                        .padding(.vertical, 6.0)
                    Spacer()
                }
            } else {
                Color.clear.frame(width: 0.0, height: 0.0)
            }
        }
    }
    
    // 获取评论边框
    private func getCommentBorder(for comment: DetailedCommentModel) -> some View {
        RoundedRectangle(cornerRadius: 12.0)
            .stroke(
                comment.isVirtualCharacter ?
                getCharacterColor(for: comment.characterID ?? "").opacity(0.1) :
                Color.gray.opacity(0.1),
                lineWidth: 0.5
            )
    }
    
    // 获取角色颜色
    private func getCharacterColor(for characterID: String) -> Color {
        switch characterID.lowercased() {
        case "einstein": return Color(hex: "5B7AC9") // 软蓝色
        case "shakespeare": return Color(hex: "8C699E") // 主紫色
        case "davinci": return Color(hex: "5C9A73") // 柔和绿色
        case "confucius": return Color(hex: "A77C4D") // 温暖棕色
        case "curie": return Color(hex: "C25B7A") // 柔和粉色
        case "libai": return Color(hex: "D07C3C") // 温暖橙色
        case "newton": return Color(hex: "B94D3F") // 柔和红色
        case "goku", "naruto": return Color(hex: "E78B30") // 鲜亮橙色
        case "holmes": return Color(hex: "546E97") // 深蓝色
        default: return DesignSystem.Colors.primary
        }
    }
    
    // 获取角色类别标签 - 统一使用CharacterAvatarService
    private func getCharacterCategory(for characterID: String) -> String {
        return CharacterAvatarService.shared.getCharacterCategoryTag(for: characterID)
    }
    
    // 用户头像视图
    private func avatarView(for comment: DetailedCommentModel) -> some View {
        // 使用统一的Avatar组件，确保头像降级处理一致
        Avatar(
            url: comment.characterID ?? comment.userAvatar,
              name: comment.username,
            category: comment.isVirtualCharacter ? CharacterAvatarService.shared.getCharacterCategoryTag(for: comment.characterID ?? "") : "",
            size: 40
            )
            .onAppear {
                if comment.isVirtualCharacter {
                print("📱 PostCardView - 评论头像 - 角色ID: \(comment.characterID ?? "nil"), 头像路径: \(comment.userAvatar), 用户名: \(comment.username)")
                
                // 检查图片是否存在
                if let characterID = comment.characterID {
                    let avatarService = CharacterAvatarService.shared
                    let exists = avatarService.checkImageExistence(imageName: characterID)
                    print("🔍 PostCardView - 角色头像检查 - \(characterID): \(exists ? "存在" : "不存在")")
                    
                    // 如果不存在，确认会降级到字母头像
                    if !exists {
                        print("⚠️ PostCardView - 角色头像不存在，将使用字母头像 - 角色: \(characterID), 名称: \(comment.username)")
                    }
                }
                }
            }
    }
    
    // MARK: - 视图组件

    // 操作按钮区域
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // 点赞按钮
            Button(action: toggleLike) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 16.0))  // 从18.0减小到16.0
                        .foregroundColor(isLiked ? DesignSystem.Colors.like : .gray)
                    
                    Text("\(post.likes)")
                        .font(.system(size: 13.0))  // 从14.0减小到13.0
                        .foregroundColor(isLiked ? DesignSystem.Colors.like : .gray)
                }
                .scaleEffect(isTapped ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTapped)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 评论按钮
            Button(action: {
                withAnimation {
                    showComments.toggle()
                }
                // 触觉反馈
                feedbackGenerator.impactOccurred(intensity: 0.5)
                
                // 回调
                if let onCommentToggle = onCommentToggle {
                    onCommentToggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 16.0))  // 从18.0减小到16.0
                        .foregroundColor(.gray)
                    
                    Text("\(post.comments.count)")
                        .font(.system(size: 13.0))  // 从14.0减小到13.0
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)  // 从3减小到2，使整体更紧凑
                .background(showComments ? DesignSystem.Colors.comment.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 分享按钮
            Button(action: {
                isSharePresented = true
                feedbackGenerator.impactOccurred(intensity: 0.5)
                
                if let onShare = onShare {
                    onShare()
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16.0))  // 从18.0减小到16.0
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 4.0)
        .padding(.vertical, 5.0)  // 从6.0减小到5.0，减少垂直间距
    }
    
    // 完整评论区域
    private var populatedCommentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 🔧 修复：使用if let安全处理commentLoader
            if let loader = commentLoader {
                // 评论区标题
                HStack {
                    Text("评论")
                        .font(.headline)
                    
                    Spacer()
                    
                    if loader.hasMoreComments {
                        Button(action: {
                            loader.loadNextPage()
                            feedbackGenerator.impactOccurred(intensity: 0.3)
                        }) {
                            Text("加载更多")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(loader.isLoading)
                    }
                }
                .padding(.top, 8)
                
                // 加载状态
                if loader.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // 无评论状态
                else if loader.loadedComments.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.bottom, 4)
                        
                        Text("暂无评论")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("成为第一个评论的人")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                
                // 评论列表
                else {
                    ForEach(loader.loadedComments) { comment in
                        VStack(spacing: 0) {
                            CommentRow(
                                comment: comment,
                                onReply: {
                                    replyingTo = comment
                                    feedbackGenerator.impactOccurred(intensity: 0.4)
                                }
                            )
                            .padding(.vertical, 6)
                            
                            if comment.id != loader.loadedComments.last?.id {
                                Divider().padding(.leading, 40)
                            }
                        }
                    }
                }
                
                // 加载更多按钮
                if loader.hasMoreComments && !loader.loadedComments.isEmpty {
                    Button(action: {
                        loader.loadNextPage()
                        feedbackGenerator.impactOccurred(intensity: 0.3)
                    }) {
                        HStack {
                            Text("查看更多评论")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.primary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(loader.isLoading)
                }
            } else {
                // 评论加载中状态
                VStack {
                    Text("评论加载中...")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // 评论输入区域 - 优化体验
    private var commentInputSection: some View {
        VStack(spacing: 0) {
            // 回复信息显示
            if let replying = replyingTo {
                HStack {
                    Text("回复：")
                        .font(.system(size: 12.0))
                        .foregroundColor(.secondary)
                    
                    Text(replying.username)
                        .font(.system(size: 12.0, weight: .medium))
                        .foregroundColor(replying.isVirtualCharacter ? 
                                        getCharacterColor(for: replying.characterID ?? "") : .primary)
                    
            Spacer()
            
                    Button(action: {
                        // 取消回复
                        withAnimation(.easeInOut(duration: 0.2)) {
                            replyingTo = nil
                        }
                        feedbackGenerator.impactOccurred(intensity: 0.3)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14.0))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12.0)
                .padding(.vertical, 8.0)
                .background(Color(.systemGray6))
                .cornerRadius(8.0)
                .padding(.bottom, 8.0)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                // 用户头像
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24.0))
                    .foregroundColor(.gray)
                
                // 自动增高的文本输入框
                ZStack(alignment: .leading) {
                    // 占位文本
                    if commentText.isEmpty {
                        Text(replyingTo == nil ? "跨越时空的对话..." : "回复 \(replyingTo?.username ?? "") 的对话...")
                            .font(.system(size: 14.0))
                            .foregroundColor(.gray)
                            .padding(.leading, 8.0)
                            .padding(.top, 8.0)
                    }
                    
                    // 评论输入框
                    TextEditor(text: $commentText)
                        .font(.system(size: 14.0))
                        .foregroundColor(.primary)
                        .frame(minHeight: 36.0, maxHeight: 120.0)
                        .padding(4.0)
                        .background(Color.clear)
                        .cornerRadius(8.0)
                        .onTapGesture {
                            // 当用户点击输入框时，触发反馈
                            isFocusedOnComment = true
                            feedbackGenerator.impactOccurred(intensity: 0.3)
                        }
                }
                .padding(.vertical, 4.0)
                .padding(.horizontal, 8.0)
                .background(Color(.systemGray6))
                .cornerRadius(18.0)
                
                // 发送按钮 - 优化状态和交互
                Button(action: {
                    submitComment()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32.0))
                        .foregroundColor(!commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .scaleEffect(isCommentSubmitting ? 0.8 : 1.0)
                .opacity(isCommentSubmitting ? 0.7 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCommentSubmitting)
            }
            .padding(.vertical, 8.0)
            .background(Color(.systemBackground))
        }
    }
    
    // 提交评论的方法 - 优化交互流程
    private func submitComment() {
        // 检查是否有内容
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty { return }
        
        // 触觉反馈
        feedbackGenerator.impactOccurred(intensity: 0.6)
        
        // 设置提交状态
        isCommentSubmitting = true
        
        // 模拟网络提交
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 处理回复逻辑
            if let replyingToComment = replyingTo {
                // 如果是回复评论，使用回调
                onAddComment?(post, trimmedText, replyingToComment.id.uuidString)
                
                // 不需要重新初始化评论加载器，因为这会清空已加载的评论
                // 回调函数会处理数据更新，评论加载器会自动反映变化
                    } else {
                // 如果是新评论
                let newComment = DetailedCommentModel(
                    username: UserProfileManager.shared.getCurrentUsername(),
                    userAvatar: UserProfileManager.shared.getCurrentAvatarURL(),
                    content: trimmedText,
                    datePosted: Date(),
                    isVirtualCharacter: false,
                    characterID: nil,
                    likes: 0
                )
                
                // 添加到评论列表
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // 🔧 修复：使用guard let安全处理commentLoader
                    guard let loader = commentLoader else { return }
                    loader.addComment(newComment)
                    
                    // 使用回调而不是直接访问viewModel
                    onAddComment?(post, trimmedText, nil)
                }
            }
            
            // 重置状态
            commentText = ""
            isCommentSubmitting = false
            replyingTo = nil
            
            // 提交成功的振动反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // 添加统一的角色标签视图
    private func characterTagView(for characterID: String) -> some View {
        Text(getCharacterCategory(for: characterID))
            .font(.system(size: 12.0, weight: .regular))
            .padding(.horizontal, 8.0)  // 统一水平内边距
            .padding(.vertical, 4.0)    // 统一垂直内边距
            .background(getCharacterColor(for: characterID).opacity(0.1))
            .foregroundColor(getCharacterColor(for: characterID))
            .cornerRadius(6.0)          // 统一圆角大小
    }
    
    // 用户标签视图 - 与角色标签保持一致的风格
    private func userTagView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12.0, weight: .regular))
            .padding(.horizontal, 8.0)  // 统一水平内边距
            .padding(.vertical, 4.0)    // 统一垂直内边距
            .background(DesignSystem.Colors.primary.opacity(0.1))
            .foregroundColor(DesignSystem.Colors.primary)
            .cornerRadius(6.0)          // 统一圆角大小
    }
    
    /**
     * 根据图片名称获取描述
     * @param imageName 图片名称
     * @return 图片描述
     */
    private func getImageDescription(for imageName: String) -> String? {
        // 使用ModelData中的样本图片描述
        return ModelData.sampleImages[imageName]
    }
    
    // 处理不喜欢角色的逻辑
    private func dislikeCharacter() {
        // 确保只能对AI生成的帖子执行此操作
        guard postSource == .aiGenerated else {
            ToastManager.shared.showToast(message: "此功能仅适用于AI生成的内容")
            return
        }
        
        // 给予触感反馈
        feedbackGenerator.impactOccurred(intensity: 0.6)
        
        // 获取当前帖子的角色ID（优先使用characterID，如果不存在则使用username）
        let characterID = post.characterID ?? post.username
        
        // 调用角色轮换系统来标记不喜欢的角色
        CharacterRotationSystem.shared.dislikeCharacter(characterID)
        
        // 显示确认提示
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 显示Toast提示
        ToastManager.shared.showToast(message: "已减少推荐\"\(post.username)\"")
        
        // 获取内容类型并调用ContentTypeWeightManager减少权重
        if let contentTypeString = post.contentType,
           let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) {
            ContentTypeWeightManager.shared.reduceContentType(contentType)
            ToastManager.shared.showToast(message: "已减少\"\(contentTypeString)\"类型内容")
        } else {
            ToastManager.shared.showToast(message: "无法识别内容类型")
        }
    }
}

// MARK: - 预览
struct PostCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // AI生成的帖子预览
            PostCardView(post: ModelData.samplePosts[0], postSource: .aiGenerated)
                .previewDisplayName("AI生成帖子")
            
            // 用户自己生成的帖子预览
            PostCardView(post: ModelData.samplePosts[1], isOwnPost: true, postSource: .userGenerated)
                .previewDisplayName("用户生成帖子")
        }
    }
}

// MARK: - 可缩放图片视图
struct ZoomableImageView: View {
    let image: String
    let description: String?
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDescriptionVisible: Bool = true
    
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1), 4)
                
                // 缩放时隐藏描述
                if scale > 1.1 {
                    withAnimation {
                        isDescriptionVisible = false
                    }
                }
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.1 {
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                        isDescriptionVisible = true
                    }
                }
            }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let newOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = newOffset
            }
            .onEnded { _ in
                lastOffset = offset
                if scale < 1.1 {
                    withAnimation {
                        offset = .zero
                    }
                }
            }
    }
    
    var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    if scale > 1.0 {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                        isDescriptionVisible = true
                            } else {
                        scale = 2.0
                        isDescriptionVisible = false
                    }
                }
                
                // 添加触感反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // 图片展示
                if let uiImage = UIImage(named: image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                                } else {
                    // 如果图片不存在，显示优化的占位符
                                ZStack {
                        Color.gray.opacity(0.1)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            
                            Text("图片加载失败")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // 图片描述 - 仅在有描述且描述可见时显示
                if let description = description, !description.isEmpty, isDescriptionVisible, scale <= 1.1 {
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
            .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
            }
        }
        .gesture(SimultaneousGesture(magnificationGesture, dragGesture))
        .gesture(doubleTapGesture)
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - 帖子选项按钮 (使用原生Popover)

// 添加重置内容类型权重的方法到ContentTypeWeightManager类中
extension ContentTypeWeightManager {
    func resetContentType(_ type: ContentGeneratorService.ContentType) {
        // 重置权重为1.0（100%）
        setWeight(1.0, for: type)
    }
}

// 添加View扩展，实现if16Available方法
extension View {
    @ViewBuilder
    func if16Available<Content: View>(_ transform: (Self) -> Content) -> some View {
        if #available(iOS 16.0, *) {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func shadowVisibility(_ visibility: Visibility) -> some View {
        if #available(iOS 16.0, *) {
            self.shadow(color: .clear, radius: 0)
        } else {
            self
        }
    }
}

// 添加HapticFeedbackManager扩展，实现lightTap方法
extension HapticFeedbackManager {
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.3)
    }
}

