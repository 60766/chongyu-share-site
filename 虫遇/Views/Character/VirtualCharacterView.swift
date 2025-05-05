import SwiftUI

/**
 * 虚拟角色页面
 * 展示虚拟人物列表，包括历史人物和虚构角色
 */
struct VirtualCharacterView: View {
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 状态变量
    @State private var searchText = ""
    @State private var selectedCategory: CharacterCategory = .all
    @State private var characters: [Character] = []
    @State private var isLoading = true
    @State private var animateContent = false
    
    // 搜索结果过滤
    private var filteredCharacters: [Character] {
        var result = characters
        
        // 根据分类过滤
        if selectedCategory != .all {
            result = result.filter { character in
                if selectedCategory == .scientist {
                    return character.field.contains("科学") || character.field.contains("物理") || character.field.contains("化学")
                } else if selectedCategory == .philosopher {
                    return character.field.contains("哲学") || character.field.contains("思想家")
                } else if selectedCategory == .writer {
                    return character.field.contains("文学") || character.field.contains("作家") || character.field.contains("诗人")
                } else if selectedCategory == .artist {
                    return character.field.contains("艺术") || character.field.contains("画家") || character.field.contains("音乐")
                }
                return false
            }
        }
        
        // 根据搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.field.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    // 所有可用的分类
    private let categories: [CharacterCategory] = [.all, .scientist, .philosopher, .writer, .artist]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色 - 更柔和的背景色
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 搜索栏 - 现代风格搜索栏
                    SearchBarView(searchText: $searchText)
                    
                    // 分类标签栏 - 优化的标签栏
                    CategoryTabBarView(
                        categories: categories,
                        selectedCategory: $selectedCategory
                    )
                    
                    if isLoading {
                        LoadingView()
                    } else if filteredCharacters.isEmpty {
                        EmptyResultView(searchText: searchText)
                    } else {
                        // 角色列表
                        ScrollView {
                            CharacterGridView(
                                characters: filteredCharacters,
                                animateContent: animateContent
                            )
                        }
                        .refreshable {
                            // 添加下拉刷新功能
                            await refreshData()
                        }
                    }
                }
            }
            .navigationTitle("虚拟角色")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 添加角色或其他操作
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.primaryColor)
                    }
                }
            }
            .onAppear {
                loadCharacters()
                
                // 确保TabBar可见
                DispatchQueue.main.async {
                    tabBarManager.ensureTabBarVisible()
                    
                    // 延迟一小段时间后启动动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            animateContent = true
                        }
                    }
                }
            }
        }
    }
    
    // 刷新数据
    private func refreshData() async {
        // 模拟网络请求
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        loadCharacters()
    }
    
    // 加载角色数据
    private func loadCharacters() {
        // 模拟加载延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.characters = [
                Character(
                    id: "1",
                    name: "阿尔伯特·爱因斯坦",
                    introduction: "现代物理学最重要的科学家之一，相对论的创立者。他的质能方程E=mc²彻底改变了人类对能量与物质关系的认识。",
                    field: "物理学家",
                    birthYear: "1879",
                    deathYear: "1955",
                    avatarUrl: "https://example.com/einstein.jpg",
                    eraTag: "1900s",
                    achievements: ["相对论", "光电效应", "质能方程"],
                    mainWorks: ["相对论：广义和狭义", "光电效应研究", "布朗运动研究"],
                    keyThoughts: ["时间和空间是相对的", "质量可以转化为能量", "自然界的规律是简单而统一的"],
                    followerCount: 3542,
                    interactionCount: 14200,
                    rating: 4.9,
                    createdAt: Date().addingTimeInterval(-3600 * 24 * 30)
                ),
                Character(
                    id: "2",
                    name: "威廉·莎士比亚",
                    introduction: "英国剧作家、诗人，被誉为英国国家诗人，西方文学史上最杰出的戏剧家。他的作品被翻译成多种语言，对现代文学影响深远。",
                    field: "剧作家、诗人",
                    birthYear: "1564",
                    deathYear: "1616",
                    avatarUrl: "https://example.com/shakespeare.jpg",
                    eraTag: "文艺复兴",
                    achievements: ["开创戏剧新时代", "丰富英语词汇", "创造经典戏剧人物"],
                    mainWorks: ["哈姆雷特", "罗密欧与朱丽叶", "奥赛罗", "麦克白"],
                    keyThoughts: ["人性的复杂性", "生存的意义", "爱与恨的纠葛"],
                    followerCount: 2980,
                    interactionCount: 10800,
                    rating: 4.8,
                    createdAt: Date().addingTimeInterval(-3600 * 24 * 25)
                ),
                Character(
                    id: "3",
                    name: "李白",
                    introduction: "唐代伟大的浪漫主义诗人，被后人称为诗仙。其诗歌想象丰富，语言瑰丽，意境高远，音律和谐。",
                    field: "诗人",
                    birthYear: "701",
                    deathYear: "762",
                    avatarUrl: "https://example.com/libai.jpg",
                    eraTag: "唐朝",
                    achievements: ["浪漫主义诗歌先驱", "发展古体诗歌", "创作近千首传世诗作"],
                    mainWorks: ["蜀道难", "将进酒", "静夜思", "望庐山瀑布"],
                    keyThoughts: ["及时行乐", "自由洒脱", "壮志难酬"],
                    followerCount: 2560,
                    interactionCount: 9200,
                    rating: 4.7,
                    createdAt: Date().addingTimeInterval(-3600 * 24 * 20)
                ),
                Character(
                    id: "4",
                    name: "孔子",
                    introduction: "中国古代思想家、教育家，儒家学派创始人。其思想对中华文明产生了深远影响，被誉为'万世师表'。",
                    field: "哲学家、教育家",
                    birthYear: "前551",
                    deathYear: "前479",
                    avatarUrl: "https://example.com/confucius.jpg",
                    eraTag: "春秋时期",
                    achievements: ["创立儒家学派", "编纂《春秋》", "设立私学教育"],
                    mainWorks: ["论语", "五经编订"],
                    keyThoughts: ["仁义礼智信", "中庸之道", "有教无类"],
                    followerCount: 4120,
                    interactionCount: 18300,
                    rating: 4.9,
                    createdAt: Date().addingTimeInterval(-3600 * 24 * 15)
                ),
                Character(
                    id: "5",
                    name: "苏格拉底",
                    introduction: "古希腊哲学家，西方哲学的奠基人之一。他没有留下任何著作，我们对他的了解主要来自于他的学生柏拉图的对话录。苏格拉底通过提问引导人们思考的方法（苏格拉底式方法）对后世的教育和哲学研究有深远影响。他的名言\"未经审视的生活不值得过\"体现了他对反思和自知的重视。",
                    field: "哲学家",
                    birthYear: "前469",
                    deathYear: "前399",
                    avatarUrl: "https://example.com/socrates.jpg",
                    eraTag: "古希腊",
                    achievements: ["苏格拉底方法", "西方哲学奠基人", "道德理性主义"],
                    mainWorks: ["（通过柏拉图记录）《申辩篇》", "《会饮篇》", "《理想国》"],
                    keyThoughts: ["认识你自己", "美德即知识", "未经审视的生活不值得过", "我只知道我一无所知"],
                    followerCount: 2870,
                    interactionCount: 10200,
                    rating: 4.8,
                    createdAt: Date().addingTimeInterval(-3600 * 24 * 15)
                )
            ]
            
            self.isLoading = false
        }
    }
}

/**
 * 搜索栏视图
 * 优化的搜索体验
 */
struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? .gray : .primaryColor)
                .font(.system(size: 17))
                .padding(.leading, 8)
            
            TextField("搜索历史人物", text: $searchText)
                .focused($isSearchFocused)
                .font(.system(size: 16))
                .padding(10)
                .autocorrectionDisabled()
                .submitLabel(.search)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: searchText)
            }
        }
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

/**
 * 分类标签栏视图
 * 轻量级分类选择UI
 */
struct CategoryTabBarView: View {
    let categories: [CharacterCategory]
    @Binding var selectedCategory: CharacterCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CharacterCategoryButton(
                        category: category, 
                        isSelected: selectedCategory == category, 
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .overlay(
            Divider()
                .opacity(0.3),
            alignment: .bottom
        )
    }
}

/**
 * 分类按钮
 * 简洁现代的分类按钮设计
 */
private struct CharacterCategoryButton: View {
    let category: CharacterCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isSelected ? category.color.opacity(0.9) : Color.gray.opacity(0.08))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        // 添加缩放动画
        .scaleEffect(isSelected ? 1.0 : 0.97)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/**
 * 角色网格视图
 * 显示角色卡片的网格布局
 */
struct CharacterGridView: View {
    let characters: [Character]
    let animateContent: Bool
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                NavigationLink(destination: CharacterDetailView(character: character)) {
                    CharacterCardView(character: character)
                        .offset(y: animateContent ? 0 : 30)
                        .opacity(animateContent ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index % 8) * 0.05),
                            value: animateContent
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
    }
}

/**
 * 角色卡片视图
 * 优化的卡片设计
 */
struct CharacterCardView: View {
    let character: Character
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头像区域
            ZStack(alignment: .bottomLeading) {
                // 头像背景
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getCategoryColor(from: character.field).opacity(0.2),
                                getCategoryColor(from: character.field).opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 130)
                
                // 模拟头像 - 使用字母缩写
                ZStack {
                    Circle()
                        .fill(getCategoryColor(from: character.field).opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Text(String(character.name.prefix(1)))
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(getCategoryColor(from: character.field))
                }
                .padding(.bottom, 10)
                .padding(.leading, 10)
                
                // 年代标签
                Text(character.eraTag ?? "现代")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)
                    .padding(10)
                    .offset(y: -40)
            }
            
            // 角色信息
            VStack(alignment: .leading, spacing: 8) {
                // 名称和评分
                HStack {
                    Text(character.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 简化评分显示
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text(String(format: "%.1f", character.rating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 职业
                Text(character.field)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // 生卒年
                Text("\(character.birthYear)-\(character.deathYear ?? "现在")")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.top, 2)
                
                // 粉丝数和互动量 - 水平排列更紧凑
                HStack(spacing: 12) {
                    // 粉丝数
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text(formatNumber(character.followerCount))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    // 互动量
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text(formatNumber(character.interactionCount))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 格式化数字
    private func formatNumber(_ number: Int) -> String {
        if number >= 10000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000.0)
        } else {
            return "\(number)"
        }
    }
    
    // 根据角色领域获取对应的分类颜色
    private func getCategoryColor(from field: String) -> Color {
        if field.contains("科学") || field.contains("物理") || field.contains("化学") {
            return CharacterCategory.scientist.color
        } else if field.contains("哲学") || field.contains("思想家") {
            return CharacterCategory.philosopher.color
        } else if field.contains("文学") || field.contains("作家") || field.contains("诗人") {
            return CharacterCategory.writer.color
        } else if field.contains("艺术") || field.contains("画家") || field.contains("音乐") {
            return CharacterCategory.artist.color
        } else {
            return .gray
        }
    }
}

/**
 * 加载中视图
 */
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, 4)
            Text("正在穿越时空...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * 空结果视图
 */
struct EmptyResultView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(searchText.isEmpty ? "没有找到符合条件的角色" : "没有找到与\"\(searchText)\"相关的角色")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("尝试其他搜索词或切换分类")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VirtualCharacterView_Previews: PreviewProvider {
    static var previews: some View {
        VirtualCharacterView()
    }
} 