import SwiftUI

// 使用内部自定义Avatar组件
// import Avatar 不需要导入，因为是同一个模块内的组件

/**
 * 获取角色对应的颜色 - 工具函数
 */
func getCharacterColor(for id: String) -> Color {
    switch id {
    case "einstein": return .blue
    case "shakespeare": return .purple
    case "davinci": return .green
    case "goku", "sunwukong", "naruto": return .orange
    case "holmes": return .indigo
    case "kongzi": return .green
    case "libai": return .orange
    case "newton": return .teal
    default: return .teal
    }
}

/**
 * 获取角色类别 - 工具函数
 */
func getCharacterCategory(for id: String) -> String {
    switch id {
    case "einstein": return "科学家"
    case "shakespeare": return "文学家"
    case "davinci": return "艺术家"
    case "kongzi": return "哲学家"
    case "libai": return "诗人"
    case "newton": return "科学家"
    case "goku", "sunwukong", "naruto": return "动漫角色"
    case "holmes": return "小说人物"
    default: return "历史人物"
    }
}

/**
 * 根据角色ID获取标签颜色
 */
func getTagColor(for characterID: String?) -> Color {
    guard let id = characterID?.lowercased() else { return .teal }
    
    switch id {
    case "einstein": return .blue
    case "shakespeare": return .purple
    case "davinci": return .green
    case "goku", "sunwukong", "naruto": return .orange
    case "holmes": return .indigo
    case "kongzi": return .green
    case "libai": return .orange
    case "newton": return .teal
    default: return .teal
    }
}

/**
 * 获取角色类别标签文本
 */
func getCharacterTag(for characterID: String?) -> String {
    guard let id = characterID?.lowercased() else { return "历史人物" }
    
    switch id {
    case "einstein", "newton": return "科学家"
    case "shakespeare", "libai": return "文学家"
    case "davinci": return "艺术家"
    case "kongzi": return "哲学家"
    case "goku", "sunwukong", "naruto": return "动漫角色"
    case "holmes": return "小说人物"
    default: return "历史人物"
    }
}

/**
 * 评论列表视图 - 小红书风格
 * 只有一层嵌套，默认折叠子评论，通过@用户名标记回复关系
 */
struct CommentsListView: View {
    // 评论数据 - 只接收顶级评论
    let comments: [DetailedCommentModel]
    
    // 回调函数
    let onReply: ((DetailedCommentModel) -> Void)?
    let onLike: ((DetailedCommentModel) -> Void)?
    
    // 状态变量
    @State private var likedComments = Set<UUID>()
    
    // 使用AppStorage持久化存储展开状态，确保在视图刷新时保持状态
    @State private var expandedComments = Set<UUID>() // 跟踪已展开的评论
    
    // 添加一个状态变量用于控制视图刷新
    @State private var refreshID = UUID()
    
    // 添加一个状态变量，用于跟踪是否正在刷新
    @State private var isRefreshing = false
    
    // 添加一个状态变量，用于保存当前锚点
    @State private var currentAnchorId: UUID? = nil
    
    // 添加一个状态集合，用于跟踪哪些评论需要显示点点动画
    @State private var commentsWithWaveAnimation = Set<UUID>()
    
    // 添加一个状态变量，用于显示邀请虚拟角色后的顶部加载动画
    @State private var showTopLoadingAnimation = false
    
    // 使用一个稳定的标识符，基于评论列表的第一个评论ID或者固定字符串
    var storageKey: String {
        if let firstComment = comments.first {
            return "expandedComments_\(firstComment.id.uuidString)"
        } else {
            return "expandedComments_global"
        }
    }
    
    // 处理回复操作的辅助方法
    private func handleReply(commentId: UUID) {
        // 找到对应的评论并调用回调
        if let comment = findComment(id: commentId, in: comments) {
            // 在回复评论前，确保当前评论已经展开
            expandedComments.insert(comment.id)
            
            // 如果是回复子评论，确保其父评论也展开
            if let parentId = comment.parentCommentId {
                expandedComments.insert(parentId)
            }
            
            onReply?(comment)
        }
    }
    
    // 处理点赞操作的辅助方法
    private func handleLike(commentId: UUID) {
        // 找到对应的评论并调用回调
        if let comment = findComment(id: commentId, in: comments) {
            onLike?(comment)
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if comments.isEmpty {
                        // 无评论时使用统一的EmptyCommentsView组件
                        EmptyCommentsView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20) // 增加垂直间距
                    } else {
                        // 添加一个隐藏的锚点视图，用于保持滚动位置
                        Color.clear
                            .frame(height: 1)
                            .id("scroll_position_anchor")
                        
                        // 显示顶部加载动画（当邀请虚拟角色后） - 已被新的图标动画取代
                        /*
                        if showTopLoadingAnimation {
                            TopLoadingWaveView()
                                .padding(.bottom, 10) // 调整此值以控制垂直位置
                            .id("top_loading_animation")
                            .transition(.opacity)
                        }
                        */
                        
                        // 显示所有顶级评论
                        ForEach(comments) { comment in
                            CommentThreadView(
                                comment: comment,
                                expandedComments: $expandedComments,
                                replyAction: handleReply,
                                onLike: handleLike,
                                commentsWithWaveAnimation: $commentsWithWaveAnimation
                            )
                            .id(comment.id)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                            
                            if comment.id != comments.last?.id {
                                Divider()
                                    .padding(.horizontal, 20) // 增加水平间距
                                    .padding(.vertical, 4) // 增加分隔线周围的间距
                            }
                        }
                        .id("comments_list_\(storageKey)") // 为整个评论列表添加固定ID
                    }
                }
                .onChange(of: comments) { oldComments, newComments in
                    print("🔄 评论数据变化: 旧评论数=\(oldComments.count), 新评论数=\(newComments.count)")
                    
                    // 1. 记录当前锚点
                    if let firstVisible = oldComments.first {
                        currentAnchorId = firstVisible.id
                    }
                    
                    // 2. 处理评论变化，更新动画状态
                    handleCommentsChange(oldComments: oldComments, newComments: newComments)
                    
                    // 如果增加的评论中有虚拟角色的评论，则隐藏顶部加载动画
                    let addedComments = newComments.filter { newComment in !oldComments.contains { $0.id == newComment.id } }
                    if addedComments.contains(where: { $0.isVirtualCharacter }) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showTopLoadingAnimation = false
                        }
                    }
                    
                    // 3. 数据变化后，滚动回锚点
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let anchorId = currentAnchorId {
                            withAnimation(.none) {
                                proxy.scrollTo(anchorId, anchor: .top)
                            }
                        }
                    }
                }
                .onDisappear {
                    // 移除ScrollToComment通知监听
                    NotificationCenter.default.removeObserver(
                        self,
                        name: NSNotification.Name("ScrollToComment"),
                        object: nil
                    )
                    
                    // 移除PreventScrollAfterSubmit通知监听
                    NotificationCenter.default.removeObserver(
                        self,
                        name: NSNotification.Name("PreventScrollAfterSubmit"),
                        object: nil
                    )
                }
                // 添加监听PreventScrollAfterSubmit通知，用于保存和恢复滚动位置
                let _ = NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("PreventScrollAfterSubmit"),
                    object: nil,
                    queue: .main
                ) { _ in
                    // 只更新refreshID，不做任何滚动操作
                    DispatchQueue.main.async {
                        self.refreshID = UUID()
                    }
                }
            }
        }
        .background(Color(.systemBackground).opacity(0.98)) // 添加轻微的背景色
        .onAppear {
            // 添加通知监听
            setupNotifications()
            
            // 从UserDefaults加载展开状态
            loadExpandedCommentsState()
            
            // 初始化点点动画状态
            initializeWaveAnimationState()
            
            // 确保动画状态正确
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 重新初始化动画状态
                self.initializeWaveAnimationState()
                
                // 强制刷新视图
                self.refreshID = UUID()
            }
            
            // 初始刷新一次，确保视图正确显示
            refreshWithoutScrolling()
        }
        .onDisappear {
            // 保存展开状态到UserDefaults
            saveExpandedCommentsState()
            
            // 移除通知监听
            NotificationCenter.default.removeObserver(self)
        }
        // 修复iOS 17中已弃用的onChange方法
        .onChange(of: expandedComments) { _, _ in
            // 当展开状态变化时保存
            saveExpandedCommentsState()
        }
        // 恢复视图ID，但不使用refreshID，避免不必要的视图重建
        .id("comments_list_view_\(storageKey)")
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CommentLikeUpdated"))) { notification in
            // 监听评论点赞更新通知，刷新评论列表显示
            DispatchQueue.main.async {
                // 强制刷新视图，确保点赞数更新
                self.refreshID = UUID()
                print("✅ CommentsListView: 收到CommentLikeUpdated通知，评论点赞数已刷新")
            }
        }
    }
    
    // 保存展开状态到UserDefaults
    private func saveExpandedCommentsState() {
        do {
            let uuidStrings = expandedComments.map { $0.uuidString }
            let data = try JSONEncoder().encode(uuidStrings)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ 保存展开状态失败: \(error)")
        }
    }
    
    // 从UserDefaults加载展开状态
    private func loadExpandedCommentsState() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let uuidStrings = try JSONDecoder().decode([String].self, from: data)
                expandedComments = Set(uuidStrings.compactMap { UUID(uuidString: $0) })
            } catch {
                print("❌ 加载展开状态失败: \(error)")
            }
        }
    }
    
    // 初始化点点动画状态 - 回归第一性原理：动画只显示在当前用户没有收到回复的评论上
    private func initializeWaveAnimationState() {
        // 获取当前用户名列表（可能的用户标识）
        let currentUserNames = ["当前用户", "科学爱好者"]
        let currentUserId = UserDefaults.standard.string(forKey: "current_user_id") ?? ""
        
        // 创建一个映射，记录所有已收到回复的评论ID
        var commentIdsWithReplies = Set<UUID>()
        
        // 创建一个集合，记录所有当前用户的评论ID
        var currentUserCommentIds = Set<UUID>()
        
        // 创建一个集合，记录所有虚拟角色的评论ID
        var virtualCharacterCommentIds = Set<UUID>()
        
        // 第一步：递归找出所有已收到回复的评论ID、当前用户的评论ID和虚拟角色的评论ID
        func processComments(comments: [DetailedCommentModel]) {
            for comment in comments {
                // 记录虚拟角色的评论
                if comment.isVirtualCharacter {
                    virtualCharacterCommentIds.insert(comment.id)
                }
                
                // 记录当前用户的评论（确保不是虚拟角色）
                if !comment.isVirtualCharacter && 
                   (comment.isCurrentUser || 
                    currentUserNames.contains(comment.username) || 
                    comment.userId == currentUserId) {
                    currentUserCommentIds.insert(comment.id)
                }
                
                // 如果评论有回复，记录评论ID
                if !comment.replies.isEmpty {
                    commentIdsWithReplies.insert(comment.id)
                    
                    // 递归处理回复
                    processComments(comments: comment.replies)
                }
                
                // 记录所有被回复的评论ID
                for reply in comment.replies {
                    if let parentId = reply.parentCommentId {
                        commentIdsWithReplies.insert(parentId)
                    }
                    
                    // 检查是否有人回复了这个回复
                    let hasReplies = comment.replies.contains { otherReply in
                        otherReply.parentCommentId == reply.id || 
                        (otherReply.replyToUsername == reply.username && 
                         otherReply.datePosted > reply.datePosted)
                    }
                    
                    if hasReplies {
                        commentIdsWithReplies.insert(reply.id)
                    }
                }
            }
        }
        
        // 处理所有评论
        processComments(comments: comments)
        
        // 第二步：确定哪些评论需要显示动画
        // 先清空之前的状态
        commentsWithWaveAnimation.removeAll()
        
        // 对于每个当前用户的评论，如果没有收到回复且不是虚拟角色，则添加到动画集合
        for commentId in currentUserCommentIds {
            // 确保不是虚拟角色的评论
            if !virtualCharacterCommentIds.contains(commentId) && !commentIdsWithReplies.contains(commentId) {
                commentsWithWaveAnimation.insert(commentId)
            }
        }
        
        // 第三步：确保最新发送的评论总是显示动画，直到收到回复
        // 找出最新发送的当前用户评论
        var latestUserComments: [DetailedCommentModel] = []
        
        func findLatestUserComments(in commentsList: [DetailedCommentModel]) {
            for comment in commentsList {
                // 只添加非虚拟角色的当前用户评论
                if !comment.isVirtualCharacter && 
                   (comment.isCurrentUser || 
                    currentUserNames.contains(comment.username) || 
                    comment.userId == currentUserId) {
                    latestUserComments.append(comment)
                }
                
                // 递归查找回复中的用户评论
                findLatestUserComments(in: comment.replies)
            }
        }
        
        findLatestUserComments(in: comments)
        
        // 按时间排序，最新的在前面
        latestUserComments.sort { $0.datePosted > $1.datePosted }
        
        // 确保最新的几条评论都显示动画，除非已经有回复
        for comment in latestUserComments.prefix(5) { // 最多显示最近5条评论的动画
            // 确保不是虚拟角色的评论
            if !virtualCharacterCommentIds.contains(comment.id) && !commentIdsWithReplies.contains(comment.id) {
                commentsWithWaveAnimation.insert(comment.id)
            }
        }
        
        // 最后一步：确保虚拟角色的评论永远不会显示动画
        commentsWithWaveAnimation = commentsWithWaveAnimation.filter { !virtualCharacterCommentIds.contains($0) }
    }
    
    // 检查新增的虚拟角色回复

    
    // 处理回复通知 - 增强版本
    private func handleReplyNotification(isVirtualCharacterReply: Bool, replyToUsername: String?, parentCommentId: UUID?) {
        // 无论是什么类型的回复，都应该移除被回复评论的动画
        if let commentId = parentCommentId {
            commentsWithWaveAnimation.remove(commentId)
        }
        
        // 如果有回复目标用户名，移除该用户的所有评论动画
        if let username = replyToUsername {
            // 递归查找并移除该用户名的所有评论动画
            func removeAnimationForUsername(in commentsList: [DetailedCommentModel]) {
                for comment in commentsList {
                    if comment.username == username {
                        // 确保不是虚拟角色的评论
                        if !comment.isVirtualCharacter {
                            commentsWithWaveAnimation.remove(comment.id)
                        }
                    }
                    
                    // 递归处理回复
                    removeAnimationForUsername(in: comment.replies)
                }
            }
            
            removeAnimationForUsername(in: comments)
        }
        
        // 重新初始化动画状态，确保一致性
        initializeWaveAnimationState()
    }
    
    // 处理评论数据变化
    private func handleCommentsChange(oldComments: [DetailedCommentModel], newComments: [DetailedCommentModel]) {
        // 检查是否有新的回复
        for newComment in newComments {
            // 找到对应的旧评论
            if let oldComment = oldComments.first(where: { $0.id == newComment.id }) {
                // 如果回复数量增加了，说明有新回复
                if newComment.replies.count > oldComment.replies.count {
                    // 立即移除该评论的动画
                    commentsWithWaveAnimation.remove(newComment.id)
                    
                    // 找出新增的回复
                    let newReplies = newComment.replies.filter { newReply in
                        !oldComment.replies.contains { $0.id == newReply.id }
                    }
                    
                    // 处理新回复，特别是虚拟角色回复
                    for newReply in newReplies {
                        // 如果有回复目标评论ID，移除该评论的动画
                        if let parentId = newReply.parentCommentId {
                            commentsWithWaveAnimation.remove(parentId)
                        }
                        
                        // 如果有回复目标用户名，移除该用户的所有评论动画
                        if let replyToUsername = newReply.replyToUsername {
                            // 移除所有该用户名的评论动画
                            for comment in comments {
                                if comment.username == replyToUsername {
                                    commentsWithWaveAnimation.remove(comment.id)
                                }
                                
                                for reply in comment.replies where reply.username == replyToUsername {
                                    commentsWithWaveAnimation.remove(reply.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 重新初始化动画状态
        initializeWaveAnimationState()
    }
    
    // 更新点点动画状态 - 当有新回复时调用
    private func updateWaveAnimationState(forCommentWithReply commentId: UUID) {
        // 如果评论在动画集合中，将其移除
        if commentsWithWaveAnimation.contains(commentId) {
            commentsWithWaveAnimation.remove(commentId)
        } else {
            // 尝试查找评论
            if let comment = findComment(id: commentId, in: self.comments) {
                // 判断是否是当前用户评论
                let currentUserId = UserDefaults.standard.string(forKey: "current_user_id") ?? ""
                let isCurrentUser = comment.userId == currentUserId || comment.isCurrentUser
                
                // 如果是当前用户的评论，强制移除动画
                if isCurrentUser {
                    commentsWithWaveAnimation.remove(commentId)
                }
            }
        }
    }
    
    // 递归查找评论
    private func findComment(id: UUID, in comments: [DetailedCommentModel]) -> DetailedCommentModel? {
        for comment in comments {
            if comment.id == id {
                return comment
            }
            
            if let found = findComment(id: id, in: comment.replies) {
                return found
            }
        }
        return nil
    }
    
    // 强制刷新方法 - 修改为只更新refreshID，而不重置展开状态
    private func forceRefresh() {
        // 避免频繁刷新导致的性能问题
        guard !isRefreshing else { return }
        
        // 标记为正在刷新
        isRefreshing = true
        
        // 使用DispatchQueue.main.async避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            // 先保存展开状态
            self.saveExpandedCommentsState()
            
            // 更新刷新ID，触发视图更新
            withAnimation(.none) {
                self.refreshID = UUID()
            }
            
            // 设置短暂延迟后重置刷新状态，避免频繁刷新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRefreshing = false
            }
        }
    }
    
    // 添加一个特殊的刷新方法，避免导致滚动
    private func refreshWithoutScrolling() {
        // 避免频繁刷新导致的性能问题
        guard !isRefreshing else { return }
        
        // 标记为正在刷新
        isRefreshing = true
        
        // 使用DispatchQueue.main.async避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            // 先保存展开状态
            self.saveExpandedCommentsState()
            
            // 强制刷新动画状态
            self.initializeWaveAnimationState()
            
            // 更新refreshID，触发视图内部更新
            self.refreshID = UUID()
            
            // 设置短暂延迟后重置刷新状态，避免频繁刷新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRefreshing = false
            }
        }
    }
    
    // 添加一个方法来处理新评论的显示，但不滚动页面
    private func showNewComment(commentId: UUID, parentCommentId: UUID?) {
        // 如果有父评论ID，确保父评论已展开
        if let parentId = parentCommentId {
            expandedComments.insert(parentId)
        }
        
        // 保存展开状态
        saveExpandedCommentsState()
        
        // 查找评论对象
        func findComment(id: UUID, in comments: [DetailedCommentModel]) -> DetailedCommentModel? {
            for comment in comments {
                if comment.id == id {
                    return comment
                }
                if let found = findComment(id: id, in: comment.replies) {
                    return found
                }
            }
            return nil
        }
        
        // 如果能找到评论，且不是虚拟角色的评论，则添加动画
        if let comment = findComment(id: commentId, in: comments), !comment.isVirtualCharacter {
            commentsWithWaveAnimation.insert(commentId)
        }
        
        // 使用特殊的刷新方法，避免导致滚动
        refreshWithoutScrolling()
    }
    
    // 辅助函数：递归查找评论
    private func containsComment(with id: UUID, in comments: [DetailedCommentModel]) -> Bool {
        for comment in comments {
            if comment.id == id {
                return true
            }
            if containsComment(with: id, in: comment.replies) {
                return true
            }
        }
        return false
    }
    
    // 辅助函数：递归展开嵌套评论
    private func expandNestedComments(in comments: [DetailedCommentModel], targetId: UUID) {
        for comment in comments {
            if comment.id == targetId {
                expandedComments.insert(comment.id)
                return
            }
            
            if containsComment(with: targetId, in: comment.replies) {
                expandedComments.insert(comment.id)
                expandNestedComments(in: comment.replies, targetId: targetId)
                return
            }
        }
    }
    
    // 滚动到指定评论
    private func scrollToComment(_ commentId: UUID) {
        // 避免频繁刷新导致的性能问题
        guard !isRefreshing else { return }
        
        // 标记为正在刷新
        isRefreshing = true
        
        // 使用DispatchQueue.main.async避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            // 先保存展开状态
            self.saveExpandedCommentsState()
            
            // 确保评论所在的线程是展开的
            for comment in self.comments {
                // 检查是否是顶级评论
                if comment.id == commentId {
                    // 如果是顶级评论，不需要展开
                    break
                }
                
                // 检查是否在回复中
                if self.containsComment(with: commentId, in: comment.replies) {
                    // 如果在回复中，展开父评论
                    self.expandedComments.insert(comment.id)
                    break
                }
            }
            
            // 更新刷新ID，触发视图更新
            withAnimation(.easeInOut(duration: 0.3)) {
                self.refreshID = UUID()
            }
            
            // 使用短延迟确保视图已更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 发送通知，让ScrollView滚动到指定评论
                NotificationCenter.default.post(
                    name: NSNotification.Name("ScrollToComment"),
                    object: nil,
                    userInfo: ["commentId": commentId.uuidString]
                )
                
                // 设置短暂延迟后重置刷新状态，避免频繁刷新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isRefreshing = false
                }
            }
        }
    }
    
    // 设置通知监听
    private func setupNotifications() {
        // 移除之前的监听器，避免重复添加
        NotificationCenter.default.removeObserver(self)
        
        // 监听ForceRefreshComments通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ForceRefreshComments"),
            object: nil,
            queue: .main
        ) { notification in
            // 检查是否需要保持展开状态
            let shouldKeepState = notification.userInfo?["keepExpandState"] as? Bool ?? true
            let preventScroll = notification.userInfo?["preventScroll"] as? Bool ?? true
            let immediateDisplay = notification.userInfo?["immediateDisplay"] as? Bool ?? false
            
            // 如果是立即显示，强制刷新评论状态
            if immediateDisplay {
                // 重新初始化动画状态
                self.initializeWaveAnimationState()
                
                // 强制刷新视图
                DispatchQueue.main.async {
                    // 更新刷新ID，触发视图更新
                    self.refreshID = UUID()
                    
                    // 发送额外通知确保评论列表刷新
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RefreshCommentsWithoutScrolling"),
                        object: nil
                    )
                }
                return
            }
            
            // 立即执行，不使用延迟
            if shouldKeepState {
                // 只刷新视图，不修改展开状态
                if preventScroll {
                    self.refreshWithoutScrolling()
                } else {
                    self.forceRefresh()
                }
            } else {
                // 清除展开状态并刷新
                self.expandedComments.removeAll()
                self.saveExpandedCommentsState()
                
                if preventScroll {
                    self.refreshWithoutScrolling()
                } else {
                    self.forceRefresh()
                }
            }
        }
        
        // 监听MaintainScrollPosition通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MaintainScrollPosition"),
            object: nil,
            queue: .main
        ) { _ in
            // 保存当前展开状态
            self.saveExpandedCommentsState()
        }
        
        // 监听PreventScrollAfterSubmit通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PreventScrollAfterSubmit"),
            object: nil,
            queue: .main
        ) { _ in
            // 完全不做任何操作，避免任何视图刷新导致的滚动
            // 新评论的显示完全依赖数据层的更新，不需要手动刷新视图
        }
        
        // 监听所有可能触发刷新的通知
        ["PostCommentsUpdated", "RefreshPostComments", "CommentAdded", "RefreshCommentsList"].forEach { notificationName in
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name(notificationName),
                object: nil,
                queue: .main
            ) { notification in
                // 检查是否需要保持展开状态
                let shouldKeepState = notification.userInfo?["keepExpandState"] as? Bool ?? true
                let preserveExpandState = notification.userInfo?["preserveExpandState"] as? Bool ?? true
                let preventScroll = notification.userInfo?["preventScroll"] as? Bool ?? true
                let immediateDisplay = notification.userInfo?["immediateDisplay"] as? Bool ?? false
                let noAutoExpand = notification.userInfo?["noAutoExpand"] as? Bool ?? false
                
                // 如果是 PostCommentsUpdated 通知，可能是新评论已经生成，隐藏加载动画
                if notificationName == "PostCommentsUpdated" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.showTopLoadingAnimation = false
                        }
                    }
                }
                
                // 检查是否需要滚动到特定评论
                var scrollToCommentId: UUID? = nil
                if let scrollToCommentIdString = notification.userInfo?["scrollToComment"] as? String,
                   let commentId = UUID(uuidString: scrollToCommentIdString) {
                    scrollToCommentId = commentId
                }
                
                // 检查是否有新评论ID，如果有则确保其父评论展开
                if let newCommentIdString = notification.userInfo?["newCommentId"] as? String,
                   let newCommentId = UUID(uuidString: newCommentIdString) {
                    
                    // 检查新评论是否是当前用户的评论，以及是否是虚拟角色
                    let isCurrentUserComment = notification.userInfo?["isCurrentUserComment"] as? Bool ?? false
                    let isVirtualCharacter = notification.userInfo?["isVirtualCharacter"] as? Bool ?? false
                    
                    // 如果是当前用户的评论，且不是虚拟角色，添加到动画集合
                    if isCurrentUserComment && !isVirtualCharacter {
                        self.commentsWithWaveAnimation.insert(newCommentId)
                    }
                    
                    // 如果有父评论ID，确保父评论展开
                    if let parentCommentIdString = notification.userInfo?["parentCommentId"] as? String,
                   let parentCommentId = UUID(uuidString: parentCommentIdString),
                   !noAutoExpand {
                    // 确保父评论展开
                    self.expandedComments.insert(parentCommentId)
                    self.saveExpandedCommentsState()
                        
                        // 父评论展开和动画处理
                        
                        // 检查新评论是否是虚拟角色的回复
                        let isVirtualCharacterReply = notification.userInfo?["isVirtualCharacter"] as? Bool ?? false
                        
                        // 处理回复通知
                        self.handleReplyNotification(
                            isVirtualCharacterReply: isVirtualCharacterReply,
                            replyToUsername: notification.userInfo?["replyToUsername"] as? String,
                            parentCommentId: parentCommentId
                        )
                    } else {
                        // 如果是顶级评论，重新初始化动画状态
                        self.initializeWaveAnimationState()
                    }
                    
                    // 如果没有指定滚动到的评论ID，则默认滚动到新评论
                    if scrollToCommentId == nil && !preventScroll {
                        scrollToCommentId = newCommentId
                    }
                }
                
                // 立即执行，不使用延迟
                if shouldKeepState && preserveExpandState {
                    // 重新初始化动画状态
                    self.initializeWaveAnimationState()
                    
                    // 只刷新视图，不修改展开状态
                    if preventScroll {
                        if immediateDisplay {
                            // 立即刷新，确保评论立即显示
                            self.refreshWithoutScrolling()
                        } else {
                            // 使用短延迟，避免多个通知同时触发导致的UI更新冲突
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                self.refreshWithoutScrolling()
                            }
                        }
                    } else if let commentId = scrollToCommentId {
                        // 需要滚动到特定评论
                        self.scrollToComment(commentId)
                    } else {
                        self.refreshWithoutScrolling() // 修改为refreshWithoutScrolling，避免滚动
                    }
                } else {
                    // 清除展开状态并刷新
                    if !preserveExpandState {
                        self.expandedComments.removeAll()
                        self.saveExpandedCommentsState()
                    }
                    
                    if preventScroll {
                        self.refreshWithoutScrolling()
                    } else if let commentId = scrollToCommentId {
                        // 需要滚动到特定评论
                        self.scrollToComment(commentId)
                    } else {
                        self.refreshWithoutScrolling() // 修改为refreshWithoutScrolling，避免滚动
                    }
                }
            }
        }
        
        // 监听ExpandComment通知，用于展开特定评论
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ExpandComment"),
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let commentIdString = userInfo["commentId"] as? String,
                  let commentId = UUID(uuidString: commentIdString) else {
                return
            }
            
            let preventScroll = userInfo["preventScroll"] as? Bool ?? true
            let forceExpand = userInfo["forceExpand"] as? Bool ?? false
            let _ = userInfo["preventCollapse"] as? Bool ?? false
            
            // 立即展开评论
            if forceExpand || !self.expandedComments.contains(commentId) {
                self.expandedComments.insert(commentId)
                self.saveExpandedCommentsState()
            }
            
            // 立即刷新
            if preventScroll {
                self.refreshWithoutScrolling()
            } else {
                self.refreshWithoutScrolling() // 修改为refreshWithoutScrolling，避免滚动
            }
        }
        
        // 监听RefreshCommentsWithoutScrolling通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshCommentsWithoutScrolling"),
            object: nil,
            queue: .main
        ) { _ in
            // 立即刷新，但不滚动
            self.refreshWithoutScrolling()
        }
        
        // 监听PrepareForNewComments通知 - 为即将到来的新评论做准备
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PrepareForNewComments"),
            object: nil,
            queue: .main
        ) { notification in
            // 重新初始化动画状态
            self.initializeWaveAnimationState()
            
            // 显示顶部加载动画
            withAnimation(.easeIn(duration: 0.2)) {
                self.showTopLoadingAnimation = true
            }
            
            // 强制刷新视图，确保准备好接收新评论
            DispatchQueue.main.async {
                self.refreshWithoutScrolling()
            }
        }
        
        // 监听HistoricalFiguresInvited通知 - 当邀请历史人物时显示加载动画
        NotificationCenter.default.addObserver(
            forName: Notification.Name("HistoricalFiguresInvited"),
            object: nil,
            queue: .main
        ) { notification in
            // 显示顶部加载动画
            withAnimation(.easeIn(duration: 0.2)) {
                self.showTopLoadingAnimation = true
            }
            
            // 强制刷新视图，确保动画显示
            DispatchQueue.main.async {
                self.refreshWithoutScrolling()
                
                // 确保其他动画状态被清理，避免多个动画同时显示
                self.commentsWithWaveAnimation.removeAll()
            }
        }
        
        // 监听CommentsGenerated通知 - 当评论生成完成时隐藏加载动画
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CommentsGenerated"),
            object: nil,
            queue: .main
        ) { notification in
                // 刷新视图
                self.refreshWithoutScrolling()

            // 重新初始化动画状态，确保新评论的动画状态正确
            self.initializeWaveAnimationState()
        }
    }
    
    // 根据角色ID获取类别
    private func getCategoryForCharacter(_ characterID: String) -> String {
        // 简单分类，可以根据需要扩展
        if ["kongzi", "laozi", "zhuangzi", "aristotle", "kant", "freud", "jung"].contains(characterID) {
            return "philosopher"
        } else if ["shakespeare", "hamlet", "macbeth", "don_quixote", "raskolnikov", "jean_valjean", "anna_karenina", "gatsby"].contains(characterID) {
            return "literature"
        } else if ["hermione", "harry_potter", "daenerys", "doctor", "joker", "gollum"].contains(characterID) {
            return "fiction"
        } else if ["yuefei", "caocao", "caesar", "genghis", "alexander", "cleopatra", "ayuwang"].contains(characterID) {
            return "historical"
        } else if ["einstein", "curie", "hawking", "darwin"].contains(characterID) {
            return "scientist"
        } else {
            return "other"
        }
    }
}

/**
 * 评论区头部视图
 */
struct CommentHeaderView: View {
    let commentCount: Int
    
    var body: some View {
        HStack {
            Text("评论")
                .font(.system(size: 16, weight: .medium))
            
            Text("(\(commentCount))")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Menu {
                Button(action: {
                    // 按时间排序
                }) {
                    Label("按时间", systemImage: "clock")
                }
                
                Button(action: {
                    // 按热度排序
                }) {
                    Label("按热度", systemImage: "flame")
                }
            } label: {
                HStack(spacing: 4) {
                    Text("最新")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 20) // 增加水平间距
        .padding(.vertical, 14) // 增加垂直间距
        .background(Color(.systemBackground))
        .overlay(
            Divider()
                .padding(.horizontal, 20), // 增加分隔线水平间距
            alignment: .bottom
        )
    }
}

/**
 * 评论线程视图 - 处理单个评论及其所有回复
 */
struct CommentThreadView: View {
    let comment: DetailedCommentModel
    @Binding var expandedComments: Set<UUID> // 接收绑定的展开状态
    let replyAction: (UUID) -> Void
    let onLike: (UUID) -> Void
    
    // 添加对动画状态的绑定
    @Binding var commentsWithWaveAnimation: Set<UUID>
    
    @State private var likedComments = Set<UUID>()
    
    // 添加一个状态变量用于控制视图刷新
    @State private var refreshID = UUID()
    
    // 添加一个状态变量，用于跟踪是否正在刷新
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // 增加垂直间距
            // 主评论
            CommentItemView(
                comment: comment,
                replyAction: replyAction,
                isLiked: likedComments.contains(comment.id),
                showExpandButton: !comment.replies.isEmpty,
                replyCount: comment.replies.count,
                isExpanded: expandedComments.contains(comment.id),
                onToggleExpand: {
                    toggleExpand(for: comment.id)
                },
                onLike: {
                    toggleLike(for: comment.id)
                }
            )
            
            // 虫洞波浪动画：移出CommentItemView，直接作为CommentThreadView的子视图
            // 只有当评论ID在动画状态集合中时才显示动画
            if self.commentsWithWaveAnimation.contains(comment.id) && !comment.isVirtualCharacter {
                WormholeWaveView(
                    id: comment.id,
                    isNestedReply: false
                )
                .padding(.bottom, 4)    // 添加少量底部间距
                .id("main_wave_\(comment.id)")
            }
            
            // 显示回复 - 只保留一层嵌套
            if expandedComments.contains(comment.id) && !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // 收集所有回复，包括嵌套回复，展平为一层
                    let allReplies = collectAllReplies(comment: comment)
                    
                    // 直接使用收集到的回复，不做额外排序
                    // 因为CommentManager.updateCommentLists已经确保了正确的排序顺序
                    ForEach(allReplies) { reply in
                        if reply.id != allReplies.first?.id {
                            Divider()
                                .padding(.leading, 48) // 增加左侧间距
                                .padding(.trailing, 16)
                                .padding(.vertical, 2) // 添加垂直间距
                        }
                        
                        // 回复内容 - 不再显示展开按钮，因为所有回复都在同一层
                        CommentItemView(
                            comment: reply,
                            replyAction: replyAction,
                            isLiked: likedComments.contains(reply.id),
                            showExpandButton: false, // 不再显示展开按钮
                            replyCount: 0,
                            isExpanded: false,
                            onToggleExpand: nil,
                            onLike: {
                                toggleLike(for: reply.id)
                            }
                        )
                        .transition(.opacity) // 添加过渡动画
                        .id("reply_\(reply.id)") // 为每个回复添加固定ID
                        
                        // 为嵌套回复添加虫洞波浪动画
                        // 只有当评论ID在动画状态集合中时才显示动画，且不是虚拟角色
                        if self.commentsWithWaveAnimation.contains(reply.id) && !reply.isVirtualCharacter {
                            WormholeWaveView(
                                id: reply.id,
                                isNestedReply: true
                            )
                            .padding(.bottom, 4)    // 添加少量底部间距
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.vertical, 6) // 增加垂直间距
                .padding(.leading, 0)
                .background(
                    RoundedRectangle(cornerRadius: 12) // 增加圆角
                        .fill(Color(.systemGray6).opacity(0.5)) // 轻微调整背景色透明度
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12) // 增加圆角
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1) // 调整边框颜色和宽度
                )
                .padding(.horizontal, 20) // 增加水平间距
                .padding(.bottom, 6) // 增加底部间距
                .transition(.opacity) // 添加过渡动画
                .id("replies_container_\(comment.id)") // 为回复容器添加固定ID
                .frame(maxWidth: .infinity) // 确保回复容器占满宽度
            }
        }
        .padding(.vertical, 4) // 增加垂直间距
        .id("comment_\(comment.id)") // 只用评论ID，避免刷新导致滚动
        .frame(maxWidth: .infinity) // 确保整个评论线程占满宽度
    }
    
    // 强制刷新方法
    private func forceRefresh() {
        // 避免频繁刷新导致的性能问题
        guard !isRefreshing else { return }
        
        // 标记为正在刷新
        isRefreshing = true
        
        // 使用DispatchQueue.main.async避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            self.refreshID = UUID()
            
            // 设置短暂延迟后重置刷新状态，避免频繁刷新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRefreshing = false
            }
        }
    }
    
    // 递归收集所有回复，并将它们展平为一层
    private func collectAllReplies(comment: DetailedCommentModel) -> [DetailedCommentModel] {
        var allReplies: [DetailedCommentModel] = []
        
        // 添加直接回复，按时间正序排序（旧的在上方）
        let sortedDirectReplies = comment.replies.sorted { $0.datePosted < $1.datePosted }
        
        // 对每个直接回复，递归获取其所有子回复
        for reply in sortedDirectReplies {
            allReplies.append(reply)
            allReplies.append(contentsOf: collectNestedReplies(reply))
        }
        
        return allReplies
    }
    
    // 递归收集嵌套回复
    private func collectNestedReplies(_ comment: DetailedCommentModel) -> [DetailedCommentModel] {
        var result: [DetailedCommentModel] = []
        
        // 添加直接回复，按时间正序排序（旧的在上方）
        let sortedReplies = comment.replies.sorted { $0.datePosted < $1.datePosted }
        
        // 递归收集更深层的嵌套回复
        for reply in sortedReplies {
            result.append(reply)
            result.append(contentsOf: collectNestedReplies(reply))
        }
        
        return result
    }
    
    // 辅助函数：获取回复所属的对话链ID
    private func getReplyChain(_ reply: DetailedCommentModel, in allReplies: [DetailedCommentModel]) -> String {
        // 如果有父评论ID，尝试找到根评论
        if let parentId = reply.parentCommentId {
            // 查找父评论
            if let parent = allReplies.first(where: { $0.id == parentId }) {
                // 递归查找根评论
                return getReplyChain(parent, in: allReplies)
            }
        }
        
        // 如果没有父评论或找不到父评论，使用自己的ID作为对话链ID
        return reply.id.uuidString
    }
    
    // 辅助函数：获取对话链的起始时间
    private func getChainStartTime(_ chainId: String, in allReplies: [DetailedCommentModel]) -> Date {
        // 找到属于该对话链的所有回复
        let chainReplies = allReplies.filter { getReplyChain($0, in: allReplies) == chainId }
        
        // 返回最早的回复时间
        return chainReplies.min(by: { $0.datePosted < $1.datePosted })?.datePosted ?? Date()
    }
    
    // 切换展开状态
    private func toggleExpand(for commentId: UUID) {
        // 不使用动画，直接更新状态
            if expandedComments.contains(commentId) {
                expandedComments.remove(commentId)
            } else {
                expandedComments.insert(commentId)
        }
    }
    
    // 切换点赞状态
    private func toggleLike(for commentId: UUID) {
        // 不使用动画，直接更新状态
            if likedComments.contains(commentId) {
                likedComments.remove(commentId)
            } else {
                likedComments.insert(commentId)
                // 添加触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        
        // 调用回调函数，更新模型数据
        onLike(commentId)
    }
    
    // 添加一个特殊的刷新方法，避免导致滚动
    private func refreshWithoutScrolling() {
        // 避免频繁刷新导致的性能问题
        guard !isRefreshing else { return }
        
        // 标记为正在刷新
        isRefreshing = true
        
        // 使用DispatchQueue.main.async避免在视图更新过程中修改状态
        DispatchQueue.main.async {
            // 使用一个特殊的ID，确保视图更新但不会导致滚动位置变化
            withAnimation(.none) {
                self.refreshID = UUID()
            }
            
            // 设置短暂延迟后重置刷新状态，避免频繁刷新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isRefreshing = false
            }
        }
    }
}

/**
 * 单个评论项视图
 */
struct CommentItemView: View {
    let comment: DetailedCommentModel
    let replyAction: (UUID) -> Void
    
    // 添加必要的参数
    var isLiked: Bool = false
    var showExpandButton: Bool = false
    var replyCount: Int = 0
    var isExpanded: Bool = false
    var onToggleExpand: (() -> Void)? = nil
    var onLike: (() -> Void)? = nil
    
    // 修改判断是否是当前用户的评论的方式
    private var isCurrentUserComment: Bool {
        // 使用UserDefaults存储的用户ID或系统生成的设备标识符来判断
        // 从UserDefaults获取当前用户ID
        let currentUserId = UserDefaults.standard.string(forKey: "current_user_id") ?? UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        // 从评论中获取用户ID
        let commentUserId = comment.userId ?? ""
        
        // 如果评论没有userId但有特殊标记，也认为是当前用户的评论
        let isMarkedAsCurrent = comment.isCurrentUser || comment.username == "当前用户"
        
        return commentUserId == currentUserId || isMarkedAsCurrent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) { // 增加水平间距
                // 用户头像 - 使用Avatar组件
                Avatar(url: comment.isVirtualCharacter ? 
                      (comment.characterID != nil ? "HistoricalFigures/\(comment.characterID!)" : comment.userAvatar) : 
                      comment.userAvatar, 
                      name: comment.username,
                      category: comment.characterID != nil ? getCharacterTag(for: comment.characterID!) : "",
                      size: 38)
                    .frame(width: 38, height: 38)
                    .onAppear {
                        if comment.isVirtualCharacter {
                            print("📱 评论头像 - 角色ID: \(comment.characterID ?? "nil"), 头像路径: \(comment.userAvatar)")
                        }
                    }
                
                VStack(alignment: .leading, spacing: 6) { // 增加垂直间距
                    // 用户信息行
                    HStack(alignment: .center, spacing: 8) { // 增加水平间距
                        // 用户名
                        Text(comment.username)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        // 角色标签
                        if comment.isVirtualCharacter, let characterID = comment.characterID {
                            CategoryBadge(characterID: characterID)
                        }
                        
                        Spacer()
                        
                        // 时间标签
                        Text(comment.getFormattedTimeAgo())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    
                    // 显示回复对象
                    if let replyToUsername = comment.replyToUsername {
                        HStack(spacing: 4) {
                            Text("回复")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                            
                            Text(replyToUsername)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 2)
                    }
                    
                    // 评论内容
                    Text(comment.content)
                        .font(.system(size: 15))
                        .foregroundColor(Color.primary.opacity(0.8))
                        .lineSpacing(5)
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading) // 确保文本正确布局
                        .id("comment_content_\(comment.id)") // 只用 comment.id，避免 refreshID 作用域错误
                    
                    // 交互按钮
                    HStack(spacing: 24) {
                        // 展开/收起回复按钮
                        if showExpandButton {
                            Button(action: {
                                onToggleExpand?()
                            }) {
                                HStack(spacing: 4) {
                                    Text(isExpanded ? "收起" : "查看\(replyCount)条回复")
                                        .font(.system(size: 13))
                                    
                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(isExpanded ? .gray.opacity(0.8) : .blue.opacity(0.9))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 4) // 从6减小到4
                        }
                        
                        Spacer()
                        
                        // 回复按钮 - 当不是当前用户的评论时才显示
                        if !isCurrentUserComment {
                        Button(action: {
                            replyAction(comment.id)
                            
                            // 发送通知，让CommentInputView获取焦点并弹出键盘
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FocusCommentInput"),
                                object: nil
                            )
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 13))
                                Text("回复")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.gray.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4) // 从6减小到4
                        }
                        
                        // 点赞按钮
                        Button(action: {
                            onLike?()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 13))
                                
                                // 动态计算显示的点赞数：如果已点赞但原始数据未更新，则+1显示
                                let displayLikes = isLiked && !comment.isLikedByCurrentUser ? 
                                    comment.likes + 1 : 
                                    ((!isLiked && comment.isLikedByCurrentUser) ? 
                                        max(0, comment.likes - 1) : 
                                        comment.likes)
                                
                                if displayLikes > 0 {
                                    Text("\(displayLikes)")
                                        .font(.system(size: 13))
                                }
                            }
                            .foregroundColor(isLiked ? .red : .gray.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4) // 从6减小到4
                    }
                    .padding(.top, 6) // 从10减小到6
                    
                    // 点点动画：只在当前用户评论且没有虚拟角色回复时显示，放在交互按钮下方
                    // 移除这里的动画，避免重复显示
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 确保内容区域正确布局
            }
            .padding(.horizontal, 20) // 增加水平间距
            .padding(.vertical, 12) // 增加垂直间距
            .frame(maxWidth: .infinity) // 确保整个HStack占满宽度
            
            // 删除重复的动画，避免多个点点同时显示
        }
        .background(Color(.systemBackground).opacity(0.5))
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity) // 确保整个评论视图占满宽度
    }
}

/**
 * 用户头像视图
 */
struct UserAvatarView: View {
    let avatar: String
    let username: String
    let isVirtualCharacter: Bool
    let characterID: String?
    
    var body: some View {
        // 使用Avatar组件，根据角色类型传递不同的URL
        Avatar(url: isVirtualCharacter ? (characterID ?? avatar) : avatar, size: 36)
    }
}

/**
 * 角色类别标签
 */
struct CategoryBadge: View {
    let characterID: String
    
    var body: some View {
        let category = getCharacterCategory(for: characterID)
        let color = getCharacterColor(for: characterID)
        
        Text(category)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

/**
 * 虫洞波浪动画组件
 */
struct WormholeWaveView: View {
    @State private var isAnimating = false
    
    // 添加一个ID属性，确保每个动画实例都是唯一的
    var id = UUID()
    
    // 添加是否是嵌套回复的参数
    var isNestedReply: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 5, height: 5)
                    .scaleEffect(isAnimating ? 1.4 : 1.0)
                    .opacity(isAnimating ? 1.0 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, isNestedReply ? 0 : -20) // 嵌套回复不需要负边距
        .frame(maxWidth: isNestedReply ? .infinity : UIScreen.main.bounds.width, alignment: .center) // 嵌套回复不需要强制宽度
        .onAppear { isAnimating = true }
        .id("wave_\(id)") // 确保每个动画实例都有唯一ID
    }
}

// 预览
struct CommentsListView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一些示例评论和回复以测试显示效果
        let mainComment = DetailedCommentModel(
            username: "爱因斯坦",
            userAvatar: "einstein", 
            content: "想象力比知识更重要。知识是有限的，而想象力概括着世界上的一切。",
            datePosted: Date().addingTimeInterval(-7200),
            isVirtualCharacter: true,
            characterID: "einstein",
            likes: 42
        )
        
        let reply1 = DetailedCommentModel(
            username: "牛顿",
            userAvatar: "newton",
            content: "我完全同意，爱因斯坦。正是想象力使科学不断向前发展。",
            datePosted: Date().addingTimeInterval(-3600),
            isVirtualCharacter: true,
            characterID: "newton",
            parentCommentId: mainComment.id,
            replyToUsername: "爱因斯坦",
            likes: 28
        )
        
        let reply2 = DetailedCommentModel(
            username: "用户123",
            userAvatar: "",
            content: "爱因斯坦先生，能否详细解释一下相对论的基本原理？",
            datePosted: Date().addingTimeInterval(-1800),
            isVirtualCharacter: false,
            characterID: nil,
            parentCommentId: mainComment.id,
            replyToUsername: "爱因斯坦",
            likes: 15
        )
        
        let reply3 = DetailedCommentModel(
            username: "爱因斯坦",
            userAvatar: "einstein",
            content: "相对论的核心是时空的相对性。你面前的时钟与以接近光速运动的时钟相比会走得更快，这种现象叫做'时间膨胀'。",
            datePosted: Date().addingTimeInterval(-1500),
            isVirtualCharacter: true,
            characterID: "einstein",
            parentCommentId: reply2.id,
            replyToUsername: "用户123",
            likes: 35
        )
        
        var commentWithReplies = mainComment
        commentWithReplies.replies = [reply1, reply2, reply3]
        
        return CommentsListView(
            comments: [commentWithReplies],
            onReply: { _ in },
            onLike: { _ in }
        )
        .padding()
        .previewLayout(.fixed(width: 375, height: 600))
    }
} 

// 添加CommentThreadView的预览
struct CommentThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let comment = DetailedCommentModel(
            username: "爱因斯坦",
            userAvatar: "einstein", 
            content: "想象力比知识更重要。知识是有限的，而想象力概括着世界上的一切。",
            datePosted: Date().addingTimeInterval(-7200),
            isVirtualCharacter: true,
            characterID: "einstein",
            likes: 42
        )
        
        return CommentThreadView(
            comment: comment,
            expandedComments: .constant(Set<UUID>()),  // 添加展开状态绑定
            replyAction: { _ in },
            onLike: { _ in },
            commentsWithWaveAnimation: .constant(Set<UUID>())  // 添加动画状态绑定
        )
        .padding()
        .previewLayout(.fixed(width: 375, height: 200))
    }
} 