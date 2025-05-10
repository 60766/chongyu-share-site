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
    
    // 引入PostViewModel以便生成帖子
    @StateObject private var postViewModel = PostViewModel()
    
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
                    TimeSpaceEffectView(isActive: $isShowingSpaceEffect, centerPosition: centerPosition) {
                        // 当特效完成后，重置过渡状态
                        withAnimation {
                            isTransitioning = false
                        }
                        
                        // 获取当前选中的创作类型索引
                        let selectedTypeIndex = typeManager.selectedIndex
                        
                        // 使用PostViewModel根据创作类型生成帖子
                        let generatedPosts = postViewModel.generatePostsByCreationType(typeIndex: selectedTypeIndex)
                        
                        // 将生成的帖子添加到PostViewModel的posts数组中
                        // 将新生成的帖子放在最前面
                        postViewModel.posts.insert(contentsOf: generatedPosts, at: 0)
                        
                        // 更新生成帖子数量并显示成功提示
                        generatedPostsCount = generatedPosts.count
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            showGeneratedPostsMessage = true
                        }
                        
                        // 3秒后隐藏提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showGeneratedPostsMessage = false
                            }
                        }
                        
                        // 添加触觉反馈
                        let successFeedback = UINotificationFeedbackGenerator()
                        successFeedback.notificationOccurred(.success)
                        
                        print("虫洞捕捉完成，生成了\(generatedPosts.count)个帖子，类型：\(typeManager.types[selectedTypeIndex])")
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