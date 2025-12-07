import SwiftUI
import Combine
import UIKit // 如果还没有导入
// 导入数据模型
import SwiftData

// 注意: TimeSpaceParticleView, TimeSpaceRippleView 和 SwipeDirection 
// 定义在 TimeSpaceTransitionEffect.swift 文件中
// 虫遇项目中所有视图组件都在同一模块内，可以直接引用
// 不需要特殊导入语句，但确保该文件是项目的编译目标一部分

// 导入NavigationHelper
// 由于无法直接导入Utils模块，我们在此处定义所需的辅助类

/**
 * 导航助手类 - 用于FullscreenPostDetailView内部
 * 提供全局导航控制和支持
 */
fileprivate class FPDVNavigationHelper {
    /// 单例实例
    static let shared = FPDVNavigationHelper()
    
    /// 私有初始化方法
    private init() {
        #if DEBUG
        print("FPDVNavigationHelper初始化")
        #endif
    }
    
    /// 强制返回上一级页面
    func forceGoBack() {
        DispatchQueue.main.async {
            // 查找顶层视图控制器
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let topVC = window.rootViewController?.fpContextTopViewController {
                
                // 如果是导航控制器，尝试弹出
                if let navigationController = topVC.navigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    // 否则尝试dismiss
                    topVC.dismiss(animated: true)
                }
            }
        }
    }
}

// MARK: - UIViewController扩展 - 用于FullscreenPostDetailView内部
extension UIViewController {
    /// 获取最顶层的视图控制器 - 用于FullscreenPostDetailView内部
    fileprivate var fpContextTopViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.fpContextTopViewController
        }
        
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.fpContextTopViewController ?? self
        }
        
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.fpContextTopViewController ?? self
        }
        
        return self
    }
    
    /// 关闭当前视图控制器 - 用于FullscreenPostDetailView内部
    fileprivate func fpContextDismissVC(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: animated)
            completion?()
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }
}

// 导入工程内其他模块，确保正确引用
// 全文件使用到的类型都正确导入

/**
 * 通用缩放按钮样式 - 用于FullscreenPostDetailView内部
 * 提供轻微的缩放效果，用于创建有触感的按钮交互
 */
fileprivate struct FPDVScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/**
 * 设计系统颜色定义 - 用于FullscreenPostDetailView内部
 * 统一程序界面的颜色方案
 */
fileprivate struct FPDVDesignSystem {
    struct Colors {
        // 主题色 - 使用适合虫遇风格的紫色作为主题色
        static let primary = Color(red: 149/255, green: 138/255, blue: 177/255)
        static let secondary = Color(red: 191/255, green: 186/255, blue: 204/255)
    }
}

private struct FullscreenScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 定义显示状态枚举，用于处理视图转换
private enum DisplayState {
    case current     // 当前显示的动态
    case transitioning(direction: SwipeDirection, progress: CGFloat) // 正在过渡
    case nextPagePreview  // 下一页预览
}

/**
 * 全屏帖子详情视图
 * 提供帖子的完整内容和交互功能
 */
struct FullscreenPostDetailView: View {
    // 使用ViewModel管理数据
    @StateObject private var viewModel: FullscreenPostDetailViewModel
    
    // 全局点赞状态管理器
    @StateObject private var likeStateManager = LikeStateManager.shared
    
    // 回调函数
    var onDismiss: (() -> Void)?
    var onLike: ((DetailedCommentModel) -> Void)?
    var onReport: (() -> Void)?
    var onShare: (() -> Void)?
    // 添加获取上一个和下一个帖子的回调
    var onNextPost: ((UUID) -> UserPostModel?)?
    var onPrevPost: ((UUID) -> UserPostModel?)?
    
    // 保存初始化时的post ID，用于检测状态不一致
    private let initialPostId: UUID
    
    // 滑动状态
    @State private var dragOffset: CGFloat = 0.0
    @State private var dampedOffset: CGFloat = 0.0
    @State private var isDragging: Bool = false
    @State private var swipeDirection: SwipeDirection = .none
    @State private var isTransitioning: Bool = false
    @State private var displayState: DisplayState = .current
    
    // 添加滚动状态变量
    @State private var isScrolled: Bool = false
    
    // 标题栏背景透明度
    @State private var titleBarBackgroundOpacity: CGFloat = 0
    
    // 双缓冲显示技术变量 - 用于过渡过程中显示下一页内容
    @State private var nextPagePost: UserPostModel? = nil
    @State private var nextPageVisible: Bool = false
    
    // 穿越时空效果状态变量
    @State private var showingTimeSpaceEffect: Bool = false
    @State private var timeSpaceDirection: SwipeDirection = .none
    
    // 添加新内容状态变量
    @State private var showAddContentView: Bool = false
    @State private var isLastPost: Bool = false
    @State private var isFirstPost: Bool = false
    
    // 状态变量
    @State private var hasNextPost: Bool = true
    @State private var hasPrevPost: Bool = true
    @GestureState private var isPostContentPressed: Bool = false
    
    // 其他状态
    @State private var selectedImageIndex: Int = 0
    @State private var showingExpandedImage: Bool = false
    @State private var showingReportSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet: Bool = false
    @State private var showingCommentTextArea: Bool = false
    @State private var showHistoricalFigureSelection: Bool = false
    
    // 添加关注状态变量
    @State private var isFollowed: Bool = false
    
    // 控制任务生命周期的状态
    @State private var isViewActive: Bool = true
    
    // TabBar管理
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 内容生成状态管理器
    @ObservedObject private var generationStateManager = ContentGenerationStateManager.shared
    
    // 环境变量，用于返回导航
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    // 系统返回按钮窗口引用
    @State private var systemBackButtonWindow: UIWindow?
    
    // Phase 2优化 - 智能缓存系统集成
    private let intelligentCache = IntelligentDataCache.shared
    private let batchedDefaults = BatchedUserDefaults.shared
    private let performanceMonitor = PerformanceMonitor.shared
    
    // 添加虫洞探索页面的拖动状态
    @State private var wormholePageDragOffset: CGFloat = 0.0
    @State private var isWormholeDragging: Bool = false
    @State private var showWormholeSwipeIndicator: Bool = false
    
    // 自定义时空特效状态
    @State private var showCustomTimeSpaceEffect: Bool = false
    
    // 黑洞中心位置状态
    @State private var blackHoleCenterPosition: CGPoint? = nil
    
    // 角色详情页导航状态
    @State private var navigateToCharacterDetail: CharacterModel? = nil
    
    // 添加虫洞共鸣的状态变量
    @State private var selectedSituation: String = "寻找答案"
    @State private var selectedExpectation: String = "新视角"
    @State private var situations = ["寻找答案", "做决定", "需要灵感", "思考人生"]
    @State private var expectations = ["被看见", "新视角", "实用建议", "共鸣与安慰"]
    @State private var explorationKeyword: String = ""
    @State private var isDirecctedMode: Bool = false
    
    // 新增状态，用于控制"三颗星星"图标的动画，使用Dictionary关联到特定帖子
    @State private var generatingMediaPostIds: Set<UUID> = []
    
    // 计算当前帖子是否正在生成内容
    private var isGeneratingAIMedia: Bool {
        // 帖子ID不是可选类型，直接使用
        let currentPostId = viewModel.post.id
        return generatingMediaPostIds.contains(currentPostId)
    }
    
    // 初始化方法
    init(
        post: UserPostModel, 
        onDismiss: (() -> Void)? = nil, 
        onLike: ((DetailedCommentModel) -> Void)? = nil,
        onReport: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onNextPost: ((UUID) -> UserPostModel?)? = nil,
        onPrevPost: ((UUID) -> UserPostModel?)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: FullscreenPostDetailViewModel(post: post))
        self.initialPostId = post.id
        self.onDismiss = onDismiss
        self.onLike = onLike
        self.onReport = onReport
        self.onShare = onShare
        self.onNextPost = onNextPost
        self.onPrevPost = onPrevPost
        
        // Phase 2优化 - 初始化时缓存当前帖子
        intelligentCache.cachePost(post)
    }
    
    @EnvironmentObject var creationTypeManager: CreationTypeManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 底层背景色 - 防止任何透明
            DesignSystem.Colors.background
                .edgesIgnoringSafeArea(.all)
                .zIndex(-3)
            
            // 滑动手势视图
            ZStack {
                // 过渡期间的背景层 - 防止看到其他内容
                if isTransitioning {
                    DesignSystem.Colors.background
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(-2)
                }
                
                // 时空效果层 - 只在页面转换时显示
                if showingTimeSpaceEffect {
                    GeometryReader { geo in
                        // 使用GeometryReader确保全屏覆盖
                        ZStack {
                            // 底层使用波纹效果
                            TimeSpaceRippleView(direction: timeSpaceDirection)
                                .opacity(0.95) // 提高透明度使波纹效果更明显
                            
                            // 顶层使用粒子效果
                            TimeSpaceParticleView(direction: timeSpaceDirection)
                                .opacity(0.95) // 提高透明度使粒子效果更明显
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1000) // 提高z轴层级，确保在所有内容之上
                    .transition(.opacity) // 添加过渡效果
                }
                
                // 下一页内容预览层 - 只在需要时显示
                if nextPageVisible, let nextPost = nextPagePost {
                    // 下一页内容视图 - 使用与主视图完全相同的结构
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // 顶部导航栏
                            makeTopBar()
                            
                            // 使用与主视图完全相同的结构显示内容
                            VStack(alignment: .leading, spacing: 0) {
                                // 用户信息区域
                                HStack(spacing: 12) {
                                    // 头像
                                    CharacterAvatarSimple(nextPost.userAvatar, size: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                        )
                                    
                                    // 用户名和时间
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(nextPost.username)
                                            .font(.system(size: 15, weight: .medium))
                                        
                                        Text(nextPost.getFormattedTimeAgo())
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    // 关注按钮
                                    Button(action: {}) {
                                        Text("关注")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(FPDVDesignSystem.Colors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .stroke(FPDVDesignSystem.Colors.primary.opacity(0.8), lineWidth: 1)
                                                    .background(Capsule().fill(FPDVDesignSystem.Colors.primary.opacity(0.05)))
                                            )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 14)
                                
                                // 正文内容
                                Text(nextPost.content)
                                    .font(.system(size: 16))
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 14)
                                
                                // 图片内容 - 使用与主视图完全相同的ZStack结构
                                ZStack(alignment: .center) {
                                    // 预先计算图片区域的大小
                                    let imageHeight: CGFloat = !nextPost.images.isEmpty ? (nextPost.images.count == 1 ? 230 : 160) : 0
                                    let hasImages = !nextPost.images.isEmpty
                                    
                                    // 占位区域 - 只有在有图片时才显示，防止内容跳动
                                    if hasImages {
                                        Color.clear
                                            .frame(height: imageHeight + 10) // 加上底部padding，保持布局一致
                                            .onAppear {
                                                // 使用异步调用避免在视图更新过程中执行预加载操作
                                                DispatchQueue.main.async {
                                                    // 在视图出现时立即预加载图片，防止延迟加载导致布局变化
                                                    for imageName in nextPost.images {
                                                        _ = UIImage(named: imageName)
                                                    }
                                                }
                                            }
                                    }
                                    
                                    // 实际图片内容
                                    if !nextPost.images.isEmpty {
                                        if nextPost.images.count == 1 {
                                            // 单图显示 - 与主视图保持一致
                                            Image(nextPost.images[0])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxHeight: 230)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .padding(.horizontal, 16)
                                                .padding(.bottom, 10)
                                        } else if nextPost.images.count == 2 {
                                            // 两张图片并排显示
                                            HStack(spacing: 6) {
                                                ForEach(0..<2, id: \.self) { index in
                                                    Image(nextPost.images[index])
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(height: 160)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 10)
                                        } else if nextPost.images.count == 3 {
                                            // 三张图片布局 - 左侧一张大图，右侧两张小图
                                            let totalWidth = UIScreen.main.bounds.width - 32 // 考虑边距
                                            let smallImageSize = (totalWidth * 0.33) - 2 // 右侧小图尺寸
                                            let largeImageSize = (totalWidth * 0.67) - 2 // 左侧大图尺寸
                                            
                                            HStack(spacing: 6) {
                                                // 左侧大图
                                                Image(nextPost.images[0])
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: largeImageSize, height: largeImageSize)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                
                                                // 右侧两张小图垂直排列
                                                VStack(spacing: 6) {
                                                    Image(nextPost.images[1])
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: smallImageSize, height: smallImageSize)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    
                                                    Image(nextPost.images[2])
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: smallImageSize, height: smallImageSize)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 10)
                                        } else {
                                            // 四张及以上图片 - 网格布局
                                            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
                                            let displayCount = min(nextPost.images.count, 9) // 最多显示9张
                                            
                                            LazyVGrid(columns: columns, spacing: 6) {
                                                ForEach(0..<displayCount, id: \.self) { index in
                                                    Image(nextPost.images[index])
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(height: 100)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 10)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // 互动栏 - 简化版本，仅显示图标
                                HStack(spacing: 24) {
                                    // 点赞按钮
                                    HStack(spacing: 4) {
                                        Image(systemName: "heart")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                        Text("\(nextPost.likes)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // 评论按钮
                                    HStack(spacing: 4) {
                                        Image(systemName: "bubble.right")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                        Text("\(nextPost.comments.count)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // 收藏按钮
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    // 更多按钮
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .rotationEffect(.degrees(90))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                
                                // 分隔线
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 16)
                                
                                // 评论区占位
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("评论 \(nextPost.comments.count)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 14)
                                    
                                    // 显示前两条评论
                                    ForEach(nextPost.comments.prefix(2), id: \.id) { comment in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 10) {
                                                // 头像
                                                Image(comment.userAvatar)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 32, height: 32)
                                                    .clipShape(Circle())
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    // 用户名
                                                    Text(comment.username)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(DesignSystem.Colors.commentPrimaryText)
                                                    
                // 评论内容
                Text(comment.content)
                    .font(DesignSystem.Typography.commentText)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineSpacing(6)
                                                }
                                                
                                                Spacer()
                                            }
                                            
                                            // 评论时间和点赞
                                            HStack {
                                                Text(comment.getFormattedTimeAgo())
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                                
                                                Spacer()
                                                
                                                // 点赞图标
                                                Image(systemName: "heart")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                                
                                                // 点赞数
                                                Text("\(comment.likes)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.leading, 42) // 与头像对齐
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    
                                    // 查看更多评论
                                    if nextPost.comments.count > 2 {
                                        Button(action: {}) {
                                            Text("查看更多评论")
                                                .font(.system(size: 14))
                                                .foregroundColor(FPDVDesignSystem.Colors.primary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                        }
                                    }
                                    
                                    // 底部间距
                                    Spacer(minLength: 60)
                                }
                            }
                        }
                    }
                    .offset(x: swipeDirection == .left ? -UIScreen.main.bounds.width + dampedOffset : UIScreen.main.bounds.width + dampedOffset)
                    .opacity(0.95) // 稍微降低透明度，增强层次感
                    .transition(.opacity)
                }
                
                // 主内容视图 - 使用ZStack包装以便添加固定的顶部导航栏
                ZStack(alignment: .top) {
                    // 滚动内容
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            ScrollViewReader { scrollProxy in
                                VStack(spacing: 0) {
                                    // 顶部锚点，用于滚动到顶部
                                    Color.clear
                                        .frame(height: 1)
                                        .id("scroll_top_\(viewModel.post.id.uuidString)")
                                    
                                    // 添加一个空白区域代替标题栏的高度
                                    Color.clear
                                        .frame(height: 44 + getSafeAreaTop())
                                    
                                    // 整体内容区域使用相同背景色
                                    VStack(spacing: 0) {
                                        // 帖子内容
                                        makePostContent()
                                        
                                        // 帖子互动栏
                                        makeInteractionBar()
                                        
                                        // 分隔线
                                        makeContentDivider()
                                        
                                        // 评论区
                                        makeCommentsSection()
                                            .id("comments_\(viewModel.post.id.uuidString)")
                                    }
                                    .background(DesignSystem.Colors.background) // 使用设计系统的统一背景色
                                }
                                // 添加底部安全区域内边距，确保内容不被输入框遮挡
                                .safeAreaInset(edge: .bottom) {
                                    // 输入框占位区域，调整高度从35增加到60，确保足够空间
                                    Color.clear.frame(height: 60)
                                }
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: FullscreenScrollOffsetKey.self,
                                            value: proxy.frame(in: .named("scroll")).minY
                                        )
                                    }
                                )
                                .onChange(of: viewModel.post.id) { _, _ in
                                    // 当帖子ID变化时，立即滚动到顶部（无动画）
                                    scrollProxy.scrollTo("scroll_top_\(viewModel.post.id.uuidString)", anchor: .top)
                                }
                                // 在视图出现时立即滚动到顶部
                                .onAppear {
                                    // 无动画滚动到顶部
                                    scrollProxy.scrollTo("scroll_top_\(viewModel.post.id.uuidString)", anchor: .top)
                                }
                            }
                        }
                        .scrollDisabled(isTransitioning) // 在过渡期间禁用滚动
                        .scrollIndicators(.hidden) // 隐藏滚动指示器
                        .coordinateSpace(name: "scroll")
                        .offset(x: dragOffset)
                        // 优化不透明度变化，更平滑过渡 - 随着拖动逐渐降低透明度
                        .opacity(isTransitioning ? 
                            (abs(dragOffset) > UIScreen.main.bounds.width * 0.8 ? 0.3 : 
                             1.0 - min(0.7, abs(dragOffset) / UIScreen.main.bounds.width)) 
                            : 1.0)
                        
                        // 评论输入视图 - 放在ZStack底部，确保它在滚动内容上方但不遮挡
                        CommentInputView(commentManager: viewModel.commentManager)
                    }
                    
                    // 固定的顶部导航栏
                    makeTopBar()
                        .background(
                            // 根据滚动位置调整标题栏背景透明度 - 使用渐变背景增加层次感
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DesignSystem.Colors.background,
                                    DesignSystem.Colors.background.opacity(0.98)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .opacity(titleBarBackgroundOpacity)
                        )
                        .zIndex(1) // 确保标题栏始终在最上层
                }
            }
            .onPreferenceChange(FullscreenScrollOffsetKey.self) { offset in
                // 计算标题栏背景透明度
                let threshold: CGFloat = 50 // 滚动多少距离开始变化
                let opacity = min(1, max(0, -offset / threshold))
                withAnimation(.easeOut(duration: 0.2)) {
                    titleBarBackgroundOpacity = opacity
                }
            }
            
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
            .wechatStyleImageViewer(
                isPresented: $showingExpandedImage,
                images: viewModel.post.images,
                initialIndex: selectedImageIndex
            )
            
            // 添加水平滑动手势 - 使用高优先级手势以减少冲突
            // 使用 simultaneousGesture 而不是 gesture，避免拦截按钮点击
            .simultaneousGesture(
                // 优化最小滑动距离，提高水平滑动识别精度
                DragGesture(minimumDistance: 20) // 增加 minimumDistance，避免拦截点击事件
                    .onChanged { value in
                        // 如果正在过渡动画中，忽略所有手势
                        guard !isTransitioning else { return }
                        
                        // 检查是否有输入框正在获取焦点，如果有则忽略滑动手势
                        guard !isAnyTextInputActive() else { return }
                        
                        // 增强水平滑动识别条件，减少与垂直滚动和图片点击的冲突
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)
                        let isHorizontalSwipe = horizontalDistance > verticalDistance * 1.2 && horizontalDistance > 20 // 增加阈值，避免拦截点击
                        
                        if isHorizontalSwipe {
                            // 使用平滑函数计算拖动偏移量，边缘阻尼效应
                            let rawOffset = value.translation.width
                            let screenWidth = UIScreen.main.bounds.width
                            
                            // 应用边缘阻尼效应：随着接近边缘，移动变得更困难
                            // 使用非线性函数，避免在边缘产生突变
                            let dampedOffset: CGFloat
                            if abs(rawOffset) > screenWidth * 0.5 {
                                // 超过半屏时应用强阻尼
                                let overThreshold = abs(rawOffset) - screenWidth * 0.5
                                let damping = max(0.25, 1.0 - (overThreshold / (screenWidth * 0.5)) * 0.75)
                                let dampedOverThreshold = overThreshold * damping
                                dampedOffset = (rawOffset > 0 ? 1 : -1) * (screenWidth * 0.5 + dampedOverThreshold)
                            } else {
                                // 半屏内线性响应，但稍微增加系数使滑动更流畅
                                dampedOffset = rawOffset * 1.05
                            }
                            
                            // 只在拖动状态发生实质变化时更新UI
                            let dragChanged = !isDragging || abs(dampedOffset - dragOffset) > 1.0
                            if dragChanged {
                                // 使用withAnimation包装状态更新，使视图变化更平滑
                                // 使用更轻量的响应式动画，减少延迟感
                                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1)) {
                                    dragOffset = dampedOffset
                                    
                                    // 设置拖动状态
                                    if !isDragging {
                                        isDragging = true
                                        
                                        // 在拖动开始时提供轻微的触觉反馈
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred(intensity: 0.3)
                                    }
                                    
                                    // 更新滑动方向，但避免频繁切换
                                    let newDirection: SwipeDirection = dampedOffset > 20 ? .right : 
                                                                      dampedOffset < -20 ? .left : .none
                                                                      
                                    // 只在方向确实改变时更新，避免频繁状态变化
                                    if newDirection != swipeDirection && 
                                       // 额外的稳定性检查：防止在临界点附近反复切换
                                       (abs(dampedOffset) < 10 || abs(dampedOffset) > 30) {
                                        swipeDirection = newDirection
                                        
                                        // 改进：提前开始准备下一页，加快显示速度
                                        if newDirection != .none {
                                            // 提前加载下一页数据，但仅加载直接相邻的帖子
                                            let prepareNewPost = {
                                                // 确保只预加载相邻帖子
                                                if newDirection == .left, let onNextPost = onNextPost {
                                                    if nextPagePost == nil {
                                                        let directNextPost = onNextPost(viewModel.post.id)
                                                        if let nextPost = directNextPost {
                                                            // 验证是直接相邻的帖子
                                                            let currentPostId = viewModel.post.id
                                                            if nextPost.id != currentPostId {
                                                                nextPagePost = nextPost
                                                                // 预加载图片和评论
                                                                Task { 
                                                                    await Task.yield() // 让UI优先更新
                                                                    _ = await preloadImagesForPostAsync(nextPost)
                                                                    _ = await preloadCommentsForPostAsync(nextPost)
                                                                }
                                                            }
                                                        }
                                                    }
                                                } else if newDirection == .right, let onPrevPost = onPrevPost {
                                                    if nextPagePost == nil {
                                                        let directPrevPost = onPrevPost(viewModel.post.id)
                                                        if let prevPost = directPrevPost {
                                                            // 验证是直接相邻的帖子
                                                            let currentPostId = viewModel.post.id
                                                            if prevPost.id != currentPostId {
                                                                nextPagePost = prevPost
                                                                // 预加载图片和评论
                                                                Task {
                                                                    await Task.yield() // 让UI优先更新
                                                                    _ = await preloadImagesForPostAsync(prevPost)
                                                                    _ = await preloadCommentsForPostAsync(prevPost)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            // 在后台线程执行，不阻塞UI
                                            DispatchQueue.global(qos: .userInitiated).async(execute: prepareNewPost)
                                        }
                                        
                                        // 显示或隐藏时空效果 - 滑动方向变化且明显滑动才显示
                                        if newDirection != .none && abs(dampedOffset) > screenWidth * 0.12 {
                                            // 显示穿越时空效果
                                            if !showingTimeSpaceEffect {
                                                // 使用更快的淡入动画
                                                withAnimation(.easeIn(duration: 0.05)) {
                                                    self.showingTimeSpaceEffect = true
                                                    self.timeSpaceDirection = newDirection
                                                }
                                                
                                                // 设置更短的动画展示时间，加快体验
                                                let displayDuration: TimeInterval = 0.5 // 缩短到0.5秒
                                                let fadeOutDuration: TimeInterval = 0.2
                                                
                                                // 动画结束后淡出
                                                DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                                                    withAnimation(.easeOut(duration: fadeOutDuration)) {
                                                        self.showingTimeSpaceEffect = false
                                                    }
                                                }
                                            }
                                        } else if showingTimeSpaceEffect {
                                            // 隐藏时空效果
                                            withAnimation(.easeOut(duration: 0.1)) {
                                                showingTimeSpaceEffect = false
                                            }
                                        }
                                    }
                                    
                                    // 改进：提前显示下一页，加快过渡
                                    if abs(dampedOffset) > screenWidth * 0.3 && nextPagePost != nil && !nextPageVisible {
                                        // 当拖动超过30%屏幕宽度且已有下一页内容时，提前显示
                                        withAnimation(.easeIn(duration: 0.1)) {
                                            nextPageVisible = true
                                        }
                                    } else if abs(dampedOffset) < screenWidth * 0.25 && nextPageVisible {
                                        // 拖动低于阈值时隐藏
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            nextPageVisible = false
                                        }
                                    }
                                    
                                    // 根据滑动位置更新时空效果的显示
                                    if abs(dampedOffset) > screenWidth * 0.15 && !showingTimeSpaceEffect {
                                        // 达到阈值但还未显示
                                        withAnimation(.easeIn(duration: 0.1)) {
                                            showingTimeSpaceEffect = true
                                            timeSpaceDirection = newDirection
                                        }
                                    } else if abs(dampedOffset) < screenWidth * 0.12 && showingTimeSpaceEffect {
                                        // 低于阈值且正在显示
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            showingTimeSpaceEffect = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        // 如果未处于拖动状态或正在过渡，直接返回
                        guard isDragging && !isTransitioning else { 
                            // 确保重置状态
                            isDragging = false
                            return 
                        }
                        
                        // 判断是否执行翻页
                        let finalOffset = dragOffset
                        let screenWidth = UIScreen.main.bounds.width
                        let velocityX = value.velocity.width
                        
                        // 计算用户滑动速度的绝对值，用于后续动画时长调整
                        let speedAbsolute = abs(velocityX)
                        
                        // 在手势结束时检查是否为最后一篇帖子
                        checkBoundaries()
                        
                        // 简化滑动有效性判断 - 降低触发阈值以避免卡住
                        // 右滑判断
                        let validRightSwipe = finalOffset > screenWidth * 0.12 || (finalOffset > screenWidth * 0.05 && velocityX > 150)
                        
                        // 左滑判断 - 进一步降低触发阈值，使左滑更容易触发
                        let validLeftSwipe = finalOffset < -screenWidth * 0.08 || (finalOffset < -screenWidth * 0.02 && velocityX < -100)
                        
                        // 重置拖动状态 - 提前重置，防止状态锁定
                        isDragging = false
                        
                        // 防卡住保障 - 如果页面在滑出一半以上时卡住，强制进行翻页
                        let forceTransitionThreshold = screenWidth * 0.4
                        let forceLeftTransition = finalOffset < -forceTransitionThreshold
                        let forceRightTransition = finalOffset > forceTransitionThreshold
                        
                        // 虫洞探索页面右滑返回
                        if showAddContentView && (validRightSwipe || forceRightTransition) {
                            // 振动反馈
                            let feedback = UIImpactFeedbackGenerator(style: .light)
                            feedback.impactOccurred()
                            
                            // 关闭添加内容页面，带有完整的滑出动画
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showAddContentView = false
                            }
                            
                            // 重置拖动状态
                            dragOffset = 0
                            swipeDirection = .none
                            
                            // 恢复完整状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // 成功返回最后一篇帖子后，可以继续让用户向右滑动浏览前面的帖子
                                checkBoundaries()
                            }
                            return
                        }
                        
                        // 最后一篇帖子左滑 - 显示添加内容页面
                        if (validLeftSwipe || forceLeftTransition) && isLastPost {
                            // 添加振动反馈
                            let feedback = UIImpactFeedbackGenerator(style: .medium)
                            feedback.impactOccurred()
                            
                            // 显示虫洞探索页面
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                dragOffset = 0
                                showAddContentView = true
                            }
                            return
                        }
                        // 普通左滑 - 切换到下一篇帖子
                        else if validLeftSwipe || forceLeftTransition {
                            // 直接尝试获取并显示下一篇帖子，简化决策
                            if let onNextPost = onNextPost, let directNextPost = onNextPost(viewModel.post.id) {
                                hasNextPost = true
                                isLastPost = false
                                
                                // 执行过渡，增加立即反馈
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .left, nextPost: directNextPost, velocity: speedAbsolute)
                            }
                            // 如果没有找到下一篇但有缓存
                            else if let nextPost = nextPagePost {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .left, nextPost: nextPost, velocity: speedAbsolute)
                            }
                            // 真的是最后一篇
                            else if isLastPost {
                                // 添加振动反馈
                                let feedback = UIImpactFeedbackGenerator(style: .medium)
                                feedback.impactOccurred()
                                
                                // 显示添加内容页面
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                    showAddContentView = true
                                }
                            }
                            // 状态不一致，复位
                            else {
                                resetPosition()
                            }
                        }
                        // 普通右滑 - 切换到上一篇帖子
                        else if validRightSwipe || forceRightTransition {
                            // 检查是否为第一篇帖子，如果是也显示探索虫洞深处页面
                            if isFirstPost {
                                // 添加振动反馈
                                let feedback = UIImpactFeedbackGenerator(style: .medium)
                                feedback.impactOccurred()
                                
                                // 显示虫洞探索页面
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                    showAddContentView = true
                                }
                                return
                            }
                            // 对于非首篇帖子，保持原有的向前翻页逻辑
                            // 直接尝试获取并显示上一篇帖子，简化决策
                            else if let onPrevPost = onPrevPost, let directPrevPost = onPrevPost(viewModel.post.id) {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .right, nextPost: directPrevPost, velocity: speedAbsolute)
                            }
                            // 如果没有找到上一篇但有缓存
                            else if let prevPost = nextPagePost {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .right, nextPost: prevPost, velocity: speedAbsolute)
                            }
                            // 没有上一篇
                            else {
                                resetPosition()
                            }
                        } 
                        // 不满足有效滑动条件，恢复原位
                        else {
                            resetPosition()
                        }
                    }
            )
            
            // 添加内容视图 - 在最后一篇帖子左滑时显示
            if showAddContentView {
                ZStack {
                    // 背景 - 使用深紫到黑色的渐变背景
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.08, green: 0.03, blue: 0.15), // 深紫色
                            Color.black
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    // 增强的星空效果
                    ZStack {
                        // 微妙的星星
                        ForEach(0..<100) { _ in
                            Circle()
                                .fill(DesignSystem.Colors.background.opacity(Double.random(in: 0.1...0.5)))
                                .frame(width: CGFloat.random(in: 1...2.5), height: CGFloat.random(in: 1...2.5))
                                .position(
                                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                                )
                        }
                        
                        // 彩色微弱星星 - 与应用图标配色呼应
                        ForEach(0..<25) { _ in
                            Circle()
                                .fill(Color(
                                    red: Double.random(in: 0.5...0.8),
                                    green: Double.random(in: 0.5...0.8),
                                    blue: Double.random(in: 0.8...1.0)
                                ).opacity(Double.random(in: 0.1...0.3)))
                                .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                                .position(
                                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                                )
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 0) {
                        // 顶部区域 - 使用ZStack而不是HStack进行绝对定位
                        ZStack(alignment: .center) {
                            // 透明背景确保布局稳定
                            Color.clear
                                .frame(height: 44)
                                .padding(.top, getSafeAreaTop())
                            
                            // 标题 - 使用GeometryReader确保精确居中
                            GeometryReader { geometry in
                                VStack(spacing: 5) {
                                    Text("探索虫洞深处")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: geometry.size.width, alignment: .center)
                                    
                                    // 删除副标题
                                }
                                .position(
                                    x: geometry.size.width / 2,
                                    y: getSafeAreaTop() + 22
                                )
                            }
                        }
                        
                        // 使用Spacer进行自动分配空间
                        Spacer()
                            .frame(minHeight: 0)
                        
                        // 顶部间距 - 保持原有间距
                        Spacer()
                            .frame(height: UIScreen.main.bounds.height * 0.05)
                        
                        // 黑洞主视觉 - 保持原有高度
                        BlackHoleView(onCenterPositionChanged: { position in
                            blackHoleCenterPosition = position
                        })
                            .environmentObject(CreationTypeManager.shared)
                            .frame(height: UIScreen.main.bounds.height * 0.38)
                            .padding(.bottom, 16)
                            .frame(width: UIScreen.main.bounds.width) // 确保黑洞视图宽度充满屏幕
                        
                        // 固定高度的Spacer，保持原有间距
                        Spacer()
                            .frame(height: UIScreen.main.bounds.height * 0.04)
                        
                        // 文字提示和选择组件的容器 - 使用固定位置
                        ZStack {
                            // 文字内容 - 仅在非虫洞共鸣时显示
                            ZStack {
                                // 背景轻微高亮
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.03),
                                            Color(red: 0.58, green: 0.44, blue: 0.86, opacity: 0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.15),
                                                    Color.white.opacity(0.05)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                                .frame(width: 332, height: 32)
                            
                                // 文字内容
                            Text("每种内容类型将带你进入不同的时空交流维度")
                                .font(.system(size: 13, weight: .light, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                    .tracking(0.8)
                                .multilineTextAlignment(.center)
                                .frame(width: 300)
                                .shadow(color: Color.black.opacity(0.5), radius: 0.5, x: 0, y: 0.5)
                                    .shadow(color: Color.white.opacity(0.1), radius: 2, x: 0, y: 0)
                            }
                            .opacity(creationTypeManager.selectedIndex != 0 ? 1.0 : 0.0)
                            
                            // 情境和期望选择组件 - 仅在虫洞共鸣时显示（优化版本）
                            if creationTypeManager.selectedIndex == 0 {
                                // 构建获取黑洞视图中心坐标的几何读取器
                                GeometryReader { geometry in
                                    // 使用自适应布局管理器计算黑洞中心点坐标
                                    let blackHoleCenterX = geometry.size.width / 2
                                    let layoutManager = AdaptiveLayoutManager.shared
                                    let blackHoleCenterY = geometry.size.height * layoutManager.blackHoleCenterYFactor()
                                    
                                    // 获取当前设备方向 - 移除未使用的变量
                                    // let isPortrait = AdaptiveLayoutManager.Orientation.current() == .portrait
                                    
                                    SituationExpectationView(
                                        selectedSituation: $selectedSituation,
                                        selectedExpectation: $selectedExpectation,
                                        situations: situations,
                                        expectations: expectations,
                                        centerPosition: CGPoint(x: blackHoleCenterX, y: blackHoleCenterY) // 传入计算得到的黑洞中心点
                                    )
                                    .frame(width: geometry.size.width, height: geometry.size.width) // 使用屏幕宽度作为高度，创建正方形布局
                                }
                                .frame(height: UIScreen.main.bounds.height * 0.38) // 匹配黑洞视图的高度
                                .offset(y: AdaptiveLayoutManager.shared.componentYOffset()) // 使用自适应布局管理器计算偏移量
                                .zIndex(200) // 确保按钮显示在黑洞上层
                                // 添加设备方向变化监听
                                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                                    // 方向变化时触发重新布局
                                    // 这里不需要额外代码，SwiftUI会自动重新计算GeometryReader中的值
                                }
                            }
                        }
                        .frame(height: 32) // 保持固定容器高度
                        .padding(.bottom, 16)
                        .frame(width: UIScreen.main.bounds.width) // 确保整个容器宽度充满屏幕
                        
                        // 创作类型按钮 - 完全保持原有位置
                        虫遇.CreationTypeButtonsView()
                            .environmentObject(CreationTypeManager.shared)
                            .frame(height: 70)
                            .padding(.bottom, 24)
                            .frame(width: UIScreen.main.bounds.width) // 确保按钮视图宽度充满屏幕
                        
                        // 主按钮 - 开启时空对话
                        Button(action: {
                            // 记录操作开始时间，用于防止可能的重复触发
                            _ = Date() // 如果后续需要，可重新启用
                            
                            // 立即重置所有相关状态
                            showWormholeSwipeIndicator = false
                            
                            // 触发触觉反馈
                            let feedback = UIImpactFeedbackGenerator(style: .medium)
                            feedback.impactOccurred()
                            
                            // 显示时空特效视图 - 使用简化版实现
                            withAnimation {
                                // 设置全屏时空特效
                                showCustomTimeSpaceEffect = true
                            }
                        }) {
                            HStack(spacing: 10) {  // 增加图标与文字间距
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 18))  // 增大图标尺寸
                                    .symbolRenderingMode(.hierarchical) // 使用分层渲染增强图标细节
                                
                                // 保持文字不变，无论选择哪个按钮
                                Text("启动虫洞捕捉")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .tracking(1.2) // 增加字间距，提升未来科技感
                                    .kerning(0.5) // 精细调整字符间距
                                    .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.5) // 微小阴影增强可读性
                            }
                            .foregroundColor(.black)
                            .frame(height: 56)  // 增加按钮高度
                            .frame(width: UIScreen.main.bounds.width * 0.6)  // 增加按钮宽度
                            .background(
                                ZStack {
                                    // 主渐变背景
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color(red: 0.96, green: 0.96, blue: 1.0) // 添加微妙的紫罗兰色调
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    
                                    // 添加轻微的内部光晕效果 
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.5),
                                            Color.clear
                                        ]),
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 150
                                    )
                                    .opacity(0.4)
                                }
                            )  // 增强渐变效果
                            .cornerRadius(28)  // 圆角随高度增加
                            .shadow(
                                color: Color(red: 0.58, green: 0.44, blue: 0.86, opacity: 0.4), 
                                radius: 12, 
                                x: 0, 
                                y: 2
                            )  // 微调阴影透明度
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.9),
                                                Color.white.opacity(0.3)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )  // 增强边框对比度
                        }
                        .padding(.bottom, 40)  // 调整与底部的距离
                        .frame(maxWidth: .infinity) // 确保按钮容器宽度充满屏幕，以实现水平居中
                        
                        // 底部空间，确保布局不贴底
                        Spacer()
                            .frame(minHeight: 0, idealHeight: UIScreen.main.bounds.height * 0.02)
                    }
                }
                .zIndex(300)
                .transition(.opacity) // 使用渐变过渡效果
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .environmentObject(CreationTypeManager.shared)
                // 使用与主视图相同的偏移动画策略
                .offset(x: dragOffset)
                // 不再单独处理虫洞探索页面的wormholePageDragOffset
                .gesture(
                    // 对齐主视图的DragGesture设置，使用同一套手势处理逻辑
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            // 如果正在过渡动画中，忽略所有手势
                            guard !isTransitioning else { return }
                            
                            // 检查是否有输入框正在获取焦点，如果有则忽略滑动手势
                            guard !isAnyTextInputActive() else { return }
                            
                            // 增强水平滑动识别条件，与主视图保持一致
                            let horizontalDistance = abs(value.translation.width)
                            let verticalDistance = abs(value.translation.height)
                            let isHorizontalSwipe = horizontalDistance > verticalDistance * 1.2 && horizontalDistance > 12
                            
                            if isHorizontalSwipe {
                                // 对于右滑和左滑，确保水平滑动为主
                                if value.translation.width > 0 || value.translation.width < 0 {
                                    // 使用与主视图完全相同的拖动偏移量计算方式
                                    let rawOffset = value.translation.width
                                    let screenWidth = UIScreen.main.bounds.width
                                    
                                    // 应用边缘阻尼效应，与主视图完全相同的计算方式
                                    let dampedOffset: CGFloat
                                    if abs(rawOffset) > screenWidth * 0.5 {
                                        // 超过半屏时应用强阻尼
                                        let overThreshold = abs(rawOffset) - screenWidth * 0.5
                                        let damping = max(0.25, 1.0 - (overThreshold / (screenWidth * 0.5)) * 0.75)
                                        let dampedOverThreshold = overThreshold * damping
                                        dampedOffset = (rawOffset > 0 ? 1 : -1) * (screenWidth * 0.5 + dampedOverThreshold)
                                    } else {
                                        // 半屏内线性响应，但稍微增加系数使滑动更流畅
                                        dampedOffset = rawOffset * 1.05
                                    }
                                    
                                    // 使用与主视图相同的动画和状态更新逻辑
                                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1)) {
                                        dragOffset = dampedOffset
                                        
                                        // 设置拖动状态
                                        if !isDragging {
                                            isDragging = true
                                            
                                            // 提供相同的触觉反馈
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred(intensity: 0.3)
                                        }
                                        
                                        // 更新滑动方向
                                        swipeDirection = rawOffset > 0 ? .right : .left
                                        
                                        // 显示时空效果 - 与主视图相同的时空效果
                                        if abs(dampedOffset) > screenWidth * 0.15 && !showingTimeSpaceEffect {
                                            withAnimation(.easeIn(duration: 0.1)) {
                                                showingTimeSpaceEffect = true
                                                timeSpaceDirection = swipeDirection
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .onEnded { value in
                            // 如果未处于拖动状态或正在过渡，直接返回
                            guard isDragging && !isTransitioning else { 
                                // 确保重置状态
                                isDragging = false
                                return 
                            }
                            
                            // 判断是否执行关闭虫洞探索页面
                            let finalOffset = dragOffset
                            let screenWidth = UIScreen.main.bounds.width
                            let velocityX = value.velocity.width
                            
                            // 使用与主视图相同的右滑判断逻辑
                            let validRightSwipe = finalOffset > screenWidth * 0.12 || (finalOffset > screenWidth * 0.05 && velocityX > 150)
                            
                            // 添加左滑判断逻辑，与主视图保持一致
                            let validLeftSwipe = finalOffset < -screenWidth * 0.08 || (finalOffset < -screenWidth * 0.02 && velocityX < -100)
                            
                            // 重置拖动状态 - 提前重置，防止状态锁定
                            isDragging = false
                            
                            // 记录详细调试日志
                            #if DEBUG
                            #endif
                            
                            // 强制过渡阈值，与主视图保持一致
                            let forceTransitionThreshold = screenWidth * 0.4
                            let forceRightTransition = finalOffset > forceTransitionThreshold
                            let forceLeftTransition = finalOffset < -forceTransitionThreshold
                            
                            // 右滑返回
                            if validRightSwipe || forceRightTransition {
                                #if DEBUG
                                #endif
                                
                                // 提供相同的触觉反馈
                                let feedback = UIImpactFeedbackGenerator(style: .light)
                                feedback.impactOccurred()
                                
                                // 关闭添加内容页面，使用与页面转场相同的动画效果
                                // 模拟 performPageTransition 的行为但目标是关闭页面
                                
                                // 设置转场状态
                                isTransitioning = true
                                
                                // 时间参数与页面转场相同
                                let initialEffectDuration: Double = 0.12
                                let slideOutDuration: Double = 0.2
                                
                                // 使用与页面转场相同的动画序列
                                withAnimation(.easeIn(duration: initialEffectDuration)) {
                                    showingTimeSpaceEffect = true
                                    timeSpaceDirection = .right
                                }
                                
                                // 第二阶段动画
                                DispatchQueue.main.asyncAfter(deadline: .now() + initialEffectDuration) {
                                    // 滑出动画 - 使用与页面转场相同的参数
                                    withAnimation(.spring(response: slideOutDuration, dampingFraction: 0.85, blendDuration: 0.08)) {
                                        dragOffset = screenWidth // 向右滑出
                                        showingTimeSpaceEffect = false
                                    }
                                    
                                    // 动画完成后执行状态重置
                                    DispatchQueue.main.asyncAfter(deadline: .now() + slideOutDuration) {
                                        // 关闭虫洞探索页面
                                        showAddContentView = false
                                        
                                        // 重置所有状态
                                        dragOffset = 0
                                        swipeDirection = .none
                                        isTransitioning = false
                                        
                                        // 恢复完整状态
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            // 重置边界
                                            checkBoundaries()
                                        }
                                    }
                                }
                            }
                            // 左滑返回
                            else if validLeftSwipe || forceLeftTransition {
                                #if DEBUG
                                #endif
                                
                                // 提供相同的触觉反馈
                                let feedback = UIImpactFeedbackGenerator(style: .light)
                                feedback.impactOccurred()
                                
                                // 关闭添加内容页面，使用与页面转场相同的动画效果
                                isTransitioning = true
                                
                                // 时间参数与页面转场相同
                                let initialEffectDuration: Double = 0.12
                                let slideOutDuration: Double = 0.2
                                
                                // 使用与页面转场相同的动画序列
                                withAnimation(.easeIn(duration: initialEffectDuration)) {
                                    showingTimeSpaceEffect = true
                                    timeSpaceDirection = .left
                                }
                                
                                // 第二阶段动画
                                DispatchQueue.main.asyncAfter(deadline: .now() + initialEffectDuration) {
                                    // 滑出动画 - 向左滑出
                                    withAnimation(.spring(response: slideOutDuration, dampingFraction: 0.85, blendDuration: 0.08)) {
                                        dragOffset = -screenWidth // 向左滑出
                                        showingTimeSpaceEffect = false
                                    }
                                    
                                    // 动画完成后执行状态重置
                                    DispatchQueue.main.asyncAfter(deadline: .now() + slideOutDuration) {
                                        // 关闭虫洞探索页面
                                        showAddContentView = false
                                        
                                        // 重置所有状态
                                        dragOffset = 0
                                        swipeDirection = .none
                                        isTransitioning = false
                                        
                                        // 恢复完整状态
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            // 重置边界
                                            checkBoundaries()
                                        }
                                    }
                                }
                            } 
                            else {
                                // 不满足右滑条件，复位
                                resetPosition()
                            }
                        }
                )
                .onAppear {
                    // 确保初始状态一致
                    isWormholeDragging = false
                    wormholePageDragOffset = 0
                    showWormholeSwipeIndicator = false
                    
                    // 使用单一的延迟显示滑动指示器
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        // 只有在页面仍然显示且用户没有主动滑动时才显示提示
                        if showAddContentView && !isDragging && dragOffset == 0 {
                            withAnimation(.easeIn(duration: 0.3)) {
                                showWormholeSwipeIndicator = true
                            }
                            
                            // 短暂提示后隐藏
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                // 再次检查状态，避免与用户操作冲突
                                if showWormholeSwipeIndicator && !isDragging {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showWormholeSwipeIndicator = false
                                    }
                                }
                            }
                            
                            // 依次显示左右滑动提示
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                // 确保用户没有正在滑动
                                if showAddContentView && !isDragging && dragOffset == 0 {
                                    withAnimation(.easeIn(duration: 0.3)) {
                                        showWormholeSwipeIndicator = true
                                    }
                                    
                                    // 短暂提示后隐藏
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        // 再次检查状态，避免与用户操作冲突
                                        if showWormholeSwipeIndicator && !isDragging {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                showWormholeSwipeIndicator = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    // 立即重置所有状态
                    showWormholeSwipeIndicator = false
                    dragOffset = 0
                    swipeDirection = .none
                }
            }
            
            // 自定义时空特效覆盖层
            if showCustomTimeSpaceEffect {
                GeometryReader { geometry in
                    let centerPosition = blackHoleCenterPosition ?? {
                    let centerX = geometry.size.width / 2
                        let centerY = geometry.size.height / 2 + geometry.size.height * 0.25 - 290
                        return CGPoint(x: centerX, y: centerY)
                    }()
                    
                    // 使用自定义位置的TimeSpaceEffectView
                    TimeSpaceEffectView(
                        isActive: $showCustomTimeSpaceEffect, 
                        centerPosition: centerPosition
                    ) {
                        // 特效完成后的回调
                        #if DEBUG
                        #endif
                        
                        // 获取选中的创作类型索引
                        let typeIndex = CreationTypeManager.shared.selectedIndex
                        let contentTypeName = CreationTypeManager.shared.types[typeIndex]
                        #if DEBUG
                        #endif
                        
                        // 触发内容生成状态
                        generationStateManager.startGenerating(contentType: contentTypeName)
                        
                        // 关闭详情页面，返回主页
                        showAddContentView = false
                        onDismiss?()
                        
                        // 获取PostViewModel的实例
                        let postViewModel = PostViewModel.shared
                        
                        // 使用Task在异步上下文中生成帖子
                        Task {
                            #if DEBUG
                            #endif
                            
                            // 添加加载状态
                            await MainActor.run {
                                // 在主线程显示加载指示器
                                let feedback = UIImpactFeedbackGenerator(style: .medium)
                                feedback.prepare()
                                feedback.impactOccurred()
                            }
                            
                            // 简化帖子生成逻辑，移除超时限制
                            #if DEBUG
                            #endif
                            var newPosts: [UserPostModel] = []
                            
                            do {
                                // 创建内容生成任务，不再添加超时限制
                                #if DEBUG
                                print("📱 开始生成内容，类型索引: \(typeIndex)")
                                #endif
                                
                                // 直接生成内容，等待直到完成
                                if typeIndex == 0 {
                                    #if DEBUG
                                    print("📱 生成虫洞共鸣内容...")
                                    #endif
                                    // 虫洞共鸣类型
                                    newPosts = try await postViewModel.generateResonancePosts(
                                        situation: selectedSituation,
                                        expectation: selectedExpectation,
                                        keyword: explorationKeyword.isEmpty ? nil : explorationKeyword
                                    )
                                } else {
                                    #if DEBUG
                                    print("📱 生成\(typeIndex)类型内容...")
                                    #endif
                                    // 其他类型
                                    newPosts = try await postViewModel.generatePostsByCreationType(typeIndex: typeIndex)
                                }
                                
                                #if DEBUG
                                print("📱 内容生成完成，获得 \(newPosts.count) 篇帖子")
                                #endif
                                
                            } catch {
                                #if DEBUG
                                print("⚠️ 生成帖子过程出错: \(error.localizedDescription)")
                                #endif
                            }
                            
                            #if DEBUG
                            #endif
                            
                            // 添加到数据模型
                            if !newPosts.isEmpty {
                                #if DEBUG
                                #endif
                                postViewModel.addPosts(newPosts)
                                
                                // 发送通知，通知主页刷新
                                #if DEBUG
                                #endif
                                NotificationCenter.default.post(name: NSNotification.Name("NewPostsGenerated"), object: nil)
                                NotificationCenter.default.post(name: NSNotification.Name("PostsUpdated"), object: nil)
                                
                                // 添加触觉反馈，让用户知道生成成功
                                await MainActor.run {
                                    let successFeedback = UINotificationFeedbackGenerator()
                                    successFeedback.notificationOccurred(.success)
                                }
                            } else {
                                #if DEBUG
                                print("⚠️ 生成的帖子数组为空")
                                #endif
                                // 当生成内容失败时，显示反馈给用户
                                await MainActor.run {
                                    let errorFeedback = UINotificationFeedbackGenerator()
                                    errorFeedback.notificationOccurred(.error)
                                }
                            }
                            
                            // 生成完成后，更新状态
                            await MainActor.run {
                                generationStateManager.finishGenerating()
                                    
                                    // 重置状态
                                    dragOffset = 0
                                    swipeDirection = .none
                                    isTransitioning = false
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .zIndex(1000) // 确保特效显示在最上层
            }
        }
        // 禁用用户交互当正在过渡中
        .disabled(isTransitioning)
        .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all)) // 使用设计系统的统一背景色
        .onAppear {
            // 为视图设置为活跃状态，用于任务循环
            isViewActive = true
            
            // 添加系统级别返回按钮（比SwiftUI原生返回按钮更稳定）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                addSystemLevelBackButton()
            }
            
            // 🚀 性能优化：减少非关键DEBUG日志输出
            
            // 检查初始帖子ID与viewModel中的帖子ID是否一致
            if initialPostId.uuidString != viewModel.post.id.uuidString {
                #if DEBUG
                print("⚠️ 警告：初始帖子ID与viewModel帖子ID不一致！进行强制同步")
                #endif
                // 强制更新viewModel中的帖子 - 这通常不应该发生，但添加以防万一
                viewModel.synchronizePost(id: initialPostId)
            }
            
            // 隐藏TabBar
            tabBarManager.pushHideState()
            
            // 🚀 异步执行边界检查和预加载，确保视图完全加载后运行
            DispatchQueue.main.async {
                checkBoundaries()
                preloadAdjacentPosts()
            }
        }
        .onDisappear {

            // 停止task的循环检查
            isViewActive = false
            
            // 恢复底部标签栏 - 使用popHideState()恢复底部导航栏
            tabBarManager.popHideState()
            
            // 清理返回按钮窗口
            if let window = systemBackButtonWindow {
                // 立即隐藏窗口
                window.isHidden = true
                window.rootViewController?.view.subviews.forEach { $0.removeFromSuperview() }
                window.rootViewController = nil
                
                // 立即清除引用
                systemBackButtonWindow = nil
                
                // 发送消失通知，通知其他可能持有引用的组件
                NotificationCenter.default.post(name: NSNotification.Name("ViewWillDisappear"), object: nil)
            }
        }
        // 添加一个任务，确保无论何时都保持TabBar隐藏状态
        .task {
            // 视图加载后，确保TabBar物理隐藏
            tabBarManager.pushHideState()
            
            // 每隔一段时间检查一次TabBar状态，确保它始终隐藏
            while isViewActive {
                try? await Task.sleep(for: .seconds(2.0)) // 将间隔从0.5秒增加到2秒
                
                // 如果视图已不再活跃，停止循环
                if !isViewActive {
                    break
                }
                
                // 使用isFullyHidden检查是否完全隐藏，如果不是则重新隐藏
                if !tabBarManager.isFullyHidden {
                    #if DEBUG
                    #endif
                    tabBarManager.pushHideState()
                }
            }
            
            // 视图任务结束时确保TabBar可见
            if !isViewActive {
    
                tabBarManager.popHideState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HistoricalFiguresInvited"))) { notification in
            // 从通知中获取帖子ID
            if let postIdString = notification.userInfo?["postId"] as? String,
               let postId = UUID(uuidString: postIdString) {
                
                #if DEBUG
                #endif
                
                // 使用动画添加帖子ID
                let _ = withAnimation {
                    // 只有当前显示的帖子才添加到生成集合中
                    if postId == viewModel.post.id {
                        generatingMediaPostIds.insert(postId)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CommentsGenerated"))) { notification in
            // 从通知中获取帖子ID
            if let postIdString = notification.userInfo?["postID"] as? String,
               let postId = UUID(uuidString: postIdString) {
                
                #if DEBUG
                #endif
                
                // 使用动画移除帖子ID
                let _ = withAnimation {
                    // 从生成集合中移除该帖子
                    generatingMediaPostIds.remove(postId)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostLikeUpdated"))) { notification in
            // 监听帖子点赞更新通知，刷新当前帖子的点赞数
            if let postIdString = notification.userInfo?["postID"] as? String,
               postIdString == viewModel.post.id.uuidString {
                
                #if DEBUG
                #endif
                
                // 从PostViewModel获取最新的帖子数据
                if let updatedPost = PostViewModel.shared.posts.first(where: { $0.id.uuidString == postIdString }) {
                    DispatchQueue.main.async {
                        // 更新当前帖子数据
                        viewModel.updatePost(updatedPost)
            
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CommentLikeUpdated"))) { notification in
            // 监听评论点赞更新通知，刷新当前帖子的评论点赞数
            if let postIdString = notification.userInfo?["postID"] as? String,
               postIdString == viewModel.post.id.uuidString {
                
                #if DEBUG
                print("❤️ FullscreenPostDetailView: 收到CommentLikeUpdated通知，当前帖子的评论点赞数需要更新")
                #endif
                
                // 从PostViewModel获取最新的帖子数据
                if let updatedPost = PostViewModel.shared.posts.first(where: { $0.id.uuidString == postIdString }) {
                    DispatchQueue.main.async {
                        // 更新当前帖子数据，这会刷新所有评论的点赞数
                        viewModel.updatePost(updatedPost)
                        // 同时刷新评论管理器
                        viewModel.commentManager.currentPost = updatedPost
        
                    }
                }
            }
        }
        // 添加角色详情页导航
        .fullScreenCover(item: $navigateToCharacterDetail) { character in
            NavigationView {
                CharacterDetailView(character: convertToCharacter(character))
            }
            .onAppear {
                // 隐藏返回按钮
                systemBackButtonWindow?.isHidden = true
            }
            .onDisappear {
                // 显示返回按钮
                systemBackButtonWindow?.isHidden = false
            }
        }
        .onChange(of: navigateToCharacterDetail) { oldValue, newValue in
            // 当角色详情页状态变化时，控制返回按钮的显示/隐藏
            if newValue != nil {
                // 正在显示角色详情页，隐藏返回按钮
                systemBackButtonWindow?.isHidden = true
            } else {
                // 角色详情页已关闭，显示返回按钮
                systemBackButtonWindow?.isHidden = false
            }
        }
    }
    
    // MARK: - 角色详情页导航辅助函数
    
    /// 根据角色ID或用户名查找角色
    private func findCharacterModel(characterID: String?, username: String?) -> CharacterModel? {
        let allCharacters = CharacterModel.loadAllCharactersWithoutFilter()
        
        // 优先使用 characterID 查找
        if let characterID = characterID {
            if let character = allCharacters.first(where: { $0.id == characterID || $0.characterID == characterID }) {
                return character
            }
        }
        
        // 如果 characterID 找不到，使用 username 查找
        if let username = username {
            if let character = allCharacters.first(where: { $0.name == username }) {
                return character
            }
        }
        
        return nil
    }

    /// 复制帖子内容
    private func copyPostContent() {
        UIPasteboard.general.string = viewModel.post.content
        
        // 触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 显示复制提示
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowToast"),
            object: nil,
            userInfo: ["message": "已复制文字"]
        )
    }
    
    /// 转换 CharacterModel 为 Character（用于详情页）
    private func convertToCharacter(_ characterModel: CharacterModel) -> Character {
        let followManager = FollowManager.shared
        return Character(
            id: characterModel.id,
            name: characterModel.name,
            introduction: characterModel.bio,
            field: characterModel.category.rawValue,
            birthYear: characterModel.era,
            deathYear: "",
            avatarUrl: characterModel.avatar,
            eraTag: characterModel.era,
            achievements: [characterModel.profession],
            mainWorks: [],
            keyThoughts: [],
            followerCount: Int.random(in: 1000...5000),
            interactionCount: Int.random(in: 5000...15000),
            rating: Double.random(in: 4.0...5.0),
            isFavorited: followManager.isFollowing(characterModel.name)
        )
    }
    
    /// 检查帖子是否是虚拟角色发布的
    private var isPostByVirtualCharacter: Bool {
        let post = viewModel.post
        // 判断帖子是否是虚拟角色发布的（characterID != nil 且 username 不是"当前用户"）
        // 简化判断：只要有 characterID 就认为是虚拟角色
        if let characterID = post.characterID, !characterID.isEmpty {
            return post.username != "当前用户"
        }
        return false
    }
    
    // MARK: - 子视图组件
    
    // 添加系统级返回按钮
    private func addSystemLevelBackButton() {
        // 计算顶部安全区域高度，为返回按钮定位
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = windowScene?.windows.first?.safeAreaInsets.top ?? 44
        
        // 创建新窗口 - 只覆盖左上角返回按钮区域
        let buttonWindow = UIWindow(frame: CGRect(
            x: 0,
            y: 0,
            width: 50,
            height: topPadding + 44
        ))
        buttonWindow.tag = 9999 // 为后续标识设置tag
        
        // 设置窗口属性
        buttonWindow.isUserInteractionEnabled = true
        buttonWindow.windowLevel = .alert // 使用高层级确保可见
        buttonWindow.backgroundColor = .clear
        buttonWindow.accessibilityViewIsModal = false
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            buttonWindow.windowScene = windowScene
        }
        
        // 设置根视图控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        buttonWindow.rootViewController = viewController
        
        // 配置返回按钮
        let backButton = UIButton(type: .system)
        // 使用与私聊页面一致的按钮位置和尺寸，符合苹果设计规范
        // 按钮垂直居中在44点高的导航栏中：(44 - 30) / 2 = 7，加上视觉平衡调整为10
        backButton.frame = CGRect(x: 16, y: topPadding + 10, width: 30, height: 30)
        
        // 设置按钮图标 - 使用与私聊页面一致的尺寸
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: imageConfig)
        backButton.setImage(image, for: .normal)
        
        // 使用主题色
        backButton.tintColor = UIColor(red: 140/255, green: 105/255, blue: 158/255, alpha: 1.0) // 主色调紫色
        
        // 简化样式 - 使用 iOS 15 推荐的方式
        backButton.backgroundColor = .clear
        
        if #available(iOS 15.0, *) {
            // 使用 UIButton.Configuration 代替过时的属性
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets.zero
            config.image = image
            config.imagePlacement = .leading
            config.imagePadding = 0
            backButton.configuration = config
        } else {
            // 旧版本 iOS 保持使用旧 API
        backButton.contentEdgeInsets = UIEdgeInsets.zero
        backButton.imageEdgeInsets = UIEdgeInsets.zero
        backButton.imageView?.contentMode = .scaleAspectFit
        }
        
        // 直接设置为完全显示状态，不使用动画
        backButton.alpha = 1.0
        backButton.transform = .identity
        
        // 设置点击事件
        backButton.addAction(UIAction { _ in
            
            
            // 添加轻微的动画效果
            UIView.animate(withDuration: 0.1, animations: {
                backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    backButton.transform = CGAffineTransform.identity
                })
            }
            
            // 触发轻柔触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 立即隐藏按钮窗口
            if let window = systemBackButtonWindow {
                window.isHidden = true
            }
            
            // 执行返回操作
            if let onDismiss = onDismiss {
                onDismiss()
                // 确保使用自定义关闭回调时也恢复底部导航栏
                tabBarManager.popHideState()
            } else {
                // 返回策略
                // 1. 尝试使用NavigationHelper返回
                FPDVNavigationHelper.shared.forceGoBack()
                
                // 2. 发送通知
                NotificationCenter.default.post(name: NSNotification.Name("DismissCurrentViewController"), object: nil)
                
                // 3. 直接查找并使用顶层视图控制器的返回方法
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let topVC = window.rootViewController?.topMostViewController {
                    
                    if let navigationController = topVC.navigationController {
                        navigationController.popViewController(animated: true)
                    } else {
                        topVC.dismiss(animated: true)
                    }
                }
                
                // 4. 使用环境变量
                dismiss()
                presentationMode.wrappedValue.dismiss()
                
                // 5. 恢复底部导航栏显示 - 添加此行解决TabBar不显示问题
                tabBarManager.popHideState()
            }
            
            // 彻底移除窗口和引用
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let window = systemBackButtonWindow {
                    window.isHidden = true
                    window.rootViewController = nil
                    
                    DispatchQueue.main.async {
                        systemBackButtonWindow = nil
                    }
                }
            }
        }, for: .touchUpInside)
        
        // 添加到视图控制器的视图
        viewController.view.addSubview(backButton)
        
        // 保存窗口引用并显示
        systemBackButtonWindow = buttonWindow
        buttonWindow.makeKeyAndVisible()
        
        // 确保按钮立即可见 - 强制布局更新
        viewController.view.layoutIfNeeded()
    }
    
    // 顶部导航栏 - 优化版本 (UI优化项#1)
    private func makeTopBar() -> some View {
        HStack(spacing: 16) {
            // 占位区域，保持布局平衡（与返回按钮宽度一致）
            Color.clear
                .frame(width: 50, height: 44)
                             
            Spacer()
                             
            // 标题 - 居中，在44点高的导航栏中垂直居中
            // 17号字体高度约22点，在44点高的导航栏中垂直居中
            Text("动态详情")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(height: 44, alignment: .center)  // 设置固定高度并垂直居中
             
            Spacer()
                             
            // 占位区域，保持布局平衡（与分享按钮宽度一致）
            Color.clear
                .frame(width: 55, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)  // 导航栏固定高度44点
        .padding(.top, getSafeAreaTop())
        .background(
            // 背景 - 根据滚动状态改变透明度
            Rectangle()
                .fill(DesignSystem.Colors.background)
                .opacity(isScrolled ? 0.9 : 1.0)
                .edgesIgnoringSafeArea(.top)
        )
    }
    
    // 获取顶部安全区域高度
    private func getSafeAreaTop() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
    }
    
    // 帖子内容区域
    private func makePostContent() -> some View {
        VStack(spacing: 0) {
            // 用户头像和信息区域
            makeUserInfoSection()
                .zIndex(10) // 确保用户信息区域在最上层，不被其他手势拦截
            
            // 帖子内容区域
            makePostContentSection()
        }
        .padding(.vertical, 10) // 整体垂直内边距
        .id("post_content_\(viewModel.post.id.uuidString)")
    }
    
    // 用户头像和信息区域
    private func makeUserInfoSection() -> some View {
        // 计算是否是虚拟角色
        // 即使 characterID 是 nil，也尝试通过 username 查找角色
        let isNotCurrentUser = viewModel.post.username != "当前用户"
        
        // 尝试通过 username 查找角色（即使 characterID 是 nil）
        let allCharacters = CharacterModel.loadAllCharactersWithoutFilter()
        let foundCharacter = allCharacters.first { $0.name == viewModel.post.username }
        let isVirtualCharacter = isNotCurrentUser && foundCharacter != nil
        
        return HStack(spacing: 12) {
            // 头像 - 使用我们统一的Avatar组件
            // 如果是虚拟角色发布的帖子，头像可点击进入角色详情页
            // 使用与评论中完全相同的方式：Button + PlainButtonStyle + frame
            
            // 🔒 修复：对于用户创建的角色，使用characterID作为url，以便正确加载头像
            let avatarURL: String = {
                // 优先使用characterID（如果是custom_开头）
                if let characterID = viewModel.post.characterID, characterID.hasPrefix("custom_") {
                    // 用户创建的角色：使用角色ID作为url，CustomAvatarLoader会根据ID加载头像
                    #if DEBUG
                    print("🔍 FullscreenPostDetailView: 用户创建的角色 - characterID: \(characterID)")
                    #endif
                    return characterID
                } else {
                    // 其他角色：使用原始avatar值
                    return viewModel.post.userAvatar
                }
            }()
            
            if isVirtualCharacter, let character = foundCharacter {
                Button(action: {
                    // 直接使用找到的角色
                    navigateToCharacterDetail = character
                }) {
                    Avatar(url: avatarURL, size: 40)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Avatar(url: avatarURL, size: 40)
            }
            
            // 用户名和时间
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.post.username)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(viewModel.post.getFormattedTimeAgo())
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 关注按钮 - 可点击并切换状态
            Button(action: {
                // 触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.5)
                
                // 使用统一的FollowManager切换关注状态
                let newFollowStatus = FollowManager.shared.toggleFollow(for: viewModel.post.username)
                isFollowed = newFollowStatus
                
                // 显示提示信息
                let toastMessage = isFollowed ? "已关注 \(viewModel.post.username)" : "已取消关注 \(viewModel.post.username)"
                
                // 发送通知更新UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowToast"),
                    object: nil,
                    userInfo: ["message": toastMessage]
                )
            }) {
                Text(isFollowed ? "已关注" : "关注")
                    .font(.system(size: 14))
                    .foregroundColor(isFollowed ? .secondary : FPDVDesignSystem.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        isFollowed 
                            ? Color.secondary.opacity(0.06) 
                            : FPDVDesignSystem.Colors.primary.opacity(0.08)
                    )
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .id("user_info_section_\(viewModel.post.id.uuidString)")
        .onAppear {
            // 在视图出现时检查关注状态
            checkFollowStatus()
        }
    }
    
    // 添加检查关注状态的函数
    private func checkFollowStatus() {
        // 使用统一的FollowManager检查关注状态
        isFollowed = FollowManager.shared.isFollowing(viewModel.post.username)
    }
    
    // 帖子内容区域
    private func makePostContentSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 帖子文字内容
            if !viewModel.post.content.isEmpty {
                let textLeadingPadding = calculateDynamicPadding(text: viewModel.post.content)
                
                Text(viewModel.post.content)
                    .font(DesignSystem.Typography.postContent)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineSpacing(6.0)
                    .multilineTextAlignment(.leading) // 🔒 修复：用户发布的文字帖子左对齐
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading) // 🔒 修复：确保文字左对齐
                    .padding(.leading, textLeadingPadding)
                    .padding(.trailing, 16)
                    .padding(.vertical, 12)
                    .id("post_text_content_\(viewModel.post.id.uuidString)")
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 12) {
                        copyPostContent()
                    }
                    .contextMenu {
                        Button {
                            copyPostContent()
                        } label: {
                            Label("复制文字", systemImage: "doc.on.doc")
                        }
                    }
            }
            
            // 图片内容区域 - 微信朋友圈风格
            if !viewModel.post.images.isEmpty {
                switch viewModel.post.images.count {
                case 1:
                    singleImageView(viewModel.post.images[0])
                        .id("image_section_\(viewModel.post.id.uuidString)")
                case 2:
                    wechatStyleGridLayout(images: viewModel.post.images, columns: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .id("image_section_\(viewModel.post.id.uuidString)")
                case 3:
                    wechatStyleGridLayout(images: viewModel.post.images, columns: 3)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .id("image_section_\(viewModel.post.id.uuidString)")
                case 4:
                    wechatStyleGridLayout(images: viewModel.post.images, columns: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .id("image_section_\(viewModel.post.id.uuidString)")
                case 5, 6:
                    wechatStyleGridLayout(images: viewModel.post.images, columns: 3)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .id("image_section_\(viewModel.post.id.uuidString)")
                default:
                    wechatStyleGridLayout(images: viewModel.post.images, columns: 3)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .id("image_section_\(viewModel.post.id.uuidString)")
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    // 单图显示 - 微信朋友圈风格
    private func singleImageView(_ imageName: String) -> some View {
        GeometryReader { geometry in
            // 修改为靠左对齐但有适当的左边距
            HStack {
                // 使用手势代替Button，优化触摸响应
                ZStack {
                    if imageName.contains("_image_") {
                        // 用户上传的图片
                        PostImageView(
                            imageId: imageName,
                            contentMode: .fit,
                            height: calculateSingleImageHeight(for: imageName, width: geometry.size.width * 0.85), // 调整为85%宽度
                            cornerRadius: 3 // 微信风格的小圆角
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                        )
                    } else if let uiImage = UIImage(named: imageName) {
                        // 内置图片资源
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width * 0.85) // 限制最大宽度为容器的85%
                            .frame(maxHeight: calculateSingleImageHeight(for: imageName, width: geometry.size.width * 0.85))
                            .cornerRadius(3)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                            )
                    } else {
                        // 占位图 - 精简版实现
                        ZStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(maxWidth: geometry.size.width * 0.85) // 限制最大宽度
                                .cornerRadius(3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                                )
                            
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                                
                                Text("图片加载失败")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(height: 180) // 设置默认高度
                    }
                }
                .contentShape(Rectangle()) // 确保整个区域可以接收手势
                .onTapGesture {
                    // 只有在非滑动状态下才响应点击
                    guard !isDragging else { return }
                    
                    selectedImageIndex = 0
                    showingExpandedImage = true
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.5)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.leading, 16) // 添加左边距，与文本内容对齐
        }
        .frame(height: calculateImageSectionHeight(for: [imageName]))
        .padding(.top, 8) // 添加顶部间距，使布局更加美观
    }
    
    // 微信朋友圈风格的网格布局
    private func wechatStyleGridLayout(images: [String], columns: Int) -> some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let spacing: CGFloat = 2 // 微信风格的小间距
            
            // 计算每个图片的尺寸
            let itemWidth = (totalWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
            
            // 计算行数
            let rows = Int(ceil(Double(images.count) / Double(columns)))
            
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { column in
                            let index = row * columns + column
                            if index < images.count {
                                wechatStyleImageItem(images[index], size: itemWidth)
                                    .contentShape(Rectangle()) // 确保整个区域可以接收手势
                                    .onTapGesture {
                                        // 只有在非滑动状态下才响应点击
                                        guard !isDragging else { return }
                                        
                                        selectedImageIndex = index
                                        showingExpandedImage = true
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred(intensity: 0.5)
                                    }
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
        .frame(height: calculateGridHeight(imagesCount: images.count, columns: columns))
    }
    
    // 微信风格的单个图片项
    private func wechatStyleImageItem(_ imageName: String, size: CGFloat) -> some View {
        Group {
            if imageName.contains("_image_") {
                // 用户上传的图片
                PostImageView(
                    imageId: imageName,
                    contentMode: .fill,
                    cornerRadius: 3
                )
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                )
            } else if let uiImage = UIImage(named: imageName) {
                // 内置图片
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .cornerRadius(3)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                    )
            } else {
                // 占位图
                ZStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .cornerRadius(3)
                    
                    ProgressView()
                        .scaleEffect(1.0)
                }
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
                )
            }
        }
    }
    
    // 计算单图高度
    private func calculateSingleImageHeight(for imageName: String, width: CGFloat) -> CGFloat {
        // 用户上传的图片用固定高度
        if imageName.contains("_image_") {
            return 200.0 // 微信朋友圈单图高度
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
        calculatedHeight = min(max(calculatedHeight, 120.0), 220.0)
        
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
    
    // 计算网格布局的高度
    private func calculateGridHeight(imagesCount: Int, columns: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 32 // 考虑边距
        let spacing: CGFloat = 2 // 微信风格的小间距
        let itemWidth = (screenWidth - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
        
        // 计算行数
        let rows = Int(ceil(Double(imagesCount) / Double(columns)))
        
        // 计算总高度 = 行数 * 单元格高度 + (行数-1) * 间距
        return (CGFloat(rows) * itemWidth) + (CGFloat(rows - 1) * spacing)
    }
    
    // 帖子互动栏
    private func makeInteractionBar() -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // 点赞按钮 - 左侧
                Button(action: {
                    // 添加触觉反馈
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred(intensity: 0.4)
                    
                    // 更新点赞状态
                    viewModel.toggleLike()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: likeStateManager.isLiked(viewModel.post.id.uuidString) ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(likeStateManager.isLiked(viewModel.post.id.uuidString) ? .red : .secondary)
                        
                        Text("\(viewModel.post.likes)")
                            .font(.system(size: 13))
                            .foregroundColor(likeStateManager.isLiked(viewModel.post.id.uuidString) ? .red.opacity(0.8) : .secondary)
                    }
                    .frame(minWidth: 50, alignment: .leading)
                    .padding(.vertical, 8)
                }
                .contentShape(Capsule())
                
                Spacer()
                
                // 右侧按钮组 - 紧凑排列
                HStack(spacing: 24) {
                    // 邀请历史人物按钮
                    Button(action: {
                        // 添加触觉反馈
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred(intensity: 0.4)
                        
                        // 显示历史人物选择视图
                        showHistoricalFigureSelection = true
                    }) {
                        HStack(spacing: 4) {
                            ZStack {
                                // 使用固定大小的容器确保不同图标状态下大小一致
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 22, height: 22)
                                
                                // 使用SparkleIconView替代静态图标，实现动画效果
                                SparkleIconView(isAnimating: isGeneratingAIMedia)
                            }
                            
                            Text("邀请")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .padding(.vertical, 8)
                    }
                    .sheet(isPresented: $showHistoricalFigureSelection) {
                        HistoricalFigureSelectionView(postId: viewModel.post.id.uuidString, postAuthor: viewModel.post.username)
                            .presentationDetents([.height(580), .large])
                            .presentationDragIndicator(.visible)
                            .presentationBackground(Material.regular)
                            .presentationCornerRadius(25)
                    }
                    .contentShape(Rectangle())

                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            
            // 添加分隔线
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.divider.opacity(0.05),
                    DesignSystem.Colors.divider.opacity(0.15),
                    DesignSystem.Colors.divider.opacity(0.05)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .padding(.horizontal, 22)
        }
        .background(Color.clear) // 使用透明背景，继承父视图背景色
        .id("interaction_bar_\(viewModel.post.id.uuidString)")
    }
    
    // 分隔线 - 完全移除
    private func makeContentDivider() -> some View {
        Color.clear
            .frame(height: 0)  // 减小到0，因为我们已经在上面添加了分隔线
    }
    
    /// 创建评论区域
    private func makeCommentsSection() -> some View {
        VStack(spacing: 0) {
            // 评论区标题
            HStack {
                HStack(spacing: 6) {
                    Text("评论")
                        .font(DesignSystem.Typography.headline)
                    
                    // 显示评论总数
                    Text("(\(viewModel.post.getTotalCommentsCount()))")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            
            // 分隔线 - 使用渐变效果增强视觉分隔感
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.divider.opacity(0.05),
                    DesignSystem.Colors.divider.opacity(0.15),
                    DesignSystem.Colors.divider.opacity(0.05)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .padding(.horizontal, 22)
            
            // 评论列表
            CommentsListView(
                comments: viewModel.post.getTopLevelComments(),
                onReply: { comment in
                    viewModel.commentManager.replyTo(comment: comment)
                    
                    // 发送通知，让CommentInputView获取焦点并弹出键盘
                    NotificationCenter.default.post(
                        name: NSNotification.Name("FocusCommentInput"),
                        object: nil
                    )
                    
                    // 添加通知，防止页面滚动
                    NotificationCenter.default.post(
                        name: NSNotification.Name("MaintainScrollPosition"),
                        object: nil
                    )
                },
                onLike: { comment in
                    // 处理点赞逻辑 - 使用 PostViewModel 的方法确保保存
                    PostViewModel.shared.likeComment(in: viewModel.post, comment: comment)
                    
                    // 更新本地视图模型的帖子数据
                    if let updatedPost = PostViewModel.shared.posts.first(where: { $0.id == viewModel.post.id }) {
                        viewModel.post = updatedPost
                    }
                    
                    // 添加通知，防止页面滚动
                    NotificationCenter.default.post(
                        name: NSNotification.Name("MaintainScrollPosition"),
                        object: nil
                    )
                },
                onAvatarTap: { comment in
                    // 如果是虚拟角色，查找角色并导航到详情页
                    if comment.isVirtualCharacter, let characterID = comment.characterID {
                        if let characterModel = findCharacterModel(
                            characterID: characterID,
                            username: comment.username
                        ) {
                            navigateToCharacterDetail = characterModel
                        }
                    }
                }
            )
            // .id("comments-list-\(viewModel.commentsRefreshTrigger)") // 已移除，使用SwiftUI的自然更新机制
            .padding(.top, 6)
            
                    // 底部提示文字
                    if !viewModel.post.getTopLevelComments().isEmpty {
                        Text("虫洞已开启 · 等你一起相遇～")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary.opacity(0.7))
                            .padding(.top, 12)
                            .padding(.bottom, 6)
            }
        }
        .background(Color.clear) // 使用透明背景，继承父视图背景色
        .padding(.bottom, 45)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshCommentsList"))) { notification in
            #if DEBUG
            #endif
            
            // 检查通知中是否包含保持展开状态的标志
            let keepExpandState = (notification.userInfo?["keepExpandState"] as? Bool) ?? true
            
            // 如果需要保持展开状态，使用特殊的刷新方法
            if keepExpandState {
                // 只刷新评论内容，不改变展开状态
                viewModel.refreshComments()
                
                // 如果有新评论ID，自动展开该评论
                if let newCommentId = notification.userInfo?["newCommentId"] as? String {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ExpandComment"),
                        object: nil,
                        userInfo: ["commentId": newCommentId]
                    )
                }
            } else {
                // 普通刷新
                viewModel.refreshComments()
            }
        }
    }
    
    // 在文件适当位置添加辅助函数，使页面过渡更流畅
    /**
     * 执行页面过渡动画和数据更新
     * 包括时空效果、滑动动画和数据模型更新
     */
    private func performPageTransition(direction: SwipeDirection, nextPost: UserPostModel, velocity: CGFloat = 0) {
        // Phase 2优化 - 开始性能监控
        performanceMonitor.startPostSwitchMeasurement()
        
        // 禁用交互，防止动画期间的用户操作
        isTransitioning = true
        
        // 触发轻量级触觉反馈 - 降低强度减轻资源消耗
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare() // 提前准备减少延迟
        
        // 在后台线程触发触觉反馈，避免阻塞主线程
        DispatchQueue.global(qos: .userInteractive).async {
            generator.impactOccurred(intensity: 0.4) // 降低强度以减少资源消耗
        }
        
        // 记录当前帖子ID和下一篇帖子ID用于调试
        let currentPostId = viewModel.post.id.uuidString
        let nextPostId = nextPost.id.uuidString
        #if DEBUG
        #endif
        
        // 检查是否就是当前帖子，避免不必要的过渡
        if currentPostId == nextPostId {
            #if DEBUG
            print("⚠️ 警告：正在尝试切换到当前相同帖子，中止过渡并复位")
            #endif
            resetPosition()
            isTransitioning = false
            return
        }
        
        // 立即更新数据模型并显示下一页
        self.nextPagePost = nextPost
        
        // Phase 2优化 - 智能缓存处理
        intelligentCache.cachePost(nextPost)
        
        // 优化2：使用低优先级线程进行预加载，避免与UI动画竞争资源
        Task(priority: .background) {
            // 预加载操作 - 确保获取异步函数的正确返回值
            let imagesTask = await preloadImagesForPostAsync(nextPost)
            let commentsTask = await preloadCommentsForPostAsync(nextPost)
            
            // Phase 2优化 - 智能图片预加载
            ImageCache.shared.predictivelyPrefetch(
                currentPost: viewModel.post,
                nextPosts: [nextPost],
                direction: direction == .left ? "forward" : "backward"
            )
            
            // 不再需要额外的等待，因为上面已经使用了 await
            #if DEBUG
            print("预加载完成：图片(\(imagesTask ? "成功" : "完成"))，评论(\(commentsTask ? "成功" : "完成"))")
            #endif
        }
        
        // 直接更新数据模型，不使用滑动动画
        // 更新数据模型 - 直接在当前线程执行
        self.viewModel.updatePost(nextPost)
        
        // 记录完成状态
        #if DEBUG
        #endif
        
        // 立即重置关键状态
        self.dragOffset = 0
        self.swipeDirection = .none
        self.showingTimeSpaceEffect = false
        self.nextPageVisible = false
        
        // 清理状态
        self.nextPagePost = nil
        self.isTransitioning = false
        
        // Phase 2优化 - 结束性能监控
        performanceMonitor.endPostSwitchMeasurement()
        
        // 更新边界状态和预加载下一篇
        self.checkBoundaries()
        self.preloadAdjacentPosts()
    }
    
    // 重置转场状态的辅助方法 - 优化为更轻量级实现
    private func resetTransitionState() {
        // 防止多次触发
        if !isTransitioning {
            return
        }
        
        // 先重置关键状态变量
        isTransitioning = false
        
        // 复位UI状态 - 使用更轻量的动画
        withAnimation(.easeOut(duration: 0.2)) { // 更简单的动画，减少计算负担
            self.dragOffset = 0
            self.swipeDirection = .none
            self.showingTimeSpaceEffect = false
            self.nextPageVisible = false // 立即隐藏下一页
        }
        
        // 立即清理预加载相关状态
        self.nextPagePost = nil
    }
    
    // 优化异步版本的图片预加载 - 使用批处理减少线程切换
    private func preloadImagesForPostAsync(_ post: UserPostModel) async -> Bool {
        // 创建一个批处理组，减少过多的线程切换
        var batchCounter = 0
        let batchSize = 3
        
        for imageName in post.images {
            if let image = UIImage(named: imageName) {
                // 触发图片加载
                _ = image.size
            }
            
            // 每处理batchSize个图片才让出线程一次，减少频繁切换
            batchCounter += 1
            if batchCounter >= batchSize {
                await Task.yield()
                batchCounter = 0
            }
        }
        
        return true
    }
    
    // 优化异步版本的评论预加载
    private func preloadCommentsForPostAsync(_ post: UserPostModel) async -> Bool {
        // 预加载评论数据
        _ = post.getTotalCommentsCount()
        let topLevelComments = post.getTopLevelComments()
        
        // 批量预加载头像
        var batchCounter = 0
        let batchSize = 5
        
        for comment in topLevelComments {
            if !comment.userAvatar.isEmpty {
                _ = UIImage(named: comment.userAvatar)
            }
            
            // 每处理batchSize个评论才让出线程一次
            batchCounter += 1
            if batchCounter >= batchSize {
                await Task.yield()
                batchCounter = 0
            }
        }
        
        return true
    }
    
    // 恢复原位 - 当滑动不满足触发翻页条件时
    private func resetPosition() {
        // 防止无效的重复调用
        if dragOffset == 0 && !isDragging {
            return
        }
        
        // 先重置关键状态变量
        isDragging = false
        
        // 提供更轻量的触觉反馈 - 在后台线程执行以避免阻塞UI
        DispatchQueue.global(qos: .userInteractive).async {
            let feedback = UIImpactFeedbackGenerator(style: .soft)
            feedback.prepare() // 提前准备，减少延迟
            feedback.impactOccurred(intensity: 0.15) // 进一步降低强度
        }
        
        // 使用最轻量的动画 - 直接使用easeOut而不是计算成本更高的spring动画
        withAnimation(.easeOut(duration: 0.18)) {
            dragOffset = 0
            swipeDirection = .none
            showingTimeSpaceEffect = false
            nextPageVisible = false // 立即隐藏下一页
        }
        
        // 立即清理其他状态，不使用延迟
        nextPagePost = nil
        isTransitioning = false
        
        // 只在明确需要时执行边界检查 - 移除异步调用以减少线程切换
        if wormholePageDragOffset != 0 || showAddContentView {
            checkBoundaries()
        }
    }
    
    // 预加载相邻帖子
    private func preloadAdjacentPosts() {
        // 增加提前缓存逻辑，记录当前帖子ID用于日志
        let _ = viewModel.post.id

        
        // 边界检查，确定是否有下一篇或上一篇帖子
        checkBoundaries()
        
        // 当确认为最后一篇时，强制禁止预加载下一篇
        if isLastPost {

            hasNextPost = false
            
            // 清除可能已缓存的下一篇帖子
            if viewModel.getNextPostCache() != nil {
                viewModel.clearNextPostCache()
            }
            
            // 直接返回，不尝试加载下一篇
            return
        }
        
        // 直接检查是否有下一篇帖子
        if let onNextPost = onNextPost, hasNextPost {
            let currentPostId = viewModel.post.id
            // 使用Void类型闭包包装onNextPost调用，确保它使用viewModel.post而不是外部post
            let getNextPostWrapper = { () -> UserPostModel? in
                // 这里返回的是onNextPost()的结果，但确保它会使用最新的viewModel.post
                #if DEBUG
                print("📦 内部函数获取下一篇帖子 - 当前帖子ID: \(currentPostId)")
                #endif
                return onNextPost(currentPostId)
            }
            
            if let nextPost = getNextPostWrapper() {
                // 避免加载当前帖子本身（错误情况）
                if nextPost.id.uuidString == currentPostId.uuidString {
                    #if DEBUG
                    #endif
                    hasNextPost = false
                    isLastPost = true
                    return
                }
                

                // 预加载下一篇帖子
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒延迟
                    
                    viewModel.preloadNextPost(nextPost)
                    
                    // 预加载图片和评论 - 使用新的异步函数
                    _ = await preloadImagesForPostAsync(nextPost)
                    
                    
                    _ = await preloadCommentsForPostAsync(nextPost)
                    
                }
            } else {
                // 如果onNextPost()返回nil但hasNextPost为true，说明状态不同步
                #if DEBUG
                #endif
                hasNextPost = false
                isLastPost = true
            }
        }
        
        // 检查是否有上一篇帖子
        if let onPrevPost = onPrevPost, hasPrevPost {
            let currentPostId = viewModel.post.id
            // 使用Void类型闭包包装onPrevPost调用，确保它使用viewModel.post而不是外部post
            let getPrevPostWrapper = { () -> UserPostModel? in
                // 这里返回的是onPrevPost()的结果，但确保它会使用最新的viewModel.post
                #if DEBUG
                print("📦 内部函数获取上一篇帖子 - 当前帖子ID: \(currentPostId)")
                #endif
                return onPrevPost(currentPostId)
            }
            
            if let prevPost = getPrevPostWrapper() {
                // 避免加载当前帖子本身（错误情况）
                if prevPost.id.uuidString == currentPostId.uuidString {
                    hasPrevPost = false
                    return
                }
                

                
                // 预加载上一篇帖子 (延迟一点以减轻加载压力)
                Task {
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒延迟
                    
                    viewModel.preloadPrevPost(prevPost)
                    
                    // 预加载图片和评论 - 使用新的异步函数
                    _ = await preloadImagesForPostAsync(prevPost)
                    
                    
                    _ = await preloadCommentsForPostAsync(prevPost)
                    
                }
            } else {
                // 如果onPrevPost()返回nil但hasPrevPost为true，说明状态不同步
                #if DEBUG
                #endif
                hasPrevPost = false
            }
        }
        
        #if DEBUG
        #endif
    }
    
    /**
     * 检查边界条件 - 确保hasNextPost、hasPrevPost和isLastPost状态保持同步
     */
    private func checkBoundaries() {
        // 记录检查前的状态
        let oldHasNextPost = hasNextPost
        let oldHasPrevPost = hasPrevPost
        let oldIsLastPost = isLastPost
        
        // 记录当前帖子ID
        let currentPostId = viewModel.post.id
        let currentPostUUID = currentPostId.uuidString
        
        // 硬编码检查是否是最后一篇帖子 (第三篇)
        let knownLastPostId = "33333333-3333-3333-3333-333333333333"
        let isKnownLastPost = (currentPostUUID == knownLastPostId)
        
        if isKnownLastPost {
            #if DEBUG
            print("⭐️ 当前帖子ID匹配已知的最后一篇ID，确认为最后一篇")
            #endif
        }
        
        // 检查是否有下一篇帖子 - 设置初始值而不是使用之前的状态
        var nextPostExists = false
        var reallyLastPost = false
        
        if let onNextPost = onNextPost {
            // 定义获取下一篇帖子的函数，可以递归重试
            func getNextPostWithRetry(currentRetry: Int = 0) -> UserPostModel? {
                // 如果重试次数过多，中止并返回nil
                if currentRetry >= 2 {
                    #if DEBUG
                    print("⭐️ 已重试获取下一篇帖子2次，放弃")
                    #endif
                    return nil
                }
                
                // 使用当前viewModel中的帖子作为上下文
                // 直接调用回调函数获取结果
                let nextPost = onNextPost(currentPostId)
                
                // 检查是否返回了当前帖子（错误情况）
                if let nextPost = nextPost {
                    let nextPostUUID = nextPost.id.uuidString
    
                    
                    if nextPostUUID == currentPostUUID {
                        #if DEBUG
                        print("⭐️⭐️⭐️ 警告：onNextPost()返回了当前帖子ID，尝试再次获取")
                        #endif
                        #if DEBUG
                        print("⭐️ 当前帖子ID: \(currentPostId), 错误返回的下一篇ID: \(nextPost.id)")
                        #endif
                        
                        // 🚀 性能优化：使用异步延迟替代同步阻塞
                        // 递归尝试再次获取（移除阻塞延迟）
                        return getNextPostWithRetry(currentRetry: currentRetry + 1)
                    }
                }
                
                return nextPost
            }
            
            // 使用重试机制获取下一篇帖子
            let nextPost = getNextPostWithRetry()
            
            // 设置标志
            nextPostExists = nextPost != nil
            
            // 如果是最后一篇已知ID，则强制设置为真正的最后一篇
            if isKnownLastPost {
                reallyLastPost = true
                nextPostExists = false
            } else {
                reallyLastPost = nextPost == nil
            }
            
            // 额外调试信息
            #if DEBUG
            print("⭐️ onNextPost调用结果: \(nextPost != nil ? "有下一篇" : "没有下一篇")")
            #endif
            
            // 如果存在下一篇帖子，打印其ID和内容摘要
            if let nextPost = nextPost {
                let nextPostUUID = nextPost.id.uuidString
                #if DEBUG
                print("⭐️ 下一篇帖子ID: \(nextPostUUID)")
                #endif
                #if DEBUG
                print("⭐️ 下一篇内容前20字符: \(String(nextPost.content.prefix(20)))")
                #endif
            }
        } else {
            // 如果没有提供回调，默认设置为没有下一篇
            nextPostExists = false
            reallyLastPost = isKnownLastPost // 只有是已知的最后一篇时才认为是最后一篇
        }
        
        // 检查是否有上一篇帖子 - 设置初始值而不是使用之前的状态
        var prevPostExists = false
        
        if let onPrevPost = onPrevPost {
            // 定义获取上一篇帖子的函数，可以递归重试
            func getPrevPostWithRetry(currentRetry: Int = 0) -> UserPostModel? {
                // 如果重试次数过多，中止并返回nil
                if currentRetry >= 2 {
                    return nil
                }
                
                // 使用当前viewModel中的帖子作为上下文
                // 直接调用回调函数获取结果
                let prevPost = onPrevPost(currentPostId)
                
                // 检查是否返回了当前帖子（错误情况）
                if let prevPost = prevPost {
                    let prevPostUUID = prevPost.id.uuidString
    
                    
                    if prevPostUUID == currentPostUUID {
                        // 🚀 性能优化：移除同步阻塞
                        // 递归尝试再次获取
                        return getPrevPostWithRetry(currentRetry: currentRetry + 1)
                    }
                }
                
                return prevPost
            }
            
            // 使用重试机制获取上一篇帖子
            let prevPost = getPrevPostWithRetry()
            
            // 设置标志
            prevPostExists = prevPost != nil
            
            // 额外调试信息
            #if DEBUG
            print("⭐️ onPrevPost调用结果: \(prevPost != nil ? "有上一篇" : "没有上一篇")")
            #endif
            
            // 如果存在上一篇帖子，打印其ID和内容摘要
            if let prevPost = prevPost {
                let prevPostUUID = prevPost.id.uuidString
                #if DEBUG
                print("⭐️ 上一篇帖子ID: \(prevPostUUID)")
                #endif
                #if DEBUG
                print("⭐️ 上一篇内容前20字符: \(String(prevPost.content.prefix(20)))")
                #endif
            }
        } else {
            // 如果没有提供回调，默认设置为没有上一篇
            prevPostExists = false
        }
        
        // 更新状态变量
        hasNextPost = nextPostExists
        hasPrevPost = prevPostExists
        isLastPost = reallyLastPost
        isFirstPost = !prevPostExists  // 如果没有上一篇帖子，则为第一篇
        
        // 确保状态一致性
        if hasNextPost && isLastPost {
            #if DEBUG
            print("⭐️ 严重状态冲突：hasNextPost=true 且 isLastPost=true，修正为非最后一篇")
            #endif
            isLastPost = false
        } else if !hasNextPost && !isLastPost {
            #if DEBUG
            print("⭐️ 状态不一致：hasNextPost=false 但 isLastPost=false，修正为isLastPost=true")
            #endif
            isLastPost = true
        }
        
        // 如果状态发生了变化，记录日志
        if oldHasNextPost != hasNextPost || oldHasPrevPost != hasPrevPost || oldIsLastPost != isLastPost {
            #if DEBUG
            print("⭐️ 边界状态已更新: hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost), isLastPost=\(isLastPost), isFirstPost=\(isFirstPost)")
            #endif
        }
    }
    
    // 在类中添加一个新的辅助方法，用于严格检查是否真的是最后一篇帖子
    private func strictlyConfirmLastPost() -> Bool {
        #if DEBUG
        print("⭐️⭐️⭐️ 严格检查是否为最后一篇帖子")
        #endif
        
        // 获取当前帖子ID
        let currentPostId = viewModel.post.id
        let currentPostIdString = currentPostId.uuidString
        #if DEBUG
        print("⭐️ 当前帖子ID: \(currentPostIdString)")
        #endif
        
        // 检查是否有onNextPost回调
        guard let onNextPost = onNextPost else {
            #if DEBUG
            print("⭐️ 没有onNextPost回调，无法确认")
            #endif
            return false
        }
        
        // 尝试获取下一篇帖子 - 多次尝试确保准确性
        for _ in 0..<3 {
            if let nextPost = onNextPost(currentPostId) {
                // 如果能获取到下一篇，并且ID不同，则肯定不是最后一篇
                if nextPost.id.uuidString != currentPostIdString {
                    #if DEBUG
                    print("⭐️ 能获取到不同ID的下一篇帖子，确认非最后一篇")
                    #endif
                    return false
                } else {
                    #if DEBUG
                    print("⭐️ 获取到ID相同的下一篇帖子，可能是最后一篇或数据错误")
                    #endif
                    // 继续下一次尝试
                }
            } else {
                // 无法获取下一篇，可能真的是最后一篇
                #if DEBUG
                print("⭐️ 无法获取下一篇帖子，可能是最后一篇")
                #endif
            }
            
            // 🚀 性能优化：移除同步阻塞，直接继续执行
        }
        
        // 检查帖子ID - 手动硬编码检查最后一篇的ID
        if currentPostIdString == "33333333-3333-3333-3333-333333333333" {
            #if DEBUG
            print("⭐️ 当前帖子ID匹配最后一篇的已知ID，确认为最后一篇")
            #endif
            return true
        }
        
        return false
    }
    
    // 计算图片区域高度
    private func calculateImageSectionHeight(for images: [String]) -> CGFloat {
        // 根据图片数量选择不同的计算方法
        switch images.count {
        case 0:
            return 0 // 无图片时高度为0
        case 1:
            // 单图高度 - 使用UIImage计算实际高度
            if images[0].contains("_image_") {
                return 200.0 // 用户上传图片使用固定高度
            } else if let uiImage = UIImage(named: images[0]) {
                // 计算图片宽高比
                let aspectRatio = uiImage.size.width / uiImage.size.height
                let screenWidth = UIScreen.main.bounds.width - 32 // 考虑边距
                let adjustedWidth = screenWidth * 0.85 // 按85%宽度显示
                
                // 基于宽度和比例计算高度，保持原始比例
                var calculatedHeight = adjustedWidth / aspectRatio
                
                // 限制最小和最大高度
                calculatedHeight = min(max(calculatedHeight, 120.0), 220.0)
                
                // 根据内容类型调整高度
                if aspectRatio > 2.0 {
                    // 超宽图片限制高度
                    calculatedHeight = min(calculatedHeight, 150.0)
                } else if aspectRatio < 0.5 {
                    // 超窄图片提高高度
                    calculatedHeight = min(calculatedHeight, 220.0)
                }
                
                return calculatedHeight
            } else {
                return 180.0 // 默认图片高度
            }
        case 2:
            // 两图布局 - 按照微信风格计算
            return calculateGridHeight(imagesCount: 2, columns: 2)
        case 3:
            // 三图布局 - 微信风格，一行三张
            return calculateGridHeight(imagesCount: 3, columns: 3)
        case 4:
            // 四图布局 - 微信风格，2x2网格
            return calculateGridHeight(imagesCount: 4, columns: 2)
        case 5, 6:
            // 5-6张图片 - 微信风格，两行三列网格
            return calculateGridHeight(imagesCount: images.count, columns: 3)
        default:
            // 7-9张图片 - 微信风格，最多三行三列
            return calculateGridHeight(imagesCount: min(images.count, 9), columns: 3)
        }
    }
    
    // 计算动态内边距的辅助函数
    private func calculateDynamicPadding(text: String) -> CGFloat {
        let charCount = text.count
        let minPadding: CGFloat = 16  // 标准内边距
        let maxPadding: CGFloat = 24  // 短文本内边距
        let threshold = 10  // 临界字符数
        
        if charCount <= threshold {
            return maxPadding
        } else if charCount >= threshold * 2 {
            return minPadding
        } else {
            // 在临界值之间进行线性插值，实现平滑过渡
            let ratio = CGFloat(charCount - threshold) / CGFloat(threshold)
            return maxPadding - (maxPadding - minPadding) * ratio
        }
    }
    
    // 在类中添加检查输入框焦点状态的方法
    private func isAnyTextInputActive() -> Bool {
        // 检查当前是否有任何文本输入框处于活跃状态
        guard let currentResponder = UIResponder.currentFirstResponder() else {
            return false
        }
        
        // 检查第一响应者是否是文本输入类控件
        return currentResponder is UITextField || currentResponder is UITextView
    }
}

/**
 * 帖子详情视图 - 使用ObservableObject管理数据
 */
class FullscreenPostDetailViewModel: ObservableObject {
    @Published var post: UserPostModel
    @Published var commentManager: CommentManager
    // 移除强制刷新的commentsRefreshTrigger，使用SwiftUI的自然更新机制
    // @Published var commentsRefreshTrigger = UUID() // 已移除
    
    // 添加缓存属性来支持预加载
    private var nextPostCache: UserPostModel?
    private var prevPostCache: UserPostModel?
    
    init(post: UserPostModel) {
        self.post = post
        self.commentManager = CommentManager(post: post)
    }
    
    // 刷新评论列表
    func refreshComments() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // 添加点赞功能
    func toggleLike() {
        // 使用全局点赞状态管理器
        let newLikedState = LikeStateManager.shared.toggleLike(post.id.uuidString)
        
        // 更新帖子数据
        let updatedPost = post.toggleLike(isLiked: newLikedState)
        post = updatedPost
        
        // 更新 PostViewModel 中的帖子数据并保存
        if let index = PostViewModel.shared.posts.firstIndex(where: { $0.id == updatedPost.id }) {
            PostViewModel.shared.posts[index] = updatedPost
            // 保存点赞数到持久化存储
            PostViewModel.shared.saveUserPosts()
            PostViewModel.shared.saveAIPosts()
        }
        
        // 发送通知给UserLikeService记录点赞行为
        NotificationCenter.default.post(
            name: NSNotification.Name("PostLiked"),
            object: nil,
            userInfo: [
                "post": updatedPost,
                "isLiked": newLikedState
            ]
        )
        
        // 发送通知以更新其他视图
        NotificationCenter.default.post(
            name: NSNotification.Name("PostLikeUpdated"),
            object: nil,
            userInfo: ["postID": post.id.uuidString]
        )
    }
    
    // 添加收藏功能
    func toggleBookmark() {
        // 更新收藏状态
        let updatedPost = post.toggleBookmark(isBookmarked: !post.isBookmarkedByCurrentUser)
        post = updatedPost
        
        // 发送通知以更新其他视图
        NotificationCenter.default.post(
            name: NSNotification.Name("PostBookmarkUpdated"),
            object: nil,
            userInfo: ["postID": post.id.uuidString]
        )
    }
    
    // 🚀 性能优化：更新帖子的方法，复用CommentManager实例
    func updatePost(_ newPost: UserPostModel) {
        // 立即更新数据模型
        self.post = newPost
        
        // 🚀 使用CommentManager的新方法，避免重新创建实例
        self.commentManager.updatePost(newPost)
        
        // 强制发送对象变更通知，确保UI更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        // 清除缓存
        nextPostCache = nil
        prevPostCache = nil
    }
    
    // 预加载下一篇帖子内容
    func preloadNextPost(_ nextPost: UserPostModel?) {
        guard let nextPost = nextPost else { return }
        nextPostCache = nextPost
    }
    
    // 预加载上一篇帖子内容
    func preloadPrevPost(_ prevPost: UserPostModel?) {
        guard let prevPost = prevPost else { return }
        prevPostCache = prevPost
    }
    
    // 获取预加载的下一篇帖子
    func getNextPostCache() -> UserPostModel? {
        return nextPostCache
    }
    
    // 获取预加载的上一篇帖子
    func getPrevPostCache() -> UserPostModel? {
        return prevPostCache
    }
    
    // 清除缓存
    func clearNextPostCache() {
        nextPostCache = nil
    }
    
    // 同步帖子
    func synchronizePost(id: UUID) {
        #if DEBUG
        print("🔄 开始同步帖子: \(id.uuidString)")
        #endif
        
        // 获取所有帖子 - 使用PostViewModel中的实际数据
        let allPosts = PostViewModel.shared.posts
        
        // 查找匹配ID的帖子
        if let foundPost = allPosts.first(where: { $0.id.uuidString == id.uuidString }) {
            #if DEBUG
            print("✅ 在PostViewModel中找到匹配帖子: \(foundPost.content.prefix(30))...")
            #endif
            
            // 更新当前帖子，使用 updatePost 方法确保一致性
            updatePost(foundPost)
            
            #if DEBUG
            print("✅ 帖子同步完成")
            #endif
        } else {
            #if DEBUG
            print("❌ 在PostViewModel中未找到匹配的帖子ID: \(id.uuidString)")
            #endif
            #if DEBUG
            print("   PostViewModel中的帖子总数: \(allPosts.count)")
            #endif
        }
    }
}

/**
 * 兼容层 - 为了满足TabBarManager中的引用
 * 这是一个空实现，以解决编译错误
 */
struct FullscreenContentView {
    typealias FullscreenContent = AnyView
    
    let content: FullscreenContent
    
    init<Content: View>(_ content: Content) {
        self.content = AnyView(content)
    }
}

// 在文件末尾添加黑洞相关的辅助视图

/**
 * 黑洞粒子环视图
 * 创建环形的粒子效果环绕黑洞
 */
struct BlackHoleParticleRing: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // 创建多层粒子环，每层旋转角度和大小略有不同
            ForEach(0..<3) { ringIndex in
                ZStack {
                    ForEach(0..<180) { index in
                        let size = CGFloat.random(in: 1.0...2.5)
                        let opacity = Double.random(in: 0.2...0.8)
                        let angle = Double(index) * (360.0 / 180.0)
                        let radius = Double(self.getFrame().width / 2) * (1.0 - Double(ringIndex) * 0.05)
                        let xPos = cos(angle * .pi / 180) * radius
                        let yPos = sin(angle * .pi / 180) * radius
                        
                        Circle()
                            .fill(Color.white.opacity(opacity))
                            .frame(width: size, height: size)
                            .position(x: self.getFrame().width / 2 + CGFloat(xPos),
                                     y: self.getFrame().height / 2 + CGFloat(yPos))
                            .blur(radius: 0.2)
                    }
                }
                .rotationEffect(.degrees(rotation + Double(ringIndex) * 30))
            }
        }
        .onAppear {
            // 使用异步调用避免在视图更新过程中修改状态
            DispatchQueue.main.async {
                // 添加缓慢旋转动画
                withAnimation(.linear(duration: 300).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
    
    private func getFrame() -> CGRect {
        return CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width * 0.65, height: UIScreen.main.bounds.width * 0.65)
    }
}

// MARK: - 辅助视图组件

/**
 * 情境和期望选择视图
 * 将复杂的嵌套视图分解为更简单的子视图
 */
struct SituationExpectationView: View {
    @Binding var selectedSituation: String
    @Binding var selectedExpectation: String
    let situations: [String]
    let expectations: [String]
    let centerPosition: CGPoint // 新增参数，接收黑洞中心点坐标
    
    // 状态变量，用于控制提示的显示
    @State private var showHint: Bool = true
    
    var body: some View {
        ZStack {
            // 情境选择 - 上半部环绕
            OrbitalSelectionView(
                items: situations,
                selectedItem: $selectedSituation,
                icon: "brain",
                title: "此刻我正在...",
                angleRange: 205.0...335.0,  // 修改角度范围，将上部区域集中在正上方
                radius: AdaptiveLayoutManager.shared.orbitalRadius(),  // 使用自适应布局管理器计算半径
                themeColor: Color(red: 0.2, green: 0.4, blue: 0.8), // 更柔和的蓝色调
                centerPosition: centerPosition // 传入黑洞中心点
            )
            
            // 期望选择 - 下半部环绕
            OrbitalSelectionView(
                items: expectations,
                selectedItem: $selectedExpectation,
                icon: "sparkles",
                title: "希望得到的是...",
                angleRange: 25.0...155.0,  // 修改角度范围，将下部区域集中在正下方
                radius: AdaptiveLayoutManager.shared.orbitalRadius(),  // 使用自适应布局管理器计算半径
                themeColor: Color(red: 0.6, green: 0.3, blue: 0.7), // 更柔和的紫色调
                centerPosition: centerPosition // 传入黑洞中心点
            )
        }
        // 添加设备方向变化监听
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // 方向变化时触发重新布局
            // 这里不需要额外代码，SwiftUI会自动重新计算布局
        }
        // 当选择改变时隐藏提示
        .onChange(of: selectedSituation) { _, _ in
            if showHint {
                withAnimation(.easeOut(duration: 0.3)) {
                    showHint = false
                }
            }
        }
        .onChange(of: selectedExpectation) { _, _ in
            if showHint {
                withAnimation(.easeOut(duration: 0.3)) {
                    showHint = false
                }
            }
        }
    }
}

// 优化环绕式选择视图
struct OrbitalSelectionView: View {
    let items: [String]
    @Binding var selectedItem: String
    let icon: String
    let title: String
    let angleRange: ClosedRange<Double>
    let radius: CGFloat
    let themeColor: Color
    let centerPosition: CGPoint // 接收黑洞中心点坐标
    
    // 状态变量，控制初始动画效果
    @State private var showInitialAnimation = true
    
    // 获取当前设备类型
    private var deviceType: AdaptiveLayoutManager.DeviceType {
        return AdaptiveLayoutManager.DeviceType.current()
    }
    
    // 获取当前屏幕方向
    private var orientation: AdaptiveLayoutManager.Orientation {
        return AdaptiveLayoutManager.Orientation.current()
    }
    
    // 计算标签偏移量 - 根据设备类型和方向动态调整
    private var labelOffset: CGFloat {
        switch (deviceType, orientation) {
        case (.smallPhone, _):
            return 35
        case (.mediumPhone, _):
            return 40
        case (.largePhone, _):
            return 45
        case (.tablet, _):
            return 50
        }
    }
    
    // 计算按钮字体大小 - 根据设备类型和方向动态调整
    private var buttonFontSize: CGFloat {
        switch (deviceType, orientation) {
        case (.smallPhone, _):
            return 10 // 减小字体大小
        case (.mediumPhone, _):
            return 11 // 减小字体大小
        case (.largePhone, _):
            return 12 // 减小字体大小
        case (.tablet, _):
            return 13 // 减小字体大小
        }
    }
    
    // 计算按钮内边距 - 根据设备类型和方向动态调整
    private var buttonPadding: (vertical: CGFloat, horizontal: CGFloat) {
        switch (deviceType, orientation) {
        case (.smallPhone, _):
            return (3, 8) // 减小内边距
        case (.mediumPhone, _):
            return (4, 10) // 减小内边距
        case (.largePhone, _):
            return (5, 12) // 减小内边距
        case (.tablet, _):
            return (6, 14) // 减小内边距
        }
    }
    
    var body: some View {
        OrbitalSelectionContent(
            title: title,
            icon: icon,
            items: items,
            selectedItem: $selectedItem,
            showInitialAnimation: $showInitialAnimation,
            centerPosition: centerPosition,
            radius: radius,
            labelOffset: labelOffset,
            angleRange: angleRange,
            themeColor: themeColor,
            deviceType: deviceType,
            orientation: orientation,
            buttonFontSize: buttonFontSize,
            buttonPadding: buttonPadding
        )
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        // 添加设备方向变化监听
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // 方向变化时触发重新布局
            // 这里不需要额外代码，SwiftUI会自动重新计算布局
        }
    }
}

/**
 * 轨道选择视图内容
 * 将复杂视图拆分为更小的组件，以便编译器更好地进行类型检查
 */
private struct OrbitalSelectionContent: View {
    let title: String
    let icon: String
    let items: [String]
    @Binding var selectedItem: String
    @Binding var showInitialAnimation: Bool
    let centerPosition: CGPoint
    let radius: CGFloat
    let labelOffset: CGFloat
    let angleRange: ClosedRange<Double>
    let themeColor: Color
    let deviceType: AdaptiveLayoutManager.DeviceType
    let orientation: AdaptiveLayoutManager.Orientation
    let buttonFontSize: CGFloat
    let buttonPadding: (vertical: CGFloat, horizontal: CGFloat)
    
    var body: some View {
        ZStack {
            // 标签部分
            CategoryLabel(
                title: title,
                icon: icon,
                centerPosition: centerPosition,
                radius: radius,
                labelOffset: labelOffset,
                angleRange: angleRange,
                themeColor: themeColor
            )
            
            // 按钮部分
            ButtonsLayout(
                items: items,
                selectedItem: $selectedItem,
                showInitialAnimation: $showInitialAnimation,
                centerPosition: centerPosition,
                radius: radius,
                angleRange: angleRange,
                themeColor: themeColor,
                buttonFontSize: buttonFontSize,
                buttonPadding: buttonPadding
            )
        }
    }
}

/**
 * 类别标签组件
 * 显示轨道选择视图的标题
 */
private struct CategoryLabel: View {
    let title: String
    let icon: String
    let centerPosition: CGPoint
    let radius: CGFloat
    let labelOffset: CGFloat
    let angleRange: ClosedRange<Double>
    let themeColor: Color
    
    // 计算标签的背景颜色 - 使用更中性的色调
    private var labelBackgroundColor: Color {
        // 采用更符合Apple设计的中性半透明背景
        if title.contains("此刻") {
            return Color(red: 0.2, green: 0.2, blue: 0.25).opacity(0.4)  // 深蓝灰色
        } else if title.contains("希望") {
            return Color(red: 0.25, green: 0.2, blue: 0.25).opacity(0.4)  // 深紫灰色
        } else {
            return Color.black.opacity(0.4)  // 其他标签使用深黑色
        }
    }
    
    // 计算标签的边框颜色 - 使用柔和的分隔色调
    private var labelBorderColor: Color {
        if title.contains("此刻") {
            return Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.25)  // 淡蓝色边框
        } else if title.contains("希望") {
            return Color(red: 0.6, green: 0.3, blue: 0.7).opacity(0.25)  // 淡紫色边框
        } else {
            return Color.white.opacity(0.2)  // 其他标签使用淡白色
        }
    }
    
    // 计算标签的位置偏移
    private var additionalOffset: CGFloat {
        if title.contains("此刻") || title.contains("希望") {
            return 15  // 保持与交互区域的距离
        } else {
            return 0
        }
    }
    
    // 计算图标颜色 - 使用更柔和的颜色
    private var iconColor: Color {
        if title.contains("此刻") {
            return Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.7)  // 柔和蓝色
        } else if title.contains("希望") {
            return Color(red: 0.7, green: 0.4, blue: 0.9).opacity(0.7)  // 柔和紫色
        } else {
            return Color.white.opacity(0.7)  // 其他图标使用白色
        }
    }
    
    // 计算文本颜色 - 确保在任何背景下都能清晰阅读
    private var textColor: Color {
        return Color.white.opacity(0.85)  // 所有文本使用高对比度白色
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(textColor)
                    .tracking(0.3)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(labelBackgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(labelBorderColor, lineWidth: 0.8)
                    )
            )
            // 使用更微妙的阴影，增强深色背景下的可见性
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .position(
            x: centerPosition.x + CGFloat(cos((angleRange.lowerBound + angleRange.upperBound) * 0.5 * .pi / 180.0)) * (radius + labelOffset + additionalOffset),
            y: centerPosition.y + CGFloat(sin((angleRange.lowerBound + angleRange.upperBound) * 0.5 * .pi / 180.0)) * (radius + labelOffset + additionalOffset)
        )
        .opacity(0.85)
        .scaleEffect(0.95)
        .accessibilityLabel(Text("\(title) 分类"))
        .accessibilityAddTraits(.isHeader)
        .accessibilityAddTraits(.isStaticText)
    }
}

/**
 * 按钮布局组件
 * 处理轨道选择视图中的按钮布局
 */
private struct ButtonsLayout: View {
    let items: [String]
    @Binding var selectedItem: String
    @Binding var showInitialAnimation: Bool
    let centerPosition: CGPoint
    let radius: CGFloat
    let angleRange: ClosedRange<Double>
    let themeColor: Color
    let buttonFontSize: CGFloat
    let buttonPadding: (vertical: CGFloat, horizontal: CGFloat)
    
    var body: some View {
        ForEach(items.indices, id: \.self) { index in
            let item = items[index]
            let isSelected = selectedItem == item
            
            // 计算按钮位置
            let position = calculateButtonPosition(for: index)
            
            // 按钮视图
            OrbitalButton(
                item: item,
                isSelected: isSelected,
                index: index,
                position: position,
                showInitialAnimation: $showInitialAnimation,
                themeColor: themeColor,
                buttonFontSize: buttonFontSize,
                buttonPadding: buttonPadding,
                onSelect: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedItem = item
                        if showInitialAnimation {
                            showInitialAnimation = false
                        }
                    }
                }
            )
        }
    }
    
    // 计算按钮位置
    private func calculateButtonPosition(for index: Int) -> CGPoint {
        let totalAngle = angleRange.upperBound - angleRange.lowerBound
        
        // 根据按钮数量动态调整角度分布
        let angle: Double
        if items.count <= 3 {
            // 按钮较少时，分布得更开
            let segmentAngle = totalAngle / Double(max(1, items.count + 1))
            let startAngle = angleRange.lowerBound + segmentAngle
            angle = startAngle + Double(index) * segmentAngle
        } else {
            // 按钮较多时，均匀分布
            let segmentAngle = totalAngle / Double(max(1, items.count - 1))
            angle = angleRange.lowerBound + Double(index) * segmentAngle
        }
        
        // 计算位置
        let radian = angle * .pi / 180.0
        let x = centerPosition.x + cos(radian) * radius
        let y = centerPosition.y + sin(radian) * radius
        
        return CGPoint(x: x, y: y)
    }
}

/**
 * 轨道按钮组件
 * 表示轨道选择视图中的单个按钮
 */
private struct OrbitalButton: View {
    let item: String
    let isSelected: Bool
    let index: Int
    let position: CGPoint
    @Binding var showInitialAnimation: Bool
    let themeColor: Color
    let buttonFontSize: CGFloat
    let buttonPadding: (vertical: CGFloat, horizontal: CGFloat)
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            onSelect()
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred(intensity: 0.4)
        }) {
            ButtonContent(
                text: item,
                isSelected: isSelected,
                fontSize: buttonFontSize,
                padding: buttonPadding,
                themeColor: themeColor
            )
        }
        .buttonStyle(PlainButtonStyle())
        .position(position)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(Text(item))
        .accessibilityHint(Text(isSelected ? "已选择" : "点击选择"))
        .accessibilityAddTraits(.isButton)
        .modifier(ButtonAnimationModifier(
            showAnimation: showInitialAnimation && !isSelected,
            index: index,
            themeColor: themeColor,
            animationState: $showInitialAnimation,
            buttonText: item
        ))
    }
}

/**
 * 情境按钮组件 - 保留但不直接使用
 */
struct SituationButton: View {
    let situation: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(situation)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(isSelected ? Color.white.opacity(0.25) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 期望按钮组件 - 保留但不直接使用
 */
struct ExpectationButton: View {
    let expectation: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(expectation)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(isSelected ? Color.white.opacity(0.25) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 自适应布局管理器
 * 根据设备特性和屏幕方向动态计算布局参数
 */
class AdaptiveLayoutManager {
    static let shared = AdaptiveLayoutManager()
    
    // 用户偏好键
    private enum UserPreferenceKeys {
        static let centerYOffset = "layout.centerYOffset"
        static let componentOffset = "layout.componentOffset"
        static let orbitalRadius = "layout.orbitalRadius"
        static let useCustomLayout = "layout.useCustomLayout"
    }
    
    // 设备类型枚举
    enum DeviceType {
        case smallPhone    // iPhone SE, 5s等
        case mediumPhone   // iPhone 8, XR, 11等
        case largePhone    // iPhone Pro Max系列
        case tablet        // iPad系列
        
        // 根据屏幕尺寸判断设备类型
        static func current() -> DeviceType {
            let screenHeight = UIScreen.main.bounds.height
            let idiom = UIDevice.current.userInterfaceIdiom
            
            if idiom == .pad {
                return .tablet
            } else {
                if screenHeight < 700 {
                    return .smallPhone
                } else if screenHeight < 800 {
                    return .mediumPhone
                } else {
                    return .largePhone
                }
            }
        }
    }
    
    // 屏幕方向枚举
    enum Orientation {
        case portrait
        case landscape
        
        // 获取当前屏幕方向
        static func current() -> Orientation {
            let screenSize = UIScreen.main.bounds.size
            return screenSize.width < screenSize.height ? .portrait : .landscape
        }
    }
    
    // 获取当前设备的安全区域
    var safeAreaInsets: UIEdgeInsets {
        // 兼容iOS 15及以上版本
        if #available(iOS 15.0, *) {
            // 使用新API获取窗口场景
            let windowScenes = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
            
            if let windowScene = windowScenes.first,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return window.safeAreaInsets
            } else {
                // 提供默认值
                return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
            }
        } else {
            // 旧版本继续使用旧API
            let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            return window?.safeAreaInsets ?? UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        }
    }
    
    // 是否使用自定义布局
    var useCustomLayout: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserPreferenceKeys.useCustomLayout)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserPreferenceKeys.useCustomLayout)
        }
    }
    
    // 计算黑洞中心Y坐标因子
    func blackHoleCenterYFactor() -> CGFloat {
        // 如果使用自定义布局，从UserDefaults获取
        if useCustomLayout, let customValue = UserDefaults.standard.object(forKey: UserPreferenceKeys.centerYOffset) as? CGFloat {
            return customValue
        }
        
        // 否则使用默认计算
        let deviceType = DeviceType.current()
        let orientation = Orientation.current()
        let safeAreaTop = safeAreaInsets.top
        
        // 根据设备类型和方向动态调整
        switch (deviceType, orientation) {
        case (.smallPhone, .portrait):
            return 0.14 + (safeAreaTop > 20 ? 0.01 : 0)
        case (.mediumPhone, .portrait):
            return 0.12 + (safeAreaTop > 20 ? 0.01 : 0)
        case (.largePhone, .portrait):
            return 0.11 + (safeAreaTop > 20 ? 0.01 : 0)
        case (.tablet, .portrait):
            return 0.1
        case (_, .landscape):
            // 横屏时调整位置更靠近顶部
            return 0.08
        }
    }
    
    // 计算整体组件的Y轴偏移量
    func componentYOffset() -> CGFloat {
        // 如果使用自定义布局，从UserDefaults获取
        if useCustomLayout, let customValue = UserDefaults.standard.object(forKey: UserPreferenceKeys.componentOffset) as? CGFloat {
            return customValue
        }
        
        // 否则使用默认计算
        let deviceType = DeviceType.current()
        let orientation = Orientation.current()
        let screenHeight = UIScreen.main.bounds.height
        
        // 根据设备类型和方向动态调整
        switch (deviceType, orientation) {
        case (.smallPhone, .portrait):
            return -screenHeight * 0.08
        case (.mediumPhone, .portrait):
            return -screenHeight * 0.1
        case (.largePhone, .portrait):
            return -screenHeight * 0.12
        case (.tablet, .portrait):
            return -screenHeight * 0.1
        case (_, .landscape):
            // 横屏时减小偏移量
            return -screenHeight * 0.06
        }
    }
    
    // 计算按钮环绕半径
    func orbitalRadius() -> CGFloat {
        // 如果使用自定义布局，从UserDefaults获取
        if useCustomLayout, let customValue = UserDefaults.standard.object(forKey: UserPreferenceKeys.orbitalRadius) as? CGFloat {
            return customValue
        }
        
        // 否则使用默认计算
        let deviceType = DeviceType.current()
        let orientation = Orientation.current()
        let screenWidth = UIScreen.main.bounds.width
        
        // 根据设备类型和方向动态调整 - 减小半径值以确保按钮不会超出屏幕
        switch (deviceType, orientation) {
        case (.smallPhone, _):
            return screenWidth * 0.32 // 从0.36减小到0.32
        case (.mediumPhone, _):
            return screenWidth * 0.34 // 从0.38减小到0.34
        case (.largePhone, _):
            return screenWidth * 0.36 // 从0.4减小到0.36
        case (.tablet, .portrait):
            return screenWidth * 0.28 // 从0.3减小到0.28
        case (.tablet, .landscape):
            return screenWidth * 0.22 // 从0.25减小到0.22
        }
    }
    
    // 保存自定义布局设置
    func saveCustomLayout(centerYFactor: CGFloat, componentOffset: CGFloat, radius: CGFloat) {
        UserDefaults.standard.set(centerYFactor, forKey: UserPreferenceKeys.centerYOffset)
        UserDefaults.standard.set(componentOffset, forKey: UserPreferenceKeys.componentOffset)
        UserDefaults.standard.set(radius, forKey: UserPreferenceKeys.orbitalRadius)
        useCustomLayout = true
    }
    
    // 重置为默认布局
    func resetToDefaultLayout() {
        UserDefaults.standard.removeObject(forKey: UserPreferenceKeys.centerYOffset)
        UserDefaults.standard.removeObject(forKey: UserPreferenceKeys.componentOffset)
        UserDefaults.standard.removeObject(forKey: UserPreferenceKeys.orbitalRadius)
        useCustomLayout = false
    }
    
    // 获取当前布局设置
    func getCurrentLayoutSettings() -> (centerYFactor: CGFloat, componentOffset: CGFloat, radius: CGFloat) {
        return (
            centerYFactor: blackHoleCenterYFactor(),
            componentOffset: componentYOffset(),
            radius: orbitalRadius()
        )
    }
    
    private init() {}
}

/**
 * 按钮内容视图
 * 封装了按钮的外观样式
 */
private struct ButtonContent: View {
    let text: String
    let isSelected: Bool
    let fontSize: CGFloat
    let padding: (vertical: CGFloat, horizontal: CGFloat)
    let themeColor: Color
    
    // 判断按钮所属的类别
    private var isPartOfSituation: Bool {
        // 基于已知的情境选项判断
        let situationOptions = ["寻找答案", "做决定", "需要灵感", "思考人生"]
        return situationOptions.contains(text)
    }
    
    private var isPartOfExpectation: Bool {
        // 基于已知的期望选项判断
        let expectationOptions = ["被看见", "新视角", "实用建议", "共鸣与安慰"]
        return expectationOptions.contains(text)
    }
    
    // 根据按钮所属类别确定颜色
    private var buttonThemeColor: Color {
        if isPartOfSituation {
            return Color(red: 0.2, green: 0.4, blue: 0.8) // 使用更柔和的蓝色
        } else if isPartOfExpectation {
            return Color(red: 0.6, green: 0.3, blue: 0.7) // 使用更柔和的紫色
        } else {
            return themeColor // 其他情况使用传入的主题色
        }
    }
    
    // 按钮背景色 - 提供更好的反馈
    private var buttonBackgroundColor: Color {
        if isSelected {
            // 选中状态使用更高饱和度
            return buttonThemeColor.opacity(0.45)
        } else {
            // 未选中状态使用统一的暗色调
            return Color(white: 0.12, opacity: 0.6)
        }
    }
    
    // 按钮边框色 - 增强可见性和层次感
    private var buttonBorderColor: Color {
        if isSelected {
            return buttonThemeColor.opacity(0.7)
        } else {
            return Color.white.opacity(0.25)
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: isSelected ? .medium : .regular, design: .rounded))
            .foregroundColor(isSelected ? .white : .white.opacity(0.85))
            .padding(.vertical, padding.vertical)
            .padding(.horizontal, padding.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(buttonBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                buttonBorderColor, 
                                lineWidth: isSelected ? 1.0 : 0.7
                            )
                    )
            )
            // 使用更微妙的阴影效果，符合iOS设计语言
            .shadow(
                color: isSelected ? buttonThemeColor.opacity(0.4) : Color.black.opacity(0.2), 
                radius: isSelected ? 4 : 2, 
                x: 0, 
                y: 0
            )
            // 缩小选中状态的放大效果，更加微妙
            .scaleEffect(isSelected ? 1.08 : 1.0)
    }
}

/**
 * 按钮动画修饰符
 * 封装了按钮的脉冲动画效果
 */
private struct ButtonAnimationModifier: ViewModifier {
    let showAnimation: Bool
    let index: Int
    let themeColor: Color
    @Binding var animationState: Bool
    let buttonText: String
    
    // 判断按钮所属的类别
    private var isPartOfSituation: Bool {
        // 基于已知的情境选项判断
        let situationOptions = ["寻找答案", "做决定", "需要灵感", "思考人生"]
        return situationOptions.contains(buttonText)
    }
    
    private var isPartOfExpectation: Bool {
        // 基于已知的期望选项判断
        let expectationOptions = ["被看见", "新视角", "实用建议", "共鸣与安慰"]
        return expectationOptions.contains(buttonText)
    }
    
    // 根据按钮所属类别确定动画颜色
    private var animationColor: Color {
        if isPartOfSituation {
            return Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.5) // 使用更柔和的蓝色
        } else if isPartOfExpectation {
            return Color(red: 0.6, green: 0.3, blue: 0.7).opacity(0.5) // 使用更柔和的紫色
        } else {
            return themeColor.opacity(0.5) // 其他情况使用传入的主题色
        }
    }
    
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if showAnimation {
                    // 创建一个简化的圆形动画
                    let animationDuration: Double = 1.5
                    let repeatCount: Int = 3
                    let animationDelay: Double = Double(index) * 0.2
                    
                    Circle()
                        .stroke(animationColor, lineWidth: 1.2)
                        .scaleEffect(1.2)
                        .opacity(0)
                        .animation(
                            Animation.easeInOut(duration: animationDuration)
                                .repeatCount(repeatCount)
                                .delay(animationDelay),
                            value: showAnimation
                        )
                        .onAppear {
                            // 减少自动关闭时间，提高响应性
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation {
                                    self.animationState = false
                                }
                            }
                        }
                }
            }
        )
    }
}

// UIResponder扩展，用于获取当前第一响应者
extension UIResponder {
    private static weak var _currentFirstResponder: UIResponder?
    
    static func currentFirstResponder() -> UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }
    
    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
}

/**
 * 闪烁图标视图 - 用于显示生成中的加载动画
 * 遵循苹果设计理念，简洁而有目的性
 */
private struct SparkleIconView: View {
    var isAnimating: Bool
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var rotationAngle: Double = 0
    
    // 使用系统黄色而不是自定义颜色，保持一致性
    private let activeColor = Color.yellow
    private let inactiveColor = Color.secondary

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(isAnimating ? activeColor : inactiveColor)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotationAngle))
            .opacity(opacity)
            .onAppear {
                updateAnimation(shouldAnimate: isAnimating)
                #if DEBUG
                print("⭐️ SparkleIconView出现，初始isAnimating状态：\(isAnimating)")
                #endif
            }
            .onChange(of: isAnimating) { _, shouldAnimate in
                #if DEBUG
                print("⭐️ SparkleIconView状态变化：isAnimating = \(shouldAnimate)")
                #endif
                updateAnimation(shouldAnimate: shouldAnimate)
                
                // 当动画从激活状态变为非激活状态时，直接应用动画
                // 不再需要特殊的完成效果
            }
    }
    
    // 将动画逻辑提取到一个方法中，以便在onAppear和onChange中复用
    private func updateAnimation(shouldAnimate: Bool) {
        if shouldAnimate {
            // 清晰简洁的脉冲效果
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.15
                opacity = 0.8
            }
            
            // 轻微旋转，增加活跃感但不分散注意力
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: true)) {
                rotationAngle = 8
            }
        } else {
            // 当动画停止时，平滑地恢复到初始状态
            withAnimation(.easeInOut(duration: 0.2)) {
                scale = 1.0
                opacity = 1.0
                rotationAngle = 0
            }
        }
    }
}
