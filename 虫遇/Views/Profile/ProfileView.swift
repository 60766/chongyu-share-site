import SwiftUI
import SwiftData
import UIKit

// 添加一个新的UIKit桥接组件来处理点击事件
struct TouchableView: UIViewRepresentable {
    var action: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func handleTap() {
            print("UIKit按钮被点击")
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            action()
        }
    }
}

// 扩展成就数据模型
struct ExtendedAchievement: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let isUnlocked: Bool
}

/**
 * 个人空间页
 * 展示用户个人信息、时空旅行记录和历史人物关系
 */
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    
    /// 当前选中的标签索引
    @State private var selectedTabIndex = 0
    /// 标签选项
    private let tabOptions = ["次元回放", "我的动态", "互动记录"]
    /// 是否显示成就详情
    @State private var showAchievements = false
    /// 是否显示等级详情
    @State private var showLevelDetails = false
    /// 用于标签指示器动画的命名空间
    @Namespace private var namespace
    
    // 添加调试菜单状态
    @State private var isDebugMenuPresented = false
    @State private var debugTapCount = 0
    @State private var lastTapTime: Date? = nil
    
    // 设置页面显示状态
    @State private var showingSettings = false
    // 用户名点击计数
    @State private var usernameTapCount = 0

    @State private var showRealStarMap = false
    
    // 添加PostViewModel依赖来获取用户帖子数据
    @ObservedObject private var postViewModel = PostViewModel.shared
    
    // 添加NotificationService依赖来获取点赞数据
    @ObservedObject private var notificationService = NotificationService.shared
    
    // 模拟用户成就数据
    private let userAchievements = [
        Achievement(id: "1", name: "时空旅行者", icon: "clock.arrow.2.circlepath", description: "完成10次历史对话"),
        Achievement(id: "2", name: "历史学者", icon: "book.fill", description: "与5位不同时代的历史人物交流"),
        Achievement(id: "3", name: "文艺复兴", icon: "paintpalette.fill", description: "与达芬奇进行3次深度交流")
    ]
    
    // 模拟数据 - 角色关系
    private var characterRelations: [SimpleCharacterRelation] {
        [] // 目前为空，未来可以添加实际数据
    }
    
    var body: some View {
        let _ = print("ProfileView正在加载...")
        
        return mainContent
    }
    
    // 将主要内容分离为单独的视图以避免编译器超时
    private var mainContent: some View {
        ZStack {
            // 主内容
            GeometryReader { geometry in
                contentScrollView(geometry: geometry)
            }
            
            // 设置按钮（右上角齿轮图标）
            VStack {
                HStack {
                    Spacer()
                    settingsButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
        }
        .onAppear {
            print("个人空间页面加载完成")
        }
    }
    
    // 内容滚动视图
    private func contentScrollView(geometry: GeometryProxy) -> some View {
            ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // 极简导航栏 - 无标题
                HStack {
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                    
                // 个人信息卡片 - 恢复原来的梦幻设计
                profileInfoCard
                
                // 时空足迹总览卡片 - 新增功能聚合
                timeTravelOverviewCard
                
                // 成就展示网格
                achievementsGrid
                
                // 统一的Tab内容容器
                unifiedTabContentContainer
                
                // 底部间距，确保不被TabBar遮挡
                    Color.clear
                    .frame(height: 100)
                }
            .padding(.bottom, 20)
        }
        .background(
            // 背景渐变层
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    // 统一的Tab内容容器 - 将Tab切换器与内容整合
    private var unifiedTabContentContainer: some View {
        VStack(spacing: 0) {
            // Apple风格的分段控制器
            appleStyleSegmentedControl
            
            // 内容区域
            tabContentArea
        }
        .background(
            // 统一容器背景
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 12)
    }
    
    // 简洁的标签切换器
    private var appleStyleSegmentedControl: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
            ForEach(0..<tabOptions.count, id: \.self) { index in
                Button(action: {
                        // 触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                        impactFeedback.impactOccurred()
                    
                        // 优化动画 - 使用更流畅的参数
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1)) {
                        selectedTabIndex = index
                    }
                }) {
                        HStack(spacing: 8) {
                            Image(systemName: tabIconName(for: index))
                                .font(.system(size: 16, weight: selectedTabIndex == index ? .semibold : .medium))
                                .foregroundColor(selectedTabIndex == index ? tabColor(for: index) : Color.secondary.opacity(0.7))
                                .symbolRenderingMode(.hierarchical)
                                .symbolEffect(.pulse.wholeSymbol, options: .speed(0.5).repeat(1), isActive: selectedTabIndex == index)
                            
                        Text(tabOptions[index])
                                .font(.system(size: 15, weight: selectedTabIndex == index ? .semibold : .medium, design: .rounded))
                                .foregroundColor(selectedTabIndex == index ? Color.primary : Color.secondary.opacity(0.8))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .background(
                            ZStack {
                            if selectedTabIndex == index {
                                    // 优化的选中状态背景 - 更柔和精致的视觉效果
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    tabColor(for: index).opacity(0.15),
                                                    tabColor(for: index).opacity(0.08)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(tabColor(for: index).opacity(0.25), lineWidth: 0.8)
                                    )
                                        .shadow(color: tabColor(for: index).opacity(0.2), radius: 3, x: 0, y: 1)
                                        .matchedGeometryEffect(id: "selectedProfileTab", in: namespace)
                            } else {
                                    // 未选中状态完全透明
                                    Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                    .scaleEffect(selectedTabIndex == index ? 1.02 : 0.98) // 更明显的选中放大效果
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedTabIndex)
            }
        }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    // 优化的标签颜色 - 更加协调的配色方案
    private func tabColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.7, green: 0.5, blue: 0.9)  // 梦幻紫 - 次元回放，与个人卡片渐变呼应
        case 1: return Color(red: 0.2, green: 0.7, blue: 0.9)  // 天空蓝 - 我的动态，清新个人色彩
        case 2: return Color(red: 0.3, green: 0.8, blue: 0.6)  // 翠绿色 - 互动记录，活跃社交感
        default: return Color.primary
        }
    }
    
    // 标签图标名称 - 优化为更具表现力的图标
    private func tabIconName(for index: Int) -> String {
        switch index {
        case 0: return "memories"                 // 次元回放 - 使用回忆图标，更贴合"回放"概念
        case 1: return "person.text.rectangle"   // 我的动态 - 个人动态内容图标
        case 2: return "bubble.left.and.bubble.right"  // 互动记录 - 双向对话气泡，强调互动
        default: return "circle.fill"
        }
    }
    
    // 标签内容区域
    private var tabContentArea: some View {
        Group {
            switch selectedTabIndex {
            case 0:
                relationshipNetworkContent
            case 1:
                myPostsContent
            case 2:
                interactionRecordsContent
            default:
                relationshipNetworkContent
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
    }
    
    // 虫遇回忆内容（替换角色关系网络）
    private var relationshipNetworkContent: some View {
        ThoughtJourneyView()
    }
    
    // 我的动态内容（适配容器内部）  
    private var myPostsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if userPosts.isEmpty {
                enhancedEmptyContentView(
                    icon: "square.text.square",
                    message: "暂无动态",
                    description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                    buttonTitle: "发布动态",
                    buttonAction: {
                        // 发布动态的代码
                    }
                )
                .frame(height: 200)
            } else {
                // 动态统计摘要（去除外层padding）
                compactDynamicsSummaryCard
                
                // 动态列表
                LazyVStack(spacing: 12) {
                    ForEach(userPosts) { post in
                        UserPostRowView(post: post)
                    }
                }
            }
        }
    }
    
    // 互动记录内容（适配容器内部）
    private var interactionRecordsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 互动统计（去除外层padding）
            compactInteractionSummaryCard
            
            // 最近互动列表
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("最近互动")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                if mockInteractionRecords.isEmpty {
                    Text("暂无互动记录")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(mockInteractionRecords.prefix(5)) { record in
                            ProfileInteractionRowView(record: record)
                        }
                        
                        if mockInteractionRecords.count > 5 {
                            Button(action: {
                                // 查看全部互动记录
                            }) {
                                Text("查看全部 \(mockInteractionRecords.count) 条互动")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // 紧凑版动态统计摘要卡片（去除外层padding）
    private var compactDynamicsSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("动态总结")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // 总帖子数
                VStack(spacing: 4) {
                    Text("\(userPosts.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("总动态")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 总点赞数
                VStack(spacing: 4) {
                    Text("\(totalLikes)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.pink)
                    Text("总点赞")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 总评论数
                VStack(spacing: 4) {
                    Text("\(totalComments)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("总评论")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // 紧凑版互动统计摘要卡片（去除外层padding）
    private var compactInteractionSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("互动总结")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // 收到评论数
                VStack(spacing: 4) {
                    Text("\(receivedCommentsCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("收到评论")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 收到点赞数
                VStack(spacing: 4) {
                    Text("\(receivedLikesCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.pink)
                    Text("收到点赞")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 互动角色数
                VStack(spacing: 4) {
                    Text("\(interactedCharactersCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("互动角色")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    

    
    // 我的动态详细视图
    private var myPostsDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if userPosts.isEmpty {
                enhancedEmptyContentView(
                    icon: "square.text.square",
                    message: "暂无动态",
                    description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                    buttonTitle: "发布动态",
                    buttonAction: {
                        // 发布动态的代码
                    }
                )
                .frame(height: 200)
            } else {
                // 动态统计摘要
                dynamicsSummaryCard
                
                // 动态列表
                LazyVStack(spacing: 12) {
                    ForEach(userPosts) { post in
                        UserPostRowView(post: post)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // 动态统计摘要卡片
    private var dynamicsSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("动态总结")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            Spacer()
            }
            
            HStack(spacing: 20) {
                // 总帖子数
                VStack(spacing: 4) {
                    Text("\(userPosts.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("总动态")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 总点赞数
                VStack(spacing: 4) {
                    Text("\(totalLikes)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.pink)
                    Text("总点赞")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 总评论数
                VStack(spacing: 4) {
                    Text("\(totalComments)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("总评论")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                }
            }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    // 互动记录视图
    private var interactionRecordsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 互动统计
            interactionSummaryCard
            
            // 最近互动列表
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("最近互动")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                if mockInteractionRecords.isEmpty {
                    Text("暂无互动记录")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(mockInteractionRecords.prefix(5)) { record in
                            ProfileInteractionRowView(record: record)
                        }
                        
                        if mockInteractionRecords.count > 5 {
                    Button(action: {
                                // 查看全部互动记录
                            }) {
                                Text("查看全部 \(mockInteractionRecords.count) 条互动")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .padding(.vertical, 8)
                    }
                            .padding(.horizontal, 20)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // 互动统计摘要卡片
    private var interactionSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("互动总结")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                        Spacer()
            }
            
            HStack(spacing: 20) {
                // 收到评论数
                VStack(spacing: 4) {
                    Text("\(receivedCommentsCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("收到评论")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 收到点赞数
                VStack(spacing: 4) {
                    Text("\(receivedLikesCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.pink)
                    Text("收到点赞")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                        
                // 互动角色数
                VStack(spacing: 4) {
                    Text("\(interactedCharactersCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("互动角色")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                                
                                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    // 设置按钮
    private var settingsButton: some View {
                                Button(action: {
            showingSettings = true
                            }) {
                    Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary.opacity(0.6))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }

        .fullScreenCover(isPresented: $showRealStarMap) {
            RealStarMapView()
        }
    }
    
    // MARK: - UI组件
    
    // 个人信息卡片 - 梦幻次元风格设计
    private var profileInfoCard: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.7, green: 0.5, blue: 0.9),   // 梦幻紫
                    Color(red: 0.5, green: 0.4, blue: 0.8)    // 深紫
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)
            
            // 粒子效果背景
            ForEach(0..<15, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...350),
                        y: CGFloat.random(in: 0...120)
                    )
                    .opacity(0.4)
            }
            
            VStack(spacing: 0) {
                // 用户信息区域
                HStack(spacing: 16) {
                    // 头像容器 - 次元感设计
                    ZStack {
                        // 外层发光环
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3)
                                    ]),
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 76, height: 76)
                            .rotationEffect(.degrees(35))
            
                        // 头像背景光晕
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.white.opacity(0.5), radius: 15)
                        
                        // 头像图片
                        Image("default_avatar")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .onTapGesture {
                        handleUsernameTap()
                    }
                    
                    // 用户信息
                    VStack(alignment: .leading, spacing: 6) {
                        // 用户名 - 次元指挥官设定
                        Button(action: {
                            handleUsernameTap()
                        }) {
                            Text("次元指挥官")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 等级和经验值 - 游戏化设计
                VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                    
                                Text("次元探索专家")
                        .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                            )
                                    )
                            }
                            
                            // 新增：经验值进度条
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("Lv.8")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("180/200 EXP")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                // 经验进度条
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // 背景
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 6)
                                        
                                        // 进度
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * 0.9, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                        .onTapGesture {
                            showLevelDetails = true
                        }
                }
                                
                                Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
    
    // 时空足迹总览卡片 - 新增功能聚合卡片
    private var timeTravelOverviewCard: some View {
        VStack(spacing: 0) {
            timeTravelCardHeader
            timeTravelStatsGrid
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(timeTravelCardBackground)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
    
    // 时空足迹卡片标题 - 更新为次元概念
    private var timeTravelCardHeader: some View {
        HStack {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text("次元足迹总览")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showRealStarMap = true
                }) {
                                    Text("虫遇星图")
                            .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.orange)
                                }
        }
        .padding(.bottom, 16)
    }
    
    // 时空足迹统计网格
    private var timeTravelStatsGrid: some View {
        VStack(spacing: 12) {
            timeTravelStatsFirstRow
            timeTravelStatsSecondRow
        }
    }
    
    // 第一行统计 - 互动成就
    private var timeTravelStatsFirstRow: some View {
        HStack(spacing: 12) {
            TimeStatItem(
                value: "\(dialogueCount)次",
                label: "次元对话",
                color: Color.blue.opacity(0.7),
                backgroundColor: Color.blue.opacity(0.08)
            )
            
            TimeStatItem(
                value: "\(resonanceScore)",
                label: "获得共鸣", 
                color: Color.pink.opacity(0.7),
                backgroundColor: Color.pink.opacity(0.08)
            )
            
            TimeStatItem(
                value: "\(deepConnectionCount)位",
                label: "互动好友",
                color: Color.green.opacity(0.7),
                backgroundColor: Color.green.opacity(0.08)
            )
        }
    }
    
    // 第二行统计 - 探索成就
    private var timeTravelStatsSecondRow: some View {
        HStack(spacing: 12) {
            TimeStatItem(
                value: "\(explorationDays)天",
                label: "探索天数",
                color: Color.orange.opacity(0.7),
                backgroundColor: Color.orange.opacity(0.08)
            )
            
            TimeStatItem(
                value: "\(collectedHighlights)份",
                label: "点赞收藏",
                color: Color.purple.opacity(0.7),
                backgroundColor: Color.purple.opacity(0.08)
                            )
            
            TimeStatItem(
                value: "\(dimensionJumps)篇",
                label: "我的动态",
                color: Color.cyan.opacity(0.7),
                backgroundColor: Color.cyan.opacity(0.08)
            )
        }
    }
    
    // 卡片背景
    private var timeTravelCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
                            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
            )
    }
    
    // 关系网络可视化 - 增强版
    private var relationshipNetwork: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("次元关系网络")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 次元分类统计
                HStack(spacing: 8) {
                    dimensionCategoryBadge(icon: "building.columns.fill", name: "历史", count: 5, color: .brown)
                    dimensionCategoryBadge(icon: "gamecontroller.fill", name: "游戏", count: 3, color: .blue)
                    dimensionCategoryBadge(icon: "tv.fill", name: "动漫", count: 4, color: .purple)
                }
            }
            .padding(.horizontal, 20)
            
            if characterRelations.isEmpty {
                // 空状态展示 - 次元关系网络预览
                VStack(spacing: 16) {
                    ZStack {
                        // 网络节点模拟图
                        ForEach(0..<6, id: \.self) { index in
                                                Circle()
                                .fill(DesignSystem.Colors.primary.opacity(0.6))
                                .frame(width: 24, height: 24)
                                .position(
                                    x: [100, 200, 150, 80, 220, 150][index],
                                    y: [50, 50, 100, 120, 120, 150][index]
                                )
                        .overlay(
                                    Image(systemName: ["person.fill", "crown.fill", "gamecontroller.fill", "paintbrush.fill", "book.fill", "tv.fill"][index])
                                        .font(.system(size: 8))
                                .foregroundColor(.white)
                                        .position(
                                            x: [100, 200, 150, 80, 220, 150][index],
                                            y: [50, 50, 100, 120, 120, 150][index]
                                        )
                                )
                        }
                        
                        // 连接线
                        Path { path in
                            let points = [
                                CGPoint(x: 100, y: 50),
                                CGPoint(x: 150, y: 100),
                                CGPoint(x: 200, y: 50),
                                CGPoint(x: 150, y: 150),
                                CGPoint(x: 80, y: 120),
                                CGPoint(x: 220, y: 120)
                            ]
                            
                            for i in 0..<points.count {
                                for j in (i+1)..<points.count {
                                    if (i == 0 && j == 2) || (i == 1 && j == 3) || (i == 2 && j == 5) {
                                        path.move(to: points[i])
                                        path.addLine(to: points[j])
                                    }
                                }
                            }
                        }
                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 2)
                    }
                    .frame(height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    VStack(spacing: 8) {
                        Text("构建您的次元关系网络")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("与不同次元的角色互动，建立独特的关系网络")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            // 跳转到探索页面
                        }) {
                            Text("开始探索")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(DesignSystem.Colors.primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            } else {
                // 角色关系列表
                LazyVStack(spacing: 8) {
                    ForEach(characterRelations, id: \.id) { relation in
                    HStack(spacing: 12) {
                        // 角色头像
                                        Circle()
                                .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                    Text(String(relation.characterName.prefix(1)))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(DesignSystem.Colors.primary)
                            )
                        
                            VStack(alignment: .leading, spacing: 2) {
                                Text(relation.characterName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(relation.relationshipType)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                                
                                Spacer()
                                
                            Text("\(relation.interactionCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                            }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // 次元分类徽章
    private func dimensionCategoryBadge(icon: String, name: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    // 最近互动列表
    private var recentInteractionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
                Text("最近互动")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
                         VStack(spacing: 0) {
                     if userPosts.count > 0 {
                         UserPostRowView(post: userPosts[0])
                         if userPosts.count > 1 {
                             Divider()
                                 .background(Color.gray.opacity(0.3))
                                 .padding(.leading, 56)
                             UserPostRowView(post: userPosts[1])
                             if userPosts.count > 2 {
                                 Divider()
                                     .background(Color.gray.opacity(0.3))
                                     .padding(.leading, 56)
                                 UserPostRowView(post: userPosts[2])
                             }
                         }
                     }
             }
            .background(Color.white)
                    .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // 成就展示网格 - 使用新的成就系统
    private var achievementsGrid: some View {
        NewAchievementView()
    }
    
    // 计算用户帖子
    private var userPosts: [UserPostModel] {
        postViewModel.posts.filter { $0.source == "user" }
    }
    
    // 计算总点赞数
    private var totalLikes: Int {
        userPosts.reduce(0) { total, post in
            total + post.likes
        }
    }
    
    // 计算总评论数
    private var totalComments: Int {
        userPosts.reduce(0) { total, post in
            total + post.comments.count
                        }
                    }
    
    // 计算关注角色数
    private var followingCount: Int {
        // 这里应该从实际的关注数据中计算，暂时返回模拟数据
        12
    }
    
    // 新增：次元对话数
    private var dialogueCount: Int {
        // 从历史数据中计算总对话数
        return calculateTotalDialogues()
    }
    
    // 新增：共鸣分数
    private var resonanceScore: Int {
        // 从历史数据中计算总共鸣数
        return calculateTotalResonance()
    }
    
    // 新增：互动好友数量
    private var deepConnectionCount: Int {
        // 从历史数据中计算总互动角色数
        return calculateTotalActiveCharacters()
    }
    
    // 新增：探索天数
    private var explorationDays: Int {
        // 从历史数据中计算探索天数
        return calculateExplorationDays()
    }
    
    // 新增：点赞收藏数
    private var collectedHighlights: Int {
        // 从历史数据中计算点赞收藏数
        return calculateCollectedEssence()
    }
    
    // 新增：我的动态数
    private var dimensionJumps: Int {
        // 从历史数据中计算我的动态数
        return calculateTotalDynamics()
    }
    
    // MARK: - 数据计算方法
    
    /// 计算总对话数：用户发布的评论数量 + 用户与虚拟角色的私聊消息数量 + 用户发布的帖子数量
    private func calculateTotalDialogues() -> Int {
        let posts = PostViewModel.shared.posts
        
        // 1. 计算用户发布的评论数量（在所有帖子中）
        let userComments = posts.flatMap { post -> [DetailedCommentModel] in
            post.comments.filter { comment in
                !comment.isVirtualCharacter // 非虚拟角色的评论即为用户评论
            }
        }.count
        
        // 2. 计算用户在私聊中发送的消息数量
        var userPrivateMessages = 0
        do {
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.isFromUser == true
                }
            )
            let messages = try modelContext.fetch(messageDescriptor)
            userPrivateMessages = messages.count
        } catch {
            print("❌ 读取用户私聊消息失败: \(error.localizedDescription)")
        }
        
        // 3. 计算用户发布的帖子数量
        let userPostsCount = userPosts.count
        
        return userComments + userPrivateMessages + userPostsCount
    }
    
    /// 计算总共鸣数：从通知数据中统计用户收到的实际点赞总数
    private func calculateTotalResonance() -> Int {
        // 从NotificationService的永久存储中获取所有点赞通知
        let likeNotifications = NotificationService.shared.notifications.filter { notification in
            notification.type == .like
        }
        
        print("🔍 ProfileView: 发现 \(likeNotifications.count) 个点赞通知")
        
        // 统计总点赞数
        let totalLikes = likeNotifications.count
        
        print("❤️ ProfileView: 计算得到的总点赞数: \(totalLikes)")
        
        return totalLikes
    }
    
    /// 计算总互动角色数：包括和用户点赞或者评论或者私聊的任意一项的角色的数量
    private func calculateTotalActiveCharacters() -> Int {
        let posts = PostViewModel.shared.posts
        var interactedCharacters: Set<String> = []
        
        // 1. 统计在帖子中与用户互动的角色（给用户帖子点赞或评论）
        for post in userPosts {
            // 检查给用户帖子点赞的角色（通过点赞通知）
            let postLikeNotifications = NotificationService.shared.notifications.filter { notification in
                notification.type == .like && notification.relatedPostId == post.id.uuidString
            }
            for notification in postLikeNotifications {
                if let character = notification.character {
                    // 通过角色名称查找角色ID
                    let characterInfoList = CharacterDataManager.shared.getAllCharactersInfo()
                    if let characterInfo = characterInfoList.first(where: { $0.name == character.name }) {
                        interactedCharacters.insert(characterInfo.id)
                    }
                }
            }
            
            // 检查给用户帖子评论的角色
            for comment in post.comments where comment.isVirtualCharacter {
                if let characterID = comment.characterID {
                    interactedCharacters.insert(characterID)
                }
            }
        }
        
        // 2. 统计在评论中与用户互动的角色（给用户评论点赞或回复）
        for post in posts {
            for comment in post.comments where !comment.isVirtualCharacter {
                // 这是用户的评论，检查哪些角色回复了
                for reply in comment.replies where reply.isVirtualCharacter {
                    if let characterID = reply.characterID {
                        interactedCharacters.insert(characterID)
                    }
                }
            }
        }
        
        // 3. 统计在私聊中与用户互动的角色
        do {
            let messageDescriptor = FetchDescriptor<Message>()
            let messages = try modelContext.fetch(messageDescriptor)
            
            for message in messages {
                if message.isFromUser {
                    // 用户发送的消息，receiverId是角色ID
                    interactedCharacters.insert(message.receiverId)
                                                } else {
                    // 角色发送的消息，senderId是角色ID
                    interactedCharacters.insert(message.senderId)
                }
            }
        } catch {
            print("❌ 读取私聊消息失败: \(error.localizedDescription)")
        }
        
        return interactedCharacters.count
    }
    
    /// 计算探索天数：从最早的帖子或消息时间计算到现在
    private func calculateExplorationDays() -> Int {
        let posts = PostViewModel.shared.posts
        let earliestPostDate = posts.map { $0.datePosted }.min() ?? Date()
        
        // 检查SwiftData中的最早消息时间
        var earliestMessageDate = Date()
        do {
            let msgDescriptor = FetchDescriptor<Message>(sortBy: [SortDescriptor(\.timestamp)])
            let messages = try modelContext.fetch(msgDescriptor)
            if let firstMessage = messages.first {
                earliestMessageDate = firstMessage.timestamp
            }
        } catch {
            print("❌ 读取最早消息失败: \(error.localizedDescription)")
        }
        
        let earliestDate = min(earliestPostDate, earliestMessageDate)
        let days = Calendar.current.dateComponents([.day], from: earliestDate, to: Date()).day ?? 0
        
        return max(days, 1) // 至少返回1天
    }
    
    /// 计算点赞收藏数：用户点赞的帖子数量
    private func calculateCollectedEssence() -> Int {
        let likedPosts = PostViewModel.shared.posts.filter { $0.isLikedByCurrentUser }
        return likedPosts.count
    }
    
    /// 计算我的动态数：用户发布的帖子数量
    private func calculateTotalDynamics() -> Int {
        return userPosts.count
    }
    
    // 模拟互动记录数据
    private var mockInteractionRecords: [InteractionRecord] = [
        InteractionRecord(
            characterName: "历史人物A",
            characterAvatar: "default_avatar",
            type: .comment,
            content: "哇，您的见解真深刻！",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        InteractionRecord(
            characterName: "历史人物B", 
            characterAvatar: "default_avatar",
            type: .like,
            content: "您的观点很有启发性。",
            timestamp: Date().addingTimeInterval(-1800)
        ),
        InteractionRecord(
            characterName: "历史人物A",
            characterAvatar: "default_avatar", 
            type: .comment,
            content: "感谢您的回复！",
            timestamp: Date().addingTimeInterval(-600)
        ),
        InteractionRecord(
            characterName: "历史人物C",
            characterAvatar: "default_avatar",
            type: .like,
            content: "您的见解很有见地。",
            timestamp: Date().addingTimeInterval(-300)
        ),
        InteractionRecord(
            characterName: "历史人物B",
            characterAvatar: "default_avatar",
            type: .comment,
            content: "您的观点很有启发性。",
            timestamp: Date().addingTimeInterval(-120)
        )
    ]
    
    // 模拟收到评论数
    private var receivedCommentsCount: Int {
        mockInteractionRecords.filter { $0.type == .comment }.count
    }
    
    // 模拟收到点赞数
    private var receivedLikesCount: Int {
        mockInteractionRecords.filter { $0.type == .like }.count
    }
    
    // 模拟互动角色数
    private var interactedCharactersCount: Int {
        Set(mockInteractionRecords.map { $0.characterName }).count
    }
    
    // 扩展成就数据 - 新增更多成就类型
    private var extendedUserAchievements: [ExtendedAchievement] {
        [
            ExtendedAchievement(id: "1", name: "次元旅行者", icon: "globe.americas.fill", description: "完成10次次元对话", isUnlocked: true),
            ExtendedAchievement(id: "2", name: "历史学者", icon: "book.fill", description: "与5位历史人物交流", isUnlocked: true),
            ExtendedAchievement(id: "3", name: "文艺复兴", icon: "paintpalette.fill", description: "与达芬奇深度交流", isUnlocked: true),
            ExtendedAchievement(id: "4", name: "游戏达人", icon: "gamecontroller.fill", description: "与3位游戏角色互动", isUnlocked: true),
            ExtendedAchievement(id: "5", name: "动漫专家", icon: "tv.fill", description: "收集5个动漫角色", isUnlocked: false),
            ExtendedAchievement(id: "6", name: "次元探索者", icon: "location.fill", description: "解锁所有次元类型", isUnlocked: false),
            ExtendedAchievement(id: "7", name: "社交达人", icon: "person.2.fill", description: "获得100次互动", isUnlocked: true),
            ExtendedAchievement(id: "8", name: "时间守护者", icon: "clock.fill", description: "连续活跃30天", isUnlocked: true),
            ExtendedAchievement(id: "9", name: "次元收藏家", icon: "star.fill", description: "收藏50个精彩对话", isUnlocked: false)
        ]
    }
    
    // 计算已解锁成就数量
    private var unlockedAchievementsCount: Int {
        extendedUserAchievements.filter { $0.isUnlocked }.count
    }
    
    // 处理用户名点击 - 七次点击触发调试菜单
    private func handleUsernameTap() {
        let now = Date()
        
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 2 {
            // 超过2秒，重置计数
            debugTapCount = 1
                                                } else {
            debugTapCount += 1
        }
        
        lastTapTime = now
        
        if debugTapCount >= 7 {
            debugTapCount = 0
            lastTapTime = nil
            isDebugMenuPresented = true
                                    }
                                }
    
    // 我的动态视图
    private func myPostsView() -> some View {
            Group {
            if userPosts.isEmpty {
                enhancedEmptyContentView(
                    icon: "square.text.square",
                    message: "暂无动态",
                    description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                    buttonTitle: "发布动态",
                    buttonAction: {
                        // 发布动态的代码
                    }
                )
                                } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(userPosts.prefix(3)) { post in
                            UserPostRowView(post: post)
                        }
                        
                        if userPosts.count > 3 {
                                        Button(action: {
                                // 查看全部动态
                            }) {
                                Text("查看全部 \(userPosts.count) 条动态")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primaryColor)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
            }
        }
    }
    
    // 角色关系视图
    private func characterRelationsView() -> some View {
        ScrollView {
        LazyVStack(spacing: 8) {
                ForEach(characterRelations, id: \.id) { relation in
                HStack(spacing: 12) {
                    // 角色头像
                    Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        .overlay(
                                Text(String(relation.characterName.prefix(1)))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primaryColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                            Text(relation.characterName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text(relation.relationshipType)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(relation.interactionCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                }
            }
        }
    }
    
    // 增强的空内容视图
    private func enhancedEmptyContentView(
        icon: String,
        message: String,
        description: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
                Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.primaryColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: buttonAction) {
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primaryColor)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
         // 用户帖子行视图
     private func UserPostRowView(post: UserPostModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("次元指挥官")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                                 Text(formatTimeAgo(post.datePosted))
                     .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                                 HStack(spacing: 4) {
                     Image(systemName: "heart")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                     Text("\(post.likes)")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                 }
                 
                 HStack(spacing: 4) {
                     Image(systemName: "message")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                     Text("\(post.comments.count)")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                 }
                
                Spacer()
                }
            }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // 时间格式化函数
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else {
            let days = Int(interval / 86400)
            return "\(days)天前"
        }
    }
    
    // 成就详情视图
    private func achievementDetailView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("成就展示")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(userAchievements) { achievement in
                        VStack(spacing: 8) {
                                    Image(systemName: achievement.icon)
                                .font(.system(size: 32))
                                .foregroundColor(.primaryColor)
                                
                                Text(achievement.name)
                                .font(.system(size: 14, weight: .medium))
                                    .multilineTextAlignment(.center)
                                
                                Text(achievement.description)
                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showAchievements = false
                    }
                }
            }
        }
    }
    
    // 等级详情视图
    private func levelDetailView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("等级详情")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Text("次元探索专家")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryColor)
                
                    Text("您已经成功探索了多个次元世界，与各次元角色建立了深度连接。")
                        .font(.system(size: 14))
                    .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                    showLevelDetails = false
                    }
                }
            }
                }
            }
            
    // 调试菜单视图
    private func debugMenuView() -> some View {
        NavigationView {
                VStack(spacing: 20) {
                Text("调试菜单")
                    .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                    
                VStack(spacing: 12) {
                    Text("开发者选项")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Button("清除所有数据") {
                        // 清除数据的代码
                    }
                    .foregroundColor(.red)
                    
                    Button("重新加载界面") {
                        // 重新加载的代码
                    }
                    
                    Button("导出日志") {
                        // 导出日志的代码
                    }
                    
                    // 颜色预览按钮
                    NavigationLink(destination: ColorPreviewView()) {
                        Text("🎨 颜色预览")
                            .foregroundColor(.blue)
                    }
                    
                    // 用户动态持久化调试工具
                    NavigationLink(destination: UserPostPersistenceDebugView()) {
                        Text("📝 用户动态调试")
                            .foregroundColor(.purple)
                    }
                            }
                .padding(20)
                    .background(
                    RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4)
                            )
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isDebugMenuPresented = false
                    }
        }
        }
    }
    }
}

// 简化的角色关系数据模型
struct SimpleCharacterRelation {
    let id = UUID()
    let characterName: String
    let relationshipType: String
    let interactionCount: Int
}

// MARK: - 支持组件

// 成就数据模型
struct Achievement: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
}

// 扩展成就数据模型已在上方定义，这里删除重复定义

// 时空统计项组件
struct TimeStatItem: View {
    let value: String
    let label: String
    let color: Color
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
        )
    }
}


// 用户帖子行视图
struct UserPostRowView: View {
    let post: PostModel
    
    var body: some View {
        HStack(spacing: 12) {
            // 用户头像
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text("用")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("次元指挥官")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(post.timestamp)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(post.content)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days)天前"
        } else if hours > 0 {
            return "\(hours)小时前"
        } else if minutes > 0 {
            return "\(minutes)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// 网络节点视图（简化版）
struct NetworkNodeView: View {
    let node: MockCharacterNode
    let size: CGFloat
    
    var body: some View {
            ZStack {
                Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.1))
                .frame(width: size, height: size)
                
            Text(String(node.name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
        }
    }
            }
            
// 模拟角色节点
struct MockCharacterNode {
    let id: String
    let name: String
}

// 互动记录行视图
struct ProfileInteractionRowView: View {
    let record: InteractionRecord
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 头像
            if UIImage(named: record.characterAvatar) != nil {
                Image(record.characterAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(record.characterName.prefix(1)))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.characterName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(record.timestamp, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(record.content)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}



#Preview {
    ProfileView()
} 