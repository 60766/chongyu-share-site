import SwiftUI
import Combine

/**
 * 时空特效视图
 * 为应用提供高级的时空穿越特效
 */
struct TimeSpaceEffectView: View {
    // 绑定状态，用于控制特效的开始和结束
    @Binding var isActive: Bool
    
    // 动画完成时的回调
    var onComplete: (() -> Void)?
    
    // 特效中心点位置，默认为nil（使用屏幕中心）
    var effectCenterPosition: CGPoint?
    
    // 状态变量控制动画效果
    @State private var animationProgress: Double = 0
    @State private var centerScale: CGFloat = 0.1
    @State private var glowOpacity: Double = 0
    @State private var particlesScale: CGFloat = 0.1
    @State private var particlesOpacity: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var tunnelScale: CGFloat = 0.1
    @State private var tunnelRotation: Double = 0
    @State private var starScale: CGFloat = 1.0
    @State private var centerPulse: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var rayOpacity: Double = 0
    @State private var finalGlowScale: CGFloat = 1.0
    @State private var finalGlowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.2
    @State private var ringOpacity: Double = 0
    @State private var rotation: Double = 0
    @State private var flashTriggered: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 黑色背景层 - 增强对比度
                Color.black.opacity(0.9)
                    .edgesIgnoringSafeArea(.all)
                
                // 星空背景效果 - 50个随机分布的星星
                ForEach(0..<50, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.7)))
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(particlesOpacity)
                        .blur(radius: 0.3)
                }
                
                // 计算中心位置 - 使用提供的中心点或默认为屏幕中心
                let centerPosition = effectCenterPosition ?? CGPoint(
                    x: geometry.size.width / 2, 
                    y: geometry.size.height / 2
                )
                
                // 阶段1: 虫洞形成 (0-0.5秒)
                ZStack {
                    // 中心爆发光点
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color(red: 0.7, green: 0.5, blue: 0.9, opacity: 0.8),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: animationProgress < 0.5 ? animationProgress * 400 : 200, 
                               height: animationProgress < 0.5 ? animationProgress * 400 : 200)
                        .opacity(animationProgress < 0.5 ? (1 - animationProgress * 0.7) : 0.3)
                        .position(centerPosition)
                    
                    // 扩散环 - 三个同心圆扩散
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.6, green: 0.4, blue: 0.8),
                                        Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.7)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2 - CGFloat(index) * 0.5
                            )
                            .frame(width: ringScale * (1 + CGFloat(index) * 0.3) * geometry.size.width,
                                   height: ringScale * (1 + CGFloat(index) * 0.3) * geometry.size.width)
                            .opacity(ringOpacity - CGFloat(index) * 0.2)
                            .position(centerPosition)
                    }
                }
                
                // 阶段2: 虫洞隧道 (0.5-1.2秒)
                ZStack {
                    // 隧道边缘 - 多层叠加的旋转圆环
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.2, blue: 0.6),
                                        Color(red: 0.6, green: 0.4, blue: 0.8),
                                        Color(red: 0.7, green: 0.6, blue: 0.9),
                                        Color(red: 0.5, green: 0.3, blue: 0.7)
                                    ]),
                                    center: .center
                                ),
                                lineWidth: 1 + CGFloat(index) * 0.5
                            )
                            .scaleEffect(tunnelScale - (0.15 * CGFloat(index)))
                            .rotationEffect(.degrees(tunnelRotation + Double(index) * 15))
                            .opacity(animationProgress >= 0.5 && animationProgress < 1.4 ? 
                                    min(1.0, (animationProgress - 0.5) * 4) : 
                                    (animationProgress >= 1.4 ? max(0, 2.0 - animationProgress) : 0))
                            .blur(radius: 0.5)
                            .position(centerPosition)
                    }
                    
                    // 星光粒子 - 从中心向外或向内飞行的粒子
                    ForEach(0..<30, id: \.self) { _ in
                        let size = CGFloat.random(in: 1...4)
                        let distance = CGFloat.random(in: 50...300)
                        let angle = CGFloat.random(in: 0...2*Double.pi)
                        let speed = CGFloat.random(in: 0.7...1.3)
                        let delay = CGFloat.random(in: 0...0.3)
                        
                        Circle()
                            .fill(
                                Color(
                                    red: Double.random(in: 0.5...0.9),
                                    green: Double.random(in: 0.5...0.9),
                                    blue: Double.random(in: 0.7...1.0)
                                )
                            )
                            .frame(width: size, height: size)
                            .position(
                                x: centerPosition.x + cos(angle) * distance * starScale * speed,
                                y: centerPosition.y + sin(angle) * distance * starScale * speed
                            )
                            .opacity(animationProgress >= 0.5 && animationProgress < 1.4 ? 
                                    min(1.0, (animationProgress - 0.5 - delay) * 5) : 
                                    (animationProgress >= 1.4 ? max(0, 1.8 - animationProgress) : 0))
                            .blur(radius: 0.3)
                    }
                    
                    // 中心光芒 - 脉动效果
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color(red: 0.9, green: 0.8, blue: 1.0).opacity(0.7),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 30 + centerPulse * 20, height: 30 + centerPulse * 20)
                        .opacity(animationProgress >= 0.7 && animationProgress < 1.4 ? 
                                min(0.8, (animationProgress - 0.7) * 3) : 
                                (animationProgress >= 1.4 ? max(0, 1.8 - animationProgress) : 0))
                        .blur(radius: 3)
                        .position(centerPosition)
                }
                
                // 阶段3: 虫洞爆发 (1.2-1.6秒)
                ZStack {
                    // 全屏闪光
                    Color.white
                        .opacity(flashOpacity)
                        .edgesIgnoringSafeArea(.all)
                    
                    // 放射光线
                    ForEach(0..<16, id: \.self) { index in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color(red: 0.8, green: 0.7, blue: 1.0).opacity(0.7),
                                        Color.clear
                                    ]),
                                    startPoint: .center,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width, height: 1 + CGFloat(index % 3))
                            .rotationEffect(.degrees(Double(index) * (360.0 / 16.0)))
                            .opacity(rayOpacity - 0.1 * CGFloat(index % 3))
                            .position(centerPosition)
                    }
                    
                    // 中心光球
                    Circle()
                        .fill(Color.white)
                        .frame(width: finalGlowScale * 50, height: finalGlowScale * 50)
                        .opacity(finalGlowOpacity * (2.0 - finalGlowScale/5.0))
                        .blur(radius: finalGlowScale * 10)
                        .position(centerPosition)
                }
                
                // 阶段4: 溶解返回 (1.6-2.0秒)
                ZStack {
                    // 逐渐显示主页面的背景色
                    Color(.systemBackground)
                        .opacity(animationProgress >= 1.6 ? min(1.0, (animationProgress - 1.6) * 3) : 0)
                        .edgesIgnoringSafeArea(.all)
                    
                    // 最终粒子效果 - 优雅的小星星缓缓消失
                    ForEach(0..<30, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .opacity(animationProgress >= 1.6 ? 1.0 - min(1.0, (animationProgress - 1.6) * 2) : 0)
                    }
                }
            }
            .onAppear {
                startAnimation()
            }
        }
    }
    
    // 统一控制所有动画
    private func startAnimation() {
        // 播放触觉反馈
        let initialFeedback = UIImpactFeedbackGenerator(style: .medium)
        initialFeedback.impactOccurred()
        
        // 阶段1: 虫洞形成动画 (0-0.5秒)
        withAnimation(.easeOut(duration: 0.5)) {
            ringScale = 1.0
            ringOpacity = 0.8
            particlesOpacity = 0.7
        }
        
        // 阶段2: 隧道形成动画 (0.5-1.2秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 触觉反馈 - 虫洞形成
            let formationFeedback = UIImpactFeedbackGenerator(style: .soft)
            formationFeedback.impactOccurred(intensity: 0.7)
            
            // 隧道扩展动画
            withAnimation(.easeInOut(duration: 0.7)) {
                tunnelScale = 1.5
                tunnelRotation = 45
            }
            
            // 星光向中心收缩动画
            withAnimation(.easeIn(duration: 0.7)) {
                starScale = 0.2
            }
            
            // 中心光芒脉动动画
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                centerPulse = 1.0
            }
        }
        
        // 阶段3: 虫洞爆发动画 (1.2-1.6秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // 触觉反馈 - 虫洞爆发
            let burstFeedback = UIImpactFeedbackGenerator(style: .rigid)
            burstFeedback.impactOccurred(intensity: 1.0)
            
            // 闪光动画
            withAnimation(.easeIn(duration: 0.1)) {
                flashOpacity = 0.9
            }
            
            // 光线动画
            withAnimation(.easeOut(duration: 0.2)) {
                rayOpacity = 0.8
            }
            
            // 爆发动画
            withAnimation(.easeOut(duration: 0.5)) {
                finalGlowScale = 10.0
                finalGlowOpacity = 1.0
            }
            
            // 闪光消失
            withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
                flashOpacity = 0
                rayOpacity = 0
            }
        }
        
        // 主动画进度控制
        withAnimation(.easeInOut(duration: 2.0)) {
            animationProgress = 2.0
        }
        
        // 动画结束后调用回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 回调传递到上层组件
            if let onComplete = onComplete {
                onComplete()
            }
            
            // 最后重置isActive状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isActive = false
            }
        }
    }
    
    // 默认初始化器 - 使用屏幕中心作为特效中心
    init(isActive: Binding<Bool>, onComplete: (() -> Void)? = nil) {
        self._isActive = isActive
        self.onComplete = onComplete
        self.effectCenterPosition = nil
    }
    
    // 带位置参数的初始化器 - 使用指定位置作为特效中心
    init(isActive: Binding<Bool>, centerPosition: CGPoint, onComplete: (() -> Void)? = nil) {
        self._isActive = isActive
        self.onComplete = onComplete
        self.effectCenterPosition = centerPosition
    }
}

#Preview {
    TimeSpaceEffectView(isActive: .constant(true), onComplete: {})
} 