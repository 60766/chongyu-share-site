import SwiftUI
import SwiftData

/**
 * 创作中心视图
 * 用于用户创建与历史人物的对话内容
 */
struct CreationCenterView: View {
    /// 搜索文本
    @State private var searchText = ""
    /// 选中的分类索引
    @State private var selectedCategoryIndex = 0
    /// 分类列表
    private let categories = ["推荐", "科学家", "艺术家", "哲学家", "政治家", "军事家"]
    /// 模拟角色数据
    @State private var characters: [Character] = []
    /// 草稿计数
    @State private var draftCount = 2
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("创作中心")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: Text("草稿箱")) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                        
                        if draftCount > 0 {
                            Text("\(draftCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -6)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // 搜索栏
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索想要对话的历史人物...", text: $searchText)
                        .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // 分类标签栏
            CategoryTabs(categories: categories, selectedIndex: $selectedCategoryIndex)
                .padding(.bottom, 8)
            
            // 内容区域
            ScrollView {
                VStack(spacing: 20) {
                    // 最近对话
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近对话")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // 创建新对话按钮
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.primaryColor.opacity(0.1))
                                            .frame(width: 70, height: 70)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 28))
                                            .foregroundColor(.primaryColor)
                                    }
                                    
                                    Text("新对话")
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                                .padding(.leading, 16)
                                
                                // 最近对话角色
                                ForEach(characters.prefix(4)) { character in
                                    VStack(spacing: 8) {
                                        // 头像
                                        AsyncImage(url: URL(string: character.avatarUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray.opacity(0.3))
                                        }
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                        
                                        // 名称
                                        Text(character.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.center)
                                    }
                                    .onTapGesture {
                                        // 跳转到对话
                                    }
                                }
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.top, 8)
                    
                    // 创作灵感
                    VStack(alignment: .leading, spacing: 12) {
                        Text("创作灵感")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 16) {
                            CreationInspirationCard(
                                title: "与爱因斯坦讨论相对论",
                                description: "想象你有机会与物理学大师爱因斯坦探讨时空弯曲的奥秘",
                                iconName: "atom"
                            )
                            
                            CreationInspirationCard(
                                title: "向达芬奇学习绘画技巧",
                                description: "向文艺复兴时期的艺术大师请教透视法和光影处理",
                                iconName: "paintbrush"
                            )
                            
                            CreationInspirationCard(
                                title: "与孔子探讨仁义礼智",
                                description: "深入了解儒家思想的核心价值观及其现代意义",
                                iconName: "book.circle"
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                    
                    // 推荐角色
                    VStack(alignment: .leading, spacing: 12) {
                        Text("热门推荐")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                        
                        // 角色网格
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredCharacters) { character in
                                CharacterCard(
                                    character: character,
                                    type: .small,
                                    onTap: {
                                        // 跳转到创建与该角色的对话
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            loadMockData()
        }
    }
    
    /// 根据分类和搜索文本过滤角色
    private var filteredCharacters: [Character] {
        var result = characters
        
        // 根据分类过滤
        if selectedCategoryIndex > 0 {
            let category = categories[selectedCategoryIndex]
            result = result.filter { $0.field.contains(category.dropLast(1)) }
        }
        
        // 根据搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.field.lowercased().contains(searchText.lowercased()) ||
                $0.introduction.lowercased().contains(searchText.lowercased())
            }
        }
        
        return result
    }
    
    /**
     * 加载模拟数据
     */
    private func loadMockData() {
        // 推荐角色
        characters = [
            Character(
                name: "阿尔伯特·爱因斯坦",
                introduction: "现代物理学最重要的科学家之一，相对论的创立者",
                field: "物理学家",
                birthYear: "1879",
                deathYear: "1955",
                avatarUrl: "https://example.com/einstein.jpg",
                eraTag: "1900s",
                achievements: ["相对论", "光电效应", "质能方程"],
                mainWorks: ["相对论：广义和狭义"],
                keyThoughts: ["时间和空间是相对的", "质量可以转化为能量"]
            ),
            Character(
                name: "苏格拉底",
                introduction: "古希腊哲学家，西方哲学的奠基人之一",
                field: "哲学家",
                birthYear: "公元前469年",
                deathYear: "公元前399年",
                avatarUrl: "https://example.com/socrates.jpg",
                eraTag: "古希腊",
                achievements: ["苏格拉底方法", "道德哲学"],
                mainWorks: ["柏拉图对话录中记载"],
                keyThoughts: ["未经审视的生活不值得过", "认识你自己"]
            ),
            Character(
                name: "伦纳德·达·芬奇",
                introduction: "意大利文艺复兴时期的多才多艺的人，艺术家、发明家、工程师",
                field: "艺术家",
                birthYear: "1452",
                deathYear: "1519",
                avatarUrl: "https://example.com/davinci.jpg",
                eraTag: "文艺复兴",
                achievements: ["蒙娜丽莎", "最后的晚餐", "解剖学研究"],
                mainWorks: ["蒙娜丽莎", "最后的晚餐"],
                keyThoughts: ["简单是终极的复杂", "人类的智慧在于观察"]
            ),
            Character(
                name: "孔子",
                introduction: "中国古代思想家、教育家，儒家学派创始人",
                field: "哲学家",
                birthYear: "公元前551年",
                deathYear: "公元前479年",
                avatarUrl: "https://example.com/confucius.jpg",
                eraTag: "春秋时期",
                achievements: ["创立儒家学派", "编订六经"],
                mainWorks: ["论语"],
                keyThoughts: ["仁者爱人", "己所不欲，勿施于人"]
            ),
            Character(
                name: "尼古拉·特斯拉",
                introduction: "塞尔维亚裔美国发明家，电气工程师，机械工程师",
                field: "科学家",
                birthYear: "1856",
                deathYear: "1943",
                avatarUrl: "https://example.com/tesla.jpg",
                eraTag: "1900s",
                achievements: ["交流电系统", "无线电技术", "感应电动机"],
                mainWorks: ["特斯拉线圈", "交流电专利"],
                keyThoughts: ["未来的能源将是无线的", "科学是一种思维方式"]
            ),
            Character(
                name: "马里奥·居里夫人",
                introduction: "波兰裔法国物理学家、化学家，首位获得诺贝尔奖的女性",
                field: "科学家",
                birthYear: "1867",
                deathYear: "1934",
                avatarUrl: "https://example.com/curie.jpg",
                eraTag: "1900s",
                achievements: ["发现镭和钋", "放射性研究", "两次诺贝尔奖"],
                mainWorks: ["放射性研究论文"],
                keyThoughts: ["科学家应当关注事实和本质，而不是名声"]
            )
        ]
    }
}

/**
 * 创作灵感卡片
 */
struct CreationInspirationCard: View {
    var title: String
    var description: String
    var iconName: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: iconName)
                .font(.system(size: 26))
                .foregroundColor(.primaryColor)
                .frame(width: 60)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/**
 * 创作中心视图预览
 */
struct CreationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        CreationCenterView()
    }
} 