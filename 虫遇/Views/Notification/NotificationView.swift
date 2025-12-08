import SwiftUI
import SwiftData

/**
 * 虫洞通知页面
 * 显示用户收到的各类通知，包括评论、点赞、关注和系统通知
 */
struct NotificationView: View {
    @Environment(\.modelContext) private var modelContext
    // 当前选中的选项卡
    @State private var selectedTab: NotificationTab = .all
    // 滚动偏移量
    @State private var scrollOffset: CGFloat = 0

    // 动画状态
    @State private var animateHeader = false
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 通知服务
    @ObservedObject private var notificationService = NotificationService.shared
    
    // 创建测试通知的方法 - 已删除预设数据
    private func createTestNotificationWithUserComment() {
        // 已删除预设的测试通知数据
    }
    
    // 通知选项卡类型
    enum NotificationTab: String, CaseIterable {
        case all = "全部"
        case interactions = "互动"  // 合并评论、点赞、关注
        case system = "系统"        // 系统消息
        
        var icon: String {
            switch self {
            case .all: return "bell.fill"
            case .interactions: return "bubble.left.and.bubble.right.fill"
            case .system: return "gear.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return Color.gray.opacity(0.6)
            case .interactions: return Color.blue.opacity(0.45)
            case .system: return Color.orange.opacity(0.45)
            }
        }
    }
    
    // 今日互动统计 - 重新设计为更全面的统计
    private var todayInteractionStats: (
        aiPosts: Int,
        replies: Int,
        activeCharacters: [(name: String, image: String?, count: Int)],
        privateChatCharacters: [(name: String, image: String?)],
        invitedCharacters: Int,
        likeInteractions: Int,
        firstTimeCharactersCount: Int,
        firstTimeCharacters: [(name: String, image: String?)],
        unreadInteractions: Int
    ) {
        // 添加错误处理，防止崩溃
        do {
            return try todayInteractionStatsImpl()
        } catch {
            #if DEBUG
            debugLog("❌ 计算今日互动统计失败: \(error.localizedDescription)")
            #endif
            // 返回默认值
            return (0, 0, [], [], 0, 0, 0, [], 0)
        }
    }
    
    private func todayInteractionStatsImpl() throws -> (
        aiPosts: Int,
        replies: Int,
        activeCharacters: [(name: String, image: String?, count: Int)],
        privateChatCharacters: [(name: String, image: String?)],
        invitedCharacters: Int,
        likeInteractions: Int,
        firstTimeCharactersCount: Int,
        firstTimeCharacters: [(name: String, image: String?)],
        unreadInteractions: Int
    ) {
        // 时间边界：今日起止
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? Date()
        func isToday(_ date: Date) -> Bool { date >= startOfToday && date < endOfToday }

        // 1) AI帖子数：今天来源为 onekey 或 wormhole 的帖子
        let posts = PostViewModel.shared.posts
        let aiPosts = posts.filter { post in
            let isAiSource = (post.source == "onekey" || post.source == "wormhole")
            return isAiSource && isToday(post.datePosted)
        }.count

        // 2) 今日通知（用于回复数、活跃角色、点赞）
        
        // 回复数：只统计今天虚拟角色与用户互动的评论和回复
        let todayUserInteractionComments = posts.flatMap { post -> [DetailedCommentModel] in
            post.comments.filter { c in
                // 只统计今天的虚拟角色评论，且满足以下条件之一：
                // 1. 回复用户的评论（replyToUsername不为空且被回复者不是虚拟角色）
                // 2. 在用户发布的帖子下的顶级评论
                guard c.isVirtualCharacter && isToday(c.datePosted) else { return false }
                
                // 如果是回复，检查是否回复的是用户（非虚拟角色）
                if let replyToUsername = c.replyToUsername {
                    // 检查被回复的用户是否是虚拟角色
                    let allCharacterNames = CharacterDataManager.shared.getAllCharactersInfo().map { $0.name }
                    return !allCharacterNames.contains(replyToUsername)  // 只有回复真实用户才算
                }
                
                // 如果是顶级评论，检查帖子作者是否是真实用户
                if c.replyToUsername == nil {
                    // 检查帖子作者是否是虚拟角色
                    let allCharacterNames = CharacterDataManager.shared.getAllCharactersInfo().map { $0.name }
                    return !allCharacterNames.contains(post.username)  // 只有在真实用户帖子下的评论才算
                }
                
                return false
            }
        }
        let replies = todayUserInteractionComments.count

        // 3) 活跃角色 Top3：今天在帖子里与用户产生互动的虚拟角色次数Top3
        let activeCounts: [String: Int] = posts.reduce(into: [:]) { dict, post in
            // 只统计与用户互动的虚拟角色评论
            for c in post.comments where c.isVirtualCharacter && isToday(c.datePosted) {
                // 应用与回复统计相同的过滤逻辑
                var shouldCount = false
                
                // 如果是回复，检查是否回复的是用户（非虚拟角色）
                if let replyToUsername = c.replyToUsername {
                    let allCharacterNames = CharacterDataManager.shared.getAllCharactersInfo().map { $0.name }
                    shouldCount = !allCharacterNames.contains(replyToUsername)
                }
                // 如果是顶级评论，检查帖子作者是否是真实用户
                else if c.replyToUsername == nil {
                    let allCharacterNames = CharacterDataManager.shared.getAllCharactersInfo().map { $0.name }
                    shouldCount = !allCharacterNames.contains(post.username)
                }
                
                if shouldCount {
                    let characterID = c.characterID ?? ""
                    let key = CharacterDataManager.shared.getName(for: characterID) ?? c.username
                    if !key.isEmpty {
                        dict[key, default: 0] += 1
                    }
                }
            }
        }
        let top3Active = activeCounts.sorted { $0.value > $1.value }.prefix(3)
        // 预先建立名称->ID映射，避免在循环中重复创建
        let infoList = CharacterDataManager.shared.getAllCharactersInfo()
        let nameToIdMap: [String: String] = {
            var map: [String: String] = [:]
            for info in infoList {
                map[info.name] = info.id
            }
            return map
        }()
        
        let activeCharacters: [(name: String, image: String?, count: Int)] = top3Active.map { (name, count) in
            let normalized = name.folding(options: .diacriticInsensitive, locale: .current)
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
            let id = nameToIdMap[name] ?? normalized
            let imageName = CharacterAvatarService.shared.getAvatarName(for: id)
            return (name: name, image: imageName, count: count)
        }

        // 4) 深度对话角色：单聊中今天消息总数最多的前三人
        // 读取 SwiftData 中的 Message 和 SDConversation
        var privateChatCountByCharacter: [String: Int] = [:]
        do {
            // 按角色聚合今天消息（双向计数）
            let msgPredicate = #Predicate<Message> { msg in
                msg.timestamp >= startOfToday && msg.timestamp < endOfToday
            }
            let msgDescriptor = FetchDescriptor<Message>(predicate: msgPredicate)
            let messages = try modelContext.fetch(msgDescriptor)
            for m in messages {
                // 角色ID在 senderId/receiverId 之一，用户ID假定为 currentUser 或非历史ID
                let characterId: String
                if m.senderId == "currentUser" { 
                    characterId = m.receiverId 
                } else if m.receiverId == "currentUser" { 
                    characterId = m.senderId 
                } else { 
                    characterId = m.senderId 
                }
                
                // 确保characterId不为空
                if !characterId.isEmpty && characterId != "currentUser" {
                    privateChatCountByCharacter[characterId, default: 0] += 1
                }
            }
        } catch {
            #if DEBUG
            debugLog("❌ 读取单聊消息失败: \(error.localizedDescription)")
            #endif
        }
        let top3Private = privateChatCountByCharacter.sorted { $0.value > $1.value }.prefix(3)
        let privateChatCharacters: [(name: String, image: String?)] = top3Private.compactMap { (id, _) in
            guard !id.isEmpty else { return nil }
            let name = CharacterDataManager.shared.getName(for: id) ?? id
            let imageName = CharacterAvatarService.shared.getAvatarName(for: id)
            return (name: name, image: imageName)
        }

        // 5) 邀请角色数：今天邀请产生的顶级虚拟评论数量（不包括回复）
        let todayInvitedComments = posts.flatMap { post -> [DetailedCommentModel] in
            post.getTopLevelComments().filter { c in
                // 顶级且虚拟角色（邀请产生），且今天
                c.isVirtualCharacter && c.replyToUsername == nil && isToday(c.datePosted)
            }
        }
        let invitedCharacters = todayInvitedComments.count

        // 6) 点赞互动数：今天的点赞通知数量
        let likeInteractions = notificationService.notifications.filter { notification in
            notification.type == .like && isToday(notification.createdAt)
        }.count

        // 7) 新相遇角色：第一次与用户互动的角色，首次互动时间在今天
        // 依据单聊会话的创建时间或首次虚拟评论时间
        var firstMetSet = Set<String>()
        // 单聊会话
        do {
            let convPredicate = #Predicate<SDConversation> { conv in
                conv.createdAt >= startOfToday && conv.createdAt < endOfToday
            }
            let convDescriptor = FetchDescriptor<SDConversation>(predicate: convPredicate)
            let conversations = try modelContext.fetch(convDescriptor)
            for conv in conversations {
                if !conv.characterId.isEmpty {
                    firstMetSet.insert(conv.characterId)
                }
            }
        } catch {
            #if DEBUG
            debugLog("❌ 读取会话失败: \(error.localizedDescription)")
            #endif
        }
        // 虚拟评论首次出现在今天（需要查看该角色在所有帖子中最早的虚拟评论是否在今天）
        // 简化：若该角色今天首次出现（没有更早的顶级虚拟评论），则计入
        let todayVirtualByRole = posts.flatMap { $0.getTopLevelComments().filter { $0.isVirtualCharacter && isToday($0.datePosted) } }
        let roleToEarliest = Dictionary(grouping: todayVirtualByRole, by: { comment in
            let roleId = comment.characterID ?? comment.username
            return roleId.isEmpty ? "unknown" : roleId
        }).compactMapValues { arr in
            arr.min(by: { $0.datePosted < $1.datePosted })?.datePosted
        }
        
        for (roleId, _) in roleToEarliest {
            if !roleId.isEmpty && roleId != "unknown" {
                // 检查是否存在早于今天的同角色顶级虚拟评论
                let hasEarlier = posts.contains { p in
                    p.getTopLevelComments().contains { c in
                        c.isVirtualCharacter && 
                        (c.characterID ?? c.username) == roleId && 
                        c.datePosted < startOfToday
                    }
                }
                if !hasEarlier { 
                    firstMetSet.insert(roleId) 
                }
            }
        }
        let firstTimeCharacters: [(name: String, image: String?)] = firstMetSet.compactMap { id in
            guard !id.isEmpty else { return nil }
            let name = CharacterDataManager.shared.getName(for: id) ?? id
            let imageName = CharacterAvatarService.shared.getAvatarName(for: id)
            return (name: name, image: imageName)
        }
        let firstTimeCharactersCount = firstTimeCharacters.count

        // 8) 未读互动数：暂无精确未读模型，这里先等同今日AI评论数
        let unreadInteractions = replies

        return (
            aiPosts,
            replies,
            activeCharacters,
            privateChatCharacters,
            invitedCharacters,
            likeInteractions,
            firstTimeCharactersCount,
            firstTimeCharacters,
            unreadInteractions
        )
    }
    
    // 筛选后的通知
    private var filteredNotifications: [NotificationModel] {
        notificationService.notifications.filter { shouldShowNotification(type: $0.type, selectedTab: selectedTab) }
    }
    
    var body: some View {
        // 🔒 修复：在 iPad 上使用 stack 导航样式，避免侧边栏布局导致内容显示不完整
        NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // 背景层 - 与探索界面一致的温暖米白色背景
                    DesignSystem.Colors.background
                        .ignoresSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // 美化的顶部标题 - 参考探索页面风格
                        HStack {
                            Text("虫洞通知")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.primary.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 0.5)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4) // 减少底部间距
                        
                        // 分类选项卡 - 精致化设计，调整顶部间距
                        TabSwitcherView(selectedTab: $selectedTab)
                            .padding(.top, 4) // 减少顶部内边距，从默认的更大值调整为4
                            .padding(.bottom, 12)
                            .background(
                                Rectangle()
                                    .fill(.regularMaterial)
                                    .opacity(0.3)
                            )
                        
                        // 通知列表 - 优化间距和布局
                        ScrollViewReader { scrollProxy in
                        ScrollView {
                            
                            // 偏好设置检测
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: AppScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scrollView")).minY
                                )
                            }
                            .frame(height: 0)
                            
                            // 扁平化通知列表 - 优化动画和间距
                            LazyVStack(spacing: 10) {
                                // 今日互动统计卡片（仅在互动标签下显示，作为第一个可滑动项目）
                                if selectedTab == .interactions {
                                    todayStatsCardView
                                        .padding(.horizontal, 14)
                                        .padding(.bottom, 8)
                                        .id("todayStatsCard")
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.96).combined(with: .opacity).combined(with: .move(edge: .top)),
                                            removal: .scale(scale: 0.96).combined(with: .opacity)
                                        ))
                                        .animation(
                                            .spring(response: 0.6, dampingFraction: 0.8),
                                            value: selectedTab
                                        )
                                }
                                ForEach(Array(filteredNotifications.enumerated()), id: \.element.id) { index, notification in
                                    Group {
                                        if notification.type == .system {
                                            SystemNotificationView(notification: notification, scrollProxy: scrollProxy)
                                        } else {
                                            NotificationItemView(notification: notification)
                                        }
                                    }
                                    .id("\(notification.id)-\(selectedTab)")
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.96).combined(with: .opacity).combined(with: .move(edge: .top)),
                                        removal: .scale(scale: 0.96).combined(with: .opacity)
                                    ))
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05),
                                        value: selectedTab
                                    )
                                }
                                
                                // 确保内容不被TabBar遮挡的底部填充
                                Color.clear
                                    .frame(height: max(0, tabBarManager.fullBottomAreaHeight - (tabBarManager.bottomSafeAreaHeight * 0.5)))
                                    .id("bottomSpacer")
                            }
                            .padding(.top, 4)
                            .padding(.horizontal, 2)
                            .frame(width: geometry.size.width)
                        }
                        .background(Color.clear)
                        .coordinateSpace(name: "scrollView")
                        .onPreferenceChange(AppScrollOffsetPreferenceKey.self) { offset in
                            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                                scrollOffset = -offset
                            }
                            }
                        }
                    }
                }
                .background(DesignSystem.Colors.background)
                .onAppear {
                    // 🚀 轻量化onAppear，避免页面切换卡顿
                    
                    // 立即触发头部动画，无需延迟
                    animateHeader = true
                    
                    // 延迟执行重型操作，不阻塞页面切换
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 修复系统通知内容
                        notificationService.fixSystemNotificationContent()
                        
                        // 清理重复通知
                        notificationService.manualCleanupDuplicates()
                        
                        // 生成系统通知（如果还没有的话）
                        notificationService.generateAdditionalSystemNotifications()
                    }
                }
                .onDisappear {
                    // 无全局设置可还原
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostLikeUpdated"))) { _ in
                    // 监听帖子点赞更新通知，刷新今日互动统计
                    #if DEBUG
                    debugLog("❤️ 收到PostLikeUpdated通知，刷新今日互动统计")
                    #endif
                    DispatchQueue.main.async {
                        // 触发今日互动统计的重新计算
                        // 由于todayInteractionStats是计算属性，当其依赖的数据源更新时会自动重新计算
                        self.notificationService.objectWillChange.send()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CommentLikeUpdated"))) { _ in
                    // 监听评论点赞更新通知，刷新今日互动统计
                    #if DEBUG
                    debugLog("❤️ NotificationViewOriginal: 收到CommentLikeUpdated通知，刷新今日互动统计")
                    #endif
                    DispatchQueue.main.async {
                        // 触发今日互动统计的重新计算
                        // 由于todayInteractionStats是计算属性，当其依赖的数据源更新时会自动重新计算
                        self.notificationService.objectWillChange.send()
                    }
                }
                .ignoresSafeArea(.all, edges: [.bottom])
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        // 🔒 修复：在 iPad 上强制使用 stack 样式，避免侧边栏布局
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // 创建额外的测试通知来展示不同的格式 - 已删除预设数据
    private func createAdditionalTestNotifications() {
        // 已删除预设的测试通知数据
    }
    
    // 今日互动统计卡片视图 - 重新设计
    private var todayStatsCardView: some View {
        let stats = todayInteractionStats
        
        return VStack(alignment: .leading, spacing: 0) {
            // 卡片标题
            HStack {
                Text("今日互动")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 右上角的标记已删除
            }
            .padding(.bottom, 12)
            
            // 主要数据行
            HStack(spacing: 16) {
                // AI帖子数
                StatItemView(
                    value: stats.aiPosts,
                    label: "AI帖子",
                    color: .purple.opacity(0.7),
                    icon: "sparkles"
                )
                
                // 回复数
                StatItemView(
                    value: stats.replies,
                    label: "回复",
                    color: .blue.opacity(0.7),
                    icon: "bubble.left.fill"
                )
                
                // 邀请数
                StatItemView(
                    value: stats.invitedCharacters,
                    label: "邀请",
                    color: .orange.opacity(0.7),
                    icon: "person.badge.plus"
                )
                
                // 点赞数
                StatItemView(
                    value: stats.likeInteractions,
                    label: "点赞",
                    color: .pink.opacity(0.7),
                    icon: "heart.fill"
                )
            }
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.vertical, 12)
            
            // 角色互动信息
            VStack(spacing: 10) {
                // 活跃角色 Top 3（头像阵列 + 次数）
                if !stats.activeCharacters.isEmpty {
                    HStack(alignment: .center) {
                        Text("活跃角色")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 10) {
                            ForEach(Array(stats.activeCharacters.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 4) {
                                    MiniAvatar(imageName: item.image, name: item.name, size: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(activeCharacterColor(for: index).opacity(0.15), lineWidth: 1)
                                        )
                                    if item.count > 1 {
                                        Text("\(item.count)")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 单聊角色（头像阵列）
                if !stats.privateChatCharacters.isEmpty {
                    HStack(alignment: .center) {
                        Text("深度对话")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(Array(stats.privateChatCharacters.prefix(5).enumerated()), id: \.offset) { _, user in
                                MiniAvatar(imageName: user.image, name: user.name, size: 20)
                            }
                            if stats.privateChatCharacters.count > 5 {
                                Text("+\(stats.privateChatCharacters.count - 5)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 新朋友（头像阵列）
                if !stats.firstTimeCharacters.isEmpty {
                    HStack(alignment: .center) {
                        Text("新相遇")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(Array(stats.firstTimeCharacters.prefix(5).enumerated()), id: \.offset) { _, user in
                                MiniAvatar(imageName: user.image, name: user.name, size: 20)
                            }
                            if stats.firstTimeCharacters.count > 5 {
                                Text("+\(stats.firstTimeCharacters.count - 5)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.gray.opacity(0.06), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 0.5)
    }
    
    // 活跃角色颜色
    private func activeCharacterColor(for index: Int) -> Color {
        let colors: [Color] = [.blue.opacity(0.6), .green.opacity(0.6), .orange.opacity(0.6)]
        return colors[min(index, colors.count - 1)]
    }
    
    // 轻量头像视图（本地图片或首字母占位）
    private struct MiniAvatar: View {
        let imageName: String?
        let name: String
        var size: CGFloat = 20
        
        var body: some View {
            Group {
                if let imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.08))
                        Text(String(name.prefix(1)))
                            .font(.system(size: size * 0.55, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(width: size, height: size)
                }
            }
        }
    }
    
    // 根据选中的选项卡确定是否显示特定类型的通知
    private func shouldShowNotification(type: NotificationModel.NotificationType, selectedTab: NotificationTab) -> Bool {
        switch selectedTab {
        case .all:
            // 全部标签只显示非系统通知
            return type != .system
        case .interactions:
            return type == .comment || type == .like || type == .follow
        case .system:
            return type == .system
        }
    }
    
    // 添加缺少的today变量
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
}

/**
 * 统计项目视图组件
 * 用于显示单个统计数据项
 */
struct StatItemView: View {
    let value: Int
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            // 图标和数值
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            // 标签
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/**
 * 标签切换视图 - 精致化设计
 */
struct TabSwitcherView: View {
    @Binding var selectedTab: NotificationView.NotificationTab
    @Namespace private var tabAnimation
    
    // 为每个选项卡定义独特的颜色
    private func tabColor(for tab: NotificationView.NotificationTab) -> Color {
        switch tab {
        case .all:
            return Color(red: 255/255, green: 204/255, blue: 0/255) // 金黄色 - 铃铛通知色
        case .interactions:
            return Color(red: 160/255, green: 130/255, blue: 250/255) // 紫色（参考梦幻联动）
        case .system:
            return Color(red: 70/255, green: 145/255, blue: 255/255) // 蓝色
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(NotificationView.NotificationTab.allCases, id: \.self) { tab in
                    Button(action: {
                        // 触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                        impactFeedback.impactOccurred()
                        
                        // 优化动画 - 使用更流畅的参数
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1)) {
                            selectedTab = tab
                        }
                    }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? tabColor(for: tab) : Color.secondary.opacity(0.7))
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? Color.primary : Color.secondary.opacity(0.7))
                            }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                            ZStack {
                            if selectedTab == tab {
                                    // 添加彩色背景渐变
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    tabColor(for: tab).opacity(0.08),
                                                    tabColor(for: tab).opacity(0.03)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: tabColor(for: tab).opacity(0.1), radius: 3, x: 0, y: 1)
                                        .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 0.5)
                                        .matchedGeometryEffect(id: "selectedTab", in: tabAnimation)
                            } else {
                                    // 未选中状态的微妙背景
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.clear)
                                }
                            }
                        )
                        .overlay(
                            // 只在选中时显示描边
                            Group {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                }
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(selectedTab == tab ? 1.0 : 0.98) // 微妙的缩放效果
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 0.5)
            )
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    NotificationView()
} 