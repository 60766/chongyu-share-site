import SwiftUI

/**
 * 角色详情页
 * 显示历史人物的详细信息
 */
struct CharacterDetailView: View {
    /// 角色数据
    var character: Character
    /// 是否显示分享菜单
    @State private var showingShareSheet = false
    /// 当前选中的标签索引
    @State private var selectedTabIndex = 0
    /// 标签选项
    private let tabOptions = ["介绍", "相关信息", "互动记录"]
    /// 模拟对话数据
    @State private var conversations: [Conversation] = []
    /// 内容动画状态
    @State private var animateContent: Bool = false
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 添加状态变量以控制导航
    @State private var navigateToChatView = false
    @State private var selectedConversationId: String? = nil
    
    // 添加环境变量用于自定义返回按钮
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 背景色 - 使用浅色背景增强文字可读性
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
                
            // 主内容区
            ScrollView {
                VStack(spacing: 0) {
                    // 角色头部区域
                    HeaderView(character: character)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: animateContent)
                    
                    // 数据指标区域
                    StatsView(character: character)
                        .padding(.top, 5)
                        .offset(y: animateContent ? 0 : 25)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateContent)
                    
                    // 操作按钮区
                    ActionButtonsView(
                        character: character,
                        onFollowTapped: {
                            print("关注按钮点击")
                        },
                        onChatTapped: {
                            print("对话按钮点击")
                            selectedConversationId = UUID().uuidString
                            navigateToChatView = true
                        },
                        onShareTapped: {
                            print("分享按钮点击")
                            showingShareSheet = true
                        }
                    )
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    .offset(y: animateContent ? 0 : 30)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: animateContent)
                    
                    // 分类内容标签区
                    TabBarView(
                        character: character,
                        tabOptions: tabOptions,
                        selectedTabIndex: $selectedTabIndex
                    )
                    .offset(y: animateContent ? 0 : 35)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: animateContent)
                    
                    // 标签页内容
                    TabView(selection: $selectedTabIndex) {
                        // 介绍标签页
                        IntroductionView(character: character)
                            .tag(0)
                        
                        // 相关信息标签页
                        RelatedInfoView(character: character)
                            .tag(1)
                        
                        // 互动记录标签页
                        InteractionView(
                            character: character, 
                            conversations: conversations,
                            onChatSelected: { conversationId in
                                print("对话记录点击: \(conversationId)")
                                selectedConversationId = conversationId
                                navigateToChatView = true
                            }
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(minHeight: 500)
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: animateContent)
                    .onChange(of: selectedTabIndex) { newValue in
                        // 当用户滑动更改标签时，触发轻微的触觉反馈
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    
                    // 底部页面指示器
                    ScrollingPageIndicator(
                        character: character,
                        currentPage: $selectedTabIndex,
                        numberOfPages: tabOptions.count
                    )
                    .padding(.vertical, 16)
                    .offset(y: animateContent ? 0 : 45)
                    .opacity(animateContent ? 0.7 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: animateContent)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // 手动返回
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("返回")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundColor(.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            Text("分享 \(character.name) 的信息")
        }
        // 使用新的导航API
        .navigationDestination(isPresented: $navigateToChatView) {
            ChatView(
                character: CYChatCharacter(
                    id: character.id,
                    name: character.name,
                    introduction: character.introduction,
                    field: character.field,
                    birthYear: character.birthYear,
                    deathYear: character.deathYear ?? "",
                    avatarUrl: character.avatarUrl,
                    eraTag: character.eraTag ?? "",
                    achievements: character.achievements,
                    mainWorks: character.mainWorks,
                    keyThoughts: character.keyThoughts
                ),
                conversationId: selectedConversationId ?? UUID().uuidString
            )
        }
        .onAppear {
            // 在视图出现时隐藏TabBar
            tabBarManager.pushHideState()
            print("CharacterDetailView出现：TabBar已隐藏")
            
            // 加载模拟对话数据
            loadMockConversations()
            
            // 延迟启动内容动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    animateContent = true
                }
            }
        }
        .onDisappear {
            // 在视图消失时重置状态以确保清晰的导航体验
            tabBarManager.popHideState()
            print("CharacterDetailView消失：TabBar状态已恢复")
        }
    }
    
    /**
     * 加载模拟对话数据
     */
    private func loadMockConversations() {
        // 模拟数据
        conversations = [
            Conversation(id: "1", characterId: character.id, userId: "currentUser", lastMessageContent: "上次我们讨论到了关于您那个时代的生活方式，能继续聊聊吗？", lastMessageTime: Date().addingTimeInterval(-3600 * 24), messageCount: 0),
            Conversation(id: "2", characterId: character.id, userId: "currentUser", lastMessageContent: "您认为历史和现代的最大区别是什么？", lastMessageTime: Date().addingTimeInterval(-3600 * 24 * 3), messageCount: 1)
        ]
    }
}

// MARK: - 子视图组件

/**
 * 角色主题颜色管理器
 * 根据角色类型返回对应的主题颜色
 */
private struct CharacterTheme {
    let primary: Color
    let secondary: Color
    let background: Color
    
    // 静态主题集合
    static let scientist = CharacterTheme(
        primary: Color(red: 0.2, green: 0.5, blue: 0.9),
        secondary: Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.8),
        background: Color(red: 0.9, green: 0.95, blue: 1.0)
    )
    
    static let philosopher = CharacterTheme(
        primary: Color(red: 0.6, green: 0.4, blue: 0.8),
        secondary: Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.8),
        background: Color(red: 0.95, green: 0.9, blue: 1.0)
    )
    
    static let writer = CharacterTheme(
        primary: Color(red: 0.2, green: 0.6, blue: 0.5),
        secondary: Color(red: 0.3, green: 0.7, blue: 0.6).opacity(0.8),
        background: Color(red: 0.9, green: 1.0, blue: 0.97)
    )
    
    static let artist = CharacterTheme(
        primary: Color(red: 0.9, green: 0.5, blue: 0.3),
        secondary: Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.8),
        background: Color(red: 1.0, green: 0.95, blue: 0.9)
    )
    
    static let military = CharacterTheme(
        primary: Color(red: 0.7, green: 0.2, blue: 0.2),
        secondary: Color(red: 0.8, green: 0.3, blue: 0.3).opacity(0.8),
        background: Color(red: 1.0, green: 0.93, blue: 0.93)
    )
    
    static let other = CharacterTheme(
        primary: Color(red: 0.3, green: 0.3, blue: 0.3),
        secondary: Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.8),
        background: Color(red: 0.95, green: 0.95, blue: 0.95)
    )
    
    // 根据领域获取主题
    static func forField(_ field: String) -> CharacterTheme {
        if field.contains("科学") || field.contains("物理") || field.contains("化学") || field.contains("数学") {
            return scientist
        } else if field.contains("哲学") || field.contains("思想家") || field.contains("伦理") {
            return philosopher
        } else if field.contains("文学") || field.contains("作家") || field.contains("诗人") {
            return writer
        } else if field.contains("艺术") || field.contains("画家") || field.contains("音乐") {
            return artist
        } else if field.contains("军事") || field.contains("将军") || field.contains("战略家") {
            return military
        } else {
            return other
        }
    }
}

/**
 * 头部视图组件
 * 显示角色基本信息
 */
private struct HeaderView: View {
    let character: Character
    
    var body: some View {
        let theme = CharacterTheme.forField(character.field)
        
        VStack(spacing: 16) {
            // 头像与背景
            ZStack(alignment: .bottom) {
                // 背景图层 - 增加温和渐变背景
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                theme.background,
                                Color(.systemBackground)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
                
                // 角色头像 - 更大更突出的头像
                ZStack {
                    // 模拟头像 - 使用字母缩写而非网络图片
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.2))
                            .frame(width: 110, height: 110)
                        
                        // 使用大字体显示名字首字母
                        Text(String(character.name.prefix(1)))
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                    .background(Circle().fill(Color.white).frame(width: 114, height: 114))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                }
                .offset(y: 40)
            }
            .frame(height: 120)
            
            // 在头像之后添加适当间距
            Spacer()
                .frame(height: 50)
            
            // 角色名称与信息
            VStack(spacing: 6) {
                // 名称
                Text(character.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                // 时代和职业
                HStack(spacing: 8) {
                    // 时代标签
                    Text(character.eraTag ?? "")
                        .font(.system(size: 14))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.primary.opacity(0.1))
                        .foregroundColor(theme.primary)
                        .cornerRadius(6)
                    
                    // 分隔点
                    Text("•")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    // 职业
                    Text(character.field)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    // 分隔点
                    Text("•")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    // 生卒年
                    Text("\(character.birthYear)-\(character.deathYear ?? "现在")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            
            // 核心思想标签云
            TagCloudView(tags: character.keyThoughts, theme: theme)
                .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

/**
 * 数据指标视图
 * 显示关注人数、互动量和评分
 */
private struct StatsView: View {
    let character: Character
    
    var body: some View {
        let theme = CharacterTheme.forField(character.field)
        
        HStack(spacing: 0) {
            // 分隔各项数据以平均占据空间
            Spacer()
            
            // 粉丝数
            StatItem(
                icon: "person.2.fill",
                value: formatNumber(character.followerCount),
                label: "粉丝",
                iconColor: theme.primary
            )
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 30)
                .padding(.horizontal, 15)
            
            // 互动量
            StatItem(
                icon: "bubble.left.and.bubble.right.fill",
                value: formatNumber(character.interactionCount),
                label: "互动量",
                iconColor: theme.primary
            )
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 30)
                .padding(.horizontal, 15)
            
            // 评分
            RatingItem(rating: character.rating)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
    
    // 单个数据指标项
    private struct StatItem: View {
        let icon: String
        let value: String
        let label: String
        var iconColor: Color = .primaryColor
        
        var body: some View {
            VStack(spacing: 6) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                
                // 数值
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                // 标签
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // 评分显示组件
    private struct RatingItem: View {
        let rating: Double
        
        var body: some View {
            VStack(spacing: 6) {
                // 星星评分
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(rating) ? "star.fill" : 
                               (index < Int(rating + 0.5) ? "star.leadinghalf.filled" : "star"))
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
                
                // 评分数值
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                // 标签
                Text("评分")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // 格式化数字
    private func formatNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1f万", Double(number) / 10000.0)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        } else {
            return "\(number)"
        }
    }
}

/**
 * 标签云视图
 * 显示角色的关键思想/标签
 */
private struct TagCloudView: View {
    let tags: [String]
    let theme: CharacterTheme
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(tags.prefix(3).enumerated()), id: \.element) { index, tag in
                Text(tag)
                    .font(.system(size: 13))
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primary.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

/**
 * 操作按钮视图
 * 包含关注、对话、分享按钮
 */
private struct ActionButtonsView: View {
    let character: Character
    let onFollowTapped: () -> Void
    let onChatTapped: () -> Void
    let onShareTapped: () -> Void
    
    var body: some View {
        let theme = CharacterTheme.forField(character.field)
        
        HStack(spacing: 16) {
            // 关注按钮
            ActionButton(
                icon: "person.crop.circle.badge.plus",
                label: "关注",
                isPrimary: false,
                themeColor: theme.primary,
                action: onFollowTapped
            )
            
            // 对话按钮 - 主按钮，更大更突出
            ActionButton(
                icon: "bubble.left.fill",
                label: "开始对话",
                isPrimary: true,
                themeColor: theme.primary,
                action: onChatTapped
            )
            
            // 分享按钮
            ActionButton(
                icon: "square.and.arrow.up",
                label: "分享",
                isPrimary: false,
                themeColor: theme.primary,
                action: onShareTapped
            )
        }
        .padding(.horizontal, 16)
    }
    
    // 操作按钮组件
    private struct ActionButton: View {
        let icon: String
        let label: String
        let isPrimary: Bool
        let themeColor: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: isPrimary ? 20 : 18))
                        .foregroundColor(isPrimary ? .white : themeColor)
                    
                    // 文字标签
                    Text(label)
                        .font(.system(size: isPrimary ? 14 : 13, weight: isPrimary ? .medium : .regular))
                        .foregroundColor(isPrimary ? .white : .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isPrimary ? 14 : 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isPrimary ? themeColor : Color.gray.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPrimary ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.96))
            .frame(maxWidth: isPrimary ? .infinity : .infinity)
        }
    }
}

/**
 * 标签栏视图
 * 提供标签切换功能
 */
private struct TabBarView: View {
    let character: Character
    let tabOptions: [String]
    @Binding var selectedTabIndex: Int
    
    var body: some View {
        let theme = CharacterTheme.forField(character.field)
        
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<tabOptions.count, id: \.self) { index in
                    Button {
                        print("标签选择: \(tabOptions[index])")
                        withAnimation {
                            selectedTabIndex = index
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tabOptions[index])
                                .font(.system(size: 16, weight: selectedTabIndex == index ? .semibold : .regular))
                                .foregroundColor(selectedTabIndex == index ? theme.primary : .secondary)
                            
                            // 选中指示条
                            Rectangle()
                                .fill(selectedTabIndex == index ? theme.primary : Color.clear)
                                .frame(height: 2)
                                .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ScaleButtonStyle(scaleAmount: 0.97))
                }
            }
            .padding(.vertical, 12)
            .background(Color.white)
            
            // 底部分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
        }
    }
}

/**
 * 介绍视图
 * 显示角色的详细介绍
 */
private struct IntroductionView: View {
    let character: Character
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 基本介绍
            ContentSection(
                title: "基本介绍",
                icon: "info.circle.fill",
                content: character.introduction,
                character: character
            )
            .opacity(animationAmount)
            .offset(y: animationAmount * 20)
            
            // 主要成就
            ContentSection(
                title: "主要成就",
                icon: "trophy.fill",
                content: character.achievements.joined(separator: "\n\n"),
                character: character
            )
            .opacity(animationAmount)
            .offset(y: (1.0 - animationAmount) * 25)
            
            // 主要作品
            ContentSection(
                title: "主要作品",
                icon: "book.fill",
                content: character.mainWorks.joined(separator: "\n\n"),
                character: character
            )
            .opacity(animationAmount)
            .offset(y: (1.0 - animationAmount) * 30)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 80)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animationAmount = 1.0
            }
        }
    }
}

/**
 * 相关信息视图
 * 显示与角色相关的历史背景、影响等信息
 */
private struct RelatedInfoView: View {
    let character: Character
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 历史背景
            ContentSection(
                title: "历史背景",
                icon: "clock.fill",
                content: "生活在\(character.eraTag ?? "")期间，\(character.name)的思想深受当时社会环境的影响。这个时期的主要特点是思想交流和文化融合不断深入。",
                character: character
            )
            .opacity(animationAmount)
            .offset(y: animationAmount * 20)
            
            // 同时代人物
            ContentSection(
                title: "同时代人物",
                icon: "person.2.fill",
                content: "与\(character.name)同时代的著名人物包括许多在不同领域有突出贡献的思想家、艺术家和科学家，他们之间的思想交流形成了这一时期丰富的文化景观。",
                character: character
            )
            .opacity(animationAmount)
            .offset(y: (1.0 - animationAmount) * 25)
            
            // 历史影响
            ContentSection(
                title: "历史影响",
                icon: "waveform.path.ecg",
                content: "\(character.name)的思想和贡献对后世产生了深远影响，特别是在\(character.field)领域。其核心思想「\(character.keyThoughts.first ?? "")」至今仍被广泛研究和引用。",
                character: character
            )
            .opacity(animationAmount)
            .offset(y: (1.0 - animationAmount) * 30)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 80)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animationAmount = 1.0
            }
        }
    }
}

/**
 * 互动记录视图
 * 显示与角色的历史对话记录
 */
private struct InteractionView: View {
    let character: Character
    let conversations: [Conversation]
    let onChatSelected: (String) -> Void
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // 新对话按钮
            Button {
                print("开始新对话")
                onChatSelected(UUID().uuidString)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("开始新对话")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primaryColor)
                )
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.97))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .opacity(animationAmount)
            .offset(y: (1.0 - animationAmount) * 20)
            
            if conversations.isEmpty {
                // 空对话提示
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.bottom, 8)
                    
                    Text("还没有与\(character.name)的对话记录")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Text("点击"开始新对话"，与这位历史人物展开对话吧")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .opacity(animationAmount)
                .offset(y: (1.0 - animationAmount) * 25)
            } else {
                // 对话记录列表
                LazyVStack(spacing: 0) {
                    ForEach(conversations, id: \.id) { conversation in
                        ConversationRow(
                            character: character,
                            conversation: conversation,
                            onTap: {
                                onChatSelected(conversation.id)
                            }
                        )
                        
                        if conversation.id != conversations.last?.id {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                .opacity(animationAmount)
                .offset(y: (1.0 - animationAmount) * 25)
            }
            
            Spacer(minLength: 60)
        }
        .padding(.top, 16)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animationAmount = 1.0
            }
        }
    }
}

/**
 * 对话行视图
 * 显示单条对话记录
 */
private struct ConversationRow: View {
    let character: Character
    let conversation: Conversation
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        let theme = CharacterTheme.forField(character.field)
        
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 角色头像
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
                
                // 对话内容预览
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(conversation.lastMessageTime))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(conversation.lastMessageContent)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primary.opacity(0.7))
                    .offset(x: isPressed ? 5 : 0)
                    .animation(.easeOut(duration: 0.2), value: isPressed)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? theme.background.opacity(0.5) : Color.white)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = pressing
            }
        }, perform: { })
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}

/**
 * 内容区块组件
 * 用于显示带有标题和图标的内容块
 */
private struct ContentSection: View {
    let title: String
    let icon: String
    let content: String
    let character: Character?
    
    init(title: String, icon: String, content: String, character: Character? = nil) {
        self.title = title
        self.icon = icon
        self.content = content
        self.character = character
    }
    
    var body: some View {
        // 如果有角色参数则使用对应主题色，否则使用默认主题色
        let theme = character != nil ? 
            CharacterTheme.forField(character!.field) : 
            CharacterTheme.other
        
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.primary)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // 内容文本
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(.leading, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.primary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

// 添加滚动指示器组件
private struct ScrollingPageIndicator: View {
    let character: Character
    @Binding var currentPage: Int
    let numberOfPages: Int
    
    var body: some View {
        let theme = CharacterTheme.forField(character.field)
        
        HStack(spacing: 6) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(currentPage == page ? theme.primary : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPage == page ? 1.2 : 1.0)
                    .animation(.spring(), value: currentPage)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

/**
 * 角色详情页预览
 */
struct CharacterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CharacterDetailView(
                character: Character(
                    name: "阿尔伯特·爱因斯坦",
                    introduction: "现代物理学最重要的科学家之一，相对论的创立者。他的质能方程E=mc²彻底改变了人类对能量与物质关系的认识，而他的相对论则彻底改变了物理学的发展方向。",
                    field: "物理学家",
                    birthYear: "1879",
                    deathYear: "1955",
                    avatarUrl: "https://example.com/einstein.jpg",
                    eraTag: "1900s",
                    achievements: ["相对论", "光电效应", "质能方程"],
                    mainWorks: ["相对论：广义和狭义", "光电效应研究", "布朗运动研究"],
                    keyThoughts: ["时间和空间是相对的", "质量可以转化为能量", "自然界的规律是简单而统一的"]
                )
            )
        }
    }
} 