import SwiftUI
import SwiftData
import UIKit

struct MultiPersonChatSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    /// 用户角色，默认为观察者
    let userRole: UserRole = .observer
    
    // MARK: - State Properties
    
    /// 所有可用角色的列表
    @State private var allCharacters: [CharacterModel] = []
    
    /// 已选择的角色ID集合，使用Set保证唯一性
    @State private var selectedCharacterIDs: Set<String> = []
    
    /// 搜索文本
    @State private var searchText: String = ""
    
    /// 历史对话是否展开
    @State private var isChatHistoryExpanded: Bool = false
    
    /// 历史对话列表
    @State private var chatHistory: [ChatHistoryItem] = []
    
    /// 是否显示全部历史记录
    @State private var showAllHistory: Bool = false
    
    /// 系统级按钮窗口
    @State private var systemBackButtonWindow: UIWindow?
    
    /// 数据服务
    private let dataService = MultiPersonChatDataService.shared
    
    /// 推荐组合的示例数据
    private let recommendedCombinations: [RecommendedCombination] = [
        .init(name: "科学思想家", characterNames: ["爱因斯坦", "尼古拉·特斯拉", "牛顿"], gradientColors: [Color(hex: "C2E9FB"), Color(hex: "A1C4FD")]),
        .init(name: "文学大师", characterNames: ["莎士比亚", "李白", "鲁迅"], gradientColors: [Color(hex: "D4C1EC"), Color(hex: "A890B8")]),
        .init(name: "超级英雄大会", characterNames: ["托尼·史塔克", "蜘蛛侠", "黑寡妇"], gradientColors: [Color(hex: "FFB6C1"), Color(hex: "FF69B4")]),
        .init(name: "古代哲学家", characterNames: ["孔子", "苏格拉底", "亚里士多德"], gradientColors: [Color(hex: "DDD6FE"), Color(hex: "C084FC")]),
        .init(name: "奇幻冒险团", characterNames: ["林克", "弗罗多·巴金斯", "赫敏·格兰杰"], gradientColors: [Color(hex: "A7F3D0"), Color(hex: "10B981")]),
        .init(name: "科幻未来", characterNames: ["尼奥", "T-800终结者", "詹姆斯·柯克"], gradientColors: [Color(hex: "DBEAFE"), Color(hex: "3B82F6")]),
        .init(name: "动漫英雄", characterNames: ["漩涡鸣人", "孙悟空", "马里奥"], gradientColors: [Color(hex: "FED7AA"), Color(hex: "F97316")]),
        .init(name: "神话传说", characterNames: ["孙悟空", "阿努比斯", "雅典娜"], gradientColors: [Color(hex: "E0E7FF"), Color(hex: "6366F1")]),
        .init(name: "侦探推理", characterNames: ["夏洛克·福尔摩斯", "豪斯医生", "江户川柯南"], gradientColors: [Color(hex: "F3E8FF"), Color(hex: "8B5CF6")]),
        .init(name: "历史女杰", characterNames: ["花木兰", "武则天", "艾莎女王"], gradientColors: [Color(hex: "FCE7F3"), Color(hex: "EC4899")]),
        .init(name: "心理大师", characterNames: ["弗洛伊德", "荣格", "苏格拉底"], gradientColors: [Color(hex: "F0F9FF"), Color(hex: "0EA5E9")]),
        .init(name: "游戏世界", characterNames: ["马里奥", "林克", "劳拉·克罗夫特"], gradientColors: [Color(hex: "ECFCCB"), Color(hex: "65A30D")])
    ]
    
    // MARK: - Computed Properties
    
    /// 已选择的角色模型数组
    private var selectedCharacters: [CharacterModel] {
        // 为了保证顺序，我们需要一个有序的ID列表
        let orderedIDs = allCharacters.filter { selectedCharacterIDs.contains($0.id) }.map { $0.id }
        // 根据这个有序列表从Set中重新构建数组
        return orderedIDs.compactMap { id in allCharacters.first { $0.id == id } }
    }
    
    /// 根据搜索文本过滤后的角色列表
    private var filteredCharacters: [CharacterModel] {
        if searchText.isEmpty {
            return allCharacters
        } else {
            return allCharacters.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// "下一步"按钮是否可用
    private var isNextButtonDisabled: Bool {
        selectedCharacterIDs.count < 2 || selectedCharacterIDs.count > 4
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 导航栏
                headerView
                
                // 主内容区域
                ScrollView {
                    VStack(spacing: 0) {
                        // 已选择的角色预览
                        selectedCharactersSection
                        
                        // 推荐组合
                        recommendedCombinationsSection
                        
                        // 最近对话
                        chatHistorySection
                        
                        // 间距
                        Spacer()
                            .frame(height: 20)
                        
                        // 所有角色
                        allCharactersSection
                    }
                    .padding(.bottom, 100) // 为底部按钮留出空间
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationBarHidden(true)
            .navigationDestination(for: [CharacterModel].self) { characters in
                SetChatThemeView(
                    selectedCharacters: characters
                )
            }
            // 使用覆盖层模式，与聊天页面保持一致
            .overlay(alignment: .bottom) {
                nextStepButtonOverlay
            }
            .edgesIgnoringSafeArea(.bottom) // 关键！忽略底部安全区域，确保按钮贴合屏幕底部
            .onAppear {
                loadCharacters()
                loadChatHistory()
                // 添加系统级返回按钮
                addSystemLevelBackButton()
            }
            .onDisappear {
                // 移除系统级返回按钮
                systemBackButtonWindow?.isHidden = true
                systemBackButtonWindow?.rootViewController = nil
                systemBackButtonWindow = nil
            }
        }
    }
    
    // MARK: - UI Components
    
    /// 底部下一步按钮覆盖层 - 使用与聊天页面相同的模式
    private var nextStepButtonOverlay: some View {
        // 占位视图本身不占空间，把按钮插入到底部安全区域
        Color.clear
            .frame(height: 0)
            .safeAreaInset(edge: .bottom) {
                nextStepButton
            }
    }
    
    /// 底部下一步按钮
    private var nextStepButton: some View {
        NavigationLink(value: selectedCharacters) {
            HStack(spacing: 8) {
                Text("下一步")
                    .font(.system(size: 17, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(
                Group {
                    if isNextButtonDisabled {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.gray.opacity(0.3))
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "A78DC7"),
                                Color(hex: "9680B7")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
            )
            .shadow(color: Color(hex: "A78DC7").opacity(0.4), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .disabled(isNextButtonDisabled)
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20) // 使用与聊天页面相同的20
        .padding(.bottom, 12) // 统一使用12，与聊天页面保持一致
    }
    
    /// 自定义顶部标题栏
    private var headerView: some View {
        ZStack {
            // 中间标题 - 与返回按钮绝对位置高度一致（返回按钮中心在 topPadding + 25）
            // 使用与ChatHeader相同的实现方式，但需要更大的offset来对齐返回按钮
            Text("选择参与者")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44) // 与ChatHeader一致，不使用alignment参数
                .offset(y: -10) // 增大offset，使标题中心与返回按钮中心绝对对齐（topPadding + 25）
            
            // 按钮已移至系统级UIWindow，这里只保留占位空间
            HStack(spacing: 0) {
                // 左侧占位 - 系统级返回按钮会覆盖这里
                Color.clear
                    .frame(width: 50, height: 44)
                    .padding(.leading, 16)
                
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.top) // 添加顶部安全区域padding，与ChatHeader一致
        .background(DesignSystem.Colors.background)
        .shadow(color: Color.black.opacity(0.05), radius: 0.5, x: 0, y: 0.5)
    }
    
    // MARK: - 系统级按钮
    
    /**
     * 创建一个覆盖在左上角的系统级返回按钮
     * 与实际聊天页面完全一致，确保视觉统一
     */
    private func addSystemLevelBackButton() {
        // 计算顶部安全区域高度
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let topPadding = windowScene?.windows.first?.safeAreaInsets.top ?? 44
        
        // 先移除旧窗口（如果存在）
        systemBackButtonWindow?.isHidden = true
        systemBackButtonWindow = nil
        
        // 创建新窗口 - 只覆盖左上角返回按钮区域
        if let windowScene = windowScene {
            let buttonWindow = UIWindow(windowScene: windowScene)
            buttonWindow.frame = CGRect(
                x: 0,
                y: 0,
                width: 50,
                height: topPadding + 44
            )
            buttonWindow.tag = 9997
            buttonWindow.isUserInteractionEnabled = true
            buttonWindow.windowLevel = .alert + 1
            buttonWindow.backgroundColor = .clear
            
            // 设置根视图控制器
            let viewController = UIViewController()
            viewController.view.backgroundColor = .clear
            buttonWindow.rootViewController = viewController
            
            // 配置返回按钮 - 与实际聊天页面完全一致
            let backButton = UIButton(type: .system)
            backButton.frame = CGRect(x: 16, y: topPadding + 10, width: 30, height: 30)
            
            // 设置按钮图标 - 与实际聊天页面完全一致
            let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let image = UIImage(systemName: "chevron.left", withConfiguration: imageConfig)
            backButton.setImage(image, for: .normal)
            
            // 使用主题色作为按钮颜色 - 与实际聊天页面完全一致
            let themeColor = UIColor(Color(hex: "9A8BB0"))
            backButton.tintColor = themeColor
            
            // 添加按钮点击事件
            backButton.addAction(UIAction { _ in
                // 立即隐藏返回按钮窗口
                buttonWindow.isHidden = true
                
                // 触发轻柔触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // 返回操作
                presentationMode.wrappedValue.dismiss()
            }, for: .touchUpInside)
            
            // 添加到视图控制器的视图
            viewController.view.addSubview(backButton)
            
            // 保存窗口引用并显示
            systemBackButtonWindow = buttonWindow
            buttonWindow.makeKeyAndVisible()
        }
    }
    
    /// 已选角色区域
    private var selectedCharactersSection: some View {
        VStack(spacing: 0) {
            // 标题与清空按钮
            HStack {
                HStack(spacing: 4) {
                    Text("已选择")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary) // 统一的灰色
                    Text("(\(selectedCharacterIDs.count)/4)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 清空按钮 - 使用正确的紫色主题色
                if !selectedCharacterIDs.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCharacterIDs.removeAll()
                        }
                    }) {
                        Text("清空")
                            .font(.system(size: 16))
                            .foregroundColor(Color.warmAccent) // 使用正确的紫色主题色
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // 分隔线
            Divider()
                .padding(.horizontal, 16)
                .background(Color.warmBorder)
            
            // 选中的角色头像
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(selectedCharacters) { character in
                        selectedCharacterAvatar(for: character)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(DesignSystem.Colors.background)
        .transition(.move(edge: .top))
    }
    
    /// 推荐组合区域
    private var recommendedCombinationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 标题
            HStack {
                Text("推荐组合")
                    .font(.system(size: 15, weight: .semibold)) // 从17变为15
                    .foregroundColor(.primary.opacity(0.7)) // 稍微黑一点点
                
                Spacer()
            }
            .padding(.horizontal)
            
            // 推荐组合卡片
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(recommendedCombinations) { combo in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectCombination(combo)
                            }
                        }) {
                            combinationCard(for: combo)
                        }
                        .buttonStyle(ScaleButtonStyle()) // 添加缩放按钮样式
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 4)
    }
    
    /// 历史对话区域
    private var chatHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 折叠状态的简洁入口
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // 如果要展开历史对话区域，重置为默认状态（只显示3条）
                    if !isChatHistoryExpanded {
                        showAllHistory = false
                    }
                    isChatHistoryExpanded.toggle()
            }
            }) {
                HStack {
                    Text("最近对话")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.warmAccent)
                    
                    Text("(\(chatHistory.count))")
                        .font(.system(size: 13))
                        .foregroundColor(Color.warmAccent.opacity(0.7))
                    
                    Spacer()
                    
                    Image(systemName: isChatHistoryExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.warmAccent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.warmAccent.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.warmAccent.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.warmAccent.opacity(0.1), radius: 2, x: 0, y: 1)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 16) // 添加外部padding与搜索框对齐
            
            if isChatHistoryExpanded {
                // 历史对话列表
                VStack(alignment: .leading, spacing: 10) {
                    if chatHistory.isEmpty {
                        // 空状态提示
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                Text("还没有历史对话")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 20)
                            Spacer()
                        }
                    } else {
                        // 根据showAllHistory状态决定显示多少条记录
                        let displayedHistory = showAllHistory ? chatHistory : Array(chatHistory.prefix(3))
                        
                        ForEach(displayedHistory) { item in
                            ChatHistoryItemView(item: item) {
                                // 删除后刷新历史对话列表
                                refreshChatHistory()
                            }
                        }
                        
                        // 如果有超过3条对话且未显示全部，显示查看全部按钮
                        if chatHistory.count > 3 && !showAllHistory {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAllHistory = true
                                }
                            }) {
                                HStack {
                                    Text("查看全部历史")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color.warmAccent)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.warmAccent)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.warmAccent.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.warmAccent.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.warmAccent.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // 如果已显示全部且有超过3条记录，显示收起按钮
                        if chatHistory.count > 3 && showAllHistory {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAllHistory = false
                                }
                            }) {
                                HStack {
                                    Text("收起历史")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.warmAccent)
                                    
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.warmAccent)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.warmAccent.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 8)
    }
    
    /// 所有角色区域
    private var allCharactersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 显示筛选结果数量
            if !searchText.isEmpty {
                HStack {
                    Text("找到\(filteredCharacters.count)个角色")
                        .font(.system(size: 14))
                        .foregroundColor(Color.warmTextSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // 搜索框
            LocalSearchBar(text: $searchText)
                .padding(.horizontal)
            
            // 角色网格
            characterGrid
                .padding(.top, 8)
                .padding(.bottom, 20)
        }
    }
    
    /// 角色网格视图
    private var characterGrid: some View {
        // 使用固定的四列网格布局
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(filteredCharacters) { character in
                characterCell(for: character)
            }
        }
        .padding(.horizontal)
    }
    
    /// 单个已选角色的头像视图
    private func selectedCharacterAvatar(for character: CharacterModel) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                // 角色头像 - 使用圆形头像服务支持首字母显示
                CharacterAvatarService.shared.getAvatarView(
                    for: character.id,
                    name: character.name,
                    category: character.category.rawValue,
                    size: 48,
                    useCaching: true
                )
                .overlay(
                    Circle()
                        .stroke(Color.warmAccentSecondary.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                
                // 角色名称
                Text(character.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(Color.warmTextPrimary)
            }
            
            // 移除按钮 - 使用系统风格
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    toggleSelection(for: character)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.warmAccentSecondary)
                    .font(.system(size: 16))
                    .background(Circle().fill(Color.white).shadow(radius: 1))
            }
            .offset(x: 4, y: -2)
        }
        .frame(width: 56)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCharacterIDs.contains(character.id))
    }
    
    /// 单个推荐组合的卡片视图
    private func combinationCard(for combo: RecommendedCombination) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 组合名称
            Text(combo.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            // 角色名称列表
            Text(combo.characterNames.joined(separator: "、"))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 200, height: 100, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: combo.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: combo.gradientColors.first?.opacity(0.4) ?? .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    // 缩放按钮样式
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// 单个可选角色的单元格视图
    private func characterCell(for character: CharacterModel) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                toggleSelection(for: character)
            }
        }) {
            VStack(spacing: 8) {
                // 角色头像
                ZStack {
                    // 头像图片 - 使用方形头像服务支持首字母显示
                    CharacterAvatarService.shared.getSquareAvatarView(
                        for: character.id,
                        name: character.name,
                        category: character.category.rawValue,
                        size: 72,
                        cornerRadius: 18,
                        useCaching: true
                    )
                    
                    // 选中状态指示器
                    if selectedCharacterIDs.contains(character.id) {
                        // 紫色渐变边框
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.warmAccent, Color.warmAccentSecondary.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 72, height: 72)
                        
                        // 选中标记 - 使用更精致的视觉效果
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.warmAccent)
                        }
                        .offset(x: 26, y: -26)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedCharacterIDs.contains(character.id))
                    }
                }
                .shadow(color: Color.black.opacity(selectedCharacterIDs.contains(character.id) ? 0.15 : 0.1), radius: selectedCharacterIDs.contains(character.id) ? 5 : 3, x: 0, y: selectedCharacterIDs.contains(character.id) ? 3 : 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.warmBorder.opacity(selectedCharacterIDs.contains(character.id) ? 0 : 0.3), lineWidth: 0.5)
                )
                .scaleEffect(selectedCharacterIDs.contains(character.id) ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCharacterIDs.contains(character.id))
                
                // 角色名称
                Text(character.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedCharacterIDs.contains(character.id) ? Color.warmAccent : Color.warmTextPrimary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(width: 75)
                    .scaleEffect(selectedCharacterIDs.contains(character.id) ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCharacterIDs.contains(character.id))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    /// 加载所有角色
    private func loadCharacters() {
        // 多人聊天不受分类屏蔽影响，使用不过滤的版本
        let characters = CharacterModel.loadAllCharactersWithoutFilter()
        // 后续支持加载用户创建的角色
        self.allCharacters = characters
    }
    
    /// 切换角色的选中状态
    private func toggleSelection(for character: CharacterModel) {
        if selectedCharacterIDs.contains(character.id) {
            selectedCharacterIDs.remove(character.id)
        } else if selectedCharacterIDs.count < 4 {
            selectedCharacterIDs.insert(character.id)
        }
    }
    
    /// 选中一个推荐组合
    private func selectCombination(_ combo: RecommendedCombination) {
        let characterNameToFind = Set(combo.characterNames)
        let foundCharacters = allCharacters.filter { characterNameToFind.contains($0.name) }
        
        // 清空当前选择，并添加组合中的角色
        selectedCharacterIDs.removeAll()
        for character in foundCharacters {
            if selectedCharacterIDs.count < 4 {
                selectedCharacterIDs.insert(character.id)
            }
        }
    }
    
    /// 加载聊天历史
    private func loadChatHistory() {
        let sessions = dataService.getChatSessions(modelContext: modelContext)
        chatHistory = sessions.map { dataService.convertToChatHistoryItem($0) }
        print("✅ 已加载 \(chatHistory.count) 个历史对话")
    }
    
    /// 刷新聊天历史（删除后调用）
    private func refreshChatHistory() {
        loadChatHistory()
    }
}

// MARK: - Supporting Types

/// 推荐组合的数据模型
struct RecommendedCombination: Identifiable {
    let id = UUID()
    let name: String
    let characterNames: [String]
    let gradientColors: [Color]
}

/// 简单的搜索框视图 - 重命名以避免冲突
struct LocalSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            // 搜索图标 - 使用更现代的SF Symbols
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.primary.opacity(0.7))
                .font(.system(size: 16, weight: .medium))
                .padding(.leading, 12)
            
            // 搜索输入框
            TextField("搜索角色...", text: $text)
                .font(.system(size: 15))
                .foregroundColor(Color.warmTextPrimary)
                .focused($isFocused)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .onTapGesture {
                    isEditing = true
                }
            
            // 清除按钮
            if !text.isEmpty {
                Button(action: { 
                    self.text = ""
                    // 保持焦点
                    isFocused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary.opacity(0.6))
                        .padding(.trailing, 8)
                }
                .transition(.scale)
            }
            
            // 取消按钮 - 仅在编辑状态显示
            if isEditing {
                Button(action: {
                    self.text = ""
                    isEditing = false
                    // 隐藏键盘
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("取消")
                        .foregroundColor(Color.warmAccent)
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "FAFAFA"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .animation(.easeInOut(duration: 0.2), value: text)
    }
}

// MARK: - Preview

struct MultiPersonChatSetupView_Previews: PreviewProvider {
    static var previews: some View {
        MultiPersonChatSetupView()
    }
}

// MARK: - 历史对话相关模型和视图

/// 历史对话数据模型
struct ChatHistoryItem: Identifiable, Hashable {
    let id = UUID()
    let topic: String
    let participants: [String]
    let messageCount: Int
    let lastActiveTime: Date
    let chatId: String
    
    /// 格式化时间显示
    var formattedTime: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: lastActiveTime, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)天前"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)小时前"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分钟前"
        } else {
            return "刚刚"
        }
    }
    
    /// 参与者显示文本
    var participantsText: String {
        return participants.joined(separator: "·")
    }
}

/// 历史对话条目视图
struct ChatHistoryItemView: View {
    let item: ChatHistoryItem
    let onDelete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @State private var shouldNavigateToChat = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        Button(action: {
            // 跳转到历史对话详情
            print("跳转到历史对话: \(item.topic) - 参与者: \(item.participantsText)")
            shouldNavigateToChat = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // 对话主题
                Text(item.topic)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 参与者和时间
                HStack {
                    Text(item.participantsText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("• \(item.formattedTime)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.08),
                                Color.purple.opacity(0.06),
                                Color(hex: "E0C3FC").opacity(0.05),  // 淡紫色
                                Color(hex: "D4F1F4").opacity(0.04)   // 淡蓝色
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(color: Color.blue.opacity(0.08), radius: 4, x: 0, y: 2)
                    .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.15),
                                Color.purple.opacity(0.12),
                                Color(hex: "E0C3FC").opacity(0.10),
                                Color(hex: "D4F1F4").opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            // 长按菜单
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("删除对话", systemImage: "trash")
            }
        }
        .alert("删除对话", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteChat()
            }
        } message: {
            Text("确定要删除这个对话吗？此操作无法撤销。")
        }
        .fullScreenCover(isPresented: $shouldNavigateToChat) {
            HistoricalChatView(chatId: item.chatId)
        }
    }
    
    private func deleteChat() {
        // 调用数据服务删除会话
        let dataService = MultiPersonChatDataService()
        dataService.deleteChatSession(sessionId: item.chatId, modelContext: modelContext)
        
        // 通知父视图更新列表
        onDelete()
    }
}

// MARK: - 历史对话详情视图
struct HistoricalChatView: View {
    let chatId: String
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var chatManager = MultiChatManager()
    @State private var isLoading = true
    @State private var historicalSession: MultiPersonChatSession?
    @State private var sessionCharacters: [CharacterModel] = []
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("加载历史对话...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                } else if let session = historicalSession {
                    MultiPersonChatView(
                        selectedCharacters: sessionCharacters,
                        chatMode: ChatMode(rawValue: session.chatMode) ?? .freeTalk,
                        chatTheme: session.chatTheme,
                        userRole: UserRole(rawValue: session.userRole) ?? .observer,
                        historicalSessionId: session.id // 传递历史会话ID
                    )
                    .environmentObject(chatManager)
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        Text("无法加载历史对话")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true) // 隐藏导航栏，避免显示关闭按钮
        }
        .onAppear {
            loadHistoricalChat()
        }
    }
    
    private func loadHistoricalChat() {
        // 先加载会话信息
        loadSessionInfo()
        
        // 再加载历史消息
        chatManager.loadChatHistory(sessionId: chatId, modelContext: modelContext, characters: sessionCharacters)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
    
    private func loadSessionInfo() {
        let dataService = MultiPersonChatDataService()
        if let session = dataService.getChatSession(sessionId: chatId, modelContext: modelContext) {
            historicalSession = session
            
            // 根据 participantIds 加载角色信息
            // 多人聊天不受分类屏蔽影响，使用不过滤的版本
            sessionCharacters = session.participantIds.compactMap { characterId in
                CharacterModel.loadAllCharactersWithoutFilter().first { $0.id == characterId }
            }
            
            print("✅ 加载历史会话信息：")
            print("   - 会话ID: \(session.id)")
            print("   - 标题: \(session.topic)")
            print("   - 角色数量: \(sessionCharacters.count)")
            print("   - 聊天模式: \(session.chatMode)")
            print("   - 主题: \(session.chatTheme)")
        } else {
            print("❌ 未找到会话ID为 \(chatId) 的历史会话")
        }
    }
} 