import SwiftUI

/// 对话设置数据，用于导航传递
struct ChatSettings: Hashable {
    let characters: [CharacterModel]
    let mode: ChatMode
    let theme: String
    let userRole: UserRole
    
    // 实现Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(characters.map { $0.id }.joined())
        hasher.combine(mode)
        hasher.combine(theme)
        hasher.combine(userRole.hashValue)
    }
    
    static func == (lhs: ChatSettings, rhs: ChatSettings) -> Bool {
        return lhs.characters.map { $0.id } == rhs.characters.map { $0.id } &&
               lhs.mode == rhs.mode &&
               lhs.theme == rhs.theme &&
               lhs.userRole == rhs.userRole
    }
}

struct SetChatThemeView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    
    /// 从上一个视图传递过来的已选角色
    let selectedCharacters: [CharacterModel]
    
    // MARK: - State Properties
    
    /// 对话主题
    @State private var chatTheme: String = ""
    
    /// 自动滑动的偏移量
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollOffset2: CGFloat = -50  // 第二行偏移不同起始位置
    @State private var scrollOffset3: CGFloat = -100 // 第三行偏移不同起始位置  
    @State private var scrollOffset4: CGFloat = -150 // 第四行偏移不同起始位置
    
    /// 用户的角色选择 - 固定为旁观者
    private let userRole: UserRole = .observer
    
    // MARK: - Constants
    private let recommendedTopics = [
        // 第一行 - 跨次元经典话题
        "科学与艺术的关系",
        "聊聊你们一生中最大的遗憾",
        "天才与勤奋哪个更重要",
        "自由与秩序的边界",
        "时间旅行的悖论",
        "语言如何塑造思维",
        
        // 第二行 - 现代生活话题
        "如果活在21世纪会做什么", 
        "对现在的网络时代怎么看",
        "人工智能会取代人类吗",
        "元宇宙是未来还是泡沫", 
        "社交媒体改变了什么",
        "年轻人的焦虑来自哪里",
        
        // 第三行 - 哲学思辨话题
        "领导力与影响力",
        "真理与权威",
        "道德是否有普世标准",
        "什么是真正的成功",
        "孤独是好事还是坏事",
        "完美的社会是什么样的",
        
        // 第四行 - 情感人生话题
        "聊聊你们的初恋故事",
        "最想对年轻的自己说什么",
        "人生中最重要的选择",
        "如何面对失败和挫折", 
        "友情和爱情哪个更重要",
        "什么瞬间让你觉得活着真好",
        
        // 第五行 - 奇思妙想话题
        "如果能重新设计人类",
        "外星人存在吗",
        "穿越到对方的世界会怎样",
        "如果世界末日只剩一天",
        "最想拥有什么超能力",
        "如果能和动物对话",
        
        // 第六行 - 创意脑洞话题  
        "互相吐槽对方的时代",
        "交换一天的身份体验",
        "一起开个什么店最有趣",
        "如果一起拍电影演什么",
        "设计一个完美的约会",
        "如果能改变历史上一件事"
    ]
    
    private let themeColors: [Color] = [
        Color(hex: "E6A8E0"), // 淡紫色 - 更纯的紫色
        Color(hex: "9DD1E8"), // 淡蓝色 - 更纯的蓝色
        Color(hex: "FFE09F"), // 奶油黄 - 更纯的黄色
        Color(hex: "C8E6C9"), // 淡绿色 - 更纯的绿色
        Color(hex: "F5C2C7"), // 淡粉色 - 更纯的粉色
        Color(hex: "B8E6E8"), // 淡青色 - 更纯的青色
        Color(hex: "FFE4A3"), // 淡橙色 - 更纯的橙色
        Color(hex: "D6D8DA")  // 淡灰色 - 保持中性但稍微纯一点
    ]
    
    // MARK: - Computed Properties
    
    private var finalChatMode: ChatMode {
            // 如果主题为空，则是自由对话，否则是主题讨论
            return chatTheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .freeTalk : .themedDiscussion
    }
    
    // 创建ChatSettings对象用于导航
    private var chatSettings: ChatSettings {
        return ChatSettings(
            characters: selectedCharacters,
            mode: finalChatMode,
            theme: chatTheme,
            userRole: userRole
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            headerView

            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // 1. 参与者预览
                    participantsSection
                    
                    // 2. 对话主题设置
                    themeSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120) // 为底部按钮留出空间
            }
        }
        .background(DesignSystem.Colors.background.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .navigationDestination(for: ChatSettings.self) { settings in
            MultiPersonChatView(
                selectedCharacters: settings.characters,
                chatMode: settings.mode,
                chatTheme: settings.theme,
                userRole: settings.userRole,
                historicalSessionId: nil // 新对话，没有历史会话ID
            )
        }
        // 使用覆盖层模式，与聊天页面保持一致
        .overlay(alignment: .bottom) {
            startChatButtonOverlay
        }
        .edgesIgnoringSafeArea(.bottom) // 关键！忽略底部安全区域，确保按钮贴合屏幕底部
        .onAppear {
            // 启动自动滑动动画
            startAutoScroll()
        }
    }
    
    // MARK: - UI Components
    
    /// 自定义顶部标题栏
    private var headerView: some View {
        ZStack {
            // 中间标题
            Text("设定对话场景")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            HStack {
                // 返回按钮
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.warmAccent)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                
                Spacer()
            }
        }
        .frame(height: 44)
        .background(DesignSystem.Colors.background)
        .shadow(color: Color.black.opacity(0.05), radius: 0.5, x: 0, y: 0.5)
    }
    
    /// 参与者预览区域
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参与者")
                .font(.system(size: 15, weight: .semibold)) // 从18变为15
                .foregroundColor(.primary.opacity(0.7)) // 稍微黑一点点
            
            // 头像左对齐布局
            HStack(spacing: 12) {
                    ForEach(selectedCharacters) { character in
                        VStack(spacing: 8) {
                        // 简化的头像 - 纯净苹果风格
                            Image(character.avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                            
                        // 简化的名称标签 - 无背景
                            Text(character.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    .frame(width: 56) // 固定宽度保持对齐
                    }
                
                Spacer() // 推到左侧
            }
        }
    }
    
    /// 对话主题区域
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Title
            Text("对话主题")
                .font(.system(size: 15, weight: .semibold)) // 从18变为15
                .foregroundColor(.primary.opacity(0.7)) // 稍微黑一点点

            // Theme TextField with character count
            VStack(alignment: .trailing, spacing: 8) {
                TextField("你想让TA们聊点什么？(选填)", text: $chatTheme, axis: .vertical)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(Color(hex: "FAFAFA")) // 更亮的背景色
                    .cornerRadius(16)
                .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(chatTheme.isEmpty ? Color(.systemGray5) : Color.warmAccent.opacity(0.3), lineWidth: 1)
                    )
                    .lineLimit(3...6)
                
                // 字符计数
                if !chatTheme.isEmpty {
                    Text("\(chatTheme.count)/200")
                        .font(.system(size: 12))
                        .foregroundColor(chatTheme.count > 200 ? .red : Color(.systemGray))
                        .transition(.opacity)
                }
            }
            
            // Recommended Topics
            recommendedTopicsSection
        }
    }

    /// 推荐主题区域
    private var recommendedTopicsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                // 将36个主题分成4行，每行9个
                let topicsPerRow = 9
                let row1 = Array(recommendedTopics.prefix(topicsPerRow))
                let row2 = Array(recommendedTopics.dropFirst(topicsPerRow).prefix(topicsPerRow))
                let row3 = Array(recommendedTopics.dropFirst(topicsPerRow * 2).prefix(topicsPerRow))
                let row4 = Array(recommendedTopics.dropFirst(topicsPerRow * 3))
                
                // 第一行 - 跨次元经典话题 + 现代生活话题 (前9个) - 向左移动
                topicRow(topics: row1, startIndex: 0, offset: scrollOffset)
                
                // 第二行 - 现代生活话题 + 哲学思辨话题 (第10-18个) - 向右移动
                topicRow(topics: row2, startIndex: topicsPerRow, offset: scrollOffset2)
                
                // 第三行 - 哲学思辨话题 + 情感人生话题 (第19-27个) - 向左移动但更快
                topicRow(topics: row3, startIndex: topicsPerRow * 2, offset: scrollOffset3)
                
                // 第四行 - 情感人生话题 + 奇思妙想话题 + 创意脑洞话题 (第28-36个) - 向右移动但更慢
                topicRow(topics: row4, startIndex: topicsPerRow * 3, offset: scrollOffset4)
            }
            .padding(.horizontal, 1)
        }
        .frame(height: 4 * 38 + 3 * 12) // 4行，每行38高度，3个间距每个12
        .onAppear {
            startAutoScroll()
        }
    }
    
    /// 开始自动滑动
    private func startAutoScroll() {
        // 创建更慢且平缓的自动滑动效果
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            withAnimation(.linear(duration: 0.08)) {
                // 第一行：向左移动，慢速
                scrollOffset -= 0.4
                if scrollOffset <= -600 {
                    scrollOffset = 100
                }
                
                // 第二行：向右移动，很慢
                scrollOffset2 += 0.25
                if scrollOffset2 >= 600 {
                    scrollOffset2 = -200
                }
                
                // 第三行：向左移动，中等速度
                scrollOffset3 -= 0.6
                if scrollOffset3 <= -800 {
                    scrollOffset3 = 150
                }
                
                // 第四行：向右移动，极慢
                scrollOffset4 += 0.15
                if scrollOffset4 >= 500 {
                    scrollOffset4 = -250
                }
            }
        }
    }
    
    /// 单行主题视图
    private func topicRow(topics: [String], startIndex: Int, offset: CGFloat) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                let colorIndex = (startIndex + index) % themeColors.count
                let baseColor = themeColors[colorIndex]
                let isSelected = chatTheme == topic
                
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        chatTheme = topic 
                    }
                }) {
                    Text(topic)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                if isSelected {
                                    LinearGradient(
                                        gradient: Gradient(colors: [baseColor.opacity(0.9), baseColor.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [baseColor.opacity(0.3), baseColor.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            }
                        )
                        .foregroundColor(isSelected ? .white : Color(hex: "4A4A4A")) // 使用柔和的深灰色
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isSelected ? baseColor.opacity(0.5) : baseColor.opacity(0.4), lineWidth: 1.2) // 稍微加强边框
                        )
                        .shadow(color: isSelected ? baseColor.opacity(0.3) : Color.clear, radius: isSelected ? 4 : 0, x: 0, y: isSelected ? 2 : 0)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .scaleEffect(isSelected ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
        }
        .frame(height: 40)
        .offset(x: offset) // 应用偏移量
    }
    
    /// 底部开始对话按钮的覆盖层 - 使用与聊天页面相同的模式
    private var startChatButtonOverlay: some View {
        // 占位视图本身不占空间，把按钮插入到底部安全区域
        Color.clear
            .frame(height: 0)
            .safeAreaInset(edge: .bottom) {
                startChatButton
            }
    }
    
    /// 底部开始对话按钮
    private var startChatButton: some View {
        NavigationLink(value: chatSettings) {
            HStack(spacing: 8) {
                Text("开始对话")
                    .font(.system(size: 17, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "A78DC7"),
                        Color(hex: "9680B7")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            )
            .shadow(color: Color(hex: "A78DC7").opacity(0.4), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20) // 使用与聊天页面相同的20
        .padding(.bottom, 12) // 统一使用12，与聊天页面保持一致
    }
}

// MARK: - Supporting Types

/// 对话模式枚举
enum ChatMode: String, CaseIterable, Identifiable {
    case freeTalk = "自由对话"
    case themedDiscussion = "主题讨论"
    
    var id: String { self.rawValue }
}

/// 用户角色枚举
enum UserRole: String, Equatable, Hashable {
    case observer = "observer"
}

// MARK: - Preview

struct SetChatThemeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetChatThemeView(selectedCharacters: [
                CharacterModel.getAllCharacters().first!,
                CharacterModel.getAllCharacters()[1]
            ])
        }
    }
} 