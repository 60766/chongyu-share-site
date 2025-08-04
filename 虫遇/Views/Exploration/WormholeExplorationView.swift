import SwiftUI
import Foundation

// TimeSpaceEffectView 已经在同一个模块中，不需要导入自己的模块

/**
 * 虫洞探索主视图
 * 包含黑洞视图和创作类型按钮
 */
public struct WormholeExplorationView: View {
    @StateObject private var typeManager = CreationTypeManager.shared
    @State private var isShowingSpaceEffect = false
    @State private var isShowingButtons = false
    @State private var isTransitioning = false
    @State private var blackHoleCenterPosition: CGPoint? = nil // 保存黑洞中心位置
    
    // 添加搜索状态
    @State private var searchText = ""
    
    // 使用共享的PostViewModel实例
    @ObservedObject private var postViewModel = PostViewModel()
    // 兼容错误修复 - 为了兼容旧代码中的引用
    private var viewModel: PostViewModel { postViewModel }
    
    // 添加生成帖子成功的状态
    @State private var showGeneratedPostsMessage = false
    @State private var generatedPostsCount = 0
    @State private var isGenerating = false
    @State private var showSuccessMessage = false
    @State private var showErrorAlert = false
    
    // 添加兼容性变量，解决编译错误
    @State private var isGeneratingPost = false
    @State private var posts: [UserPostModel] = []
    @State private var generatedTypes = Set<Int>()
    @State private var showSuccessToast = false
    @State private var showErrorToast = false
    @State private var toastMessage = ""
    @State private var isCommentsEnabled = true
    
    // 添加生成任务属性，用于跟踪和取消生成任务
    @State private var generatePostsTask: Task<Void, Never>?
    
    // 添加选项菜单状态
    @State private var showOptionsMenu = false
    @State private var selectedPost: UserPostModel? = nil
    
    // 添加帖子数量控制状态
    @State private var currentPostCount: Int = 6
    
    public var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 星空背景
            StarfieldBackground()
            
            // 主内容
            VStack {
                // 搜索栏
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 6)
                        
                        TextField("搜索时空内容...", text: $searchText)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .accentColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
            .opacity(isShowingButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.3), value: isShowingButtons)
                
                Spacer()
            }
            
            // 黑洞视图 - 使用GeometryReader获取其中心位置
            GeometryReader { geometry in
                BlackHoleView()
                    .opacity(isShowingButtons && !isShowingSpaceEffect ? 1 : 0)
                    .scaleEffect(isShowingButtons ? 1 : 0.5)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1), value: isShowingButtons)
                    .onAppear {
                        // 计算黑洞中心位置
                        let centerX = geometry.frame(in: .global).midX
                        let centerY = geometry.frame(in: .global).midY + geometry.size.height * 0.15 - 290
                        blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
                        
                        print("黑洞中心位置设置为: x=\(centerX), y=\(centerY)")
                    }
            }
            .padding(.top, -20) // 向上移动黑洞位置，使其更靠近顶部
            
            // 底部按钮视图
            VStack {
                Spacer()
                
                // 创作类型按钮
                WormholeCreationTypeButtonsView(onOptionsButtonTapped: { contentType in
                    // 当点击选项按钮时，创建一个临时帖子模型用于菜单显示
                    let tempPost = createTempPost(for: contentType)
                    selectedPost = tempPost
                    showOptionsMenu = true
                }, onTypeChanged: {
                    // 当类型更改时，更新帖子数量
                    loadCurrentPostCount()
                })
                .padding(.bottom, 24) // 增加与下方元素的间距
                
                // 帖子数量控制视图
                PostCountControlView(
                    count: $currentPostCount,
                    onIncrease: {
                        increasePostCount()
                    },
                    onDecrease: {
                        decreasePostCount()
                    }
                )
                    .padding(.bottom, 32) // 增加与启动按钮的间距
                .opacity(isShowingButtons ? 1 : 0)
                .animation(.easeInOut(duration: 0.6).delay(0.4), value: isShowingButtons)
                
                // 启动按钮
                Button(action: {
                    // 触发触觉反馈
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    // 启动虫洞捕捉过程
                    withAnimation {
                        isTransitioning = true
                    }
                    
                    // 显示时空效果 - 由TimeSpaceEffectView自己控制结束时间
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isShowingSpaceEffect = true
                    }
                }) {
                    Text("启动虫洞捕捉")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 16) // 增加按钮高度
                        .padding(.horizontal, 40) // 增加按钮宽度
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.4, green: 0.2, blue: 0.6),
                                            Color(red: 0.5, green: 0.3, blue: 0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.5), radius: 10, x: 0, y: 4)
                }
                .disabled(isTransitioning)
                .opacity(isTransitioning ? 0.5 : 1.0)
                .padding(.bottom, 44) // 增加底部间距
                .opacity(isShowingButtons ? 1 : 0)
                .animation(.easeInOut(duration: 0.6).delay(0.5), value: isShowingButtons)
                
                // 开发测试按钮 - 仅用于测试特效
                #if DEBUG
                NavigationLink(destination: TimeSpaceEffectCenterTestView()) {
                    Text("测试特效")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 12) // 调整测试按钮间距
                .opacity(isShowingButtons ? 0.7 : 0)
                #endif
            }
            
            // 帖子生成成功提示
            if showGeneratedPostsMessage {
                VStack {
                    Text("虫洞捕捉成功")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("已为你生成\(generatedPostsCount)个「\(typeManager.types[typeManager.selectedIndex])」类型的帖子")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
            
            // 时空效果覆盖层 - 使用新的TimeSpaceEffectView
            if isShowingSpaceEffect {
                if let centerPosition = blackHoleCenterPosition {
                    // 如果黑洞中心位置可用，则使用它作为特效中心
                    TimeSpaceEffectView(
                        isActive: $isShowingSpaceEffect,
                        centerPosition: centerPosition
                    ) {
                        // 特效完成后的回调
                        print("🚀 TimeSpaceEffectView回调开始 - 特效完成，准备生成帖子")
                        withAnimation {
                            isTransitioning = false
                        }
                        
                        // 使用Task在异步上下文中调用我们的生成方法
                        Task {
                            await generateAndAddPosts()
                        }
                    }
                } else {
                    // 如果黑洞中心位置不可用，则使用屏幕中心作为特效中心
                    // 计算默认的屏幕中心位置
                    let screenSize = UIScreen.main.bounds.size
                    let defaultCenter = CGPoint(
                        x: screenSize.width / 2,
                        y: screenSize.height / 2 + screenSize.height * 0.25 - 290
                    )
                    
                    TimeSpaceEffectView(
                        isActive: $isShowingSpaceEffect,
                        centerPosition: defaultCenter
                    ) {
                        // 特效完成后的回调
                        print("🚀 TimeSpaceEffectView回调开始(使用默认中心) - 特效完成，准备生成帖子")
                                withAnimation {
                            isTransitioning = false
                        }
                        
                        // 使用Task在异步上下文中调用我们的生成方法
                        Task {
                            await generateAndAddPosts()
                        }
                    }
                }
            }
            
            // 选项菜单
            if let post = selectedPost {
                ExplorationOptionsMenuView(
                    isShowing: $showOptionsMenu,
                    post: post,
                    onDislikeCharacter: {
                        print("屏蔽角色: \(post.username)")
                    },
                    onReport: {
                        print("举报内容: \(post.id)")
                    },
                    onFollowCharacter: { isFollowed in
                        print("\(isFollowed ? "关注" : "取消关注")角色: \(post.username)")
                    },
                    feedbackGenerator: UIImpactFeedbackGenerator(style: .light)
                )
            }
        }
        .onAppear {
            // 延迟显示按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    isShowingButtons = true
                }
            }
            
            // 重置所有内容类型的权重，确保所有类型的数量控制组件都能正常显示
            // 这不会影响一键生成的权重分配，因为权重会在需要时重新计算
            print("🔄 重置所有内容类型权重，确保虫洞探索界面正常显示")
            ContentTypeWeightManager.shared.resetWeight()
            
            // 加载当前内容类型的帖子数量
            loadCurrentPostCount()
        }
        .onDisappear {
            // 在视图消失时取消所有正在进行的任务
            print("🧹 WormholeExplorationView已消失，正在清理资源...")
            generatePostsTask?.cancel()
            generatePostsTask = nil
        }
        .alert("生成失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("虫洞内容生成失败，请稍后再试")
        }
    }
    
    // 为选项菜单创建临时帖子模型
    private func createTempPost(for contentType: String) -> UserPostModel {
        // 在控制台打印内容类型，方便调试
        print("📋 为类型[\(contentType)]创建临时帖子用于选项菜单")
        
        // 特殊处理"虫洞共鸣"类型
        var finalContentType: String
        if contentType == "虫洞共鸣" {
            print("📋 检测到虫洞共鸣类型，使用特殊处理")
            finalContentType = ContentGeneratorService.ContentType.resonance.rawValue
            print("📋 虫洞共鸣转换为[\(finalContentType)]")
        } else {
            // 转换为ContentGeneratorService.ContentType对象
            let contentTypeEnum = ContentGeneratorService.ContentType(rawValue: contentType)
            
            // 确保为contentType和characterID使用正确的原始值
            finalContentType = contentTypeEnum?.rawValue ?? contentType
            print("📋 转换后的内容类型为[\(finalContentType)]")
        }
        
        return UserPostModel(
            id: UUID(),
            username: "虫洞探索",
            userAvatar: "wormhole",
            content: "临时帖子",
            images: [],
            datePosted: Date(),
            likes: 0,
            comments: [],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: finalContentType,
            characterID: finalContentType,
            source: "wormhole" // 添加来源标识，表示来自虫洞探索
        )
    }
    
    public init() {}
    
    // 加载当前内容类型的帖子数量
    private func loadCurrentPostCount() {
        let contentType = typeManager.types[typeManager.selectedIndex]
        print("🔍 尝试加载内容类型[\(contentType)]的帖子数量")
        
        // 特殊处理"虫洞共鸣"类型
        if contentType == "虫洞共鸣" || contentType == "resonance" {
            print("🔍 检测到虫洞共鸣类型，使用特殊处理")
            currentPostCount = ExplorationCountManager.shared.getCount(for: .resonance)
            print("✅ 成功加载虫洞共鸣的帖子数量: \(currentPostCount)")
            return
        }
        
        if let type = ContentGeneratorService.ContentType(rawValue: contentType) {
            // 获取该类型的权重，用于调试
            let weight = ContentTypeWeightManager.shared.getWeight(for: type)
            print("📊 内容类型[\(contentType)]的权重为: \(weight)")
            
            // 获取该类型的生成数量
            currentPostCount = ExplorationCountManager.shared.getCount(for: type)
            print("✅ 成功加载内容类型[\(contentType)]的帖子数量: \(currentPostCount)")
        } else {
            print("⚠️ 无法将[\(contentType)]转换为ContentType枚举")
        }
    }
    
    // 增加帖子数量
    private func increasePostCount() {
        let contentType = typeManager.types[typeManager.selectedIndex]
        
        // 特殊处理"虫洞共鸣"类型
        if contentType == "虫洞共鸣" || contentType == "resonance" {
            print("🔍 检测到虫洞共鸣类型，使用特殊处理增加数量")
            currentPostCount = ExplorationCountManager.shared.increaseCount(for: .resonance)
            
            // 触发触觉反馈
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentPostCount)篇「虫洞共鸣」")
            return
        }
        
        if let type = ContentGeneratorService.ContentType(rawValue: contentType) {
            currentPostCount = ExplorationCountManager.shared.increaseCount(for: type)
            
            // 触发触觉反馈
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentPostCount)篇「\(contentType)」")
        }
    }
    
    // 减少帖子数量
    private func decreasePostCount() {
        let contentType = typeManager.types[typeManager.selectedIndex]
        
        // 特殊处理"虫洞共鸣"类型
        if contentType == "虫洞共鸣" || contentType == "resonance" {
            print("🔍 检测到虫洞共鸣类型，使用特殊处理减少数量")
            currentPostCount = ExplorationCountManager.shared.decreaseCount(for: .resonance)
            
            // 触发触觉反馈
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentPostCount)篇「虫洞共鸣」")
            return
        }
        
        if let type = ContentGeneratorService.ContentType(rawValue: contentType) {
            currentPostCount = ExplorationCountManager.shared.decreaseCount(for: type)
            
            // 触发触觉反馈
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            
            // 显示提示
            ToastManager.shared.showToast(message: "已设置生成\(currentPostCount)篇「\(contentType)」")
        }
    }
    
    /**
     * 创建备用帖子，当API生成失败时使用
     */
    private func createBackupPosts() async -> [UserPostModel] {
        // 尝试使用异步方法生成帖子
        var posts: [UserPostModel] = []
        do {
            posts = try await postViewModel.generatePostsByCreationType(typeIndex: 0)
            print("✅ 成功生成备用帖子: \(posts.count)个")
        } catch {
            print("❌ 生成备用帖子失败: \(error.localizedDescription)")
        }
        
        if !posts.isEmpty {
            return posts
        }
        
        print("⚠️ 备用帖子生成失败，创建本地备用内容")
        
        // 如果异步生成失败，创建本地备用帖子
        let historicalFigures = [
            ("苏格拉底", "person.fill.questionmark"),
            ("孔子", "person.bust"),
            ("莎士比亚", "theatermasks"),
            ("爱因斯坦", "atom"),
            ("达芬奇", "paintpalette"),
            ("居里夫人", "testtube.2")
        ]
        
        let postCount = Int.random(in: 2...4) // 随机生成2-4个帖子
        var backupPosts = [UserPostModel]()
        
        for _ in 0..<postCount {
            let randomFigureIndex = Int.random(in: 0..<historicalFigures.count)
            let (authorName, authorAvatar) = historicalFigures[randomFigureIndex]
            
            // 创建一个简单的帖子
            let post = UserPostModel(
                id: UUID(),
                username: authorName,
                userAvatar: authorAvatar,
                content: "思考是灵魂与自己的对话。",
                images: [],
                datePosted: Date(),
                likes: Int.random(in: 5...50),
                comments: [],
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false,
                source: "wormhole" // 添加来源标识，表示来自虫洞探索
            )
            
            // 为帖子添加随机数量的评论
            let commentCount = Int.random(in: 1...3)
            for _ in 0..<commentCount {
                // 确保评论者不是帖子作者
                var commenterIndex: Int
                repeat {
                    commenterIndex = Int.random(in: 0..<historicalFigures.count)
                } while commenterIndex == randomFigureIndex
                
                let (commenterName, commenterAvatar) = historicalFigures[commenterIndex]
                
                let comment = DetailedCommentModel(
                    id: UUID(),
                    username: commenterName,
                    userAvatar: commenterAvatar,
                    content: "这是一个深刻的思考。",
                    datePosted: Date(),
                    likes: Int.random(in: 1...10)
                )
                
                post.comments.append(comment)
            }
            
            backupPosts.append(post)
        }
        
        // 如果没有生成任何帖子，创建一个紧急帖子
        if backupPosts.isEmpty {
            backupPosts.append(UserPostModel(
                id: UUID(),
                username: "系统",
                userAvatar: "exclamationmark.triangle",
                content: "虫洞探索遇到了一些小问题，但我们仍在继续前进。",
                images: [],
                datePosted: Date(),
                likes: 1,
                comments: [],
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false,
                source: "wormhole" // 添加来源标识，表示来自虫洞探索
            ))
        }
        
        return backupPosts
    }
    
    /**
     * 生成并添加帖子
     * 基于当前选择的内容类型，生成指定数量的帖子
     */
    private func generateAndAddPosts() async {
        // 已经有任务在执行时，不重复执行
        if isGeneratingPost {
            return
        }
        
        do {
            print("🚀 开始生成帖子，类型索引: \(typeManager.selectedIndex)")
            
            // 设置生成中状态
            isGeneratingPost = true
            
            // 获取当前选择的内容类型
            let selectedType = typeManager.types[typeManager.selectedIndex]
            
            // 特殊处理"虫洞共鸣"类型
            var contentType: ContentGeneratorService.ContentType
            if selectedType == "虫洞共鸣" || selectedType == "resonance" {
                print("🔍 检测到虫洞共鸣类型，使用特殊处理")
                contentType = .resonance
            } else {
                contentType = convertIndexToType(typeManager.selectedIndex)
            }
            
            // 日志输出当前选择的类型
            print("📝 生成内容类型: \(contentType)")
            
            // 获取虫洞探索配置的生成数量
            let count = ExplorationCountManager.shared.getCount(for: contentType)
            print("📊 配置的生成数量: \(count)篇")
            
            // 调用ViewModel的生成方法
            let generatedPosts = try await postViewModel.generatePosts(
                contentType: contentType,
                count: count,
                source: "wormhole" // 添加来源标识，表示来自虫洞探索
            )
            
            if generatedPosts.count > 0 {
                posts += generatedPosts
                
                // 更新已生成类型的状态
                var updatedGeneratedTypes = generatedTypes
                updatedGeneratedTypes.insert(typeManager.selectedIndex)
                generatedTypes = updatedGeneratedTypes
                
                print("✅ 成功生成\(generatedPosts.count)个类型[\(getTypeNameForIndex(typeManager.selectedIndex))]的帖子")
                
                // 显示成功提示
                DispatchQueue.main.async {
                    self.showSuccessToast = true
                    self.toastMessage = "成功生成\(generatedPosts.count)个\(self.getTypeNameForIndex(typeManager.selectedIndex))帖子"
                    
                    // 2秒后自动隐藏
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showSuccessToast = false
                    }
                }
            } else {
                print("⚠️ 没有生成任何帖子")
                
                // 显示错误提示
                DispatchQueue.main.async {
                    self.showErrorToast = true
                    self.toastMessage = "生成失败，请重试"
                    
                    // 2秒后自动隐藏
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showErrorToast = false
                    }
                }
                
                // 尝试创建备用帖子
                if let backupPosts = createBackupPosts(for: typeManager.selectedIndex) {
                    posts += backupPosts
                    
                    // 更新已生成类型的状态
                    var updatedGeneratedTypes = generatedTypes
                    updatedGeneratedTypes.insert(typeManager.selectedIndex)
                    generatedTypes = updatedGeneratedTypes
                    
                    print("🔄 使用了\(backupPosts.count)个备用帖子")
                }
            }
        } catch {
            print("❌ 生成帖子失败: \(error)")
            
            // 显示错误提示
            DispatchQueue.main.async {
                self.showErrorToast = true
                self.toastMessage = "生成失败: \(error.localizedDescription)"
                
                // 2秒后自动隐藏
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showErrorToast = false
                }
            }
            
            // 尝试创建备用帖子
            if let backupPosts = createBackupPosts(for: typeManager.selectedIndex) {
                posts += backupPosts
                
                // 更新已生成类型的状态
                var updatedGeneratedTypes = generatedTypes
                updatedGeneratedTypes.insert(typeManager.selectedIndex)
                generatedTypes = updatedGeneratedTypes
                
                print("🔄 使用了\(backupPosts.count)个备用帖子")
            }
        }
        
        isGeneratingPost = false
    }

    /**
     * 根据索引转换为内容类型
     */
    private func convertIndexToType(_ index: Int) -> ContentGeneratorService.ContentType {
        let typeString = typeManager.types[index]
        print("🔄 转换索引\(index)对应类型[\(typeString)]为ContentType枚举")
        
        guard let contentType = ContentGeneratorService.ContentType(rawValue: typeString) else {
            print("⚠️ 警告：无法将[\(typeString)]转换为ContentType枚举，使用默认值.resonance")
            return .resonance
        }
        
        print("✅ 成功转换为ContentType.\(contentType)")
        return contentType
    }
    
    /**
     * 根据索引获取内容类型名称
     */
    private func getTypeNameForIndex(_ index: Int) -> String {
        let contentType = typeManager.types[index]
        
        switch contentType {
        case "resonance": return "虫洞共鸣"
        case "ancient2modern": return "古潮新语"
        case "creativeIdea": return "穿越吐槽"
        case "mood": return "日常心情"
        case "question": return "思考提问"
        default: return contentType
        }
    }
    
    /**
     * 创建指定类型的备用帖子
     */
    private func createBackupPosts(for typeIndex: Int) -> [UserPostModel]? {
        let contentType = convertIndexToType(typeIndex)
        print("🆘 为类型[\(getTypeNameForIndex(typeIndex))]创建备用帖子")
        
        // 创建本地备用帖子
        let historicalFigures = [
            ("苏格拉底", "person.fill.questionmark"),
            ("孔子", "person.bust"),
            ("莎士比亚", "theatermasks"),
            ("爱因斯坦", "atom"),
            ("达芬奇", "paintpalette"),
            ("居里夫人", "testtube.2")
        ]
        
        // 获取该类型配置的生成数量，或使用默认的2-4篇
        let count = min(ExplorationCountManager.shared.getCount(for: contentType), 4)
        var backupPosts = [UserPostModel]()
        
        for i in 0..<count {
            let randomFigureIndex = Int.random(in: 0..<historicalFigures.count)
            let (authorName, authorAvatar) = historicalFigures[randomFigureIndex]
            
            // 根据内容类型生成不同的备用内容
            var content = ""
            switch contentType {
            case .resonance:
                content = "在人生的旅途中，我们总是需要思考自己的道路和方向。"
            case .ancient2modern:
                content = "古人云：'吾日三省吾身'，放在现代社会依然有其价值。"
            case .creativeIdea:
                content = "如果穿越到现代，我一定会对智能手机这个神奇的发明感到惊叹。"
            case .mood:
                content = "今天心情不错，发现了一个有趣的思想，值得分享。"
            case .timelineEvent:
                content = "我们是否应该更多地思考生活的本质，而非追逐外在的物质？"
            }
            
            // 创建一个备用帖子
            let post = UserPostModel(
                id: UUID(),
                username: authorName,
                userAvatar: authorAvatar,
                content: content,
                images: [],
                datePosted: Date().addingTimeInterval(-Double(i * 300)), // 设置不同的时间
                likes: Int.random(in: 5...50),
                comments: [],
                isLikedByCurrentUser: false,
                isBookmarkedByCurrentUser: false,
                contentType: contentType.rawValue,
                source: "wormhole" // 添加来源标识，表示来自虫洞探索
            )
            
            // 为帖子添加评论
            let commentCount = Int.random(in: 1...2)
            for _ in 0..<commentCount {
                // 确保评论者不是帖子作者
                var commenterIndex: Int
                repeat {
                    commenterIndex = Int.random(in: 0..<historicalFigures.count)
                } while commenterIndex == randomFigureIndex
                
                let (commenterName, commenterAvatar) = historicalFigures[commenterIndex]
                
                // 根据内容类型生成不同的评论
                var commentContent = ""
                switch contentType {
                case .resonance:
                    commentContent = "这确实是一个值得思考的问题，自我认知是人生的重要课题。"
                case .ancient2modern:
                    commentContent = "古代智慧永远不会过时，只是需要我们用现代视角重新理解。"
                case .creativeIdea:
                    commentContent = "我也很好奇现代科技，它彻底改变了人类的生活方式。"
                case .mood:
                    commentContent = "分享是一种美德，感谢你的思考。"
                case .timelineEvent:
                    commentContent = "这个问题引发了我深刻的思考，物质与精神确实需要平衡。"
                }
                
                let comment = DetailedCommentModel(
                    id: UUID(),
                    username: commenterName,
                    userAvatar: commenterAvatar,
                    content: commentContent,
                    datePosted: Date().addingTimeInterval(-Double(i * 300 + Int.random(in: 60...180))),
                    isVirtualCharacter: true,
                    characterID: UUID().uuidString,
                    likes: Int.random(in: 1...10),
                    isLikedByCurrentUser: false
                )
                
                post.comments.append(comment)
            }
            
            backupPosts.append(post)
        }
        
        return backupPosts.isEmpty ? nil : backupPosts
    }
}

/**
 * 帖子数量控制视图
 * 显示当前帖子数量并提供增加/减少按钮
 */
struct PostCountControlView: View {
    @Binding var count: Int
    var onIncrease: () -> Void
    var onDecrease: () -> Void
    
    var body: some View {
        HStack(spacing: 24) { // 增加按钮间距
            // 减号按钮
            Button(action: onDecrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 26)) // 稍微增大按钮
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // 数量显示
            HStack(spacing: 6) { // 调整数字和"篇"字的间距
                Text("\(count)")
                    .font(.system(size: 22, weight: .medium)) // 数字字体稍大
                    .foregroundColor(.white)
                
                Text("篇")
                    .font(.system(size: 15)) // "篇"字字体
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 70) // 增加显示区域宽度
            
            // 加号按钮
            Button(action: onIncrease) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26)) // 稍微增大按钮
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 12) // 调整垂直内边距
        .padding(.horizontal, 24) // 调整水平内边距
        .background(
            RoundedRectangle(cornerRadius: 24) // 增加圆角
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

/**
 * 星空背景视图
 */
public struct StarfieldBackground: View {
    @State private var phase: CGFloat = 0
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.1, blue: 0.25),
                        Color(red: 0.1, green: 0.05, blue: 0.2),
                        Color(red: 0.05, green: 0.02, blue: 0.1),
                        Color.black
                    ]),
                    center: .center,
                    startRadius: 1,
                    endRadius: geometry.size.width
                )
                .edgesIgnoringSafeArea(.all)
                
                // 星星层 - 大型星星
                ForEach(0..<50, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1.5...3.0), height: CGFloat.random(in: 1.5...3.0))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Double.random(in: 0.4...1.0))
                        .blur(radius: CGFloat.random(in: 0...0.3))
                }
                
                // 星星层 - 中型星星
                ForEach(0..<100, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 0.8...1.8), height: CGFloat.random(in: 0.8...1.8))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Double.random(in: 0.2...0.8))
                        .blur(radius: CGFloat.random(in: 0...0.2))
                }
                
                // 星星层 - 小型星星
                ForEach(0..<150, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 0.3...1.0), height: CGFloat.random(in: 0.3...1.0))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Double.random(in: 0.1...0.6))
                }
                
                // 闪烁效果
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1.0...2.5), height: CGFloat.random(in: 1.0...2.5))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Foundation.sin(phase + Double.random(in: 0...2 * .pi)))
                }
            }
        }
        .onAppear {
            // 创建闪烁动画
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                phase += 2 * .pi
            }
        }
    }
    
    public init() {}
}

// 导航相关扩展
extension WormholeExplorationView {
    /**
     * 返回首页
     * 使用NotificationCenter广播返回首页的请求
     */
    private func navigateBackToHome() {
        // 取消所有正在进行的任务
        generatePostsTask?.cancel()
        
        // 发送通知以返回主页
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToHomeTab"), object: nil)
        
        // 使用UIApplication获取顶层视图控制器并返回
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            // 如果是NavigationController，尝试返回到根视图
            if let navigationController = rootViewController as? UINavigationController {
                navigationController.popToRootViewController(animated: true)
            } 
            // 如果是模态呈现的，则关闭
            else if let presentedVC = rootViewController.presentedViewController {
                presentedVC.dismiss(animated: true)
            }
        }
    }
} 

/**
 * 创作类型按钮视图
 * 显示不同的创作类型选项
 */
struct WormholeCreationTypeButtonsView: View {
    @ObservedObject private var typeManager = CreationTypeManager.shared
    var onOptionsButtonTapped: ((String) -> Void)? = nil
    var onTypeChanged: (() -> Void)? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<typeManager.types.count, id: \.self) { index in
                    creationTypeButton(for: index)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func creationTypeButton(for index: Int) -> some View {
        let isSelected = typeManager.selectedIndex == index
        
        return Button(action: {
            // 触发触觉反馈
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            
            // 更新选中的类型
            typeManager.selectedIndex = index
            
            // 通知类型已更改
            onTypeChanged?()
        }) {
            buttonLabel(for: index, isSelected: isSelected)
        }
        .overlay(
            optionsButton(for: index),
            alignment: .trailing
        )
    }
    
    private func buttonLabel(for index: Int, isSelected: Bool) -> some View {
        HStack {
            Text(typeManager.types[index])
                .font(.system(size: 15, weight: isSelected ? .medium : .regular)) // 调整字体大小
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 14) // 调整水平内边距
                .padding(.vertical, 8) // 调整垂直内边距
        }
        .background(buttonBackground(isSelected: isSelected))
    }
    
    private func buttonBackground(isSelected: Bool) -> some View {
        Capsule()
            .fill(isSelected ? 
                  selectedGradient() : 
                  LinearGradient(
                      gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.3)]),
                      startPoint: .leading,
                      endPoint: .trailing
                  ))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.15), lineWidth: 0.5)
            )
    }
    
    private func selectedGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.4, green: 0.2, blue: 0.6),
                Color(red: 0.5, green: 0.3, blue: 0.7)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func optionsButton(for index: Int) -> some View {
        Button(action: {
            // 获取内容类型
            let contentTypeText = typeManager.types[index]
            
            // 打印日志，帮助调试
            print("🔘 点击了[\(contentTypeText)]的选项按钮")
            
            // 确保内容类型与ContentGeneratorService.ContentType匹配
            if contentTypeText == "虫洞共鸣" {
                print("✅ 虫洞共鸣类型，使用特殊处理")
                // 为虫洞共鸣类型创建临时帖子，确保使用resonance作为contentType
                let _ = createTempPost(for: contentTypeText)
                onOptionsButtonTapped?(contentTypeText)
            } else if ContentGeneratorService.ContentType(rawValue: contentTypeText) != nil {
                print("✅ 内容类型[\(contentTypeText)]可以成功转换为ContentGeneratorService.ContentType")
                onOptionsButtonTapped?(contentTypeText)
            } else {
                print("⚠️ 警告：内容类型[\(contentTypeText)]无法转换为ContentGeneratorService.ContentType")
            }
        }) {
            Image(systemName: "ellipsis")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .padding(8)
                .background(Color.black.opacity(0.01))
        }
        .offset(x: 30, y: 0)
    }
    
    // 为选项菜单创建临时帖子模型
    private func createTempPost(for contentType: String) -> UserPostModel {
        // 在控制台打印内容类型，方便调试
        print("📋 为类型[\(contentType)]创建临时帖子用于选项菜单")
        
        // 特殊处理"虫洞共鸣"类型
        var finalContentType: String
        if contentType == "虫洞共鸣" {
            print("📋 检测到虫洞共鸣类型，使用特殊处理")
            finalContentType = ContentGeneratorService.ContentType.resonance.rawValue
            print("📋 虫洞共鸣转换为[\(finalContentType)]")
        } else {
            // 转换为ContentGeneratorService.ContentType对象
            let contentTypeEnum = ContentGeneratorService.ContentType(rawValue: contentType)
            
            // 确保为contentType和characterID使用正确的原始值
            finalContentType = contentTypeEnum?.rawValue ?? contentType
            print("📋 转换后的内容类型为[\(finalContentType)]")
        }
        
        return UserPostModel(
            id: UUID(),
            username: "虫洞探索",
            userAvatar: "wormhole",
            content: "临时帖子",
            images: [],
            datePosted: Date(),
            likes: 0,
            comments: [],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: finalContentType,
            characterID: finalContentType,
            source: "wormhole" // 添加来源标识，表示来自虫洞探索
        )
    }
}