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
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 选项卡类型
    enum TabType: String, CaseIterable {
        case all = "全部"
        case popular = "热门"
        case recent = "最近"
    }
    
    // 当前选中的选项卡
    @State private var selectedTab: TabType = .all
    
    // 是否显示最近互动角色
    @State private var showingRecentInteractions: Bool = false
    
    // 是否显示我的关注角色
    @State private var showingFavorites: Bool = false
    
    // 我的关注角色列表
    @State private var favoriteCharacters: [String] = [] // 存储角色ID
    
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

    // 添加新的状态变量和sheet
    @State private var showingMyCharacters = false
    @State private var userCharacters: [CharacterModel] = []

    var body: some View {
        ZStack(alignment: .top) {
            // 背景色 - 使用微妙的渐变增加空间感
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 248/255, green: 250/255, blue: 252/255),
                    Color(red: 250/255, green: 252/255, blue: 254/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 主内容区
            VStack(spacing: 0) {
                // 顶部区域：搜索栏
                VStack(spacing: 0) {
                    // 搜索栏 - 优化视觉层次感
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.systemGray2))
                                .padding(.leading, 8)
                            
                            TextField("搜索时空旅行者...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6).opacity(0.9))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                        )
                        
                        // 扫码按钮 - 圆润极简设计
                        Button(action: {
                            // TODO: 实现扫码功能
                            print("扫码按钮被点击")
                        }) {
                            ZStack {
                                // 圆角方形框架，表示扫描区域
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.primary.opacity(0.4), lineWidth: 1)
                                    .frame(width: 14, height: 14)
                                
                                // 中间的横线，更淡的颜色
                                Capsule()
                                    .fill(Color.primary.opacity(0.4))
                                    .frame(width: 8, height: 1)
                            }
                            .frame(width: 30, height: 30)
                        }
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
                                // 多人对话按钮 - 精致化设计
                                Button(action: {
                                    // 处理多人对话功能
                                    // TODO: 实现多人对话功能
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(red: 160/255, green: 130/255, blue: 250/255))
                                        
                                        Text("多人对话")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
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
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
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
                                        
                                    // 我的角色按钮 (交换位置)
                                        Button(action: {
                                        // 显示用户创建的角色列表，而不是直接显示创建角色视图
                                        showingMyCharacters = true
                                        }) {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    Circle()
                                                    .fill(Color(red: 95/255, green: 158/255, blue: 225/255).opacity(0.15))
                                                        .frame(width: 56, height: 56)
                                                    
                                                Image(systemName: "person.crop.circle")
                                                        .font(.system(size: 22))
                                                    .foregroundColor(Color(red: 95/255, green: 158/255, blue: 225/255))
                                                }
                                                .shadow(
                                                color: Color(red: 95/255, green: 158/255, blue: 225/255).opacity(0), 
                                                radius: 5,
                                                    x: 0,
                                                y: 2
                                                )
                                                
                                            Text("我的角色")
                                                    .font(.system(size: 11))
                                                .foregroundColor(Color(.secondaryLabel))
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                            }
                                        }
                                        
                                    // 显示历史人物和文学家分类按钮（固定在第一排）
                                    let firstRowCategories: [CharacterCategory] = [.historical, .writer]
                                    ForEach(firstRowCategories, id: \.self) { category in
                                            Button(action: {
                                                withAnimation(.easeInOut) {
                                                // 设置选中的分类
                                                    selectedCategory = category
                                                
                                                // 重置特殊显示模式，但保持分类选择
                                                showingRecentInteractions = false
                                                showingFavorites = false
                                                
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
                                
                                // 第二排分类按钮 - 显示剩余的排序分类
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                    // 显示电影角色分类按钮和其他剩余分类
                                    let movieCategory: CharacterCategory = .movieCharacter
                                            Button(action: {
                                                withAnimation(.easeInOut) {
                                            // 设置选中的分类
                                            selectedCategory = movieCategory
                                            
                                            // 重置特殊显示模式，但保持分类选择
                                            showingRecentInteractions = false
                                            showingFavorites = false
                                            
                                            // 打印调试信息
                                            print("选中分类: \(movieCategory.displayName)")
                                        }
                                    }) {
                                        categoryView(for: movieCategory)
                                    }
                                    
                                    // 显示其他剩余的排序分类（除了历史人物、文学家和电影角色）
                                    let otherCategories = sortedCategories.filter { 
                                        $0 != .historical && $0 != .writer && $0 != .movieCharacter 
                                    }
                                    ForEach(otherCategories, id: \.self) { category in
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                // 设置选中的分类
                                                    selectedCategory = category
                                                
                                                // 重置特殊显示模式，但保持分类选择
                                                showingRecentInteractions = false
                                                showingFavorites = false
                                                
                                                // 打印调试信息
                                                print("选中分类: \(category.displayName)")
                                                }
                                            }) {
                                                categoryView(for: category)
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
                            
                            // 选项卡视图 - 移到横线下方
                            HStack(spacing: 0) {
                                ForEach(TabType.allCases, id: \.self) { tab in
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            selectedTab = tab
                                            // 只有在非特殊模式下才重置显示模式
                                            // 保持最近互动和我的关注模式下的显示状态
                                            if !showingRecentInteractions && !showingFavorites {
                                                resetDisplayMode()
                                            }
                                        }
                                    }) {
                                        ZStack {
                                            if selectedTab == tab {
                                                Capsule()
                                                    .fill(Color(.systemGray6))
                                                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                                                    .frame(height: 28) // 减小高度
                                            }
                                            
                                            Text(tab.rawValue)
                                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular)) // 减小字号
                                                .foregroundColor(selectedTab == tab ? Color(.label) : Color(.systemGray2))
                                                .padding(.horizontal, 12) // 减小水平内边距
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 0)
                            .padding(.bottom, 1) // 减小底部间距，让选项卡更靠近卡片
                            
                            // 推荐角色 - 纵向网格布局
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
                                        .padding(.top, 0)
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
                                        .padding(.top, 0)
                                    }
                                } else if selectedCategory == .all {
                                    // 准备数据
                                    let characters = displayCharacters.prefix(12).map { $0 }
                                    
                                    // 角色卡片网格，不显示标题行
                                    LazyVGrid(
                                        columns: threeColumns,
                                        alignment: .center,
                                        spacing: 8 // 进一步减小卡片垂直间距
                                    ) {
                                        ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                                            improvedCharacterCard(for: character)
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .id(character.id) // 确保每个卡片有唯一ID
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 0) // 移除顶部间距
                                } else {
                                    // 删除分类标题，不再显示
                                    
                                    // 优化角色卡片网格
                                    LazyVGrid(
                                        columns: threeColumns,
                                        alignment: .center,
                                        spacing: 8 // 进一步减小卡片垂直间距
                                    ) {
                                        ForEach(Array(displayCharacters.enumerated()), id: \.element.id) { index, character in
                                            improvedCharacterCard(for: character)
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .id(character.id) // 确保每个卡片有唯一ID
                                        }
                                    }
                                    .padding(.horizontal, 16) // 与标题使用相同的水平内边距
                                    .padding(.top, 0) // 移除顶部间距
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
                .edgesIgnoringSafeArea(.all)
                
                // 添加一个透明视图，确保底部导航栏区域不被覆盖
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: tabBarManager.fullBottomAreaHeight)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .fullScreenCover(item: $navigateToChatView) { character in
            // 使用ZStack包装NavigationView，确保底部导航栏在整个导航过程中保持可见
            ZStack {
                // 使用NavigationView包装ChatView
                NavigationView {
                    ChatView(character: convertToChatCharacter(character))
                }
                .edgesIgnoringSafeArea(.all)
                
                // 添加一个透明视图，确保底部导航栏区域不被覆盖
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: tabBarManager.fullBottomAreaHeight)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .sheet(isPresented: $showingCreateCharacter) {
            NavigationView {
                CreateCharacterView(characters: $characters)
            }
        }
        .sheet(isPresented: $showingMyCharacters) {
            MyCharactersView(characters: $characters)
        }
        .onAppear {
            loadAllCharacters()
            loadRecentInteractions() // 加载最近互动数据
            loadFavoriteCharacters() // 加载关注列表
            // 确保TabBar可见
            tabBarManager.ensureTabBarVisible()
            
            // 添加通知监听，当收到关注状态变化通知时更新UI
            NotificationCenter.default.addObserver(forName: Notification.Name("FavoriteStatusChanged"), object: nil, queue: .main) { _ in
                // 收到通知后，重新加载关注列表
                self.loadFavoriteCharacters()
            }
        }
        .onDisappear {
            // 移除通知监听，避免内存泄漏
            NotificationCenter.default.removeObserver(self, name: Notification.Name("FavoriteStatusChanged"), object: nil)
        }
    }
    
    // 加载所有角色
    private func loadAllCharacters() {
        self.characters = CharacterModel.getAllCharacters()
        print("已加载 \(characters.count) 个角色")
    }
    
    // 创建改进的角色卡片视图
    private func improvedCharacterCard(for character: CharacterModel) -> some View {
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
    }
    
    /// 导航到角色详情页
    private func navigateToCharacterDetail(_ character: CharacterModel) {
        // 直接导航，不处理TabBar
        navigateToCharacterDetail = character
    }
    
    /// 导航到聊天页面
    private func navigateToCharacterChat(_ character: CharacterModel) {
        // 直接导航，不处理TabBar
        navigateToChatView = character
    }
    
    // 分类视图辅助方法
    private func categoryView(for category: CharacterCategory) -> some View {
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
        var result = characters
        
        // 如果是在"我的关注"模式下，只显示关注的角色
        if showingFavorites {
            result = result.filter { favoriteCharacters.contains($0.id) }
        }
        
        // 根据选项卡过滤
        switch selectedTab {
        case .all:
            // 保持所有角色
            break
        case .popular:
            // 模拟热门角色 - 这里可以根据实际数据添加排序逻辑
            // 在实际应用中，这可能是基于互动量、评分等的排序
            let shuffled = result.shuffled()
            result = Array(shuffled.prefix(min(shuffled.count, 20))).uniqued()
        case .recent:
            // 模拟最近角色 - 这里随机排序模拟
            // 在实际应用中，这可能是基于添加时间的排序
            let shuffled = result.shuffled()
            result = Array(shuffled.prefix(min(shuffled.count, 15))).uniqued()
        }
        
        // 根据分类过滤 - 确保正确使用selectedCategory
        if selectedCategory != .all {
            // 打印调试信息
            print("按分类过滤: \(selectedCategory.displayName), 过滤前数量: \(result.count)")
            result = result.filter { $0.category == selectedCategory }
            print("过滤后数量: \(result.count)")
            
            // 如果过滤后结果为空，可能是类别匹配问题，尝试打印所有角色的类别
            if result.isEmpty {
                let allCategories = Set(characters.map { $0.category })
                print("所有可用类别: \(allCategories.map { $0.displayName }.joined(separator: ", "))")
            }
        }
        
        // 根据时间轴过滤 - 保留时间轴筛选逻辑，但通过筛选按钮使用
        if let era = selectedEra {
            result = result.filter { $0.era.contains(era) }
        }
        
        // 根据搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                ($0.era.lowercased().contains(searchText.lowercased())) ||
                ($0.profession.lowercased().contains(searchText.lowercased())) ||
                ($0.bio.lowercased().contains(searchText.lowercased()))
            }
        }
        
        return result
    }
    
    /// 获取最近互动的角色列表
    private var recentInteractionCharacters: [CharacterModel] {
        // 获取所有互动过的角色ID
        let characterIds = recentInteractions.map { $0.characterId }
        
        // 根据互动记录获取角色对象，并按最近互动时间排序
        return characterIds
            .compactMap { id in characters.first { $0.id == id } }
            .uniqued() // 确保不重复
    }
    
    /// 获取我的关注角色列表
    private var favoriteCharactersList: [CharacterModel] {
        // 根据关注列表获取角色对象
        return favoriteCharacters
            .compactMap { id in characters.first { $0.id == id } }
    }
    
    /// 根据当前状态获取应该显示的角色
    private var displayCharacters: [CharacterModel] {
        if showingRecentInteractions {
            var result = recentInteractionCharacters
            
            // 在最近互动模式下也应用选项卡过滤
            switch selectedTab {
            case .all:
                // 保持所有最近互动角色
                break
            case .popular:
                // 按照互动类型筛选 - 优先展示点赞的角色
                let likedCharacterIds = recentInteractions
                    .filter { $0.interactionType == .like }
                    .map { $0.characterId }
                result = result.filter { likedCharacterIds.contains($0.id) }.uniqued()
            case .recent:
                // 按照互动时间排序 - 取最近7天的互动记录
                let recentDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let recentCharacterIds = recentInteractions
                    .filter { $0.timestamp >= recentDate }
                    .map { $0.characterId }
                result = result.filter { recentCharacterIds.contains($0.id) }.uniqued()
            }
            
            return result
        } else if showingFavorites {
            var result = favoriteCharactersList
            
            // 在我的关注模式下也应用选项卡过滤
            switch selectedTab {
            case .all:
                // 保持所有关注角色
                break
            case .popular:
                // 按照热门程度排序，这里使用followerCount或interactionCount作为热门指标
                // 由于这些属性在CharacterModel中可能不存在，我们可以使用随机排序模拟热门
                let shuffled = result.shuffled()
                // 确保结果是唯一的（不重复）
                result = shuffled.count > 10 ? Array(shuffled.prefix(10)).uniqued() : shuffled.uniqued()
            case .recent:
                // 可以按照最近关注时间排序，但目前没有存储关注时间
                // 这里可以使用最近互动记录来筛选
                let recentInteractionIds = recentInteractions
                    .prefix(20)
                    .map { $0.characterId }
                
                // 筛选出既在关注列表中又有最近互动的角色
                let recentFavorites = result.filter { character in
                    recentInteractionIds.contains(character.id)
                }
                
                // 如果有符合条件的角色，则使用这些角色，否则保持原样
                if !recentFavorites.isEmpty {
                    result = recentFavorites
                }
            }
            
            return result
        } else {
            return filteredCharacters
        }
    }
    
    // 处理查看全部事件
    private func handleViewAllTap() {
        // 查看全部角色
        selectedCategory = .all
        searchText = ""
    }
    
    // 处理创建角色事件
    private func handleCreateCharacter() {
        showingCreateCharacter = true
    }
    
    // 转换CharacterModel为Character（用于详情页）
    private func convertToCharacter(_ characterModel: CharacterModel) -> Character {
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
            isFavorited: favoriteCharacters.contains(characterModel.id)
        )
        return character
    }
    
    // 转换CharacterModel为CYChatCharacter（用于聊天页）
    private func convertToChatCharacter(_ characterModel: CharacterModel) -> CYChatCharacter {
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
        // 获取所有分类
        let allCategories = CharacterCategory.allCases.filter { $0 != .all }
        
        // 获取每个分类的角色数量
        var categoryCounts: [(category: CharacterCategory, count: Int)] = []
        for category in allCategories {
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
    private func addInteraction(for character: CharacterModel, type: CharacterInteraction.InteractionType) {
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
            // 更新现有记录
            recentInteractions[index] = newInteraction
        } else {
            // 添加新记录
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
    private func saveRecentInteractions() {
        if let data = try? JSONEncoder().encode(recentInteractions) {
            UserDefaults.standard.set(data, forKey: "recentInteractions")
        }
    }
    
    /// 从本地加载最近互动记录
    private func loadRecentInteractions() {
        if let data = UserDefaults.standard.data(forKey: "recentInteractions"),
           let interactions = try? JSONDecoder().decode([CharacterInteraction].self, from: data) {
            recentInteractions = interactions
        }
    }
    
    /// 处理最近互动按钮点击
    private func handleRecentInteractionsTap() {
        withAnimation(.easeInOut) {
            // 重置其他显示模式
            if showingFavorites {
                showingFavorites = false
            }
            
            showingRecentInteractions = true
            selectedCategory = .all
            // 不重置选项卡，允许在最近互动中使用选项卡筛选
        }
    }
    
    /// 处理我的关注点击
    private func handleFavoritesTap() {
        withAnimation(.easeInOut) {
            // 重置其他显示模式
            if showingRecentInteractions {
                showingRecentInteractions = false
            }
            
            // 切换到我的关注模式
                showingFavorites = true
            selectedCategory = .all
            // 不重置选项卡，允许在我的关注中使用选项卡筛选
        }
    }
    
    /// 重置显示模式
    private func resetDisplayMode() {
        withAnimation(.easeInOut) {
            showingRecentInteractions = false
            showingFavorites = false
            // 不重置分类选择，保持当前选中的分类
            // selectedCategory = .all
        }
    }
    
    /// 添加角色到关注列表
    private func toggleFavorite(for character: CharacterModel) {
        if favoriteCharacters.contains(character.id) {
            // 如果已经在关注列表中，则移除
            favoriteCharacters.removeAll { $0 == character.id }
            
            // 如果当前在我的关注页面并且关注列表为空，可能需要重置显示模式
            if showingFavorites && favoriteCharacters.isEmpty {
                // 可以选择添加一个小延迟，让动画效果更好
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        if favoriteCharactersList.isEmpty {
                            resetDisplayMode()
                        }
                    }
                }
            }
        } else {
            // 否则添加到关注列表
            favoriteCharacters.append(character.id)
        }
        
        // 保存关注列表
        saveFavoriteCharacters()
        
        // 发送通知，更新其他视图中的关注状态
        NotificationCenter.default.post(
            name: Notification.Name("FavoriteStatusChanged"), 
            object: nil,
            userInfo: ["characterId": character.id, "isFavorited": favoriteCharacters.contains(character.id)]
        )
    }
    
    /// 判断角色是否被关注
    private func isFavorite(_ character: CharacterModel) -> Bool {
        return favoriteCharacters.contains(character.id)
    }
    
    /// 保存关注列表到UserDefaults
    private func saveFavoriteCharacters() {
        if let encoded = try? JSONEncoder().encode(favoriteCharacters) {
            UserDefaults.standard.set(encoded, forKey: "favoriteCharacters")
        }
    }
    
    /// 从UserDefaults加载关注列表
    private func loadFavoriteCharacters() {
        if let savedFavorites = UserDefaults.standard.data(forKey: "favoriteCharacters"),
           let decoded = try? JSONDecoder().decode([String].self, from: savedFavorites) {
            favoriteCharacters = decoded
        }
    }
    
    /// 处理角色点赞
    private func handleCharacterLike(for character: CharacterModel) {
        // 添加点赞互动记录
        addInteraction(for: character, type: .like)
        
        // 这里可以添加点赞的网络请求等
        print("用户点赞了角色: \(character.name)")
    }
    
    /// 处理角色评论
    private func handleCharacterComment(for character: CharacterModel) {
        // 添加评论互动记录
        addInteraction(for: character, type: .comment)
        
        // 这里可以添加评论的网络请求等
        print("用户评论了角色: \(character.name)")
    }
    
    /// 处理角色聊天
    private func handleCharacterChat(for character: CharacterModel) {
        // 添加聊天互动记录
        addInteraction(for: character, type: .chat)
        
        // 导航到聊天页面
        navigateToCharacterChat(character)
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

#Preview("探索页面") {
    ExploreView()
} 

// 添加"我的角色"视图
struct MyCharactersView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var characters: [CharacterModel]
    @State private var userCharacters: [CharacterModel] = []
    @State private var showingCreateCharacter = false
    @State private var selectedCharacter: CharacterModel? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if userCharacters.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Text("您还没有创建角色")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("创建您自己的虚拟角色，与历史人物进行对话")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingCreateCharacter = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("创建角色")
                            }
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(userCharacters, id: \.id) { character in
                            CharacterRowView(character: character)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCharacter = character
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("我的角色", displayMode: .inline)
            .navigationBarItems(
                leading: Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    showingCreateCharacter = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingCreateCharacter) {
                // 使用相对路径引用CreateCharacterView
                CreateCharacterView(characters: $characters)
                    .onDisappear {
                        loadUserCharacters()
                    }
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let character = selectedCharacter {
                            CharacterDetailView(character: character)
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
            )
        }
        .onAppear {
            loadUserCharacters()
        }
    }
    
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
                        
                        let category = CharacterCategory(rawValue: categoryRawValue) ?? .fictionCharacter
                        let region = dict["region"] as? String ?? ""
                        
                        let character = CharacterModel(
                            id: id,
                            name: name,
                            avatar: avatar,
                            category: category,
                            era: era,
                            profession: profession,
                            bio: bio,
                            region: region
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
}

struct CharacterRowView: View {
    let character: CharacterModel
    
    var body: some View {
        HStack(spacing: 12) {
            // 角色头像
            if character.avatar == "default_avatar" {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
            } else {
                Image(character.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
            
            // 角色信息
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                
                Text(character.profession)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(character.era)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 类型标签
            Text(character.category.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(character.category.color.opacity(0.2))
                .foregroundColor(character.category.color)
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
} 