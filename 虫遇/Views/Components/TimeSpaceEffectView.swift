import SwiftUI

/**
 * 简化版时空特效视图
 * 用于测试虫洞捕捉按钮点击后的动画效果
 */
struct TimeSpaceEffectView: View {
    @Binding var isActive: Bool
    let onComplete: () -> Void
    
    // 动画状态变量
    @State private var animationProgress: Double = 0
    @State private var centerScale: CGFloat = 0.1
    @State private var glowOpacity: Double = 0
    @State private var particlesScale: CGFloat = 0
    @State private var particlesOpacity: Double = 0
    @State private var finalGlowScale: CGFloat = 0
    @State private var finalGlowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.1
    @State private var ringOpacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // 黑色背景逐渐填充屏幕
            Color.black
                .opacity(min(0.9, animationProgress * 1.2))
                .edgesIgnoringSafeArea(.all)
            
            // 添加星空效果
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.5)))
                    .frame(width: CGFloat.random(in: 1...2), height: CGFloat.random(in: 1...2))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(min(1.0, animationProgress * 1.5))
            }
            
            // 能量光环
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.7, green: 0.3, blue: 0.9, opacity: 0.8),
                                Color(red: 0.5, green: 0.3, blue: 0.7, opacity: 0.6),
                                Color(red: 0.7, green: 0.3, blue: 0.9, opacity: 0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0 - CGFloat(index) * 0.5
                    )
                    .frame(width: 150 + CGFloat(index) * 30, height: 150 + CGFloat(index) * 30)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity * (1.0 - Double(index) * 0.15))
                    .rotationEffect(.degrees(rotation * (index % 2 == 0 ? 1 : -1)))
            }
            
            // 光线效果
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.7),
                                Color(red: 0.6, green: 0.4, blue: 0.8, opacity: 0.4),
                                Color.clear
                            ]),
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 1.5)
                    .rotationEffect(.degrees(Double(index) * 45 + rotation * 0.2))
                    .opacity(min(1.0, particlesOpacity * 1.2))
                    .blur(radius: 0.5)
            }
            
            // 中心光晕效果
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color(red: 0.6, green: 0.4, blue: 0.8, opacity: 0.5),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(centerScale)
                .opacity(glowOpacity)
                .blur(radius: 3)
            
            // 粒子效果 - 增加数量
            ForEach(0..<30, id: \.self) { index in
                Circle()
                    .fill(
                        Color(
                            red: Double.random(in: 0.5...0.8),
                            green: Double.random(in: 0.3...0.6),
                            blue: Double.random(in: 0.7...1.0)
                        )
                    )
                    .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
                    .offset(
                        x: CGFloat.random(in: -200...200) * particlesScale,
                        y: CGFloat.random(in: -200...200) * particlesScale
                    )
                    .opacity(particlesOpacity * Double.random(in: 0.3...1.0))
                    .blur(radius: CGFloat.random(in: 0...0.5))
            }
            
            // 最终闪光效果
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .scaleEffect(finalGlowScale)
                .opacity(finalGlowOpacity)
                .blur(radius: 15)
        }
        .onAppear {
            // 触发触觉反馈
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
            
            startAnimation()
            
            // 添加旋转动画
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    private func startAnimation() {
        // 第一阶段：中心光晕出现
        withAnimation(.easeIn(duration: 0.3)) {
            centerScale = 1.0
            glowOpacity = 0.8
            animationProgress = 0.3
            ringScale = 0.8
            ringOpacity = 0.7
        }
        
        // 第二阶段：粒子扩散
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                particlesScale = 1.0
                particlesOpacity = 0.7
                animationProgress = 0.7
                ringScale = 1.0
                ringOpacity = 0.8
            }
            
            // 第三阶段：最终闪光
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) {
                    centerScale = 0.1
                    glowOpacity = 0
                    particlesScale = 3.0
                    particlesOpacity = 0
                    finalGlowScale = 10.0
                    finalGlowOpacity = 0.9
                    animationProgress = 1.0
                    ringScale = 2.0
                    ringOpacity = 0
                }
                
                // 触发第二次触觉反馈
                let feedbackBurst = UIImpactFeedbackGenerator(style: .heavy)
                feedbackBurst.impactOccurred()
                
                // 闪光消失并调用完成回调
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        finalGlowOpacity = 0
                    }
                    
                    // 完成动画后调用回调
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isActive = false
                        onComplete()
                    }
                }
            }
        }
    }
}

#Preview {
    TimeSpaceEffectView(isActive: .constant(true), onComplete: {})
} 