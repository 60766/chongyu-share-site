import SwiftUI
import SwiftData
// CreateCharacterView位于：Views/Components/Character/CreateCharacterView.swift
import Foundation

// 导入自定义组件
// @_exported import struct 虫遇.ImprovedCharacterCardView
// @_exported import struct 虫遇.RecommendedCharactersView

/**
 * 角色探索页面
 * 用于浏览和筛选所有历史人物
 */
struct ExploreView: View {
    /// 搜索文本
    @State private var searchText = ""
    /// 选中的分类
    @State private var selectedCategory: CharacterCategory = .all
    /// 历史人物数据
    @State private var characters: [CharacterModel] = []
    /// 滚动偏移量
    @State private var scrollOffset: CGFloat = 0
    /// 选中的时间轴时期
    @State private var selectedEra: String? = nil
    /// 是否显示创建角色视图
    @State private var showingCreateCharacter = false
    @State private var showingMultiPersonChatSetup = false // 新增状态
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 选项卡类型
    enum TabType: String, CaseIterable {
        case all = "全部"
        case popular = "热门"
        case manage = "管理" // 将"最近"改为"管理"
    }
    
    // 当前选中的选项卡
    @State private var selectedTab: TabType = .all
    
    // 标签动画命名空间
    @Namespace private var tabAnimation
    
    // 是否显示最近互动角色
    @State private var showingRecentInteractions: Bool = false
    
    // 是否显示我的关注角色
    @State private var showingFavorites: Bool = false
    
    // 是否处于角色管理模式
    @State private var isManagingCharacters: Bool = false
    
    // 添加确认删除对话框状态
    @State private var showingDeleteConfirmation: Bool = false
    @State private var characterToDelete: CharacterModel? = nil
    
    // 添加确认隐藏对话框状态
    @State private var showingHideConfirmation: Bool = false
    @State private var characterToHide: CharacterModel? = nil
    
    // 被隐藏的预设角色IDs
    @State private var hiddenCharacters: [String] = []
    
    // 置顶角色的IDs
    @State private var pinnedCharacters: [String] = []
    
    // 我的关注角色列表
    // 使用统一的关注管理器
    @StateObject private var followManager = FollowManager.shared
    
    // 时间轴数据
    private let timeEras = [
        "古代", "中世纪", "文艺复兴", "启蒙运动", "工业革命", "现代", "当代"
    ]
    
    // 定义三列网格布局 - 修改为固定尺寸
    private let threeColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // 导航状态
    @State private var navigateToCharacterDetail: CharacterModel? = nil
    @State private var navigateToChatView: CharacterModel? = nil
    
    // 最近互动相关状态
    @State private var recentInteractions: [CharacterInteraction] = []
    private let maxRecentInteractions = 20 // 最近互动数量限制
    
    // 用户交互记录结构
    struct CharacterInteraction: Identifiable, Codable {
        var id: UUID
        let characterId: String
        let characterName: String
        let interactionType: InteractionType
        let timestamp: Date
        
        init(characterId: String, characterName: String, interactionType: InteractionType, timestamp: Date) {
            self.id = UUID()
            self.characterId = characterId
            self.characterName = characterName
            self.interactionType = interactionType
            self.timestamp = timestamp
        }
        
        enum InteractionType: String, Codable, CaseIterable {
            case like = "点赞"
            case comment = "评论"
            case chat = "聊天"
        }
    }

    // 添加新的状态变量
    @State private var showingUserCharacters: Bool = false
    @State private var userCharacters: [CharacterModel] = []

    var body: some View {
        ZStack(alignment: .top) {
            // 背景色 - 使用与主页面一致的温暖米白色背景
            DesignSystem.Colors.background
                .ignoresSafeArea(.all) // 忽略所有安全区域，包括顶部，避免白色背景遮盖
            
            // 主内容区
            VStack(spacing: 0) {
                // 顶部区域：搜索栏
                VStack(spacing: 0) {
                    // 搜索栏 - 优化视觉层次感
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.leading, 8)
                            
                            TextField("搜索时空旅行者...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 8)
                        .background(Color(hex: "FAFAFA"))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 14)
                }
                .background(Color.clear) // 移除白色背景，改为透明背景
                .shadow(color: Color.black.opacity(scrollOffset > 20 ? 0.05 : 0), radius: 6, x: 0, y: 3)
                .zIndex(1)
                
                // 内容区
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) { // 调整整体间距为16pt
                            // 搜索框下方添加两个主要按钮 - 优化设计使其更突出
                            HStack(spacing: 12) { // 调整按钮之间的间距为12pt
                                // 梦幻联动按钮 - 精致化设计
                                Button(action: {
                                    // 处理梦幻联动功能
                                    showingMultiPersonChatSetup = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(red: 160/255, green: 130/255, blue: 250/255))
                                        
                                        Text("梦幻联动")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 160/255, green: 130/255, blue: 250/255).opacity(0.08),
                                                Color(red: 140/255, green: 110/255, blue: 230/255).opacity(0.06)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color(red: 160/255, green: 130/255, blue: 250/255).opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 创建角色按钮 - 精致化设计
                                Button(action: {
                                    // 显示创建角色功能
                                    showingCreateCharacter = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color(red: 70/255, green: 145/255, blue: 255/255))
                                        
                                        Text("创建角色")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 70/255, green: 145/255, blue: 255/255).opacity(0.08),
                                                Color(red: 50/255, green: 125/255, blue: 235/255).opacity(0.06)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color(red: 70/255, green: 145/255, blue: 255/255).opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4) // 进一步减小顶部间距
                            .padding(.bottom, 4) // 进一步减小底部间距
                            
                            // 分类筛选
                            VStack(alignment: .leading, spacing: 6) { // 进一步减小分类区域内部间距
                                // 第一排显示个人相关按钮和前几个分类
                                    HStack(spacing: 20) {
                                        // 最近互动按钮
                                        Button(action: {
                                            handleRecentInteractionsTap()
                                        }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                    .fill(Color(red: 185/255, green: 145/255, blue: 235/255).opacity(showingRecentInteractions ? 0.9 : 0.15))
                                                        .frame(width: 56, height: 56)
                                                    
                                                    Image(systemName: "clock.badge.checkmark")
                                                        .font(.system(size: 22))
                                                    .foregroundColor(showingRecentInteractions ? .white : Color(red: 185/255, green: 145/255, blue: 235/255))
                                                }
                                                .shadow(
                                                color: Color(red: 185/255, green: 145/255, blue: 235/255).opacity(showingRecentInteractions ? 0.2 : 0), 
                                                radius: 5,
                                                    x: 0,
                                                y: 2
                                                )
                                                
                                                Text("最近互动")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(showingRecentInteractions ? .primary : Color(.secondaryLabel))
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                            }
                                        }
                                        
                                    // 我的关注按钮 (交换位置)
                                        Button(action: {
                                        handleFavoritesTap()
                                        }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                    .fill(Color(red: 214/255, green: 114/255, blue: 114/255).opacity(showingFavorites ? 0.9 : 0.15))
                                                        .frame(width: 56, height: 56)
                                                    
                                                Image(systemName: "heart.fill")
                                                        .font(.system(size: 22))
                                                    .foregroundColor(showingFavorites ? .white : Color(red: 214/255, green: 114/255, blue: 114/255))
                                                }
                                                .shadow(
                                                color: Color(red: 214/255, green: 114/255, blue: 114/255).opacity(showingFavorites ? 0.2 : 0), 
                                                radius: 5,
                                                    x: 0,
                                                y: 2
                                                )
                                                
                                            Text("我的关注")
                                                    .font(.system(size: 11))
                                                .foregroundColor(showingFavorites ? .primary : Color(.secondaryLabel))
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                            }
                                        }
                                        
                                    // 显示热门分类按钮（固定在第一排）
                                    // 第一排：最近互动 | 我的关注 | 动漫角色 | 历史人物 | 影视角色
                                    let firstRowCategories: [CharacterCategory] = [.animeCharacter, .historical, .filmCharacter]
                                    ForEach(firstRowCategories, id: \.self) { category in
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                // 设置选中的分类
                                                selectedCategory = category
                                                
                                                // 重置特殊显示模式，确保包括我的角色模式
                                                showingRecentInteractions = false
                                                showingFavorites = false
                                                showingUserCharacters = false
                                                
                                                // 打印调试信息
                                                print("选中分类: \(category.displayName)")
                                            }
                                        }) {
                                            categoryView(for: category)
                                        }
                                    }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 2) // 减小顶部内边距
                                }
                                
                                // 第二排分类按钮 - 显示中低频分类和我的角色
                                // 第二排：游戏角色 | 文学世界 | 哲学家 | 神话角色 | 我的角色
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                    // 显示第二排的分类按钮（按推荐顺序）
                                    let secondRowCategories: [CharacterCategory] = [.gameCharacter, .writer, .philosopher, .mythCharacter]
                                    ForEach(secondRowCategories, id: \.self) { category in
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                // 设置选中的分类
                                                selectedCategory = category
                                                
                                                // 重置特殊显示模式，确保包括我的角色模式
                                                showingRecentInteractions = false
                                                showingFavorites = false
                                                showingUserCharacters = false
                                                
                                                // 打印调试信息
                                                print("选中分类: \(category.displayName)")
                                            }
                                        }) {
                                            categoryView(for: category)
                                        }
                                    }
                                    
                                    // 我的角色按钮（放在第二排末尾）
                                    Button(action: {
                                        handleUserCharactersTap()
                                    }) {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                .fill(Color(red: 95/255, green: 158/255, blue: 225/255).opacity(showingUserCharacters ? 0.9 : 0.15))
                                                    .frame(width: 56, height: 56)
                                                
                                            Image(systemName: "person.crop.circle")
                                                    .font(.system(size: 22))
                                                .foregroundColor(showingUserCharacters ? .white : Color(red: 95/255, green: 158/255, blue: 225/255))
                                            }
                                            .shadow(
                                            color: Color(red: 95/255, green: 158/255, blue: 225/255).opacity(showingUserCharacters ? 0.2 : 0), 
                                            radius: 5,
                                                x: 0,
                                            y: 2
                                            )
                                            
                                        Text("我的角色")
                                                .font(.system(size: 11))
                                            .foregroundColor(showingUserCharacters ? .primary : Color(.secondaryLabel))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                    }
                                    }
                                    .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 2) // 进一步减小分类区域整体间距
                            
                            // 视觉分隔线 - 位于选项卡上方
                            Rectangle()
                                .fill(Color(.systemGray5).opacity(0.7))
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                            
                            // 优化的底部标签栏 - 添加流畅动画
                            HStack(spacing: 0) {
                                ForEach([TabType.all, .popular, .manage], id: \.self) { tab in
                                    Button(action: {
                                        // 防止重复点击同一标签
                                        guard selectedTab != tab else { return }
                                        
                                        // 使用简单平滑的动画
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.selectedTab = tab
                                            
                                            // 如果点击"管理"标签，则切换管理模式
                                            if tab == .manage {
                                                // 直接切换管理模式，不改变当前分类
                                                isManagingCharacters.toggle()
                                            } else {
                                                // 退出管理模式
                                                isManagingCharacters = false
                                            }
                                        }
                                    }) {
                                        ZStack {
                                             // 温暖和谐的背景圆角矩形
                                             if selectedTab == tab {
                                                 RoundedRectangle(cornerRadius: 12)
                                                     .fill(
                                                         LinearGradient(
                                                             gradient: Gradient(colors: [
                                                                 DesignSystem.Colors.primary.opacity(0.12),
                                                                 DesignSystem.Colors.primary.opacity(0.08)
                                                             ]),
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing
                                                         )
                                                     )
                                                     .overlay(
                                                         RoundedRectangle(cornerRadius: 12)
                                                             .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 0.5)
                                                     )
                                                     .frame(height: 30)
                                                     .matchedGeometryEffect(id: "selectedBackground", in: tabAnimation)
                                             }
                                             
                                             // 文本标签 - 温暖和谐的颜色搭配
                                             Text(tab.rawValue)
                                                 .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                                                 .foregroundColor(selectedTab == tab ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                                                .padding(.horizontal, 12)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .contentShape(Rectangle()) // 确保整个区域可点击
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            
                            // 稳定的内容区域 - 移除闪动效果
                            VStack(alignment: .leading, spacing: 0) {
                                if showingRecentInteractions {
                                    // 显示最近互动的角色
                                    if displayCharacters.isEmpty {
                                        // 如果没有最近互动的角色，显示提示信息
                                        VStack {
                                            Spacer().frame(height: 30)
                                            Text("暂无互动记录")
                                                .font(.system(size: 16))
                                                .foregroundColor(.secondary)
                                            Text("与角色互动后，他们会出现在这里")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .padding(.top, 8)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                    } else {
                                        // 显示最近互动的角色
                                        VStack(spacing: 8) {
                                            // 每行显示3个卡片
                                            ForEach(0..<(displayCharacters.count + 2) / 3, id: \.self) { rowIndex in
                                                HStack(spacing: 8) {
                                                    // 每行最多3个卡片
                                                    ForEach(0..<3) { columnIndex in
                                                        let index = rowIndex * 3 + columnIndex
                                                        if index < displayCharacters.count {
                                                            improvedCharacterCard(for: displayCharacters[index])
                                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                        } else {
                                                            // 占位视图，保持网格结构
                                                            Color.clear
                                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                                .aspectRatio(1, contentMode: .fit)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                    }
                                } else if showingFavorites {
                                    // 显示我的关注角色
                                    if displayCharacters.isEmpty {
                                        VStack {
                                            Spacer().frame(height: 30)
                                            Text("暂无关注角色")
                                                .font(.system(size: 16))
                                                .foregroundColor(.secondary)
                                            Text("关注角色后，他们会出现在这里")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .padding(.top, 8)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                    } else {
                                        VStack(spacing: 8) {
                                            // 每行显示3个卡片
                                            ForEach(0..<(displayCharacters.count + 2) / 3, id: \.self) { rowIndex in
                                                HStack(spacing: 8) {
                                                    // 每行最多3个卡片
                                                    ForEach(0..<3) { columnIndex in
                                                        let index = rowIndex * 3 + columnIndex
                                                        if index < displayCharacters.count {
                                                            improvedCharacterCard(for: displayCharacters[index])
                                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                        } else {
                                                            // 占位视图，保持网格结构
                                                            Color.clear
                                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                                .aspectRatio(1, contentMode: .fit)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                    }
                                } else if selectedCategory == .all {
                                    // 角色卡片网格，不显示标题行
                                    LazyVGrid(
                                        columns: threeColumns,
                                        alignment: .center,
                                        spacing: 8
                                    ) {
                                        ForEach(displayCharacters, id: \.id) { character in
                                            improvedCharacterCard(for: character)
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .id(character.id)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                                } else {
                                    // 优化角色卡片网格
                                    LazyVGrid(
                                        columns: threeColumns,
                                        alignment: .center,
                                        spacing: 8
                                    ) {
                                        ForEach(Array(displayCharacters.enumerated()), id: \.element.id) { index, character in
                                            improvedCharacterCard(for: character)
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .id(character.id)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: AppScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("scrollView")).minY
                                )
                            }
                        )
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(AppScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = -value
                    }
                }
            }
            
            // 移除之前的导航链接
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard)
        // 使用fullScreenCover进行导航
        .fullScreenCover(item: $navigateToCharacterDetail) { character in
            // 使用ZStack包装NavigationView，确保底部导航栏在整个导航过程中保持可见
            ZStack {
                // 使用NavigationView包装CharacterDetailView
                NavigationView {
                    CharacterDetailView(character: convertToCharacter(character))
                }
                .ignoresSafeArea(.all, edges: .bottom)
                
                // 添加一个透明视图，确保底部导航栏区域不被覆盖
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: tabBarManager.fullBottomAreaHeight)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .fullScreenCover(item: $navigateToChatView) { character in
            // 使用ZStack包装NavigationView，确保底部导航栏在整个导航过程中保持可见
            ZStack {
                // 使用NavigationView包装ChatView
                NavigationView {
                    ChatView(character: convertToChatCharacter(character))
                }
                .ignoresSafeArea(.all, edges: .bottom)
                
                // 添加一个透明视图，确保底部导航栏区域不被覆盖
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: tabBarManager.fullBottomAreaHeight)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .sheet(isPresented: $showingCreateCharacter) {
            NavigationView {
                CreateCharacterView(characters: $characters)
                    .onDisappear {
                        // 如果当前正在显示用户角色，则重新加载
                        if showingUserCharacters {
                            loadUserCharacters()
                        }
                        // 无论是否显示用户角色，都重新加载所有角色
                        // 这样确保新创建的角色同时出现在主列表和分类中
                        loadAllCharacters()
                    }
            }
        }
        .fullScreenCover(isPresented: $showingMultiPersonChatSetup) { // 改为fullScreenCover
            NavigationView { // 包裹NavigationView
                MultiPersonChatSetupView()
            }
        }
        .onAppear {
            // 🚀 轻量化onAppear，避免页面切换卡顿
            // 只在真正需要时进行数据加载
            if characters.isEmpty {
                // 快速同步加载核心数据，避免异步阻塞
                loadAllCharactersSync()
                
                // 延迟加载辅助数据，不阻塞页面切换
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    Task {
                        await loadAuxiliaryDataConcurrently()
                    }
                }
            }
            
            // 🔧 通知监听器优化 - 使用防抖机制
            setupOptimizedNotificationListeners()
            
            // 🔧 确保TabBar可见（立即执行，无需异步）
            tabBarManager.ensureTabBarVisible()
        }
        .onDisappear {
            // 🔧 取消正在进行的异步任务，避免内存泄漏
            favoriteUpdateTask?.cancel()
            characterCreatedTask?.cancel()
            
            // 移除通知监听，避免内存泄漏
            NotificationCenter.default.removeObserver(self, name: Notification.Name("FavoriteStatusChanged"), object: nil)
            NotificationCenter.default.removeObserver(self, name: Notification.Name("CharacterCreated"), object: nil)
        }
    }
    
    // 加载所有角色 - 保持兼容性，同时支持异步优化
    private func loadAllCharacters() {
        // 🚀 优化：直接使用异步加载，避免线程检查导致的问题
        Task {
            await loadCoreDataImmediately()
        }
    }
    
    /// 同步版本的加载所有角色（向后兼容）
    private func loadAllCharactersSync() {
        // 🔧 修复：探索页面应该显示所有角色，不应用分类过滤
        // 加载预定义角色（不应用BlockedCategoriesManager过滤）
        var allCharacters = CharacterModel.loadAllCharactersWithoutFilter()
        
        // 加载用户创建的角色
        loadUserCharacters()
        
        // 将用户创建的角色也添加到主角色列表中
        allCharacters.append(contentsOf: userCharacters)
        
        // 去重：根据角色ID去重，保留第一个出现的角色
        var seenIds = Set<String>()
        allCharacters = allCharacters.filter { character in
            if seenIds.contains(character.id) {
                return false
            } else {
                seenIds.insert(character.id)
                return true
            }
        }
        
        // 更新角色列表
        self.characters = allCharacters
    }
    
    // 完整重新实现improvedCharacterCard方法
    private func improvedCharacterCard(for character: CharacterModel) -> some View {
        if isManagingCharacters {
            // 管理模式，使用新的CharacterManagementView
            return AnyView(
                CharacterManagementView(
                    character: character,
                    isUserCreated: character.id.hasPrefix("custom_"),
                    onDeleteOrHide: {
                        // 根据角色类型选择适当的操作
                        if character.id.hasPrefix("custom_") {
                            // 用户创建的角色 - 删除
                            characterToDelete = character
                            showingDeleteConfirmation = true
                        } else {
                            // 预设角色 - 隐藏
                            characterToHide = character
                            showingHideConfirmation = true
                        }
                    }
                )
                .alert(isPresented: Binding<Bool>(
                    get: { 
                        character.id.hasPrefix("custom_") ? showingDeleteConfirmation : showingHideConfirmation 
                    },
                    set: { newValue in
                        if character.id.hasPrefix("custom_") {
                            showingDeleteConfirmation = newValue
                        } else {
                            showingHideConfirmation = newValue
                        }
                    }
                )) {
                    if character.id.hasPrefix("custom_") {
                        // 用户创建的角色 - 删除确认
                        return Alert(
                            title: Text("删除角色"),
                            message: Text("确定要删除角色\"\(characterToDelete?.name ?? "")\"吗？此操作不可恢复。"),
                            primaryButton: .destructive(Text("删除")) {
                                if let character = characterToDelete {
                                    deleteCharacter(character)
                                }
                            },
                            secondaryButton: .cancel(Text("取消"))
                        )
                    } else {
                        // 预设角色 - 隐藏确认
                        return Alert(
                            title: Text("隐藏角色"),
                            message: Text("确定要隐藏角色\"\(characterToHide?.name ?? "")\"吗？可在设置中恢复。"),
                            primaryButton: .destructive(Text("隐藏")) {
                                if let character = characterToHide {
                                    hideCharacter(character)
                                }
                            },
                            secondaryButton: .cancel(Text("取消"))
                        )
                    }
                }
            )
        } else {
            // 正常模式下使用标准卡片
            return AnyView(
                ImprovedCharacterCardView(character: character)
                    .onTap {
                        // 导航到角色详情页
                        navigateToCharacterDetail = character
                    }
                    .onChatTap {
                        // 添加聊天互动记录
                        addInteraction(for: character, type: .chat)
                        
                        // 导航到聊天页面
                        navigateToChatView = character
                    }
            )
        }
    }
    
    /// 导航到角色详情页
    func navigateToCharacterDetail(_ character: CharacterModel) {
        // 直接导航，不处理TabBar
        navigateToCharacterDetail = character
    }
    
    /// 导航到聊天页面
    func navigateToCharacterChat(_ character: CharacterModel) {
        // 直接导航，不处理TabBar
        navigateToChatView = character
    }
    
    // 分类视图辅助方法
    func categoryView(for category: CharacterCategory) -> some View {
        VStack(spacing: 8) { // 图标和文字间距
            ZStack {
                Circle()
                    .fill(category.color.opacity(selectedCategory == category ? 0.9 : 0.15))
                    .frame(width: 56, height: 56) // 图标稍大
                
                Image(systemName: category.icon)
                    .font(.system(size: 22)) // icon稍大
                    .foregroundColor(selectedCategory == category ? .white : category.color)
            }
            .shadow(
                color: category.color.opacity(selectedCategory == category ? 0.25 : 0), 
                radius: 5,
                x: 0,
                y: 2
            )
            
            Text(category.displayName)
                .font(.system(size: 11)) // 文字变小
                .foregroundColor(selectedCategory == category ? .primary : Color(.secondaryLabel)) // 恢复原来的颜色
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    /// 根据分类、时间轴和搜索文本过滤角色
    private var filteredCharacters: [CharacterModel] {
        // 首先过滤掉所有被隐藏的角色
        var result = characters.filter { !hiddenCharacters.contains($0.id) }
        
        // 如果是在"我的角色"模式下，只显示用户创建的角色
        if showingUserCharacters {
            return userCharacters
        }
        
        // 如果是在"我的关注"模式下，只显示关注的角色
        if showingFavorites {
            result = result.filter { followManager.isFollowing($0.name) }
        }
        
        // 如果是在"最近互动"模式下，显示最近互动的角色
        if showingRecentInteractions {
            let recentCharacterIds = recentInteractions.map { $0.characterId }
            result = result.filter { recentCharacterIds.contains($0.id) }
            
            // 根据最近互动的顺序排序
            result.sort { char1, char2 in
                let index1 = recentCharacterIds.firstIndex(of: char1.id) ?? Int.max
                let index2 = recentCharacterIds.firstIndex(of: char2.id) ?? Int.max
                return index1 < index2
            }
        } else if selectedCategory != .all {
            // 根据选中的分类过滤
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 根据搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.profession.localizedCaseInsensitiveContains(searchText) ||
                $0.bio.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 根据时间轴过滤
        if let era = selectedEra {
            result = result.filter { $0.era == era }
        }
        
        return result
    }
    
    /// 获取最近互动的角色列表
    private var recentInteractionCharacters: [CharacterModel] {
        // 首先按时间戳降序排序最近互动记录（最新的在前面）
        let sortedInteractions = recentInteractions.sorted { $0.timestamp > $1.timestamp }
        
        // 获取所有互动过的角色ID（保持时间顺序）
        let characterIds = sortedInteractions.map { $0.characterId }
        
        // 根据互动记录获取角色对象，保持时间排序
        return characterIds
            .compactMap { id in characters.first { $0.id == id } }
            .uniqued() // 确保不重复
    }
    
    /// 获取我的关注角色列表
    private var favoriteCharactersList: [CharacterModel] {
        // 根据关注列表获取角色对象
        return followManager.followedUsers
            .compactMap { username in 
                characters.first { $0.name == username }
            }
    }
    
    // 在ExploreView中，找到displayCharacters计算属性，并将其修改为：
    private var displayCharacters: [CharacterModel] {
        // 如果是"最近互动"模式，则直接返回按时间排序的列表，不应用任何置顶逻辑
        if showingRecentInteractions {
            return recentInteractionCharacters
        }

        var result: [CharacterModel]
        
        // 根据当前模式获取基础角色列表
        if showingUserCharacters {
            result = userCharacters
            if selectedCategory != .all {
                result = result.filter { $0.category == selectedCategory }
            }
        } else if showingFavorites {
            result = favoriteCharactersList
        } else {
            result = filteredCharacters
        }
        
        // 根据选项卡进行排序
        switch selectedTab {
        case .all, .manage:
            // 保持默认排序
            break
        case .popular:
            // 对于热门排序，我们只随机排列未置顶的角色
            let pinnedIds = CharacterPinManager.shared.pinnedCharacterIds
            let pinnedChars = result.filter { pinnedIds.contains($0.id) }
            let unpinnedChars = result.filter { !pinnedIds.contains($0.id) }.shuffled()
            result = pinnedChars + unpinnedChars
        }
        
        // 对除"最近互动"外的所有情况，应用置顶排序
        return CharacterPinManager.shared.getSortedCharacters(characters: result, idKeyPath: \.id)
    }
    
    // 处理查看全部事件
    func handleViewAllTap() {
        // 查看全部角色
        selectedCategory = .all
        searchText = ""
    }
    
    // 处理创建角色事件
    func handleCreateCharacter() {
        showingCreateCharacter = true
    }
    
    // 转换CharacterModel为Character（用于详情页）
    func convertToCharacter(_ characterModel: CharacterModel) -> Character {
        // 创建一个新的Character实例
        let character = Character(
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
        return character
    }
    
    // 转换CharacterModel为CYChatCharacter（用于聊天页）
    func convertToChatCharacter(_ characterModel: CharacterModel) -> CYChatCharacter {
        return CYChatCharacter(
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
            rating: Double.random(in: 4.0...5.0)
        )
    }
    
    // 按角色数量排序的分类列表
    private var sortedCategories: [CharacterCategory] {
        // 明确指定要显示的分类（排除"全部"和已删除的"科学家"、"艺术家"）
        let availableCategories: [CharacterCategory] = [
            .historical,    // 历史人物（包含科学家、艺术家）
            .philosopher,   // 哲学家
            .writer,        // 文学世界
            .animeCharacter, // 动漫角色
            .gameCharacter,  // 游戏角色
            .filmCharacter,  // 影视角色
            .mythCharacter   // 神话角色
        ]
        
        // 获取每个分类的角色数量
        var categoryCounts: [(category: CharacterCategory, count: Int)] = []
        for category in availableCategories {
            let count = characters.filter { $0.category == category }.count
            categoryCounts.append((category, count))
        }
        
        // 按角色数量从多到少排序
        categoryCounts.sort { $0.count > $1.count }
        
        // 返回排序后的分类
        return categoryCounts.map { $0.category }
    }
    
    // 前三个排序的分类（第一行显示）
    private var topCategories: [CharacterCategory] {
        return Array(sortedCategories.prefix(3))
    }
    
    // 剩余的排序分类（第二行显示）
    private var remainingCategories: [CharacterCategory] {
        return Array(sortedCategories.dropFirst(3))
    }
    
    // MARK: - 最近互动相关方法
    
    /// 添加角色交互记录
    func addInteraction(for character: CharacterModel, type: CharacterInteraction.InteractionType) {
        // 检查是否已有该角色的互动记录
        let existingInteractionIndex = recentInteractions.firstIndex { 
            $0.characterId == character.id && $0.interactionType == type 
        }
        
        let newInteraction = CharacterInteraction(
            characterId: character.id,
            characterName: character.name,
            interactionType: type,
            timestamp: Date()
        )
        
        if let index = existingInteractionIndex {
            // 删除旧记录
            recentInteractions.remove(at: index)
            // 在最前面插入更新的记录
            recentInteractions.insert(newInteraction, at: 0)
        } else {
            // 添加新记录到最前面
            recentInteractions.insert(newInteraction, at: 0)
            
            // 如果超过限制，删除最早的记录
            if recentInteractions.count > maxRecentInteractions {
                recentInteractions.removeLast()
            }
        }
        
        // 保存到本地存储
        saveRecentInteractions()
        
        print("添加/更新交互记录: \(character.name) - \(type.rawValue)")
    }
    
    /// 保存最近互动记录到本地
    func saveRecentInteractions() {
        if let data = try? JSONEncoder().encode(recentInteractions) {
            UserDefaults.standard.set(data, forKey: "recentInteractions")
        }
    }
    
    /// 从本地加载最近互动记录
    func loadRecentInteractions() {
        if let data = UserDefaults.standard.data(forKey: "recentInteractions"),
           let interactions = try? JSONDecoder().decode([CharacterInteraction].self, from: data) {
            recentInteractions = interactions
        }
    }
    
    // 修改处理最近互动按钮点击的方法
    func handleRecentInteractionsTap() {
        withAnimation(.easeInOut) {
            // 切换最近互动显示状态
            showingRecentInteractions.toggle()
            
            // 如果开启了最近互动显示，关闭其他特殊显示模式
            if showingRecentInteractions {
                showingFavorites = false
                showingUserCharacters = false // 确保关闭"我的角色"模式
                selectedCategory = .all // 重置分类选择
            }
        }
    }
    
    // 修改处理我的关注按钮点击的方法
    func handleFavoritesTap() {
        withAnimation(.easeInOut) {
            // 切换我的关注显示状态
            showingFavorites.toggle()
            
            // 如果开启了我的关注显示，关闭其他特殊显示模式
            if showingFavorites {
                showingRecentInteractions = false
                showingUserCharacters = false // 确保关闭"我的角色"模式
                selectedCategory = .all // 重置分类选择
            }
        }
    }
    
    /// 重置显示模式
    func resetDisplayMode() {
        withAnimation(.easeInOut) {
            showingRecentInteractions = false
            showingFavorites = false
            // 不重置分类选择，保持当前选中的分类
            // selectedCategory = .all
        }
    }
    
    /// 添加角色到关注列表
    func toggleFavorite(for character: CharacterModel) {
        let newFollowStatus = followManager.toggleFollow(for: character.name)
        
        // 如果当前在我的关注页面并且关注列表为空，可能需要重置显示模式
        if showingFavorites && !newFollowStatus && favoriteCharactersList.isEmpty {
            // 可以选择添加一个小延迟，让动画效果更好
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    if favoriteCharactersList.isEmpty {
                        resetDisplayMode()
                    }
                }
            }
        }
        
        // 发送通知，更新其他视图中的关注状态
        NotificationCenter.default.post(
            name: Notification.Name("FavoriteStatusChanged"), 
            object: nil,
            userInfo: ["characterId": character.id, "isFavorited": newFollowStatus]
        )
    }
    
    /// 判断角色是否被关注
    func isFavorite(_ character: CharacterModel) -> Bool {
        return followManager.isFollowing(character.name)
    }
    

    
    /// 处理角色点赞
    func handleCharacterLike(for character: CharacterModel) {
        // 添加点赞互动记录
        addInteraction(for: character, type: .like)
        
        // 这里可以添加点赞的网络请求等
        print("用户点赞了角色: \(character.name)")
    }
    
    /// 处理角色评论
    func handleCharacterComment(for character: CharacterModel) {
        // 添加评论互动记录
        addInteraction(for: character, type: .comment)
        
        // 这里可以添加评论的网络请求等
        print("用户评论了角色: \(character.name)")
    }
    
    /// 处理角色聊天
    func handleCharacterChat(for character: CharacterModel) {
        // 添加聊天互动记录
        addInteraction(for: character, type: .chat)
        
        // 导航到聊天页面
        navigateToCharacterChat(character)
    }

    // 添加处理"我的角色"点击的方法
    func handleUserCharactersTap() {
        withAnimation(.easeInOut) {
            // 切换显示状态
            showingUserCharacters.toggle()
            
            // 如果开启了"我的角色"显示，关闭其他特殊显示模式
            if showingUserCharacters {
                showingRecentInteractions = false
                showingFavorites = false
                selectedCategory = .all // 在"我的角色"模式下，重置分类选择为"全部"
                
                // 加载用户创建的角色
                loadUserCharacters()
            } else {
                // 如果关闭了"我的角色"显示，重置为默认状态
                selectedCategory = .all
            }
        }
    }

    // 添加加载用户角色的方法
    private func loadUserCharacters() {
        // 尝试从UserDefaults加载自定义角色
        guard let data = UserDefaults.standard.data(forKey: "CustomCharactersData") else {
            userCharacters = []
            return
        }
        
        do {
            if let characterDicts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var loadedCharacters: [CharacterModel] = []
                
                for dict in characterDicts {
                    if let id = dict["id"] as? String,
                       let name = dict["name"] as? String,
                       let avatar = dict["avatar"] as? String,
                       let profession = dict["profession"] as? String,
                       let bio = dict["bio"] as? String,
                       let categoryRawValue = dict["category"] as? String,
                       let era = dict["era"] as? String {
                        
                        let category = CharacterCategory(rawValue: categoryRawValue) ?? .filmCharacter
                        
                        let character = CharacterModel(
                            id: id,
                            name: name,
                            avatar: avatar,
                            era: era,
                            profession: profession,
                            bio: bio,
                            category: category
                        )
                        
                        loadedCharacters.append(character)
                    }
                }
                
                userCharacters = loadedCharacters
            }
        } catch {
            print("加载自定义角色失败: \(error)")
            userCharacters = []
        }
    }

    // 添加删除角色的方法
    private func deleteCharacter(_ character: CharacterModel) {
        print("删除角色: \(character.name), ID: \(character.id)")
        
        // 1. 从内存中删除
        if let index = userCharacters.firstIndex(where: { $0.id == character.id }) {
            userCharacters.remove(at: index)
        }
        
        if let index = characters.firstIndex(where: { $0.id == character.id }) {
            characters.remove(at: index)
        }
        
        // 2. 从UserDefaults中删除
        deleteCharacterFromUserDefaults(character.id)
        
        // 3. 删除头像文件
        deleteCharacterImage(character.id)
        
        // 4. 发送通知，通知其他视图更新
        NotificationCenter.default.post(
            name: Notification.Name("CharacterDeleted"),
            object: nil,
            userInfo: ["characterId": character.id]
        )
        
        // 如果删除后没有角色了，退出管理模式
        if userCharacters.isEmpty {
            isManagingCharacters = false
        }
    }
    
    // 从UserDefaults中删除角色
    private func deleteCharacterFromUserDefaults(_ characterId: String) {
        guard let data = UserDefaults.standard.data(forKey: "CustomCharactersData") else { return }
        
        do {
            if var characterDicts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                // 过滤掉要删除的角色
                characterDicts = characterDicts.filter { dict in
                    guard let id = dict["id"] as? String else { return true }
                    return id != characterId
                }
                
                // 保存更新后的数据
                let updatedData = try JSONSerialization.data(withJSONObject: characterDicts)
                UserDefaults.standard.set(updatedData, forKey: "CustomCharactersData")
                print("成功从UserDefaults中删除角色: \(characterId)")
            }
        } catch {
            print("从UserDefaults中删除角色失败: \(error)")
        }
    }
    
    // 删除角色图像文件
    private func deleteCharacterImage(_ characterId: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("\(characterId).jpg")
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("成功删除角色图像文件: \(fileURL.path)")
            }
        } catch {
            print("删除角色图像文件失败: \(error)")
        }
    }

    // 添加隐藏角色的方法
    func hideCharacter(_ character: CharacterModel) {
        print("隐藏角色: \(character.name), ID: \(character.id)")
        
        // 将角色ID添加到隐藏列表
        if !hiddenCharacters.contains(character.id) {
            hiddenCharacters.append(character.id)
        }
        
        // 保存到UserDefaults
        saveHiddenCharacters()
        
        // 重新加载角色列表，使隐藏生效
        loadAllCharacters()
    }

    // 修改置顶状态切换方法，移除private修饰符
    func togglePinStatus(for character: CharacterModel) {
        if pinnedCharacters.contains(character.id) {
            // 如果已经置顶，则取消置顶
            pinnedCharacters.removeAll { $0 == character.id }
            print("取消置顶角色: \(character.name)")
        } else {
            // 如果未置顶，则添加到置顶列表
            pinnedCharacters.append(character.id)
            print("置顶角色: \(character.name)")
        }
        
        // 保存置顶状态
        savePinnedCharacters()
        
        // 重新排序角色列表，让置顶角色显示在前面
        // 不需要重新加载所有角色，因为filteredCharacters和displayCharacters会根据置顶状态重新排序
    }

    // MARK: - 🚀 异步数据加载优化
    
    /// 异步并发数据加载 - 保持现有功能和效果
    private func loadDataAsynchronously() {
        Task {
            // 🎯 第一阶段：立即加载核心数据（角色列表）
            // 这是用户最先看到的内容，需要优先加载
            await loadCoreDataImmediately()
            
            // 🎯 第二阶段：并发加载辅助数据
            // 这些数据影响筛选和状态，但不阻塞初始显示
            await loadAuxiliaryDataConcurrently()
        }
    }

    /// 第一阶段：立即加载核心数据
    private func loadCoreDataImmediately() async {
        // 在后台线程加载角色数据
        let loadedCharacters = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 🔧 修复：探索页面应该显示所有角色，不应用分类过滤
                var allCharacters = CharacterModel.loadAllCharactersWithoutFilter()
                
                // 加载用户创建的角色
                let userChars = self.loadUserCharactersSync()
                allCharacters.append(contentsOf: userChars)
                
                continuation.resume(returning: allCharacters)
            }
        }
        
        // 在主线程更新UI
        await MainActor.run {
            self.characters = loadedCharacters
            self.userCharacters = loadedCharacters.filter { $0.id.hasPrefix("custom_") }
        }
    }

    /// 第二阶段：并发加载辅助数据
    private func loadAuxiliaryDataConcurrently() async {
        // 🚀 并发执行4个辅助数据加载任务
        await withTaskGroup(of: Void.self) { group in
            // 任务1：加载最近互动
            group.addTask {
                let interactions = await self.loadRecentInteractionsAsync()
                await MainActor.run {
                    self.recentInteractions = interactions
                }
            }
            
            // 任务2：关注列表由FollowManager管理，无需额外加载
            
            // 任务3：加载隐藏角色
            group.addTask {
                let hidden = await self.loadHiddenCharactersAsync()
                await MainActor.run {
                    self.hiddenCharacters = hidden
                }
            }
            
            // 任务4：加载置顶角色
            group.addTask {
                let pinned = await self.loadPinnedCharactersAsync()
                await MainActor.run {
                    self.pinnedCharacters = pinned
                }
            }
        }
    }

    // MARK: - 异步数据加载方法

    /// 异步加载用户角色（保持原有逻辑）
    private func loadUserCharactersSync() -> [CharacterModel] {
        guard let data = UserDefaults.standard.data(forKey: "CustomCharactersData") else {
            return []
        }
        
        do {
            if let characterDicts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var loadedCharacters: [CharacterModel] = []
                
                for dict in characterDicts {
                    if let id = dict["id"] as? String,
                       let name = dict["name"] as? String,
                       let avatar = dict["avatar"] as? String,
                       let profession = dict["profession"] as? String,
                       let bio = dict["bio"] as? String,
                       let categoryRawValue = dict["category"] as? String,
                       let era = dict["era"] as? String {
                        
                        let category = CharacterCategory(rawValue: categoryRawValue) ?? .filmCharacter
                        
                        let character = CharacterModel(
                            id: id,
                            name: name,
                            avatar: avatar,
                            era: era,
                            profession: profession,
                            bio: bio,
                            category: category
                        )
                        
                        loadedCharacters.append(character)
                    }
                }
                
                return loadedCharacters
            }
        } catch {
            print("加载自定义角色失败: \(error)")
        }
        
        return []
    }

    /// 异步加载最近互动数据
    private func loadRecentInteractionsAsync() async -> [CharacterInteraction] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                if let data = UserDefaults.standard.data(forKey: "recentInteractions"),
                   let interactions = try? JSONDecoder().decode([CharacterInteraction].self, from: data) {
                    continuation.resume(returning: interactions)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }



    /// 异步加载隐藏角色数据
    private func loadHiddenCharactersAsync() async -> [String] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                if let data = UserDefaults.standard.data(forKey: "HiddenCharacters"),
                   let decodedIds = try? JSONDecoder().decode([String].self, from: data) {
                    continuation.resume(returning: decodedIds)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// 异步加载置顶角色数据
    private func loadPinnedCharactersAsync() async -> [String] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                if let data = UserDefaults.standard.data(forKey: "PinnedCharacters"),
                   let decodedIds = try? JSONDecoder().decode([String].self, from: data) {
                    continuation.resume(returning: decodedIds)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    // MARK: - 🔧 优化通知监听器
    
    // 🔧 将Task存储为实例变量，避免被过早释放
    @State private var favoriteUpdateTask: Task<Void, Never>?
    @State private var characterCreatedTask: Task<Void, Never>?

    /// 设置优化的通知监听器（防抖机制）
    private func setupOptimizedNotificationListeners() {
        // 关注状态变化通知（300ms防抖）
        NotificationCenter.default.addObserver(forName: Notification.Name("FavoriteStatusChanged"), object: nil, queue: .main) { _ in
            favoriteUpdateTask?.cancel()
            favoriteUpdateTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms防抖
                // 关注数据由FollowManager管理，UI会自动更新
            }
        }
        
        // 监听FollowManager的关注状态变化
        NotificationCenter.default.addObserver(forName: Notification.Name("FollowStatusChanged"), object: nil, queue: .main) { _ in
            favoriteUpdateTask?.cancel()
            favoriteUpdateTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms防抖
                // 关注数据由FollowManager管理，UI会自动更新
            }
        }
        
        // 角色创建通知（500ms防抖）
        NotificationCenter.default.addObserver(forName: Notification.Name("CharacterCreated"), object: nil, queue: .main) { _ in
            characterCreatedTask?.cancel()
            characterCreatedTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms防抖
                await MainActor.run {
                    self.loadAllCharacters()
                }
            }
        }
    }
}

// MARK: - 数组扩展
extension Array where Element: Hashable {
    // 去除重复元素
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// 在Array扩展后，Preview前，添加存储和加载隐藏角色的扩展方法
extension ExploreView {
    // 保存隐藏角色到UserDefaults
    func saveHiddenCharacters() {
        if let encoded = try? JSONEncoder().encode(hiddenCharacters) {
            UserDefaults.standard.set(encoded, forKey: "HiddenCharacters")
            print("保存了\(hiddenCharacters.count)个隐藏角色到UserDefaults")
        }
    }
    
    // 从UserDefaults加载隐藏角色
    func loadHiddenCharacters() {
        if let data = UserDefaults.standard.data(forKey: "HiddenCharacters"),
           let decodedIds = try? JSONDecoder().decode([String].self, from: data) {
            hiddenCharacters = decodedIds
    
        }
    }
}

// 在ExploreView扩展中修复private修饰符问题
extension ExploreView {
    // 保存置顶角色列表到UserDefaults
    func savePinnedCharacters() {
        if let encoded = try? JSONEncoder().encode(pinnedCharacters) {
            UserDefaults.standard.set(encoded, forKey: "PinnedCharacters")
            print("保存了\(pinnedCharacters.count)个置顶角色到UserDefaults")
        }
    }
    
    // 从UserDefaults加载置顶角色列表
    func loadPinnedCharacters() {
        if let data = UserDefaults.standard.data(forKey: "PinnedCharacters"),
           let decodedIds = try? JSONDecoder().decode([String].self, from: data) {
            pinnedCharacters = decodedIds
    
        }
    }
}

#Preview("探索页面") {
    ExploreView()
} 

// 添加"我的角色"视图
struct MyCharactersView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var characters: [CharacterModel] = []
    @State private var selectedCharacter: CharacterModel?
    @State private var showingCreateCharacter = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题栏
                Text("我的角色")
                    .font(.system(size: 18, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(.systemBackground))
                    .overlay(
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("关闭")
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 16)
                            
                            Spacer()
                            
                            Button(action: {
                                showingCreateCharacter = true
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(.blue)
                            }
                            .padding(.trailing, 16)
                        }
                    )
                
                if characters.isEmpty {
                    // 空状态视图
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "person.fill.questionmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("您还没有创建角色")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingCreateCharacter = true
                        }) {
                            Text("创建角色")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // 内容视图 - 使用网格布局展示角色卡片
                    ScrollView {
                        // 分类标签栏
                        HStack(spacing: 20) {
                            Text("全部")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.primary.opacity(0.1))
                                .cornerRadius(16)
                            
                            Text("最近")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Text("热门")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        
                        // 角色网格
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(characters) { character in
                                CharacterGridItem(character: character)
                                    .onTapGesture {
                                        selectedCharacter = character
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateCharacter) {
                // 使用相对路径引用CreateCharacterView
                CreateCharacterView(characters: $characters)
                    .onDisappear {
                        loadUserCharacters()
                    }
            }
            .background(
                Group {
                    if #available(iOS 16.0, *) {
                        // iOS 16及以上使用新API
                        NavigationLink(value: selectedCharacter) {
                            EmptyView()
                        }
                        .navigationDestination(for: CharacterModel.self) { character in
                            // 创建一个Character对象，使用CharacterModel的属性
                            let characterForDetail = Character(
                                id: character.id,
                                name: character.name,
                                introduction: character.bio,
                                field: character.profession,
                                birthYear: character.era,
                                avatarUrl: character.avatar,
                                achievements: [],
                                mainWorks: [],
                                keyThoughts: []
                            )
                            CharacterDetailView(character: characterForDetail)
                        }
                    } else {
                        // iOS 16以下使用旧API
                        NavigationLink(
                            destination: Group {
                                if let character = selectedCharacter {
                                    // 创建一个Character对象，使用CharacterModel的属性
                                    let characterForDetail = Character(
                                        id: character.id,
                                        name: character.name,
                                        introduction: character.bio,
                                        field: character.profession,
                                        birthYear: character.era,
                                        avatarUrl: character.avatar,
                                        achievements: [],
                                        mainWorks: [],
                                        keyThoughts: []
                                    )
                                    CharacterDetailView(character: characterForDetail)
                                } else {
                                    EmptyView()
                                }
                            },
                            isActive: Binding<Bool>(
                                get: { selectedCharacter != nil },
                                set: { if !$0 { selectedCharacter = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                    }
                }
            )
        }
        .onAppear {
            loadUserCharacters()
        }
    }
    
    private func loadUserCharacters() {
        // 尝试从UserDefaults加载自定义角色
        guard let data = UserDefaults.standard.data(forKey: "CustomCharactersData") else {
            characters = []
            return
        }
        
        do {
            if let characterDicts = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var loadedCharacters: [CharacterModel] = []
                
                for dict in characterDicts {
                    if let id = dict["id"] as? String,
                       let name = dict["name"] as? String,
                       let avatar = dict["avatar"] as? String,
                       let profession = dict["profession"] as? String,
                       let bio = dict["bio"] as? String,
                       let categoryRawValue = dict["category"] as? String,
                       let era = dict["era"] as? String {
                        
                        let category = CharacterCategory(rawValue: categoryRawValue) ?? .filmCharacter
                        
                        let character = CharacterModel(
                            id: id,
                            name: name,
                            avatar: avatar,
                            era: era,
                            profession: profession,
                            bio: bio,
                            category: category
                        )
                        
                        loadedCharacters.append(character)
                    }
                }
                
                characters = loadedCharacters
            }
        } catch {
            print("加载自定义角色失败: \(error)")
            characters = []
        }
    }
}

// 角色网格项组件
struct CharacterGridItem: View {
    let character: CharacterModel
    @State private var customImage: UIImage? = nil
    
    var body: some View {
        VStack(spacing: 6) {
            // 角色头像 - 使用统一的CharacterAvatarService
            ZStack {
                if let customImage = customImage {
                    // 显示从文档目录加载的自定义头像
                    Image(uiImage: customImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Rectangle())
                        .cornerRadius(8)
                } else if let avatarImage = UIImage(named: character.avatar), avatarImage.size.width > 0 {
                    // 系统提供的头像图片
                    Image(character.avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Rectangle())
                        .cornerRadius(8)
                } else {
                    // 使用与CharacterAvatarService完全相同的渐变效果
                    let avatarColor = CharacterAvatarService.shared.generateConsistentColor(for: character.id)
                    let size: CGFloat = 100
                    
                    ZStack {
                        // 使用与CharacterAvatarService相同的渐变背景
                        Rectangle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        avatarColor.opacity(0.45),
                                        avatarColor.opacity(0.25),
                                        avatarColor.opacity(0.08)
                                    ]),
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: size * 0.05,
                                    endRadius: size * 0.85
                                )
                            )
                            .overlay(
                                // 增强的边框效果
                                Rectangle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.5),
                                                avatarColor.opacity(0.2),
                                                Color.black.opacity(0.08)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        // 文字放在右下角
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(String(character.name.prefix(1)))
                                    .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.95),
                                                Color.white.opacity(0.85)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: avatarColor.opacity(0.8), radius: 1, x: 0, y: 1)
                                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    .padding(.trailing, 8)
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                    .shadow(color: avatarColor.opacity(0.25), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .clipShape(Rectangle())
                    .cornerRadius(8)
                }
            }
            .frame(width: 100, height: 100)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            // 角色名称 - 添加聊天气泡样式
            HStack {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.7))
                
                Text(formatDisplayName(character.name))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .cornerRadius(12)
        }
        .padding(.vertical, 8)
        .onAppear {
            // 尝试从文档目录加载自定义头像
            loadCustomAvatar()
        }
    }
    
    // 格式化显示名称，处理过长或中英文混合的名称
    private func formatDisplayName(_ name: String) -> String {
        // 如果名称中包含括号，只显示括号前的部分
        if let bracketRange = name.range(of: "（") ?? name.range(of: "(") {
            let nameBeforeBracket = String(name[name.startIndex..<bracketRange.lowerBound])
            return nameBeforeBracket.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 如果名称过长，截断显示
        if name.count > 8 {
            let endIndex = name.index(name.startIndex, offsetBy: 8)
            return String(name[..<endIndex]) + "..."
        }
        
        return name
    }
    
    // 从文档目录加载自定义头像
    private func loadCustomAvatar() {
        // 记录尝试加载的信息
        print("🔄 CharacterGridItem - 尝试加载头像: id=\(character.id), avatar=\(character.avatar)")
        
        // 只对自定义角色尝试加载头像
        if character.id.hasPrefix("custom_") {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(character.id).jpg")
            
            // 直接从文件路径加载图像
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.customImage = image
                        print("✅ CharacterGridItem - 成功加载自定义头像: \(character.id)")
                    }
                } else {
                    print("❌ CharacterGridItem - 无法加载自定义头像数据: \(character.id)")
                }
            } else {
                print("⚠️ CharacterGridItem - 自定义头像文件不存在: \(character.id)")
                
                // 如果直接加载失败，尝试使用CustomAvatarLoader
                if let image = CustomAvatarLoader.shared.loadCustomAvatar(characterId: character.id, avatarName: character.avatar) {
                    DispatchQueue.main.async {
                        self.customImage = image
                        print("✅ CharacterGridItem - 通过CustomAvatarLoader成功加载: \(character.id)")
                    }
                }
            }
        } else {
            print("ℹ️ CharacterGridItem - 非自定义角色: \(character.id)")
        }
    }
} 

// 修改ManagedCharacterCardView以支持不同的按钮样式
struct ManagedCharacterCardView: View {
    let character: CharacterModel
    let isUserCreated: Bool
    let onAction: () -> Void
    let isPinned: Bool
    let onTogglePin: () -> Void
    
    var body: some View {
        // 使用ZStack将按钮覆盖在原有卡片上
        ZStack(alignment: .topTrailing) {
            // 使用原有的ImprovedCharacterCardView
            ZStack(alignment: .topLeading) {
                ImprovedCharacterCardView(character: character)
                    // 禁用原有卡片的点击事件，避免与按钮冲突
                    .allowsHitTesting(false)
                
                // 左上角添加置顶/取消置顶按钮
                Button(action: onTogglePin) {
                    ZStack {
                        Circle()
                            .fill(isPinned ? Color.yellow : Color.gray.opacity(0.8))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 6, y: 6)
                .padding(8)
            }
            
            // 右上角保留原有的删除/隐藏按钮
            Button(action: onAction) {
                ZStack {
                    Circle()
                        .fill(isUserCreated ? Color.red : Color.orange)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: isUserCreated ? "xmark" : "eye.slash")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(x: 6, y: -6)
            .padding(8)
        }
    }
} 

