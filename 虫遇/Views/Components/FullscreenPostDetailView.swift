import SwiftUI

/**
 * 全屏帖子详情视图
 * 提供帖子的完整内容和交互功能
 */
struct FullscreenPostDetailView: View {
    // 使用ViewModel管理数据
    @StateObject private var viewModel: FullscreenPostDetailViewModel
    
    // 回调函数
    var onDismiss: (() -> Void)?
    var onLike: ((UserCommentModel) -> Void)?
    var onReport: (() -> Void)?
    var onShare: (() -> Void)?
    
    // 其他状态
    @State private var selectedImageIndex: Int = 0
    @State private var showingExpandedImage: Bool = false
    @State private var showingReportSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet: Bool = false
    @State private var showingCommentTextArea: Bool = false
    
    // TabBar管理
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 初始化方法
    init(post: UserPostModel, 
         onDismiss: (() -> Void)? = nil, 
         onLike: ((UserCommentModel) -> Void)? = nil,
         onReport: (() -> Void)? = nil,
         onShare: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: FullscreenPostDetailViewModel(post: post))
        self.onDismiss = onDismiss
        self.onLike = onLike
        self.onReport = onReport
        self.onShare = onShare
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部导航栏
                    makeTopBar()
                    
                    // 帖子内容
                    makePostContent()
                    
                    // 帖子互动栏
                    makeInteractionBar()
                    
                    // 分隔线
                    makeContentDivider()
                    
                    // 评论区
                    makeCommentsSection()
                        .id("comments")
                }
            }
            .dismissKeyboardOnTap() // 添加点击关闭键盘功能
            
            // 评论输入视图
            CommentInputView(commentManager: viewModel.commentManager)
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            // 隐藏底部标签栏
            tabBarManager.hide()
        }
        .onDisappear {
            // 恢复底部标签栏
            tabBarManager.show()
        }
    }
    
    // MARK: - 子视图组件
    
    // 顶部导航栏 - 优化版本 (UI优化项#1)
    private func makeTopBar() -> some View {
                            HStack(spacing: 16) {
            // 返回按钮
            Button(action: { onDismiss?() }) {
                                        Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                }
                                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                                .contentShape(Circle())
                            
                            Spacer()
                            
            // 标题 - 改进版本
                                    Text("动态详情")
                .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(Color.primary)
                            
                            Spacer()
                            
            // 分享按钮
            Button(action: { showingShareSheet = true }) {
                                        Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                }
                                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                                .contentShape(Circle())
                        }
                        .padding(.horizontal, 16)
        .frame(height: 44)
        .padding(.top, getSafeAreaTop())
        .background(Color(.systemBackground).opacity(0.98))
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
    
    // 获取顶部安全区域高度
    private func getSafeAreaTop() -> CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets.top ?? 0
    }
    
    // 帖子内容
    private func makePostContent() -> some View {
                    VStack(spacing: 0) {
            // 用户信息区域
            HStack(spacing: 12) {
                // 头像
                Image(viewModel.post.userAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
                
                // 用户名和时间
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.post.username)
                        .font(.system(size: 15, weight: .medium))
                    
                    Text(viewModel.post.getFormattedTimeAgo())
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                Spacer()
                
                // 关注按钮
                Button(action: {
                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                    feedbackGenerator.impactOccurred(intensity: 0.4)
                }) {
                    Text("关注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .stroke(DesignSystem.Colors.primary.opacity(0.8), lineWidth: 1)
                                .background(Capsule().fill(DesignSystem.Colors.primary.opacity(0.05)))
                        )
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 14)
            
            // 正文内容
            Text(viewModel.post.content)
                .font(.system(size: 16))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            
            // 图片内容
            if !viewModel.post.images.isEmpty {
                if viewModel.post.images.count == 1 {
                    // 单图显示
                    Image(viewModel.post.images[0])
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                } else {
                    // 多图网格
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(viewModel.post.images, id: \.self) { image in
                            Image(image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
                }
            }
            
    // 帖子互动栏
    private func makeInteractionBar() -> some View {
            HStack(spacing: 20) {
            // 点赞按钮
        Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.4)
                }) {
                    HStack(spacing: 4) {
                    Image(systemName: viewModel.post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                        .foregroundColor(viewModel.post.isLikedByCurrentUser ? .red : .secondary)
                        
                    Text("\(viewModel.post.likes)")
                            .font(.system(size: 13))
                        .foregroundColor(viewModel.post.isLikedByCurrentUser ? .red.opacity(0.8) : .secondary)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                
            // 评论按钮
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.4)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                    Text("\(viewModel.post.comments.count)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                
            // 收藏按钮
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.4)
                }) {
                Image(systemName: viewModel.post.isBookmarkedByCurrentUser ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15))
                    .foregroundColor(viewModel.post.isBookmarkedByCurrentUser ? DesignSystem.Colors.primary : .secondary)
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                
                    Spacer()
                    
            // 分享按钮
            Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
            }
                    .padding(.horizontal, 16)
            .padding(.bottom, 12)
    }
            
    // 分隔线
    private func makeContentDivider() -> some View {
            Divider()
                            .padding(.horizontal, 16)
                .opacity(0.6)
    }
    
    /// 创建评论区域
    private func makeCommentsSection() -> some View {
        VStack(spacing: 0) {
            // 评论区标题
            HStack {
                HStack(spacing: 6) {
                Text("评论")
                        .font(.system(size: 16, weight: .medium))
                
                    // 显示评论总数
                    Text("(\(viewModel.post.getTotalCommentsCount()))")
                        .font(.system(size: 15))
                    .foregroundColor(.secondary)
                }
                        
                Spacer()
                
                // 排序按钮
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("最新")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // 评论列表
                CommentsListView(
                comments: viewModel.post.getTopLevelComments(),
                onReply: { comment in
                    viewModel.commentManager.replyTo(comment: comment)
                },
                onLike: { comment in
                    viewModel.post.likeComment(commentId: comment.id)
                }
            )
            .padding(.top, 6)
        }
        .background(Color(.systemBackground))
        .padding(.bottom, 80) // 为评论输入框留出空间
    }
}

/**
 * 帖子详情视图 - 使用ObservableObject管理数据
 */
class FullscreenPostDetailViewModel: ObservableObject {
    @Published var post: UserPostModel
    @Published var commentManager: CommentManager
    
    init(post: UserPostModel) {
        self.post = post
        self.commentManager = CommentManager(post: post)
    }
}

/**
 * 滚动偏移量首选项键
 */
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/**
 * 水平滑动模态呈现修饰符
 * 用于替换默认的从下往上的模态呈现方式
 */
struct FullscreenPostDetailHorizontalModalTransition: ViewModifier {
    let isPresented: Binding<Bool>
    let onDismiss: (() -> Void)?
    let content: () -> AnyView
    let direction: ModalDirection
    
    enum ModalDirection {
        case fromRight
        case fromLeft
    }
    
    @State private var internalIsPresented = false
    @State private var slideInPosition = CGSize.zero
    
    init<V: View>(isPresented: Binding<Bool>, direction: ModalDirection = .fromRight, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> V) {
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        self.content = { AnyView(content()) }
        self.direction = direction
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .onChange(of: isPresented.wrappedValue) { oldValue, newValue in
                    // 在闭包内创建局部变量，确保安全访问变量
                    // 删除未使用的局部变量
                    let localDirection = self.direction
                    var localInternalIsPresented = self.internalIsPresented
                    var localSlideInPosition = self.slideInPosition
                    
                    if newValue && !localInternalIsPresented {
                        // 根据方向从侧面滑入
                        let screenWidth = UIScreen.main.bounds.width
                        localSlideInPosition = CGSize(
                            width: localDirection == .fromRight ? screenWidth : -screenWidth, 
                            height: 0
                        )
                        withAnimation(.linear(duration: 0.01)) {
                            self.internalIsPresented = true
                            localInternalIsPresented = true
                        }
                        
                        // 更新状态变量
                        self.slideInPosition = localSlideInPosition
                        
                        // 在下一帧执行滑入动画
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.slideInPosition = .zero
                            }
                        }
                    } else if !newValue && localInternalIsPresented {
                        // 向侧面滑出
                        let screenWidth = UIScreen.main.bounds.width
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            self.slideInPosition = CGSize(
                                width: localDirection == .fromRight ? screenWidth : -screenWidth, 
                                height: 0
                            )
                        }
                        
                        // 动画完成后关闭
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.internalIsPresented = false
                            self.onDismiss?()
                        }
                    }
                }
            
            if internalIsPresented {
                self.content()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: slideInPosition.width, y: 0)
                    .transition(.identity)
                    .zIndex(999)
            }
        }
    }
}

// 扩展 View 以添加自定义模态呈现修饰符
extension View {
    func postDetailHorizontalModal<Content: View>(
        isPresented: Binding<Bool>,
        direction: FullscreenPostDetailHorizontalModalTransition.ModalDirection = .fromRight,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FullscreenPostDetailHorizontalModalTransition(isPresented: isPresented, direction: direction, onDismiss: onDismiss, content: content))
    }
}

/**
 * 预览
 */
struct FullscreenPostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FullscreenPostDetailView(
            post: ModelData.samplePosts[0],
            onDismiss: {},
            onLike: { _ in }
        )
    }
}

/**
 * 全屏内容视图 - 使用UIKit实现真正的全屏效果
 * 完全绕过SwiftUI的安全区域限制
 */
struct FullscreenContentView: UIViewControllerRepresentable {
    let post: UserPostModel
    @Binding var scrollOffset: CGFloat
    @Binding var scrollToCommentSection: Bool
    @Binding var dragOffset: CGSize
    let contentOpacity: Double
    let onLike: (UserCommentModel) -> Void
    let onReply: (UserCommentModel) -> Void
    let onTapGesture: () -> Void
    
    // 添加isFullImmersiveMode绑定变量
    @Binding var isFullImmersiveMode: Bool
    
    // 添加replyingTo绑定属性
    @Binding var replyingTo: UserCommentModel?
    
    func makeUIViewController(context: Context) -> UIHostingController<FullscreenContent> {
        let hostingController = UIHostingController(
            rootView: FullscreenContent(
                post: post,
                scrollOffset: $scrollOffset,
                scrollToCommentSection: $scrollToCommentSection,
                dragOffset: $dragOffset,
                contentOpacity: contentOpacity,
                onLike: { comment in
                    self.onLike(comment)
                },
                onReply: { comment in
                    self.onReply(comment)
                },
                onTapGesture: onTapGesture,
                isFullImmersiveMode: $isFullImmersiveMode,
                replyingTo: $replyingTo
            )
        )
        
        // 关键设置：禁用安全区域调整
        hostingController.view.backgroundColor = .clear
        
        // 使用我们之前创建的扩展彻底禁用安全区域
        hostingController.disableSafeAreaEnhanced()
        
        // 额外的设置，确保内容延伸到边缘
        hostingController.additionalSafeAreaInsets = .zero

        // 设置 Home Indicator 自动隐藏 - 提高沉浸感
        hostingController.setupPrefersHomeIndicatorAutoHidden() // 首先设置子类化
        hostingController.enableHomeIndicatorAutoHiding() // 然后启用自动隐藏
        
        // 更新获取window的方式，兼容iOS 15+
        if #available(iOS 15.0, *) {
            // 使用UIWindowScene.windows
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                // 获取最底层的ViewController，确保它不受安全区域限制
                if var topController = window.rootViewController {
                    while let presentedViewController = topController.presentedViewController {
                        topController = presentedViewController
                    }
                    // 将禁用安全区域的设置应用到顶层控制器
                    topController.additionalSafeAreaInsets = .zero
                    topController.view.insetsLayoutMarginsFromSafeArea = false
                }
            }
        } else {
            // iOS 15以下使用旧API
            if let window = UIApplication.shared.windows.first {
                // 获取最底层的ViewController，确保它不受安全区域限制
                if var topController = window.rootViewController {
                    while let presentedViewController = topController.presentedViewController {
                        topController = presentedViewController
                    }
                    // 将禁用安全区域的设置应用到顶层控制器
                    topController.additionalSafeAreaInsets = .zero
                    topController.view.insetsLayoutMarginsFromSafeArea = false
                }
            }
        }
        
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<FullscreenContent>, context: Context) {
        uiViewController.rootView = FullscreenContent(
            post: post,
            scrollOffset: $scrollOffset,
            scrollToCommentSection: $scrollToCommentSection,
            dragOffset: $dragOffset,
            contentOpacity: contentOpacity,
            onLike: { comment in
                self.onLike(comment)
            },
            onReply: { comment in
                self.onReply(comment)
            },
            onTapGesture: onTapGesture,
            isFullImmersiveMode: $isFullImmersiveMode,
            replyingTo: $replyingTo
        )
        
        // 确保每次更新都应用设置
        uiViewController.disableSafeAreaEnhanced()
    }
    
    // 内部内容视图 - 复用现有视图内容
    struct FullscreenContent: View {
        let post: UserPostModel
        @Binding var scrollOffset: CGFloat
        @Binding var scrollToCommentSection: Bool
        @Binding var dragOffset: CGSize
        let contentOpacity: Double
        let onLike: ((UserCommentModel) -> Void)?
        let onReply: ((UserCommentModel) -> Void)?
        let onTapGesture: () -> Void
        
        // 添加isFullImmersiveMode绑定变量
        @Binding var isFullImmersiveMode: Bool
        
        // 添加replyingTo绑定属性
        @Binding var replyingTo: UserCommentModel?
        
        // 添加likedComments状态变量
        @State private var likedComments: Set<UUID> = []
        // 添加分享表单状态变量
        @State private var showShareSheet: Bool = false
        
        // 获取设备颜色模式
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            GeometryReader { geometry in
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        // 滚动位置检测
                        scrollPositionDetector
                        
                        // 内容区
                        VStack(spacing: 0) {
                            // 帖子内容部分
                            makePostContentSection(for: post)
                                .id("postContent")
                            
                            // 移除灰色分隔线，使用透明间隔代替
                            Color.clear
                                .frame(height: 1)
                            
                            // 评论区部分
                            makeCommentsSection()
                                .id("comments")
                                
                            // 额外添加一个超小的填充区域，以确保ScrollView完全滚动到底部
                            Color.clear
                                .frame(height: 1)
                                
                            // 添加柔和的分隔线
                            Rectangle()
                                .fill(Color(UIColor.separator).opacity(0.2))
                                .frame(height: 0.5)
                        }
                        .opacity(contentOpacity)
                        .offset(x: dragOffset.width)
                        .onTapGesture(count: 2) {
                            onTapGesture()
                        }
                    }
                    // 使用这些修饰符确保滚动视图真正全屏
                    .ignoresSafeArea(.all)
                    .edgesIgnoringSafeArea(.all)
                    .padding(.bottom, 0) // 确保没有底部内边距
                    .padding(.top, 0) // 确保没有顶部内边距
                    .background(Color.clear) // 使用透明背景代替白色
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        withAnimation(.easeOut) {
                            scrollOffset = -offset
                        }
                    }
                    .onChange(of: scrollToCommentSection) { oldValue, newValue in
                        if newValue {
                            withAnimation {
                                scrollProxy.scrollTo("commentInputSection", anchor: .top)
                            }
                            
                            // 延迟重置状态变量
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                scrollToCommentSection = false
                            }
                        }
                    }
                    .onChange(of: post.id) { oldValue, newValue in
                        withAnimation {
                            scrollProxy.scrollTo("postContent", anchor: .top)
                        }
                    }
                    .onChange(of: isFullImmersiveMode) { oldValue, newValue in
                        // UIScrollView 设置可以保持不变，因为它是全局的
                        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("RefreshCommentInputLayout"),
                                object: nil
                            )
                        }
                    }
                }
            }
            // 确保所有边缘都被忽略
            .ignoresSafeArea(edges: .all)
        }
        
        // 滚动位置检测器
        private var scrollPositionDetector: some View {
            GeometryReader { innerGeometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: innerGeometry.frame(in: .named("scrollView")).minY
                )
            }
            .frame(height: 0)
        }
        
        // 生成指定帖子的内容区域 (复用现有实现)
        private func makePostContentSection(for currentPost: UserPostModel) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                // 用户信息区域 - 超简洁设计
                HStack(spacing: 12) {
                    // 头像 - 更精致的设计
                    Image(currentPost.userAvatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    
                    // 用户名和时间 - 更紧凑
                    VStack(alignment: .leading, spacing: 1) {
                        Text(currentPost.username)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(currentPost.getFormattedTimeAgo())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // 简洁关注按钮
                    Button(action: {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        feedbackGenerator.impactOccurred(intensity: 0.4)
                    }) {
                        Text("关注")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .stroke(DesignSystem.Colors.primary.opacity(0.8), lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
                
                // 正文内容 - 优化阅读体验
                Text(currentPost.content)
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                
                // 图片内容 - 优化布局和圆角
                if !currentPost.images.isEmpty {
                    if currentPost.images.count == 1 {
                        // 单图显示 - 更自然的高度
                        Image(currentPost.images[0])
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                    } else {
                        // 多图网格 - 更紧凑的布局
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(currentPost.images, id: \.self) { image in
                            Image(image)
                                .resizable()
                                .scaledToFill()
                                    .frame(height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                }
                
                // 互动按钮区 - 现代化设计
                HStack(spacing: 20) {
                    // 点赞按钮 - 视觉效果增强
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred(intensity: 0.4)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: currentPost.isLikedByCurrentUser ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(currentPost.isLikedByCurrentUser ? .red : .secondary)
                            
                            Text("\(currentPost.likes)")
                                .font(.system(size: 13))
                                .foregroundColor(currentPost.isLikedByCurrentUser ? .red.opacity(0.8) : .secondary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                    
                    // 评论按钮 - 改进交互
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred(intensity: 0.4)
                        scrollToCommentSection = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Text("\(currentPost.comments.count)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                    
                    // 收藏按钮 - 增强视觉效果
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred(intensity: 0.4)
                    }) {
                        Image(systemName: currentPost.isBookmarkedByCurrentUser ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15))
                            .foregroundColor(currentPost.isBookmarkedByCurrentUser ? DesignSystem.Colors.primary : .secondary)
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                    
                    Spacer()
                    
                    // 分享按钮 - 使用状态变量
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred(intensity: 0.4)
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // 更细的分隔线
                Divider()
                    .padding(.horizontal, 16)
                    .opacity(0.6)
            }
            .background(Color(UIColor.systemBackground))
        }
        
        // 创建评论区域
        private func makeCommentsSection() -> some View {
            VStack(spacing: 0) {
                // 提取顶级评论（主评论，不包含回复）
                let topLevelComments = post.getTopLevelComments()
                
                if topLevelComments.isEmpty {
                    // 无评论时的提示视图
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.4))
                        
                        Text("暂无评论")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                        
                        Text("快来发表第一条评论吧")
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                } else {
                    // 评论列表
                    CommentsListView(
                        comments: topLevelComments,
                        onReply: { comment in
                            if let onReply = onReply {
                                onReply(comment)
                            }
                        },
                        onLike: { comment in
                            post.likeComment(commentId: comment.id)
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        
        // 格式化时间的辅助方法
        private func getFormattedDate(from date: Date) -> String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
}

/**
 * 增强评论列表视图 - 微信朋友圈风格
 * 提供扁平化展示所有评论和回复的微信朋友圈模式
 */
struct EnhancedCommentsListView: View {
    let comments: [UserCommentModel]
    let onReply: ((UserCommentModel) -> Void)?
    let onLike: ((UserCommentModel) -> Void)?
    let likedComments: Set<UUID>
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // 评论区标题
            HStack {
                Text("评论")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("(\(comments.count))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    
                Spacer()
                
                // 排序选项
                Menu {
                    Button(action: {}) {
                        Label("最新", systemImage: "arrow.up")
                    }
                    Button(action: {}) {
                        Label("热度", systemImage: "flame")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("最新")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if comments.isEmpty {
                // 无评论时显示空状态
                EmptyCommentsView()
            } else {
                // 微信朋友圈风格的评论列表 - 统一背景
                VStack(spacing: 0) {
                    ForEach(comments) { comment in
                        WechatStyleCommentItem(
                            comment: comment,
                            onReply: { comment in onReply?(comment) },
                            onLike: { comment in onLike?(comment) },
                            isLiked: likedComments.contains(comment.id)
                        )
                        
                        // 每条评论之间的分隔线
                        if comment.id != comments.last?.id {
                            Divider()
                                .padding(.leading, 58)
                                .padding(.trailing, 16)
                                .opacity(0.6)
                        }
                    }
                }
                .background(Color.warmNestedBackground.opacity(0.6))
                .cornerRadius(DesignSystem.Radius.m)
                .padding(.horizontal, 16)
            }
        }
        // 移除底部的内边距，确保没有额外空间
        .padding(.bottom, 0)
    }
}

/**
 * 微信朋友圈风格的评论项视图
 * 扁平化展示每条评论或回复
 */
private struct WechatStyleCommentItem: View {
    let comment: UserCommentModel
    let onReply: ((UserCommentModel) -> Void)?
    let onLike: ((UserCommentModel) -> Void)?
    let isLiked: Bool
    
    // 获取角色颜色 - 更新颜色值使其与紫色主题协调
    private var characterColor: Color {
        if comment.isVirtualCharacter {
            switch comment.characterID?.lowercased() {
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
        } else {
            return DesignSystem.Colors.primary
        }
    }
    
    // 获取角色领域
    private var characterField: String? {
        if comment.isVirtualCharacter {
            switch comment.characterID?.lowercased() {
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
        return nil
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 用户头像
            if !comment.userAvatar.isEmpty, let avatar = UIImage(named: comment.userAvatar) {
                Image(uiImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                comment.isVirtualCharacter ? 
                                    characterColor.opacity(0.3) : 
                                    Color.clear, 
                                lineWidth: 0.5
                            )
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(comment.username.prefix(1).uppercased()))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 用户信息和回复关系行
                HStack(alignment: .center, spacing: 4) {
                    // 用户名
                    Text(comment.username)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(
                            comment.isVirtualCharacter ? 
                                characterColor : 
                                Color.primary
                        )
                    
                    // 历史人物标识
                    if let field = characterField {
                        Text(field)
                            .font(.system(size: 10))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(characterColor.opacity(0.12))
                            .foregroundColor(characterColor)
                            .cornerRadius(4)
                    }
                    
                    // 如果是回复，显示回复对象
                    if let replyToUsername = comment.replyToUsername {
                        Text(" 回复 ")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(replyToUsername)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.primary.opacity(0.8))
                        
                        Text("：")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Text("：")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                // 评论内容
                Text(comment.content)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 1)
                
                // 底部元信息和操作按钮
                HStack {
                    // 时间
                    Text(getFormattedTimeAgo(from: comment.datePosted))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // 回复按钮
                    if let replyAction = onReply {
                        Button(action: {
                            replyAction(comment)
                        }) {
                            Text("回复")
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // 点赞按钮
                    if let likeAction = onLike {
                        Button(action: {
                            likeAction(comment)
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                
                                if comment.likes > 0 {
                                    Text("\(comment.likes)")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(
                                isLiked ? .likeColor.opacity(0.8) : .gray.opacity(0.8)
                            )
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

/**
 * 空评论状态视图
 * 显示无评论时的状态
 */
private struct EmptyCommentsView: View {
    var body: some View {
        VStack(spacing: 14) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.05))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 22))
                    .foregroundColor(Color.gray.opacity(0.3))
            }
            
            // 文本提示
            VStack(spacing: 4) {
                Text("暂无评论")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("成为第一个参与讨论的人吧")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 评论按钮
            Button(action: {
                // 触发评论输入框聚焦通知
                NotificationCenter.default.post(
                    name: Notification.Name("FocusCommentInput"),
                    object: nil
                )
            }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                    
                    Text("写评论")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(DesignSystem.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
    }
}

// 格式化时间的辅助方法
private func getFormattedTimeAgo(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

// 辅助函数：检查是否为系统图标名称
private func isSystemImageName(_ name: String) -> Bool {
    // 系统图标名称通常不会包含文件扩展名或特定路径
    return !name.contains(".") && !name.contains("/")
} 

/**
 * 格式化日期为相对时间描述
 * @param from - 要格式化的日期
 * @return 格式化后的时间字符串，如"3小时前"
 */
private func getFormattedDate(from date: Date) -> String {
    let now = Date()
    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)
    
    if let year = components.year, year > 0 {
        return "\(year)年前"
    } else if let month = components.month, month > 0 {
        return "\(month)个月前"
    } else if let day = components.day, day > 0 {
        return "\(day)天前"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)小时前"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)分钟前"
    } else {
        return "刚刚"
    }
}

/**
 * 分享表单包装器
 * 包装UIActivityViewController以在SwiftUI中使用
 */
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PostCommentView: View {
    let comment: UserCommentModel
    let onReply: ((UserCommentModel) -> Void)?
    let onLike: ((UserCommentModel) -> Void)?
    let isLiked: Bool
    
    // 获取角色颜色
    private var characterColor: Color {
        if comment.isVirtualCharacter {
            switch comment.characterID?.lowercased() {
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
        } else {
            return DesignSystem.Colors.primary
        }
    }
    
    // 获取角色领域
    private var characterField: String? {
        if comment.isVirtualCharacter {
            switch comment.characterID?.lowercased() {
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
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 主评论
            HStack(alignment: .top, spacing: 12) {
                // 用户头像
                if !comment.userAvatar.isEmpty, let avatar = UIImage(named: comment.userAvatar) {
                    Image(uiImage: avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    comment.isVirtualCharacter ? 
                                        characterColor.opacity(0.3) : 
                                        Color.clear, 
                                    lineWidth: 0.5
                                )
                        )
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(comment.username.prefix(1).uppercased()))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 用户信息行
                    HStack(alignment: .center, spacing: 6) {
                        Text(comment.username)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(comment.isVirtualCharacter ? characterColor : Color.primary)
                        
                        // 显示角色领域标签
                        if let field = characterField {
                            Text(field)
                                .font(.system(size: 10))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(characterColor.opacity(0.12))
                                .foregroundColor(characterColor)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Text(getFormattedDate(from: comment.datePosted))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    // 显示回复对象
                    if let replyToUsername = comment.replyToUsername {
                        Text("回复 \(replyToUsername)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                    }
                    
                    // 评论内容
                    Text(comment.content)
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .padding(.top, 2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 互动按钮
                    HStack(spacing: 16) {
                        Button(action: {
                            onReply?(comment)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 12))
                                Text("回复")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.gray.opacity(0.8))
                        }
                        
                        Button(action: {
                            onLike?(comment)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                if comment.likes > 0 {
                                    Text("\(comment.likes)")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(isLiked ? .red : .gray.opacity(0.8))
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // 格式化日期为相对时间
    private func getFormattedDate(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}

