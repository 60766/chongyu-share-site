import SwiftUI
import Combine
import UIKit // 如果还没有导入
// 使用ColorExtensions提供的Color(hex:)方法

// 导入工程内其他模块，确保正确引用
// 全文件使用到的类型都正确导入

// 移除了本地CustomScaleButtonStyle的定义
// 直接使用Utils包中定义的CustomScaleButtonStyle


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
    var onNextPost: (() -> UserPostModel?)?
    var onPrevPost: (() -> UserPostModel?)?
    
    // 滑动状态
    @State private var dragOffset: CGFloat = 0
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
    
    // 初始化方法
    init(
        post: UserPostModel, 
        onDismiss: (() -> Void)? = nil, 
        onLike: ((UserCommentModel) -> Void)? = nil,
        onReport: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onNextPost: (() -> UserPostModel?)? = nil,
        onPrevPost: (() -> UserPostModel?)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: FullscreenPostDetailViewModel(post: post))
        self.onDismiss = onDismiss
        self.onLike = onLike
        self.onReport = onReport
        self.onShare = onShare
        self.onNextPost = onNextPost
        self.onPrevPost = onPrevPost
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
                                            .foregroundColor(DesignSystem.Colors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .stroke(DesignSystem.Colors.primary.opacity(0.8), lineWidth: 1)
                                                    .background(Capsule().fill(DesignSystem.Colors.primary.opacity(0.05)))
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
                                    .foregroundColor(nextPost.isBookmarkedByCurrentUser ? DesignSystem.Colors.primary : .secondary)
                                
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
                                                        let directNextPost = onNextPost()
                                                        if let nextPost = directNextPost {
                                                            // 验证是直接相邻的帖子
                                                            let currentPostId = viewModel.post.id
                                                            if nextPost.id != currentPostId {
                                                                nextPagePost = nextPost
                                                                // 预加载图片和评论
                                                                Task { 
                                                                    await Task.yield() // 让UI优先更新
                                                                    preloadImagesForPost(nextPost) {}
                                                                    preloadCommentsForPost(nextPost) {}
                                                                }
                                                            }
                                                        }
                                                    }
                                                } else if newDirection == .right, let onPrevPost = onPrevPost {
                                                    if nextPagePost == nil {
                                                        let directPrevPost = onPrevPost()
                                                        if let prevPost = directPrevPost {
                                                            // 验证是直接相邻的帖子
                                                            let currentPostId = viewModel.post.id
                                                            if prevPost.id != currentPostId {
                                                                nextPagePost = prevPost
                                                                // 预加载图片和评论
                                                                Task {
                                                                    await Task.yield() // 让UI优先更新
                                                                    preloadImagesForPost(prevPost) {}
                                                                    preloadCommentsForPost(prevPost) {}
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
                        
                        // 滑动有效性判断 - 简化逻辑，关注方向而非距离
                        // 右滑判断
                        let validRightSwipe = finalOffset > screenWidth * 0.15 || (finalOffset > screenWidth * 0.05 && velocityX > 200)
                        
                        // 左滑判断 - 进一步降低触发阈值，使左滑更容易触发
                        let validLeftSwipe = finalOffset < -screenWidth * 0.08 || (finalOffset < -screenWidth * 0.02 && velocityX < -100)
                        
                        // 关键修改：更严格确认最后一篇状态 - 多重检查确保准确性
                        var confirmLastPost = false
                        if let onNextPost = onNextPost {
                            // 额外安全检查：尝试获取下一篇并确认
                            let currentPostId = viewModel.post.id
                            let nextPostCheck = onNextPost()
                            
                            // 严格检查：如果返回了当前帖子ID，说明这是个错误
                            if let nextPostId = nextPostCheck?.id, nextPostId == currentPostId {
                                print("⭐️⭐️⭐️ 警告: onNextPost返回了当前帖子，确认为最后一篇")
                                confirmLastPost = true
                            } else {
                                confirmLastPost = nextPostCheck == nil
                            }
                            
                            // 打印详细调试信息
                            print("⭐️ 最后一篇检查 - nextPostCheck为空: \(nextPostCheck == nil), isLastPost: \(isLastPost), hasNextPost: \(hasNextPost)")
                            
                            // 强制同步状态，避免不一致
                            if confirmLastPost {
                                isLastPost = true
                                hasNextPost = false
                                print("⭐️ 确认是真正的最后一篇，强制同步状态")
                            } else {
                                // 如果不是最后一篇，确保状态正确
                                isLastPost = false
                                hasNextPost = true
                                print("⭐️ 确认不是最后一篇，强制同步状态")
                            }
                        } else {
                            // 如果没有提供onNextPost回调，使用isLastPost作为备选指标
                            confirmLastPost = isLastPost
                            print("⭐️ 没有onNextPost回调，使用isLastPost(\(isLastPost))作为备选判断")
                        }
                        
                        // 重置拖动状态
                        isDragging = false
                        
                        // 添加详细调试日志
                        print("⭐️ 滑动结束 - validLeftSwipe=\(validLeftSwipe), validRightSwipe=\(validRightSwipe), confirmLastPost=\(confirmLastPost), dragOffset=\(finalOffset), velocityX=\(velocityX)")
                        
                        // 最后一篇帖子左滑 - 严格判断必须确认是最后一篇才显示添加内容页面
                        if validLeftSwipe && confirmLastPost {
                            print("⭐️ 准备显示虫洞探索页面 - 确认为最后一篇")
                            
                            // 添加振动反馈 - 增强触觉反馈
                            let feedback = UIImpactFeedbackGenerator(style: .medium)
                            feedback.impactOccurred()
                            
                            // 重置滑动位置，避免与添加内容页面切换动画冲突
                            dragOffset = 0
                            
                            // 确保状态一致
                            isLastPost = true
                            hasNextPost = false
                            
                            // 显示虫洞探索页面 - 使用同步更新并确保视图层次正确
                            DispatchQueue.main.async {
                                // 使用主线程确保UI正确更新
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showAddContentView = true
                                    print("⭐️ 已设置showAddContentView = true")
                                }
                            }
                            
                            // 早期返回，不执行后续逻辑
                            return
                        }
                        // 处理有效的普通左滑动作
                        else if validLeftSwipe {
                            // 普通左滑 - 切换到下一篇帖子
                            print("⭐️ 处理普通左滑动作")
                            
                            // 确保不是最后一篇时才尝试获取下一篇
                            if !confirmLastPost && hasNextPost {
                                // 修改：短滑动时优先使用直接调用而非缓存，确保顺序一致性
                                if let onNextPost = onNextPost, let directNextPost = onNextPost() {
                                    print("⭐️ 使用下一篇帖子: \(directNextPost.id)")
                                    performPageTransition(direction: .left, nextPost: directNextPost, velocity: speedAbsolute)
                                } else if let nextPost = nextPagePost {
                                    // 仅在无法直接获取时使用缓存
                                    print("⭐️ 使用缓存的下一篇帖子: \(nextPost.id)")
                                    performPageTransition(direction: .left, nextPost: nextPost, velocity: speedAbsolute)
                                } else {
                                    // 如果出现意外情况：hasNextPost为true但获取不到下一篇
                                    print("⭐️ 警告：hasNextPost=true但无法获取下一篇帖子，恢复原位")
                                    resetPosition()
                                    
                                    // 更新状态以避免再次出现相同问题
                                    DispatchQueue.main.async {
                                        checkBoundaries()
                                    }
                                }
                            } 
                            // 如果确认是最后一篇但上面的检查没有捕获到
                            else if confirmLastPost || isLastPost {
                                print("⭐️ 通过备用逻辑确认为最后一篇，执行添加内容操作")
                                
                                // 添加振动反馈
                                let feedback = UIImpactFeedbackGenerator(style: .medium)
                                feedback.impactOccurred()
                                
                                // 重置状态确保一致性
                                isLastPost = true
                                hasNextPost = false
                                dragOffset = 0
                                
                                // 显示添加内容页面
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showAddContentView = true
                                }
                            } 
                            // 无法确定状态时的安全处理
                            else {
                                print("⭐️ 无法确定帖子状态，恢复原位并重新检查边界")
                                resetPosition()
                                
                                // 异步重新检查边界状态
                                DispatchQueue.main.async {
                                    checkBoundaries()
                                }
                            }
                        } else if validRightSwipe {
                            // 处理右滑动作
                            if showAddContentView {
                                // 如果当前显示的是添加内容页面，右滑返回到最后一篇帖子
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showAddContentView = false
                                }
                                return
                            }
                            
                            // 修改：短滑动时优先使用直接调用而非缓存，确保顺序一致性
                            if let onPrevPost = onPrevPost, let directPrevPost = onPrevPost() {
                                print("⭐️ 使用上一篇帖子: \(directPrevPost.id)")
                                performPageTransition(direction: .right, nextPost: directPrevPost, velocity: speedAbsolute)
                            } else if let prevPost = nextPagePost {
                                // 仅在无法直接获取时使用缓存
                                print("⭐️ 使用缓存的上一篇帖子: \(prevPost.id)")
                                performPageTransition(direction: .right, nextPost: prevPost, velocity: speedAbsolute)
                            } else {
                                // 恢复原位，没有可用的上一页
                                resetPosition()
                            }
                        } else {
                            // 不满足有效滑动条件，恢复原位
                            resetPosition()
                        }
                    }
            )
            
            // 添加内容视图 - 在最后一篇帖子左滑时显示
            if showAddContentView {
                ZStack {
                    // 背景 - 使用纯黑背景
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // 顶部标题 - 修改为与导航栏一致的风格
                        ZStack(alignment: .center) {
                            // 标题层
                            HStack {
                                Spacer()
                                
                                // 标题 - 使用与其他页面相同的样式
                                Text("探索虫洞深处")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            // 占位空间 - 保持与左侧返回按钮的对齐
                            HStack {
                                // 空占位符，与系统返回按钮布局匹配
                                Color.clear
                                    .frame(width: 32, height: 32)
                                    .padding(.leading, 16)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 44)
                        .padding(.top, getSafeAreaTop() + 15) // 与系统返回按钮垂直对齐，进一步下移5点
                        
                        // 黑洞主视觉
                        BlackHoleView()
                            .environmentObject(CreationTypeManager.shared)
                            .frame(height: UIScreen.main.bounds.height * 0.38)  // 进一步减小黑洞视图高度
                            .padding(.bottom, 16)  // 增加底部间距
                        
                        // 提示文本 - 移到黑洞下方
                        Text("连接不同时代的声音，体验跨越时空的社交互动")
                            .font(.system(size: 16, weight: .medium))  // 增大字体并增加粗细
                            .foregroundColor(.white.opacity(0.8))  // 增加文字不透明度
                            .padding(.top, 0)
                            .padding(.bottom, 8)  // 增加段落间距
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)  // 减少水平内边距
                        
                        // 辅助说明
                        Text("每种内容类型将带你进入不同的时空交流维度")
                            .font(.system(size: 14))  // 增大字体
                            .foregroundColor(.white.opacity(0.6))  // 增加对比度
                            .padding(.bottom, 28)  // 增加与按钮之间的间距
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // 创作类型按钮 - 移到文字下方
                        CreationTypeButtonsView()
                            .environmentObject(CreationTypeManager.shared)
                            .frame(height: 80)  // 减小按钮区域高度，适应单行按钮
                            .padding(.bottom, 30)  // 增加与主按钮之间的间距
                        
                        // 主按钮 - 开启时空对话
                        Button(action: {
                            // 这里添加AI生成内容的逻辑
                            withAnimation {
                                showAddContentView = false
                            }
                            
                            // 关闭详情页面
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismiss?()
                            }
                        }) {
                            HStack(spacing: 10) {  // 增加图标与文字间距
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 18))  // 增大图标尺寸
                                
                                Text("启动虫洞捕捉")
                                    .font(.system(size: 18, weight: .semibold))  // 增大文字尺寸
                            }
                            .foregroundColor(.black)
                            .frame(height: 56)  // 增加按钮高度
                            .frame(width: UIScreen.main.bounds.width * 0.6)  // 增加按钮宽度
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .white.opacity(0.92)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )  // 添加微妙渐变
                            .cornerRadius(28)  // 圆角随高度增加
                            .shadow(color: Color.white.opacity(0.4), radius: 10, x: 0, y: 0)  // 增强发光效果
                        }
                        .padding(.bottom, 60)  // 调整与底部的距离
                        
                        // 移除Spacer，防止按钮被推到底部
                        // Spacer()
                    }
                }
                .zIndex(300)
                .transition(.opacity) // 仅保留简单过渡动画
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .environmentObject(CreationTypeManager.shared)
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
            print("⭐️ FullscreenPostDetailView 显示")
            // 确保NavigationHelper已初始化
            _ = NavigationHelper.shared
            
            // 激活视图状态
            isViewActive = true
            
            // 隐藏底部标签栏 - 使用pushHideState()彻底物理隐藏底部导航栏
            tabBarManager.pushHideState()
            
            // 添加系统级返回按钮
            addSystemLevelBackButton()
            
            // 检查边界状态前记录当前状态
            print("⭐️ onAppear开始: 当前帖子ID: \(viewModel.post.id), hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost)")
            
            // 检查是否是最后一篇帖子 - 同步执行确保立即更新状态
            checkBoundaries()
            
            // 记录检查后的状态
            print("⭐️ onAppear检查边界后: hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost)")
            
            // 预加载下一篇和上一篇动态，实现滑动时的无缝切换
            preloadAdjacentPosts()
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
        backButton.tintColor = UIColor.systemBlue
        
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
                NavigationHelper.shared.forceGoBack()
                
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
            // 使用更安全的轻量级替代方案，避免引用ScaleButtonStyle
            .scaleEffect(1.0) // 默认比例，按下时会自动变化
            .contentShape(Circle()) // 确保点击区域正确
            .disabled(true) // 禁用按钮
                            
            Spacer()
                            
            // 标题 - 改进版本
            Text("动态详情")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.primary)
                            
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
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .stroke(DesignSystem.Colors.primary.opacity(0.8), lineWidth: 1)
                                .background(Capsule().fill(DesignSystem.Colors.primary.opacity(0.05)))
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
            // 使用更安全的轻量级替代方案，避免引用ScaleButtonStyle
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
            // 使用更安全的轻量级替代方案，避免引用ScaleButtonStyle
            .scaleEffect(1.0) // 默认比例，按下时会自动变化
            .contentShape(Capsule()) // 确保点击区域正确
            
            // 收藏按钮
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.4)
            }) {
                Image(systemName: viewModel.post.isBookmarkedByCurrentUser ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15))
                    .foregroundColor(viewModel.post.isBookmarkedByCurrentUser ? DesignSystem.Colors.primary : .secondary)
            }
            // 使用更安全的轻量级替代方案，避免引用ScaleButtonStyle
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
     * 执行页面过渡动画
     * 确保页面过渡流畅且无抖动
     * @param direction 过渡方向
     * @param nextPost 下一页的帖子
     * @param velocity 用户滑动的速度，用于动态调整动画时长
     */
    private func performPageTransition(direction: SwipeDirection, nextPost: UserPostModel, velocity: CGFloat = 0) {
        // 禁用交互，防止动画期间的用户操作
        isTransitioning = true
        
        let screenWidth = UIScreen.main.bounds.width
        
        // 触发触觉反馈，增强用户体验
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
        
        // 记录当前帖子ID和下一篇帖子ID用于调试
        let currentPostId = viewModel.post.id
        let nextPostId = nextPost.id
        print("⭐️ 页面过渡: 从 \(currentPostId) 到 \(nextPostId), 方向: \(direction == .left ? "左" : "右")")
        
        // 立即更新数据模型并显示下一页
        self.nextPagePost = nextPost
        
        // 根据用户滑动速度动态计算动画时长
        let maxVelocity: CGFloat = 3000
        let minDuration: CGFloat = 0.01
        let baseDuration: CGFloat = 0.05
        
        let dynamicDuration = velocity > 0 ? 
            max(minDuration, baseDuration * (1 - min(velocity, maxVelocity) / maxVelocity)) : 
            baseDuration
        
        withAnimation(.easeIn(duration: Double(dynamicDuration))) {
            self.showingTimeSpaceEffect = true
            self.timeSpaceDirection = direction
            self.nextPageVisible = true
        }
        
        // 收集所有预加载任务
        let preloadGroup = DispatchGroup()
        
        // 后台进行预加载 - 但不阻止UI显示
        preloadGroup.enter()
        preloadImagesForPost(nextPost) {
            preloadGroup.leave()
        }
        
        preloadGroup.enter()
        preloadCommentsForPost(nextPost) {
            preloadGroup.leave()
        }
        
        // 动态计算页面切换的延迟时间
        let transitionDelay = velocity > 0 ? 
            max(0.05, 0.1 * (1 - min(velocity, maxVelocity) / maxVelocity)) : 
            0.1
        
        // 立即开始过渡动画
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDelay) {
            let slideOutDuration = velocity > 0 ? 
                max(0.15, 0.25 * (1 - min(velocity, maxVelocity) / maxVelocity)) : 
                0.25
            
            withAnimation(.spring(response: slideOutDuration, dampingFraction: 0.8, blendDuration: 0.1)) {
                self.dragOffset = direction == .left ? -screenWidth : screenWidth
                self.showingTimeSpaceEffect = false
            }
            
            let completionDelay = velocity > 0 ? 
                max(0.15, 0.25 * (1 - min(velocity, maxVelocity) / maxVelocity)) : 
                0.25
            
            DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
                // 更新数据模型
                self.viewModel.updatePost(nextPost)
                
                // 记录完成状态
                print("⭐️ 页面过渡完成: 当前帖子ID已更新为 \(nextPost.id)")
                
                // 同步检查边界状态 - 确保立即更新
                checkBoundaries()
                
                // 重置所有状态，准备下一次交互
                self.dragOffset = 0
                self.swipeDirection = .none
                
                // 确保完全关闭时空效果
                withAnimation {
                    self.showingTimeSpaceEffect = false
                }
                
                // 加快隐藏过渡页面的时间
                DispatchQueue.main.async {
                    self.nextPageVisible = false
                    self.nextPagePost = nil
                    // 最后才完全解除转换状态
                    self.isTransitioning = false
                    
                    // 发送自定义通知，通知评论区域刷新
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshCommentsSection"), object: nil)
                    
                    // 预加载下一篇可能需要的内容，保持流畅体验
                    self.preloadAdjacentPosts()
                }
            }
        }
    }
    
    /**
     * 预加载帖子中的图片资源
     * 在翻页前确保图片已开始加载，防止评论区随着图片加载而移动
     */
    private func preloadImagesForPost(_ post: UserPostModel, completion: @escaping () -> Void) {
        // 确保在后台线程执行
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()
            
            // 遍历所有图片并加载
            for imageName in post.images {
                dispatchGroup.enter()
                
                // 预加载图片资源
                if let image = UIImage(named: imageName) {
                    // 图片已加载完成
                    // 忽略未使用的宽高比计算
                    _ = image.size.width / image.size.height
                    // 使用主线程更新UI相关属性
                        DispatchQueue.main.async {
                        // 可以在这里保存图片宽高比用于布局计算
                        // 例如：post.imageAspectRatios[imageName] = aspectRatio
                        dispatchGroup.leave()
                    }
                    } else {
                    // 如果图片未加载，使用更短的延迟
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
                        dispatchGroup.leave()
                    }
                }
            }
            
            // 图片都加载完成后调用完成回调
            dispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }
    
    /**
     * 预加载帖子评论资源
     * 确保评论区域在页面切换时已经准备好
     */
    private func preloadCommentsForPost(_ post: UserPostModel, completion: @escaping () -> Void) {
        // 在后台线程执行评论相关数据的预处理
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()
            
            // 模拟评论数据处理
            dispatchGroup.enter()
            
            // 提前计算并缓存评论总数等信息
            _ = post.getTotalCommentsCount()
            let topLevelComments = post.getTopLevelComments()
            
            // 提前加载每个评论的用户头像
            for comment in topLevelComments {
                if !comment.userAvatar.isEmpty {
                    _ = UIImage(named: comment.userAvatar)
                }
                
                // 递归处理回复
                for reply in comment.replies {
                    if !reply.userAvatar.isEmpty {
                        _ = UIImage(named: reply.userAvatar)
                    }
                }
            }
            
            // 缩短模拟加载时间
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
                dispatchGroup.leave()
            }
            
            // 完成所有处理后调用回调
            dispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }
    
    // 恢复原位 - 当滑动不满足触发翻页条件时
    private func resetPosition() {
        // 实现平滑恢复动画 - 使用弹性动画使还原更自然
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0.1)) {
            dragOffset = 0
            swipeDirection = .none
            showingTimeSpaceEffect = false
        }
        
        // 确保下一页内容完全隐藏
        withAnimation(.easeOut(duration: 0.15)) {
            nextPageVisible = false
        }
        
        // 略微延迟后重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            nextPagePost = nil
        }
    }
    
    // 预加载相邻帖子
    private func preloadAdjacentPosts() {
        // 先重新检查边界条件，确保hasNextPost和hasPrevPost状态同步
        print("⭐️ preloadAdjacentPosts开始 - 当前帖子: \(viewModel.post.id)")
        
        // 首先进行一次强制边界检查，确保状态是最新的
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
            if let nextPost = onNextPost() {
                // 避免加载当前帖子本身（错误情况）
                if nextPost.id == currentPostId {
                    print("⭐️⭐️⭐️ 严重错误：onNextPost() 返回了当前帖子，应为最后一篇")
                    hasNextPost = false
                    isLastPost = true
                    return
                }
                
                print("⭐️ 开始预加载下一篇帖子: \(nextPost.id)")
                // 预加载下一篇帖子
                viewModel.preloadNextPost(nextPost)
                
                // 预加载图片和评论
                preloadImagesForPost(nextPost) {
                    print("⭐️ 下一篇帖子图片预加载完成: \(nextPost.id)")
                }
                preloadCommentsForPost(nextPost) {
                    print("⭐️ 下一篇帖子评论预加载完成: \(nextPost.id)")
                }
            } else {
                // 如果onNextPost()返回nil但hasNextPost为true，说明状态不同步
                print("⭐️ 警告：hasNextPost=true但onNextPost()返回nil，修正状态")
                hasNextPost = false
                isLastPost = true
            }
        }
        
        // 直接检查是否有上一篇帖子
        if let onPrevPost = onPrevPost, hasPrevPost {
            let currentPostId = viewModel.post.id
            if let prevPost = onPrevPost() {
                // 避免加载当前帖子本身（错误情况）
                if prevPost.id == currentPostId {
                    print("⭐️⭐️⭐️ 严重错误：onPrevPost() 返回了当前帖子")
                    hasPrevPost = false
                    return
                }
                
                print("⭐️ 开始预加载上一篇帖子: \(prevPost.id)")
                
                // 预加载上一篇帖子 (延迟一点以减轻加载压力)
                Task {
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒延迟
                    
                    viewModel.preloadPrevPost(prevPost)
                    
                    // 预加载图片和评论
                    preloadImagesForPost(prevPost) {
                        print("⭐️ 上一篇帖子图片预加载完成: \(prevPost.id)")
                    }
                    preloadCommentsForPost(prevPost) {
                        print("⭐️ 上一篇帖子评论预加载完成: \(prevPost.id)")
                    }
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
        print("⭐️ 开始检查边界 - 当前帖子ID: \(viewModel.post.id)")
        
        // 检查是否有下一篇帖子 - 更可靠的验证
        var nextPostExists = false
        var reallyLastPost = false
        
        if let onNextPost = onNextPost {
            // 多次验证以确保结果的准确性
            // 首次检查前记录当前帖子ID以进行比对
            let currentPostId = viewModel.post.id
            var nextPost = onNextPost()
            
            // 检查返回的是否是同一篇帖子（错误情况）
            if let nextPostId = nextPost?.id, nextPostId == currentPostId {
                print("⭐️⭐️⭐️ 警告: onNextPost返回了当前帖子，视为没有下一篇")
                nextPost = nil
            }
            
            nextPostExists = nextPost != nil
            
            // 如果第一次检查结果为nil，进行第二次验证
            if nextPost == nil {
                print("⭐️ 第一次检查无法获取下一篇，进行第二次验证")
                usleep(30000) // 增加到30毫秒
                nextPost = onNextPost()
                // 再次检查避免返回当前帖子
                if let nextPostId = nextPost?.id, nextPostId == currentPostId {
                    print("⭐️⭐️⭐️ 警告: 第二次检查时onNextPost返回了当前帖子，视为没有下一篇")
                    nextPost = nil
                }
                nextPostExists = nextPost != nil
                
                // 如果第二次检查仍为nil，进行第三次确认
                if nextPost == nil {
                    print("⭐️ 第二次检查仍无法获取下一篇，视为最后一篇")
                    nextPostExists = false
                }
            }
            
            // 最终确认结果 - 三次检查都确认没有下一篇才认为是最后一篇
            reallyLastPost = nextPost == nil
            
            if nextPost != nil {
                print("⭐️ 多重验证结果：检测到下一篇帖子: \(nextPost!.id)")
            } else {
                print("⭐️ 多重验证结果：确认没有下一篇帖子，当前为最后一篇")
            }
            
            // 强制更新状态 - 不再使用保守策略，而是直接使用验证结果
            hasNextPost = nextPostExists
            isLastPost = reallyLastPost
            
            if reallyLastPost {
                print("⭐️ 确认最后一篇，强制更新状态：hasNextPost=false, isLastPost=true")
            } else {
                print("⭐️ 确认非最后一篇，强制更新状态：hasNextPost=true, isLastPost=false")
            }
        } else {
            // 如果没有提供回调，默认设置为没有下一篇，但打印警告
            print("⭐️ 警告：未提供onNextPost回调，默认视为最后一篇")
            hasNextPost = false
            isLastPost = true
            reallyLastPost = true
        }
        
        // 检查是否有上一篇帖子 - 简化处理
        if let onPrevPost = onPrevPost {
            let prevPost = onPrevPost()
            hasPrevPost = prevPost != nil
            
            if prevPost != nil {
                print("⭐️ 检测到上一篇帖子: \(prevPost!.id)")
            } else {
                print("⭐️ 没有上一篇帖子，当前为第一篇")
            }
        } else {
            // 如果没有提供回调，默认设置为没有上一篇
            hasPrevPost = false
        }
        
        // 最终一致性检查 - 确保状态逻辑一致
        if hasNextPost && isLastPost {
            print("⭐️ 严重状态冲突：hasNextPost=true 且 isLastPost=true，强制修正为非最后一篇")
            isLastPost = false // 优先信任hasNextPost=true
        } else if !hasNextPost && !isLastPost {
            // 这种情况下我们确信没有下一篇，所以应该是最后一篇
            print("⭐️ 状态不一致：hasNextPost=false 但 isLastPost=false，修正为isLastPost=true")
            isLastPost = true
        }
        
        // 如果状态发生了变化，记录日志
        if oldHasNextPost != hasNextPost || oldHasPrevPost != hasPrevPost || oldIsLastPost != isLastPost {
            print("⭐️ 边界状态已更新: hasNextPost=\(hasNextPost), hasPrevPost=\(hasPrevPost), isLastPost=\(isLastPost)")
            
            // 如果确认是最后一篇，额外打印信息
            if isLastPost {
                print("⭐️⭐️ 已确认当前为最后一篇帖子，准备好左滑添加内容")
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
