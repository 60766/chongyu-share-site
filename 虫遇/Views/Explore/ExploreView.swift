import SwiftUI
import SwiftData
// CreateCharacterView位于：Views/Components/Character/CreateCharacterView.swift
import Foundation

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
    @State private var characters: [CharacterModel] = CharacterModel.sampleCharacters
    /// 滚动偏移量
    @State private var scrollOffset: CGFloat = 0
    /// 选中的时间轴时期
    @State private var selectedEra: String? = nil
    /// 是否显示创建角色视图
    @State private var showingCreateCharacter = false
    
    // 时间轴数据
    private let timeEras = [
        "古代", "中世纪", "文艺复兴", "启蒙运动", "工业革命", "现代", "当代"
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景色 - 使用微妙的渐变增加空间感
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 246/255, green: 248/255, blue: 252/255),
                    Color(red: 250/255, green: 250/255, blue: 252/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 主内容区
            VStack(spacing: 0) {
                // 顶部区域：标题和搜索栏
                VStack(spacing: 0) {
                    HStack {
                        Text("虫遇")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primaryColor)
                            .tracking(-0.5) // 紧凑排版
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // 搜索栏 - 优化视觉层次感
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 17))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.leading, 4)
                            
                            TextField("搜索时空旅行者...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .padding(.vertical, 10)
                        }
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        
                        // 筛选按钮 - 使用与App风格一致的设计语言
                        Button(action: {
                            // 筛选功能
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                                
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryColor)
                            }
                            .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(Color.white.opacity(scrollOffset > 20 ? 1 : 0))
                .shadow(color: Color.black.opacity(scrollOffset > 20 ? 0.05 : 0), radius: 8, x: 0, y: 4)
                .zIndex(1)
                
                // 内容区
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            // 历史时间轴 - 新增元素，强化时空概念
                            VStack(alignment: .leading, spacing: 12) {
                                Text("历史时间轴")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(timeEras, id: \.self) { era in
                                            Button(action: {
                                                withAnimation(.easeInOut) {
                                                    selectedEra = selectedEra == era ? nil : era
                                                }
                                            }) {
                                                Text(era)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(selectedEra == era ? 
                                                                  Color.primaryColor : 
                                                                  Color.white)
                                                    )
                                                    .foregroundColor(selectedEra == era ? .white : .primary)
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                                    )
                                                    .shadow(color: Color.black.opacity(selectedEra == era ? 0.1 : 0.03), 
                                                            radius: 4, x: 0, y: 2)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 4)
                                }
                            }
                            .padding(.top, 8)
                            
                            // 分类筛选
                            VStack(alignment: .leading, spacing: 12) {
                                Text("按类型探索")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                
                                // 分类选择器 - 增强视觉吸引力
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(CharacterCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                            Button(action: {
                                                withAnimation(.easeInOut) {
                                                    selectedCategory = category
                                                }
                                            }) {
                                                VStack(spacing: 8) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(category.color.opacity(selectedCategory == category ? 1.0 : 0.15))
                                                            .frame(width: 60, height: 60)
                                                        
                                                        Image(systemName: category.icon)
                                                            .font(.system(size: 24))
                                                            .foregroundColor(selectedCategory == category ? .white : category.color)
                                                    }
                                                    .shadow(color: category.color.opacity(selectedCategory == category ? 0.3 : 0), 
                                                            radius: 8, x: 0, y: 4)
                                                    
                                                    Text(category.displayName)
                                                        .font(.system(size: 14))
                                                        .foregroundColor(selectedCategory == category ? .primary : .secondary)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // 推荐角色 - 平铺网格布局
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    if selectedCategory == .all {
                                        Text("推荐角色")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("\(selectedCategory.displayName)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    // 创建角色按钮
                                    Button(action: {
                                        showingCreateCharacter = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 14))
                                            Text("创建角色")
                                                .font(.system(size: 14))
                                        }
                                        .foregroundColor(.primaryColor)
                                    }
                                    .padding(.trailing, 10)
                                    
                                    Button(action: {
                                        // 查看全部
                                    }) {
                                        Text("查看全部")
                                            .font(.system(size: 14))
                                            .foregroundColor(.primaryColor)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // 优化角色卡片网格
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ],
                                    spacing: 20
                                ) {
                                    ForEach(filteredCharacters) { character in
                                        improvedCharacterCard(for: character)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // 底部间距
                            Color.clear.frame(height: 20)
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
    }
    
    // 优化的角色卡片
    private func improvedCharacterCard(for character: CharacterModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 角色头像区域
            ZStack(alignment: .bottomLeading) {
                // 角色图像
                if UIImage(named: character.avatar) != nil {
                    Image(character.avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .appCornerRadius(16, corners: [.topLeft, .topRight])
                } else {
                    // 占位图 - 使用更有设计感的渐变
                    LinearGradient(
                        gradient: Gradient(colors: [
                            character.category.color.opacity(0.7),
                            character.category.color.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 180)
                    .appCornerRadius(16, corners: [.topLeft, .topRight])
                    .overlay(
                        Image(systemName: character.category.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                    )
                }
                
                // 角色年代标签 - 增强时空感
                HStack(spacing: 4) {
                    Text(character.era)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                                .blur(radius: 0.5)
                        )
                }
                .padding(12)
                
                // 角色分类标签 - 右上角
                Text(character.category.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(character.category.color)
                    .cornerRadius(12)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            
            // 角色信息区域
            VStack(alignment: .leading, spacing: 8) {
                // 角色名称
                Text(character.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                // 职业标签
                Text(character.profession)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                // 角色简介
                Text(character.bio)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
                
                // 互动按钮
                HStack(spacing: 12) {
                    // 对话按钮
                    Button(action: {
                        // 开始对话
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 12))
                            
                            Text("对话")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(character.category.color)
                        .cornerRadius(16)
                    }
                    
                    // 资料按钮
                    Button(action: {
                        // 查看资料
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                            
                            Text("资料")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(character.category.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(character.category.color.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    // 收藏按钮
                    Button(action: {
                        // 收藏角色
                    }) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 6)
            }
            .padding(16)
            .background(Color.white)
            .appCornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle()) // 确保整个卡片都可点击
        .onTapGesture {
            // 点击角色卡片的操作 - 查看详情
        }
    }
    
    /// 根据分类、时间轴和搜索文本过滤角色
    private var filteredCharacters: [CharacterModel] {
        var result = characters
        
        // 根据分类过滤
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 根据时间轴过滤
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
}

#Preview("探索页面") {
    ExploreView()
} 