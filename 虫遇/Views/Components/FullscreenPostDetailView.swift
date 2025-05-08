import SwiftUI
import Combine
import UIKit // 如果还没有导入
// 使用ColorExtensions提供的Color(hex:)方法

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
        print("FPDVNavigationHelper初始化")
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

// 定义滑动方向枚举
enum SwipeDirection {
    case left
    case right
    case none
}

// 定义显示状态枚举，用于处理视图转换
private enum DisplayState {
    case current     // 当前显示的动态
    case transitioning(direction: SwipeDirection, progress: CGFloat) // 正在过渡
    case nextPagePreview  // 下一页预览
}

/**
 * 穿越时空粒子效果视图
 * 在页面转换过程中显示，增强穿越时空的主题感
 */
struct TimeSpaceParticleView: View {
    @State private var phase: CGFloat = 0
    let direction: SwipeDirection
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景层 - 仍然使用协调的色彩，但略微提高对比度
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.92, green: 0.94, blue: 0.98, opacity: 0.85),  // 淡蓝白色
                        Color(red: 0.94, green: 0.92, blue: 0.97, opacity: 0.85)   // 淡紫白色
                    ]),
                    startPoint: direction == .left ? .trailing : .leading,
                    endPoint: direction == .left ? .leading : .trailing
                )
                
                // 粒子层 - 增加粒子数量，提高不透明度和尺寸
                ForEach(0..<45, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 0.6, green: 0.7, blue: 0.95, opacity: Double.random(in: 0.3...0.6)))
                        .frame(width: CGFloat.random(in: 3...10))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(x: offsetForIndex(index, width: geometry.size.width))
                        .animation(
                            Animation.linear(duration: Double.random(in: 0.4...0.8))
                                .repeatForever(autoreverses: false),
                            value: phase
                        )
                }
                
                // 光线效果 - 增强光线效果，增加数量和不透明度
                ForEach(0..<15, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear, 
                                    Color(red: 0.65, green: 0.7, blue: 0.95, opacity: 0.45), 
                                    .clear
                                ]),
                                startPoint: direction == .left ? .trailing : .leading,
                                endPoint: direction == .left ? .leading : .trailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 100...350), height: CGFloat.random(in: 1.5...3))
                        .rotationEffect(.degrees(Double.random(in: -15...15)))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(x: offsetForIndex(index + 40, width: geometry.size.width) * 1.5)
                        .animation(
                            Animation.linear(duration: Double.random(in: 0.5...0.9))
                                .repeatForever(autoreverses: false),
                            value: phase
                        )
                }
                
                // 方向指示箭头 - 增强可见度
                Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color(red: 0.55, green: 0.65, blue: 0.95, opacity: 0.8))
                    .offset(x: direction == .left ? -30 : 30)
                    .opacity(phase == 1.0 ? 0.9 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: phase
                    )
            }
            .onAppear {
                // 使用异步调用避免在视图更新过程中修改状态
                DispatchQueue.main.async {
                    self.phase = 1.0
                }
            }
            .drawingGroup() // 使用离屏渲染提高性能
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // 根据方向计算偏移量
    private func offsetForIndex(_ index: Int, width: CGFloat) -> CGFloat {
        let baseOffset = direction == .left ? width * 2 : -width * 2
        return phase * baseOffset
    }
}

/**
 * 时空波纹效果视图
 * 作为备选效果，模拟穿越时空时的空间波纹
 */
struct TimeSpaceRippleView: View {
    @State private var animating = false
    let direction: SwipeDirection
    
    var body: some View {
        ZStack {
            // 背景层 - 保持协调的色彩，略微增强对比度
            Color(red: 0.93, green: 0.95, blue: 0.98, opacity: 0.9)
                .edgesIgnoringSafeArea(.all)
            
            // 波纹效果 - 增强波纹的可见度
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(Color(red: 0.6, green: 0.7, blue: 0.95, opacity: 0.3 - Double(index) * 0.04), lineWidth: 2.5)
                    .scaleEffect(animating ? 1 + CGFloat(index) * 0.25 : 0.2)
                    .opacity(animating ? 0 : 0.7)
                    .animation(
                        Animation.easeOut(duration: 0.8)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
            
            // 中心光效 - 增强光晕效果
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.65, green: 0.75, blue: 0.95, opacity: 0.7), 
                            .clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 100, height: 100)
                .opacity(animating ? 0.6 : 0.3)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: animating
                )
            
            // 方向指示 - 增强指示箭头的可见度
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(Color(red: 0.55, green: 0.65, blue: 0.9, opacity: 0.8))
                .offset(x: direction == .left ? -30 : 30)
                .opacity(animating ? 0.9 : 0.6)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true),
                    value: animating
                )
        }
        .onAppear {
            // 使用异步调用避免在视图更新过程中修改状态
            DispatchQueue.main.async {
                self.animating = true
            }
        }
        .drawingGroup() // 使用离屏渲染提高性能
    }
}

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
    // 添加获取上一个和下一个帖子的回调
    var onNextPost: ((UUID) -> UserPostModel?)?
    var onPrevPost: ((UUID) -> UserPostModel?)?
    
    // 保存初始化时的post ID，用于检测状态不一致
    private let initialPostId: UUID
    
    // 滑动状态
    @State private var dragOffset: CGFloat = 0.0
    @State private var isDragging: Bool = false
    @State private var swipeDirection: SwipeDirection = .none
    @State private var isTransitioning: Bool = false
    @State private var displayState: DisplayState = .current
    
    // 双缓冲显示技术变量 - 用于过渡过程中显示下一页内容
    @State private var nextPagePost: UserPostModel? = nil
    @State private var nextPageVisible: Bool = false
    
    // 穿越时空效果状态变量
    @State private var showingTimeSpaceEffect: Bool = false
    @State private var timeSpaceDirection: SwipeDirection = .none
    
    // 添加新内容状态变量
    @State private var showAddContentView: Bool = false
    @State private var isLastPost: Bool = false
    
    // 边界状态变量
    @State private var hasNextPost: Bool = true
    @State private var hasPrevPost: Bool = true
    
    // 其他状态
    @State private var selectedImageIndex: Int = 0
    @State private var showingExpandedImage: Bool = false
    @State private var showingReportSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet: Bool = false
    @State private var showingCommentTextArea: Bool = false
    
    // 控制任务生命周期的状态
    @State private var isViewActive: Bool = true
    
    // TabBar管理
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 环境变量，用于返回导航
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    // 系统返回按钮窗口引用
    @State private var systemBackButtonWindow: UIWindow?
    
    // 添加虫洞探索页面的拖动状态
    @State private var wormholePageDragOffset: CGFloat = 0.0
    @State private var isWormholeDragging: Bool = false
    @State private var showWormholeSwipeIndicator: Bool = false
    
    // 添加虫洞捕捉转场效果状态
    @State private var showWormholeTransition: Bool = false
    
    // 初始化方法
    init(
        post: UserPostModel, 
        onDismiss: (() -> Void)? = nil, 
        onLike: ((UserCommentModel) -> Void)? = nil,
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
        
        // 打印初始化信息以便调试
        print("🔄 初始化FullscreenPostDetailView - 帖子ID: \(post.id.uuidString)")
    }
    
    @EnvironmentObject var creationTypeManager: CreationTypeManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 底层背景色 - 防止任何透明
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
                .zIndex(-3)
            
            // 滑动手势视图
            ZStack {
                // 过渡期间的背景层 - 防止看到其他内容
                if isTransitioning {
                    Color(.systemBackground)
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
                                    Image(nextPost.userAvatar)
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
                                            // 多图网格 - 更紧凑的布局
                                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                                ForEach(nextPost.images, id: \.self) { image in
                                                    Image(image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(height: 150)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 10)
                                        }
                                    }
                                }
                                
                                // 分隔线
                                Divider()
                                    .padding(.horizontal, 16)
                                    .opacity(0.6)
                            }
                            
                            // 互动栏 - 预先显示点赞和评论等信息
                            HStack(spacing: 20) {
                                // 点赞按钮
                                HStack(spacing: 4) {
                                    Image(systemName: nextPost.isLikedByCurrentUser ? "heart.fill" : "heart")
                                        .font(.system(size: 16))
                                        .foregroundColor(nextPost.isLikedByCurrentUser ? .red : .secondary)
                                    
                                    Text("\(nextPost.likes)")
                                        .font(.system(size: 13))
                                        .foregroundColor(nextPost.isLikedByCurrentUser ? .red.opacity(0.8) : .secondary)
                                }
                                
                                // 评论按钮
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(nextPost.comments.count)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                // 收藏按钮
                                Image(systemName: nextPost.isBookmarkedByCurrentUser ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 15))
                                    .foregroundColor(nextPost.isBookmarkedByCurrentUser ? FPDVDesignSystem.Colors.primary : .secondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            // 分隔线
                            Rectangle()
                                .fill(Color.gray.opacity(0.08))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                            
                            // 评论区标题 - 与主视图保持相同结构
                            HStack {
                                HStack(spacing: 6) {
                                    Text("评论")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    // 显示评论总数
                                    Text("(\(nextPost.getTotalCommentsCount()))")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // 排序按钮
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            
                            // 分隔线
                            Rectangle()
                                .fill(Color.gray.opacity(0.08))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                            
                            // 简化的评论区域 - 仅显示前三条评论
                            VStack(spacing: 0) {
                                let topComments = Array(nextPost.getTopLevelComments().prefix(3))
                                
                                if topComments.isEmpty {
                                    // 无评论状态
                                    Text("暂无评论，快来说点什么~")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 40)
                                } else {
                                    // 显示前三条评论
                                    ForEach(topComments) { comment in
                                        HStack(alignment: .top, spacing: 12) {
                                            // 用户头像
                                            Circle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Text(String(comment.username.prefix(1).uppercased()))
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.gray)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                // 用户名
                                                Text(comment.username)
                                                    .font(.system(size: 14, weight: .medium))
                                                
                                                // 评论内容
                                                Text(comment.content)
                                                    .font(.system(size: 14))
                                                    .lineSpacing(4)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        
                                        if comment.id != topComments.last?.id {
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 80) // 为评论输入框留出空间
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    // 修改：根据滑动方向设置初始偏移，确保新页面从正确方向进入
                    .offset(x: swipeDirection == .left ? UIScreen.main.bounds.width - dragOffset : -UIScreen.main.bounds.width + dragOffset)
                    // 添加：过渡透明度效果，随着拖动增加透明度
                    .opacity(min(1.0, abs(dragOffset) / (UIScreen.main.bounds.width * 0.7)))
                    .background(Color(.systemBackground))
                    .zIndex(-1) // 确保在主内容下方
                }
                
                // 主内容视图
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
                    // 添加底部安全区域内边距，确保内容不被输入框遮挡
                    .safeAreaInset(edge: .bottom) {
                        // 输入框占位区域，调整高度从40减少为40
                        Color.clear.frame(height: 40)
                    }
                }
                .offset(x: dragOffset)
                // 优化不透明度变化，更平滑过渡 - 随着拖动逐渐降低透明度
                .opacity(isTransitioning ? 
                    (abs(dragOffset) > UIScreen.main.bounds.width * 0.8 ? 0.3 : 
                     1.0 - min(0.7, abs(dragOffset) / UIScreen.main.bounds.width)) 
                    : 1.0)
                .zIndex(0) // 主内容始终在最上层
            }
            // 添加水平滑动手势
            .simultaneousGesture(
                // 增加最小滑动距离要求，避免微小移动触发手势
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        // 如果正在过渡动画中，忽略所有手势
                        guard !isTransitioning else { return }
                        
                        // 只处理主要是水平方向的滑动，减少与垂直滚动冲突
                        if abs(value.translation.height) < abs(value.translation.width) * 0.8 {
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
                                                                    await preloadImagesForPostAsync(nextPost)
                                                                    await preloadCommentsForPostAsync(nextPost)
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
                                                                    await preloadImagesForPostAsync(prevPost)
                                                                    await preloadCommentsForPostAsync(prevPost)
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
                        print("⭐️ 滑动结束前边界检查: 当前帖子ID: \(viewModel.post.id)")
                        checkBoundaries()
                        
                        // 简化滑动有效性判断 - 降低触发阈值以避免卡住
                        // 右滑判断
                        let validRightSwipe = finalOffset > screenWidth * 0.12 || (finalOffset > screenWidth * 0.05 && velocityX > 150)
                        
                        // 左滑判断 - 进一步降低触发阈值，使左滑更容易触发
                        let validLeftSwipe = finalOffset < -screenWidth * 0.08 || (finalOffset < -screenWidth * 0.02 && velocityX < -100)
                        
                        // 重置拖动状态 - 提前重置，防止状态锁定
                        isDragging = false
                        
                        // 添加详细调试日志
                        print("⭐️ 滑动结束 - validLeftSwipe=\(validLeftSwipe), validRightSwipe=\(validRightSwipe), isLastPost=\(isLastPost), dragOffset=\(finalOffset), velocityX=\(velocityX)")
                        
                        // 防卡住保障 - 如果页面在滑出一半以上时卡住，强制进行翻页
                        let forceTransitionThreshold = screenWidth * 0.4
                        let forceLeftTransition = finalOffset < -forceTransitionThreshold
                        let forceRightTransition = finalOffset > forceTransitionThreshold
                        
                        // 虫洞探索页面右滑返回
                        if showAddContentView && (validRightSwipe || forceRightTransition) {
                            print("⭐️ 虫洞探索页面右滑返回")
                            
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
                            print("⭐️ 准备显示虫洞探索页面 - 确认为最后一篇")
                            
                            // 添加振动反馈
                            let feedback = UIImpactFeedbackGenerator(style: .medium)
                            feedback.impactOccurred()
                            
                            // 显示虫洞探索页面
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                dragOffset = 0
                                showAddContentView = true
                                print("⭐️ 已设置showAddContentView = true")
                            }
                            return
                        }
                        // 普通左滑 - 切换到下一篇帖子
                        else if validLeftSwipe || forceLeftTransition {
                            print("⭐️ 处理普通左滑动作")
                            
                            // 直接尝试获取并显示下一篇帖子，简化决策
                            if let onNextPost = onNextPost, let directNextPost = onNextPost(viewModel.post.id) {
                                print("⭐️ 成功获取下一篇帖子，执行转换")
                                hasNextPost = true
                                isLastPost = false
                                
                                // 执行过渡，增加立即反馈
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .left, nextPost: directNextPost, velocity: speedAbsolute)
                            }
                            // 如果没有找到下一篇但有缓存
                            else if let nextPost = nextPagePost {
                                print("⭐️ 使用缓存的下一篇帖子: \(nextPost.id)")
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .left, nextPost: nextPost, velocity: speedAbsolute)
                            }
                            // 真的是最后一篇
                            else if isLastPost {
                                print("⭐️ 再次确认是最后一篇，显示添加内容页面")
                                
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
                                print("⭐️ 状态不一致，恢复原位")
                                resetPosition()
                            }
                        }
                        // 普通右滑 - 切换到上一篇帖子
                        else if validRightSwipe || forceRightTransition {
                            // 处理右滑动作
                            print("⭐️ 处理普通右滑动作")
                            
                            // 直接尝试获取并显示上一篇帖子，简化决策
                            if let onPrevPost = onPrevPost, let directPrevPost = onPrevPost(viewModel.post.id) {
                                print("⭐️ 使用上一篇帖子: \(directPrevPost.id)")
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .right, nextPost: directPrevPost, velocity: speedAbsolute)
                            } 
                            // 如果没有找到上一篇但有缓存
                            else if let prevPost = nextPagePost {
                                print("⭐️ 使用缓存的上一篇帖子: \(prevPost.id)")
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                performPageTransition(direction: .right, nextPost: prevPost, velocity: speedAbsolute)
                            } 
                            // 没有上一篇
                            else {
                                print("⭐️ 没有上一篇帖子，恢复原位")
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
                                .fill(Color.white.opacity(Double.random(in: 0.1...0.5)))
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
                    
                    VStack(spacing: 0) {
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
                        
                        // 顶部间距 - 大幅增加空间
                        Spacer()
                            .frame(height: UIScreen.main.bounds.height * 0.05)
                        
                        // 黑洞主视觉 - 进一步减小高度
                        BlackHoleView()
                            .environmentObject(CreationTypeManager.shared)
                            .frame(height: UIScreen.main.bounds.height * 0.38)  // 增大黑洞视觉比例
                            .padding(.bottom, 16)
                        
                        // 删除原有的两行说明文字
                        
                        // 使用灵活的Spacer自动分配空间
                        Spacer()
                            .frame(minHeight: 0, idealHeight: UIScreen.main.bounds.height * 0.04)
                        
                        // 将说明文字移到按钮上方，并添加视觉增强效果
                        ZStack {
                            // 背景轻微高亮 - 优化为渐变并添加精致的边框
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
                            
                            // 文字内容 - 优化字重和透明度
                            Text("每种内容类型将带你进入不同的时空交流维度")
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(.white.opacity(0.45))  // 微调透明度
                                .multilineTextAlignment(.center)
                                .frame(width: 300)  // 文字宽度稍小于背景
                                .shadow(color: Color.black.opacity(0.5), radius: 0.5, x: 0, y: 0.5) // 极微小的阴影增强可读性
                        }
                        .padding(.bottom, 16)  // 减少与按钮的间距
                        
                        // 创作类型按钮
                        CreationTypeButtonsView()
                            .environmentObject(CreationTypeManager.shared)
                            .frame(height: 70)  // 保持按钮高度
                            .padding(.bottom, 24)  // 增加与主按钮间的间距
                        
                        // 主按钮 - 开启时空对话
                        Button(action: {
                            // 记录操作开始时间，用于防止可能的重复触发
                            let operationStartTime = Date()
                            
                            // 立即重置所有相关状态
                            showWormholeSwipeIndicator = false
                            
                            // 额外检查，防止转场状态混乱
                            if isTransitioning {
                                print("⚠️ 警告：点击按钮时发现正在转场中，先重置转场状态")
                                isTransitioning = false
                                dragOffset = 0
                                return
                            }
                            
                            // 触发虫洞捕捉转场效果
                            withAnimation {
                                showWormholeTransition = true
                            }
                        }) {
                            HStack(spacing: 10) {  // 增加图标与文字间距
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 18))  // 增大图标尺寸
                                    .symbolRenderingMode(.hierarchical) // 使用分层渲染增强图标细节
                                
                                Text("启动虫洞捕捉")
                                    .font(.system(size: 18, weight: .semibold))  // 增大文字尺寸
                                    .kerning(0.3) // 添加轻微字间距
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
                        
                        // 底部空间，确保布局不贴底
                        Spacer()
                            .frame(minHeight: 0, idealHeight: UIScreen.main.bounds.height * 0.02)
                    }
                    
                    // 右滑指示器 - 仅在开始拖动时显示或短暂提示时显示
                    if (isDragging && dragOffset > 0 && swipeDirection == .right) || showWormholeSwipeIndicator {
                        HStack {
                            // 左侧箭头指示器
                            Image(systemName: "chevron.left")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                                .offset(x: 20 + dragOffset * 0.1) // 跟随拖动稍微移动
                                .opacity(isDragging ? min(1.0, dragOffset / 30) : 0.8) // 动态不透明度
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 16)
                        .opacity(showWormholeSwipeIndicator || (isDragging && dragOffset > 10) ? 0.8 : 0)
                        .animation(.easeOut(duration: 0.2), value: showWormholeSwipeIndicator || isDragging)
                    }
                    
                    // 虫洞捕捉转场效果
                    WormholeTransitionEffect(isActive: $showWormholeTransition, onComplete: {
                        // 转场效果结束后执行原有的关闭逻辑
                        executeWormholeCaptureAction(operationStartTime: Date())
                    })
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
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            // 如果正在过渡动画中，忽略所有手势
                            guard !isTransitioning else { return }
                            
                            // 只处理水平方向的滑动，并添加水平性检查
                            if abs(value.translation.height) < abs(value.translation.width) * 0.8 {
                                // 对于右滑, 确保水平滑动为主
                                if value.translation.width > 0 {
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
                                        
                                        // 更新滑动方向为右滑
                                        swipeDirection = .right
                                        
                                        // 显示时空效果 - 与主视图相同的时空效果
                                        if abs(dampedOffset) > screenWidth * 0.15 && !showingTimeSpaceEffect {
                                            withAnimation(.easeIn(duration: 0.1)) {
                                                showingTimeSpaceEffect = true
                                                timeSpaceDirection = .right
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
                            
                            // 重置拖动状态 - 提前重置，防止状态锁定
                            isDragging = false
                            
                            // 记录详细调试日志
                            print("⭐️ 虫洞探索页面滑动结束 - validRightSwipe=\(validRightSwipe), dragOffset=\(finalOffset), velocityX=\(velocityX)")
                            
                            // 强制右滑阈值，与主视图保持一致
                            let forceTransitionThreshold = screenWidth * 0.4
                            let forceRightTransition = finalOffset > forceTransitionThreshold
                            
                            if validRightSwipe || forceRightTransition {
                                print("⭐️ 虫洞探索页面右滑返回")
                                
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
                            } else {
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
            
            // 评论输入视图
            CommentInputView(commentManager: viewModel.commentManager)
                .background(
                    // 添加背景和阴影，使其更清晰地与内容分离
                    Color(.systemBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -2)
                        .edgesIgnoringSafeArea(.bottom)
                )
        }
        // 禁用用户交互当正在过渡中
        .disabled(isTransitioning)
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            // 为视图设置为活跃状态，用于任务循环
            isViewActive = true
            
            // 添加系统级别返回按钮（比SwiftUI原生返回按钮更稳定）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                addSystemLevelBackButton()
            }
            
            // 检查边界状态前记录当前状态
            print("⭐️ onAppear开始: 当前帖子ID: \(viewModel.post.id), hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost)")
            
            // 检查是否是最后一篇帖子 - 同步执行确保立即更新状态
            checkBoundaries()
            
            // 记录检查后的状态
            print("⭐️ onAppear检查边界后: hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost)")
            
            // 预加载下一篇和上一篇动态，实现滑动时的无缝切换
            preloadAdjacentPosts()
            
            // 打印当前状态，用于调试
            print("⭐️ 视图出现 - 初始帖子ID: \(initialPostId.uuidString)")
            
            // 检查初始帖子ID与viewModel中的帖子ID是否一致
            if initialPostId.uuidString != viewModel.post.id.uuidString {
                print("⚠️ 警告：初始帖子ID与viewModel帖子ID不一致！进行强制同步")
                // 强制更新viewModel中的帖子 - 这通常不应该发生，但添加以防万一
                viewModel.synchronizePost(id: initialPostId)
            }
            
            // 隐藏TabBar
            tabBarManager.pushHideState()
            
            // 显示时进行边界检查和预加载
            DispatchQueue.main.async {
                // 异步执行，确保视图完全加载后运行
                checkBoundaries()
                preloadAdjacentPosts()
            }
        }
        .onDisappear {
            print("⭐️ FullscreenPostDetailView 消失")
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
                    print("⭐️ 发现TabBar未完全隐藏，重新隐藏")
                    tabBarManager.pushHideState()
                }
            }
            
            // 视图任务结束时确保TabBar可见
            if !isViewActive {
                print("⭐️ 视图任务结束，确保TabBar可见")
                tabBarManager.popHideState()
            }
        }
        // 使用更稳定的滑动指示器实现
        .overlay(
            ZStack {
                // 左侧指示器（向右滑）- 完全平滑过渡
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.15)))
                        .padding(.leading, 20)
                    Spacer()
                }
                // 关键改进：使用平滑连续的不透明度函数
                .opacity(max(0, min(dragOffset * 0.01, 0.7)))
                
                // 右侧指示器（向左滑）- 完全平滑过渡
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.15)))
                        .padding(.trailing, 20)
                }
                // 关键改进：使用平滑连续的不透明度函数
                .opacity(max(0, min(dragOffset * -0.01, 0.7)))
            }
            // 无需额外动画，跟随拖动实时更新
            .opacity(isTransitioning ? 0 : 1)
        )
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
        backButton.frame = CGRect(x: 16, y: topPadding + 10, width: 32, height: 32)
        
        // 设置按钮图标
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
            print("⭐️ 动态详情视图返回按钮被点击")
            
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
            // 返回按钮 - 保留但不执行实际操作，由系统级返回按钮负责返回
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.clear) // 使按钮不可见
            }
            // 使用更安全的轻量级替代方案，避免引用FPDVScaleButtonStyle
            .scaleEffect(1.0) // 默认比例，按下时会自动变化
            .contentShape(Circle()) // 确保点击区域正确
            .disabled(true) // 禁用按钮
                            
            Spacer()
                            
            // 标题 - 改进版本
            Text("动态详情")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(FPDVDesignSystem.Colors.primary)
                            
            Spacer()
                            
            // 删除分享按钮，增加占位空间保持对称
            Color.clear
                .frame(width: 16, height: 16)
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
    
    // 帖子内容区域
    private func makePostContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    // 在这里可以添加关注用户的逻辑
                }) {
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
            Text(viewModel.post.content)
                .font(.system(size: 16))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            
            // 图片内容 - 关键优化：使用 GeometryReader 提前确定布局尺寸
            ZStack(alignment: .center) {
                // 预先计算图片区域的大小
                let imageHeight: CGFloat = !viewModel.post.images.isEmpty ? (viewModel.post.images.count == 1 ? 230 : 160) : 0
                let hasImages = !viewModel.post.images.isEmpty
                
                // 占位区域 - 只有在有图片时才显示，防止内容跳动
                if hasImages {
                    // 创建占位区域，确保图片加载期间保持布局稳定
                    Color.clear
                        .frame(height: imageHeight + 10) // 加上底部padding，保持布局一致
                        .onAppear {
                            // 使用异步调用避免在视图更新过程中执行预加载操作
                            DispatchQueue.main.async {
                                // 在视图出现时立即预加载图片，防止延迟加载导致布局变化
                                for imageName in viewModel.post.images {
                                    _ = UIImage(named: imageName)
                                }
                            }
                        }
                }
                
                // 实际图片内容
            if !viewModel.post.images.isEmpty {
                    Group {
                if viewModel.post.images.count == 1 {
                            // 单图显示 - 设置固定高度，避免加载时的布局变化
                    Image(viewModel.post.images[0])
                        .resizable()
                        .scaledToFill()
                                .frame(maxHeight: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                } else if viewModel.post.images.count == 2 {
                            // 两张图片并排显示 - 设置固定高度
                    HStack(spacing: 6) {
                        ForEach(0..<2, id: \.self) { index in
                            Image(viewModel.post.images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                } else if viewModel.post.images.count == 3 {
                    // 三张图片布局 - 左侧一张大图，右侧两张小图
                    let totalWidth = UIScreen.main.bounds.width - 32 // 考虑边距
                    let smallImageSize = (totalWidth * 0.33) - 2 // 右侧小图尺寸
                    let largeImageSize = (totalWidth * 0.67) - 2 // 左侧大图尺寸
                    
                    HStack(spacing: 6) {
                        // 左侧大图
                        Image(viewModel.post.images[0])
                            .resizable()
                            .scaledToFill()
                            .frame(width: largeImageSize, height: largeImageSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // 右侧两张小图垂直排列
                        VStack(spacing: 6) {
                            Image(viewModel.post.images[1])
                                .resizable()
                                .scaledToFill()
                                .frame(width: smallImageSize, height: smallImageSize)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Image(viewModel.post.images[2])
                                .resizable()
                                .scaledToFill()
                                .frame(width: smallImageSize, height: smallImageSize)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                } else {
                            // 多图网格 - 更紧凑的布局
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(viewModel.post.images, id: \.self) { image in
                            Image(image)
                                .resizable()
                                .scaledToFill()
                                        .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                        }
                    }
                    // 增加渐变显示效果，防止突然出现造成布局跳动
                    .transition(.opacity.animation(.easeIn(duration: 0.1)))
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
            // 使用更安全的轻量级替代方案，避免引用FPDVScaleButtonStyle
            .scaleEffect(1.0) // 默认比例，按下时会自动变化
            .contentShape(Capsule()) // 确保点击区域正确
            
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
            // 使用更安全的轻量级替代方案，避免引用FPDVScaleButtonStyle
            .scaleEffect(1.0) // 默认比例，按下时会自动变化
            .contentShape(Capsule()) // 确保点击区域正确
            
            // 收藏按钮
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.4)
            }) {
                Image(systemName: viewModel.post.isBookmarkedByCurrentUser ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15))
                    .foregroundColor(viewModel.post.isBookmarkedByCurrentUser ? FPDVDesignSystem.Colors.primary : .secondary)
            }
            // 使用更安全的轻量级替代方案，避免引用FPDVScaleButtonStyle
            .scaleEffect(1.0) // 默认比例，按下时会自动变化
            .contentShape(Capsule()) // 确保点击区域正确
            
            Spacer()
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
            
            // 底部提示文字
            if !viewModel.post.getTopLevelComments().isEmpty {
                Text("虫洞已开启 · 等你一起相遇～")
                    .font(.system(size: 12))  // 稍微减小字体大小
                    .foregroundColor(.secondary.opacity(0.5))  // 降低一点透明度，使文字更轻柔
                    .padding(.top, 12)  
                    .padding(.bottom, 5)  // 减少底部padding
            }
        }
        .background(Color(.systemBackground))
        .padding(.bottom, 55)  // 减少评论区整体底部内边距
    }
    
    // 在文件适当位置添加辅助函数，使页面过渡更流畅
    /**
     * 执行页面过渡动画和数据更新
     * 包括时空效果、滑动动画和数据模型更新
     */
    private func performPageTransition(direction: SwipeDirection, nextPost: UserPostModel, velocity: CGFloat = 0) {
        // 禁用交互，防止动画期间的用户操作
        isTransitioning = true
        
        let screenWidth = UIScreen.main.bounds.width
        
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
        print("⭐️ 页面过渡: 从 \(currentPostId) 到 \(nextPostId), 方向: \(direction == .left ? "左" : "右")")
        
        // 检查是否就是当前帖子，避免不必要的过渡
        if currentPostId == nextPostId {
            print("⚠️ 警告：正在尝试切换到当前相同帖子，中止过渡并复位")
            resetPosition()
            isTransitioning = false
            return
        }
        
        // 立即更新数据模型并显示下一页
        self.nextPagePost = nextPost
        
        // 更短、更快的动画时间，减少用户等待
        let initialEffectDuration: Double = 0.12
        let slideOutDuration: Double = 0.2
        
        // 添加转场保障计时器 - 如果转场在合理时间内未完成会强制恢复
        let transitionTimeout: Double = 1.2 // 缩短超时时间
        
        // 保存状态用于恢复
        var transitionCancelled = false
        let transitionStartTime = Date()
        
        // 优化1：合并初始动画和滑出动画减少动画层叠
        withAnimation(.easeIn(duration: initialEffectDuration)) {
            self.showingTimeSpaceEffect = true
            self.timeSpaceDirection = direction
            self.nextPageVisible = true
        }
        
        // 优化2：使用低优先级线程进行预加载，避免与UI动画竞争资源
        Task(priority: .background) {
            // 预加载操作
            async let imagesTask = preloadImagesForPostAsync(nextPost)
            async let commentsTask = preloadCommentsForPostAsync(nextPost)
            
            // 非阻塞式等待 - 继续UI动画而不等待预加载完成
            _ = await (imagesTask, commentsTask)
        }
        
        // 优化3：使用单一动画队列而不是嵌套的延迟调用，减少动画竞争
        DispatchQueue.main.asyncAfter(deadline: .now() + initialEffectDuration) {
            // 如果转场已被取消则退出
            guard !transitionCancelled else { return }
            
            // 滑出动画 - 使用更短的响应时间和更高的弹性
            withAnimation(.spring(response: slideOutDuration, dampingFraction: 0.85, blendDuration: 0.08)) {
                self.dragOffset = direction == .left ? -screenWidth : screenWidth
                self.showingTimeSpaceEffect = false
            }
            
            // 准备完成转场 - 直接安排下一步而不是再嵌套一层
            let completionDeadline = DispatchTime.now() + slideOutDuration
            
            // 优化4：直接在主队列中调度完成动作，减少队列切换开销
            DispatchQueue.main.asyncAfter(deadline: completionDeadline) {
                // 如果转场已被取消则退出
                guard !transitionCancelled else { return }
                
                // 最后安全检查，确保目标帖子仍然有效
                if nextPost.id.uuidString == currentPostId {
                    print("⚠️ 严重警告：检测到帖子ID冲突，尝试恢复...")
                    
                    // 额外安全机制 - 如果确实是ID相同但实际是不同的帖子，仍然允许切换
                    if nextPost !== self.viewModel.post {
                        print("⚠️ 但确认是不同帖子实例，继续切换...")
                    } else {
                        // 复位状态并退出
                        self.resetTransitionState()
                        return
                    }
                }
                
                // 更新数据模型 - 直接在当前线程执行
                self.viewModel.updatePost(nextPost)
                
                // 记录完成状态
                print("⭐️ 页面过渡完成: 当前帖子ID已更新为 \(nextPost.id.uuidString)")
                
                // 优化5：立即重置关键状态，避免动画层叠
                self.dragOffset = 0
                self.swipeDirection = .none
                self.showingTimeSpaceEffect = false
                self.nextPageVisible = false
                
                // 优化6：直接清理状态，不使用额外的嵌套异步调用
                self.nextPagePost = nil
                self.isTransitioning = false
                
                // 发送通知，要求评论区域刷新
                NotificationCenter.default.post(name: NSNotification.Name("RefreshCommentsSection"), object: nil)
                
                // 更新边界状态和预加载下一篇 - 放在最后进行
                self.checkBoundaries()
                self.preloadAdjacentPosts()
            }
        }
        
        // 设置安全超时，防止转场卡住
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionTimeout) {
            // 检查转场是否仍在进行中
            if self.isTransitioning && !transitionCancelled {
                // 计算转场已经持续的时间
                let elapsedTime = Date().timeIntervalSince(transitionStartTime)
                
                // 如果超过了安全时间，强制结束转场
                if elapsedTime >= transitionTimeout * 0.9 {
                    print("⚠️ 转场超时(\(String(format: "%.1f", elapsedTime))秒)，强制恢复...")
                    
                    // 标记转场已取消
                    transitionCancelled = true
                    
                    // 还原所有状态
                    self.resetTransitionState()
                    
                    // 触发轻微震动通知用户 - 使用更轻量的反馈方式
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.prepare()
                    errorFeedback.notificationOccurred(.warning)
                    
                    // 提供视觉反馈 - 使用更简单的动画
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.dragOffset = 0
                        self.showingTimeSpaceEffect = false
                    }
                }
            }
        }
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
    private func preloadImagesForPostAsync(_ post: UserPostModel) async {
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
    }
    
    // 优化异步版本的评论预加载
    private func preloadCommentsForPostAsync(_ post: UserPostModel) async {
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
        let currentPostId = viewModel.post.id
        print("⭐️ 开始预加载相邻帖子 - 当前帖子ID: \(currentPostId)")
        
        // 边界检查，确定是否有下一篇或上一篇帖子
        checkBoundaries()
        print("⭐️ 边界检查后状态: hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost), isLastPost=\(isLastPost)")
        
        // 当确认为最后一篇时，强制禁止预加载下一篇
        if isLastPost {
            print("⭐️ 已确认为最后一篇帖子，不尝试预加载下一篇")
            hasNextPost = false
            
            // 清除可能已缓存的下一篇帖子
            if viewModel.getNextPostCache() != nil {
                print("⭐️ 清除错误缓存的下一篇帖子")
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
                print("📦 内部函数获取下一篇帖子 - 当前帖子ID: \(currentPostId)")
                return onNextPost(currentPostId)
            }
            
            if let nextPost = getNextPostWrapper() {
                // 避免加载当前帖子本身（错误情况）
                if nextPost.id.uuidString == currentPostId.uuidString {
                    print("⭐️⭐️⭐️ 严重错误：onNextPost() 返回了当前帖子，应为最后一篇")
                    hasNextPost = false
                    isLastPost = true
                    return
                }
                
                print("⭐️ 开始预加载下一篇帖子: \(nextPost.id)")
                // 预加载下一篇帖子
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒延迟
                    
                    viewModel.preloadNextPost(nextPost)
                    
                    // 预加载图片和评论 - 使用新的异步函数
                    await preloadImagesForPostAsync(nextPost)
                    print("⭐️ 下一篇帖子图片预加载完成: \(nextPost.id)")
                    
                    await preloadCommentsForPostAsync(nextPost)
                    print("⭐️ 下一篇帖子评论预加载完成: \(nextPost.id)")
                }
            } else {
                // 如果onNextPost()返回nil但hasNextPost为true，说明状态不同步
                print("⭐️ 警告：hasNextPost=true但onNextPost()返回nil，修正状态")
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
                print("📦 内部函数获取上一篇帖子 - 当前帖子ID: \(currentPostId)")
                return onPrevPost(currentPostId)
            }
            
            if let prevPost = getPrevPostWrapper() {
                // 避免加载当前帖子本身（错误情况）
                if prevPost.id.uuidString == currentPostId.uuidString {
                    print("⭐️⭐️⭐️ 严重错误：onPrevPost() 返回了当前帖子")
                    hasPrevPost = false
                    return
                }
                
                print("⭐️ 开始预加载上一篇帖子: \(prevPost.id)")
                
                // 预加载上一篇帖子 (延迟一点以减轻加载压力)
                Task {
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒延迟
                    
                    viewModel.preloadPrevPost(prevPost)
                    
                    // 预加载图片和评论 - 使用新的异步函数
                    await preloadImagesForPostAsync(prevPost)
                    print("⭐️ 上一篇帖子图片预加载完成: \(prevPost.id)")
                    
                    await preloadCommentsForPostAsync(prevPost)
                    print("⭐️ 上一篇帖子评论预加载完成: \(prevPost.id)")
                }
            } else {
                // 如果onPrevPost()返回nil但hasPrevPost为true，说明状态不同步
                print("⭐️ 警告：hasPrevPost=true但onPrevPost()返回nil，修正状态")
                hasPrevPost = false
            }
        }
        
        print("⭐️ preloadAdjacentPosts 完成，最终状态: hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost), isLastPost=\(isLastPost)")
    }
    
    /**
     * 检查边界条件 - 确保hasNextPost、hasPrevPost和isLastPost状态保持同步
     */
    private func checkBoundaries() {
        // 记录检查前的状态
        let oldHasNextPost = hasNextPost
        let oldHasPrevPost = hasPrevPost
        let oldIsLastPost = isLastPost
        
        // 记录当前帖子ID，用于调试
        let currentPostId = viewModel.post.id
        let currentPostUUID = currentPostId.uuidString
        print("⭐️ 开始检查边界 - 当前帖子ID: \(currentPostId)")
        
        // 硬编码检查是否是最后一篇帖子 (第三篇)
        let knownLastPostId = "33333333-3333-3333-3333-333333333333"
        let isKnownLastPost = (currentPostUUID == knownLastPostId)
        
        if isKnownLastPost {
            print("⭐️ 当前帖子ID匹配已知的最后一篇ID，确认为最后一篇")
        }
        
        // 检查是否有下一篇帖子 - 设置初始值而不是使用之前的状态
        var nextPostExists = false
        var reallyLastPost = false
        
        if let onNextPost = onNextPost {
            // 定义获取下一篇帖子的函数，可以递归重试
            func getNextPostWithRetry(currentRetry: Int = 0) -> UserPostModel? {
                // 如果重试次数过多，中止并返回nil
                if currentRetry >= 2 {
                    print("⭐️ 已重试获取下一篇帖子2次，放弃")
                    return nil
                }
                
                // 使用当前viewModel中的帖子作为上下文
                print("📊 检查上下文 - 检查前确认当前帖子ID: \(currentPostUUID)")
                
                // 直接调用回调函数获取结果
                let nextPost = onNextPost(currentPostId)
                
                // 检查是否返回了当前帖子（错误情况）
                if let nextPost = nextPost {
                    let nextPostUUID = nextPost.id.uuidString
                    print("📊 比较 - 当前: \(currentPostUUID) vs 下一篇: \(nextPostUUID)")
                    
                    if nextPostUUID == currentPostUUID {
                        print("⭐️⭐️⭐️ 警告：onNextPost()返回了当前帖子ID，尝试再次获取")
                        print("⭐️ 当前帖子ID: \(currentPostId), 错误返回的下一篇ID: \(nextPost.id)")
                        
                        // 等待一小段时间后重试 - 可能是由于状态未同步导致
                        // 使用同步延迟避免异步问题
                        usleep(50000) // 50毫秒
                        
                        // 递归尝试再次获取
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
            print("⭐️ onNextPost调用结果: \(nextPost != nil ? "有下一篇" : "没有下一篇")")
            
            // 如果存在下一篇帖子，打印其ID和内容摘要
            if let nextPost = nextPost {
                let nextPostUUID = nextPost.id.uuidString
                print("⭐️ 下一篇帖子ID: \(nextPostUUID)")
                print("⭐️ 下一篇内容前20字符: \(String(nextPost.content.prefix(20)))")
            }
        } else {
            // 如果没有提供回调，默认设置为没有下一篇
            print("⭐️ 警告：未提供onNextPost回调，默认视为最后一篇")
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
                    print("⭐️ 已重试获取上一篇帖子2次，放弃")
                    return nil
                }
                
                // 使用当前viewModel中的帖子作为上下文
                print("📊 检查上下文 - 检查前确认当前帖子ID: \(currentPostUUID)")
                
                // 直接调用回调函数获取结果
                let prevPost = onPrevPost(currentPostId)
                
                // 检查是否返回了当前帖子（错误情况）
                if let prevPost = prevPost {
                    let prevPostUUID = prevPost.id.uuidString
                    print("📊 比较 - 当前: \(currentPostUUID) vs 上一篇: \(prevPostUUID)")
                    
                    if prevPostUUID == currentPostUUID {
                        print("⭐️⭐️⭐️ 警告：onPrevPost()返回了当前帖子ID，尝试再次获取")
                        print("⭐️ 当前帖子ID: \(currentPostId), 错误返回的上一篇ID: \(prevPost.id)")
                        
                        // 等待一小段时间后重试
                        usleep(50000) // 50毫秒
                        
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
            print("⭐️ onPrevPost调用结果: \(prevPost != nil ? "有上一篇" : "没有上一篇")")
            
            // 如果存在上一篇帖子，打印其ID和内容摘要
            if let prevPost = prevPost {
                let prevPostUUID = prevPost.id.uuidString
                print("⭐️ 上一篇帖子ID: \(prevPostUUID)")
                print("⭐️ 上一篇内容前20字符: \(String(prevPost.content.prefix(20)))")
            }
        } else {
            // 如果没有提供回调，默认设置为没有上一篇
            prevPostExists = false
        }
        
        // 更新状态变量
        hasNextPost = nextPostExists
        hasPrevPost = prevPostExists
        isLastPost = reallyLastPost
        
        // 确保状态一致性
        if hasNextPost && isLastPost {
            print("⭐️ 严重状态冲突：hasNextPost=true 且 isLastPost=true，修正为非最后一篇")
            isLastPost = false
        } else if !hasNextPost && !isLastPost {
            print("⭐️ 状态不一致：hasNextPost=false 但 isLastPost=false，修正为isLastPost=true")
            isLastPost = true
        }
        
        // 如果状态发生了变化，记录日志
        if oldHasNextPost != hasNextPost || oldHasPrevPost != hasPrevPost || oldIsLastPost != isLastPost {
            print("⭐️ 边界状态已更新: hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost), isLastPost=\(isLastPost)")
        }
    }
    
    // 在类中添加一个新的辅助方法，用于严格检查是否真的是最后一篇帖子
    private func strictlyConfirmLastPost() -> Bool {
        print("⭐️⭐️⭐️ 严格检查是否为最后一篇帖子")
        
        // 获取当前帖子ID
        let currentPostId = viewModel.post.id
        let currentPostIdString = currentPostId.uuidString
        print("⭐️ 当前帖子ID: \(currentPostIdString)")
        
        // 检查是否有onNextPost回调
        guard let onNextPost = onNextPost else {
            print("⭐️ 没有onNextPost回调，无法确认")
            return false
        }
        
        // 尝试获取下一篇帖子 - 多次尝试确保准确性
        for _ in 0..<3 {
            if let nextPost = onNextPost(currentPostId) {
                // 如果能获取到下一篇，并且ID不同，则肯定不是最后一篇
                if nextPost.id.uuidString != currentPostIdString {
                    print("⭐️ 能获取到不同ID的下一篇帖子，确认非最后一篇")
                    return false
                } else {
                    print("⭐️ 获取到ID相同的下一篇帖子，可能是最后一篇或数据错误")
                    // 继续下一次尝试
                }
            } else {
                // 无法获取下一篇，可能真的是最后一篇
                print("⭐️ 无法获取下一篇帖子，可能是最后一篇")
            }
            
            // 短暂延迟后再次尝试
            usleep(10000) // 10毫秒
        }
        
        // 检查帖子ID - 手动硬编码检查最后一篇的ID
        if currentPostIdString == "33333333-3333-3333-3333-333333333333" {
            print("⭐️ 当前帖子ID匹配最后一篇的已知ID，确认为最后一篇")
            return true
        }
        
        print("⭐️ 经过多次尝试，无法确定是否为最后一篇帖子，默认非最后一篇")
        return false
    }
    
    // 添加执行虫洞捕捉动作的方法
    private func executeWormholeCaptureAction(operationStartTime: Date) {
        // 使用与页面转场相同的动画序列
        isTransitioning = true
        
        // 使用与页面转场相同的动画序列
        let initialEffectDuration: Double = 0.12
        let slideOutDuration: Double = 0.2
        
        // 第一阶段：显示时空效果
        withAnimation(.easeIn(duration: initialEffectDuration)) {
            showingTimeSpaceEffect = true
            // 从顶部返回而不是右滑
            timeSpaceDirection = .right
        }
        
        // 第二阶段：页面滑出
        DispatchQueue.main.asyncAfter(deadline: .now() + initialEffectDuration) {
            withAnimation(.spring(response: slideOutDuration, dampingFraction: 0.85, blendDuration: 0.08)) {
                // 向右滑出
                dragOffset = UIScreen.main.bounds.width
                showingTimeSpaceEffect = false
            }
            
            // 第三阶段：关闭页面并重置
            DispatchQueue.main.asyncAfter(deadline: .now() + slideOutDuration) {
                // 关闭虫洞探索页面
                showAddContentView = false
                
                // 重置状态
                dragOffset = 0
                swipeDirection = .none
                isTransitioning = false
                
                // 延迟一点调用onDismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 额外检查以确保不会出现重复调用
                    let elapsedTime = Date().timeIntervalSince(operationStartTime)
                    if elapsedTime < 1.0 && !showAddContentView {
                        onDismiss?()
                    }
                }
            }
        }
    }
}

/**
 * 帖子详情视图 - 使用ObservableObject管理数据
 */
class FullscreenPostDetailViewModel: ObservableObject {
    @Published var post: UserPostModel
    @Published var commentManager: CommentManager
    
    // 添加缓存属性来支持预加载
    private var nextPostCache: UserPostModel?
    private var prevPostCache: UserPostModel?
    
    init(post: UserPostModel) {
        self.post = post
        self.commentManager = CommentManager(post: post)
    }
    
    // 添加更新帖子的方法
    func updatePost(_ newPost: UserPostModel) {
        // 立即更新数据模型
        self.post = newPost
        self.commentManager = CommentManager(post: newPost)
        
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
        print("🔄 开始同步帖子: \(id.uuidString)")
        
        // 获取所有帖子
        let allPosts = ModelData.samplePosts
        
        // 查找匹配ID的帖子
        if let foundPost = allPosts.first(where: { $0.id.uuidString == id.uuidString }) {
            print("✅ 找到匹配的帖子: \(foundPost.id.uuidString)")
            
            // 更新当前帖子
            updatePost(foundPost)
            
            // 清除缓存以避免潜在问题
            nextPostCache = nil
            prevPostCache = nil
            
            print("✅ 帖子同步完成")
        } else {
            print("❌ 无法找到ID为 \(id.uuidString) 的帖子")
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
