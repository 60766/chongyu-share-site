import SwiftUI

// 自定义下拉菜单按钮
struct CustomPostOptionsButton: View {
    var post: UserPostModel? // 添加post参数
    var onDislikeCharacter: () -> Void
    var onFollowCharacter: ((Bool) -> Void)? = nil // 添加关注回调
    var onDeletePost: (() -> Void)? = nil // 添加删除帖子回调
    var isOneKeyGeneration: Bool = false // 添加是否为一键生成模式的标志
    
    @State private var isPressed: Bool = false
    @State private var showMenu: Bool = false
    @State private var isFollowed: Bool = false // 添加关注状态
    @State private var isBlocked: Bool = false // 添加屏蔽状态
    @State private var contentTypePercentage: Double = 0 // 内容类型占比
    @State private var contentTypeCount: Int = 0 // 内容类型数量
    @State private var totalContentCount: Int = 0 // 总内容数量
    @State private var estimatedAfterCount: Int = 0 // 减少后预计数量
    @State private var currentCount: Int = 6 // 添加当前数量变量
    
    // 修复isOneKeyGeneration判断逻辑
    // 添加一个计算属性来判断是否为虫洞探索（单独生成）模式
    private var isWormholeExploration: Bool {
        // 简化逻辑，移除调试日志
        return post?.username == "虫洞探索" || post?.characterID == "虫洞探索" || post?.characterID == "wormhole"
    }
    
    // 添加计算属性，确保虫洞探索模式总是显示数量控制
    private var shouldShowCountControl: Bool {
        // 简化逻辑，虫洞共鸣帖子直接显示数值组件
        return true
    }
    
    // 添加计算属性，确保一键生成模式总是显示权重控制
    private var shouldShowWeightControl: Bool {
        // 简化逻辑，只有一键生成的帖子才显示权重控制
        guard let post = post else {
            return false
        }
        
        // 判断逻辑：只有来源是onekey的帖子（一键生成的）才显示权重控制
        return post.source == "onekey"
    }
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
                feedbackGenerator.impactOccurred(intensity: 0.2)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.15)) {
                    isPressed = false
                }
                showMenu = true
            }
        }) {
            ZStack {
                if isPressed {
                    Circle()
                        .fill(Color(.systemGray5).opacity(0.5))
                        .frame(width: 28, height: 28)
                }
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 15.0, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .frame(width: 28, height: 28)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 检查关注状态
            if let username = post?.username {
                isFollowed = FollowManager.shared.isFollowing(username)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FollowStatusChanged"))) { notification in
            // 监听关注状态变化通知
            if let userInfo = notification.userInfo,
               let changedUsername = userInfo["username"] as? String,
               let newFollowStatus = userInfo["isFollowed"] as? Bool,
               let currentUsername = post?.username,
               changedUsername == currentUsername {
                // 只有当通知中的用户名与当前帖子的用户名匹配时才更新状态
                isFollowed = newFollowStatus
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FollowDataMigrationCompleted"))) { _ in
            // 监听数据迁移完成通知，刷新关注状态
            if let username = post?.username {
                isFollowed = FollowManager.shared.isFollowing(username)
            }
        }
        .popover(isPresented: $showMenu, arrowEdge: .top) {
            VStack(spacing: 0) {
                // 关注角色按钮 - 根据关注状态显示不同UI
                Button(action: {
                    showMenu = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 使用统一的FollowManager切换关注状态
                        if let username = post?.username {
                            let newFollowStatus = FollowManager.shared.toggleFollow(for: username)
                            isFollowed = newFollowStatus
                        HapticFeedbackManager.shared.menuSelection()
                        
                        // 使用回调通知外部状态变化
                        onFollowCharacter?(isFollowed)
                        
                        // 显示操作反馈
                        ToastManager.shared.showToast(
                                message: isFollowed ? "已关注「\(username)」" : "已取消关注"
                        )
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isFollowed ? "person.badge.minus" : "person.badge.plus")
                            .font(.system(size: 12))
                            .foregroundColor(isFollowed ? Color.red.opacity(0.7) : Color.primaryColor)
                            .frame(width: 16, alignment: .center)
                        
                        Spacer()
                        
                        Text(isFollowed ? "取消关注" : "关注角色")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.trailing, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .frame(width: 110)
                
                // 屏蔽此角色按钮
                Button(action: {
                    showMenu = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 切换屏蔽状态
                        isBlocked.toggle()
                        HapticFeedbackManager.shared.menuSelection()
                        
                        // 调用屏蔽回调
                        onDislikeCharacter()
                        
                        // 显示操作反馈
                        ToastManager.shared.showToast(
                            message: isBlocked ? "已屏蔽「\(post?.username ?? "该角色")」" : "已取消屏蔽"
                        )
                        
                        // 更新本地存储
                        updateBlockedCharacters(post?.characterID ?? post?.username ?? "", isBlocked: isBlocked)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isBlocked ? "eye.slash.fill" : "eye.slash")
                            .font(.system(size: 12))
                            .foregroundColor(isBlocked ? Color.red.opacity(0.7) : Color.orange.opacity(0.8))
                            .frame(width: 16, alignment: .center)
                        
                        Spacer()
                        
                        Text(isBlocked ? "已屏蔽角色" : "屏蔽此角色")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.trailing, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .frame(width: 110)
                
                // 根据模式显示不同的功能
                if shouldShowWeightControl {
                    // 一键生成模式：显示减少此类内容功能
                    Button(action: {
                        // 不再关闭菜单
                        // showMenu = false
                        
                        // 直接执行减少/恢复操作
                        if let contentTypeString = post?.contentType,
                           let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) {
                            // 检查当前权重，如果为0则恢复为100%
                            let currentWeight = ContentTypeWeightManager.shared.getWeight(for: contentType)
                            
                            if currentWeight <= 0.01 {
                                // 权重接近0时，恢复为100%
                                ContentTypeWeightManager.shared.resetContentType(contentType)
                                
                                // 显示操作反馈
                                ToastManager.shared.showToast(
                                    message: "已恢复「\(contentTypeString)」类型内容权重"
                                )
                            } else {
                                // 正常减少权重
                                ContentTypeWeightManager.shared.reduceContentType(contentType)
                                
                                // 显示操作反馈
                                ToastManager.shared.showToast(
                                    message: "已减少「\(contentTypeString)」类型内容"
                                )
                            }
                            
                            // 更新UI数据
                            updateContentTypePercentage()
                            updateContentStats()
                            
                            // 触觉反馈
                            HapticFeedbackManager.shared.notifySuccess()
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            // 第一行：图标 + 文字 - 与上面的选项保持一致
                            HStack(spacing: 4) {
                                Image(systemName: contentTypePercentage <= 1 ? "arrow.clockwise" : "circle.slash")
                                    .font(.system(size: 12))
                                    .foregroundColor(contentTypePercentage <= 1 ? Color.blue.opacity(0.7) : Color.green.opacity(0.7))
                                    .frame(width: 16, alignment: .center)
                                
                                Spacer()
                                
                                Text(contentTypePercentage <= 1 ? "恢复此类内容" : "减少此类内容")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .padding(.trailing, 4)
                            }
                            
                            // 第二行：进度条 - 居中显示
                            HStack(alignment: .center, spacing: 4) {
                                Spacer()
                                
                                // 进度条
                                ZStack(alignment: .leading) {
                                    // 背景条
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    // 前景条 - 最终正确版本
                                    Capsule()
                                        .fill(contentTypePercentage <= 1 ? Color.blue : Color.green)
                                        .frame(width: min(97, max(0, contentTypePercentage)) * 0.01 * 97, height: 4)
                                }
                                .frame(width: 97)
                                
                                // 百分比文本
                                Text("\(Int(contentTypePercentage))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .frame(width: 30, alignment: .trailing)
                            }
                            
                            // 第三行：当前占比和减少后预计 - 靠右对齐，缩小间距
                            HStack(spacing: 1) {
                                Spacer()
                                
                                Text("当前占比：")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                
                                Text("\(contentTypeCount)/\(totalContentCount)篇")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.black.opacity(0.8))
                                
                                Text("减少后")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    .padding(.leading, 2)
                                
                                Text("\(estimatedAfterCount)篇")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.red.opacity(0.9))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        // 更新内容类型百分比和统计数据
                        updateContentTypePercentage()
                        updateContentStats()
                    }
                } else if shouldShowCountControl {
                    // 单独生成模式：显示调整生成数量功能
                    VStack(alignment: .trailing, spacing: 8) {
                        // 第一行：图标 + 文字
                        HStack(spacing: 4) {
                            Image(systemName: "text.badge.plus")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 90/255, green: 140/255, blue: 230/255).opacity(0.75))
                                .frame(width: 16, alignment: .center)
                            
                            Spacer()
                            
                            Text("调整生成数量")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .padding(.trailing, 4)
                        }
                        
                        // 第二行：加减按钮和数量显示
                        HStack(alignment: .center, spacing: 8) {
                            Spacer()
                                .frame(width: 22)
                            
                            // 减号按钮 - 使用Button组件替代点击手势
                            Button(action: {
                                if currentCount > 1 {
                                    decreaseCount()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(currentCount > 1 ? 
                                              Color(red: 90/255, green: 140/255, blue: 230/255).opacity(0.12) : 
                                              Color.gray.opacity(0.08))
                                        .frame(width: 26, height: 26)
                                    
                                    Image(systemName: "minus")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(currentCount > 1 ? 
                                                        Color(red: 90/255, green: 140/255, blue: 230/255).opacity(0.9) : 
                                                        Color.gray.opacity(0.4))
                                }
                            }
                            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                            
                            // 数量显示
                            Text("\(currentCount)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .frame(width: 30, alignment: .center)
                            
                            // 加号按钮 - 使用Button组件替代点击手势
                            Button(action: {
                                if currentCount < 12 {
                                    increaseCount()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(currentCount < 12 ? 
                                              Color(red: 90/255, green: 140/255, blue: 230/255).opacity(0.12) : 
                                              Color.gray.opacity(0.08))
                                        .frame(width: 26, height: 26)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(currentCount < 12 ? 
                                                        Color(red: 90/255, green: 140/255, blue: 230/255).opacity(0.9) : 
                                                        Color.gray.opacity(0.4))
                                }
                            }
                            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
                            
                            Text("篇")
                                .font(.system(size: 14))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        // 第三行：提示文本
                        HStack {
                            Spacer()
                                .frame(width: 22)
                            
                            Text("范围：1-12篇")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                                .padding(.trailing, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                    .onAppear {
                        // 确保显示菜单时加载当前数量设置
                        loadCurrentCount()
                    }
                }
                
                // 删除帖子按钮
                if let onDeletePost = onDeletePost {
                    Divider()
                        .frame(width: 110)
                        .padding(.vertical, 4)
                    
                    Button(action: {
                        showMenu = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            HapticFeedbackManager.shared.menuSelection()
                            onDeletePost()
                            
                            // 显示操作反馈
                            ToastManager.shared.showToast(message: "已删除帖子")
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(width: 16, alignment: .center)
                            
                            Spacer()
                            
                            Text("删除帖子")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.trailing, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: 170)
            .background(
                ZStack {
                    // 磨砂玻璃背景
                    if #available(iOS 15.0, *) {
                        UltraVisualEffectView(blurStyle: .systemMaterial)
                    } else {
                        Color(.systemBackground)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .presentationCompactAdaptation(.none)
        }
        // 适配iOS 16及以上版本
        .if16Available {
            $0.presentationCompactAdaptation(.none)
               .presentationBackgroundInteraction(.enabled)
               .presentationCornerRadius(8)
               .shadowVisibility(.hidden)
        }
        .onAppear {
            // 检查是否已屏蔽该角色
            checkIfBlocked()
            // 加载当前生成数量设置
            loadCurrentCount()
        }
    }
    
    // 检查是否已关注该角色
    private func checkIfFollowed() {
        guard let post = post else { return }
        
        // 使用统一的FollowManager检查关注状态
        isFollowed = FollowManager.shared.isFollowing(post.username)
    }
    
    // 检查是否已屏蔽该角色
    private func checkIfBlocked() {
        guard let post = post else { return }
        
        // 获取当前用户屏蔽的角色列表
        let characterID = post.characterID ?? post.username
        let blockedCharacters = UserDefaults.standard.stringArray(forKey: "BlockedCharacters") ?? []
        
        // 更新屏蔽状态
        isBlocked = blockedCharacters.contains(characterID)
    }
    
    // 加载当前生成数量设置
    private func loadCurrentCount() {
        guard let post = post,
              let contentTypeString = post.contentType,
              let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) else {
            currentCount = 6
            return
        }
        currentCount = ExplorationCountManager.shared.getCount(for: contentType)
    }
    
    // 增加生成数量
    private func increaseCount() {
        #if DEBUG
        print("🔼🔼🔼 尝试增加生成数量，当前值: \(currentCount)")
        #endif
        
        guard let post = post else {
            #if DEBUG
            print("⚠️⚠️⚠️ 严重错误: post为nil")
            #endif
            return
        }
        
        if let contentTypeString = post.contentType,
           let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) {
            // 使用ExplorationCountManager增加数量
            let newCount = ExplorationCountManager.shared.increaseCount(for: contentType)
            currentCount = newCount
            #if DEBUG
            print("✅ 成功增加生成数量: \(currentCount)")
            #endif
            
            // 添加触觉反馈
            HapticFeedbackManager.shared.lightTap()
        } else {
            // 如果无法获取内容类型，使用默认的resonance类型
            let defaultContentType = ContentGeneratorService.ContentType.resonance
            let newCount = ExplorationCountManager.shared.increaseCount(for: defaultContentType)
            currentCount = newCount
            #if DEBUG
            print("⚠️ 无法获取内容类型，使用默认类型增加生成数量: \(currentCount)")
            #endif
            
            // 添加触觉反馈
            HapticFeedbackManager.shared.lightTap()
        }
    }
    
    // 减少生成数量
    private func decreaseCount() {
        #if DEBUG
        print("🔽🔽🔽 尝试减少生成数量，当前值: \(currentCount)")
        #endif
        
        guard let post = post else {
            #if DEBUG
            print("⚠️⚠️⚠️ 严重错误: post为nil")
            #endif
            return
        }
        
        if let contentTypeString = post.contentType,
           let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) {
            // 使用ExplorationCountManager减少数量
            let newCount = ExplorationCountManager.shared.decreaseCount(for: contentType)
            currentCount = newCount
            #if DEBUG
            print("✅ 成功减少生成数量: \(currentCount)")
            #endif
            
            // 添加触觉反馈
            HapticFeedbackManager.shared.lightTap()
        } else {
            // 如果无法获取内容类型，使用默认的resonance类型
            let defaultContentType = ContentGeneratorService.ContentType.resonance
            let newCount = ExplorationCountManager.shared.decreaseCount(for: defaultContentType)
            currentCount = newCount
            #if DEBUG
            print("⚠️ 无法获取内容类型，使用默认类型减少生成数量: \(currentCount)")
            #endif
            
            // 添加触觉反馈
            HapticFeedbackManager.shared.lightTap()
        }
    }
    
    // 更新屏蔽的角色列表
    private func updateBlockedCharacters(_ characterID: String, isBlocked: Bool) {
        // 获取当前屏蔽列表
        var blockedCharacters = UserDefaults.standard.stringArray(forKey: "BlockedCharacters") ?? []
        
        if isBlocked {
            // 添加到屏蔽列表（避免重复）
            if !blockedCharacters.contains(characterID) {
                blockedCharacters.append(characterID)
            }
        } else {
            // 从屏蔽列表中移除
            blockedCharacters.removeAll { $0 == characterID }
        }
        
        // 保存更新后的列表
        UserDefaults.standard.set(blockedCharacters, forKey: "BlockedCharacters")
    }
    
    // 更新内容类型百分比和统计数据
    private func updateContentTypePercentage() {
        guard let post = post,
              let contentTypeString = post.contentType,
              let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) else {
            contentTypePercentage = 100 // 默认显示100%
            return
        }
        
        // 使用ContentTypeWeightManager获取权重并转换为百分比
        let weight = ContentTypeWeightManager.shared.getWeight(for: contentType)
        contentTypePercentage = weight * 100
    }
    
    // 更新内容统计数据
    private func updateContentStats() {
        guard let post = post,
              let contentTypeString = post.contentType,
              let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) else {
            contentTypeCount = 0
            totalContentCount = 12 // 总内容数固定为12篇
            estimatedAfterCount = 0
            return
        }
        
        // 从ContentTypeWeightManager获取实际权重
        let weight = ContentTypeWeightManager.shared.getWeight(for: contentType)
        
        // 总内容数固定为12篇（一轮推荐的总数）
        totalContentCount = 12
        
        // 计算当前类型的内容数量
        // 使用基于权重的分级计算方法
        if weight >= 1.0 {
            // 默认权重（未减少过）
            contentTypeCount = 3 // 基础数量
        } else if weight >= 0.5 {
            // 减少一次后的权重 (降低50%)
            contentTypeCount = 2
        } else if weight >= 0.25 {
            // 减少两次后的权重 (降低75%)
            contentTypeCount = 1
        } else if weight > 0 {
            // 极低权重但不为0
            contentTypeCount = 1 // 最低保留1篇
        } else {
            // 权重接近0，不显示任何内容
            contentTypeCount = 0 // 完全不显示
        }
        
        // 计算减少后预计数量（基于当前权重再次减少）
        // 当前权重乘以0.5就是下一次减少后的权重
        let nextWeight = max(0.0, weight * 0.5) // 最低可以为0
        
        if nextWeight >= 0.5 {
            estimatedAfterCount = 2
        } else if nextWeight >= 0.25 {
            estimatedAfterCount = 1
        } else if nextWeight > 0 {
            estimatedAfterCount = 1 // 最低保留1篇
        } else {
            estimatedAfterCount = 0 // 完全不显示
        }
    }
} 