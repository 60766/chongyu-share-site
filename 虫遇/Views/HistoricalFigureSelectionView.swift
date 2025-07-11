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
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // 颜色系统
    private var primaryColor: Color { Color.warmAccent }
    private var secondaryColor: Color { Color.secondary }
    private var accentColor: Color { Color.orange }
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
        VStack(spacing: 0) {
            // 顶部区域：标题和搜索框
            headerSection
            
            // 分类标签栏
            categorySection
            
            // 历史人物列表
            figureListSection
            
            // 底部区域：已选择提示和确认按钮
            bottomSection
        }
        .background(backgroundColor)
        .onAppear {
            viewModel.loadHistoricalFigures()
        }
    }
    
    // MARK: - 界面组件
    
    // 顶部区域
    private var headerSection: some View {
        VStack(spacing: spacing * 2) {
            // 标题和关闭按钮
            HStack {
                Text("邀请角色参与讨论")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(secondaryColor)
                        .padding(spacing)
                        .background(surfaceColor)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, spacing * 2)
            .padding(.top, spacing * 2)
            
            // 搜索框和一键邀请按钮
            HStack(spacing: spacing) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(secondaryColor)
                        .padding(.leading, spacing / 2)
                    
                    TextField("搜索历史人物", text: $searchText)
                        .font(.system(size: 13))
                    
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
                .padding(.vertical, spacing)
                .padding(.horizontal, spacing)
                .background(surfaceColor)
                .cornerRadius(cornerRadius)
                .frame(maxWidth: .infinity, maxHeight: 36)
                
                Button(action: {
                    viewModel.oneClickInvite()
                }) {
                    Text("一键邀请")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, spacing * 1.5)
                        .padding(.vertical, spacing)
                        .frame(height: 36)
                        .background(primaryColor)
                        .cornerRadius(cornerRadius)
                }
            }
            .padding(.horizontal, spacing * 2)
        }
        .padding(.bottom, spacing)
    }
    
    // 分类标签栏
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing * 3) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .font(.system(size: 14, weight: selectedCategory == category ? .medium : .regular))
                            .foregroundColor(selectedCategory == category ? primaryColor : secondaryColor)
                            .padding(.bottom, spacing)
                            .overlay(
                                selectedCategory == category ?
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(primaryColor)
                                    .offset(y: spacing / 2)
                                : nil,
                                alignment: .bottom
                            )
                    }
                    .padding(.horizontal, spacing / 2)
                }
            }
            .padding(.horizontal, spacing * 2)
            .padding(.vertical, spacing)
        }
        .background(backgroundColor)
    }
    
    // 历史人物列表
    private var figureListSection: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(viewModel.filteredFigures(searchText: searchText, category: selectedCategory)) { figure in
                    figureCell(figure)
                        .padding(.vertical, spacing / 2)
                }
            }
            .padding(.horizontal, spacing * 2)
            .padding(.vertical, spacing)
        }
    }
    
    // 历史人物单元格
    private func figureCell(_ figure: CommentHistoricalFigure) -> some View {
        let isSelected = viewModel.isSelected(figure)
        
        return VStack(spacing: spacing) {
            ZStack(alignment: .topTrailing) {
                // 头像
                Group {
                    // 尝试加载角色专属头像
                    if let avatarImage = viewModel.getCharacterAvatar(for: figure.name) {
                        Image(avatarImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                    } else {
                        // 使用系统图标作为备用
                        Image(systemName: viewModel.getAvatarSymbol(for: figure.name))
                            .resizable()
                            .scaledToFit()
                    }
                }
                .padding(spacing)
                .frame(width: 48, height: 48)
                .background(surfaceColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 2)
                )
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(primaryColor)
                        .background(backgroundColor)
                        .clipShape(Circle())
                        .offset(x: 2, y: -2)
                }
                
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
        VStack(spacing: spacing * 2) {
            // 已选择的历史人物
            if !viewModel.selectedFigures.isEmpty {
                HStack {
                    Text("已选择：")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(secondaryColor)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing * 2) {
                            ForEach(viewModel.selectedFigures) { figure in
                                ZStack(alignment: .topTrailing) {
                                    // 尝试加载角色专属头像
                                    if let avatarImage = viewModel.getCharacterAvatar(for: figure.name) {
                                        Image(avatarImage)
                                            .resizable()
                                            .scaledToFit()
                                            .padding(spacing / 2)
                                            .frame(width: 24, height: 24)
                                            .background(surfaceColor)
                                            .clipShape(Circle())
                                    } else {
                                        // 使用系统图标作为备用
                                        Image(systemName: viewModel.getAvatarSymbol(for: figure.name))
                                            .resizable()
                                            .scaledToFit()
                                            .padding(spacing / 2)
                                            .frame(width: 24, height: 24)
                                            .background(surfaceColor)
                                            .clipShape(Circle())
                                    }
                                    
                                    Button(action: {
                                        viewModel.toggleSelection(figure)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(secondaryColor)
                                            .background(backgroundColor)
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 2, y: -2)
                                    .padding(4)
                                }
                                .padding(.horizontal, spacing / 2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.selectedFigures.count)/5")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(secondaryColor)
                }
                .padding(.horizontal, spacing * 2)
                .padding(.top, spacing / 2)
            }
            
            // 邀请按钮
            Button(action: {
                viewModel.inviteSelectedFigures()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("邀请参与")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, spacing * 1.5)
                    .background(viewModel.selectedFigures.isEmpty ? Color.gray.opacity(0.6) : primaryColor)
                    .cornerRadius(cornerRadius)
            }
            .disabled(viewModel.selectedFigures.isEmpty)
            .padding(.horizontal, spacing * 2)
            .padding(.bottom, spacing * 3)
            .padding(.top, spacing)
        }
        .padding(.top, spacing)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(surfaceColor),
            alignment: .top
        )
    }
}

struct HistoricalFigureSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        HistoricalFigureSelectionView(postId: "sample-post-id")
    }
} 