import SwiftUI
import Foundation
import UIKit
import Combine

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
        print("🏗️ CommentLoader: 初始化")
        setupNotifications()
    }
    
    deinit {
        print("🗑️ CommentLoader: 清理资源")
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
        
        print("📡 CommentLoader: 已注册PostCommentsUpdated和CharacterReplyGenerated通知监听")
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
        
        print("🔕 CommentLoader: 已移除所有通知监听")
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
            print("⚠️ CommentLoader: 收到评论更新通知，但缺少有效的帖子ID")
            return
        }
        
        print("📣 CommentLoader: 收到评论更新通知，帖子ID: \(postIDString)")
        
        // 检查是否与当前加载的帖子匹配
        if let currentID = currentPostID, currentID == postID {
            print("✅ CommentLoader: 帖子ID匹配当前加载的帖子，即将刷新评论")
            
            // 在主线程执行UI更新
            DispatchQueue.main.async {
                self.refreshComments()
            }
        } else {
            print("ℹ️ CommentLoader: 评论更新通知与当前加载的帖子不匹配")
            print("  当前帖子ID: \(self.currentPostID?.uuidString ?? "nil")")
            print("  通知帖子ID: \(postIDString)")
        }
    }
    
    // 处理角色回复生成完成的通知
    @objc private func handleCharacterReplyGenerated(_ notification: Notification) {
        // 提取通知中的帖子ID和回复内容
        guard let userInfo = notification.userInfo,
              let postID = userInfo["postID"] as? String,
              let characterID = userInfo["characterID"] as? String,
              let replyContent = userInfo["reply"] as? String else {
            print("⚠️ CommentLoader: 收到角色回复生成通知，但缺少必要信息")
            return
        }
        
        print("📣 CommentLoader: 收到角色回复生成通知 - 帖子ID: \(postID), 角色ID: \(characterID)")
        print("💬 回复内容: \"\(String(replyContent.prefix(50)))...\"")
        
        // 检查是否与当前加载的帖子匹配
        if let currentID = currentPostID, currentID.uuidString == postID {
            print("✅ CommentLoader: 帖子ID匹配当前加载的帖子，添加角色回复")
            
            // 在主线程执行UI更新
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 创建虚拟角色评论对象
                let comment = DetailedCommentModel(
                    username: self.getCharacterName(for: characterID),
                    userAvatar: self.getCharacterAvatar(for: characterID),
                    content: replyContent,
                    datePosted: Date(),
                    isVirtualCharacter: true,
                    characterID: characterID,
                    likes: 0
                )
                
                // 添加到评论列表
                self.addComment(comment)
                
                print("✅ CommentLoader: 角色回复已添加到评论列表")
            }
        } else {
            print("ℹ️ CommentLoader: 角色回复通知与当前加载的帖子不匹配")
            print("  当前帖子ID: \(self.currentPostID?.uuidString ?? "nil")")
            print("  通知帖子ID: \(postID)")
        }
    }
    
    // 刷新评论内容
    func refreshComments() {
        print("🔄 CommentLoader: 开始刷新评论...")
        
        // 取消正在进行的加载任务
        loadingTask?.cancel()
        
        // 重置加载状态
        currentPage = 1
        loadedComments = []
        isLoading = true
        
        // 创建刷新任务
        loadingTask = Task { @MainActor in
            // 检查任务是否被取消
            if Task.isCancelled {
                print("❌ CommentLoader: 刷新任务被取消")
                return
            }
            
            do {
                // 短暂延迟，避免UI抖动
                print("⏳ CommentLoader: 短暂延迟以避免UI抖动...")
                try await Task.sleep(nanoseconds: 200_000_000)
                
                // 检查任务是否被取消
                if Task.isCancelled {
                    print("❌ CommentLoader: 延迟后任务被取消")
                    return
                }
                
                // 检查我们是否有评论可以加载
                if allComments.isEmpty {
                    print("ℹ️ CommentLoader: 无评论可加载，帖子评论列表为空")
                    self.loadedComments = []
                    self.hasMoreComments = false
                    self.isLoading = false
                    return
                }
                
                // 重新加载评论
                let preloadCount = min(5, self.allComments.count)
                let preloadedComments = Array(self.allComments.prefix(preloadCount))
                
                self.loadedComments = preloadedComments
                self.currentPage = 1
                self.hasMoreComments = preloadCount < self.allComments.count
                self.isPreloaded = true
                self.isLoading = false
                
                // 打印刷新后的评论信息
                print("✅ CommentLoader: 评论列表已刷新，共加载\(preloadedComments.count)条评论")
                print("📊 CommentLoader: 当前评论总数: \(self.allComments.count), 已加载: \(self.loadedComments.count)")
                
                // 打印评论内容日志
                if !self.loadedComments.isEmpty {
                    print("📝 CommentLoader: 已加载评论预览:")
                    for (index, comment) in self.loadedComments.enumerated() {
                        let isVirtual = comment.isVirtualCharacter ? "虚拟角色" : "用户"
                        print("  \(index+1). [\(isVirtual)] \(comment.username): \(comment.content.prefix(20))...")
                    }
                }
            } catch {
                // 错误处理
                if error is CancellationError {
                    print("❌ CommentLoader: 刷新任务被取消")
                } else {
                    print("⚠️ CommentLoader: 刷新评论时发生错误 - \(error.localizedDescription)")
                    self.errorMessage = "加载评论时出错: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // 初始化加载器
    func initialize(with comments: [DetailedCommentModel], postID: UUID? = nil) {
        print("🚀 CommentLoader: 初始化评论加载器...")
        
        // 记录当前帖子ID
        if let id = postID {
            print("🔑 CommentLoader: 设置帖子ID: \(id)")
            self.currentPostID = id
        } else {
            print("⚠️ CommentLoader: 警告 - 未提供帖子ID")
            self.currentPostID = nil
        }
        
        self.allComments = comments
        self.loadedComments = []
        self.currentPage = 1
        self.hasMoreComments = !comments.isEmpty
        self.isInitialized = true
        self.errorMessage = nil
        
        // 记录评论数量信息
        print("📊 CommentLoader: 初始化了 \(comments.count) 条评论")
        
        // 如果有虚拟角色评论，单独记录
        let virtualComments = comments.filter { $0.isVirtualCharacter }
        if !virtualComments.isEmpty {
            print("🤖 CommentLoader: 包含 \(virtualComments.count) 条虚拟角色评论")
        }
        
        // 自动预加载评论
        if !comments.isEmpty {
            print("⏳ CommentLoader: 即将预加载初始评论...")
            preloadFirstComments()
        } else {
            print("ℹ️ CommentLoader: 无评论可预加载")
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
        
        // 避免重复加载
        guard !isPreloaded && !isLoading else { return }
        
        isLoading = true
        
        // 创建新任务
        loadingTask = Task { @MainActor in
            // 检查任务是否被取消
            if Task.isCancelled { return }
            
            do {
                // 模拟网络延迟
                try await Task.sleep(nanoseconds: 100_000_000)
                
                // 检查任务是否被取消
                if Task.isCancelled { return }
                
                let preloadCount = min(3, self.allComments.count)
                let preloadedComments = Array(self.allComments.prefix(preloadCount))
                
                self.loadedComments = preloadedComments
                self.currentPage = 1
                self.hasMoreComments = preloadCount < self.allComments.count
                self.isPreloaded = true
                self.isLoading = false
            } catch {
                // 错误处理
                if !(error is CancellationError) {
                    self.errorMessage = "加载评论时出错"
                    self.isLoading = false
                }
            }
        }
    }
    
    // 加载下一页评论 - 批次加载避免UI阻塞，优化性能
    func loadNextPage() {
        // 避免重复加载
        guard !isLoading && hasMoreComments else { return }
        
        // 取消之前的任务
        loadingTask?.cancel()
        
        isLoading = true
        errorMessage = nil
        
        // 创建新任务
        loadingTask = Task { @MainActor in
            // 检查任务是否被取消
            if Task.isCancelled { return }
            
            do {
                // 先设置加载状态，让UI有反馈
                isLoading = true
                
                // 提供触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // 延迟执行实际加载，避免UI卡顿
                try await Task.sleep(nanoseconds: 100_000_000) // 100毫秒
                
                // 检查任务是否被取消
                if Task.isCancelled { 
                    isLoading = false
                    return 
                }
                
                // 减少每页加载的评论数量
                let pageSize = 2  // 原来是3，减少到2
                let startIndex = self.currentPage * pageSize
                let endIndex = min(startIndex + pageSize, self.allComments.count)
                
                // 安全检查
                guard startIndex < self.allComments.count else {
                    self.hasMoreComments = false
                    self.isLoading = false
                    return
                }
                
                // 安全获取评论片段
                let safeEndIndex = min(endIndex, self.allComments.count)
                let newComments = Array(self.allComments[startIndex..<safeEndIndex])
                
                // 不使用分批加载和动画，直接添加所有评论
                self.loadedComments.append(contentsOf: newComments)
                
                // 更新状态
                self.currentPage += 1
                self.hasMoreComments = endIndex < self.allComments.count
                self.isLoading = false
            } catch {
                // 错误处理
                if !(error is CancellationError) {
                    self.errorMessage = "加载评论时出错"
                    self.isLoading = false
                }
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
        
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + (isInitialLoad ? 0.5 : 0.8)) {
            // 使用虚拟数据（实际应用中应当从API获取）
            var newComments: [DetailedCommentModel] = []
            
            // 内容量基于分页加载
            let start = (self.currentPage - 1) * self.pageSize
            let end = min(start + self.pageSize, ModelData.sampleComments.count)
            
            if start < ModelData.sampleComments.count {
                for i in start..<end {
                    if i < ModelData.sampleComments.count {
                        let comment = ModelData.sampleComments[i]
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
                self.hasMoreComments = end < ModelData.sampleComments.count
                self.currentPage += 1
                self.isInitialLoad = false
            }
            
            self.isLoading = false
        }
    }
    
    // 模拟添加评论
    func addComment(_ comment: DetailedCommentModel) {
        print("➕ CommentLoader: 添加新评论...")
        
        // 添加到所有评论列表
        allComments.insert(comment, at: 0)
        
        // 添加到已加载的评论列表（确保显示在最前面）
        loadedComments.insert(comment, at: 0)
        
        // 更新分页状态
        hasMoreComments = allComments.count > loadedComments.count
        
        // 打印添加的评论信息
        let commentType = comment.isVirtualCharacter ? "虚拟角色评论" : "用户评论"
        let characterInfo = comment.isVirtualCharacter ? "(角色ID: \(comment.characterID ?? "未知"))" : ""
        print("✅ CommentLoader: 新\(commentType)已添加\(characterInfo)")
        print("📝 评论内容: \(comment.content)")
        print("👤 评论者: \(comment.username)")
        print("📊 CommentLoader: 当前评论总数: \(allComments.count), 已加载: \(loadedComments.count)")
        
        // 如果有帖子ID，发送通知以更新其他可能显示此帖子的视图
        if let postID = currentPostID {
            print("📣 CommentLoader: 发送评论更新通知，帖子ID: \(postID)")
            
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
    
    // 评论加载器
    @StateObject private var commentLoader = CommentLoader()
    
    // 触觉反馈
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // 交互状态
    @State private var isTapped: Bool = false
    
    // 回调函数
    var onPostTap: () -> Void = {}
    var onLikeToggle: ((Bool) -> Void)? = nil
    var onCommentToggle: (() -> Void)? = nil
    var onBookmarkToggle: ((Bool) -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onAddComment: ((UserPostModel, String, String?) -> Void)? = nil  // 修改：UUID改为String类型
    
    // 配置参数
    var showUserInfo: Bool = true
    var maxPreviewLines: Int = 5  // 默认显示5行，适合中等长度内容
    var maxPreviewLength: Int = 250  // 增加默认阈值从100到250字符，让中等长度内容也完整显示
    var showActions: Bool = true
    var showCommentSection: Bool = true
    var fullWidthImages: Bool = false
    var isDetailView: Bool = false
    
    // 新增：显示模式枚举
    enum DisplayMode {
        case preview   // 简化版，用于首页列表
        case detail    // 完整版，用于详情页
        case compact   // 紧凑版，用于主页列表
    }
    
    // 显示模式，默认为预览模式
    var displayMode: DisplayMode = .preview
    
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
        // 假设每行平均字符数(中文约15-20字，英文35-40字)
        let chineseCharsPerLine = 18
        let englishCharsPerLine = 40
        
        // 估算中文字符数
        var chineseCharCount = 0
        for char in text {
            if String(char).unicodeScalars.contains(where: { 
                // 基本汉字范围
                ($0.value >= 0x4E00 && $0.value <= 0x9FFF) ||
                // 扩展汉字范围
                ($0.value >= 0x3400 && $0.value <= 0x4DBF)
            }) {
                chineseCharCount += 1
            }
        }
        
        // 估算英文字符数(包括标点符号和空格)
        let englishCharCount = text.count - chineseCharCount
        
        // 综合计算估计行数
        let estimatedChineseLines = Double(chineseCharCount) / Double(chineseCharsPerLine)
        let estimatedEnglishLines = Double(englishCharCount) / Double(englishCharsPerLine)
        
        return max(1, Int(ceil(estimatedChineseLines + estimatedEnglishLines)))
    }
    
    // 新增：评论预览获取逻辑
    private var previewComments: [DetailedCommentModel] {
        // 只在预览模式下限制评论数量
        if displayMode == .preview {
            // 获取一条历史人物的评论
            let virtualComments = post.comments.filter { $0.isVirtualCharacter }.prefix(1)
            
            // 获取一条高赞评论
            let featuredComments = post.comments
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
        maxPreviewLines: Int = 5,  // 默认显示5行，适合中等长度内容
        maxPreviewLength: Int = 250,  // 增加默认阈值从100到250字符，让中等长度内容也完整显示
        showActions: Bool = true,
        showCommentSection: Bool = true,
        fullWidthImages: Bool = false,
        isDetailView: Bool = false,
        displayMode: DisplayMode = .preview
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
        
        // 初始化状态
        _isLiked = State(initialValue: post.isLikedByCurrentUser)
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
                    .padding(.top, -4) // 负值内边距，减少与图片区域之间的间距
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
        .padding(DesignSystem.Spacing.m)
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
        .padding(.vertical, 10.0)
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
            // 初始化评论加载器
            commentLoader.initialize(with: post.comments, postID: post.id)
            
            // 只在详情模式下预加载评论
            if displayMode == .detail && showCommentSection {
                commentLoader.loadNextPage()
            }
            
            // 准备触觉反馈
            feedbackGenerator.prepare()
        }
        .sheet(isPresented: $showImageViewer) {
            imageViewerSheet
        }
    }
    
    // MARK: - 子视图组件
    
    // 用户信息区域
    private var userInfoSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // 用户头像 - 使用 Avatar 组件，支持系统符号
            Avatar(url: post.userAvatar, size: 46.0)
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.divider, lineWidth: 0.5)
                )
            
            // 用户信息 - 更紧凑的布局
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // 用户名 - 增加字体粗细区分
                    Text(post.username)
                        .font(.system(size: 16.0, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    // 用户标签 - 统一标签样式
                    if post.username.contains("探索") {
                        userTagView("历史爱好者")
                    }
                    
                    Spacer()
                
                    // 使用独立组件处理选项按钮
                    PostOptionsButton(
                        post: post,
                        onDislikeCharacter: dislikeCharacter,
                        onReport: {
                            // 举报内容的逻辑
                            feedbackGenerator.impactOccurred(intensity: 0.4)
                        },
                        onFollowCharacter: { isFollowed in
                            // 关注角色的逻辑
                            feedbackGenerator.impactOccurred(intensity: 0.4)
                        }
                    )
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
                        
                        Text(post.images.isEmpty ? "文字" : "图文")
                            .font(.system(size: 13.0, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
        }
        .padding(.bottom, 10.0)
    }
    
    // 内容区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // 帖子内容 - 调整字体大小和行高
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 16.0, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    // 修复lineLimit条件，确保短内容显示完整
                    .lineLimit(isExpanded || isDetailView || !shouldShowExpandButton ? nil : maxPreviewLines)
                    .lineSpacing(6.0) // 增加行间距提高可读性
                    .fixedSize(horizontal: false, vertical: true) // 确保文本正确换行
                    .padding(.bottom, 2.0) // 为文本添加底部间距
                
                // 仅在需要展开按钮时显示
                if shouldShowExpandButton && !isDetailView {
                    Button(action: {
                        // 立即提供触觉反馈
                        feedbackGenerator.impactOccurred(intensity: 0.3)
                        
                        // 延迟状态更新，给UI线程留出响应时间
                        DispatchQueue.main.async {
                            // 直接切换状态，避免复杂的动画计算
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "收起" : "显示更多")
                                .font(.system(size: 15.0, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            // 添加方向指示图标
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12.0, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4.0)
                }
            }
        }
        .padding(.vertical, 6.0) // 添加垂直间距，增强视觉舒适度
    }
    
    // 图片画廊区域
    private var imageGallerySection: some View {
        Group {
            // 根据图片数量选择不同的布局
            switch post.images.count {
            case 1:
                // 单张图片布局
                singleImageScrollView(post.images[0])
                    .padding(.top, 8.0)
                    .padding(.bottom, 8.0) // 调整底部间距
            case 2:
                // 两张图片布局
                twoImagesLayout
                    .padding(.top, 8.0)
                    .padding(.bottom, 8.0) // 调整底部间距
            case 3:
                // 三张图片布局
                threeImagesLayout
                    .padding(.top, 8.0)
                    .padding(.bottom, 4.0)
            case 4...:
                // 四张或更多图片布局
                fourOrMoreImagesLayout
                    .padding(.top, 8.0)
                    .padding(.bottom, 4.0)
            default:
                Color.clear
            }
        }
    }
    
    // 单张图片视图 - 优化后的小红书风格
    private func singleImageScrollView(_ imageName: String) -> some View {
        GeometryReader { geometry in
                    Button(action: {
            selectedImageIndex = 0
            showImageViewer = true
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred(intensity: 0.5)
        }) {
                // 检查是否是用户上传的图片（通过ID格式判断）
                if imageName.contains("_image_") {
                    // 使用PostImageView加载用户上传的图片
                    PostImageView(
                        imageId: imageName,
                        contentMode: .fill,
                        height: calculateImageHeight(for: imageName, width: geometry.size.width),
                        cornerRadius: 12
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                } else if let uiImage = UIImage(named: imageName) {
                    // 如果是内置图片资源，显示实际图片
                    Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                        .frame(height: calculateOptimizedImageHeight(for: imageName, width: geometry.size.width))
                        .cornerRadius(12)
                    .clipped()
                    .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .overlay(
                            // 仅在有描述时显示描述层
                            Group {
                                if let description = getImageDescription(for: imageName) {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Text(description)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                        .foregroundColor(.white)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.black.opacity(0.6))
                                                )
                        .padding(12)
                                            
                                            Spacer()
                                    }
                                }
                            }
                        )
                } else {
                    // 如果图片不存在，显示优化的占位符
                    generateMockImage(for: imageName)
                        .frame(height: calculateOptimizedImageHeight(for: imageName, width: geometry.size.width))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        }
        .frame(height: estimatedImageHeight(for: imageName))
    }
    
    // 新增：计算优化的图片高度（小红书风格）
    private func calculateOptimizedImageHeight(for imageName: String, width: CGFloat) -> CGFloat {
        // 如果是用户上传的图片，使用默认高度
        if imageName.contains("_image_") {
            return min(width * 1.2, 350) // 默认高度，小红书风格更偏向于竖图
        }
        
        // 尝试获取图片并计算适当的高度
        guard let uiImage = UIImage(named: imageName) else { 
            return min(width * 1.2, 350) // 默认高度
        }
        
        let aspectRatio = uiImage.size.height / uiImage.size.width
        
        // 小红书风格的高度计算逻辑
        if aspectRatio > 1.5 {
            // 竖图 - 限制最大高度
            return min(width * aspectRatio, 450)
        } else if aspectRatio < 0.6 {
            // 横图 - 确保足够高度展示
            return max(width * aspectRatio, 200)
        } else {
            // 近似方形图 - 根据宽度调整
            return width * min(aspectRatio, 1.2)
        }
    }
    
    // 两张图片布局 - 小红书风格
    private var twoImagesLayout: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let imageWidth = (totalWidth - 6) / 2  // 两张图片等宽，中间有间隙
            let aspectRatios = post.images.prefix(2).map { getImageAspectRatio($0) }
            let maxAspectRatio = aspectRatios.max() ?? 1.0
            let imageHeight = min(imageWidth * maxAspectRatio, 240)  // 限制最大高度
            
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { index in
                    twoImageItem(post.images[index], index: index, width: imageWidth, height: imageHeight)
                }
            }
            .frame(height: imageHeight)
        }
        .frame(height: estimateTwoImagesHeight())
    }
    
    // 辅助方法：获取两图布局的估计高度
    private func estimateTwoImagesHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40  // 考虑边距
        let imageWidth = (screenWidth - 6) / 2  // 每张图片的宽度
        
        // 获取两张图片的宽高比
        let aspectRatios = post.images.prefix(2).map { getImageAspectRatio($0) }
        let maxAspectRatio = aspectRatios.max() ?? 1.0
        
        // 根据宽高比计算高度，并限制在合理范围内
        return min(imageWidth * maxAspectRatio, 240)
    }
    
    // 辅助方法：获取图片宽高比
    private func getImageAspectRatio(_ imageName: String) -> CGFloat {
        if imageName.contains("_image_") {
            return 1.2  // 用户上传图片默认宽高比
        }
        
        guard let uiImage = UIImage(named: imageName) else {
            return 1.0  // 默认为正方形
        }
        
        return uiImage.size.height / uiImage.size.width
    }
    
    // 两图布局的单个图片项
    private func twoImageItem(_ imageName: String, index: Int, width: CGFloat, height: CGFloat) -> some View {
        Button(action: {
            selectedImageIndex = index
            showImageViewer = true
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred(intensity: 0.5)
        }) {
            if imageName.contains("_image_") {
                PostImageView(
                    imageId: imageName,
                    contentMode: .fill,
                    width: width,
                    height: height,
                    cornerRadius: 12
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .cornerRadius(12)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                generateMockImage(for: imageName)
                    .frame(width: width, height: height)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 四张或更多图片布局 - 小红书风格
    private var fourOrMoreImagesLayout: some View {
        let rows = min(post.images.count, 9) / 3 + (min(post.images.count, 9) % 3 > 0 ? 1 : 0)
        let height: CGFloat = CGFloat(rows) * 115 + CGFloat(rows - 1) * 6
        
        return GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let imageSize = (totalWidth - 12) / 3  // 3列布局，间距为6
            
            VStack(spacing: 6) {
                ForEach(0..<min(rows, 3), id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<min(3, post.images.count - row * 3), id: \.self) { col in
                            let index = row * 3 + col
                            
                            // 最后一个位置显示+N
                            if index == 8 && post.images.count > 9 {
                                ZStack {
                                    gridImageItem(post.images[index], index: index)
                                        .frame(width: imageSize, height: imageSize)
                                    
                                    // 半透明蒙版
                                    Rectangle()
                                        .fill(Color.black.opacity(0.5))
                                        .cornerRadius(12)
                                    
                                    // +N标识
                                    VStack(spacing: 4) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Text("+\(post.images.count - 9)")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: imageSize, height: imageSize)
                            } else {
                                gridImageItem(post.images[index], index: index)
                                    .frame(width: imageSize, height: imageSize)
                            }
                        }
                        
                        // 填充空白位置以保持网格对齐
                        if row == rows - 1 && post.images.count % 3 != 0 && post.images.count < 9 {
                            ForEach(0..<(3 - (post.images.count % 3)), id: \.self) { _ in
                                Color.clear
                                    .frame(width: imageSize, height: imageSize)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 优化的图片网格项 - 用于三图布局
    private func imageGridItem(_ imageName: String, index: Int, count: Int = 0) -> some View {
                Button(action: {
            selectedImageIndex = index
                    showImageViewer = true
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred(intensity: 0.5)
                }) {
            // 检查是否是用户上传的图片（通过ID格式判断）
            if imageName.contains("_image_") {
                // 使用PostImageView加载用户上传的图片
                PostImageView(
                    imageId: imageName,
                    contentMode: .fill,
                    cornerRadius: 12
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else if let uiImage = UIImage(named: imageName) {
                // 如果图片资源存在，则显示图片
                Image(uiImage: uiImage)
                        .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(12)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .overlay(
                        // 仅在有描述时显示描述层 - 仅在2个以下的图片时显示
                        Group {
                            if let description = getImageDescription(for: imageName), count <= 2 {
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
                // 如果图片资源不存在，则显示优化的占位图
                generateMockImage(for: imageName)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // 三张图片布局 - 小红书风格
    private var threeImagesLayout: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let smallImageWidth = (totalWidth * 0.33) - 3  // 右侧小图宽度
            let largeImageWidth = (totalWidth * 0.67) - 3  // 左侧大图宽度
            let smallImageHeight = (largeImageWidth / 2) - 3  // 右侧小图高度
            let largeImageHeight = largeImageWidth  // 左侧大图高度（保持正方形）
            
            HStack(spacing: 6) {
                // 左侧大图 - 保持比例并剪裁
                imageGridItem(post.images[0], index: 0, count: 3)
                    .frame(width: largeImageWidth, height: largeImageHeight)
                    .clipped()
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // 右侧两张小图垂直排列
                VStack(spacing: 6) {
                    imageGridItem(post.images[1], index: 1, count: 3)
                        .frame(width: smallImageWidth, height: smallImageHeight)
                        .clipped()
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    imageGridItem(post.images[2], index: 2, count: 3)
                        .frame(width: smallImageWidth, height: smallImageHeight)
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
        return largeImageWidth  // 返回大图宽度作为整体高度（保持正方形）
    }
    
    // 根据图片数量和位置计算高度 - 用于多图布局
    private func getImageHeight(for count: Int, index: Int) -> CGFloat {
        switch count {
        case 2:
            return 160 // 两张图片等高
        case 3:
            if index == 0 {
                // 大图高度，为左侧大正方形
                let screenWidth = UIScreen.main.bounds.width - 40 // 考虑边距
                return (screenWidth * 0.67) - 2
            } else {
                // 右侧小图高度，为小正方形
                let screenWidth = UIScreen.main.bounds.width - 40 // 考虑边距
                return (screenWidth * 0.33) - 2
            }
        case 4:
            return 120 // 四张图片网格布局
        default:
            return index < 2 ? 120 : 90 // 默认：前两张较高，后两张较矮
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
                        Text("评论")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                
                        Text("(\(post.comments.count))")
                            .font(.system(size: 13))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
            
                        Spacer()
                
                        // 虚拟角色参与统计
                        let virtualCount = post.comments.filter { $0.isVirtualCharacter }.count
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
                    .padding(.bottom, 6)
                    
                    // 获取一条精选评论
                    if let featuredComment = getFeaturedComment() {
                        HStack(alignment: .top, spacing: 8) {
                            // 用户头像
                            ZStack {
                                Circle()
                                    .fill(featuredComment.isVirtualCharacter 
                                          ? getCharacterColor(for: featuredComment.characterID ?? "").opacity(0.1)
                                          : DesignSystem.Colors.secondaryBackground)
                                    .frame(width: 30, height: 30)
                                
                                Text(String(featuredComment.username.prefix(1)))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(featuredComment.isVirtualCharacter 
                                                    ? getCharacterColor(for: featuredComment.characterID ?? "")
                                                    : DesignSystem.Colors.secondary)
                            }
                            .overlay(
                                Circle()
                                    .stroke(
                                        featuredComment.isVirtualCharacter 
                                        ? getCharacterColor(for: featuredComment.characterID ?? "")
                                        : Color.clear,
                                        lineWidth: 1.0
                                    )
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                // 用户名和类型
                                HStack {
                                    Text(featuredComment.username)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    if featuredComment.isVirtualCharacter {
                                        Text(getCharacterCategory(for: featuredComment.characterID ?? ""))
                                            .font(.system(size: 10))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(getCharacterColor(for: featuredComment.characterID ?? "").opacity(0.12))
                                            .foregroundColor(getCharacterColor(for: featuredComment.characterID ?? ""))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                // 评论内容
                                Text(featuredComment.content)
                                    .font(.system(size: 14))
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
                                                .foregroundColor(getCharacterColor(for: featuredComment.characterID ?? ""))
                                            
                                            Text("历史人物")
                                                .font(.system(size: 10))
                                                .foregroundColor(getCharacterColor(for: featuredComment.characterID ?? "").opacity(0.8))
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
    
    // 获取精选评论 - 按照优先级排序
    private func getFeaturedComment() -> DetailedCommentModel? {
        // 优先选择有回复的虚拟角色评论
        if let virtualComment = post.comments.first(where: { 
            $0.isVirtualCharacter && !$0.replies.isEmpty 
        }) {
            return virtualComment
        }
        
        // 其次选择点赞最多的虚拟角色评论
        if let topVirtualComment = post.comments
            .filter({ $0.isVirtualCharacter })
            .sorted(by: { $0.likes > $1.likes })
            .first {
            return topVirtualComment
        }
        
        // 最后选择点赞最多的普通评论
        return post.comments.sorted(by: { $0.likes > $1.likes }).first
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
        // 检查是否有用户上传的图片
        let hasUploadedImages = post.images.contains { $0.contains("_image_") }
        
        // 如果有用户上传的图片，使用PostImageFullScreenViewer
        if hasUploadedImages {
            return AnyView(
                PostImageFullScreenViewer(
                    imageIds: post.images,
                    initialIndex: selectedImageIndex,
                    isPresented: $showImageViewer
                )
            )
        } else {
            // 否则使用原来的查看器
            return AnyView(
        ZStack {
            // 黑色背景
            Color.black.ignoresSafeArea()
            
            // 轻微缩放效果改进图片显示
            GeometryReader { proxy in
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<post.images.count, id: \.self) { index in
                        ZoomableImageView(
                            image: post.images[index],
                            description: getImageDescription(for: post.images[index])
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 隐藏默认分页指示器，使用自定义指示器
                .background(Color.black)
            }
    
            // 控制界面
        VStack {
                // 顶部控制栏
            HStack {
                    // 关闭按钮
                Button(action: {
                    showImageViewer = false
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16.0, weight: .semibold))
                        .foregroundColor(.white)
                            .padding(12.0)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.leading, 16.0)
                    
                    Spacer()
                    
                    // 分享按钮
                    Button(action: {
                        feedbackGenerator.impactOccurred(intensity: 0.5)
                        // 这里可以添加分享图片的功能
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16.0, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12.0)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.trailing, 16.0)
                }
                .padding(.top, 16.0)
                
            Spacer()
                
                // 底部控制栏
                VStack(spacing: 8) {
                    // 自定义分页指示器
                    if post.images.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<post.images.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedImageIndex ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(index == selectedImageIndex ? 1.3 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedImageIndex)
                            }
                        }
                        .padding(.horizontal, 12.0)
                        .padding(.vertical, 8.0)
                    }
                    
                    // 图片计数指示器
                    if post.images.count > 1 {
                        Text("\(selectedImageIndex + 1) / \(post.images.count)")
                            .font(.system(size: 12.0, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12.0)
                            .padding(.vertical, 6.0)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .padding(.bottom, 16.0)
                    }
                }
                .padding(.bottom, 16.0)
            }
        }
        .statusBar(hidden: true)
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
            )
        }
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
        
        isLiked.toggle()
        
        // 触觉反馈
        feedbackGenerator.impactOccurred(intensity: 0.4)
        
        // 回调
        if let onLikeToggle = onLikeToggle {
            onLikeToggle(isLiked)
        }
    }
    
    // 切换评论显示状态
    private func toggleComments() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showComments.toggle()
        }
        
        // 如果是打开评论区，加载评论数据
        if showComments {
            // 如果是首次加载或者评论为空，触发加载
            if commentLoader.loadedComments.isEmpty {
                // 加载评论数据
                commentLoader.loadComments(forPostID: post.id.uuidString, resetPagination: true)
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
                characterAvatar(for: comment)
                
                VStack(alignment: .leading, spacing: 2) {
                    // 用户名和标签
                    HStack(spacing: 6) {
                        Text(comment.username)
                            .font(.system(size: 15.0, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        if comment.characterID != nil {
                            Text(getCharacterCategory(for: comment.characterID ?? ""))
                                .font(.system(size: 12.0, weight: .regular))
                                .padding(.horizontal, 6.0)
                                .padding(.vertical, 2.0)
                                .background(getCharacterColor(for: comment.characterID ?? "").opacity(0.1))
                                .foregroundColor(getCharacterColor(for: comment.characterID ?? ""))
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
        .overlay(getCommentBorder(for: comment))
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
    
    // 获取角色类别标签
    private func getCharacterCategory(for characterID: String) -> String {
        switch characterID.lowercased() {
        case "einstein": return "科学家"
        case "shakespeare": return "文学家"
        case "davinci": return "艺术家"
        case "confucius": return "哲学家"
        case "curie": return "科学家"
        case "libai": return "诗人"
        case "newton": return "物理学家"
        case "goku", "naruto": return "动漫角色" 
        case "holmes": return "侦探"
        default: return "历史人物"
        }
    }
    
    // 用户头像视图
    private func avatarView(for comment: DetailedCommentModel) -> some View {
        Group {
            if comment.isVirtualCharacter {
                // 虚拟角色头像
                Avatar(url: comment.userAvatar, size: 40)
                    .overlay(
                        Circle()
                            .stroke(getCharacterColor(for: comment.characterID ?? ""), lineWidth: 2)
                            .shadow(color: getCharacterColor(for: comment.characterID ?? "").opacity(0.3), radius: 2, x: 0, y: 0)
                    )
            } else {
                // 普通用户头像
                Avatar(url: comment.userAvatar, size: 40)
            }
        }
    }
    
    // 角色头像
    private func characterAvatar(for comment: DetailedCommentModel) -> some View {
        ZStack {
            Circle()
                .fill(comment.isVirtualCharacter 
                      ? getCharacterColor(for: comment.characterID ?? "").opacity(0.1)
                      : DesignSystem.Colors.secondaryBackground)
                .frame(width: 34.0, height: 34.0)
            
            Text(String(comment.username.prefix(1)))
                .font(.system(size: 18.0, weight: .semibold))
                .foregroundColor(comment.isVirtualCharacter 
                                 ? getCharacterColor(for: comment.characterID ?? "")
                                 : DesignSystem.Colors.secondary)
        }
        .overlay(
            Circle()
                .stroke(
                    comment.isVirtualCharacter 
                    ? getCharacterColor(for: comment.characterID ?? "")
                    : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
    
    // MARK: - 视图组件

    // 操作按钮区域
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // 点赞按钮
            Button(action: toggleLike) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18.0))
                        .foregroundColor(isLiked ? DesignSystem.Colors.like : .gray)
                    
                    Text("\(post.likes)")
                        .font(.system(size: 14.0))
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
                        .font(.system(size: 18.0))
                        .foregroundColor(.gray)
                    
                    Text("\(post.comments.count)")
                        .font(.system(size: 14.0))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(showComments ? DesignSystem.Colors.comment.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 收藏按钮
            Button(action: toggleBookmark) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18.0))
                    .foregroundColor(isBookmarked ? DesignSystem.Colors.bookmark : .gray)
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
                    .font(.system(size: 18.0))
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 4.0)
        .padding(.vertical, 6.0)
    }
    
    // 完整评论区域
    private var populatedCommentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 评论区标题
            HStack {
                Text("评论")
                    .font(.headline)
                
                Spacer()
                
                if commentLoader.hasMoreComments {
                    Button(action: {
                        commentLoader.loadNextPage()
                        feedbackGenerator.impactOccurred(intensity: 0.3)
                    }) {
                        Text("加载更多")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(commentLoader.isLoading)
                }
            }
            .padding(.top, 8)
            
            // 加载状态
            if commentLoader.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // 无评论状态
            else if commentLoader.loadedComments.isEmpty {
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
                ForEach(commentLoader.loadedComments) { comment in
                    CommentRow(
                        comment: comment,
                        onReply: {
                            replyingTo = comment
                            feedbackGenerator.impactOccurred(intensity: 0.4)
                        }
                    )
                    .padding(.vertical, 6)
                    
                    if comment.id != commentLoader.loadedComments.last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            
            // 加载更多按钮
            if commentLoader.hasMoreComments && !commentLoader.loadedComments.isEmpty {
                Button(action: {
                    commentLoader.loadNextPage()
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
                .disabled(commentLoader.isLoading)
            }
            
            // 评论输入区域
            commentInputSection
        }
        .padding(.horizontal, 4)
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
                
                // 更新本地评论加载器
                if let updatedPost = viewModel.posts.first(where: { $0.id == post.id }) {
                    commentLoader.initialize(with: updatedPost.comments, postID: updatedPost.id)
                }
            } else {
                // 如果是新评论
                let newComment = DetailedCommentModel(
                    username: "当前用户",
                    userAvatar: "person.crop.circle.fill",
                    content: trimmedText,
                    datePosted: Date(),
                    isVirtualCharacter: false,
                    characterID: nil,
                    likes: 0
                )
                
                // 添加到评论列表
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    commentLoader.addComment(newComment)
                    
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
        PostCardView(post: ModelData.samplePosts[0])
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
struct PostOptionsButton: View {
    var post: UserPostModel? // 添加post参数
    var onDislikeCharacter: () -> Void
    var onReport: () -> Void
    var onFollowCharacter: ((Bool) -> Void)? = nil // 添加关注回调
    var isOneKeyGeneration: Bool = false // 添加是否为一键生成模式的标志
    
    @State private var isPressed: Bool = false
    @State private var showOptions: Bool = false
    @State private var isFollowing: Bool = false
    @State private var isBlocked: Bool = false
    @State private var showContentTypeStats: Bool = false
    @State private var contentTypeWeights: [String: Double] = [:]
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    // 计算是否在"虫洞探索"模式下
    private var isWormholeExploration: Bool {
        if let post = post {
            return post.source == "wormhole" || post.characterID == "wormhole" || post.username == "虫洞探索"
        }
        return false
    }
    
    // 确定是否显示计数和权重控制
    private var showCountAndWeightControls: Bool {
        isWormholeExploration && post != nil
    }
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // 添加触感反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // 显示选项菜单
            showOptions = true
        }) {
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isPressed ? Color(.systemGray5) : Color.clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showOptions, arrowEdge: .bottom) {
            List {
                // 关注/取消关注角色选项
                if let onFollowCharacter = onFollowCharacter, let post = post {
                    let characterName = post.username
                    Button(action: {
                        isFollowing.toggle()
                        onFollowCharacter(isFollowing)
                        
                        // 显示提示消息
                        toastMessage = isFollowing ? "已关注 \(characterName)" : "已取消关注 \(characterName)"
                        withAnimation {
                            showToast = true
                        }
                        
                        // 2秒后隐藏提示消息
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                        
                        showOptions = false
                    }) {
                        Label(
                            isFollowing ? "取消关注 \(characterName)" : "关注 \(characterName)",
                            systemImage: isFollowing ? "person.badge.minus" : "person.badge.plus"
                        )
                    }
                }
                
                // 屏蔽角色选项
                if let post = post {
                    let characterName = post.username
                    Button(action: {
                        isBlocked.toggle()
                        
                        // 显示提示消息
                        toastMessage = isBlocked ? "已屏蔽 \(characterName)" : "已解除屏蔽 \(characterName)"
                        withAnimation {
                            showToast = true
                        }
                        
                        // 2秒后隐藏提示消息
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                        
                        showOptions = false
                        
                        // 如果屏蔽了角色，调用不喜欢角色的回调
                        if isBlocked {
                            onDislikeCharacter()
                        }
                    }) {
                        Label(
                            isBlocked ? "解除屏蔽 \(characterName)" : "屏蔽 \(characterName)",
                            systemImage: isBlocked ? "person.fill.checkmark" : "person.fill.xmark"
                        )
                    }
                }
                
                // 内容类型统计与权重控制
                if showCountAndWeightControls {
                    Section(header: Text("内容类型统计")) {
                        Button(action: {
                            showContentTypeStats.toggle()
                        }) {
                            HStack {
                                Label(
                                    "查看内容类型统计",
                                    systemImage: "chart.bar"
                                )
                                
                                Spacer()
                                
                                Image(systemName: showContentTypeStats ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showContentTypeStats {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(contentTypeWeights.keys.sorted()), id: \.self) { key in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(key)
                                                .font(.system(size: 14))
                                            
                                            Spacer()
                                            
                                            Text("\(Int(contentTypeWeights[key] ?? 0))")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        
                                        Slider(value: Binding(
                                            get: { contentTypeWeights[key] ?? 0 },
                                            set: { contentTypeWeights[key] = $0 }
                                        ), in: 0...100, step: 1)
                                    }
                                }
                                
                                Button(action: {
                                    // 更新内容类型权重的逻辑
                                    ContentTypeWeightManager.shared.updateAllWeights(weights: contentTypeWeights)
                                    
                                    // 显示提示消息
                                    toastMessage = "已更新内容类型权重"
                                    withAnimation {
                                        showToast = true
                                    }
                                    
                                    // 2秒后隐藏提示消息
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showToast = false
                                        }
                                    }
                                    
                                    showOptions = false
                                }) {
                                    Text("保存设置")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // 不喜欢选项
                Button(action: {
                    onDislikeCharacter()
                    showOptions = false
                }) {
                    Label("不喜欢", systemImage: "hand.thumbsdown")
                }
                
                // 举报选项
                Button(action: {
                    onReport()
                    showOptions = false
                }) {
                    Label("举报", systemImage: "exclamationmark.triangle")
                }
            }
            .frame(minWidth: 250)
        }
        .overlay(
            Group {
                if showToast {
                    VStack {
                        Text(toastMessage)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.6))
                            )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring())
                }
            }
        )
    }
}
}

// 适配iOS 16+的阴影修饰符扩展
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

// 添加重置内容类型权重的方法到ContentTypeWeightManager类中
extension ContentTypeWeightManager {
    func resetContentType(_ type: ContentGeneratorService.ContentType) {
        // 重置权重为1.0（100%）
        setWeight(1.0, for: type)
    }
}

