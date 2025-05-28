import SwiftUI
import Foundation

// TimeSpaceEffectCenterTestView 已经在同一个模块中，不需要导入自己的模块

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
    
    // 使用共享的PostViewModel实例
    @ObservedObject private var postViewModel = PostViewModel.shared
    
    // 添加生成帖子成功的状态
    @State private var showGeneratedPostsMessage = false
    @State private var generatedPostsCount = 0
    
    public var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 星空背景
            StarfieldBackground()
            
            // 主标题
            VStack {
                Text("时空探索")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                Text("选择你想探索的方向")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 2)
                
                Spacer()
            }
            .opacity(isShowingButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).delay(0.3), value: isShowingButtons)
            
            // 黑洞视图 - 使用GeometryReader获取其中心位置
            GeometryReader { geometry in
                BlackHoleView()
                    .opacity(isShowingButtons && !isShowingSpaceEffect ? 1 : 0)
                    .scaleEffect(isShowingButtons ? 1 : 0.5)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1), value: isShowingButtons)
                    .onAppear {
                        // 计算黑洞中心位置
                        let centerX = geometry.frame(in: .global).midX
                        let centerY = geometry.frame(in: .global).midY + geometry.size.height * 0.25 - 290
                        blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
                        
                        print("黑洞中心位置设置为: x=\(centerX), y=\(centerY)")
                    }
            }
            
            // 底部按钮视图
            VStack {
                Spacer()
                
                // 创作类型按钮
                CreationTypeButtonsView()
                    .padding(.bottom, 30)
                
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
                        .padding(.vertical, 14)
                        .padding(.horizontal, 36)
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
                .padding(.bottom, 40)
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
                .padding(.bottom, 10)
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
                            showGeneratedPostsMessage = true
                        }
                        
                        // 创建单独的函数处理帖子生成，以简化回调逻辑
                        DispatchQueue.main.async {
                            // 获取选中的创作类型索引
                            let typeIndex = typeManager.selectedIndex
                            print("🚀 当前选择的创作类型索引: \(typeIndex)")
                            
                            // 生成基于当前所选创作类型的帖子
                            print("🚀 开始生成帖子...")
                            var posts = postViewModel.generatePostsByCreationType(typeIndex: typeIndex)
                            print("🚀 generatePostsByCreationType返回了 \(posts.count) 篇帖子")
                            
                            // 检查帖子是否生成成功 - 增加保障措施，确保生成的帖子有效
                            if posts.isEmpty {
                                print("⚠️ 严重错误：第一次尝试未生成任何帖子！重试...")
                                // 重试一次
                                posts = postViewModel.generatePostsByCreationType(typeIndex: typeIndex)
                                
                                if posts.isEmpty {
                                    print("⚠️⚠️ 严重错误：第二次尝试仍未生成任何帖子！")
                                    // 最后尝试通过强制索引生成
                                    posts = postViewModel.generatePostsByCreationType(typeIndex: 0)
                                    
                                    if posts.isEmpty {
                                        print("⚠️⚠️⚠️ 致命错误：无法生成任何帖子，可能是PostViewModel出现问题")
                                        // 作为最后的尝试，手动创建一个带有评论的帖子
                                        print("🔄 尝试创建备用帖子作为最后的尝试...")

                                        // 选择一位历史人物作为评论者
                                        let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
                                        let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
                                        
                                        let commenterIndex = Int.random(in: 0..<historicalFigures.count)
                                        let commenterName = historicalFigures[commenterIndex]
                                        let commenterAvatar = avatarSymbols[commenterIndex]
                                        
                                        // 创建两条历史人物评论
                                        let comment1 = UserCommentModel(
                                            username: commenterName,
                                            userAvatar: commenterAvatar,
                                            content: "作为\(commenterName)，我对这个虫洞探索非常感兴趣。跨越时空的体验总是让我思考宇宙的本质。",
                                            datePosted: Date().addingTimeInterval(-Double.random(in: 0...1800)),
                                            likes: Int.random(in: 5...25),
                                            isVirtualCharacter: true,
                                            characterID: commenterName.lowercased()
                                        )
                                        
                                        // 选择另一位历史人物
                                        var secondCommenterIndex = Int.random(in: 0..<historicalFigures.count)
                                        while secondCommenterIndex == commenterIndex {
                                            secondCommenterIndex = Int.random(in: 0..<historicalFigures.count)
                                        }
                                        let secondCommenterName = historicalFigures[secondCommenterIndex]
                                        let secondCommenterAvatar = avatarSymbols[secondCommenterIndex]
                                        
                                        let comment2 = UserCommentModel(
                                            username: secondCommenterName,
                                            userAvatar: secondCommenterAvatar,
                                            content: "\(commenterName)的观点很有启发性。我也想补充，从\(secondCommenterName)的视角看，这种跨维度的体验展示了思维的无限可能。",
                                            datePosted: Date().addingTimeInterval(-Double.random(in: 0...900)),
                                            likes: Int.random(in: 3...20),
                                            isVirtualCharacter: true,
                                            characterID: secondCommenterName.lowercased()
                                        )
                                        
                                        // 创建最终备用帖子
                                        let backupPost = UserPostModel(
                                            id: UUID(),
                                            username: "虫遇探索者",
                                            userAvatar: "person.fill",
                                            content: "穿越虫洞漫游时，遭遇了一个特殊的时空节点，那里的物理规则与我们的主宇宙完全不同。思维在那里可以直接影响现实...",
                                            images: [],
                                            datePosted: Date(),
                                            likes: Int.random(in: 10...30),
                                            comments: [comment1, comment2],
                                            isLikedByCurrentUser: false,
                                            isBookmarkedByCurrentUser: false
                                        )
                                        
                                        posts = [backupPost]
                                        print("✅ 已创建包含\(backupPost.comments.count)条评论的备用帖子: \(backupPost.id)")
                                        
                                        // 显示错误信息后立即关闭，避免错误状态持续
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            withAnimation {
                                                showGeneratedPostsMessage = false
                                            }
                                        }
                                        // 不提前返回，尝试使用这个备用帖子
                                    }
                                }
                            }
                            
                            // 更新生成成功的帖子数量
                            generatedPostsCount = posts.count
                            print("✅ 成功生成 \(posts.count) 篇帖子，创作类型: \(typeManager.types[typeIndex])")
                            
                            // 捕获当前帖子数量用于验证
                            let beforeCount = postViewModel.posts.count
                            print("📊 添加前帖子总数: \(beforeCount)")
                            
                            // 在主线程上添加帖子
                            DispatchQueue.main.async {
                                print("🚀 开始添加帖子到PostViewModel...")
                                postViewModel.addPosts(posts)
                                
                                // 验证添加成功
                                let afterCount = postViewModel.posts.count
                                print("📊 添加后帖子总数: \(afterCount)，添加了 \(posts.count) 篇帖子")
                                
                                // 发送多个通知，确保主页面能收到更新
                                print("📣 发送NewPostsGenerated通知")
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("NewPostsGenerated"),
                                    object: nil
                                )
                                
                                print("📣 发送PostsUpdated通知")
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("PostsUpdated"),
                                    object: nil
                                )
                                
                                // 0.3秒后再次发送通知
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    print("📣 延迟0.3秒后再次发送通知")
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("NewPostsGenerated"),
                                        object: nil
                                    )
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PostsUpdated"),
                                        object: nil
                                    )
                                }
                                
                                // 再次0.5秒后最后一次发送通知
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    print("📣 延迟0.5秒后最后一次发送通知")
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("NewPostsGenerated"),
                                        object: nil
                                    )
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PostsUpdated"),
                                        object: nil
                                    )
                                    
                                    print("✨ 所有生成和通知步骤已完成")
                                }
                            }
                            
                            // 显示成功信息一段时间后关闭
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showGeneratedPostsMessage = false
                                }
                                
                                // 提供触觉反馈
                                let successFeedback = UINotificationFeedbackGenerator()
                                successFeedback.notificationOccurred(.success)
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    // 确保特效位于最顶层且全屏显示
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(100) // 确保在最上层显示
                }
            }
        }
        .onAppear {
            // 延迟显示按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    isShowingButtons = true
                }
            }
        }
    }
    
    public init() {}
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