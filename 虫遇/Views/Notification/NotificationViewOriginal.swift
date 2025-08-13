import SwiftUI

/**
 * 虫洞通知页面
 * 显示用户收到的各类通知，包括评论、点赞、关注和系统通知
 */
struct NotificationView: View {
    // 当前选中的选项卡
    @State private var selectedTab: NotificationTab = .all
    // 滚动偏移量
    @State private var scrollOffset: CGFloat = 0
    // 是否有新通知
    @State private var hasNewNotifications = true
    // 是否正在刷新
    @State private var isRefreshing = false
    // 动画状态
    @State private var animateHeader = false
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 通知服务
    @StateObject private var notificationService = NotificationService.shared
    
    // 创建测试通知的方法
    private func createTestNotificationWithUserComment() {
        let testNotification = NotificationModel(
            type: .comment,
            avatar: "einstein",
            username: "爱因斯坦",
            content: "非常有趣的观点！时间确实是一个相对的概念，在不同的参照系中会有不同的流逝速度。",
            time: "刚刚",
            isOnline: true,
            actionText: "评论",
            character: NotificationModel.CharacterInfo(
                name: "爱因斯坦",
                era: "20世纪",
                category: .scientist,
                image: "einstein"
            ),
            previewContent: nil,
            relatedPostId: "test_post",
            relatedCommentId: nil,
            triggeredByAction: "comment",
            isGenerated: true,
            userComment: "我觉得时间旅行很神奇，想知道你对此有什么看法？",
            userPost: nil,
            originalPost: "时间是什么？我们真的能穿越时间吗？",
            originalPostAuthor: "时间探索者"
        )
        
        notificationService.addTestNotification(testNotification)
    }
    
    // 通知选项卡类型
    enum NotificationTab: String, CaseIterable {
        case all = "全部"
        case comments = "评论"
        case likes = "点赞"
        case follows = "关注"
        
        var icon: String {
            switch self {
            case .all: return "bell.fill"
            case .comments: return "bubble.left.fill"
            case .likes: return "heart.fill"
            case .follows: return "person.fill.badge.plus"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return Color.gray.opacity(0.75)
            case .comments: return Color.blue.opacity(0.65)
            case .likes: return Color.pink.opacity(0.65)
            case .follows: return Color.green.opacity(0.65)
            }
        }
    }
    
    // 筛选后的通知
    private var filteredNotifications: [NotificationModel] {
        notificationService.notifications.filter { shouldShowNotification(type: $0.type, selectedTab: selectedTab) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 背景层 - 更加微妙的渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.gray.opacity(0.015)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 测试按钮
                    Button("📝 测试用户评论显示") {
                        createTestNotificationWithUserComment()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // 顶部标题栏 - 增强层次感
                    HStack(alignment: .center) {
                        ZStack(alignment: .topTrailing) {
                            Text("虫洞通知")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            if hasNewNotifications {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color.red.opacity(0.9),
                                                Color.red.opacity(0.7)
                                            ]),
                                            center: .center,
                                            startRadius: 1,
                                            endRadius: 4
                                        )
                                    )
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                    .shadow(color: Color.red.opacity(0.4), radius: 3, x: 0, y: 1)
                                    .offset(x: 4, y: -2)
                                    .scaleEffect(animateHeader ? 1.0 : 0.3)
                                    .opacity(animateHeader ? 1.0 : 0.0)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.6).delay(0.8),
                                        value: animateHeader
                                    )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(scrollOffset > 30 ? 0.95 : 0)
                            .animation(.easeInOut(duration: 0.2), value: scrollOffset > 30)
                    )
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.gray.opacity(scrollOffset > 30 ? 0.2 : 0))
                            .animation(.easeInOut(duration: 0.2), value: scrollOffset > 30),
                        alignment: .bottom
                    )
                    .zIndex(100)
                    
                    // 分类选项卡 - 精致化设计
                    TabSwitcherView(selectedTab: $selectedTab)
                        .padding(.bottom, 12)
                        .background(
                            Rectangle()
                                .fill(.regularMaterial)
                                .opacity(0.3)
                        )
                    
                    // 通知列表 - 优化间距和布局
                    ScrollView {
                        // 下拉刷新指示器
                        if isRefreshing {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray.opacity(0.6)))
                                    .scaleEffect(1.1)
                                    .padding(.vertical, 16)
                                Spacer()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // 偏好设置检测
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: AppScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scrollView")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        // 扁平化通知列表 - 优化动画和间距
                        LazyVStack(spacing: 6) {
                            ForEach(Array(filteredNotifications.enumerated()), id: \.element.id) { index, notification in
                                Group {
                                    if notification.type == .system {
                                        SystemNotificationView(notification: notification)
                                    } else {
                                        NotificationItemView(notification: notification)
                                    }
                                }
                                .id("\(notification.id)-\(selectedTab)")
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.96).combined(with: .opacity).combined(with: .move(edge: .top)),
                                    removal: .scale(scale: 0.96).combined(with: .opacity)
                                ))
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05),
                                    value: selectedTab
                                )
                            }
                            
                            // 确保内容不被TabBar遮挡的底部填充
                            Color.clear
                                .frame(height: max(0, tabBarManager.fullBottomAreaHeight - (tabBarManager.bottomSafeAreaHeight * 0.5)))
                                .id("bottomSpacer")
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 2)
                        .frame(width: geometry.size.width)
                    }
                    .background(Color.clear)
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(AppScrollOffsetPreferenceKey.self) { offset in
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                            scrollOffset = -offset
                            
                            // 下拉刷新逻辑
                            if offset > 60 && !isRefreshing {
                                isRefreshing = true
                                // 触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // 刷新通知数据（重新加载本地通知）
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    // 这里可以添加一些随机的系统通知来模拟刷新效果
                                    if Bool.random() {
                                        notificationService.generateSystemWelcomeNotification()
                                    }
                                    
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        isRefreshing = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .onAppear {
                // 设置UIScrollView的全局配置
                UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
                UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = false
                
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                    animateHeader = true
                }
            }
            .onDisappear {
                // 还原ScrollView默认设置
                UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
                UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = true
            }
            .ignoresSafeArea(.all, edges: [.bottom])
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // 根据选中的选项卡确定是否显示特定类型的通知
    private func shouldShowNotification(type: NotificationModel.NotificationType, selectedTab: NotificationTab) -> Bool {
        switch selectedTab {
        case .all:
            return true
        case .comments:
            return type == .comment
        case .likes:
            return type == .like
        case .follows:
            return type == .follow
        }
    }
}

/**
 * 标签切换视图 - 精致化设计
 */
struct TabSwitcherView: View {
    @Binding var selectedTab: NotificationView.NotificationTab
    @Namespace private var tabAnimation
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(NotificationView.NotificationTab.allCases, id: \.self) { tab in
                    Button(action: {
                        // 触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                            }
                            .foregroundColor(selectedTab == tab ? tab.color : .secondary.opacity(0.7))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == tab ? tab.color.opacity(0.06) : Color.clear)
                                    .animation(.easeInOut(duration: 0.2), value: selectedTab == tab)
                            )
                            
                            // 选中指示器 - 更优雅的设计
                            ZStack {
                            if selectedTab == tab {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    tab.color.opacity(0.8),
                                                    tab.color.opacity(0.6)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    .frame(height: 3)
                                        .frame(width: 24)
                                    .matchedGeometryEffect(id: "underline", in: tabAnimation)
                                        .shadow(color: tab.color.opacity(0.3), radius: 2, x: 0, y: 1)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            
            // 分割线
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.gray.opacity(0.12),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .padding(.horizontal, 20)
        }
    }
}

#Preview {
    NotificationView()
} 