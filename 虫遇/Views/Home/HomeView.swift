import SwiftUI
import SwiftData
import Combine

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
                    isPresented = false
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
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.97))
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
    
    // 获取示例数据 - 实际项目应从后端获取
    private let allCharacters = CharacterModel.sampleCharacters // 修复: 使用sampleCharacters而不是historicalCharacters
    
    // 根据角色类别分组
    private var categorizedCharacters: [CharacterCategory: [CharacterModel]] {
        Dictionary(grouping: allCharacters) { $0.category }
    }
    
    // 所有类别
    private var categories: [CharacterCategory] {
        CharacterCategory.allCases
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
        
        return result
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 顶部关闭按钮和标题
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6).opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Text("虚拟角色")
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 40, height: 40)
                        .padding(.trailing, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    
                    TextField("搜索历史人物", text: $searchText)
                        .padding(8)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)
                        }
                    }
                }
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(15)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // 分类标签栏
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                color: category.color
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category == selectedCategory ? nil : category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                
                // 角色列表区域
                if filteredCharacters.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text("没有符合\"\(searchText)\"的搜索结果")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 40)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(filteredCharacters) { character in
                                VirtualCharacterCard(character: character) // 修改为使用不同的卡片组件名称
                                    .onTapGesture {
                                        onSelectCharacter(character)
                                        onDismiss()
                                    }
                                    .offset(y: animateContent ? 0 : 20)
                                    .opacity(animateContent ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(filteredCharacters.firstIndex(where: { $0.id == character.id }) ?? 0) * 0.03),
                                        value: animateContent
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onAppear {
            // 延迟一小段时间再显示内容，增加动画效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateContent = true
            }
        }
    }
}

/**
 * 虚拟角色卡片视图 - 改名以避免冲突
 */
struct VirtualCharacterCard: View {
    let character: CharacterModel
    
    var body: some View {
        VStack(spacing: 8) {
            // 角色头像
            ZStack {
                Circle()
                    .fill(character.category.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                if UIImage(named: character.avatar) != nil {
                    Image(character.avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                } else {
                    Text(character.name.prefix(1))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(character.category.color)
                }
                
                // 未来可添加消息提示标记
                if character.isVirtual {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "bubble.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 32, y: -32)
                }
            }
            
            // 角色名称
            Text(character.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // 角色分类/职业标签
            Text(character.profession)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(height: 16)
            
            // 类型标签
            Text(character.category.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(character.category.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(character.category.color.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

/**
 * 首页视图
 * 显示历史人物角色和动态内容
 */
struct HomeView: View {
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
    @State private var replyingTo: UserCommentModel? = nil
    @State private var expandedPostID: UUID? = nil
    @State private var showCharacterSelector: Bool = false
    @State private var selectedPost: UserPostModel?
    /// 滚动位置
    @State private var scrollOffset: CGFloat = 0
    /// 是否显示顶部导航栏
    @State private var showNavBar: Bool = true
    /// 是否显示历史人物选择器
    @State private var showCharacterPicker: Bool = false
    /// 当前选中的历史人物
    @State private var selectedCharacter: CharacterModel? = nil
    /// 是否显示帖子详情
    @State private var showPostDetail: Bool = false
    /// 内容动画状态
    @State private var contentAppeared: Bool = false
    
    /// 首页标签类型
    enum HomeTab: String, CaseIterable {
        case recommended = "推荐"
        case following = "关注"
        case trending = "热门"
    }
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 新增一个初始化方法来设置通知观察者
    init() {
        // 添加通知监听，当新帖子生成时刷新界面
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NewPostsGenerated"),
            object: nil,
            queue: .main
        ) { notification in
            if let count = notification.userInfo?["count"] as? Int {
                print("🏠 HomeView: 接收到新帖子生成通知，\(count)个新帖子")
                // 主要目的是触发视图刷新，实际的添加帖子逻辑已在PostViewModel中处理
                // 强制刷新列表，确保新增的帖子能显示出来
                self.postViewModel.objectWillChange.send()
            }
        }
        
        // 添加帖子更新通知监听
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PostsUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let count = notification.userInfo?["newPostsCount"] as? Int {
                print("🏠 HomeView: 接收到帖子更新通知，\(count)个新帖子已添加")
                // 触发视图刷新
                self.postViewModel.objectWillChange.send()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
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
                
                // 主滚动视图
                ScrollView {
                    // 滚动偏移量监听
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: AppScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
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
                            
                            // 历史人物横向滚动区 - 集成到顶部区域
                            ScrollViewReader { scrollProxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        // 角色卡片
                                        ForEach(characters) { character in
                                            characterCard(for: character)
                                                .id(character.id)
                                                .offset(y: contentAppeared ? 0 : 20)
                                                .opacity(contentAppeared ? 1 : 0)
                                                .animation(
                                                    .spring(response: 0.5, dampingFraction: 0.7)
                                                    .delay(Double(characters.firstIndex(where: { $0.id == character.id }) ?? 0) * 0.05),
                                                    value: contentAppeared
                                                )
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
                                                        .fill(Color.gray.opacity(0.1))
                                                        .frame(width: 48, height: 48)
                                                    
                                                    Image(systemName: "ellipsis")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.primary.opacity(0.7))
                                                }
                                                
                                                Text("查看全部")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
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
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                            }
                        }
                        .background(Color.white) // 整个顶部区域使用统一背景色
                        .opacity(showNavBar ? 1 : 0)
                        .offset(y: showNavBar ? 0 : -20)
                        .animation(.easeInOut(duration: 0.3), value: showNavBar)
                        
                        // 内容分类标签
                        tabSection
                        
                        // 内容区域
                        contentSection
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(AppScrollOffsetPreferenceKey.self) { value in
                    // 根据滚动位置控制导航栏显示
                    withAnimation {
                        showNavBar = value < 50
                    }
                }
                
                // 历史人物选择器（全屏模态）
                if showCharacterPicker {
                    VirtualCharacterPickerView(
                        onDismiss: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCharacterPicker = false
                            }
                        },
                        onSelectCharacter: { character in
                            selectedCharacter = character
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCharacterPicker = false
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1000)
                }
            }
            .onAppear {
                loadSampleData()
                
                // 内容出现动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        contentAppeared = true
                    }
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
                            // 打印当前帖子ID - 使用传入的post参数
                            print("🔎 当前查找帖子ID: \(currentPostId.uuidString)")
                            
                            // 查找当前帖子索引 - 使用更严格的ID比较
                            let currentIndex = postViewModel.posts.firstIndex { currentPost in
                                let matchFound = currentPost.id.uuidString == currentPostId.uuidString
                                print("📊 比较索引 - 当前遍历ID: \(currentPost.id.uuidString) vs 当前帖子ID: \(currentPostId.uuidString) = \(matchFound ? "匹配" : "不匹配")")
                                return matchFound
                            }
                            
                            guard let safeIndex = currentIndex else {
                                print("❌ 无法找到当前帖子索引! ID: \(currentPostId.uuidString)")
                                return nil
                            }
                            
                            // 确保索引有效并输出调试信息
                            print("🔍 当前帖子索引: \(safeIndex), 总帖子数: \(postViewModel.posts.count)")
                            
                            // 检查是否有下一篇帖子
                            let nextIndex = safeIndex + 1
                            if nextIndex < postViewModel.posts.count {
                                let nextPost = postViewModel.posts[nextIndex]
                                
                                // 确保不返回相同ID的帖子
                                if nextPost.id.uuidString == currentPostId.uuidString {
                                    print("⚠️ 警告：下一篇帖子ID与当前帖子ID相同，跳过")
                                    
                                    // 尝试获取下下篇帖子
                                    if nextIndex + 1 < postViewModel.posts.count {
                                        print("🔄 跳过ID相同的帖子，尝试获取下下篇帖子")
                                        let nextNextPost = postViewModel.posts[nextIndex + 1]
                                        print("✅ 找到下下篇帖子ID: \(nextNextPost.id.uuidString)")
                                        return nextNextPost
                                    } else {
                                        print("❌ 已经是最后一篇帖子!")
                                        return nil
                                    }
                                }
                                
                                print("✅ 找到下一篇帖子: \(nextPost.id.uuidString)")
                                return nextPost
                            } else {
                                print("❌ 已经是最后一篇帖子! 索引: \(safeIndex)")
                                return nil // 如果是最后一篇，返回nil
                            }
                        },
                        onPrevPost: { currentPostId in
                            // 打印当前帖子ID - 使用传入的post参数
                            print("🔎 当前查找帖子ID: \(currentPostId.uuidString)")
                            
                            // 查找当前帖子索引 - 使用更严格的ID比较
                            let currentIndex = postViewModel.posts.firstIndex { currentPost in 
                                let matchFound = currentPost.id.uuidString == currentPostId.uuidString
                                print("📊 比较索引 - 当前遍历ID: \(currentPost.id.uuidString) vs 当前帖子ID: \(currentPostId.uuidString) = \(matchFound ? "匹配" : "不匹配")")
                                return matchFound
                            }
                            
                            guard let safeIndex = currentIndex else {
                                print("❌ 无法找到当前帖子索引! ID: \(currentPostId.uuidString)")
                                return nil
                            }
                            
                            // 确保索引有效并输出调试信息
                            print("🔍 当前帖子索引: \(safeIndex), 总帖子数: \(postViewModel.posts.count)")
                            
                            // 检查是否有上一篇帖子
                            if safeIndex > 0 {
                                let prevPost = postViewModel.posts[safeIndex - 1]
                                
                                // 确保不返回相同ID的帖子
                                if prevPost.id.uuidString == currentPostId.uuidString {
                                    print("⚠️ 警告：上一篇帖子ID与当前帖子ID相同，跳过")
                                    
                                    // 尝试获取上上篇帖子
                                    if safeIndex - 2 >= 0 {
                                        print("🔄 跳过ID相同的帖子，尝试获取上上篇帖子")
                                        let prevPrevPost = postViewModel.posts[safeIndex - 2]
                                        print("✅ 找到上上篇帖子ID: \(prevPrevPost.id.uuidString)")
                                        return prevPrevPost
                                    } else {
                                        print("❌ 已经是第一篇帖子!")
                                        return nil
                                    }
                                }
                                
                                print("✅ 找到上一篇帖子: \(prevPost.id.uuidString)")
                                return prevPost
                            } else {
                                print("❌ 已经是第一篇帖子! 索引: \(safeIndex)")
                                return nil // 如果是第一篇，返回nil
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - 导航栏
    private var navBar: some View {
        HStack {
            // 应用标题 - 简洁扁平风格
            Text("虫遇")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color.primaryColor)
            
            // 应用副标题 - 轻量化设计
            Text("·穿越时空对话")
                .font(.system(size: 13, weight: .light))
                .foregroundColor(Color(hex: "A190B2").opacity(0.75))
                .kerning(0.3)
                .offset(y: 1)
            
            Spacer()
            
            // 编辑按钮 - 更加简约
            Button(action: {
                // 编辑操作
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primaryColor)
                    .frame(width: 32, height: 32)
                    .background(Color.primaryColor.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            
            // 已移除搜索按钮，使界面更加简洁
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(Color.white) // 纯白背景
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
                            .foregroundColor(selectedTab == tab ? Color.primary : Color.secondary.opacity(0.6))
                        
                        // 选中指示器 - 更微妙的设计
                        Rectangle()
                            .fill(selectedTab == tab ? Color.primaryColor : Color.clear)
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
        .background(Color.white)
        // 移除分隔线，创造更一体化的感觉
    }
    
    // MARK: - 内容区域
    private var contentSection: some View {
        ScrollView {
            // 使用LazyVStack提高性能
            LazyVStack(spacing: 0) {
                // 提取帖子列表为独立的视图生成函数
                postsListView
                
                // 底部安全区域填充 - 使用极小值，避免多余的空白
                Color.clear
                    .frame(height: max(0, tabBarManager.fullBottomAreaHeight - (tabBarManager.bottomSafeAreaHeight)))
                    .id("bottomSpacer")
            }
            .padding(.vertical, 0) // 移除顶部内边距，与标签栏紧密连接
        }
        .background(Color(red: 246/255, green: 248/255, blue: 252/255)) // 使用微妙的背景色而不是透明背景
        .refreshable {
            // 下拉刷新逻辑
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // 添加轻微延迟以提供更好的视觉反馈
            try? await Task.sleep(nanoseconds: 800_000_000)
            loadSampleData()
        }
        .ignoresSafeArea(.all, edges: .bottom) // 确保内容可以延伸到底部安全区域
        .edgesIgnoringSafeArea(.bottom) // 进一步确保内容延伸到底部边缘
    }
    
    // 提取帖子列表为独立的计算属性
    private var postsListView: some View {
        ForEach(Array(postViewModel.posts.enumerated()), id: \.element.id) { index, post in
            postCardView(for: post, at: index)
        }
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
                // 可以在此添加分享功能
            },
            // 确保使用预览模式显示
            displayMode: .preview
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
        let _ = UserCommentModel(
            username: "我",
            userAvatar: "person.circle.fill",
            content: commentText,
            datePosted: Date(),
            likes: 0,
            isVirtualCharacter: false,
            characterID: nil
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
        let _ = UserCommentModel(
            username: "当前用户",  // 应该使用实际的当前用户名
            userAvatar: "person.circle.fill",  // 应该使用实际的当前用户头像
            content: trimmedContent,
            datePosted: Date(),
            likes: 0,
            isVirtualCharacter: false,
            characterID: nil
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
    private func handleLikeComment(post: UserPostModel, comment: UserCommentModel) {
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
        // 加载历史人物
        characters = [
            // 爱因斯坦
            CharacterModel(
                name: "爱因斯坦",
                avatar: "einstein",
                era: "1879-1955",
                profession: "物理学家",
                bio: "相对论创立者，诺贝尔物理学奖获得者，改变了人类对时间、空间和引力的认识。",
                category: .scientist
            ),
            // 莎士比亚
            CharacterModel(
                name: "莎士比亚",
                avatar: "shakespeare",
                era: "1564-1616",
                profession: "剧作家、诗人",
                bio: "英国文艺复兴时期伟大的戏剧家和诗人，被誉为'人类文学的一座高峰'。",
                category: .artist
            ),
            // 达芬奇
            CharacterModel(
                name: "达芬奇",
                avatar: "davinci",
                era: "1452-1519",
                profession: "艺术家、科学家",
                bio: "文艺复兴时期的天才，在绘画、雕塑、建筑、科学、音乐、数学等多个领域都有卓越成就。",
                category: .artist
            ),
            // 孔子
            CharacterModel(
                name: "孔子",
                avatar: "confucius",
                era: "前551-前479",
                profession: "哲学家、教育家",
                bio: "中国古代思想家、教育家，儒家学派创始人，主张仁义礼智信的思想。",
                category: .philosopher
            ),
            // 居里夫人
            CharacterModel(
                name: "居里夫人",
                avatar: "curie",
                era: "1867-1934",
                profession: "物理学家、化学家",
                bio: "首位获得诺贝尔奖的女性，也是唯一一位在两个不同领域获得诺贝尔奖的女性科学家。",
                category: .scientist
            )
        ]
        
        // 加载用户帖子 - 使用共享的PostViewModel
        // 检查是否已有帖子，如果没有才加载示例帖子
        if postViewModel.posts.isEmpty {
            postViewModel.posts = ModelData.samplePosts
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
    private func convertToCharacter(_ model: CharacterModel) -> Character {
        return Character(
            id: model.id.uuidString,
            name: model.name,
            introduction: model.bio,
            field: model.profession,
            birthYear: model.era.components(separatedBy: "-").first ?? "",
            deathYear: model.era.components(separatedBy: "-").last,
            avatarUrl: model.avatar,
            eraTag: model.era,
            achievements: [],  // 这些数据可以根据需要添加
            mainWorks: [],
            keyThoughts: [],
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
                    // 简单的圆形背景，无阴影
                    Circle()
                        .fill(Color.gray.opacity(0.04))
                        .frame(width: 48, height: 48)
                    
                    // 图标
                    Image(systemName: character.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(character.category.color)
                }
                
                // 只保留人物名称 - 更紧凑的设计
                Text(character.name)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(width: 48)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .tint(.primary)
    }
}

#Preview("首页") {
    HomeView()
} 
