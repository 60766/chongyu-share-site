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
    
    // 时间轴数据
    private let timeEras = [
        "古代", "中世纪", "文艺复兴", "启蒙运动", "工业革命", "现代", "当代"
    ]
    
    // 定义三列网格布局
    private let threeColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // 导航状态
    @State private var navigateToCharacterDetail: CharacterModel? = nil
    @State private var navigateToChatView: CharacterModel? = nil

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
                                .foregroundColor(Color(.systemGray))
                                .padding(.leading, 8)
                            
                            TextField("搜索时空旅行者...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.05), lineWidth: 0.5)
                        )
                        
                        // 筛选按钮 - 使用与App风格一致的设计语言
                        Button(action: {
                            // 筛选功能
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primaryColor)
                            }
                            .frame(width: 36, height: 36)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .background(Color.white.opacity(scrollOffset > 20 ? 1 : 0))
                .shadow(color: Color.black.opacity(scrollOffset > 20 ? 0.05 : 0), radius: 6, x: 0, y: 3)
                .zIndex(1)
                
                // 内容区
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) { // 调整主要板块间距
                            // 分类筛选
                            VStack(alignment: .leading, spacing: 12) {
                                // 分类选择器 - 改为网格布局
                                // 先获取筛选后的分类列表
                                let categories = CharacterCategory.allCases.filter { $0 != .all }
                                
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)
                                    ],
                                    spacing: 20
                                ) {
                                    // 使用预先筛选的列表
                                    ForEach(categories, id: \.self) { category in
                                            Button(action: {
                                                withAnimation(.easeInOut) {
                                                    selectedCategory = category
                                                }
                                            }) {
                                            categoryView(for: category)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 6)
                            
                            // 选项卡视图
                            HStack(spacing: 0) {
                                ForEach(TabType.allCases, id: \.self) { tab in
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            selectedTab = tab
                                        }
                                    }) {
                                        ZStack {
                                            if selectedTab == tab {
                                                Capsule()
                                                    .fill(Color(.systemGray6))
                                                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                                                    .frame(height: 32)
                                            }
                                            
                                            Text(tab.rawValue)
                                                .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .regular))
                                                .foregroundColor(selectedTab == tab ? Color(.label) : Color(.systemGray2))
                                                .padding(.horizontal, 16)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                            
                            // 视觉分隔线
                            Rectangle()
                                .fill(Color(.systemGray5).opacity(0.5))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                            
                            // 推荐角色 - 纵向网格布局
                            VStack(alignment: .leading, spacing: 0) {
                                if selectedCategory == .all {
                                    // 准备数据
                                    let displayCharacters = filteredCharacters.prefix(12).map { $0 }
                                    let titleText = selectedCategory == .all ? "全部角色" : selectedCategory.displayName
                                    
                                    // 使用新的推荐角色组件
                                    RecommendedCharactersView(
                                        characters: displayCharacters,
                                        titleText: titleText,
                                        onCharacterTap: navigateToCharacterDetail,
                                        onCharacterChatTap: navigateToCharacterChat,
                                        onViewAllTap: handleViewAllTap,
                                        onCreateTap: handleCreateCharacter
                                    )
                                } else {
                                    // 分类标题
                                    Text(selectedCategory.displayName)
                                        .font(.system(size: 15, weight: .medium)) // 字体保持小一点
                                        .foregroundColor(Color(.label)) // 恢复原来的颜色
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 8)
                                    
                                    // 优化角色卡片网格
                                    LazyVGrid(
                                        columns: threeColumns,
                                        spacing: 12 // 增加卡片垂直间距
                                    ) {
                                        ForEach(filteredCharacters) { character in
                                            improvedCharacterCard(for: character)
                                        }
                                    }
                                    .padding(.horizontal, 16) // 与标题使用相同的水平内边距
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
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showingCreateCharacter) {
            NavigationView {
                CreateCharacterView(characters: $characters)
            }
        }
        .onAppear {
            loadAllCharacters()
            // 确保TabBar可见
            tabBarManager.ensureTabBarVisible()
        }
        // 添加导航链接 - 使用全屏覆盖而不是sheet
        .fullScreenCover(item: $navigateToCharacterDetail) { character in
            NavigationView {
                CharacterDetailView(character: convertToCharacter(character))
            }
            .onDisappear {
                // 强制重置并显示TabBar，确保返回时TabBar可见
                tabBarManager.forceResetAndShow()
            }
        }
        .fullScreenCover(item: $navigateToChatView) { character in
            NavigationView {
                ChatView(character: convertToChatCharacter(character))
            }
            .onDisappear {
                // 强制重置并显示TabBar，确保返回时TabBar可见
                tabBarManager.forceResetAndShow()
            }
        }
    }
    
    // 加载所有角色
    private func loadAllCharacters() {
        self.characters = CharacterModel.getAllCharacters()
        print("已加载 \(characters.count) 个角色")
    }
    
    // 优化的角色卡片
    private func improvedCharacterCard(for character: CharacterModel) -> some View {
        ImprovedCharacterCardView(
            character: character,
            onTap: { navigateToCharacterDetail(character) }, // 点击图片进入角色详情页
            onChatTap: { navigateToCharacterChat(character) } // 点击底部按钮进入聊天页
        )
        .contentShape(Rectangle())
    }
    
    // 导航到角色详情页
    private func navigateToCharacterDetail(_ character: CharacterModel) {
        // 先隐藏TabBar，然后再导航
        tabBarManager.pushHideState()
        navigateToCharacterDetail = character
    }
    
    // 导航到聊天页面
    private func navigateToCharacterChat(_ character: CharacterModel) {
        // 先隐藏TabBar，然后再导航
        tabBarManager.pushHideState()
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
                color: category.color.opacity(selectedCategory == category ? 0.3 : 0), 
                radius: 6,
                x: 0,
                y: 3
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
        
        // 根据选项卡过滤
        switch selectedTab {
        case .all:
            // 保持所有角色
            break
        case .popular:
            // 模拟热门角色 - 这里可以根据实际数据添加排序逻辑
            // 在实际应用中，这可能是基于互动量、评分等的排序
            let shuffled = result.shuffled()
            result = Array(shuffled.prefix(min(shuffled.count, 20)))
        case .recent:
            // 模拟最近角色 - 这里随机排序模拟
            // 在实际应用中，这可能是基于添加时间的排序
            let shuffled = result.shuffled()
            result = Array(shuffled.prefix(min(shuffled.count, 15)))
        }
        
        // 根据分类过滤
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
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
            rating: Double.random(in: 4.0...5.0)
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
}

#Preview("探索页面") {
    ExploreView()
} 