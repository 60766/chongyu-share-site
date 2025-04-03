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
    
    // 根据角色类别分组
    private var categorizedCharacters: [CharacterCategory: [CharacterModel]] {
        Dictionary(grouping: characters) { $0.category }
    }
    
    // 所有类别
    private var categories: [CharacterCategory] {
        categorizedCharacters.keys.sorted { $0.rawValue < $1.rawValue }
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
                // 顶部标题栏
                HStack {
                    // 虫洞图标 - 强化时空穿越主题
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.primaryColor, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: 18, height: 18)
                    }
                    
                    Text("时空穿越门户")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            animateContent = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isPresented = false
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // 描述文本
                Text("选择一位历史人物或虚构角色，穿越时空进行对话")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                // 角色列表
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(categories, id: \.self) { category in
                            categorySection(category, characters: categorizedCharacters[category] ?? [])
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(
                // 创建圆角形状
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.white.opacity(0.98)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
            )
            .overlay(
                // 顶部装饰性条纹
                VStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.primaryColor, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 100, height: 4)
                        .padding(.top, 8)
                    Spacer()
                }
            )
            .padding(20)
            .scaleEffect(animateContent ? 1.0 : 0.9)
            .opacity(animateContent ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    animateContent = true
                }
            }
        }
        .transition(.opacity)
    }
    
    // 类别分组视图
    private func categorySection(_ category: CharacterCategory, characters: [CharacterModel]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 类别标题
            HStack {
                Circle()
                    .fill(category.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )
                
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 时代范围标签
                Text(getCategoryEra(category))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(category.color.opacity(0.1))
                    .foregroundColor(category.color)
                    .cornerRadius(8)
            }
            
            // 角色网格
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 130))], spacing: 16) {
                ForEach(characters) { character in
                    characterCell(character)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75)
                            .delay(0.1 + Double(characters.firstIndex(where: { $0.id == character.id }) ?? 0) * 0.03),
                            value: animateContent
                        )
                }
            }
        }
    }
    
    // 角色单元格
    private func characterCell(_ character: CharacterModel) -> some View {
        Button(action: {
            selectedCharacter = character
            withAnimation(.easeOut(duration: 0.2)) {
                animateContent = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateContent = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPresented = false
                    }
                }
            }
        }) {
            VStack(spacing: 12) {
                // 头像容器
                ZStack {
                    // 背景光晕 - 加强时空穿越感
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    character.category.color.opacity(0.3),
                                    character.category.color.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    // 角色头像
                    if UIImage(named: character.avatar) != nil {
                        Image(character.avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                character.category.color,
                                                character.category.color.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        Circle()
                            .fill(character.category.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: character.category.icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(character.category.color)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                character.category.color,
                                                character.category.color.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    }
                    
                    // 选中状态指示
                    if selectedCharacter?.id == character.id {
                        Circle()
                            .strokeBorder(character.category.color, lineWidth: 3)
                            .frame(width: 88, height: 88)
                    }
                    
                    // 时代标签
                    Text(getEraTag(era: character.era))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(character.category.color)
                        )
                        .offset(y: 40)
                }
                
                // 角色名称
                Text(character.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                // 角色职业
                Text(character.profession)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedCharacter?.id == character.id ? character.category.color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // 获取类别的时代范围
    private func getCategoryEra(_ category: CharacterCategory) -> String {
        switch category {
        case .scientist: return "古代-现代"
        case .artist: return "文艺复兴"
        case .philosopher: return "古希腊-现代"
        case .writer: return "古代-现代"
        case .animeCharacter: return "现代"
        case .gameCharacter: return "现代"
        case .fictionCharacter: return "多元宇宙"
        default: return "跨时代"
        }
    }
    
    // 根据年代范围获取时代标签
    private func getEraTag(era: String) -> String {
        // 解析年代范围
        let components = era.components(separatedBy: "-")
        if components.count > 0 {
            let firstYear = components[0]
            
            // 处理公元前年份
            if firstYear.contains("前") {
                return "古代"
            }
            
            // 处理数字年份
            if let year = Int(firstYear.trimmingCharacters(in: .letters)) {
                // 根据世纪分类
                if year < 0 {
                    return "古代"
                } else if year < 1000 {
                    return "中古"
                } else if year < 1800 {
                    return "文艺"
                } else if year < 1900 {
                    return "近代"
                } else {
                    return "现代"
                }
            }
        }
        
        // 默认返回
        return "未知"
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
    /// 用户帖子数据 - 用于显示评论功能
    @State private var userPosts: [UserPostModel] = []
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
                    // 顶部导航栏
                    navBar
                        .opacity(showNavBar ? 1 : 0)
                        .offset(y: showNavBar ? 0 : -20)
                        .animation(.easeInOut(duration: 0.3), value: showNavBar)
                    
                    // 历史人物横向滚动区
                    characterScrollSection
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
                CharacterPickerView(
                    characters: characters,
                    selectedCharacter: $selectedCharacter,
                    isPresented: $showCharacterPicker
                )
                .transition(.opacity)
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
                    }
                )
            }
        }
    }
    
    // MARK: - 导航栏
    private var navBar: some View {
        HStack {
            // 应用标题 - 改用渐变色更醒目
            Text("虫遇")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primaryColor, Color.primaryColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(-0.5) // 紧凑字距
            
            // 应用副标题 - 强化时空穿越主题
            Text("·穿越时空的对话")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .offset(y: 2)
            
            Spacer()
            
            // 编辑按钮 - 现代化设计
            Button(action: {
                // 编辑操作
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryColor)
                    .frame(width: 36, height: 36)
                    .background(Color.primaryColor.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            
            // 搜索按钮 - 现代化设计
            Button(action: {
                // 搜索操作
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryColor)
                    .frame(width: 36, height: 36)
                    .background(Color.primaryColor.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            // 导航栏渐变背景
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.95)
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - 历史人物滚动区
    private var characterScrollSection: some View {
        VStack(spacing: 4) { // 减少整体间距
            // 标题栏 - 更紧凑的设计
            HStack {
                Text("历史人物")
                    .font(.system(size: 15, weight: .semibold)) // 减小字体
                    .foregroundColor(.primary)
                
                Text("· 穿越对话")
                    .font(.system(size: 13)) // 减小字体
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        showCharacterPicker = true
                    }
                }) {
                    Text("查看全部")
                        .font(.system(size: 13, weight: .medium)) // 减小字体
                        .foregroundColor(Color.primaryColor)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8) // 减少顶部间距
            .padding(.bottom, 4) // 减少底部间距
            
            // 角色滚动区 - 优化为占用更少垂直空间
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) { // 减少角色间距
                        ForEach(characters) { character in
                            CharacterAvatarView(
                                character: character,
                                size: 48, // 使用更小的尺寸
                                onTap: {
                                    selectedCharacter = character
                                    showCharacterPicker = true
                                }
                            )
                            .id(character.id) // 为滚动定位添加id
                            .offset(y: contentAppeared ? 0 : 20)
                            .opacity(contentAppeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(characters.firstIndex(where: { $0.id == character.id }) ?? 0) * 0.05), // 减少延迟时间
                                value: contentAppeared
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6) // 减少垂直间距
                }
                .onAppear {
                    // 自动滚动到中间位置显示更多角色
                    if !characters.isEmpty && characters.count > 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                scrollProxy.scrollTo(characters[min(2, characters.count-1)].id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3) // 减轻阴影
        )
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
                    VStack(spacing: 4) { // 减小内部间距
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .regular)) // 减小字体
                            .foregroundColor(selectedTab == tab ? Color.primary : Color.secondary)
                        
                        // 选中指示器 - 更细更精致
                        Capsule()
                            .fill(selectedTab == tab ? Color.primaryColor : Color.clear)
                            .frame(width: 16, height: 2) // 减小宽度和高度
                            .opacity(selectedTab == tab ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 34) // 减小整体高度
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6) // 减小垂直内边距
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1) // 减轻阴影
        )
    }
    
    // MARK: - 内容区域
    private var contentSection: some View {
        ScrollView {
            // 使用LazyVStack提高性能
            LazyVStack(spacing: 0) {
                ForEach(Array(userPosts.enumerated()), id: \.element.id) { index, post in
                    PostCardView(
                        post: post,
                        onPostTap: {
                            // 查看帖子详情
                            selectedPost = post
                            showPostDetail = true
                        },
                        onLikeToggle: { isLiked in
                            // 点赞逻辑
                            if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
                                var updatedPost = userPosts[index].toggleLike(isLiked: isLiked)
                                updatedPost = updatedPost.updateLikes(delta: isLiked ? 1 : -1)
                                userPosts[index] = updatedPost
                            }
                        },
                        onCommentToggle: {
                            // 在首页中，评论按钮直接跳转到详情页
                            selectedPost = post
                            
                            // 触觉反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // 显示帖子详情
                            withAnimation(.easeOut(duration: 0.2)) {
                                showPostDetail = true
                            }
                        },
                        onBookmarkToggle: { isBookmarked in
                            // 收藏逻辑
                            if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
                                userPosts[index] = userPosts[index].toggleBookmark(isBookmarked: isBookmarked)
                            }
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
                
                // 底部安全区域填充 - 使用极小值，避免多余的空白
                Color.clear
                    .frame(height: max(0, tabBarManager.fullBottomAreaHeight - (tabBarManager.bottomSafeAreaHeight)))
                    .id("bottomSpacer")
            }
            .padding(.vertical, 8)
        }
        .background(Color.clear) // 使用透明背景而不是白色背景
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
        if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
            userPosts[index].addComment(
                username: "我",
                userAvatar: "person.circle.fill",
                content: commentText,
                isVirtualCharacter: false,
                characterID: nil
            )
            selectedPost = userPosts[index]
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
        if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
            userPosts[index].addComment(
                username: character.name,
                userAvatar: character.avatar,
                content: content,
                isVirtualCharacter: true,
                characterID: "\(character.id)"
            )
            
            // 如果正在查看的是同一帖子，也更新 selectedPost
            selectedPost = userPosts[index]
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
        if let index = userPosts.firstIndex(where: { $0.id == post.id }) {
            // 如果是回复评论
            if let replyID = replyingTo {
                userPosts[index].addComment(
                    username: "当前用户",
                    userAvatar: "person.circle.fill",
                    content: trimmedContent,
                    parentCommentId: replyID.id,
                    replyToUsername: replyID.username // 使用被回复评论的用户名
                )
            } else {
                // 直接添加评论
                userPosts[index].addComment(
                    username: "当前用户",
                    userAvatar: "person.circle.fill",
                    content: trimmedContent
                )
            }
            
            // 如果正在查看的是同一帖子，也更新 selectedPost
            if selectedPost?.id == post.id {
                selectedPost = userPosts[index]
            }
        }
    }
    
    /**
     * 导航到下一个帖子
     */
    private func navigateToNextPost() {
        guard !userPosts.isEmpty else { return }
        
        let currentIndex = userPosts.firstIndex(where: { $0.id == selectedPost?.id }) ?? 0
        
        // 只有当不是最后一个帖子时才导航到下一个
        if currentIndex < userPosts.count - 1 {
            let nextIndex = currentIndex + 1
            selectedPost = userPosts[nextIndex]
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
        guard !userPosts.isEmpty else { return }
        
        let currentIndex = userPosts.firstIndex(where: { $0.id == selectedPost?.id }) ?? 0
        
        // 只有当不是第一个帖子时才导航到上一个
        if currentIndex > 0 {
            let previousIndex = currentIndex - 1
            selectedPost = userPosts[previousIndex]
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
        if let postIndex = userPosts.firstIndex(where: { $0.id == post.id }) {
            // 更新点赞状态
            userPosts[postIndex].likeComment(commentId: comment.id)
            
            // 如果是当前选中的帖子，也更新selectedPost
            if selectedPost?.id == post.id {
                selectedPost = userPosts[postIndex]
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
        
        // 加载用户帖子
        userPosts = ModelData.samplePosts
    }
}

#Preview("首页") {
    HomeView()
} 
