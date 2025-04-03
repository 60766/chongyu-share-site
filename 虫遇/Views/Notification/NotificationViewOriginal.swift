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
    
    // 通知数据
    @State private var notifications: [NotificationModel] = NotificationModel.sampleNotifications
    
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
            case .all: return .primary
            case .comments: return .blue
            case .likes: return .pink
            case .follows: return .orange
            }
        }
    }
    
    // 筛选后的通知
    private var filteredNotifications: [NotificationModel] {
        notifications.filter { shouldShowNotification(type: $0.type, selectedTab: selectedTab) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 背景层 - 添加微妙渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部标题栏 - 动态效果
                    HStack {
                        ZStack(alignment: .topTrailing) {
                            Text("虫洞通知")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if hasNewNotifications {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.red, Color(red: 0.9, green: 0.2, blue: 0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1.5)
                                    )
                                    .shadow(color: Color.red.opacity(0.4), radius: 2, x: 0, y: 1)
                                    .offset(x: 2, y: -2)
                                    .scaleEffect(animateHeader ? 1.0 : 0.5)
                                    .opacity(animateHeader ? 1.0 : 0.0)
                            }
                        }
                        
                        Spacer()
                        
                        // 已读按钮
                        Button(action: {
                            withAnimation(.spring()) {
                                hasNewNotifications = false
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18))
                                .foregroundColor(Color.green)
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .background(Color.green.opacity(0.1))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // 设置按钮
                        Button(action: {
                            // 打开设置
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                                .foregroundColor(Color.primary)
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .background(Color.gray.opacity(0.1))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .background(
                        Rectangle()
                            .fill(Color.white.opacity(scrollOffset > 20 ? 0.98 : 0))
                            .shadow(color: Color.black.opacity(scrollOffset > 20 ? 0.05 : 0), radius: 8, x: 0, y: 4)
                    )
                    .zIndex(100)
                    
                    // 分类选项卡 - 增强视觉效果
                    TabSwitcherView(selectedTab: $selectedTab)
                        .padding(.bottom, 8)
                        .background(
                            Rectangle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        )
                    
                    // 通知列表 - 添加滚动交互
                    ScrollView {
                        // 下拉刷新指示器空间
                        if isRefreshing {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.3)
                                    .padding()
                                Spacer()
                            }
                            .transition(.opacity)
                        }
                        
                        // 偏好设置检测
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: AppScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scrollView")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        // 通知组群容器 - 确保内容填充全屏宽度
                        VStack(alignment: .leading, spacing: 16) {
                            // 虚拟角色通知组
                            if notifications.contains(where: { $0.character.category.isVirtual }) {
                                notificationGroup(
                                    title: "虚拟角色的回应",
                                    icon: "sparkles",
                                    iconColor: .purple,
                                    notifications: filteredNotifications.filter { $0.character.category.isVirtual }
                                )
                            }
                            
                            // 历史人物通知组
                            if notifications.contains(where: { $0.character.category.isHistorical }) {
                                notificationGroup(
                                    title: "穿越时空的对话",
                                    icon: "clock.arrow.circlepath",
                                    iconColor: .blue,
                                    notifications: filteredNotifications.filter { 
                                        $0.character.category.isHistorical && $0.type != .system 
                                    }
                                )
                            }
                            
                            // 系统通知组
                            if filteredNotifications.contains(where: { $0.type == .system }) {
                                notificationGroup(
                                    title: "系统通知",
                                    icon: "bell",
                                    iconColor: .orange,
                                    notifications: filteredNotifications.filter { $0.type == .system },
                                    isSystemGroup: true
                                )
                            }
                            
                            // 确保内容不被TabBar遮挡的底部填充
                            Color.clear
                                .frame(height: max(0, tabBarManager.fullBottomAreaHeight - (tabBarManager.bottomSafeAreaHeight * 0.8)))
                                .id("bottomSpacer")
                        }
                        .frame(width: geometry.size.width) // 确保内容填充整个宽度
                    }
                    .background(Color.clear) // 使用透明背景
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(AppScrollOffsetPreferenceKey.self) { offset in
                        withAnimation(.interactiveSpring()) {
                            scrollOffset = -offset
                            
                            // 下拉刷新逻辑
                            if offset > 50 && !isRefreshing {
                                isRefreshing = true
                                // 模拟刷新操作
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        isRefreshing = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.clear) // 整体背景设为透明
            .onAppear {
                // 设置UIScrollView的全局配置，确保延伸到底部
                UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
                UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = false
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                    animateHeader = true
                }
            }
            .onDisappear {
                // 还原ScrollView默认设置
                UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
                UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = true
            }
            .ignoresSafeArea(.all, edges: [.bottom]) // 确保忽略底部安全区域
            .edgesIgnoringSafeArea(.bottom) // 双重保险确保内容延伸到底部
        }
    }
    
    // 通知分组视图构建器
    private func notificationGroup(
        title: String, 
        icon: String, 
        iconColor: Color, 
        notifications: [NotificationModel],
        isSystemGroup: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // 分组标题
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 4)
            
            // 通知列表
            ForEach(notifications) { notification in
                if isSystemGroup {
                    SystemNotificationView(notification: notification)
                        .id("\(notification.id)-\(selectedTab)")
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    NotificationItemView(notification: notification)
                        .id("\(notification.id)-\(selectedTab)")
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
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
 * 标签切换视图
 */
struct TabSwitcherView: View {
    @Binding var selectedTab: NotificationView.NotificationTab
    @Namespace private var tabAnimation
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(NotificationView.NotificationTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 12))
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .regular))
                            }
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            
                            // 选中指示器
                            if selectedTab == tab {
                                Rectangle()
                                    .fill(tab.color)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "underline", in: tabAnimation)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            
            Divider()
                .background(Color.gray.opacity(0.2))
        }
    }
}

#Preview {
    NotificationView()
} 