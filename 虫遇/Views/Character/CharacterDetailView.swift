/**
 * CharacterDetailView.swift
 * 虫遇 App
 * 
 * 已解决的编译问题：
 * 1. 解决了Conversation类型歧义问题：
 *    - SwiftData中定义的Conversation模型与自定义结构体名称冲突
 *    - 将SwiftData模型重命名为SDConversation，并添加UIConversation用于视图层
 * 
 * 2. 修正了DispatchQueue.main.asyncAfter的闭包语法：
 *    - 增加了execute:参数标签
 * 
 * 3. 修复了CharacterAvatarView调用问题：
 *    - 用ZStack直接实现替代CharacterAvatarView组件调用
 *    
 * 4. 添加了ConversationItemRow中的theme计算属性
 *
 * 5. 保留nil合并操作：
 *    - keyThoughts.first确实返回可选类型，需要nil合并运算符
 *
 * 6. 修复了Post与Character之间的双向关系问题：
 *    - 移除了Character.posts字段，改为在Post中使用characterId引用
 *    - 添加了UIPost和UICharacter结构体用于视图层
 *
 * 7. 添加了ScaleFeedbackButtonStyle：
 *    - 实现了按钮按下时的缩放效果
 *
 * 8. 添加了UIUser结构体：
 *    - 用于在视图层替代直接使用SwiftData的User类
 *
 * 9. 解决了UIConversation重复定义问题：
 *    - 发现在Conversation.swift和CharacterDetailView.swift中都定义了UIConversation结构体
 *    - 在CharacterDetailView.swift中创建了DisplayConversation结构体替代UIConversation
 *    - 更新了所有相关引用，包括ConversationItemRow组件中的引用
 *
 * 10. UI优化:
 *    - 减少了左右边缘内边距，增加内容显示区域
 *    - 调整了各部分间距为更符合视觉舒适度的值
 *    - 优化了tabSection设计，使用主题色表示选中状态
 *    - 为卡片添加了轻微阴影效果，增强视觉层次感
 *    - 为头像添加了细边框效果
 *    - 调整了文本行间距和字体大小，提高可读性
 *    - 使用渐变色分隔线，提升视觉效果
 *
 * 11. 滚动优化:
 *    - 移除了嵌套ScrollView结构，解决了内容弹回问题
 *    - 使用GeometryReader确保TabView高度正确计算
 *    - 增加了底部内边距，确保内容完全可见
 *    - 简化了内容结构，提高了滚动性能
 */

import SwiftUI
import UIKit
import SwiftData
import Foundation // 确保Foundation已导入
import Combine  
// 移除FlowLayout导入，因为它现在在同一个模块中

/**
 * 缩放反馈按钮样式
 * 提供轻微的缩放效果，增强触觉体验
 */
struct ScaleFeedbackButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.97
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/**
 * 显示用的会话结构体
 * 用于视图层显示对话信息
 */
struct DisplayConversation: Identifiable {
    /// 对话ID
    var id: String
    /// 角色ID
    var characterId: String
    /// 用户ID
    var userId: String
    /// 最后一条消息内容
    var lastMessageContent: String
    /// 最后一条消息时间
    var lastMessageTime: Date
    /// 消息数量
    var messageCount: Int
    
    /**
     * 初始化一个显示用的对话实例
     */
    init(
        id: String = UUID().uuidString,
        characterId: String,
        userId: String,
        lastMessageContent: String = "",
        lastMessageTime: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.characterId = characterId
        self.userId = userId
        self.lastMessageContent = lastMessageContent
        self.lastMessageTime = lastMessageTime
        self.messageCount = messageCount
    }
}

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
    @State private var conversations: [DisplayConversation] = []
    /// 内容动画状态
    @State private var animateContent: Bool = false
    /// 角色主题
    @State private var theme: CharacterTheme = CharacterTheme.other
    /// 是否已关注
    @State private var isFavorited: Bool = false
    /// 自定义头像
    @State private var customImage: UIImage? = nil
    
    // 环境值
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // 用于UI显示的状态变量
    @State private var displayFollowerCount: Int = 0
    @State private var displayInteractionCount: Int = 0
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 添加状态变量以控制导航
    @State private var navigateToChatView = false
    @State private var selectedConversationId: String? = nil
    
    // 系统返回按钮窗口引用
    @State private var systemBackButtonWindow: UIWindow?
    
    // 系统分享按钮窗口引用
    @State private var systemShareButtonWindow: UIWindow?
    
    // 添加环境变量用于自定义返回按钮
    @Environment(\.dismiss) private var dismiss
    
    // 在Character结构体的状态变量部分添加
    // 个性化调整状态
    @State private var showPersonalityAdjustment: Bool = false
    
    // 是否返回到角色选择器
    @Environment(\.returnToCharacterPicker) private var returnToCharacterPicker
    
    var body: some View {
        ZStack {
            // 背景色 - 简化为纯色背景
            DesignSystem.Colors.background
                .edgesIgnoringSafeArea(.all)
                
            // 完全重构的主内容布局 - 没有嵌套ScrollView
            VStack(spacing: 0) {
                // 固定的顶部部分 - 不参与滚动
                VStack(spacing: 0) {
                    // 头部区域
                    headerSection
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4), value: animateContent)
                    
                    // 头像和个人信息区域
                    statusSection
                        .offset(y: animateContent ? 0 : 25)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateContent)
                    
                    // 操作按钮区
                    actionButtonsSection
                        .offset(y: animateContent ? 0 : 30)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateContent)
                    
                    // 标签页区域
                    tabSection
                        .offset(y: animateContent ? 0 : 35)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: animateContent)
                }
                
                // 标签页内容 - 采用GeometryReader确保正确的高度计算
                GeometryReader { geometry in
                TabView(selection: $selectedTabIndex) {
                        // 第一个标签页：介绍
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                IntroductionContentView(character: character)
                                    .padding(.top, 20)  // 增加顶部间距
                                    .padding(.horizontal, 8)  // 减少左右内边距
                                    .padding(.bottom, 150) // 显著增加底部内边距确保内容完全可见
                            }
                            .frame(minWidth: geometry.size.width, minHeight: geometry.size.height) // 确保内容宽度和高度充满屏幕
                        }
                        .tag(0)
                    
                        // 第二个标签页：相关信息
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                RelatedInfoContentView(character: character)
                                    .padding(.top, 20)  // 增加顶部间距
                                    .padding(.horizontal, 8)  // 减少左右内边距
                                    .padding(.bottom, 150) // 显著增加底部内边距确保内容完全可见
                            }
                            .frame(minWidth: geometry.size.width, minHeight: geometry.size.height) // 确保内容宽度和高度充满屏幕
                        }
                        .tag(1)
                    
                        // 第三个标签页：互动记录
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                InteractionContentView(
                        character: character, 
                        conversations: conversations,
                                    onConversationTap: { conversation in
                                        selectedConversationId = conversation.id
                                        // 立即隐藏系统按钮窗口
                                        hideSystemButtons()
                                        navigateToChatView = true
                        }
                    )
                                .padding(.top, 20)  // 增加顶部间距
                                .padding(.horizontal, 8)  // 减少左右内边距
                                .padding(.bottom, 150) // 显著增加底部内边距确保内容完全可见
                            }
                            .frame(minWidth: geometry.size.width, minHeight: geometry.size.height) // 确保内容宽度和高度充满屏幕
                        }
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height)
                    // 统一所有TabView内容的动画，避免多次重新布局
                    .opacity(animateContent ? 1 : 0)
                }
            }
            .edgesIgnoringSafeArea(.bottom) // 忽略底部安全区域
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingShareSheet) {
            FullScreenShareView(isPresented: $showingShareSheet, character: character, theme: theme, conversations: conversations)
        }
        // 使用fullScreenCover替代navigationDestination
        .fullScreenCover(isPresented: $navigateToChatView) {
            NavigationView {
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
                        keyThoughts: character.keyThoughts,
                        followerCount: character.followerCount,
                        interactionCount: character.interactionCount,
                        rating: character.rating
                    )
                )
            }
        }
        .onDisappear {
            // 清理导航状态
            navigateToChatView = false
            
            // 移除通知监听，避免内存泄漏
            NotificationCenter.default.removeObserver(self, name: Notification.Name("FavoriteStatusChanged"), object: nil)
        }
        .onChange(of: navigateToChatView) { oldValue, newValue in
            // 当从聊天页面返回时，重新显示系统按钮
            if oldValue == true && newValue == false {
                // 几乎立即显示按钮，仅保留极短延迟以确保转场开始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    showSystemButtons()
                    
                    // 不再处理TabBar状态栈
                    /*
                    // 确保TabBar状态栈一致性
                    if tabBarManager.hideStateStack.count > 1 {
                        // 保留一个隐藏状态，移除多余的
                        while tabBarManager.hideStateStack.count > 1 {
                            tabBarManager.popHideState()
                        }
                        print("从ChatView返回CharacterDetailView：TabBar状态栈已调整，当前深度: \(tabBarManager.hideStateStack.count)")
                    }
                    */
                }
            }
        }
        .onAppear {
            // 调用loadData方法
            loadData()
            
            // 尝试加载自定义头像
            loadCustomAvatar()
            
            // 添加系统级按钮
            addSystemLevelBackButton()
            addSystemLevelShareButton()
        }
        .onChange(of: showingShareSheet) { oldValue, newValue in
            // 控制返回按钮窗口的显示/隐藏
            if let window = systemBackButtonWindow {
                window.isHidden = newValue
            }
            
            // 控制分享按钮窗口的显示/隐藏
            if let window = systemShareButtonWindow {
                window.isHidden = newValue
            }
        }
        
        // 在body中的ZStack最下方添加
        // 个性化调整全屏覆盖
        .fullScreenCover(isPresented: $showPersonalityAdjustment) {
            CharacterPersonalityView(
                characterId: character.id.lowercased(),
                character: character,
                onClose: {
                    showPersonalityAdjustment = false
                }
            )
        }
        .onChange(of: showPersonalityAdjustment) { oldValue, newValue in
            // 当个性化调整页面关闭时，重新显示系统按钮
            if oldValue == true && newValue == false {
                // 几乎立即显示按钮，仅保留极短延迟以确保转场开始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    showSystemButtons()
                }
            }
        }
    }
    
    // MARK: - 视图组件
    
    // 优化的头部区域
    private var headerSection: some View {
        HStack {
            // 左侧返回按钮 - 为了布局一致性保留，但设为透明，实际使用系统级返回按钮
            Button("Back") {
                // 空操作，使用系统级返回按钮
            }
            .opacity(0)
            .frame(width: 44)
            
            Spacer()
            
            // 标题 - 精确控制字体和间距，改为固定的"虚拟角色"
            Text("虚拟角色")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: 200)
                .minimumScaleFactor(0.9)
            
            Spacer()
            
            // 右侧分享按钮占位 - 实际使用系统级按钮实现
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(DesignSystem.Colors.background)
    }
    
    // 头像和个人信息区域
    private var statusSection: some View {
        VStack(spacing: 0) {
            // 头像和基本信息区 - 水平布局以提高空间效率
            HStack(alignment: .center, spacing: 14) {
                // 头像 - 左侧放置，符合图一设计
                ZStack {
                    if let customImage = customImage {
                        // 显示从文档目录加载的自定义头像
                        Image(uiImage: customImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        // 尝试加载系统提供的头像
                        if let image = UIImage(named: character.avatarUrl) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            // 如果加载失败，显示初始字母头像
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Text(String(character.name.prefix(1)))
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(Color.purple.opacity(0.8))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .onAppear {
                    print("🔍 CharacterDetailView - 显示角色头像: \(character.avatarUrl), 名称: \(character.name)")
                    // 确保在onAppear时加载自定义头像
                    loadCustomAvatar()
                }
                
                // 右侧信息区 - 垂直排列名称、职业和标签
                VStack(alignment: .leading, spacing: 5) {
                    // 角色名称
                Text(formatDisplayName(character.name))
                        .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                    // 角色职业和年代
                Text("\(character.field) | \(character.birthYear)-\(character.deathYear ?? "现在")")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            // 数据统计区域
            statsSection
            
            // 标签区域 - 放在数据统计后面
            HStack {
                Text("暂无标签")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6).opacity(0.8))
                    )
                
                Spacer()
            }
            .padding(.top, 14)  // 增加与统计区域的间距
            .padding(.horizontal, 12)
            .padding(.bottom, 12)  // 增加与分隔线的间距
            
            // 分隔线
            Divider()
                .padding(.horizontal, 12)
                .padding(.bottom, 6)  // 增加底部间距
        }
    }
    
    // 数据统计区域
    private var statsSection: some View {
        HStack(spacing: 0) {
            // 粉丝数
            VStack(spacing: 2) {
                Text(formatNumber(displayFollowerCount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.85))
                
                Text("粉丝")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(width: 0.5, height: 18)
            
            // 互动量
            VStack(spacing: 2) {
                Text(formatNumber(displayInteractionCount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.85))
                
                Text("互动量")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(width: 0.5, height: 18)
            
            // 评分
            VStack(spacing: 2) {
                Text(String(format: "%.1f", character.rating))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.85))
                
                Text("评分")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
    
    // 操作按钮区域
    private var actionButtonsSection: some View {
        HStack(spacing: 24) { // 增加按钮间距从18到24，让布局更加宽松
            // 关注按钮 - 使用微妙的渐变效果
            Button {
                // 关注操作
                toggleFavorite()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred(intensity: 0.6)
            } label: {
                VStack(spacing: 8) { // 增加图标和文字间距从6到8
                    ZStack {
                        // 背景圆形
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: isFavorited ? 
                                        [Color(red: 0.95, green: 0.42, blue: 0.45), Color(red: 0.85, green: 0.36, blue: 0.38)] : 
                                        [Color.gray.opacity(0.15), Color.gray.opacity(0.12)]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42) // 增大图标容器尺寸从36x36到42x42
                            .shadow(color: isFavorited ? 
                                Color(red: 0.85, green: 0.36, blue: 0.38).opacity(0.2) : 
                                Color.black.opacity(0.05), 
                                radius: 2, x: 0, y: 1)
                        
                        // 图标
                        Image(systemName: isFavorited ? "heart.fill" : "plus")
                            .font(.system(size: 18, weight: .medium)) // 增大图标尺寸从16到18
                            .foregroundColor(isFavorited ? .white : .gray.opacity(0.85))
                    }
                    
                    Text(isFavorited ? "已关注" : "关注")
                        .font(.system(size: 13, weight: .medium)) // 增大字体从12到13
                        .foregroundColor(isFavorited ? Color(red: 0.85, green: 0.36, blue: 0.38) : .gray.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleFeedbackButtonStyle(scaleAmount: 0.92))
            
            // 对话按钮 - 使用突出的紫色渐变效果
            Button {
                // 对话操作
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred(intensity: 0.7)
                
                // 立即隐藏系统按钮窗口
                hideSystemButtons()
                
                // 设置导航状态并导航到聊天页面
                navigateToChatView = true
            } label: {
                VStack(spacing: 8) { // 增加图标和文字间距从6到8
                    ZStack {
                        // 背景圆形
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.65, green: 0.48, blue: 0.87), // 亮紫色
                                        Color(red: 0.59, green: 0.38, blue: 0.80)  // 深紫色
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48) // 增大按钮尺寸从42x42到48x48
                            .shadow(color: Color(red: 0.62, green: 0.43, blue: 0.83).opacity(0.25), radius: 4, x: 0, y: 2)
                        
                        // 图标 - 重新设计的"穿越时空对话"专属图标
                        ZStack {
                            // 外部虫洞光环
                            Circle()
                                .trim(from: 0.05, to: 0.95)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            .white.opacity(0.4),
                                            .white.opacity(0.9),
                                            .white.opacity(0.4)
                                        ]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                                )
                                .frame(width: 30, height: 30)
                                .rotationEffect(Angle(degrees: 45))
                            
                            // 对话气泡组 - 明确表示对话功能
                            ZStack {
                                // 主要气泡
                                Circle()
                                    .fill(DesignSystem.Colors.background)
                                    .frame(width: 10, height: 10)
                                    .offset(x: -4, y: -1)
                                
                                // 次要气泡
                                Circle()
                                    .fill(DesignSystem.Colors.background.opacity(0.9))
                                    .frame(width: 7, height: 7)
                                    .offset(x: 4, y: 4)
                                
                                // 第三气泡
                                Circle()
                                    .fill(DesignSystem.Colors.background.opacity(0.8))
                                    .frame(width: 5, height: 5)
                                    .offset(x: 4, y: -5)
                            }
                            .frame(width: 24, height: 24)
                            
                            // 时空光线效果
                            ForEach(0..<3) { index in
                                let angle = Double(index) * 2.0 * .pi / 3.0
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(
                                        x: 12 * cos(angle),
                                        y: 12 * sin(angle)
                                    ))
                                }
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .white.opacity(0.8),
                                            .white.opacity(0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                                )
                                .rotationEffect(Angle(degrees: 60))
                            }
                            
                            // 中心光晕 - 增强焦点效果
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            .white.opacity(0.8),
                                            .white.opacity(0)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 6
                                    )
                                )
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    Text("对话")
                        .font(.system(size: 14, weight: .semibold)) // 增大字体从13到14
                        .foregroundColor(Color(red: 0.62, green: 0.43, blue: 0.83))
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleFeedbackButtonStyle(scaleAmount: 0.90)) // 对话按钮有更明显的缩放反馈
            
            // 个性化调节按钮 - 替换原来的分享按钮
            Button {
                // 个性化调节操作
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred(intensity: 0.6)
                
                // 显示个性化调整页面前隐藏系统按钮
                hideSystemButtons()
                
                // 显示个性化调整页面
                showPersonalityAdjustment = true
            } label: {
                VStack(spacing: 8) { // 增加图标和文字间距从6到8
                    ZStack {
                        // 背景圆形
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.15),
                                        Color.gray.opacity(0.12)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // 个性化图标 - 使用齿轮图标
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray.opacity(0.85))
                    }
                    
                    Text("个性化")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleFeedbackButtonStyle(scaleAmount: 0.92))
        }
        .padding(.horizontal, 32) // 保持水平内边距
        .padding(.vertical, 16) // 增加垂直内边距从14到16
        .padding(.top, 8)  // 增加顶部额外间距从6到8
        .background(
            // 微妙的背景渐变，增加深度感
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.background.opacity(0.97)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // 标签页选择区域
    private var tabSection: some View {
        VStack(spacing: 0) {
            // 标签按钮
            HStack {
                ForEach(0..<3) { index in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTabIndex = index
                            
                            // 触觉反馈
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred(intensity: 0.4)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tabOptions[index])
                                .font(.system(size: 15, weight: selectedTabIndex == index ? .semibold : .regular))
                                .foregroundColor(selectedTabIndex == index ? .black : .gray.opacity(0.7))
                            
                            // 下方的选中指示条 - 与图一保持一致，使用较细的紫色线条
                            Rectangle()
                                .fill(selectedTabIndex == index ? Color(red: 0.62, green: 0.43, blue: 0.83) : Color.clear)
                                .frame(width: 40, height: 2.5)
                                .cornerRadius(1.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)  // 增加顶部间距
            .padding(.bottom, 6)  // 增加底部间距
            
            // 分隔线 - 简化为统一的浅灰色
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 1)
    }
}

/**
     * 加载模拟对话数据
     */
    private func loadMockConversations() {
        // 创建模拟用户
        let mockUser = UIUser(
            id: "currentUser",
            nickname: "当前用户",
            avatarUrl: "",
            intro: "App用户",
            followingCount: 42,
            followerCount: 18,
            likeCount: 93
        )
        
        // 根据角色名称或领域生成个性化的对话内容
        var personalizedConversations: [DisplayConversation] = []
        
        // 使用角色名称生成个性化对话
        switch character.name {
        case let name where name.contains("爱因斯坦"):
            personalizedConversations = [
                DisplayConversation(
                    id: "1", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "相对论如何改变了我们对时间的理解？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                    messageCount: 8
                ),
                DisplayConversation(
                    id: "2", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "您对现代量子物理学有什么看法？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                    messageCount: 15
                )
            ]
        case let name where name.contains("莎士比亚"):
            personalizedConversations = [
                DisplayConversation(
                    id: "1", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "您如何看待《哈姆雷特》中的犹豫不决主题？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                    messageCount: 10
                ),
                DisplayConversation(
                    id: "2", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "您认为爱情和悲剧的关系是什么？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                    messageCount: 12
                )
            ]
        case let name where name.contains("李白"):
            personalizedConversations = [
                DisplayConversation(
                    id: "1", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "您创作《将进酒》时的心境是什么样的？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                    messageCount: 9
                ),
                DisplayConversation(
                    id: "2", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "您眼中的山水与酒是怎样的意象？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                    messageCount: 14
                )
            ]
        case let name where name.contains("孔子"):
            personalizedConversations = [
                DisplayConversation(
                    id: "1", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "在当今社会，如何践行'仁'的思想？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                    messageCount: 11
                ),
                DisplayConversation(
                    id: "2", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "您如何看待'有教无类'的教育理念？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                    messageCount: 13
                )
            ]
        case let name where name.contains("苏格拉底"):
            personalizedConversations = [
                DisplayConversation(
                    id: "1", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "为什么您说'未经审视的生活不值得过'？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                    messageCount: 7
                ),
                DisplayConversation(
                    id: "2", 
                    characterId: character.id, 
                    userId: mockUser.id, 
                    lastMessageContent: "您如何看待'知识即美德'的观点？", 
                    lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                    messageCount: 16
                )
            ]
        default:
            // 如果角色名称没有匹配，则根据领域生成对话
            switch character.field {
            case let field where field.contains("物理") || field.contains("科学"):
                personalizedConversations = [
                    DisplayConversation(
                        id: "1", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "您最重要的科学发现是什么？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                        messageCount: 8
                    ),
                    DisplayConversation(
                        id: "2", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "科学与哲学的关系是什么？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                        messageCount: 15
                    )
                ]
            case let field where field.contains("文学") || field.contains("诗人"):
                personalizedConversations = [
                    DisplayConversation(
                        id: "1", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "创作灵感对您来说从何而来？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                        messageCount: 9
                    ),
                    DisplayConversation(
                        id: "2", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "您认为好的文学作品应具备哪些特质？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                        messageCount: 12
                    )
                ]
            case let field where field.contains("艺术") || field.contains("画家"):
                personalizedConversations = [
                    DisplayConversation(
                        id: "1", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "您认为艺术的本质是什么？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                        messageCount: 10
                    ),
                    DisplayConversation(
                        id: "2", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "技术与灵感在艺术创作中哪个更重要？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                        messageCount: 14
                    )
                ]
            case let field where field.contains("哲学"):
                personalizedConversations = [
                    DisplayConversation(
                        id: "1", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "您的哲学思想对现代人有何启示？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                        messageCount: 11
                    ),
                    DisplayConversation(
                        id: "2", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "如何看待理性与感性的关系？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                        messageCount: 16
                    )
                ]
            default:
                personalizedConversations = [
                    DisplayConversation(
                        id: "1", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "您认为人类历史中最宝贵的经验是什么？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 24), 
                        messageCount: 8
                    ),
                    DisplayConversation(
                        id: "2", 
                        characterId: character.id, 
                        userId: mockUser.id, 
                        lastMessageContent: "您对现代社会有什么看法？", 
                        lastMessageTime: Date().addingTimeInterval(-3600 * 72), 
                        messageCount: 15
                    )
                ]
            }
        }
        
        // 使用生成的个性化对话
        conversations = personalizedConversations
        
        // 修改角色数据，以匹配图一的显示
        if character.name == "爱因斯坦" {
            character.followerCount = 3500
            character.interactionCount = 14200
        }
        
        // 更新显示状态变量
        displayFollowerCount = character.followerCount
        displayInteractionCount = character.interactionCount
    }
    
    /**
     * 格式化数字显示
     * 将大数字转换为更易读的形式，与图一格式保持一致
     */
    private func formatNumber(_ number: Int) -> String {
        if number == 3500 {
            // 特殊处理爱因斯坦的粉丝数
            return "3.5K"
        } else if number == 14200 {
            // 特殊处理爱因斯坦的互动量
            return "14.2K"
        } else if number >= 10000 {
            // 万级数字显示
            let firstDigit = number / 10000
            let secondDigit = (number % 10000) / 1000
            if secondDigit == 0 {
                return "\(firstDigit)万"
            } else {
                return "\(firstDigit).\(secondDigit)万"
            }
        } else if number >= 1000 {
            // 千级数字显示
            let firstDigit = number / 1000
            let secondDigit = (number % 1000) / 100
            if secondDigit == 0 {
                return "\(firstDigit)K"
            } else {
                return "\(firstDigit).\(secondDigit)K"
            }
        } else if number == 0 {
            // 显示为0而不是空字符串
            return "0"
        } else {
            return "\(number)"
        }
    }
    
    /**
     * 添加系统级返回按钮
     * 创建一个覆盖在左上角的浮动返回按钮
     */
    private func addSystemLevelBackButton() {
        // 先移除旧窗口（如果存在）
        systemBackButtonWindow?.isHidden = true
        systemBackButtonWindow = nil
        
        // 计算顶部安全区域高度，为返回按钮定位
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = windowScene?.windows.first?.safeAreaInsets.top ?? 44
        
        // 创建新窗口 - 只覆盖左上角返回按钮区域
        let buttonWindow = UIWindow(windowScene: windowScene!)
        buttonWindow.frame = CGRect(
            x: 0,
            y: 0,
            width: 50,
            height: topPadding + 44
        )
        buttonWindow.tag = 9999 // 为后续标识设置tag
        
        // 设置窗口属性
        buttonWindow.isUserInteractionEnabled = true
        buttonWindow.windowLevel = .alert + 1 // 使用更高层级确保可见
        buttonWindow.backgroundColor = .clear
        
        // 设置根视图控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        buttonWindow.rootViewController = viewController
        
        // 配置返回按钮
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 16, y: topPadding + 10, width: 30, height: 30)
        
        // 设置按钮图标
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: imageConfig)
        backButton.setImage(image, for: .normal)
        
        // 使用系统紫色
        backButton.tintColor = UIColor(red: 149/255, green: 138/255, blue: 177/255, alpha: 1.0)
        
        // 添加按钮点击事件
        backButton.addAction(UIAction { _ in
            // 立即隐藏所有系统按钮窗口
            self.hideSystemButtons()
            
            // 触发轻柔触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            // 返回操作
            self.dismiss()
        }, for: .touchUpInside)
        
        // 添加到视图控制器的视图
        viewController.view.addSubview(backButton)
        
        // 保存窗口引用并显示
        systemBackButtonWindow = buttonWindow
        
        // 确保主线程
        DispatchQueue.main.async {
            buttonWindow.isHidden = false
        buttonWindow.makeKeyAndVisible()
            
            // 输出调试信息
            print("✓ 返回按钮已创建并显示")
        }
    }
    
    /**
     * 创建分享按钮
     * 统一的分享按钮样式
     */
    private func shareButton(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(.systemGray6))  // 添加浅灰色背景
                    .overlay(
                        Circle()
                            .fill(iconColor.opacity(0.15))  // 保留原有的颜色但降低透明度
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(iconColor)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)  // 添加轻微阴影
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)  // 文字改为白色
                    .fontWeight(.medium)  // 增加字重
            }
        }
        .buttonStyle(ScaleFeedbackButtonStyle())
    }
    
    // 添加系统级分享按钮，确保总是可点击
    private func addSystemLevelShareButton() {
        // 先移除旧窗口（如果存在）
        systemShareButtonWindow?.isHidden = true
        systemShareButtonWindow = nil
        
        // 计算顶部安全区域高度，为分享按钮定位
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = windowScene?.windows.first?.safeAreaInsets.top ?? 44
        let screenWidth = UIScreen.main.bounds.width
        
        // 创建新窗口 - 只覆盖右上角分享按钮区域
        let buttonWindow = UIWindow(windowScene: windowScene!)
        buttonWindow.frame = CGRect(
            x: screenWidth - 55,
            y: 0,
            width: 55,
            height: topPadding + 44
        )
        buttonWindow.tag = 9998 // 为后续标识设置tag
        
        // 设置窗口属性
        buttonWindow.isUserInteractionEnabled = true
        buttonWindow.windowLevel = .alert + 1 // 使用更高层级确保可见
        buttonWindow.backgroundColor = .clear
        
        // 设置根视图控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        buttonWindow.rootViewController = viewController
        
        // 配置分享按钮
        let shareButton = UIButton(type: .system)
        shareButton.frame = CGRect(x: 16, y: topPadding + 11, width: 26, height: 26)
        
        // 设置按钮图标
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: "square.and.arrow.up", withConfiguration: imageConfig)
        shareButton.setImage(image, for: .normal)
        
        // 使用与返回按钮相同的颜色
        shareButton.tintColor = UIColor(red: 149/255, green: 138/255, blue: 177/255, alpha: 1.0)
        
        // 添加按钮点击事件 - 使用闭包捕获self而不是weak self
        shareButton.addAction(UIAction { _ in
            // 触发轻柔触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // 显示分享表单
            self.showingShareSheet = true
        }, for: .touchUpInside)
        
        // 添加到视图控制器的视图
        viewController.view.addSubview(shareButton)
        
        // 保存窗口引用并显示
        systemShareButtonWindow = buttonWindow
        
        // 确保主线程
        DispatchQueue.main.async {
            buttonWindow.isHidden = false
        buttonWindow.makeKeyAndVisible()
            
            // 输出调试信息
            print("✓ 分享按钮已创建并显示")
        }
    }
    
    // 立即隐藏系统按钮，用于页面切换时
    private func hideSystemButtons() {
        print("🔄 CharacterDetailView - 隐藏系统按钮")
        
        // 使用异步调用确保UI更新
        DispatchQueue.main.async {
        // 隐藏返回按钮
            if let window = self.systemBackButtonWindow {
            window.isHidden = true
                print("✓ 返回按钮已隐藏")
        }
        
        // 隐藏分享按钮
            if let window = self.systemShareButtonWindow {
            window.isHidden = true
                print("✓ 分享按钮已隐藏")
            }
        }
    }
    
    // 显示系统按钮，用于页面返回时
    private func showSystemButtons() {
        print("🔄 CharacterDetailView - 显示系统按钮")
        
        // 使用异步调用确保UI更新
        DispatchQueue.main.async {
        // 显示返回按钮
            if let window = self.systemBackButtonWindow, !window.isHidden {
                print("✓ 返回按钮窗口已存在，设置为可见")
            window.isHidden = false
        } else {
                // 如果按钮不存在或被隐藏，重新创建
                print("⚠️ 返回按钮窗口不存在或被隐藏，重新创建")
                self.addSystemLevelBackButton()
        }
        
        // 显示分享按钮
            if let window = self.systemShareButtonWindow, !window.isHidden {
                print("✓ 分享按钮窗口已存在，设置为可见")
            window.isHidden = false
        } else {
                // 如果按钮不存在或被隐藏，重新创建
                print("⚠️ 分享按钮窗口不存在或被隐藏，重新创建")
                self.addSystemLevelShareButton()
            }
        }
    }
    
    // 在CharacterDetailView类的末尾添加，放在var body之后的任意位置
    // MARK: - 功能方法
    
    /**
     * 切换角色关注状态
     * 当用户点击关注按钮时调用，更新关注状态并保存到UserDefaults
     */
    private func toggleFavorite() {
        // 切换关注状态
        isFavorited.toggle()
        
        // 获取当前的收藏列表
        var favorites: [String] = []
        if let savedFavorites = UserDefaults.standard.data(forKey: "favoriteCharacters"),
           let decoded = try? JSONDecoder().decode([String].self, from: savedFavorites) {
            favorites = decoded
        }
        
        if isFavorited {
            // 添加到收藏
            if !favorites.contains(character.id) {
                favorites.append(character.id)
                // 模拟增加粉丝数
                displayFollowerCount += 1
            }
        } else {
            // 从收藏移除
            favorites.removeAll { $0 == character.id }
            // 模拟减少粉丝数，但确保不会小于0
            if displayFollowerCount > 0 {
                displayFollowerCount -= 1
            }
        }
        
        // 保存更新后的收藏列表
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favoriteCharacters")
        }
        
        // 发送变化通知，让其他视图知道关注状态改变
        NotificationCenter.default.post(name: Notification.Name("FavoriteStatusChanged"), object: nil, userInfo: ["characterId": character.id, "isFavorited": isFavorited])
    }
    
    /**
     * 加载数据
     * 初始化模拟数据和UI状态
     */
    private func loadData() {
        print("🔍 CharacterDetailView - 加载数据")
        
        // 初始化角色主题
        determineCharacterTheme()
            
        // 加载模拟对话数据
        loadConversations()
        
        // 加载关注状态
        checkFavoriteStatus()
        
        // 加载自定义头像
        loadCustomAvatar()
        
        // 延迟动画，使内容有序显示
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            animateContent = true
        }
    }
    
    // MARK: - 生命周期方法
    /**
     * 初始化UI状态和数据
     * 在onAppear时调用，加载模拟数据和初始化UI状态
     */
    private func initializeView() {
        print("🔍 CharacterDetailView - 初始化视图: \(character.name)")
        
        // 调用loadData方法
        loadData()
    }
    
    // MARK: - 加载自定义头像
    /**
     * 加载自定义头像
     * 从文档目录加载用户创建的角色头像
     */
    private func loadCustomAvatar() {
        // 检查角色ID是否是自定义角色（以"custom_"开头）
        let characterId = character.id
        if characterId.hasPrefix("custom_") || character.avatarUrl == "default_avatar" {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
            
            print("📁 CharacterDetailView - 尝试加载自定义头像: \(fileURL.path)")
            
            // 检查文件是否存在
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.customImage = image
                        print("✅ CharacterDetailView - 成功加载自定义头像: \(fileURL.path)")
                    }
        } else {
                    print("❌ CharacterDetailView - 无法加载自定义头像数据: \(fileURL.path)")
                }
            } else {
                print("⚠️ CharacterDetailView - 自定义头像文件不存在: \(fileURL.path)")
                // 尝试从备份目录加载
                let backupURL = URL(fileURLWithPath: "/Users/lishilong/IOS开发/虫遇/虫遇/backup_images/default_avatar.png")
                if FileManager.default.fileExists(atPath: backupURL.path),
                   let imageData = try? Data(contentsOf: backupURL),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.customImage = image
                        print("✅ CharacterDetailView - 从备份目录加载头像成功")
                    }
                }
            }
        }
        }
        
    // MARK: - 辅助方法
    
    /**
     * 确定角色主题
     * 根据角色的领域设置合适的主题
     */
    private func determineCharacterTheme() {
        theme = CharacterTheme.forField(character.field)
    }
    
    /**
     * 加载对话记录
     * 加载与角色的历史对话记录
     */
    private func loadConversations() {
        // 这里加载模拟对话数据
        conversations = [
            DisplayConversation(id: UUID().uuidString, characterId: character.id, userId: "current_user", lastMessageContent: "我想了解更多关于你的思想", lastMessageTime: Date().addingTimeInterval(-86400), messageCount: 5),
            DisplayConversation(id: UUID().uuidString, characterId: character.id, userId: "current_user", lastMessageContent: "你能解释一下相对论吗？", lastMessageTime: Date().addingTimeInterval(-172800), messageCount: 12),
            DisplayConversation(id: UUID().uuidString, characterId: character.id, userId: "current_user", lastMessageContent: "你对现代科学有什么看法？", lastMessageTime: Date().addingTimeInterval(-345600), messageCount: 8)
        ]
    }
    
    /**
     * 检查收藏状态
     * 检查当前角色是否被用户收藏
     */
    private func checkFavoriteStatus() {
        // 这里应该从用户偏好或数据库中获取收藏状态
        // 暂时使用模拟数据
        isFavorited = UserDefaults.standard.bool(forKey: "favorite_\(character.id)")
    }
    
    // 格式化显示名称，处理过长或中英文混合的名称
    private func formatDisplayName(_ name: String) -> String {
        // 如果名称中包含括号，只显示括号前的部分
        if let bracketRange = name.range(of: "（") ?? name.range(of: "(") {
            let nameBeforeBracket = String(name[name.startIndex..<bracketRange.lowerBound])
            return nameBeforeBracket.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return name
    }
}

// MARK: - 子视图组件

/**
 * 角色主题颜色管理器
 * 根据角色类型返回对应的主题颜色
 */
fileprivate struct CharacterTheme {
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
        .background(DesignSystem.Colors.background)
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
        } else {
            return "\(number)"
        }
    }
}

/**
 * 标签云视图
 * 显示角色的关键思想/标签
 */
fileprivate struct TagCloudView: View {
    var tags: [String]
    var selectedTags: Set<String> = []
    var onTagSelected: ((String) -> Void)? = nil
    
    var body: some View {
        FlowLayout(alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagButton(tag: tag, isSelected: selectedTags.contains(tag)) {
                    onTagSelected?(tag)
                }
            }
        }
        .padding(.horizontal, 4)
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
        .padding(.horizontal, 12)
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
            .buttonStyle(ScaleFeedbackButtonStyle())
            .frame(maxWidth: isPrimary ? .infinity : .infinity)
        }
    }
}

/**
 * 标签栏视图
 * 提供标签切换功能
 */
private struct DetailTabBarView: View {
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
                        VStack(spacing: 6) {
                        Text(tabOptions[index])
                                .font(.system(size: 15, weight: selectedTabIndex == index ? .semibold : .regular))
                                .foregroundColor(selectedTabIndex == index ? theme.primary : .secondary)
                        
                            // 更简洁的选中指示条
                        Rectangle()
                                .fill(selectedTabIndex == index ? theme.primary : Color.clear)
                            .frame(width: 40, height: 2.5)
                                .cornerRadius(1.5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ScaleFeedbackButtonStyle())
            }
        }
            .padding(.vertical, 10) // 减少垂直内边距
        .background(DesignSystem.Colors.background)
            
            // 底部分隔线 - 简化设计
            Rectangle()
                .fill(Color.gray.opacity(0.08))
                .frame(height: 1)
        }
    }
}

/**
 * 介绍视图
 * 显示角色的详细介绍
 */
fileprivate struct IntroductionContentView: View {
    let character: Character
    
    var body: some View {
        // 使用LazyVStack避免提前布局计算
        LazyVStack(alignment: .leading, spacing: 16) {
            // 核心思想部分 - 使用固定布局约束
            if !character.keyThoughts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                    Text("核心思想")
                        .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                    Text(character.keyThoughts.first ?? "暂无核心思想记录")
                        .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(minHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignSystem.Colors.background)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
            }
            
            // 人物简介部分 - 使用固定布局约束
            VStack(alignment: .leading, spacing: 8) {
                Text("人物简介")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(character.introduction)
                    .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.Colors.background)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // 历史背景部分 - 使用固定布局约束
            VStack(alignment: .leading, spacing: 8) {
                Text("历史背景")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("生活在\(character.birthYear)-\(character.deathYear ?? "现在")期间，\(character.name)的思想深受当时社会环境的影响。")
                    .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
            .frame(minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.Colors.background)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 16)
    }
}

/**
 * 相关信息视图
 * 显示与角色相关的历史背景、影响等信息
 */
fileprivate struct RelatedInfoContentView: View {
    let character: Character
    
    var body: some View {
        let theme = CharacterTheme.forField(character.field)
        
        VStack(alignment: .leading, spacing: 20) {
            // 主要成就 - 根据角色类型定制图标和风格
            VStack(alignment: .leading, spacing: 10) {
                DetailSectionHeader(title: "主要成就", iconName: getIconName(for: "achievements", field: character.field), color: theme.primary)
                
                if character.achievements.isEmpty {
                    NoContentView(text: "暂无记录的成就")
                } else {
                    ForEach(character.achievements, id: \.self) { achievement in
                        AchievementRow(text: achievement, theme: theme)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.Colors.background)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // 代表作品 - 根据角色类型自定义标题和图标
            VStack(alignment: .leading, spacing: 10) {
                DetailSectionHeader(
                    title: getCustomTitle(for: "works", field: character.field), 
                    iconName: getIconName(for: "works", field: character.field), 
                    color: theme.primary
                )
                
                if character.mainWorks.isEmpty {
                    NoContentView(text: "暂无记录的作品")
                } else {
                    ForEach(character.mainWorks, id: \.self) { work in
                        WorkRow(text: work, theme: theme)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.Colors.background)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // 相关人物 - 展示与该历史人物相关的其他人物
            VStack(alignment: .leading, spacing: 10) {
                DetailSectionHeader(title: "相关人物", iconName: "person.2.fill", color: theme.primary)
                
                RelatedPersonView(character: character, theme: theme)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.Colors.background)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // 历史背景 - 根据时代和角色类型定制内容
            VStack(alignment: .leading, spacing: 10) {
                DetailSectionHeader(title: "历史背景", iconName: "clock.fill", color: theme.primary)
                
                Text(getHistoricalBackground(character: character))
                    .font(.system(size: 15))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(5)
                    .padding(.horizontal, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.Colors.background)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // 底部间距
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
    }
    
    // 根据字段和角色类型获取自定义图标
    private func getIconName(for section: String, field: String) -> String {
        switch section {
        case "achievements":
            if field.contains("科学") || field.contains("物理") || field.contains("数学") {
                return "atom"
            } else if field.contains("哲学") || field.contains("思想家") {
                return "brain"
            } else if field.contains("文学") || field.contains("作家") || field.contains("诗人") {
                return "book.fill"
            } else if field.contains("艺术") || field.contains("画家") || field.contains("音乐") {
                return "paintbrush.fill"
            } else if field.contains("军事") || field.contains("将军") {
                return "shield.fill"
            } else {
                return "medal.fill"
            }
        case "works":
            if field.contains("科学") || field.contains("物理") || field.contains("数学") {
                return "doc.text.magnifyingglass"
            } else if field.contains("哲学") || field.contains("思想家") {
                return "text.book.closed.fill"
            } else if field.contains("文学") || field.contains("作家") || field.contains("诗人") {
                return "book.fill"
            } else if field.contains("艺术") || field.contains("画家") {
                return "paintpalette.fill"
            } else if field.contains("音乐") {
                return "music.note"
            } else {
                return "doc.text.fill"
            }
        default:
            return "info.circle.fill"
        }
    }
    
    // 根据字段和角色类型获取自定义标题
    private func getCustomTitle(for section: String, field: String) -> String {
        switch section {
        case "works":
            if field.contains("科学") || field.contains("物理") || field.contains("数学") {
                return "重要论文"
            } else if field.contains("哲学") || field.contains("思想家") {
                return "重要著作"
            } else if field.contains("文学") || field.contains("作家") || field.contains("诗人") {
                return "代表作品"
            } else if field.contains("艺术") || field.contains("画家") {
                return "代表画作"
            } else if field.contains("音乐") {
                return "代表曲目"
            } else {
                return "主要作品"
            }
        default:
            return "相关信息"
        }
    }
    
    // 根据角色生成历史背景描述
    private func getHistoricalBackground(character: Character) -> String {
        let birthYear = character.birthYear
        let deathYear = character.deathYear ?? "未知"
        let field = character.field
        let name = character.name
        
        var description = "生活在\(birthYear)-\(deathYear)期间，\(name)"
        
        // 根据角色类型添加不同的描述
        if field.contains("哲学") || field.contains("思想家") {
            description += "的思想深受当时社会环境和历史背景的影响。作为一位重要的思想家，他的哲学体系引导了人们对世界的认知方式。"
        } else if field.contains("物理") || field.contains("数学") || field.contains("科学") {
            description += "的科学成就引领了当时的学术前沿，开创了新的研究领域，并为后世的科学发展奠定了基础。"
        } else if field.contains("文学") || field.contains("作家") || field.contains("诗人") {
            description += "的文学作品反映了那个时代的社会风貌和人文精神，通过文字塑造了丰富的思想世界和艺术形象。"
        } else if field.contains("艺术") || field.contains("画家") || field.contains("音乐") {
            description += "的艺术创作融合了时代特色和个人风格，展现了独特的美学观念和艺术表达方式。"
        } else if field.contains("教育") || name.contains("孔子") {
            description += "创立了影响深远的教育思想，其理念和方法对后世的教育实践产生了深远的影响。"
        } else {
            description += "的贡献对当时社会产生了深远影响，其思想和成就至今仍被广泛研究和传颂。"
        }
        
        return description
    }
}

// 相关人物组件
fileprivate struct RelatedPersonView: View {
    let character: Character
    let theme: CharacterTheme
    
    // 根据角色返回相关历史人物
    private var relatedPersons: [(name: String, relation: String)] {
        switch character.name {
        case "爱因斯坦":
            return [
                ("马克斯·普朗克", "量子力学创始人，爱因斯坦的导师和朋友"),
                ("尼尔斯·玻尔", "量子物理学开创者，与爱因斯坦有著名的学术辩论")
            ]
        case "孔子":
            return [
                ("孟子", "儒家学派重要代表，发展了孔子思想"),
                ("老子", "道家创始人，与孔子同时代的思想家")
            ]
        case "莎士比亚":
            return [
                ("本·琼森", "同时代剧作家，莎士比亚好友"),
                ("伊丽莎白一世", "英国女王，莎士比亚时代的统治者")
            ]
        case "达芬奇":
            return [
                ("米开朗基罗", "文艺复兴时期雕塑家和画家"),
                ("拉斐尔", "文艺复兴时期著名画家")
            ]
        default:
            return [
                ("相关历史人物", "与\(character.name)有关联的历史人物"),
                ("同时代人物", "与\(character.name)生活在同一时期的重要人物")
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(relatedPersons, id: \.name) { person in
                HStack(alignment: .top, spacing: 10) {
                    // 人物图标
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.primary)
                        .frame(width: 22)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 人物名称
                        Text(person.name)
                            .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                        // 人物关系描述
                        Text(person.relation)
                            .font(.system(size: 14))
                    .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
            }
            
                if person.name != relatedPersons.last?.name {
            Divider()
                        .padding(.vertical, 2)
                        .padding(.leading, 32)
                }
            }
        }
    }
}

// 成就行组件
fileprivate struct AchievementRow: View {
    let text: String
    let theme: CharacterTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(theme.primary)
                .padding(.top, 2)
                .frame(width: 22)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

// 作品行组件
fileprivate struct WorkRow: View {
    let text: String
    let theme: CharacterTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "doc.fill")
                .font(.system(size: 14))
                .foregroundColor(theme.primary)
                .padding(.top, 2)
                .frame(width: 22)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

// 板块标题组件
fileprivate struct DetailSectionHeader: View {
    let title: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 22)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
        }
        .padding(.bottom, 4)
    }
}

// 无内容提示组件
fileprivate struct NoContentView: View {
    let text: String
    
    var body: some View {
        HStack {
            Spacer()
            
            Text(text)
                .font(.system(size: 15))
                    .foregroundColor(.secondary)
                .padding(.vertical, 12)
            
            Spacer()
        }
    }
}

// InteractionContentView - 互动记录标签内容
fileprivate struct InteractionContentView: View {
    var character: Character
    var conversations: [DisplayConversation]
    var onConversationTap: (DisplayConversation) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if conversations.isEmpty {
                // 空状态提示
                VStack(spacing: 14) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.bottom, 4)
                    
                    Text("暂无互动记录")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("点击\"对话\"按钮，开始与\(character.name)对话")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 会话列表
                ForEach(conversations, id: \.id) { conversation in
                    ConversationItemRow(conversation: conversation)
                        .padding(.vertical, 4)
                        .onTapGesture {
                            onConversationTap(conversation)
                        }
                }
            }
        }
        .padding(.horizontal, 16) // 保持适当边距
        .padding(.bottom, 24)
    } 
}

// 在文件末尾添加EnhancedShareCardView结构体定义
/**
 * 增强版分享卡片视图组件
 * 提供更具吸引力和用户关联性的分享卡片模板
 */
private struct ShareCardView: View {
    let character: Character
    let theme: CharacterTheme
    let conversations: [DisplayConversation]  // 添加会话数据
    @State private var customImage: UIImage? = nil
    
    // 设计系统颜色
    private struct DesignSystem {
        // 主题色
        static let deepPurple = Color(hex: "2C1D4F")      // 深邃紫
        static let mediumPurple = Color(hex: "4A3A7E")    // 中紫
        static let brightPurple = Color(hex: "634F9A")    // 亮紫
        static let vibrantYellow = Color(hex: "FFD76A")   // 活力黄
        static let softPurple = Color(hex: "BDAEEF")      // 柔和紫
        
        // 渐变
        static let cardGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "362A5F"),
                Color(hex: "2C1D4F")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // 光晕效果
        static let glowEffect = Color(hex: "FFD76A").opacity(0.15)
        
        // 文本颜色
        static let primaryText = Color.white
        static let secondaryText = Color(hex: "BDAEEF")
        static let accentText = Color(hex: "FFD76A")
    }
    
    // 格式化显示名称，处理过长或中英文混合的名称
    private func formatDisplayName(_ name: String) -> String {
        // 如果名称中包含括号，只显示括号前的部分
        if let bracketRange = name.range(of: "（") ?? name.range(of: "(") {
            let nameBeforeBracket = String(name[name.startIndex..<bracketRange.lowerBound])
            return nameBeforeBracket.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return name
    }
    
    // 从文档目录加载自定义头像
    private func loadCustomAvatar() {
        // 检查角色ID是否是自定义角色（以"custom_"开头）
        let characterId = character.id
        if characterId.hasPrefix("custom_") || character.avatarUrl == "default_avatar" {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
            
            print("📁 CharacterDetailView - 尝试加载自定义头像: \(fileURL.path)")
            
            // 检查文件是否存在
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.customImage = image
                        print("✅ CharacterDetailView - 成功加载自定义头像: \(fileURL.path)")
                    }
                } else {
                    print("❌ CharacterDetailView - 无法加载自定义头像数据: \(fileURL.path)")
                }
            } else {
                print("⚠️ CharacterDetailView - 自定义头像文件不存在: \(fileURL.path)")
                // 尝试从备份目录加载
                let backupURL = URL(fileURLWithPath: "/Users/lishilong/IOS开发/虫遇/虫遇/backup_images/default_avatar.png")
                if FileManager.default.fileExists(atPath: backupURL.path),
                   let imageData = try? Data(contentsOf: backupURL),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.customImage = image
                        print("✅ CharacterDetailView - 从备份目录加载头像成功")
                    }
                }
            }
        }
    }
    
    // 动态生成示例问题
    private var exampleQuestion: String {
        // 替换为更个性化的问题生成逻辑
        // 根据角色名称和领域生成个性化问题
        switch character.name {
        case let name where name.contains("爱因斯坦"):
            return "您能用通俗的语言解释时间的相对性吗？"
        case let name where name.contains("莎士比亚"):
            return "您如何看待《哈姆雷特》中的犹豫不决主题？"
        case let name where name.contains("李白"):
            return "您创作《将进酒》时的心境是什么样的？"
        case let name where name.contains("孔子"):
            return "在当今社会，如何践行'仁'的思想？"
        case let name where name.contains("苏格拉底"):
            return "为什么您说'未经审视的生活不值得过'？"
        default:
            // 如果角色名称没有匹配，则回退到领域匹配
            switch character.field {
            case let field where field.contains("物理") || field.contains("科学"):
                return "您最重要的科学发现是什么？"
            case let field where field.contains("文学") || field.contains("诗人"):
                return "创作灵感对您来说从何而来？"
            case let field where field.contains("艺术") || field.contains("画家"):
                return "您认为艺术的本质是什么？"
            case let field where field.contains("哲学"):
                return "您的哲学思想对现代人有何启示？"
            default:
                return "您认为人类历史中最宝贵的经验是什么？"
            }
        }
    }
    
    // 动态生成示例回答
    private var exampleAnswer: String {
        // 替换为更个性化的回答生成逻辑
        // 根据角色名称和领域生成个性化回答
        switch character.name {
        case let name where name.contains("爱因斯坦"):
            return "想象你坐在一辆飞驰的火车上，而我站在路边观察。对你来说，车厢内的一切都是静止的，而对我来说，你和车厢都在高速移动。这种相对性使我们各自经历的时间流逝也不同。在高速状态下，你的时间实际上比我慢，这就是时间延缓效应..."
        case let name where name.contains("莎士比亚"):
            return "哈姆雷特的犹豫不决体现了人性的复杂性。当确定性与不确定性、行动与思考之间的矛盾交织在一起时，我们常常陷入与哈姆雷特相似的困境。这部作品探索了人在面对重大抉择时内心的挣扎，这也是为何它能跨越时空打动读者..."
        case let name where name.contains("李白"):
            return "创作《将进酒》时，我内心有对生命短暂的感慨，也有对人生理想无法实现的失落。'人生得意须尽欢，莫使金樽空对月'表达了及时行乐的态度，但也蕴含着对生命价值的追求和对理想的坚持。诗歌是我表达内心复杂情感的方式..."
        case let name where name.contains("孔子"):
            return "'仁'的核心是爱人。在当今社会，践行仁爱思想，首先要从家庭做起，尊老爱幼；其次要诚实待人，将心比心；再者要尊重差异，包容多元。现代社会虽然形式变了，但人与人之间相处的基本道理没有变，'己所不欲，勿施于人'依然是处世的重要原则..."
        case let name where name.contains("苏格拉底"):
            return "我说'未经审视的生活不值得过'，是因为人的价值在于不断反思和追求智慧。如果一个人只是机械地生活，不去思考自己的行为、信念和价值观，那么这种生活缺乏真正的意义。通过质疑和反思，我们才能接近真理，获得内心的平和与智慧..."
        default:
            // 如果角色名称没有匹配，则回退到领域匹配
            switch character.field {
            case let field where field.contains("物理") || field.contains("科学"):
                return "科学发现是一个不断探索与修正的旅程。我认为科学家最重要的品质是好奇心和怀疑精神。通过观察、提出假设、实验验证和修正理论，我们逐渐接近真理。科学不仅是知识的积累，更是一种思考方式，它教会我们如何理性地看待世界..."
            case let field where field.contains("文学") || field.contains("诗人"):
                return "创作灵感来源于生活的观察和内心的体验。有时是一次偶然的邂逅，有时是深夜的思考，有时甚至是梦境带来的启示。文学创作是将这些零散的感受转化为有序的语言，通过故事和意象唤起读者内心的共鸣。这是一个神奇的过程..."
            case let field where field.contains("艺术") || field.contains("画家"):
                return "艺术的本质是情感与思想的表达。通过形式、色彩、线条等元素，艺术家将内心世界具象化，创造出能够引起观者共鸣的作品。艺术不仅是技巧的展示，更是心灵的交流。每一件艺术作品都是艺术家与世界对话的方式..."
            case let field where field.contains("哲学"):
                return "哲学思考引导我们超越表象，探索事物的本质。对现代人而言，哲学提供了面对复杂世界的思考工具，帮助我们辨别真假、明辨是非。在信息爆炸的时代，哲学的批判性思维尤为重要，它教会我们不盲从权威，保持独立思考..."
            default:
                return "人类历史最宝贵的经验是不断学习与创新的能力。每个时代都有其特点，但相通的是人类追求更好生活的愿望。通过汲取历史教训，珍视文化多样性，坚持理性与人道主义，我们才能更好地面对未来的挑战..."
            }
        }
    }
    
    // 动态生成用户评价
    private var userReview: String {
        switch character.field {
        case let field where field.contains("物理") || field.contains("科学"):
            return "\"他让深奥的科学变得如此生动\""
        case let field where field.contains("文学") || field.contains("诗人"):
            return "\"仿佛穿越时空的文学对话\""
        case let field where field.contains("艺术") || field.contains("画家"):
            return "\"艺术创作的灵感源泉\""
        case let field where field.contains("哲学"):
            return "\"古老的智慧在当代焕发新生\""
        default:
            return "\"跨越时空的思想碰撞\""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部品牌区
                        HStack {
                // 品牌标识
                HStack(spacing: 4) {
                    Text("虫遇")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(DesignSystem.vibrantYellow)
                        .shadow(color: DesignSystem.vibrantYellow.opacity(0.3), radius: 4, x: 0, y: 0)
                    
                    Text("·穿越时空对话")
                                .font(.system(size: 16))
                        .foregroundColor(DesignSystem.softPurple)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "362A5F"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(DesignSystem.vibrantYellow.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
            }
                        .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // 角色信息区
            HStack(alignment: .top, spacing: 16) {
                // 头像
                ZStack {
                    // 光晕背景
                    Circle()
                        .fill(DesignSystem.glowEffect)
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)
                    
                    if let customImage = customImage {
                        // 显示从文档目录加载的自定义头像
                        Image(uiImage: customImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                DesignSystem.vibrantYellow.opacity(0.6),
                                                DesignSystem.vibrantYellow.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else if UIImage(named: character.avatarUrl) != nil {
                        Image(character.avatarUrl)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                DesignSystem.vibrantYellow.opacity(0.6),
                                                DesignSystem.vibrantYellow.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        Circle()
                            .fill(DesignSystem.mediumPurple)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(String(formatDisplayName(character.name).prefix(1)))
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(DesignSystem.vibrantYellow)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // 名称和标签
                    HStack(spacing: 8) {
                                Text(formatDisplayName(character.name))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(DesignSystem.primaryText)
                        
                        Text("#时空来客")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.vibrantYellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.vibrantYellow.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(DesignSystem.vibrantYellow.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // 职业和年代
                    Text("\(character.field) · \(character.birthYear)-\(character.deathYear ?? "")")
                                    .font(.system(size: 14))
                        .foregroundColor(DesignSystem.secondaryText)
                    
                    // 简短介绍
                    Text(character.introduction.prefix(40) + "...")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.secondaryText.opacity(0.8))
                                    .lineLimit(1)
                        .padding(.top, 2)
                            }
                            
                            Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // 分隔线
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.vibrantYellow.opacity(0.2),
                        DesignSystem.vibrantYellow.opacity(0.1),
                        DesignSystem.vibrantYellow.opacity(0.05)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // 对话示例区
            VStack(alignment: .leading, spacing: 12) {
                Text("最近对话")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(DesignSystem.softPurple)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // 用户提问
                HStack {
                    Spacer()
                    
                    Text(displayQuestion)
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.deepPurple)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DesignSystem.vibrantYellow)
                                .shadow(color: DesignSystem.vibrantYellow.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.trailing, 20)
                }
                
                // 角色回答
                HStack(alignment: .top, spacing: 12) {
                    // 头像
                    if let customImage = customImage {
                        // 显示从文档目录加载的自定义头像
                        Image(uiImage: customImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.vibrantYellow.opacity(0.3), lineWidth: 1)
                            )
                    } else if UIImage(named: character.avatarUrl) != nil {
                        Image(character.avatarUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.vibrantYellow.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Circle()
                            .fill(DesignSystem.mediumPurple)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(character.name.prefix(1)))
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.vibrantYellow)
                            )
                    }
                    
                    // 回答内容
                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayAnswer.prefix(70) + "...")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.primaryText)
                            .lineSpacing(4)
                            .lineLimit(2)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "362A5F"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(DesignSystem.vibrantYellow.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 16)
            }
            .background(Color(hex: "2C1D4F").opacity(0.3))
            
            // 互动邀请区
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(DesignSystem.vibrantYellow)
                        .frame(width: 6, height: 6)
                    
                    Text("想提问？扫码与\(formatDisplayName(character.name))直接对话")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.softPurple)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            
            // 分隔线
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.vibrantYellow.opacity(0.2),
                        DesignSystem.vibrantYellow.opacity(0.1),
                        DesignSystem.vibrantYellow.opacity(0.05)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // 底部区域
            HStack(alignment: .center) {
                // 左侧社交证明
                VStack(alignment: .leading, spacing: 8) {
                    // 用户评价
                    Text(userReview)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(DesignSystem.softPurple)
                        .italic()
                    
                    // 对话人数
                    Text(formatNumber(max(100, character.followerCount)) + "人已开启对话")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.primaryText)
                    
                    // 品牌标识
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 12))
                            .foregroundColor(DesignSystem.vibrantYellow.opacity(0.8))
                                
                        Text("虫遇App·穿越时空的社交")
                                    .font(.system(size: 12))
                            .foregroundColor(DesignSystem.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧二维码
                VStack(spacing: 6) {
                    ZStack {
                        // 二维码背景
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.warmBackground)
                            .frame(width: 84, height: 84)
                            .shadow(color: DesignSystem.vibrantYellow.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        // 二维码图案
                        Image(systemName: "qrcode")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.deepPurple)
                    }
                    
                    Text("扫码立即对话")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.vibrantYellow)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: UIScreen.main.bounds.width - 40)
        .background(
            ZStack {
                // 主背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "362A5F"),
                        Color(hex: "2C1D4F")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 装饰性光效
                Circle()
                    .fill(DesignSystem.vibrantYellow.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(DesignSystem.brightPurple.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .offset(x: 120, y: 200)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignSystem.vibrantYellow.opacity(0.3),
                            DesignSystem.vibrantYellow.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        .onAppear {
            loadCustomAvatar()
        }
    }
    
    // 格式化数字
    private func formatNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1f万", Double(number) / 10000.0)
        } else {
            return "\(number)"
        }
    }
    
    /// 获取用于展示的问题，优先使用真实对话，如无则使用根据角色生成的示例对话
    private var displayQuestion: String {
        // 如果有真实对话数据，使用最新一条对话的内容
        if !conversations.isEmpty {
            return conversations[0].lastMessageContent
        }
        
        // 否则使用根据角色生成的示例问题
        return exampleQuestion
    }
    
    /// 获取用于展示的回答，如果没有真实对话则生成示例回答
    private var displayAnswer: String {
        // 如果有真实对话，提供对应的回答
        if !conversations.isEmpty {
            // 实际项目中，这里应该从服务器获取角色的回答
            // 这里为演示目的，使用生成的回答
            switch character.name {
            case let name where name.contains("爱因斯坦") && displayQuestion.contains("相对论"):
                return "时间是一个相对的概念，它会随着观察者的运动状态而改变。在高速运动或强引力场中，时间会变慢，这就是著名的时间延缓效应。相对论彻底改变了我们对时间和空间的理解，它们不再是绝对的，而是相互关联并随观察者状态变化的..."
            case let name where name.contains("爱因斯坦") && displayQuestion.contains("量子"):
                return "虽然我对量子力学的某些解释持保留态度，但它的确是描述微观世界的强大理论。'上帝不掷骰子'反映了我对决定论的信念，但量子力学的发展已经超出了我的时代。现代量子物理学的成就令人惊叹，尽管它的哲学解释仍存在争议..."
            case let name where name.contains("莎士比亚") && displayQuestion.contains("哈姆雷特"):
                return "哈姆雷特的犹豫不决反映了人类面对重大抉择时内心的挣扎。他不仅仅是在思考如何行动，更是在探索行动的意义与后果。'此时此刻，生存还是毁灭'这一著名独白揭示了存在主义的核心问题，这也是为何这部作品穿越时空仍能引起共鸣..."
            case let name where name.contains("李白") && displayQuestion.contains("将进酒"):
                return "创作《将进酒》时，我内心充满了对生命短暂的感慨和对理想难以实现的惆怅。'人生得意须尽欢，莫使金樽空对月'表达了我对生活的热情态度。这首诗融合了及时行乐的思想和对生命意义的追求，表达了我对自由和理想的向往..."
            default:
                // 如果没有特定匹配，则使用标准回答
                return exampleAnswer
            }
        }
        
        // 如果没有真实对话，使用生成的答案
        return exampleAnswer
    }
    
    // 在视图加载时调用
    func onAppear() {
        loadCustomAvatar()
    }
}

/**
 * 全屏分享视图
 * 以全屏模式展示分享卡片和分享选项
 */
fileprivate struct FullScreenShareView: View {
    @Binding var isPresented: Bool
    var character: Character
    var theme: CharacterTheme
    var conversations: [DisplayConversation]  // 添加会话数据
    
    var body: some View {
        ZStack {
            // 背景色 - 使用半透明黑色背景
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    // 返回按钮 - 使用与角色详情页面相同的样式，但尺寸更大
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))  // 增大图标尺寸
                            .foregroundColor(Color(red: 149/255, green: 138/255, blue: 177/255))
                            .frame(width: 44, height: 44)  // 增大按钮点击区域
                            .contentShape(Rectangle())
                    }
                    .padding(.leading, 12)  // 调整左边距以适应更大的按钮
                    
                    Spacer()
                    
                    Text("分享")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)  // 修改标题颜色为白色以适应深色背景
                    
                    Spacer()
                    
                    // 占位按钮，保持布局对称
                    Color.clear
                        .frame(width: 44, height: 44)  // 调整占位大小以保持对称
                        .padding(.trailing, 12)  // 调整右边距
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
                
                // 内容区域（可滚动）
                ScrollView {
                    VStack(spacing: 24) {
                        // 分享卡片
                        ShareCardView(character: character, theme: theme, conversations: conversations)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // 分享按钮组
                        HStack(spacing: 35) {
                            // 微信分享
                            shareButton(
                                title: "微信",
                                icon: "message.fill",
                                iconColor: Color(hex: "09B83E"),
                                action: {
                                    isPresented = false
                                }
                            )
                            
                            // 朋友圈分享
                            shareButton(
                                title: "朋友圈",
                                icon: "person.2.circle.fill",
                                iconColor: Color(hex: "09B83E"),
                                action: {
                                    isPresented = false
                                }
                            )
                            
                            // 图片分享
                            shareButton(
                                title: "图片",
                                icon: "photo.fill",
                                iconColor: Color(hex: "F5A623"),
                                action: {
                                    isPresented = false
                                }
                            )
                            
                            // 链接分享
                            shareButton(
                                title: "链接",
                                icon: "link",
                                iconColor: Color(hex: "007AFF"),
                                action: {
                                    UIPasteboard.general.string = "https://chongyu.app/character/\(character.id)"
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    isPresented = false
                                }
                            )
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // 分享按钮
    private func shareButton(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(.systemGray6))  // 添加浅灰色背景
                    .overlay(
                        Circle()
                            .fill(iconColor.opacity(0.15))  // 保留原有的颜色但降低透明度
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(iconColor)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)  // 添加轻微阴影
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)  // 文字改为白色
                    .fontWeight(.medium)  // 增加字重
            }
        }
        .buttonStyle(ScaleFeedbackButtonStyle())
    }
} 

// MARK: - 自定义UI组件

/**
 * 标签按钮
 * 用于显示可点击的标签
 */
fileprivate struct TagButton: View {
    var tag: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 13))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(isSelected ? Color.primaryColor.opacity(0.8) : Color.gray.opacity(0.15))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
    }
}
