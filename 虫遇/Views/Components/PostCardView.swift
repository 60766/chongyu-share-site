import SwiftUI
import Foundation



/**
 * 后台数据加载器
 * 用于将数据加载从UI线程分离，优化性能
 */
class CommentLoader: ObservableObject {
    @Published var loadedComments: [UserCommentModel] = []
    @Published var isLoading: Bool = false
    @Published var hasMoreComments: Bool = true
    @Published var isPreloaded: Bool = false  // 标记是否已预加载
    @Published var errorMessage: String? = nil // 错误信息
    @Published var currentPage = 1
    @Published var isInitialized: Bool = false  // 添加isInitialized属性
    private var pageSize = 10
    private var isInitialLoad = true
    
    // 兼容性属性 - 支持新的属性名
    var hasMoreToLoad: Bool { 
        return hasMoreComments 
    }
    
    private var allComments: [UserCommentModel] = []
    private var loadingTask: Task<Void, Never>? = nil // 跟踪当前加载任务
    
    // 析构函数，取消所有任务
    deinit {
        loadingTask?.cancel()
    }
    
    // 初始化加载器
    func initialize(with comments: [UserCommentModel]) {
        guard !isInitialized else { return }
        
        self.allComments = comments
        self.loadedComments = []
        self.currentPage = 1
        self.hasMoreComments = !comments.isEmpty
        self.isInitialized = true
        self.errorMessage = nil
        
        // 自动预加载评论
        if !comments.isEmpty {
            preloadFirstComments()
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
                // 模拟网络延迟，但保持短暂，不影响用户体验
                try await Task.sleep(nanoseconds: 100_000_000)
                
                // 检查任务是否被取消
                if Task.isCancelled { return }
                
                let pageSize = 5  // 合理的批量加载大小，避免一次加载过多
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
                
                // 更新状态
                self.loadedComments.append(contentsOf: newComments)
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
            var newComments: [UserCommentModel] = []
            
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
    func addComment(_ comment: UserCommentModel) {
        isLoading = true
        
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // 在评论列表顶部插入新评论
                self.loadedComments.insert(comment, at: 0)
            }
            self.isLoading = false
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
    
    // 状态属性
    @State private var isExpanded: Bool = false
    @State private var showComments: Bool = false
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    @State private var showImageViewer: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var commentText: String = ""  // 新增：评论文本
    @State private var replyingTo: UserCommentModel? = nil  // 新增：回复对象
    @State private var isSharePresented: Bool = false // 新增：分享菜单展示状态
    
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
    var maxPreviewLines: Int = 5
    var maxPreviewLength: Int = 120
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
    
    // 新增：评论预览获取逻辑
    private var previewComments: [UserCommentModel] {
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
        maxPreviewLines: Int = 5,
        maxPreviewLength: Int = 120,
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
            
            // 评论预览部分
            virtualCommentPreviewSection
            
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
        .padding(.vertical, 10.0) // 调整帖子之间的垂直间距
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
            commentLoader.initialize(with: post.comments)
            
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
            // 用户头像 - 简化设计
            Image(post.userAvatar)
                .resizable()
                    .aspectRatio(contentMode: .fill)
                .frame(width: 46.0, height: 46.0)
                .clipShape(Circle())
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
                
                    // 菜单按钮移至用户信息行内，更加整洁
            Button(action: {
                            feedbackGenerator.impactOccurred(intensity: 0.4)
            }) {
                Image(systemName: "ellipsis")
                            .font(.system(size: 16.0))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(6.0)
                        }
                        .buttonStyle(PlainButtonStyle())
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
                    .lineLimit(isExpanded || isDetailView ? nil : maxPreviewLines)
                    .lineSpacing(6.0) // 增加行间距提高可读性
                    .fixedSize(horizontal: false, vertical: true) // 确保文本正确换行
                    .padding(.bottom, 2.0) // 为文本添加底部间距
                
                // 仅在内容较长且非详情视图时显示展开/收起按钮
                if post.content.count > maxPreviewLength && !isDetailView {
                    Button(action: {
                        withAnimation(DesignSystem.Animations.quick) {
                            isExpanded.toggle()
                        }
                        feedbackGenerator.impactOccurred(intensity: 0.3)
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
                    .padding(.bottom, 4.0)
            case 2:
                // 两张图片布局
                twoImagesLayout
                    .padding(.top, 8.0)
                    .padding(.bottom, 4.0)
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
    
    // 单张图片视图 - 全宽单图布局
    private func singleImageScrollView(_ imageName: String) -> some View {
        GeometryReader { geometry in
                    Button(action: {
            selectedImageIndex = 0
            showImageViewer = true
            feedbackGenerator.impactOccurred(intensity: 0.5)
        }) {
                if let uiImage = UIImage(named: imageName) {
                    // 如果图片存在，显示实际图片
                    Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                        .frame(height: calculateImageHeight(for: imageName, width: geometry.size.width))
                    .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                    .clipped()
                    .overlay(
                            RoundedRectangle(cornerRadius: 12)
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
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                        .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .cornerRadius(8)
                        .padding(12)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        )
                } else {
                    // 如果图片不存在，显示优化的占位符
                    generateMockImage(for: imageName)
                        .frame(height: calculateImageHeight(for: imageName, width: geometry.size.width))
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 0.5)
                        )
            }
        }
        .buttonStyle(PlainButtonStyle())
        }
        .frame(height: estimatedImageHeight(for: imageName))
    }
    
    // 优化的图片网格项
    private func imageGridItem(_ imageName: String, index: Int, count: Int = 0) -> some View {
                Button(action: {
            selectedImageIndex = index
                    showImageViewer = true
            feedbackGenerator.impactOccurred(intensity: 0.5)
                }) {
            if let uiImage = UIImage(named: imageName) {
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
                    .transition(.opacity.combined(with: .scale))
            } else {
                // 如果图片资源不存在，则显示优化的占位图
                generateMockImage(for: imageName)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .transition(.opacity)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
    
    // 两张图片布局
    private var twoImagesLayout: some View {
        GeometryReader { geometry in
                HStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { index in
                    imageGridItem(post.images[index], index: index, count: 2)
                }
            }
            .frame(height: 160) // 固定高度
        }
        .frame(height: 160) // 确保GeometryReader不会扩展
    }
    
    // 三张图片布局
    private var threeImagesLayout: some View {
        GeometryReader { geometry in
                HStack(spacing: 4) {
                // 左侧大图 - 占据左侧2/3空间
                imageGridItem(post.images[0], index: 0, count: 3)
                    .frame(width: (geometry.size.width - 4) * 0.66)
                    .clipped()
                
                // 右侧两张小图垂直排列 - 占据右侧1/3空间
                VStack(spacing: 4) {
                    imageGridItem(post.images[1], index: 1, count: 3)
                    imageGridItem(post.images[2], index: 2, count: 3)
                }
                .frame(width: (geometry.size.width - 4) * 0.34)
            }
            .frame(height: 240) // 固定整体高度
        }
        .frame(height: 240) // 确保GeometryReader不会扩展
    }
    
    // 四张或更多图片布局
    private var fourOrMoreImagesLayout: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    imageGridItem(post.images[0], index: 0, count: 4)
                    imageGridItem(post.images[1], index: 1, count: 4)
                }
                
                HStack(spacing: 4) {
                    imageGridItem(post.images[2], index: 2, count: 4)
                    
                    // 第四张图片（如果有更多，显示+N）
                    ZStack {
                        imageGridItem(post.images[3], index: 3, count: 4)
                        
                        if post.images.count > 4 {
                            // 半透明蒙版
                            Rectangle()
                                .fill(Color.black.opacity(0.4))
                                .cornerRadius(10.0)
                            
                            // +N标识
                            VStack(spacing: 4) {
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("+\(post.images.count - 4)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .frame(height: geometry.size.width) // 保持整体为方形
        }
        .aspectRatio(1.0, contentMode: .fit) // 确保宽高比为1:1
    }
    
    // 根据图片数量和位置计算高度 - 用于多图布局
    private func getImageHeight(for count: Int, index: Int) -> CGFloat {
        switch count {
        case 2:
            return 160 // 两张图片等高
        case 3:
            return index == 0 ? 240 : 118 // 三张图片：第一张高，其余两张较矮
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
                            .font(.system(size: 14))
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
                    .padding(.bottom, 4)
                    
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
                                            .background(getCharacterColor(for: featuredComment.characterID ?? "").opacity(0.1))
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
                            }
                        }
                        .padding(8)
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
                        Text("\(post.comments.count)条评论").font(.system(size: 14)).foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // 获取精选评论 - 按照优先级排序
    private func getFeaturedComment() -> UserCommentModel? {
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
    private func commentButtonSection(for comment: UserCommentModel) -> some View {
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
    private func buttonSection(for comment: UserCommentModel) -> some View {
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
    private func commentBackground(for comment: UserCommentModel) -> some View {
        Group {
            if comment.isVirtualCharacter {
                getCharacterColor(for: comment.characterID ?? "").opacity(0.03)
            } else {
                DesignSystem.Colors.secondaryBackground // 使用设计系统定义的嵌套背景色
            }
        }
    }
    
    // 评论左侧边框
    private func commentLeftBorder(for comment: UserCommentModel) -> some View {
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
    private func commentBorder(for comment: UserCommentModel) -> some View {
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
    private func CommentRow(comment: UserCommentModel, onReply: @escaping () -> Void) -> some View {
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
    private func getCommentBackground(for comment: UserCommentModel) -> some View {
        Group {
            if comment.isVirtualCharacter {
                getCharacterColor(for: comment.characterID ?? "").opacity(0.03)
            } else {
                DesignSystem.Colors.secondaryBackground // 使用设计系统定义的嵌套背景色
            }
        }
    }
    
    // 获取评论左侧边框
    private func getCommentLeftBorder(for comment: UserCommentModel) -> some View {
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
    private func getCommentBorder(for comment: UserCommentModel) -> some View {
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
        switch characterID {
        case "einstein":
            return Color(hex: "5B7AC9") // 更柔和的蓝色，与紫色主题协调
        case "shakespeare":
            return Color(hex: "8C699E") // 与应用主色调相同的紫色
        case "davinci":
            return Color(hex: "5C9A73") // 柔和的绿色，与整体色调和谐
        case "confucius":
            return Color(hex: "A77C4D") // 温暖的棕色，与米色背景协调
        case "curie":
            return Color(hex: "C25B7A") // 保持原有的柔和粉红色
        case "libai":
            return Color(hex: "D07C3C") // 保持原有的温暖橙色
        case "newton":
            return Color(hex: "B94D3F") // 保持原有的柔和红色
        default:
            return DesignSystem.Colors.secondary // 默认使用次要色
        }
    }
    
    // 获取角色类别
    private func getCharacterCategory(for characterID: String) -> String {
        switch characterID {
        case "einstein", "curie", "newton":
            return "科学家"
        case "shakespeare", "libai":
            return "文学家"
        case "davinci":
            return "艺术家"
        case "confucius":
            return "哲学家"
        default:
            return "历史人物"
        }
    }
    
    // 用户头像视图
    private func avatarView(for comment: UserCommentModel) -> some View {
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
    private func characterAvatar(for comment: UserCommentModel) -> some View {
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
        
        // 构建评论对象 - 根据UserPostModel中的定义调整参数
        let newComment = UserCommentModel(
            username: "当前用户",
            userAvatar: "person.crop.circle.fill",
            content: trimmedText,
            datePosted: Date(),
            likes: 0,
            isVirtualCharacter: false,
            characterID: nil
        )
        
        // 模拟网络提交
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // 添加到评论列表
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // 可以改用评论加载器的添加方法
                commentLoader.addComment(newComment)
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
    
    var body: some View {
        Text("图片查看器")
    }
}
