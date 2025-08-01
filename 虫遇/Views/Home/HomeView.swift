import SwiftUI
import SwiftData
import Combine
import UIKit

// 导入自定义组件
// 注意：CosmicGenerateButton是在项目内部定义的，不需要特殊导入

/**
 * 历史人物选择器视图
 * 用于全屏展示历史人物列表，并选择特定角色
 */
struct CharacterPickerView: View {
    let characters: [CharacterModel]
    @Binding var selectedCharacter: CharacterModel?
    @Binding var isPresented: Bool
    @State private var animateContent = false
    @State private var selectedCategory: CharacterCategory? = nil
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    
    // 根据角色类别分组
    private var categorizedCharacters: [CharacterCategory: [CharacterModel]] {
        Dictionary(grouping: characters) { $0.category }
    }
    
    // 所有类别
    private var categories: [CharacterCategory] {
        let result = categorizedCharacters.keys.sorted { $0.rawValue < $1.rawValue }
        return result
    }
    
    // 过滤后的角色
    private var filteredCharacters: [CharacterModel] {
        var result = characters
        
        // 按类别筛选
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.profession.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            // 背景遮罩 - 使用带模糊效果的背景
            Color.black.opacity(0.5)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        animateContent = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                        }
                    }
                }
            
            // 主内容区
            VStack(spacing: 0) {
                // 顶部栏
                HStack {
                    // 关闭按钮
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            animateContent = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.15))
                            )
                    }
                    
                    Spacer()
                    
                    // 标题
                    Text("虚拟角色")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    // 空白占位，保持对称
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    TextField("搜索历史人物", text: $searchText)
                        .font(.system(size: 15))
                        .padding(.vertical, 8)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // 分类标签栏
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 全部类别按钮
                        CategoryButton(
                            title: "全部",
                            isSelected: selectedCategory == nil,
                            color: .gray
                        ) {
                            withAnimation {
                                selectedCategory = nil
                            }
                        }
                        
                        // 其他类别按钮
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                color: category.color
                            ) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // 内容区域
                if filteredCharacters.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(searchText.isEmpty ? "没有找到相关角色" : "没有符合\"\(searchText)\"的搜索结果")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 40)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: animateContent)
                } else {
                    // 角色网格
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 100, maximum: 110), spacing: 12)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filteredCharacters) { character in
                                enhancedCharacterCell(character)
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0)
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.75)
                                        .delay(0.1 + Double(filteredCharacters.firstIndex(where: { $0.id == character.id }) ?? 0) * 0.03),
                                        value: animateContent
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .frame(height: UIScreen.main.bounds.height * 0.8)
            .offset(y: UIScreen.main.bounds.height * 0.1)
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.95)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animateContent)
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animateContent = true
                }
            }
        }
    }
    
    // 增强版角色单元格
    private func enhancedCharacterCell(_ character: CharacterModel) -> some View {
        Button(action: {
            selectedCharacter = character
            withAnimation(.easeOut(duration: 0.2)) {
                animateContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateContent = false
                }
            }
        }) {
            VStack(spacing: 8) {
                // 角色头像
                ZStack(alignment: .bottomTrailing) {
                    if let image = UIImage(named: character.avatar) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(character.category.color.opacity(0.6), lineWidth: 2)
                            )
                            .shadow(color: character.category.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(character.category.color.opacity(0.1))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text(String(character.name.prefix(1)))
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(character.category.color)
                            )
                            .overlay(
                                Circle().stroke(character.category.color.opacity(0.6), lineWidth: 2)
                            )
                    }
                    
                    // 热度指示器 (示例，实际应从模型中获取)
                    if ["爱因斯坦", "莎士比亚", "达芬奇"].contains(character.name) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color.orange.opacity(0.9))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .offset(x: 0, y: 0)
                    }
                }
                
                // 角色名称
                Text(character.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 角色时代或职业
                Text(character.profession)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // 类型标签
                Text(character.category.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(character.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(character.category.color.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(HomeScaleButtonStyle(scaleAmount: 0.97))
    }
}

/// 类别按钮组件
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 虚拟角色选择器视图
 * 用于全屏展示虚拟角色列表，包含分类筛选和搜索功能
 */
struct VirtualCharacterPickerView: View {
    // 上级视图传入的关闭方法
    let onDismiss: () -> Void
    // 选中角色后的回调
    let onSelectCharacter: (CharacterModel) -> Void
    
    // 状态变量
    @State private var searchText = ""
    @State private var selectedCategory: CharacterCategory? = .all
    @State private var animateContent = false
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 获取所有角色数据
    @State private var allCharacters: [CharacterModel] = []
    
    // 所有类别
    private var categories: [CharacterCategory] {
        // 定义固定的类别顺序
        let fixedCategoryOrder: [CharacterCategory] = [
            .all,           // 全部
            .historical,    // 历史人物
            .scientist,     // 科学家
            .philosopher,   // 哲学家
            .writer,        // 文学家
            .artist,        // 艺术家
            .mythCharacter, // 神话角色
            .movieCharacter, // 电影角色
            .tvCharacter,   // 电视剧角色
            .animeCharacter, // 动漫角色
            .gameCharacter, // 游戏角色
            .fictionCharacter, // 虚构人物
            .vtuber         // 虚拟主播
        ]
        
        // 从所有角色中提取唯一的类型
        var uniqueCategories = Set<CharacterCategory>()
        uniqueCategories.insert(.all) // 始终包含"全部"选项
        
        // 根据角色的类型添加对应的类别
        for character in allCharacters {
            uniqueCategories.insert(character.category)
        }
        
        // 按照固定顺序返回实际存在的类别
        return fixedCategoryOrder.filter { uniqueCategories.contains($0) }
    }
    
    // 过滤后的角色
    private var filteredCharacters: [CharacterModel] {
        var result = allCharacters
        
        // 按类别筛选
        if let category = selectedCategory, category != .all {
            result = result.filter { $0.category == category }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.profession.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 确保结果不为空
        if result.isEmpty && !allCharacters.isEmpty {
            // 如果筛选结果为空，返回所有角色中的前几个
            return Array(allCharacters.prefix(6))
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            // 添加可点击的背景层，用于关闭视图
            // 修改为Color.black.opacity(0.001)，保持可点击但几乎透明
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    print("背景点击 - 关闭角色选择器")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDismiss()
                    }
                }
                .zIndex(0) // 确保背景在最底层
            
            // 内容区域，使用Material背景
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack(spacing: 16) {
                    // 返回按钮
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onDismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 140/255, green: 105/255, blue: 158/255)) // 主色调紫色
                    }
                    .padding(.leading, 4)
                    
                    Spacer()
                    
                    // 标题
                    Text("角色库")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 占位区域
                    Color.clear
                        .frame(width: 33, height: 33)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    TextField("搜索历史人物", text: $searchText)
                        .font(.system(size: 15))
                        .padding(.vertical, 8)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // 类别选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                                    selectedCategory = category
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            }) {
                                Text(category.displayName)
                                    .font(.system(size: 14))
                                    .fontWeight(selectedCategory == category ? .medium : .regular)
                                    .foregroundColor(selectedCategory == category ? .white : category.color)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .frame(height: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(selectedCategory == category ? category.color : category.color.opacity(0.1))
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id("\(category.rawValue)_tab")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 12)
                
                // 角色总数显示
                HStack {
                    Text("共 \(filteredCharacters.count) 个角色")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                        .padding(.bottom, 8)
                    
                    Spacer()
                    
                    // 如果是筛选状态，显示"查看全部"按钮
                    if selectedCategory != .all || !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedCategory = .all
                                searchText = ""
                            }
                        }) {
                            Text("查看全部")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 16)
                    }
                }
                
                // 角色列表内容
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                    Spacer()
                } else if filteredCharacters.isEmpty {
                    Spacer()
                    Text("没有找到匹配的角色")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    // 使用新的ScrollView包装角色网格
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filteredCharacters, id: \.characterID) { character in
                                VirtualCharacterCard(character: character)
                                    .scaleEffect(animateContent ? 1 : 0.8)
                                    .opacity(animateContent ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedCategory)
                                    .transition(
                                        AnyTransition.opacity
                                            .combined(with: .scale(scale: 0.9))
                                            .animation(.spring(response: 0.4, dampingFraction: 0.7))
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .allowsHitTesting(true) // 确保ScrollView可点击
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20))
            // 添加阴影和内边距
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.vertical, 30)
            .padding(.horizontal, 10)
            // 确保内容区域捕获点击事件，但不传递到底层
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .allowsHitTesting(true)
            .zIndex(1) // 确保内容在背景之上
        }
        .zIndex(1000)
        .onAppear {
            // 确保TabBar在角色选择器显示时隐藏
            tabBarManager.hide()
            // 使用pushHideState确保TabBar被彻底隐藏
            tabBarManager.pushHideState()
            
            // 加载所有角色
            loadAllCharacters()
            
            // 动画显示内容
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animateContent = true
                }
            }
        }
        .onDisappear {
            // 不在onDisappear中恢复TabBar，而是让HomeView中的代码来控制
            // 这样可以避免在角色选择器消失时TabBar意外显示
            print("VirtualCharacterPickerView消失")
        }
    }
    
    private func loadAllCharacters() {
        isLoading = true
        
        // 使用CharacterModel的静态方法加载所有角色
        allCharacters = CharacterModel.getAllCharacters()
        isLoading = false
    }
}

struct VirtualCharacterCard: View {
    let character: CharacterModel
    @State private var isAppearing: Bool = false
    
    var body: some View {
        // 使用简单的NavigationLink，确保正常导航
        NavigationLink(destination: CharacterDetailView(character: convertToCharacter(character))) {
            VStack(spacing: 8) {
                // 角色头像
                ZStack {
                    Circle()
                        .fill(character.category.color.opacity(0.15))
                        .frame(width: 68, height: 68)
                    
                    // 使用统一的Avatar组件
                    Avatar(
                        url: character.characterID ?? character.name,
                        name: character.name,
                        category: character.category.displayName,
                        size: 60
                    )
                    
                    // 虚拟角色标记
                    if character.isVirtual {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Image(systemName: "bubble.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 24, y: -24)
                    }
                }
                .padding(.top, 4)
                
                // 角色名称
                Text(character.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                
                // 角色职业
                Text(character.profession)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                
                // 角色类型标签
                Text(character.category.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(character.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(character.category.color.opacity(0.1))
                    )
                    .padding(.bottom, 4)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .frame(minWidth: 0, maxWidth: .infinity) // 确保卡片填满可用宽度
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle()) // 使用PlainButtonStyle确保点击效果正常
        .contentShape(Rectangle()) // 确保整个卡片区域可点击
        .allowsHitTesting(true) // 明确允许点击事件
        .scaleEffect(isAppearing ? 1.0 : 0.92)
        .opacity(isAppearing ? 1.0 : 0.7)
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2), value: isAppearing)
        .onAppear {
            // 错开动画开始时间，创造波浪效果
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.05...0.3)) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isAppearing = true
                }
            }
            
            // 打印调试信息
            print("VirtualCharacterCard appeared: \(character.name)")
        }
        .onDisappear {
            // 重置状态以便下次显示
            withAnimation(.easeOut(duration: 0.2)) {
                isAppearing = false
            }
        }
        .onTapGesture {
            // 添加调试点击处理器
            print("Character card tapped: \(character.name)")
            // 注意：这个点击处理器不会被触发，因为NavigationLink会消耗点击事件
            // 但保留它作为调试目的
        }
    }
    
    // 转换CharacterModel为Character的辅助方法
    private func convertToCharacter(_ characterModel: CharacterModel) -> Character {
        return Character(
            id: characterModel.characterID ?? characterModel.name,
            name: characterModel.name,
            introduction: characterModel.bio,
            field: characterModel.profession,
            birthYear: characterModel.era,
            deathYear: nil,
            avatarUrl: characterModel.avatar,
            eraTag: characterModel.category.rawValue,
            achievements: characterModel.famousQuotes ?? [],
            mainWorks: [],
            keyThoughts: characterModel.famousQuotes ?? [],
            followerCount: 0,
            interactionCount: 0,
            rating: 4.5,
            createdAt: Date()
        )
    }
}

// 添加通知管理器类
class HomeViewNotificationManager: ObservableObject {
    private weak var postViewModel: PostViewModel?
    
    // 添加对象ID，便于区分不同实例
    private let instanceId = UUID().uuidString.prefix(8)
    
    init(postViewModel: PostViewModel) {
        self.postViewModel = postViewModel
        print("🔔 HomeViewNotificationManager[\(instanceId)]: 初始化完成，postViewModel设置成功")
        setupNotifications()
    }
    
    deinit {
        print("🔔 HomeViewNotificationManager[\(instanceId)]: 正在析构，移除所有观察者")
        // 移除通知观察者，防止内存泄漏
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        print("🔔 HomeViewNotificationManager[\(instanceId)]: 开始设置通知观察者")
        
        // 新帖子生成通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewPostsGenerated(_:)),
            name: NSNotification.Name("NewPostsGenerated"),
            object: nil
        )
        
        // 帖子更新通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostsUpdated(_:)),
            name: NSNotification.Name("PostsUpdated"),
            object: nil
        )
        
        print("🔔 HomeViewNotificationManager[\(instanceId)]: 通知观察者设置完成")
    }
    
    @objc private func handleNewPostsGenerated(_ notification: Notification) {
        print("🔔 HomeViewNotificationManager[\(instanceId)]: 接收到NewPostsGenerated通知")
        
        // 检查通知中是否包含数量信息
        var postsCount = 0
        if let count = notification.userInfo?["count"] as? Int {
            postsCount = count
            print("🔔 HomeViewNotificationManager[\(instanceId)]: 通知包含count数据: \(postsCount)个新帖子")
        } else {
            print("🔔 HomeViewNotificationManager[\(instanceId)]: 通知不包含count数据，使用默认值0")
        }
        
        // 检查发送者
        if let sender = notification.object {
            print("🔔 通知发送者: \(type(of: sender))")
        } else {
            print("🔔 通知发送者: nil")
        }
        
        // 检查postViewModel是否仍然有效
        if postViewModel == nil {
            print("⚠️ HomeViewNotificationManager[\(instanceId)]: 警告 - postViewModel已被释放")
        }
        
        DispatchQueue.main.async { [self] in
            print("🏠 HomeViewNotificationManager[\(self.instanceId)]: 正在主线程处理NewPostsGenerated通知")
            
            if let viewModel = self.postViewModel {
                print("🏠 HomeViewNotificationManager[\(self.instanceId)]: postViewModel依然有效，准备触发objectWillChange")
                viewModel.objectWillChange.send()
                print("🏠 HomeViewNotificationManager[\(self.instanceId)]: 已触发objectWillChange，当前帖子数量: \(viewModel.posts.count)")
                
                // 验证数据一致性
                if !viewModel.posts.isEmpty {
                    print("🏠 HomeViewNotificationManager[\(self.instanceId)]: 第一篇帖子内容片段: \(viewModel.posts[0].content.prefix(30))...")
                }
            } else {
                print("⚠️ HomeViewNotificationManager[\(self.instanceId)]: 严重错误 - 无法访问postViewModel")
            }
        }
    }
    
    @objc private func handlePostsUpdated(_ notification: Notification) {
        print("🔔 HomeViewNotificationManager[\(instanceId)]: 接收到PostsUpdated通知")
        
        // 检查通知中是否包含数量信息
        var postsCount = 0
        if let count = notification.userInfo?["newPostsCount"] as? Int {
            postsCount = count
            print("🔔 HomeViewNotificationManager[\(instanceId)]: 通知包含count数据: \(postsCount)个更新帖子")
        } else {
            print("🔔 HomeViewNotificationManager[\(instanceId)]: 通知不包含count数据，使用默认值0")
        }
        
        // 检查发送者
        if let sender = notification.object {
            print("🔔 通知发送者: \(type(of: sender))")
        } else {
            print("🔔 通知发送者: nil")
        }
        
        // 检查postViewModel是否仍然有效
        if postViewModel == nil {
            print("⚠️ HomeViewNotificationManager[\(instanceId)]: 警告 - postViewModel已被释放")
        }
        
        DispatchQueue.main.async { [self] in
            print("🏠 HomeViewNotificationManager[\(self.instanceId)]: 正在主线程处理PostsUpdated通知")
            
            if let viewModel = self.postViewModel {
                print("🏠 HomeViewNotificationManager[\(self.instanceId)]: postViewModel依然有效，准备触发objectWillChange")
                viewModel.objectWillChange.send()
                print("🏠 HomeViewNotificationManager[\(self.instanceId)]: 已触发objectWillChange，当前帖子数量: \(viewModel.posts.count)")
                
                // 验证数据一致性
                if !viewModel.posts.isEmpty {
                    print("🏠 HomeViewNotificationManager[\(self.instanceId)]: 第一篇帖子内容片段: \(viewModel.posts[0].content.prefix(30))...")
                }
            } else {
                print("⚠️ HomeViewNotificationManager[\(self.instanceId)]: 严重错误 - 无法访问postViewModel")
            }
        }
    }
}

/**
 * 主页按钮缩放样式
 * 用于主页上的按钮交互效果
 */
struct HomeScaleButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

/**
 * 首页视图
 * 显示历史人物角色和动态内容
 */
struct HomeView: View {
    // 添加场景状态环境变量
    @Environment(\.scenePhase) private var scenePhase
    
    /// 当前选中的标签
    @State private var selectedTab: HomeTab = .recommended
    /// 历史人物数据
    @State private var characters: [CharacterModel] = []
    /// 帖子数据
    @State private var posts: [PostModel] = []
    /// 使用共享的PostViewModel提供的用户帖子数据
    @ObservedObject private var postViewModel = PostViewModel.shared
    /// 为兼容现有代码，提供用户帖子的计算属性
    private var userPosts: [UserPostModel] {
        return postViewModel.posts
    }
    /// 评论相关状态
    @State private var commentText: String = ""
    @State private var replyingTo: DetailedCommentModel? = nil
    @State private var expandedPostID: UUID? = nil
    @State private var showCharacterSelector: Bool = false
    @State private var selectedPost: UserPostModel?
    /// 滚动位置
    @State private var scrollOffset: CGFloat = 0
    /// 是否显示顶部导航栏
    @State private var showNavBar: Bool = true
    /// 是否显示历史人物选择器
    @State private var showCharacterPicker: Bool = false {
        didSet {
            // 监听showCharacterPicker状态变化，确保TabBar状态正确
            if showCharacterPicker {
                // 显示角色选择器时隐藏TabBar
                tabBarManager.hide()
                // 使用pushHideState确保TabBar被彻底隐藏
                tabBarManager.pushHideState()
            } else {
                // 关闭角色选择器时立即显示TabBar
                tabBarManager.showImmediately()
            }
        }
    }
    /// 当前选中的历史人物
    @State private var selectedCharacter: CharacterModel? = nil
    /// 是否显示帖子详情
    @State private var showPostDetail: Bool = false
    /// 内容动画状态
    @State private var contentAppeared: Bool = false
    
    // 添加一个新的状态来存储顶部角色
    @State private var topCharacters: [CharacterModel] = []
    
    /// 首页标签类型
    enum HomeTab: String, CaseIterable {
        case recommended = "推荐"
        case following = "关注"
        case trending = "热门"
    }
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 通知管理器
    @StateObject private var notificationManager: HomeViewNotificationManager
    
    // 添加强制刷新状态
    @State private var forceRefreshID = UUID()
    
    // 添加存储subscribers的属性
    @State private var cancellables = Set<AnyCancellable>()
    
    // 添加一键生成帖子相关的状态变量
    @State private var showGenerateSuccess = false
    @State private var showGenerateError = false
    @State private var generateError = ""
    @State private var isGeneratingPosts = false
    @State private var generatePostsTask: Task<Void, Never>? = nil
    
    // 帖子操作相关
    @State private var editingPost: UserPostModel? = nil
    @State private var showEditPostView: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var postToDelete: UserPostModel? = nil
    
    // 移除原来的初始化方法，改用新的初始化器
    init() {
        // 使用 _notificationManager 直接初始化 @StateObject
        let manager = HomeViewNotificationManager(postViewModel: PostViewModel.shared)
        self._notificationManager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // 背景色 - 更加接近白色的淡色渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 255/255, green: 248/255, blue: 245/255),  // 极淡的暖白色
                        Color(red: 245/255, green: 248/255, blue: 255/255)   // 极淡的蓝白色
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false) // 背景不阻止点击事件
                
                // 主滚动视图
                ScrollView {
                    // 滚动偏移量监听 - 修改为不阻止点击事件
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: AppScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                            .allowsHitTesting(false) // 不阻止点击事件传递
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 0) {
                        // 顶部UI区域 - 集成导航栏和历史人物滚动区
                        VStack(spacing: 0) {
                            // 顶部导航栏
                            navBar
                                .opacity(showNavBar ? 1 : 0)
                                .offset(y: showNavBar ? 0 : -20)
                                .animation(.easeInOut(duration: 0.3), value: showNavBar)
                                .padding(.bottom, 8) // 调整间距
                                .contentShape(Rectangle()) // 确保整个区域可点击
                                .allowsHitTesting(true) // 明确允许点击事件
                            
                            // 历史人物横向滚动区 - 集成到顶部区域
                            ScrollViewReader { scrollProxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 25) {
                                        // 角色卡片 - 使用 topCharacters
                                        ForEach(topCharacters.prefix(5)) { character in
                                            characterCard(for: character)
                                                .id(character.id)
                                                .offset(y: contentAppeared ? 0 : 20)
                                                .opacity(contentAppeared ? 1 : 0)
                                                .animation(
                                                    .spring(response: 0.5, dampingFraction: 0.7)
                                                    .delay(Double(topCharacters.firstIndex(where: { $0.id == character.id }) ?? 0) * 0.05),
                                                    value: contentAppeared
                                                )
                                                .contentShape(Rectangle()) // 确保整个卡片可点击
                                                .allowsHitTesting(true) // 明确允许点击事件
                                        }
                                        
                                        // 查看全部按钮
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                showCharacterPicker = true
                                            }
                                        }) {
                                            VStack(spacing: 4) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(red: 220/255, green: 230/255, blue: 250/255))
                                                        .frame(width: 48, height: 48)
                                                    
                                                    Image(systemName: "ellipsis")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(Color(red: 80/255, green: 120/255, blue: 210/255))
                                                }
                                                
                                                Text("查看全部")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(red: 80/255, green: 100/255, blue: 180/255))
                                            }
                                            .frame(width: 50)
                                        }
                                        .offset(y: contentAppeared ? 0 : 20)
                                        .opacity(contentAppeared ? 1 : 0)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.7)
                                            .delay(0.3),
                                            value: contentAppeared
                                        )
                                        .contentShape(Rectangle()) // 确保按钮可点击
                                        .allowsHitTesting(true) // 明确允许点击事件
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                                .allowsHitTesting(true) // 明确允许ScrollView接收点击事件
                            }
                        }
                        .opacity(showNavBar ? 1 : 0)
                        .offset(y: showNavBar ? 0 : -20)
                        .animation(.easeInOut(duration: 0.3), value: showNavBar)
                        .contentShape(Rectangle()) // 确保整个顶部区域可点击
                        .allowsHitTesting(true) // 明确允许点击事件
                        
                        // 内容分类标签
                        tabSection
                        
                        // 内容区域
                        contentSection
                            .id(forceRefreshID) // 添加动态ID实现强制刷新
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(AppScrollOffsetPreferenceKey.self) { value in
                    withAnimation {
                        showNavBar = value < 50
                    }
                }
                .contentShape(Rectangle())
                .allowsHitTesting(true)
                
                // 添加一键生成内容按钮
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // 使用新的宇宙球体按钮，生成中保持位置不变
                        CosmicGenerateButton(isGenerating: $isGeneratingPosts, isHalfHidden: !isGeneratingPosts && !showGenerateError) {
                            // 添加震动反馈，使用统一的反馈管理器
                            HapticFeedback.medium()
                            
                            // 显示加载状态
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isGeneratingPosts = true
                            }
                            
                            // 取消之前可能存在的任务
                            generatePostsTask?.cancel()
                            
                            // 创建新任务并保存引用
                            generatePostsTask = Task {
                                // 使用ContentGeneratorService生成随机内容
                                await generateAndAddPosts()
                                
                                // 检查任务是否已取消，如果取消则不更新UI
                                if !Task.isCancelled {
                                    // 在主线程更新UI状态
                                    await MainActor.run {
                                        // 强制刷新视图
                                        forceRefreshID = UUID()
                                        
                                        // 成功生成时的触觉反馈
                                        HapticFeedback.success()
                                    }
                                }
                            }
                        }
                        .padding(.trailing, 0) // 靠近右边缘，不需要额外的padding
                        .padding(.bottom, 200) // 避免遮挡TabBar，并提高位置方便手指触及
                        .disabled(isGeneratingPosts) // 生成过程中禁用按钮
                    }
                }
                .allowsHitTesting(true) // 确保按钮可点击
                
                // 错误提示 - 从按钮区域移到屏幕中央，作为全局浮动提示
                if showGenerateError {
                    VStack {
                        Spacer()
                        
                        // 网络错误提示卡片 - 优化设计
                        HStack(spacing: 8) {
                            // 错误图标
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.95, green: 0.4, blue: 0.4))
                            
                            // 错误文本
                            Text(generateError.isEmpty ? "网络连接失败" : generateError)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground).opacity(0.9))
                                .background(
                                    .ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.95, green: 0.4, blue: 0.4).opacity(0.3), lineWidth: 0.5)
                        )
                        .frame(maxWidth: 280)
                        
                        Spacer()
                            .frame(height: 220) // 位置调整，确保在按钮上方显示
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showGenerateError)
                    .zIndex(1000) // 确保在最上层显示
                }
                
                // 历史人物选择器（全屏模态）
                if showCharacterPicker {
                    ZStack {
                        // 添加一个全屏黑色半透明背景，点击时关闭角色选择器
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    tabBarManager.popHideState()
                                    showCharacterPicker = false
                                }
                            }
                            .contentShape(Rectangle()) // 确保背景可点击
                            .allowsHitTesting(true) // 明确允许点击事件
                        
                        // 使用VirtualCharacterPickerView而不包装额外的修饰符
                        VirtualCharacterPickerView(
                            onDismiss: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    tabBarManager.popHideState()
                                    showCharacterPicker = false
                                }
                            },
                            onSelectCharacter: { character in
                                selectedCharacter = character
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    tabBarManager.popHideState()
                                    showCharacterPicker = false
                                }
                            }
                        )
                        .allowsHitTesting(true) // 确保角色选择器可点击
                    }
                    .transition(.opacity)
                    .zIndex(1000)
                    .onAppear {
                        // 确保TabBar在角色选择器显示时隐藏
                        tabBarManager.hide()
                    }
                }
            }
            .onAppear {
                // 更新顶部角色栏
                updateTopCharacters()

                // 确保数据存在
                postViewModel.ensureDataExists()
                
                // 在视图重新出现时添加延迟检查，防止切换回来显示空白
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // 二次确认数据存在并触发UI刷新
                    if postViewModel.posts.isEmpty {
                        postViewModel.posts = ModelData.samplePosts
                        // 生成新的刷新ID触发界面更新
                        forceRefreshID = UUID()
                    }
                }
                
                // 内容出现动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        contentAppeared = true
                    }
                }
                
                // 注册为publisher的订阅者，确保数据变化时能收到通知
                postViewModel.objectWillChange
                    .sink { _ in
                        // 强制刷新视图
                        forceRefreshID = UUID()
                    }
                    .store(in: &cancellables)
                
                // 添加定时刷新机制，确保UI显示最新数据
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 强制发出objectWillChange信号，确保视图刷新
                    forceRefreshID = UUID()
                }
            }
            .onDisappear {
                // 在视图消失时清理资源
                cancellables.removeAll()
                
                // 取消生成任务
                if let task = generatePostsTask {
                    task.cancel()
                    generatePostsTask = nil
                }
            }
            // 使用水平模态过渡代替全屏覆盖
            .fullscreenHorizontalModal(
                isPresented: Binding(
                    get: { selectedPost != nil },
                    set: { if !$0 { selectedPost = nil } }
                ),
                direction: .fromRight
            ) {
                if let post = selectedPost {
                    // 使用全屏沉浸式详情页
                    FullscreenPostDetailView(
                        post: post,
                        onDismiss: {
                            selectedPost = nil
                        },
                        onLike: { comment in
                            handleLikeComment(post: post, comment: comment)
                        },
                        onNextPost: { currentPostId in
                            // 查找当前帖子索引
                            let currentIndex = postViewModel.posts.firstIndex { $0.id.uuidString == currentPostId.uuidString }
                            
                            guard let safeIndex = currentIndex else {
                                return nil
                            }
                            
                            // 检查是否有下一篇帖子
                            let nextIndex = safeIndex + 1
                            if nextIndex < postViewModel.posts.count {
                                let nextPost = postViewModel.posts[nextIndex]
                                
                                // 确保不返回相同ID的帖子
                                if nextPost.id.uuidString == currentPostId.uuidString {
                                    // 尝试获取下下篇帖子
                                    if nextIndex + 1 < postViewModel.posts.count {
                                        let nextNextPost = postViewModel.posts[nextIndex + 1]
                                        return nextNextPost
                                    } else {
                                        return nil
                                    }
                                }
                                
                                return nextPost
                            } else {
                                return nil // 如果是最后一篇，返回nil
                            }
                        },
                        onPrevPost: { currentPostId in
                            // 查找当前帖子索引
                            let currentIndex = postViewModel.posts.firstIndex { $0.id.uuidString == currentPostId.uuidString }
                            
                            guard let safeIndex = currentIndex else {
                                return nil
                            }
                            
                            // 检查是否有上一篇帖子
                            if safeIndex > 0 {
                                let prevPost = postViewModel.posts[safeIndex - 1]
                                
                                // 确保不返回相同ID的帖子
                                if prevPost.id.uuidString == currentPostId.uuidString {
                                    // 尝试获取上上篇帖子
                                    if safeIndex - 2 >= 0 {
                                        let prevPrevPost = postViewModel.posts[safeIndex - 2]
                                        return prevPrevPost
                                    } else {
                                        return nil
                                    }
                                }
                                
                                return prevPost
                            } else {
                                return nil // 如果是第一篇，返回nil
                            }
                        }
                    )
                }
            }
        }
        // 移除调试按钮
        
        // 监听场景状态变化，优化性能
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // 应用进入前台，恢复数据加载
                if postViewModel.posts.isEmpty {
                    postViewModel.ensureDataExists()
                }
                
            case .inactive, .background:
                // 应用进入后台，取消正在进行的生成任务
                if isGeneratingPosts {
                    // 保存当前状态，在可能的情况下
                    generatePostsTask?.cancel()
                }
                
            @unknown default:
                break
            }
        }
        
        // 添加编辑帖子视图的sheet
        .sheet(item: $editingPost) { post in
            EditPostView(
                post: post,
                onClose: {
                    print("关闭编辑视图")
                    editingPost = nil
                },
                onUpdate: { newContent, newImages in
                    print("更新帖子内容，新内容长度: \(newContent.count), 图片数: \(newImages.count)")
                    updatePost(post, content: newContent, images: newImages)
                }
            )
            .presentationDetents([.height(550), .large])
            .onAppear {
                // 添加延迟，确保视图完全加载
                print("EditPostView 开始加载，帖子ID: \(post.id)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("EditPostView 已完全加载")
                }
            }
        }
        // 添加删除确认对话框
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {
                postToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let post = postToDelete {
                    deletePost(post)
                    postToDelete = nil
                }
            }
        } message: {
            Text("确认删除这条帖子吗？此操作不可撤销。")
        }
    }
    
    // MARK: - 导航栏
    private var navBar: some View {
        HStack {
            // 应用标题 - 简洁扁平风格
            Text("虫遇")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(red: 90/255, green: 120/255, blue: 190/255))
            
            // 应用副标题 - 轻量化设计
            Text("·穿越时空对话")
                .font(.system(size: 13, weight: .light))
                .foregroundColor(Color(red: 130/255, green: 150/255, blue: 200/255))
                .kerning(0.3)
                .offset(y: 1)
            
            Spacer()
            
            // 已移除编辑按钮
            // 已移除搜索按钮，使界面更加简洁
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 6)
        // 直接暴露在渐变背景中
    }
    
    // MARK: - 标签区域
    private var tabSection: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 2) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .medium : .regular))
                            .foregroundColor(selectedTab == tab ? Color(red: 80/255, green: 110/255, blue: 200/255) : Color(red: 150/255, green: 160/255, blue: 190/255))
                        
                        // 选中指示器 - 更微妙的设计
                        Rectangle()
                            .fill(selectedTab == tab ? Color(red: 80/255, green: 110/255, blue: 200/255) : Color.clear)
                            .frame(width: 16, height: 1.5)
                            .opacity(selectedTab == tab ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 0)
        .padding(.bottom, 0)
        // 直接暴露在渐变背景中
    }
    
    // MARK: - 内容区域
    private var contentSection: some View {
        ScrollView {
            // 使用LazyVStack提高性能
            LazyVStack(spacing: 0) {
                // 帖子列表
                ForEach(Array(postViewModel.posts.enumerated()), id: \.element.id) { index, post in
                    postCardView(for: post, at: index)
                        .id("\(post.id)_\(forceRefreshID)") // 在强制刷新时更新视图ID
                }
                .id("\(postViewModel.posts.count)_\(forceRefreshID)") // 当帖子数量变化或forceRefreshID变化时，整个ForEach会重新创建
                
                // 如果列表为空，显示加载提示
                if postViewModel.posts.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("正在加载内容...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                // 底部安全区域填充 - 使用极小值，避免多余的空白
                Color.clear
                    .frame(height: max(0, tabBarManager.fullBottomAreaHeight - (tabBarManager.bottomSafeAreaHeight)))
                    .id("bottomSpacer")
            }
            .padding(.vertical, 0) // 移除顶部内边距，与标签栏紧密连接
        }
        .refreshable {
            // 下拉刷新逻辑
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // 添加轻微延迟以提供更好的视觉反馈
            try? await Task.sleep(nanoseconds: 800_000_000)
            loadSampleData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostsUpdated"))) { _ in
            // 强制刷新视图
            self.forceRefreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewPostsGenerated"))) { _ in
            // 强制刷新视图
                self.forceRefreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewPostGenerated"))) { _ in
            // 单篇帖子生成时刷新视图
            self.forceRefreshID = UUID()
            
            // 如果列表滚动到顶部，确保新帖子可见
            if self.scrollOffset < 50 {
                // 轻微震动提示新帖子出现
                HapticFeedback.light()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewPostsGenerated"))) { notification in
            // 批量帖子生成时刷新视图
            self.forceRefreshID = UUID()
            
            // 如果列表滚动到顶部，确保新帖子可见
            if self.scrollOffset < 50 {
                // 轻微震动提示新帖子出现
                HapticFeedback.medium()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HomeViewShouldRefresh"))) { _ in
            // 如果帖子为空，则重新加载
            if postViewModel.posts.isEmpty {
                // 先尝试让 PostViewModel 恢复数据
                postViewModel.ensureDataExists()
                
                // 强制刷新 UI
                Task { @MainActor in
                    // 如果依然为空，直接加载示例数据
                    if postViewModel.posts.isEmpty {
                        postViewModel.posts = ModelData.samplePosts
                    }
                    
                    // 强制刷新UI
                self.forceRefreshID = UUID()
                }
            } else {
                // 仍然触发一次刷新，确保UI正确显示
                self.forceRefreshID = UUID()
            }
        }
        .ignoresSafeArea(.all, edges: .bottom) // 确保内容可以延伸到底部安全区域
        .edgesIgnoringSafeArea(.bottom) // 进一步确保内容延伸到底部边缘
    }
    
    // 提取单个帖子卡片为独立方法
    private func postCardView(for post: UserPostModel, at index: Int) -> some View {
        PostCardView(
            post: post,
            onPostTap: {
                // 查看帖子详情
                selectedPost = post
                showPostDetail = true
            },
            onLikeToggle: { isLiked in
                handlePostLike(post: post, isLiked: isLiked)
            },
            onCommentToggle: {
                handleCommentToggle(for: post)
            },
            onBookmarkToggle: { isBookmarked in
                handlePostBookmark(post: post, isBookmarked: isBookmarked)
            },
            onShare: {
                // 分享逻辑
                let content = "\(post.username)的虫遇动态: \(post.content)"
                shareContent(content)
                HapticFeedbackManager.shared.selectionChanged()
            },
            // 不指定maxPreviewLines和maxPreviewLength，使用PostCardView默认值
            // 这样列表页面也会使用相同的智能显示逻辑
            displayMode: .preview,
            // 根据帖子来源设置正确的postSource
            isOwnPost: post.source == "user",
            onEdit: {
                handleEditPost(post)
            },
            onDelete: {
                handleDeletePost(post)
            },
            onPin: { isPinned in
                handlePinPost(post, isPinned: isPinned)
            },
            postSource: post.source == "user" ? .userGenerated : .aiGenerated
        )
        .offset(y: contentAppeared ? 0 : 50)
        .opacity(contentAppeared ? 1 : 0)
        .animation(
            .easeOut(duration: 0.5)
            .delay(0.1 + Double(index % 5) * 0.05), // 使用取模避免延迟过长
            value: contentAppeared
        )
    }
    
    // 处理帖子点赞
    private func handlePostLike(post: UserPostModel, isLiked: Bool) {
        if let index = postViewModel.posts.firstIndex(where: { $0.id == post.id }) {
            var updatedPost = postViewModel.posts[index].toggleLike(isLiked: isLiked)
            updatedPost = updatedPost.updateLikes(delta: isLiked ? 1 : -1)
            postViewModel.posts[index] = updatedPost
        }
    }
    
    // 处理评论切换
    private func handleCommentToggle(for post: UserPostModel) {
        // 在首页中，评论按钮直接跳转到详情页
        selectedPost = post
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 显示帖子详情
        withAnimation(.easeOut(duration: 0.2)) {
            showPostDetail = true
        }
    }
    
    // 处理帖子收藏
    private func handlePostBookmark(post: UserPostModel, isBookmarked: Bool) {
        if let index = postViewModel.posts.firstIndex(where: { $0.id == post.id }) {
            postViewModel.posts[index] = postViewModel.posts[index].toggleBookmark(isBookmarked: isBookmarked)
        }
    }
    
    // MARK: - 历史人物邀请区域
    private var characterInvitationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题行
            HStack {
                Text("邀请历史人物点评")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 查看全部按钮
                Button(action: {
                    withAnimation {
                        showCharacterSelector.toggle()
                    }
                }) {
                    HStack {
                        Text("查看全部")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 历史人物列表 - 简化表达式
            charactersHorizontalList
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // 提取复杂的历史人物列表为单独的计算属性
    private var charactersHorizontalList: some View {
        // 精选历史人物头像列表
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                let displayedCharacters = characters.prefix(5)
                ForEach(Array(displayedCharacters), id: \.id) { character in
                    // 提取角色单元格为独立表达式
                    characterInviteCell(for: character)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // 提取每个角色单元格为单独的方法
    private func characterInviteCell(for character: CharacterModel) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                addVirtualCharacterComment(character: character)
            }
        }) {
            VStack(spacing: 6) {
                // 角色头像
                ZStack {
                    Circle()
                        .fill(character.category.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: character.category.icon)
                        .font(.system(size: 30))
                        .foregroundColor(character.category.color)
                }
                
                // 角色名称
                Text(character.name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - 评论输入栏
    private var commentInputBar: some View {
        HStack(alignment: .center, spacing: 10) {
            if replyingTo != nil {
                // 回复信息
                HStack {
                    Text("回复")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(replyingTo?.username ?? "")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Button(action: {
                        withAnimation {
                            replyingTo = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 评论文本框
            HStack {
                TextField("跨越时空的对话...", text: $commentText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        addUserComment()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(commentText.isEmpty ? .gray : .blue)
                        .padding(.trailing, 12)
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - 评论相关方法
    private func addUserComment() {
        guard !commentText.isEmpty, let post = selectedPost else { return }
        
        // 创建新评论
        let _ = DetailedCommentModel(
            username: "我",
            userAvatar: "person.circle.fill",
            content: commentText,
            datePosted: Date(),
            isVirtualCharacter: false,
            characterID: nil,
            likes: 0
        )
        
        // 更新帖子评论
        if let index = postViewModel.posts.firstIndex(where: { $0.id == post.id }) {
            postViewModel.posts[index].addComment(
                username: "我",
                userAvatar: "person.circle.fill",
                content: commentText,
                isVirtualCharacter: false,
                characterID: nil
            )
            selectedPost = postViewModel.posts[index]
        }
        
        // 重置评论状态
        commentText = ""
        replyingTo = nil
    }
    
    private func addVirtualCharacterComment(character: CharacterModel) {
        guard let post = selectedPost else { return }
        
        // 创建虚拟角色评论内容（实际应用中可通过AI生成）
        let contentMap: [String: String] = [
            "爱因斯坦": "从相对论的角度来看，时间确实是一个相对的概念。在高速运动的情况下，时间会变慢，这就是著名的钟慢效应。",
            "莎士比亚": "啊，时间！你是最伟大的魔术师，让一切都在你的魔法中流转。让我们珍惜每一刻，因为时间就像沙漏中的沙，一去不复返。",
            "达芬奇": "观察是艺术与科学的起点。通过细致的观察，我们能发现自然界中最美妙的规律。",
            "孔子": "学而不思则罔，思而不学则殆。我们应当在学习中思考，在思考中学习。"
        ]
        
        let content = contentMap[character.name] ?? "这是一条来自\(character.name)的虚拟评论，实际应用中应通过AI生成。"
        
        // 更新帖子评论
        if let index = postViewModel.posts.firstIndex(where: { $0.id == post.id }) {
            postViewModel.posts[index].addComment(
                username: character.name,
                userAvatar: character.avatar,
                content: content,
                isVirtualCharacter: true,
                characterID: "\(character.id)"
            )
            
            // 如果正在查看的是同一帖子，也更新 selectedPost
            selectedPost = postViewModel.posts[index]
        }
    }
    
    // MARK: - 评论功能
    
    /**
     * 添加评论
     */
    private func addComment(to post: UserPostModel, content: String, replyingTo replyID: UUID?) {
        // 验证评论内容
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        // 创建新评论
        let _ = DetailedCommentModel(
            username: "当前用户",  // 应该使用实际的当前用户名
            userAvatar: "person.circle.fill",  // 应该使用实际的当前用户头像
            content: trimmedContent,
            datePosted: Date(),
            isVirtualCharacter: false,
            characterID: nil,
            likes: 0
        )
        
        // 更新帖子的评论列表 - 使用帖子模型自带的 addComment 方法
        if let index = postViewModel.posts.firstIndex(where: { $0.id == post.id }) {
            // 如果是回复评论
            if let replyID = replyingTo {
                postViewModel.posts[index].addComment(
                    username: "当前用户",
                    userAvatar: "person.circle.fill",
                    content: trimmedContent,
                    parentCommentId: replyID.id,
                    replyToUsername: replyID.username // 使用被回复评论的用户名
                )
            } else {
                // 直接添加评论
                postViewModel.posts[index].addComment(
                    username: "当前用户",
                    userAvatar: "person.circle.fill",
                    content: trimmedContent
                )
            }
            
            // 如果正在查看的是同一帖子，也更新 selectedPost
            if selectedPost?.id == post.id {
                selectedPost = postViewModel.posts[index]
            }
        }
    }
    
    /**
     * 导航到下一个帖子
     */
    private func navigateToNextPost() {
        guard !postViewModel.posts.isEmpty else { return }
        
        let currentIndex = postViewModel.posts.firstIndex(where: { $0.id == selectedPost?.id }) ?? 0
        
        // 只有当不是最后一个帖子时才导航到下一个
        if currentIndex < postViewModel.posts.count - 1 {
            let nextIndex = currentIndex + 1
            selectedPost = postViewModel.posts[nextIndex]
        } else {
            // 已经是最后一个帖子，提供触觉反馈提示用户
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
            feedbackGenerator.impactOccurred(intensity: 0.5)
            
            // 可以选择添加一个视觉提示，表明已经到达最后一个帖子
            // 例如短暂显示一个提示文本或轻微的晃动动画
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                // 轻微的晃动效果
                let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
                var cancellable: AnyCancellable?
                var counter = 0
                
                cancellable = timer.sink { _ in
                    counter += 1
                    if counter >= 6 {
                        cancellable?.cancel()
                    }
                }
            }
        }
    }
    
    /**
     * 导航到上一个帖子
     */
    private func navigateToPreviousPost() {
        guard !postViewModel.posts.isEmpty else { return }
        
        let currentIndex = postViewModel.posts.firstIndex(where: { $0.id == selectedPost?.id }) ?? 0
        
        // 只有当不是第一个帖子时才导航到上一个
        if currentIndex > 0 {
            let previousIndex = currentIndex - 1
            selectedPost = postViewModel.posts[previousIndex]
        } else {
            // 已经是第一个帖子，使用触觉反馈提示用户
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
            feedbackGenerator.impactOccurred(intensity: 0.5)
            
            // 如果是第一个帖子，右滑可能会关闭详情页
            // 触发dismiss操作
            if selectedPost != nil {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedPost = nil
                }
            }
        }
    }
    
    /**
     * 处理评论点赞
     */
    private func handleLikeComment(post: UserPostModel, comment: DetailedCommentModel) {
        // 查找评论所属的帖子
        if let postIndex = postViewModel.posts.firstIndex(where: { $0.id == post.id }) {
            // 更新点赞状态
            postViewModel.posts[postIndex].likeComment(commentId: comment.id)
            
            // 如果是当前选中的帖子，也更新selectedPost
            if selectedPost?.id == post.id {
                selectedPost = postViewModel.posts[postIndex]
            }
        }
    }
    
    // MARK: - 数据加载
    private func loadSampleData() {
        print("📋 HomeView.loadSampleData: 开始加载示例数据")
        
        // 加载用户帖子 - 使用共享的PostViewModel
        // 检查是否已有帖子，如果没有才加载示例帖子
        print("📋 HomeView.loadSampleData: 当前帖子数量: \(postViewModel.posts.count)")
        
        if postViewModel.posts.isEmpty {
            print("📋 HomeView.loadSampleData: 帖子为空，加载示例帖子")
            postViewModel.posts = ModelData.samplePosts
            print("📋 HomeView.loadSampleData: 示例帖子加载完成，数量: \(postViewModel.posts.count)")
            
            // 打印所有帖子的ID和内容前缀，方便调试
            for (index, post) in postViewModel.posts.enumerated() {
                print("📋 HomeView.loadSampleData: 帖子[\(index)] ID = \(post.id), 内容 = \(post.content.prefix(30))...")
            }
        } else {
            print("📋 HomeView.loadSampleData: 已有帖子数据，跳过加载，当前数量: \(postViewModel.posts.count)")
        }
    }

    // 新增方法：更新顶部角色栏
    private func updateTopCharacters() {
        // 确保有一些模拟的互动数据
        ensureInteractionData()
        
        let sortedFollowed = postViewModel.getFollowedCharactersSortedByInteraction()
        
        if sortedFollowed.isEmpty {
            // 如果用户没有关注任何人或没有互动，显示默认推荐的角色
            self.topCharacters = Array(CharacterModel.sampleCharacters.prefix(5))
        } else {
            self.topCharacters = sortedFollowed
        }
    }
    
    // 确保有一些模拟的互动数据
    private func ensureInteractionData() {
        // 获取当前互动数据
        let interactionScores = UserInterestTracker.shared.interestModel.figureCounts
        
        // 如果没有任何互动数据，添加一些模拟数据
        if interactionScores.values.reduce(0, +) == 0 {
            print("📊 添加模拟的角色互动数据")
            
            // 模拟与几个角色的互动
            let characters = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "居里夫人", "福尔摩斯", "钢铁侠"]
            
            for character in characters {
                // 模拟不同类型的互动
                let interactionTypes: [UserInterestTracker.UserInterestModel.InteractionRecord.InteractionType] = [
                    .view, .like, .comment, .bookmark, .share
                ]
                
                // 为每个角色随机生成1-5次互动
                let interactionCount = Int.random(in: 1...5)
                for _ in 0..<interactionCount {
                    // 随机选择一种互动类型
                    if let interactionType = interactionTypes.randomElement() {
                        UserInterestTracker.shared.trackFigureInteraction(
                            figure: character,
                            interactionType: interactionType,
                            situation: "浏览首页",
                            expectation: "了解观点"
                        )
                    }
                }
            }
            
            print("📊 模拟互动数据添加完成")
        }
    }
    
    // MARK: - Helper Methods
    private func getPrimaryProfession(for character: CharacterModel) -> String {
        let professions = character.profession.components(separatedBy: CharacterSet(charactersIn: "，、"))
        return professions.first?.trimmingCharacters(in: .whitespaces) ?? character.profession
    }
    
    /**
     * 将 CharacterModel 转换为 Character
     */
    private func convertToCharacter(_ characterModel: CharacterModel) -> Character {
        return Character(
            id: characterModel.characterID ?? characterModel.name,
            name: characterModel.name,
            introduction: characterModel.bio,
            field: characterModel.profession,
            birthYear: characterModel.era,
            deathYear: nil,
            avatarUrl: characterModel.avatar,
            eraTag: characterModel.category.rawValue,
            achievements: characterModel.famousQuotes ?? [],
            mainWorks: [],
            keyThoughts: characterModel.famousQuotes ?? [],
            followerCount: 0,
            interactionCount: 0,
            rating: 4.5,
            createdAt: Date()
        )
    }

    // MARK: - Character Card View
    private func characterCard(for character: CharacterModel) -> some View {
        NavigationLink(destination: CharacterDetailView(character: convertToCharacter(character))) {
            VStack(spacing: 4) {
                // 头像部分 - 极简设计
                ZStack {
                    // 圆形背景，更浅的蓝色调，几乎不可见的边框
                    Circle()
                        .fill(Color(red: 240/255, green: 245/255, blue: 255/255))
                        .frame(width: 46, height: 46)
                    
                    // 使用Avatar组件加载头像，增大尺寸
                    Avatar(url: character.characterID ?? character.name, size: 42)
                        .frame(width: 42, height: 42)
                }
                
                // 人物名称
                Text(character.name)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 80/255, green: 100/255, blue: 180/255))
                    .frame(width: 48)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .tint(Color(red: 80/255, green: 100/255, blue: 180/255))
    }

    // 生成并添加帖子的方法
    /**
     * 生成并添加新帖子
     * 该方法使用ContentGeneratorService生成虫洞内容并添加到帖子列表
     */
    private func generateAndAddPosts() async {
        // 创建本地取消令牌集合，避免资源泄漏
        var localCancellables = Set<AnyCancellable>()
        
        print("🔄 HomeView: 开始生成多种类型帖子...")
        
        // 设置内容生成状态为生成中，防止权重被重置
        ContentTypeWeightManager.shared.setGeneratingContent(true)
        
        // 打印当前权重，确认是否正确
        ContentTypeWeightManager.shared.printAllWeights()
        
        do {
            // 使用ContentGeneratorService生成多种类型的内容
            print("📊 开始根据权重分配内容类型...")
            
            // 设置内容类型和总数量
            let contentTypes: [ContentGeneratorService.ContentType] = [
                .mood,            // 日常心情
                .ancient2modern,  // 古潮新语
                .creativeIdea,    // 穿越吐槽
                .timelineEvent    // 时空记事
            ]
            
            // 设置总帖子数量
            let totalPostCount = 12
            
            // 使用ContentTypeWeightManager根据权重分配每种类型的帖子数量
            let typeDistribution = ContentTypeWeightManager.shared.calculateTypeDistribution(
                totalCount: totalPostCount,
                types: contentTypes
            )
            
            // 打印分配情况和权重
            print("📊 内容类型分配结果:")
            for contentType in contentTypes {
                let weight = ContentTypeWeightManager.shared.getWeight(for: contentType)
                let count = typeDistribution[contentType] ?? 0
                print("  - \(contentType.rawValue): 权重=\(weight), 分配数量=\(count)")
            }
            
            // 为每种类型分别生成帖子和评论
            for contentType in contentTypes {
                // 获取当前类型分配的数量
                guard let typeCount = typeDistribution[contentType], typeCount > 0 else {
                    print("⏩ 跳过\(contentType.rawValue)类型，因为分配数量为0")
                    continue // 如果分配数量为0，跳过此类型
                }
                
                // 生成特定类型的帖子
                print("🌟 正在批量生成\(contentType.rawValue)类型的\(typeCount)篇帖子...")
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    // 使用批量生成方法，一次性生成所有指定类型的帖子
                    ContentGeneratorService.shared.generatePostsWithComments(
                        contentType: contentType,
                        count: typeCount,
                        topic: nil
                    )
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("❌ 生成\(contentType.rawValue)类型帖子失败: \(error.localizedDescription)")
                                continuation.resume(throwing: error)
                            } else {
                                print("✅ 完成\(contentType.rawValue)类型帖子的API请求")
                                continuation.resume(returning: ())
                            }
                        },
                        receiveValue: { results in
                            print("✅ 成功生成\(results.count)篇\(contentType.rawValue)类型帖子")
                            
                            // 将所有结果转换为UserPostModel
                            let posts = results.map { result -> UserPostModel in
                                // 将生成的内容和评论转换为UserPostModel
                                let post = self.postViewModel.convertContentItemToUserPost(result.contentItem)
                                
                                // 将CommentItem转换为DetailedCommentModel
                                var comments: [DetailedCommentModel] = result.comments.map { commentItem -> DetailedCommentModel in
                                    // 获取评论的基本信息
                                    let commentId = UUID(uuidString: commentItem.id) ?? UUID()
                                    
                                    // 检查是否是回复评论
                                    if commentItem.isReply {
                                        // 处理回复评论
                                        return DetailedCommentModel(
                                            id: commentId,
                                            username: commentItem.characterName,
                                            userAvatar: commentItem.characterAvatar != nil ? commentItem.characterAvatar! : "person.circle.fill",
                                            content: commentItem.content,
                                            datePosted: commentItem.timestamp,
                                            isVirtualCharacter: true,
                                            characterID: commentItem.characterId,
                                            parentCommentId: nil, // 暂时设为nil，后面会更新
                                            replyToUsername: self.findUsernameById(commentItem.parentCommentId!, in: result.comments), // 查找被回复者用户名
                                            likes: commentItem.likes,
                                            isLikedByCurrentUser: false
                                        )
                                    } else {
                                        // 处理普通评论
                                        return DetailedCommentModel(
                                            id: commentId,
                                            username: commentItem.characterName,
                                            userAvatar: commentItem.characterAvatar != nil ? commentItem.characterAvatar! : "person.circle.fill",
                                            content: commentItem.content,
                                            datePosted: commentItem.timestamp,
                                            isVirtualCharacter: true,
                                            characterID: commentItem.characterId,
                                            parentCommentId: nil,
                                            replyToUsername: nil,
                                            likes: commentItem.likes,
                                            isLikedByCurrentUser: false
                                        )
                                    }
                                }
                                
                                // 第二次遍历，处理回复评论的parentCommentId
                                for i in 0..<comments.count {
                                    if let replyToUsername = comments[i].replyToUsername {
                                        // 查找被回复评论的ID
                                        for j in 0..<comments.count {
                                            if comments[j].username == replyToUsername {
                                                comments[i].parentCommentId = comments[j].id
                                                break
                                            }
                                        }
                                    }
                                }
                                
                                // 确保评论能正确生成虚拟回复
                                for comment in comments {
                                    // 设置评论的虚拟角色标识，确保能正确触发虚拟回复逻辑
                                    if comment.isVirtualCharacter && comment.characterID != nil {
                                        // 记录虚拟角色已回复过该用户的状态
                                        if let replyToUsername = comment.replyToUsername {
                                            let userRepliedCharactersKey = "user_\(replyToUsername)_replied_characters"
                                            var repliedCharacters = UserDefaults.standard.stringArray(forKey: userRepliedCharactersKey) ?? []
                                            if !repliedCharacters.contains(comment.characterID!) {
                                                repliedCharacters.append(comment.characterID!)
                                                UserDefaults.standard.set(repliedCharacters, forKey: userRepliedCharactersKey)
                                            }
                                            
                                            // 如果是帖子作者回复，标记已回复
                                            if comment.username == post.username {
                                                for parentComment in comments {
                                                    if parentComment.username == replyToUsername {
                                                        let commentAuthorReplyKey = "author_replied_\(parentComment.id.uuidString)"
                                                        UserDefaults.standard.set(true, forKey: commentAuthorReplyKey)
                                                        break
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // 确保帖子中的评论也能正确显示嵌套关系
                                post.comments = comments
                                post.updateCommentRelationships()
                                
                                // 添加来源标记为"onekey"，确保一键生成的帖子能正确显示权重控制组件
                                post.source = "onekey"
                                
                                return post
                            }
                            
                            // 每生成一种类型的帖子就立即更新UI显示
                            Task { @MainActor in
                                // 将当前类型生成的帖子添加到视图模型的最前面
                                self.postViewModel.posts.insert(contentsOf: posts, at: 0)
                                
                                // 通知系统显示新内容
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("NewPostsGenerated"),
                                    object: nil
                                )
                                
                                // 强制刷新视图
                                self.forceRefreshID = UUID()
                                
                                print("🎉 UI更新完成，新增\(posts.count)篇\(contentType.rawValue)类型帖子")
                                
                                // 提供触觉反馈，表示新帖子已生成
                                HapticFeedback.light()
                            }
                        }
                    )
                    .store(in: &localCancellables)
                }
            }
            
            // 所有类型的帖子都生成完成后的最终处理
            await MainActor.run {
                // 生成状态设置为false
                self.isGeneratingPosts = false
                print("✅ 所有帖子生成完成，生成状态设置为false")
                
                // 内容生成完成，恢复权重管理器状态
                ContentTypeWeightManager.shared.setGeneratingContent(false)
                
                // 成功生成所有帖子的触觉反馈
                HapticFeedback.success()
                
                // 再次打印权重，确认没有被重置
                ContentTypeWeightManager.shared.printAllWeights()
            }
        } catch {
            print("❌ 生成帖子失败: \(error.localizedDescription)")
            
            // 在主线程处理错误
            await MainActor.run {
                // 网络错误处理 - 设置更友好的错误信息
                if let networkError = error as? URLError {
                    switch networkError.code {
                    case .notConnectedToInternet:
                        generateError = "网络连接已断开，请检查网络设置"
                    case .timedOut:
                        generateError = "请求超时，请稍后再试"
                    case .cannotConnectToHost:
                        generateError = "无法连接到服务器，请稍后再试"
                    default:
                        generateError = "网络错误: \(networkError.localizedDescription)"
                    }
                } else if let aiError = error as? AINetworkError {
                    // 自定义AI错误处理
                    switch aiError {
                    case .requestFailed:
                        generateError = "AI服务请求失败"
                    case .invalidResponse:
                        generateError = "AI服务返回无效响应"
                    default:
                        generateError = "AI服务错误: \(aiError.localizedDescription)"
                    }
                } else {
                    // 一般错误处理
                    generateError = error.localizedDescription
                }
                
                // 显示错误提示，但保持生成状态为true，以确保按钮保持显示
                withAnimation(.easeInOut(duration: 0.3)) {
                    showGenerateError = true
                }
                print("⚠️ 显示错误提示: \(generateError)")
                
                // 3秒后隐藏错误提示并重置生成状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    print("⏱️ 错误提示显示3秒后，开始隐藏错误并缩回按钮")
                    
                    // 先隐藏错误提示
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showGenerateError = false
                    }
                    
                    // 然后使用单独的动画设置isGeneratingPosts为false，使按钮缩回
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isGeneratingPosts = false
                            print("🔄 生成状态设置为false，按钮应开始缩回")
                        }
                    }
                }
                
                // 内容生成完成，恢复权重管理器状态
                ContentTypeWeightManager.shared.setGeneratingContent(false)
            }
        }
        
        // 清理本地取消令牌
        localCancellables.removeAll()
    }
    
    // 辅助函数：根据评论ID查找用户名
    private func findUsernameById(_ commentId: String, in comments: [CommentItem]) -> String? {
        return comments.first(where: { $0.id == commentId })?.characterName
    }
    
    // MARK: - 帖子操作方法
    
    // 处理编辑帖子
    private func handleEditPost(_ post: UserPostModel) {
        print("开始编辑帖子: \(post.id), 内容: \(post.content.prefix(20))...")
        
        // 直接设置要编辑的帖子，不再需要标志变量
        editingPost = post
        print("✅ 设置editingPost成功: \(post.id)")
        
        // 触发触觉反馈
        HapticFeedbackManager.shared.selectionChanged()
    }
    
    // 处理删除帖子
    private func handleDeletePost(_ post: UserPostModel) {
        postToDelete = post
        showDeleteConfirmation = true
        HapticFeedbackManager.shared.notifyWarning()
    }
    
    // 处理置顶帖子
    private func handlePinPost(_ post: UserPostModel, isPinned: Bool) {
        var pinnedPosts = UserDefaults.standard.stringArray(forKey: "PinnedPosts") ?? []
        
        if isPinned {
            // 确保不重复添加
            if !pinnedPosts.contains(post.id.uuidString) {
                pinnedPosts.append(post.id.uuidString)
            }
        } else {
            // 移除置顶
            pinnedPosts.removeAll { $0 == post.id.uuidString }
        }
        
        // 保存更新后的置顶帖子列表
        UserDefaults.standard.set(pinnedPosts, forKey: "PinnedPosts")
        
        // 为了在UI上立即反映变化，可以重新排序或强制刷新UI
        reorderPostsBasedOnPin()
        
        // 震动反馈
        HapticFeedbackManager.shared.notifySuccess()
    }
    
    // 更新帖子内容
    private func updatePost(_ post: UserPostModel, content: String, images: [UIImage]) {
        guard let index = postViewModel.posts.firstIndex(where: { $0.id == post.id }) else {
            return
        }
        
        // 保存新图片并获取图片ID
        var imageIdentifiers: [String] = []
        for (i, image) in images.enumerated() {
            // 生成唯一图片标识符
            let imageId = "\(post.id)_updated_image_\(i)"
            
            // 保存图片到本地存储或云存储
            if ImageManager.shared.saveImage(image, withId: imageId) {
                imageIdentifiers.append(imageId)
            }
        }
        
        // 创建更新后的帖子对象
        let updatedPost = UserPostModel(
            id: post.id,
            username: post.username,
            userAvatar: post.userAvatar,
            content: content,
            images: imageIdentifiers,
            datePosted: post.datePosted,
            likes: post.likes,
            comments: post.comments,
            isLikedByCurrentUser: post.isLikedByCurrentUser,
            isBookmarkedByCurrentUser: post.isBookmarkedByCurrentUser,
            contentType: post.contentType,
            characterID: post.characterID,
            source: post.source
        )
        
        // 更新模型
        postViewModel.posts[index] = updatedPost
        
        // 如果正在查看的是同一帖子，也更新selectedPost
        if selectedPost?.id == post.id {
            selectedPost = updatedPost
        }
        
        // 强制刷新UI
        forceRefreshID = UUID()
        
        // 显示成功提示
        ToastManager.shared.showToast(message: "帖子已更新")
        
        // 震动反馈
        HapticFeedbackManager.shared.notifySuccess()
    }
    
    // 删除帖子
    private func deletePost(_ post: UserPostModel) {
        // 从模型中删除帖子
        postViewModel.posts.removeAll { $0.id == post.id }
        
        // 如果正在查看的是被删除的帖子，关闭详情视图
        if selectedPost?.id == post.id {
            selectedPost = nil
        }
        
        // 强制刷新UI
        forceRefreshID = UUID()
        
        // 显示成功提示
        ToastManager.shared.showToast(message: "帖子已删除")
        
        // 震动反馈
        HapticFeedbackManager.shared.notifySuccess()
        
        // 如果帖子是置顶的，也从置顶列表中移除
        var pinnedPosts = UserDefaults.standard.stringArray(forKey: "PinnedPosts") ?? []
        pinnedPosts.removeAll { $0 == post.id.uuidString }
        UserDefaults.standard.set(pinnedPosts, forKey: "PinnedPosts")
    }
    
    // 根据置顶状态重新排序帖子
    private func reorderPostsBasedOnPin() {
        let pinnedPosts = UserDefaults.standard.stringArray(forKey: "PinnedPosts") ?? []
        
        // 将帖子分为置顶和非置顶两组
        var pinnedItems: [UserPostModel] = []
        var unpinnedItems: [UserPostModel] = []
        
        for post in postViewModel.posts {
            if pinnedPosts.contains(post.id.uuidString) {
                pinnedItems.append(post)
            } else {
                unpinnedItems.append(post)
            }
        }
        
        // 将置顶帖子按时间排序
        pinnedItems.sort { $0.datePosted > $1.datePosted }
        
        // 将非置顶帖子按时间排序
        unpinnedItems.sort { $0.datePosted > $1.datePosted }
        
        // 合并两组帖子
        postViewModel.posts = pinnedItems + unpinnedItems
        
        // 强制刷新UI
        forceRefreshID = UUID()
    }
    
    // 分享内容
    private func shareContent(_ content: String) {
        // 创建分享项
        let items: [Any] = [content]
        
        // 创建活动视图控制器
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // 获取当前窗口场景和根视图控制器
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // 在iPad上设置popover源视图
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // 显示分享菜单
            rootViewController.present(activityVC, animated: true)
        }
    }
}

#Preview("首页") {
    HomeView()
} 

// 创建环境键，用于传递是否返回角色选择器的状态
private struct ReturnToCharacterPickerKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var returnToCharacterPicker: Bool {
        get { self[ReturnToCharacterPickerKey.self] }
        set { self[ReturnToCharacterPickerKey.self] = newValue }
    }
}
