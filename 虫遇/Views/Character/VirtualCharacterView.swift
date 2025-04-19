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
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 搜索栏
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("搜索历史人物", text: $searchText)
                            .padding(8)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding([.horizontal, .top], 16)
                    
                    // 分类标签栏
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    withAnimation {
                                        selectedCategory = category
                                    }
                                }) {
                                    Text(category.displayName)
                                        .font(.system(size: 14, weight: selectedCategory == category ? .semibold : .regular))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == category ? category.color : Color.white)
                                        )
                                        .foregroundColor(selectedCategory == category ? .white : category.color)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    if isLoading {
                        Spacer()
                        ProgressView("加载中...")
                        Spacer()
                    } else if filteredCharacters.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("没有找到符合条件的角色")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        // 角色列表
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(filteredCharacters) { character in
                                    NavigationLink(destination: CharacterDetailView(character: character)) {
                                        CharacterCardView2(character: character)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("虚拟角色")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCharacters()
                
                // 确保TabBar可见
                DispatchQueue.main.async {
                    tabBarManager.ensureTabBarVisible()
                }
            }
        }
    }
    
    // 加载角色数据
    private func loadCharacters() {
        // 模拟加载延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
                )
            ]
            
            self.isLoading = false
        }
    }
}

/**
 * 角色卡片视图
 */
struct CharacterCardView2: View {
    let character: Character
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 角色头像区域
            ZStack(alignment: .bottomLeading) {
                // 头像
                AsyncImage(url: URL(string: character.avatarUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                    }
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // 年代标签
                Text(character.eraTag ?? "现代")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)
                    .padding(8)
            }
            
            // 角色信息
            VStack(alignment: .leading, spacing: 6) {
                // 名称和职业
                HStack {
                    Text(character.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 粉丝数指示
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                        
                        Text("\(character.followerCount)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                
                Text(character.field)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // 评分
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(character.rating) ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    Text(String(format: "%.1f", character.rating))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

struct VirtualCharacterView_Previews: PreviewProvider {
    static var previews: some View {
        VirtualCharacterView()
    }
} 