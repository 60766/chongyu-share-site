import SwiftUI

/**
 * 中文字符集扩展
 */
extension CharacterSet {
    static var chineseCharacters: CharacterSet {
        return CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")
    }
}

/**
 * 评论视图组件
 * 显示单条评论，支持点赞、回复等操作
 * 采用极简设计风格，优化阅读体验
 */
struct CommentView: View {
    // 评论数据
    let comment: DetailedCommentModel
    
    // 回调函数
    var onReply: (DetailedCommentModel) -> Void
    var onLike: (DetailedCommentModel) -> Void
    
    // 本地状态
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var showOptions: Bool = false
    @State private var isPressed: Bool = false
    
    // 头像服务
    private let avatarService = CharacterAvatarService.shared
    
    // 初始化函数
    init(comment: DetailedCommentModel, onReply: @escaping (DetailedCommentModel) -> Void = { _ in }, onLike: @escaping (DetailedCommentModel) -> Void = { _ in }) {
        self.comment = comment
        self.onReply = onReply
        self.onLike = onLike
        
        // 初始化本地状态，默认为未点赞
        _isLiked = State(initialValue: false)
        _likeCount = State(initialValue: comment.likes)
        
        // 调试信息
        if comment.isVirtualCharacter {
            print("🔍 创建虚拟角色评论视图 - 角色ID: \(comment.characterID ?? "未知"), 用户名: \(comment.username)")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 评论内容容器 - 移除多余的阴影和边框，使设计更简洁
            VStack(alignment: .leading, spacing: 8) {
                // 用户信息区
                HStack(alignment: .center, spacing: 10) {
                    // 用户头像 - 优先使用CharacterAvatarService
                    AvatarView(comment: comment, avatarService: avatarService)
                    
                    // 用户名和标签区域
                    HStack(alignment: .top, spacing: 4) {
                        // 用户名 - 根据评论类型使用不同数据源
                        Text(comment.isCurrentUser ? UserProfileManager.shared.getCurrentUsername() : getUserDisplayName(comment: comment))
                            .font(DesignSystem.Typography.subheadline.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.commentPrimaryText)
                        
                        // 添加调试日志
                        .onAppear {
                            if comment.isVirtualCharacter {
                                print("🔍 CommentView显示用户名: \(comment.username), 角色ID: \(comment.characterID ?? "未知")")
                                if let characterID = comment.characterID, characterID.lowercased() == "kongzi" {
                                    print("⚠️ 检测到孔子评论，显示名称: \(comment.username)")
                                }
                            }
                        }
                        
                        // 虚拟角色标签
                        if comment.isVirtualCharacter {
                            let tagColor = getCategoryTagColor(for: comment.characterID ?? "")
                            Text(getCategoryTag(for: comment.characterID ?? ""))
                                .font(.system(size: 10.0, weight: .regular))  // 与主页面标签一致
                                .padding(.horizontal, 6.0)  // 与主页面标签一致
                                .padding(.vertical, 3.0)    // 与主页面标签一致
                                .background(tagColor.opacity(0.08))  // 与主页面标签一致
                                .foregroundColor(tagColor.opacity(0.7))  // 与主页面标签一致
                                .cornerRadius(5.0)  // 与主页面标签一致
                        }
                        
                        Spacer()
                        
                        // 时间标签
                        Text(comment.getFormattedTimeAgo())
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 更多操作按钮 - 精简样式
                    Button(action: {
                        hapticFeedback(style: .light)
                        showOptions.toggle()
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .medium)) // 稍小的图标
                            .foregroundColor(Color(.systemGray3))
                            .padding(6)
                            .contentShape(Circle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // 评论内容 - 增强排版和阅读体验
                Text(comment.content)
                    .font(DesignSystem.Typography.commentText)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .kerning(0.3) // 添加字符间距，提升数字和字母的可读性
                    .lineSpacing(6) // 适当增加行间距提高优雅感
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                
            }
            .background(
                comment.isVirtualCharacter ? 
                    Color.orange.opacity(0.02) : // 极淡的背景色差异
                    Color.clear // 使用透明背景，继承父视图背景色
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        comment.isVirtualCharacter ? 
                            Color.orange.opacity(0.08) : // 极淡的边框
                            Color(.systemGray5).opacity(0.6), // 更淡的边框
                        lineWidth: 0.5 // 极细的边框
                    )
            )
            // 移除阴影以实现更极简的设计
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            // 点赞选项
            Button(action: {
                toggleLike()
            }) {
                Label(
                    isLiked ? "取消点赞" : "点赞",
                    systemImage: isLiked ? "heart.slash" : "heart"
                )
            }
            
            // 回复选项
            Button(action: {
                onReply(comment)
            }) {
                Label("回复评论", systemImage: "arrowshape.turn.up.left")
            }
            
            // 复制选项
            Button(action: {
                UIPasteboard.general.string = comment.content
                hapticFeedback(style: .medium)
            }) {
                Label("复制内容", systemImage: "doc.on.doc")
            }
        }
        .onTapGesture {
            // 点击评论区域轻触反馈
            hapticFeedback(style: .soft)
        }
    }
    
    /**
     * 触感反馈
     */
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /**
     * 切换点赞状态
     */
    private func toggleLike() {
        // 触感反馈
        hapticFeedback(style: .light)
        
        // 更新状态 - 使用更快的动画
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            isLiked.toggle()
            likeCount += isLiked ? 1 : -1
        }
        
        // 调用回调
        onLike(comment)
    }
    
    /**
     * 将时间转换为友好的文本格式
     */
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year >= 1 { return "\(year)年前" }
        if let month = components.month, month >= 1 { return "\(month)月前" }
        if let week = components.weekOfYear, week >= 1 { return "\(week)周前" }
        if let day = components.day, day >= 1 { return "\(day)天前" }
        if let hour = components.hour, hour >= 1 { return "\(hour)小时前" }
        if let minute = components.minute, minute >= 1 { return "\(minute)分钟前" }
        return "刚刚"
    }

    /**
     * 获取用户显示名称
     * 对于虚拟角色，使用与评论创建时相同的数据源
     */
    private func getUserDisplayName(comment: DetailedCommentModel) -> String {
        if comment.isVirtualCharacter, let characterID = comment.characterID {
            // 使用与评论创建时相同的数据源：CharacterDataManager
            if let chineseName = CharacterDataManager.shared.getName(for: characterID) {
                return chineseName
            }
            
            // 如果CharacterDataManager找不到，检查用户名是否已经是中文
            if comment.username.rangeOfCharacter(from: .chineseCharacters) != nil {
                return comment.username
            }
            
            // 最后返回原始用户名
            return comment.username
        }
        
        return comment.username
    }

    /**
     * 获取分类标签
     */
    private func getCategoryTag(for characterID: String) -> String {
        // 直接从AvatarService获取，保持统一
        return avatarService.getCharacterCategoryTag(for: characterID)
    }

    /**
     * 获取分类标签颜色
     */
    private func getCategoryTagColor(for characterID: String) -> Color {
        // 直接从AvatarService获取，保持统一
        return avatarService.getCharacterTagColor(for: characterID)
    }
    
    // MARK: - 辅助视图
    
    /**
     * 头像视图
     * 根据评论类型显示不同的头像
     */
    struct AvatarView: View {
        let comment: DetailedCommentModel
        let avatarService: CharacterAvatarService
        
        var body: some View {
            if comment.isVirtualCharacter {
                // 虚拟角色头像
                if let characterID = comment.characterID {
                    // 使用统一的Avatar组件
                    Avatar(
                        url: characterID,
                        name: comment.username,
                        category: avatarService.getCharacterCategoryTag(for: characterID),
                        size: 36
                    )
                    .onAppear {
                        print("🔍 CommentView.AvatarView - 显示虚拟角色头像: \(characterID), 用户名: \(comment.username)")
                        
                        // 检查图片是否存在
                        let exists = avatarService.checkImageExistence(imageName: characterID)
                        print("🔍 CommentView.AvatarView - 角色头像检查 - \(characterID): \(exists ? "存在" : "不存在")")
                    }
            } else {
                    // 没有角色ID的虚拟角色，使用用户名生成字母头像
                    Avatar(
                        url: comment.userAvatar,
                        name: comment.username,
                        size: 36
                    )
                    .onAppear {
                        print("⚠️ CommentView.AvatarView - 虚拟角色没有characterID，使用userAvatar: \(comment.userAvatar)")
                }
                }
            } else {
                // 普通用户头像
                Avatar(
                    url: comment.userAvatar,
                    name: comment.username,
                    size: 36
                )
                .onAppear {
                    print("🔍 CommentView.AvatarView - 显示普通用户头像: \(comment.userAvatar)")
                }
            }
        }
    }
    
    /// 历史人物头像视图
    struct HistoricalFigureAvatarView: View {
        let characterID: String
        let avatarPath: String // 添加avatarPath参数接收从AvatarView传来的路径
        
        var body: some View {
            Group {
                // 尝试多种方式加载头像
                if let image = loadImageFromFileSystem() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .onAppear {
                            print("✅ 成功加载历史人物头像: \(characterID)")
                        }
                } 
                // 如果文件系统加载失败，显示文字头像
                else {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Text(String(characterID.prefix(1).uppercased()))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .onAppear {
                        print("⚠️ 无法加载历史人物头像，显示文字头像: \(characterID)")
                        print("⚠️ 尝试的头像路径: \(avatarPath)")
                        debugPrintImagePaths(characterID)
                    }
                }
            }
        }
        
        /// 直接从文件系统加载图片
        private func loadImageFromFileSystem() -> UIImage? {
            // 1. 首先尝试使用UIImage(named:)加载，这是最简单的方式
            // 尝试多种可能的命名格式
            let possibleNames = [
                characterID,
                characterID.lowercased(),
                "HistoricalFigures/\(characterID)",
                "HistoricalFigures/\(characterID.lowercased())",
                avatarPath,
                avatarPath.lowercased()
            ]
            
            for name in possibleNames {
                if let image = UIImage(named: name) {
                    print("✅ 成功使用UIImage(named:)加载头像: \(name)")
                    return image
                }
            }
            
            // 2. 如果UIImage(named:)失败，尝试直接从文件系统加载
            guard let resourcePath = Bundle.main.resourcePath else { 
                print("❌ 无法获取资源路径")
                return nil 
            }
            
            // 从avatarPath中提取角色ID，以便正确处理路径
            let extractedID: String
            if avatarPath.contains("/") {
                extractedID = avatarPath.components(separatedBy: "/").last ?? characterID
            } else {
                extractedID = avatarPath.isEmpty ? characterID : avatarPath
            }
            
            print("🔍 从avatarPath提取的ID: \(extractedID)")
            
            // 尝试多个可能的路径
            let possiblePaths = [
                // 1. 使用标准的HistoricalFigures路径
                resourcePath + "/Assets.xcassets/HistoricalFigures/\(extractedID.lowercased()).imageset/\(extractedID.lowercased()).png",
                resourcePath + "/Assets.xcassets/HistoricalFigures/\(characterID.lowercased()).imageset/\(characterID.lowercased()).png",
                
                // 2. 直接使用avatarPath
                resourcePath + "/\(avatarPath).png",
                
                // 3. 使用标准的HistoricalFigures路径
                resourcePath + "/HistoricalFigures/\(extractedID).png",
                resourcePath + "/HistoricalFigures/\(extractedID.lowercased()).png",
                
                // 4. 直接在根目录查找
                resourcePath + "/\(extractedID).png",
                resourcePath + "/\(extractedID.lowercased()).png",
                
                // 5. 在Assets.xcassets中查找
                resourcePath + "/Assets.xcassets/HistoricalFigures/\(extractedID).imageset/\(extractedID).png",
                
                // 6. 在不同的Assets.xcassets路径中查找
                resourcePath + "/Assets.xcassets/\(extractedID).imageset/\(extractedID).png"
            ]
            
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path) {
                    print("✅ 文件存在: \(path)")
                    if let image = UIImage(contentsOfFile: path) {
                        print("✅ 成功加载头像图片: \(path)")
                        return image
                    }
                }
            }
            
            // 3. 尝试在备份目录中查找
            let backupPaths = [
                resourcePath + "/backup_assets_20250730181514/HistoricalFigures/\(extractedID.lowercased()).imageset/\(extractedID.lowercased()).png",
                resourcePath + "/backup_assets_20250730181514/HistoricalFigures/\(characterID.lowercased()).imageset/\(characterID.lowercased()).png"
            ]
            
            for path in backupPaths {
                if FileManager.default.fileExists(atPath: path) {
                    print("✅ 文件存在于备份目录: \(path)")
                    if let image = UIImage(contentsOfFile: path) {
                        print("✅ 成功从备份目录加载头像: \(path)")
                        return image
                    }
                }
            }
            
            print("❌ 所有路径尝试失败，无法加载头像: \(characterID)")
            return nil
        }
        
        /// 打印调试信息，帮助诊断问题
        private func debugPrintImagePaths(_ characterID: String) {
            print("🔍 调试图片路径 - 角色ID: \(characterID)")
            
            if let resourcePath = Bundle.main.resourcePath {
                print("📁 资源路径: \(resourcePath)")
                
                // 检查Assets.xcassets中的HistoricalFigures目录
                let assetPath = resourcePath + "/Assets.xcassets/HistoricalFigures"
                if FileManager.default.fileExists(atPath: assetPath) {
                    print("✅ HistoricalFigures目录存在: \(assetPath)")
                } else {
                    print("❌ HistoricalFigures目录不存在: \(assetPath)")
                }
                
                // 检查备份目录
                let backupPath = resourcePath + "/backup_assets_20250730181514/HistoricalFigures"
                if FileManager.default.fileExists(atPath: backupPath) {
                    print("✅ 备份HistoricalFigures目录存在: \(backupPath)")
                } else {
                    print("❌ 备份HistoricalFigures目录不存在: \(backupPath)")
                }
            }
        }
    }
    
}

/**
 * 评论列表视图
 */
struct CommentListContainer: View {
    let comments: [DetailedCommentModel]
    let onReply: (DetailedCommentModel) -> Void
    let onLike: (DetailedCommentModel) -> Void
    
    // 触觉反馈
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    // 使用TabBarManager获取底部安全区域高度
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 缓存虚拟角色评论数量避免频繁计算
    private var virtualCommentCount: Int {
        comments.filter { $0.isVirtualCharacter }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 评论标题
            HStack {
                Text("评论")
                    .font(DesignSystem.Typography.title3.weight(.bold))
                
                Text("(\(comments.count))")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                // 虚拟角色评论数量
                if virtualCommentCount > 0 {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "sparkles")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(.orange)
                        
                        Text("\(virtualCommentCount)位历史人物参与")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.s)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(DesignSystem.Radius.m)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.l)
            .padding(.vertical, DesignSystem.Spacing.m)
            
            if comments.isEmpty {
                // 空状态
                VStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                    
                    Text("暂无评论")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("快来发表第一条评论吧")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.top, DesignSystem.Spacing.xs)
                        
                    Button(action: {
                        feedbackGenerator.impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("写评论")
                        }
                        .font(DesignSystem.Typography.subheadline)
                        .padding(.horizontal, DesignSystem.Spacing.l)
                        .padding(.vertical, DesignSystem.Spacing.s)
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.Radius.l)
                    }
                    .padding(.top, DesignSystem.Spacing.m)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
            } else {
                // 评论列表 - 使用LazyVStack优化性能
                LazyVStack(spacing: 0) {
                    // 在每次更新时保持评论ID稳定，避免重新创建视图
                    ForEach(comments) { comment in
                        CommentView(
                            comment: comment,
                            onReply: onReply,
                            onLike: onLike
                        )
                        // 每个评论项后添加分隔线，提高可读性
                        if comment.id != comments.last?.id {
                            Divider()
                                .padding(.horizontal, DesignSystem.Spacing.l)
                        }
                    }
                    
                    // 底部安全区域填充 - 确保所有内容可见
                    Color.clear
                        .frame(height: 60)
                        .id("commentsBottomSpacer")
                }
            }
        }
        .background(Color(hex: "#EFEEE8")) // rgb(239,238,232) 嵌套评论背景色
        .onAppear {
            // 准备触觉反馈
            feedbackGenerator.prepare()
        }
    }
}

/**
 * 预览
 */
struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            // 普通用户评论
            CommentView(
                comment: DetailedCommentModel(
                    username: "用户123",
                    userAvatar: "person.circle.fill",
                    content: "这是一条普通用户评论，评论内容可以很长很长很长很长很长很长很长很长很长很长很长很长很长很长。",
                    datePosted: Date().addingTimeInterval(-3600),
                    isVirtualCharacter: false,
                    characterID: nil,
                    likes: 5
                ),
                onReply: { _ in },
                onLike: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .background(DesignSystem.Colors.background)
            
            // 历史人物评论
            CommentView(
                comment: DetailedCommentModel(
                    username: "爱因斯坦",
                    userAvatar: "einstein",
                    content: "这是一条历史人物评论，带有特殊样式。相对论改变了我们对时间和空间的认识。",
                    datePosted: Date().addingTimeInterval(-7200),
                    isVirtualCharacter: true,
                    characterID: "einstein",
                    likes: 120
                ),
                onReply: { _ in },
                onLike: { _ in }
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .background(DesignSystem.Colors.background)
        }
    }
} 