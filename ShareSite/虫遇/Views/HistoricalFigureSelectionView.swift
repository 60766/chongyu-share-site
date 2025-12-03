import SwiftUI

/**
 * 历史人物选择视图
 * 用于邀请历史人物参与帖子讨论
 * 采用极简现代设计风格，遵循8pt网格系统
 */
struct HistoricalFigureSelectionView: View {
    // 环境变量
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // 状态变量
    @StateObject private var viewModel: HistoricalFigureSelectionViewModel
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "全部"
    
    // 常量 - 设计系统
    private let spacing: CGFloat = 8
    private let cornerRadius: CGFloat = 12
    
    // UI常量
    private let categories = ["全部", "最近", "关注", "历史人物", "文学角色", "电影角色", "动漫角色", "神话角色", "电视剧角色", "游戏角色", "虚拟主播"]
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // 颜色系统 - 与选择参与者页面保持一致的紫色主题
    private var primaryColor: Color { Color(hex: "A78DC7") }
    private var secondaryColor: Color { Color.secondary }
    private var accentColor: Color { Color(hex: "9680B7") }
    private var backgroundColor: Color { Color(.systemBackground) }
    private var surfaceColor: Color { colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6) }
    private var textColor: Color { Color.primary.opacity(0.8) }
    
    // 初始化方法
    init(postId: String) {
        _viewModel = StateObject(wrappedValue: HistoricalFigureSelectionViewModel(postId: postId))
    }
    
    // 添加接收postAuthor参数的初始化方法
    init(postId: String, postAuthor: String) {
        _viewModel = StateObject(wrappedValue: HistoricalFigureSelectionViewModel(postId: postId, postAuthor: postAuthor))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 顶部区域和分类，不滚动
                headerSection
                    .padding(.top, 8) // 增加顶部间距
                categorySection
                
                // 角色列表，可滚动
                figuresListView
                    .frame(maxHeight: .infinity)
                
                // 底部按钮区域，固定在底部
                VStack(spacing: 0) {
                    Divider()
                    bottomSection
                }
                .background(backgroundColor)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(backgroundColor)
            .onAppear {
                viewModel.loadHistoricalFigures()
            }
            .refreshable {
                viewModel.loadHistoricalFigures()
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    // MARK: - 界面组件
    
    // 历史人物列表视图
    private var figuresListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    // 加载中状态
                    ProgressView("加载中...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.vertical, 50)
                } else {
                    let figures = viewModel.filteredFigures(searchText: searchText, category: selectedCategory)
                    
                    if figures.isEmpty {
                        // 空状态
                        VStack(spacing: spacing * 2) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(secondaryColor)
                            
                            Text(searchText.isEmpty ? "没有找到相关角色" : "没有找到与\"\(searchText)\"相关的角色")
                                .font(.system(size: 16))
                                .foregroundColor(secondaryColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else {
                        // 角色网格
                        LazyVGrid(columns: gridColumns, spacing: spacing) {
                            ForEach(figures) { figure in
                                figureCell(figure)
                                    .padding(.vertical, spacing / 2)
                            }
                        }
                        .padding(.horizontal, spacing * 2)
                        .padding(.vertical, spacing)
                    }
                }
            }
            // 移除不必要的强制刷新，让SwiftUI自然管理视图更新
            // .id(UUID()) // 强制在数据变化时刷新视图
        }
    }
    
    // 顶部区域
    private var headerSection: some View {
        VStack(spacing: spacing) {
            // 标题和关闭按钮
            HStack {
                Spacer()
                
                Text("邀请角色参与讨论")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .padding(.horizontal, spacing * 2)
            .padding(.top, spacing)
            
            // 搜索框和一键邀请按钮
            HStack(spacing: spacing) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryColor)
                        .padding(.leading, spacing / 2)
                    
                    TextField("搜索历史人物", text: $searchText)
                        .font(.system(size: 14))
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(secondaryColor)
                                .padding(.trailing, spacing / 2)
                        }
                    }
                }
                .padding(.vertical, spacing * 0.75)
                .padding(.horizontal, spacing)
                .background(surfaceColor.opacity(0.8))
                .cornerRadius(17) // 更圆润的搜索框，半径为高度的一半
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .frame(maxWidth: .infinity, maxHeight: 34)
                
                Button(action: {
                    viewModel.oneClickInvite()
                }) {
                    Text("一键选择")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(primaryColor)
                        .padding(.horizontal, spacing * 1.5)
                        .padding(.vertical, spacing * 0.75)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 17)
                                .stroke(primaryColor, lineWidth: 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 17)
                                        .fill(surfaceColor.opacity(0.7))
                                )
                        )
                        .cornerRadius(17) // 更圆润的按钮，半径为高度的一半
                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                }
            }
            .padding(.horizontal, spacing * 2)
        }
        .padding(.bottom, spacing / 2)
    }
    
    // 分类标签栏
    private var categorySection: some View {
        VStack(spacing: 0) {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing * 1.5) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .font(.system(size: 13, weight: selectedCategory == category ? .medium : .regular))
                            .foregroundColor(selectedCategory == category ? primaryColor : secondaryColor.opacity(0.8))
                            .padding(.bottom, spacing * 0.75)
                            .overlay(
                                selectedCategory == category ?
                                Rectangle()
                                    .frame(height: 1.5)
                                    .foregroundColor(primaryColor)
                                    .offset(y: spacing / 4)
                                : nil,
                                alignment: .bottom
                            )
                    }
                    .padding(.horizontal, spacing / 2)
                }
            }
            .padding(.horizontal, spacing * 2)
            .padding(.vertical, spacing * 0.75)
        }
        .background(backgroundColor)
            
            // 角色数量指示器
            HStack {
                Spacer()
            }
        }
    }
    
    // 历史人物单元格
    private func figureCell(_ figure: CommentHistoricalFigure) -> some View {
        let isSelected = viewModel.isSelected(figure)
        
        return VStack(spacing: spacing) {
            ZStack(alignment: .topTrailing) {
                 // 头像 - 使用CharacterAvatarService确保显示首字母头像
                 CharacterAvatarService.shared.getAvatarView(
                     for: figure.avatarUrl,
                     name: figure.name,
                     category: "历史人物",
                     size: 48
                 )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? 
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor, accentColor]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), 
                            lineWidth: 3
                        )
                )
                .overlay(
                    // 选中状态的勾选标记
                    Group {
                        if isSelected {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(primaryColor)
                            }
                            .offset(x: 18, y: -18)
                            .scaleEffect(1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                        }
                    }
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                // 相关性标记
                if viewModel.isRelevant(figure) {
                    Text("相关")
                        .font(.system(size: 9))
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 0.5)
                        .background(accentColor)
                        .cornerRadius(3)
                        .offset(x: 0, y: -4)
                }
            }
            
            // 名字
            Text(figure.name)
                .font(.system(size: 13))
                .foregroundColor(textColor)
                .lineLimit(1)
        }
        .frame(height: 72)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleSelection(figure)
        }
        .onLongPressGesture {
            viewModel.showPreview(for: figure)
        }
    }
    
    // 底部区域
    private var bottomSection: some View {
        VStack(spacing: spacing * 0.75) {
            // 已选择的历史人物
            if !viewModel.selectedFigures.isEmpty {
                HStack {
                    Text("已选择：")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryColor)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing * 1.5) {
                            ForEach(viewModel.selectedFigures) { figure in
                                ZStack(alignment: .topTrailing) {
                                     // 头像 - 使用CharacterAvatarService确保显示首字母头像
                                     CharacterAvatarService.shared.getAvatarView(
                                         for: figure.avatarUrl,
                                         name: figure.name,
                                         category: "历史人物",
                                         size: 22
                                     )
                                    
                                    Button(action: {
                                        viewModel.toggleSelection(figure)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(secondaryColor)
                                            .background(backgroundColor)
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 2, y: -2)
                                    .padding(2)
                                }
                                .padding(.horizontal, spacing / 2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.selectedFigures.count)/5")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(secondaryColor)
                }
                .padding(.horizontal, spacing * 2)
                .padding(.top, spacing / 4)
            }
            
            // 邀请按钮 - 增强视觉效果
            Button(action: {
                // 添加触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                viewModel.inviteSelectedFigures()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("邀请参与")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42) // 固定高度
                    .background(
                        viewModel.selectedFigures.isEmpty
                        ? AnyView(Color.gray.opacity(0.5))
                        : AnyView(LinearGradient(
                            gradient: Gradient(colors: [primaryColor, accentColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
                    )
                    .cornerRadius(21) // 更圆润的按钮，半径为高度的一半
                    .shadow(color: viewModel.selectedFigures.isEmpty ? Color.clear : primaryColor.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .disabled(viewModel.selectedFigures.isEmpty)
            .padding(.horizontal, spacing * 2)
            .padding(.vertical, spacing / 4)
        }
        .padding(.bottom, 16) // 增加底部间距，让按钮位置稍微高一些
    }

    // 获取底部安全区域高度
    private func getSafeAreaBottom() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom
        }
        return 0
    }
}

struct HistoricalFigureSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        HistoricalFigureSelectionView(postId: "sample-post-id")
    }
} 