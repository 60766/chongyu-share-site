import SwiftUI
import Foundation

// 移除自导入，因为该文件已经是模块的一部分
// @_implementationOnly import struct 虫遇.TimeSpaceEffectCenterTestView

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
                // 使用ZStack包装BlackHoleView并使用geometry获取其确切中心位置
                ZStack {
                    BlackHoleView()
                        .opacity(isShowingButtons && !isShowingSpaceEffect ? 1 : 0)
                        .scaleEffect(isShowingButtons ? 1 : 0.5)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1), value: isShowingButtons)
                        .background(
                            // 使用背景GeometryReader精确捕获黑洞中心位置
                            GeometryReader { blackHoleGeometry in
                                Color.clear
                                    .onAppear {
                                        // 计算黑洞中心位置 - 这是随机漫游按钮所在位置
                                        let centerX = blackHoleGeometry.frame(in: .global).midX
                                        let centerY = blackHoleGeometry.frame(in: .global).midY
                                        blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
                                    }
                                    .onChange(of: geometry.size) { _, _ in
                                        // 屏幕尺寸改变时更新位置
                                        let centerX = blackHoleGeometry.frame(in: .global).midX
                                        let centerY = blackHoleGeometry.frame(in: .global).midY
                                        blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
                                    }
                            }
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
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
            
            // 时空效果覆盖层 - 使用新的TimeSpaceEffectView
            if isShowingSpaceEffect {
                TimeSpaceEffectView(isActive: $isShowingSpaceEffect, effectCenterPosition: blackHoleCenterPosition) {
                    // 当特效完成后，重置过渡状态
                    withAnimation {
                        isTransitioning = false
                    }
                    
                    // 可以添加其他逻辑，例如导航到新页面等
                    print("虫洞捕捉完成")
                }
                .edgesIgnoringSafeArea(.all)
                // 确保特效位于最顶层且全屏显示
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(100) // 确保在最上层显示
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
            }
            .onChange(of: phase) { _, newValue in
                // 添加微妙的星星移动或闪烁效果
                // 根据phase更新星星位置或不透明度
            }
            .onAppear {
                // 添加星星闪烁动画
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                    phase = 1.0
                }
            }
        }
    }
} 