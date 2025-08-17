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

/**
 * 个人空间页
 * 展示用户个人信息、时空旅行记录和历史人物关系
 */
struct ProfileView: View {
    /// 当前选中的标签索引
    @State private var selectedTabIndex = 0
    /// 标签选项
    private let tabOptions = ["角色关系", "我的动态", "互动记录"]
    /// 是否显示成就详情
    @State private var showAchievements = false
    /// 是否显示等级详情
    @State private var showLevelDetails = false
    /// 用于标签指示器动画的命名空间
    @Namespace private var namespace
    
    // 用于关注列表的类型枚举
    enum FollowListType {
        case following
        case followers
    }
    
    // 等级特权行
    struct LevelPrivilegeRow: View {
        var icon: String
        var title: String
        var level: String
        var isUnlocked: Bool
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isUnlocked ? .primaryColor : .gray)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isUnlocked ? .primary : .gray)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                    }
                    
                    Text(level)
                        .font(.system(size: 14))
                        .foregroundColor(isUnlocked ? .gray : .gray.opacity(0.7))
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    /**
     * 调试版个人空间
     * 包含额外的调试功能和选项
     */
    struct DebugProfileView: View {
        var body: some View {
            ProfileView()
                .overlay(
                    VStack {
                        Spacer()
                        Text("调试模式")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 4)
                )
        }
    }
    
    // 模拟用户成就数据
    private let userAchievements = [
        Achievement(id: "1", name: "时空旅行者", icon: "clock.arrow.2.circlepath", description: "完成10次历史对话"),
        Achievement(id: "2", name: "历史学者", icon: "book.fill", description: "与5位不同时代的历史人物交流"),
        Achievement(id: "3", name: "文艺复兴", icon: "paintpalette.fill", description: "与达芬奇进行3次深度交流")
    ]
    
    // 模拟时间线数据
    private let timelineEvents = [
        TimelineEvent(date: "2024-03-15", title: "遇见爱因斯坦", icon: "atom", description: "第一次与爱因斯坦交谈关于相对论"),
        TimelineEvent(date: "2024-03-10", title: "探索文艺复兴", icon: "paintbrush.fill", description: "与达芬奇讨论艺术与科学"),
        TimelineEvent(date: "2024-03-05", title: "哲学之旅", icon: "questionmark.circle", description: "向苏格拉底请教人生智慧")
    ]
    
    @State private var selectedTab = 0
    @State private var isSettingsPresented = false
    @State private var isFollowListPresented = false
    @State private var followListType: ProfileView.FollowListType = .following
    
    // 添加调试菜单状态
    @State private var isDebugMenuPresented = false
    @State private var debugTapCount = 0
    @State private var lastTapTime: Date? = nil
    
    // 模拟数据 - 角色关系
    private var characterRelations: [CharacterRelation] {
        [] // 目前为空，未来可以添加实际数据
    }
    
    var body: some View {
        // 打印视图加载信息
        let _ = {
            print("ProfileView正在加载...")
            return true
        }()
        
        ZStack {
            // 主内容
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        // 顶部区域：用户名和头像
                        VStack(spacing: 0) {
                            HStack {
                                Text("我的空间")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .tracking(-0.3) // 减少字间距，更精致
                                
                                Spacer()
                                
                                // 设置按钮 - 更现代的设计
                                Button(action: {
                                    print("⭐ 设置按钮被点击")
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    isSettingsPresented = true
                                }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(Color(.systemGray6))
                                                .opacity(0.8)
                                        )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16) // 增加顶部间距，符合iOS规范
                            .padding(.bottom, 16)
                        }
                        
                        // 用户信息卡片 - 简化设计，更现代
                        VStack(spacing: 0) {
                            // 简化的头部背景
                            ZStack(alignment: .top) {
                                // 渐变背景 - 更柔和的颜色
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(.systemBlue).opacity(0.1),
                                                Color(.systemBlue).opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 80)
                                    .overlay(
                                        // 简化的装饰元素
                                        HStack {
                                            Spacer()
                                                Circle()
                                                .fill(Color(.systemBlue).opacity(0.08))
                                                .frame(width: 120, height: 120)
                                                .offset(x: 60, y: -30)
                                        }
                                    )
                            }
                            
                            // 用户信息内容
                            VStack(spacing: 12) {
                                // 用户头像 - 简化设计
                                ZStack {
                                    // 头像背景
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 90, height: 90)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    
                                    // 头像图片
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(Color(.systemBlue))
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .offset(y: -35)
                                .padding(.bottom, -35)
                                
                                // 用户名和等级 - 优化排版
                                VStack(spacing: 6) {
                                    Text("历史探索者")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .onTapGesture {
                                            // 检测连续点击以触发调试菜单
                                            let now = Date()
                                            if let lastTime = lastTapTime, now.timeIntervalSince(lastTime) < 0.8 {
                                                // 在800毫秒内的点击算作连续点击
                                                debugTapCount += 1
                                                if debugTapCount >= 7 { // 需要连续点击7次
                                                    debugTapCount = 0
                                                    isDebugMenuPresented = true
                                                    
                                                    // 震动反馈
                                                    let generator = UINotificationFeedbackGenerator()
                                                    generator.notificationOccurred(.success)
                                                }
                                            } else {
                                                // 重置计数器
                                                debugTapCount = 1
                                            }
                                            lastTapTime = now
                                        }
                                        .onLongPressGesture(minimumDuration: 2.0) { // 长按2秒
                                            isDebugMenuPresented = true
                                            
                                            // 震动反馈
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.success)
                                        }
                                    
                                    // 等级标签 - 更精致的设计
                                    Button(action: { showLevelDetails.toggle() }) {
                                        HStack(spacing: 6) {
                                                Text("Lv.8")
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                    .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color(.systemBlue))
                                                )
                                            
                                            Text("穿越时空的历史探索者")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                            
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(.tertiaryLabel))
                                        }
                                    }
                                }
                                
                                // 成就勋章栏 - 重新设计
                                HStack(spacing: 16) {
                                    ForEach(userAchievements.prefix(3)) { achievement in
                                        VStack(spacing: 6) {
                                            ZStack {
                                                // 成就背景 - 更柔和
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(.systemBlue).opacity(0.15),
                                                                Color(.systemBlue).opacity(0.08)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 40, height: 40)
                                                
                                                // 成就图标
                                                Image(systemName: achievement.icon)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(Color(.systemBlue))
                                            }
                                            
                                            Text(achievement.name)
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                // 查看全部成就按钮 - 更现代的设计
                                Button(action: { showAchievements.toggle() }) {
                                    Text("查看全部成就")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(.systemBlue))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color(.systemBlue).opacity(0.08))
                                        )
                                }
                                .padding(.bottom, 4)
                            }
                            .padding(.horizontal, 16)
                            .background(Color(.systemBackground))
                        }
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        
                        // 统计数据 - 统一设计风格
                        HStack(spacing: 10) {
                            ForEach([
                                ("动态", "128", "square.text.square", Color(.systemBlue)),
                                ("获赞", "1.2K", "heart.fill", Color(.systemPink)),
                                ("好友", "12", "person.2.fill", Color(.systemGreen))
                            ], id: \.0) { title, value, icon, color in
                                VStack(spacing: 10) {
                                    // 图标容器 - 更精致
                                    ZStack {
                                        Circle()
                                            .fill(color.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(color)
                                    }
                                    
                                    // 数值 - 优化字体
                                    Text(value)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    // 标题 - 更小更精致
                                    Text(title)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // 时空旅行里程 - 现代化设计
                        VStack(alignment: .leading, spacing: 0) {
                            // 标题区域
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(.systemBlue))
                                    
                                    Text("时空旅行里程")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // 查看全部时间线
                                }) {
                                    Text("查看全部")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(.systemBlue))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 12)
                            
                            // 时间线 - 简化设计
                            VStack(spacing: 8) {
                                ForEach(timelineEvents) { event in
                                    HStack(alignment: .top, spacing: 12) {
                                        // 日期标签 - 更精致
                                        Text(event.date.components(separatedBy: "-").last ?? "")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(.systemBlue))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(Color(.systemBlue).opacity(0.1))
                                            )
                                            .frame(width: 44)
                                        
                                        // 时间线点
                                        VStack(spacing: 0) {
                                            Circle()
                                                .fill(Color(.systemBlue))
                                                .frame(width: 8, height: 8)
                                            
                                            if event.id != timelineEvents.last?.id {
                                            Rectangle()
                                                    .fill(Color(.systemBlue).opacity(0.2))
                                                    .frame(width: 1.5)
                                                    .frame(height: 40)
                                            }
                                        }
                                        
                                        // 事件内容
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Image(systemName: event.icon)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .padding(4)
                                                    .background(
                                                        Circle()
                                                            .fill(Color(.systemBlue))
                                                    )
                                                
                                                Text(event.title)
                                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Text(event.description)
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 5)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        .padding(.horizontal, 16)
                        
                        // 内容标签选择器 - 精致设计
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                    ForEach(Array(tabOptions.enumerated()), id: \.element) { index, tab in
                                        Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                selectedTabIndex = index
                                            }
                                        }) {
                                        VStack(spacing: 6) {
                                                Text(tab)
                                                .font(.system(size: 15, weight: selectedTabIndex == index ? .semibold : .medium, design: .rounded))
                                                .foregroundColor(selectedTabIndex == index ? Color(.systemBlue) : .secondary)
                                                
                                            // 精致的指示器
                                                if selectedTabIndex == index {
                                                Capsule()
                                                    .fill(Color(.systemBlue))
                                                    .frame(width: 24, height: 3)
                                                        .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                                                } else {
                                                Capsule()
                                                        .fill(Color.clear)
                                                    .frame(width: 24, height: 3)
                                                }
                                            }
                                        }
                                    .frame(maxWidth: .infinity)
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            }
                        .background(Color(.systemBackground))
                        
                        // 内容区域 - 现代化设计，增强视觉反馈
                        ZStack {
                            // 角色关系视图
                            if selectedTabIndex == 0 {
                                if characterRelations.isEmpty {
                                    enhancedEmptyContentView(
                                        icon: "person.2.circle.fill",
                                        message: "暂无角色关系",
                                        description: "尝试与历史人物聊天，建立与他们的关系吧！",
                                        buttonTitle: "去探索历史人物",
                                        buttonAction: {
                                            // 跳转到探索页面的代码
                                        }
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                } else {
                                    characterRelationsView()
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                }
                            }
                            
                            // 我的动态视图
                            if selectedTabIndex == 1 {
                                enhancedEmptyContentView(
                                    icon: "square.text.square",
                                    message: "暂无动态",
                                    description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                                    buttonTitle: "发布动态",
                                    buttonAction: {
                                        // 发布动态的代码
                                    }
                                )
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                            
                            // 互动记录视图
                            if selectedTabIndex == 2 {
                                enhancedEmptyContentView(
                                    icon: "text.bubble",
                                    message: "暂无互动记录",
                                    description: "尝试与历史人物聊天、点赞或评论，建立互动关系吧！",
                                    buttonTitle: "开始互动",
                                    buttonAction: {
                                        // 开始互动的代码
                                    }
                                )
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                            }
                        }
                        .frame(minHeight: 280)
                        .background(Color(.systemBackground))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTabIndex)
                    }
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 12)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            

            .zIndex(999) // 确保按钮在ZStack的最上层
        }
        .fullScreenCover(isPresented: $isSettingsPresented) {
            SettingsView()
        }
        // 添加onAppear用于调试
        .onAppear {
            print("ProfileView已加载，设置按钮状态准备就绪")
        }
    }
    
    // 数据统计视图 - 增加图标
    private func statView(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.primaryColor)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // 角色关系视图
    private func characterRelationsView() -> some View {
        VStack {
            Text("此处将展示您与历史人物的互动关系")
                .foregroundColor(.gray)
        }
    }
    
    // 时间线事件视图
    private func timelineEventView(event: TimelineEvent) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // 日期
            Text(event.date)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .trailing)
            
            // 时间线轴
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.primaryColor)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.primaryColor.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 70)
            
            // 事件内容
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: event.icon)
                        .foregroundColor(.primaryColor)
                    
                    Text(event.title)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(event.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // 成就视图 - 现代化设计
    private func achievementsView() -> some View {
        VStack(spacing: 0) {
            // 导航栏
            HStack {
                Spacer()
                Text("我的成就")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                
                Button(action: {
                    showAchievements = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray.opacity(0.7))
                }
            }
        .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .background(Color.white)
            
            // 成就等级概览
            VStack(spacing: 8) {
                HStack {
                    Text("成就等级")
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text("大师级探索者")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryColor)
                }
                
                // 成就进度
                VStack(spacing: 8) {
                    HStack {
                        Text("\(userAchievements.count)/30")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("解锁下一等级还需3项成就")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    // 进度条
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.primaryColor,
                                        Color.primaryColor.opacity(0.7)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.3, height: 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                
                // 主要内容 - 成就列表
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        ForEach(userAchievements) { achievement in
                            // 成就卡片
                            VStack(spacing: 12) {
                                ZStack {
                                    // 外圈装饰
                                    Circle()
                                        .strokeBorder(
                                            AngularGradient(
                                                gradient: Gradient(colors: [
                                                    Color.primaryColor.opacity(0.3),
                                                    Color.primaryColor,
                                                    Color.primaryColor.opacity(0.3)
                                                ]),
                                                center: .center
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: 70, height: 70)
                                    
                                    // 背景
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.primaryColor,
                                                    Color.primaryColor.opacity(0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 60, height: 60)
                                    
                                    // 图标
                                    Image(systemName: achievement.icon)
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                }
                                
                                // 成就名称
                                Text(achievement.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                // 成就描述
                                Text(achievement.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(height: 40)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(20)
                }
                .background(
                    Color(red: 246/255, green: 248/255, blue: 252/255)
                )
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // 等级详情视图 - 现代化设计
    private func levelDetailsView() -> some View {
        VStack(spacing: 0) {
            // 导航栏
            HStack {
                Spacer()
                Text("等级详情")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                
                Button(action: {
                    showLevelDetails = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 当前等级卡片
                    VStack(spacing: 16) {
                        // 等级图标
                        ZStack {
                            // 发光背景
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.primaryColor.opacity(0.7),
                                            Color.primaryColor.opacity(0.0)
                                        ]),
                                        center: .center,
                                        startRadius: 25,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .blur(radius: 5)
                            
                            // 等级显示
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.primaryColor,
                                                Color.primaryColor.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.primaryColor.opacity(0.3), radius: 10)
                                
                                Text("Lv.8")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 等级名称
                        Text("穿越时空的历史探索者")
                            .font(.system(size: 18, weight: .medium))
                            .multilineTextAlignment(.center)
                        
                        // 进度区域
                        VStack(spacing: 10) {
                            // 进度标题
                            HStack {
                                Text("等级进度")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                Text("750/1000 经验")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            // 进度条 - 平滑动画效果
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.primaryColor,
                                                Color.primaryColor.opacity(0.7)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: UIScreen.main.bounds.width * 0.6, height: 12)
                            }
                            
                            Text("距离下一级还需: 250经验")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                Color.white
                            )
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 20)
                    
                    // 等级特权卡片
                    VStack(alignment: .leading, spacing: 16) {
                        Text("等级特权")
                            .font(.system(size: 18, weight: .semibold))
                        
                        // 特权列表
                        VStack(spacing: 0) {
                            Self.LevelPrivilegeRow(icon: "message.fill", title: "解锁更多历史人物对话", level: "Lv.5", isUnlocked: true)
                            Divider().background(Color.gray.opacity(0.1))
                            
                            Self.LevelPrivilegeRow(icon: "wand.and.stars", title: "个性化空间装饰", level: "Lv.8", isUnlocked: true)
                            Divider().background(Color.gray.opacity(0.1))
                            
                            Self.LevelPrivilegeRow(icon: "crown.fill", title: "专属徽章展示", level: "Lv.10", isUnlocked: false)
                            Divider().background(Color.gray.opacity(0.1))
                            
                            Self.LevelPrivilegeRow(icon: "key.fill", title: "历史隐藏场景", level: "Lv.15", isUnlocked: false)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .background(
                Color(red: 246/255, green: 248/255, blue: 252/255)
            )
        }

        .edgesIgnoringSafeArea(.bottom)
        .id("ProfileView-\(selectedTabIndex)") // 添加ID确保视图正确刷新
        .onAppear {
            // 页面出现时重置状态，确保每次进入都是一致的布局
            resetPageState()
        }

        .onDisappear {
            // 页面消失时清理状态
            cleanupPageState()
        }
    }
    
    // MARK: - 页面状态管理
    
    /// 重置页面状态，确保每次进入都是一致的布局
    private func resetPageState() {
        // 重置标签索引到第一个
        selectedTabIndex = 0
        
        // 重置其他可能影响布局的状态
        showAchievements = false
        showLevelDetails = false
        isSettingsPresented = false
        isFollowListPresented = false
        
        // 重置调试相关状态
        isDebugMenuPresented = false
        debugTapCount = 0
        lastTapTime = nil
        
        // 状态重置 - 使用简化方案，避免直接操作UIScrollView
        // SwiftUI会自动处理视图重建，这里主要重置状态变量
        
        print("✅ ProfileView状态已重置")
    }
    
    /// 清理页面状态
    private func cleanupPageState() {
        // 清理可能的悬挂状态
        showAchievements = false
        showLevelDetails = false
        isSettingsPresented = false
        isFollowListPresented = false
        isDebugMenuPresented = false
        
        print("🧹 ProfileView状态已清理")
    }
    
    // 简单的空内容提示视图
    private func emptyContentView(icon: String, message: String, description: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 现代化空状态视图
    private func enhancedEmptyContentView(icon: String, message: String, description: String, buttonTitle: String, buttonAction: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            // 图标容器 - 更现代的设计
            ZStack {
                Circle()
                    .fill(Color(.systemBlue).opacity(0.08))
                    .frame(width: 80, height: 80)
                
            Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color(.systemBlue).opacity(0.6))
            }
            
            VStack(spacing: 8) {
            Text(message)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            
            Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 16)
            }
            
            Button(action: buttonAction) {
                Text(buttonTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(.systemBlue))
                    )
                    .shadow(color: Color(.systemBlue).opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 24)
    }
}

/**
 * 成就模型
 */
struct Achievement: Identifiable {
    var id: String
    var name: String
    var icon: String
    var description: String
}

/**
 * 时间线事件模型
 */
struct TimelineEvent: Identifiable {
    var id = UUID()
    var date: String
    var title: String
    var icon: String
    var description: String
}

/**
 * 角色关系模型
 */
struct CharacterRelation: Identifiable {
    var id = UUID()
    var characterName: String
    var characterIcon: String
    var relationshipType: String
    var lastInteraction: String
}

/**
 * 个人空间页预览
 */
#Preview("个人空间") {
    ProfileView()
}

#Preview("调试版空间") {
    ProfileView.DebugProfileView()
} 