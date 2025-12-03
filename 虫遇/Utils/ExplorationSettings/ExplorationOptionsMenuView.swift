import SwiftUI
import Foundation

/**
 * 虫洞探索选项菜单视图
 * 专用于虫洞探索页面的选项菜单，提供调整生成帖子数量功能
 */
struct ExplorationOptionsMenuView: View {
    @Binding var isShowing: Bool
    var post: UserPostModel
    var onDislikeCharacter: () -> Void
    var onReport: () -> Void
    var onFollowCharacter: ((Bool) -> Void)? = nil
    var onDeletePost: (() -> Void)? = nil
    var feedbackGenerator: UIImpactFeedbackGenerator
    
    @State private var isFollowed: Bool = false
    @State private var isBlocked: Bool = false
    @State private var currentCount: Int = 6 // 当前生成数量
    
    var body: some View {
        GeometryReader { geo in
            if isShowing {
                ZStack {
                    // 透明覆盖层
                    Color.black.opacity(0.01)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isShowing = false
                            }
                        }
                        .edgesIgnoringSafeArea(.all)
                    
                    // 实际菜单，固定位置在全局坐标系
                    VStack(spacing: 0) {
                        // 关注角色按钮 - 根据关注状态显示不同UI
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isShowing = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                // 使用统一的FollowManager切换关注状态
                                let newFollowStatus = FollowManager.shared.toggleFollow(for: post.username)
                                isFollowed = newFollowStatus
                                HapticFeedbackManager.shared.menuSelection()
                                
                                // 使用回调通知外部状态变化
                                onFollowCharacter?(isFollowed)
                                
                                // 显示操作反馈
                                ToastManager.shared.showToast(
                                    message: isFollowed ? "已关注「\(post.username)」" : "已取消关注"
                                )
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isFollowed ? "person.badge.minus" : "person.badge.plus")
                                    .font(.system(size: 12))
                                    .foregroundColor(isFollowed ? Color.red.opacity(0.7) : Color(hex: "9A8BB0"))
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
                            withAnimation(.easeOut(duration: 0.2)) {
                                isShowing = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                // 切换屏蔽状态
                                isBlocked.toggle()
                                HapticFeedbackManager.shared.menuSelection()
                                
                                // 调用屏蔽回调
                                onDislikeCharacter()
                                
                                // 显示操作反馈
                                ToastManager.shared.showToast(
                                    message: isBlocked ? "已屏蔽「\(post.username)」" : "已取消屏蔽"
                                )
                                
                                // 更新本地存储
                                updateBlockedCharacters(post.characterID ?? post.username, isBlocked: isBlocked)
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
                        
                        // 调整生成数量按钮（替代减少此类内容）
                        // 确保所有类型都显示数量控制组件
                        VStack(alignment: .trailing, spacing: 8) {
                            // 第一行：标题
                            HStack(spacing: 4) {
                                Image(systemName: "number")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.blue.opacity(0.7))
                                    .frame(width: 16, alignment: .center)
                                
                                Spacer()
                                
                                Text("调整生成数量")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .padding(.trailing, 4)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                            
                            // 第二行：加减按钮和数量显示
                            HStack(alignment: .center, spacing: 8) {
                                Spacer()
                                    .frame(width: 22)
                                
                                // 减号按钮
                                Button(action: {
                                    decreaseCount()
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(currentCount > 1 ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5))
                                }
                                .disabled(currentCount <= 1)
                                
                                // 数量显示
                                Text("\(currentCount)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .frame(width: 30, alignment: .center)
                                
                                // 加号按钮
                                Button(action: {
                                    increaseCount()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(currentCount < 12 ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5))
                                }
                                .disabled(currentCount >= 12)
                                
                                Text("篇")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .padding(.trailing, 4)
                            }
                            .padding(.horizontal, 12)
                            
                            // 第三行：提示文本
                            HStack {
                                Spacer()
                                    .frame(width: 22)
                                
                                Text("范围：1-12篇")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                    .padding(.trailing, 4)
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        }
                        .contentShape(Rectangle())
                        
                        Divider()
                            .frame(width: 110)
                            .padding(.vertical, 4)
                        
                        // 删除帖子按钮
                        if let onDeletePost = onDeletePost {
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isShowing = false
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
                    .frame(width: 150)
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
                    .position(
                        x: geo.frame(in: .global).maxX - 20,
                        y: geo.frame(in: .global).minY + 45
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing))
                        )
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
                }
                .ignoresSafeArea()
            }
        }
        .allowsHitTesting(isShowing)
        .onAppear {
            // 检查是否已关注该角色
            checkIfFollowed()
            // 检查是否已屏蔽该角色
            checkIfBlocked()
            // 加载当前生成数量设置
            loadCurrentCount()
        }
    }
    
    // 检查是否已关注该角色
    private func checkIfFollowed() {
        // 使用统一的FollowManager检查关注状态
        isFollowed = FollowManager.shared.isFollowing(post.username)
    }
    
    // 检查是否已屏蔽该角色
    private func checkIfBlocked() {
        // 获取当前用户屏蔽的角色列表
        let characterID = post.characterID ?? post.username
        let blockedCharacters = UserDefaults.standard.stringArray(forKey: "BlockedCharacters") ?? []
        
        // 更新屏蔽状态
        isBlocked = blockedCharacters.contains(characterID)
    }
    
    // 加载当前生成数量设置
    private func loadCurrentCount() {
        // 打印临时帖子信息，帮助调试
        #if DEBUG
        print("📊 加载帖子数量设置：帖子ID=\(post.id), 内容类型=\(post.contentType ?? "nil")")
        #endif
        
        guard let contentTypeString = post.contentType else {
            #if DEBUG
            print("⚠️ 错误：帖子contentType为nil，使用默认数量6")
            #endif
            currentCount = 6
            return
        }
        
        #if DEBUG
        print("🔄 尝试加载[\(contentTypeString)]的数量设置")
        #endif
        
        // 打印所有可用的ContentType枚举值
        #if DEBUG
        print("📚 可用的ContentType枚举值：")
        #endif
        for type in ContentGeneratorService.ContentType.allCases {
            #if DEBUG
            print("  - \(type.rawValue)")
            #endif
        }
        
        // 检查CreationTypeManager中的类型
        #if DEBUG
        print("📚 CreationTypeManager中的类型：")
        #endif
        for type in CreationTypeManager.shared.types {
            #if DEBUG
            print("  - \(type)")
            #endif
        }
        
        // 特殊处理"虫洞共鸣"类型
        if contentTypeString == "虫洞共鸣" || contentTypeString == "resonance" {
            #if DEBUG
            print("🔍 检测到虫洞共鸣类型，使用特殊处理：")
            #endif
            let resonanceType = ContentGeneratorService.ContentType.resonance
            currentCount = ExplorationCountManager.shared.getCount(for: resonanceType)
            #if DEBUG
            print("✅ 成功加载虫洞共鸣的数量设置：\(currentCount)")
            #endif
            return
        }
        
        // 特殊处理"穿越吐槽"类型
        if contentTypeString == "穿越吐槽" {
            #if DEBUG
            print("🔍 检测到穿越吐槽类型，使用特殊处理：")
            #endif
            let creativeIdeaType = ContentGeneratorService.ContentType.creativeIdea
            currentCount = ExplorationCountManager.shared.getCount(for: creativeIdeaType)
            #if DEBUG
            print("✅ 成功加载穿越吐槽的数量设置：\(currentCount)")
            #endif
            return
        }
        
        guard let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) else {
            #if DEBUG
            print("⚠️ 错误：无法将[\(contentTypeString)]转换为ContentType枚举，使用默认数量6")
            #endif
            currentCount = 6
            return
        }
        
        // 从ExplorationCountManager获取当前设置的生成数量
        currentCount = ExplorationCountManager.shared.getCount(for: contentType)
        #if DEBUG
        print("✅ 成功加载[\(contentTypeString)]的数量设置：\(currentCount)")
        #endif
    }
    
    // 增加生成数量
    private func increaseCount() {
        guard let contentTypeString = post.contentType else {
            #if DEBUG
            print("⚠️ 错误：增加数量失败，帖子contentType为nil")
            #endif
            return
        }
        
        #if DEBUG
        print("🔄 尝试增加[\(contentTypeString)]的数量")
        #endif
        
        // 特殊处理"虫洞共鸣"类型
        if contentTypeString == "虫洞共鸣" || contentTypeString == "resonance" {
            #if DEBUG
            print("🔍 检测到虫洞共鸣类型，使用特殊处理增加数量")
            #endif
            // 触发触觉反馈
            HapticFeedbackManager.shared.lightImpact()
            // 使用枚举值直接增加数量
            currentCount = ExplorationCountManager.shared.increaseCount(for: .resonance)
            #if DEBUG
            print("✅ 成功增加虫洞共鸣的数量为：\(currentCount)")
            #endif
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「虫洞共鸣」")
            return
        }
        
        // 特殊处理"穿越吐槽"类型
        if contentTypeString == "穿越吐槽" {
            #if DEBUG
            print("🔍 检测到穿越吐槽类型，使用特殊处理增加数量")
            #endif
            // 触发触觉反馈
            HapticFeedbackManager.shared.lightImpact()
            // 使用枚举值直接增加数量
            currentCount = ExplorationCountManager.shared.increaseCount(for: .creativeIdea)
            #if DEBUG
            print("✅ 成功增加穿越吐槽的数量为：\(currentCount)")
            #endif
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「穿越吐槽」")
            return
        }
        
        guard let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) else {
            #if DEBUG
            print("⚠️ 错误：增加数量失败，无法将[\(contentTypeString)]转换为ContentType枚举")
            #endif
            return
        }
        
        // 触发触觉反馈
        HapticFeedbackManager.shared.lightImpact()
        
        // 增加数量并更新UI
        currentCount = ExplorationCountManager.shared.increaseCount(for: contentType)
        #if DEBUG
        print("✅ 成功增加[\(contentTypeString)]的数量为：\(currentCount)")
        #endif
        
        // 显示提示
        ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「\(contentTypeString)」")
    }
    
    // 减少生成数量
    private func decreaseCount() {
        guard let contentTypeString = post.contentType else {
            #if DEBUG
            print("⚠️ 错误：减少数量失败，帖子contentType为nil")
            #endif
            return
        }
        
        #if DEBUG
        print("🔄 尝试减少[\(contentTypeString)]的数量")
        #endif
        
        // 特殊处理"虫洞共鸣"类型
        if contentTypeString == "虫洞共鸣" || contentTypeString == "resonance" {
            #if DEBUG
            print("🔍 检测到虫洞共鸣类型，使用特殊处理减少数量")
            #endif
            // 触发触觉反馈
            HapticFeedbackManager.shared.lightImpact()
            // 使用枚举值直接减少数量
            currentCount = ExplorationCountManager.shared.decreaseCount(for: .resonance)
            #if DEBUG
            print("✅ 成功减少虫洞共鸣的数量为：\(currentCount)")
            #endif
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「虫洞共鸣」")
            return
        }
        
        // 特殊处理"穿越吐槽"类型
        if contentTypeString == "穿越吐槽" {
            #if DEBUG
            print("🔍 检测到穿越吐槽类型，使用特殊处理减少数量")
            #endif
            // 触发触觉反馈
            HapticFeedbackManager.shared.lightImpact()
            // 使用枚举值直接减少数量
            currentCount = ExplorationCountManager.shared.decreaseCount(for: .creativeIdea)
            #if DEBUG
            print("✅ 成功减少穿越吐槽的数量为：\(currentCount)")
            #endif
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「穿越吐槽」")
            return
        }
        
        guard let contentType = ContentGeneratorService.ContentType(rawValue: contentTypeString) else {
            #if DEBUG
            print("⚠️ 错误：减少数量失败，无法将[\(contentTypeString)]转换为ContentType枚举")
            #endif
            return
        }
        
        // 触发触觉反馈
        HapticFeedbackManager.shared.lightImpact()
        
        // 减少数量并更新UI
        currentCount = ExplorationCountManager.shared.decreaseCount(for: contentType)
        #if DEBUG
        print("✅ 成功减少[\(contentTypeString)]的数量为：\(currentCount)")
        #endif
        
        // 显示提示
        ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「\(contentTypeString)」")
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
} 