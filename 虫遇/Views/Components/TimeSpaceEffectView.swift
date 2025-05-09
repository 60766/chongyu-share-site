import SwiftUI
import Combine

/**
 * 时空特效视图 - 简化版
 * 提供虫洞穿越和时空扭曲的视觉效果
 */
struct TimeSpaceEffectView: View {
    // 激活状态绑定
    @Binding var isActive: Bool
    
    // 可选的回调函数，在特效完成时触发
    var onComplete: (() -> Void)?
    
    // 可选的中心点位置，用于自定义特效中心
    var effectCenterPosition: CGPoint?
    
    // 动画状态
    @State private var animationProgress: Double = 0
    
    // 环扩散动画
    @State private var ringScale: CGFloat = 0
    @State private var ringOpacity: Double = 0
    
    // 星光粒子动画
    @State private var particlesOpacity: Double = 0
    @State private var starScale: Double = 1.0
    @State private var starAcceleration: Double = 1.0
    
    // 旋转动画
    @State private var rotationAngle: Double = 0
    
    // 隧道动画
    @State private var tunnelScale: CGFloat = 0
    @State private var tunnelRotation: Double = 0
    @State private var tunnelDepth: Double = 1.0
    
    // 中心脉动
    @State private var centerPulse: Double = 0
    
    // 闪光效果
    @State private var glowOpacity: Double = 0.7
    @State private var flashOpacity: Double = 0
    @State private var rayOpacity: Double = 0
    @State private var finalGlowScale: Double = 1.0
    @State private var finalGlowOpacity: Double = 0
    
    // 空间扭曲效果
    @State private var warpEffect: Double = 0
    
    // 新增状态变量
    @State private var eventHorizonScale: CGFloat = 0
    @State private var singularityPull: Double = 0
    
    // 简化的body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景层
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                // 计算中心位置
                let centerPosition = getEffectCenter(in: geometry)
                
                // 特效内容
                if animationProgress > 0 {
                    // 第1阶段：初始形成
                    if animationProgress < 0.5 {
                        initialFormationEffects(geometry: geometry, centerPosition: centerPosition)
                    }
                    
                    // 第2阶段：隧道形成
                    if animationProgress >= 0.5 && animationProgress < 1.2 {
                        tunnelFormationEffects(geometry: geometry, centerPosition: centerPosition)
                    }
                    
                    // 第3阶段：爆发效果
                    if animationProgress >= 1.2 && animationProgress < 1.6 {
                        burstEffects(geometry: geometry, centerPosition: centerPosition)
                    }
                    
                    // 第4阶段：溶解返回
                    if animationProgress >= 1.6 {
                        dissolveEffects(geometry: geometry, centerPosition: centerPosition)
                    }
                }
            }
            .onAppear {
                startAnimation()
            }
        }
    }
    
    // MARK: - 特效阶段实现
    
    // 阶段1：初始形成效果
    private func initialFormationEffects(geometry: GeometryProxy, centerPosition: CGPoint) -> some View {
        ZStack {
            // 事件视界
            Circle()
                .fill(Color.black.opacity(0.8))
                .frame(width: eventHorizonScale * 250, height: eventHorizonScale * 250)
                .position(centerPosition)
                .opacity(min(1.0, animationProgress * 3))
            
            // 扩散环
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.purple.opacity(0.8 - Double(index) * 0.2), lineWidth: 2 - CGFloat(index) * 0.5)
                    .frame(
                        width: ringScale * (1 + CGFloat(index) * 0.3) * geometry.size.width,
                        height: ringScale * (1 + CGFloat(index) * 0.3) * geometry.size.width
                    )
                    .opacity(ringOpacity * (1.0 - Double(index) * 0.2))
                    .position(centerPosition)
            }
            
            // 中心光点
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.purple.opacity(0.8),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.5, y: 0.5),
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 100, height: 100)
                .opacity(animationProgress < 0.3 ? animationProgress * 3 : 1.0 - (animationProgress - 0.3) * 5)
                .position(centerPosition)
        }
    }
    
    // 阶段2：隧道形成效果
    private func tunnelFormationEffects(geometry: GeometryProxy, centerPosition: CGPoint) -> some View {
        ZStack {
            // 隧道环
            ForEach(0..<5, id: \.self) { index in
                let progress = (animationProgress - 0.5) / 0.7 // 归一化到0-1
                let opacity = min(1.0, progress * 2 - Double(index) * 0.2)
                let size = tunnelScale * (1.0 - Double(index) * 0.15) * geometry.size.width
                
                Ellipse()
                    .stroke(
                        Color.purple.opacity(0.7),
                        lineWidth: 2 - CGFloat(index) * 0.3
                    )
                    .frame(width: size, height: size * 0.8)
                    .rotationEffect(.degrees(tunnelRotation * (index % 2 == 0 ? 1 : -1)))
                    .opacity(opacity)
                    .position(centerPosition)
            }
            
            // 星光粒子
            ForEach(0..<20, id: \.self) { index in
                let angle = Double(index) * 18.0 + rotationAngle
                let distance = (0.2 + Double(index % 5) / 10.0) * min(geometry.size.width, geometry.size.height) * 0.5
                let xPos = cos(angle * .pi / 180.0) * distance
                let yPos = sin(angle * .pi / 180.0) * distance
                
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 2 + CGFloat(index % 3), height: 2 + CGFloat(index % 3))
                    .position(
                        x: centerPosition.x + CGFloat(xPos),
                        y: centerPosition.y + CGFloat(yPos)
                    )
                    .opacity(particlesOpacity)
            }
        }
    }
    
    // 阶段3：爆发效果
    private func burstEffects(geometry: GeometryProxy, centerPosition: CGPoint) -> some View {
        ZStack {
            // 闪光效果
            Color.white
                .opacity(flashOpacity)
                .edgesIgnoringSafeArea(.all)
            
            // 中心爆发光球
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.purple.opacity(0.8),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.5, y: 0.5),
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: finalGlowScale * 50, height: finalGlowScale * 50)
                .opacity(finalGlowOpacity)
                .position(centerPosition)
            
            // 放射线
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.purple.opacity(0.7),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 3)
                    .rotationEffect(.degrees(Double(index) * 30))
                    .opacity(rayOpacity)
                    .position(centerPosition)
            }
        }
    }
    
    // 阶段4：溶解返回效果
    private func dissolveEffects(geometry: GeometryProxy, centerPosition: CGPoint) -> some View {
        ZStack {
            // 背景过渡
            Color(.systemBackground)
                .opacity(min(1.0, (animationProgress - 1.6) * 2.5))
                .edgesIgnoringSafeArea(.all)
            
            // 余波粒子
            ForEach(0..<30, id: \.self) { index in
                Circle()
                    .fill(Color.purple.opacity(0.6))
                    .frame(width: 2, height: 2)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(1.0 - min(1.0, (animationProgress - 1.6) * 2))
            }
            
            // 消散光晕
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.5, y: 0.5),
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .position(centerPosition)
                .opacity(1.0 - min(1.0, (animationProgress - 1.6) * 3))
        }
    }
    
    // MARK: - 辅助方法
    
    // 获取特效中心点
    private func getEffectCenter(in geometry: GeometryProxy) -> CGPoint {
        if let centerPoint = effectCenterPosition {
            return centerPoint
        } else {
            return CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
    
    // 将CGPoint转换为UnitPoint
    private func getCenterUnitPoint(for geometry: GeometryProxy) -> UnitPoint {
        let centerPosition = getEffectCenter(in: geometry)
        let relativeX = centerPosition.x / geometry.size.width
        let relativeY = centerPosition.y / geometry.size.height
        return UnitPoint(x: relativeX, y: relativeY)
    }
    
    // 启动动画序列
    private func startAnimation() {
        // 播放触觉反馈
        let initialFeedback = UIImpactFeedbackGenerator(style: .medium)
        initialFeedback.impactOccurred()
        
        // 阶段1: 事件视界形成 (0-0.5秒)
        withAnimation(.easeOut(duration: 0.5)) {
            ringScale = 1.0
            ringOpacity = 0.8
            particlesOpacity = 0.7
            eventHorizonScale = 1.0
            rotationAngle = 30
        }
        
        // 持续旋转动画
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // 阶段2: 隧道形成 (0.5-1.2秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let feedback = UIImpactFeedbackGenerator(style: .soft)
            feedback.impactOccurred(intensity: 0.7)
            
            withAnimation(.easeInOut(duration: 0.7)) {
                tunnelScale = 1.8
                tunnelRotation = 60
                tunnelDepth = 1.5
                warpEffect = 1.0
                singularityPull = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.7)) {
                starScale = 0.1
            }
            
            withAnimation(.easeOut(duration: 0.7)) {
                starAcceleration = 2.5
            }
            
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                centerPulse = 1.0
            }
        }
        
        // 阶段3: 爆发 (1.2-1.6秒)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let feedback = UIImpactFeedbackGenerator(style: .rigid)
            feedback.impactOccurred(intensity: 1.0)
            
            withAnimation(.easeIn(duration: 0.08)) {
                flashOpacity = 0.95
            }
            
            withAnimation(.easeOut(duration: 0.25)) {
                rayOpacity = 0.9
            }
            
            withAnimation(.easeOut(duration: 0.4)) {
                finalGlowScale = 12.0
                finalGlowOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.25).delay(0.1)) {
                flashOpacity = 0
            }
            
            withAnimation(.easeOut(duration: 0.3).delay(0.15)) {
                rayOpacity = 0
            }
        }
        
        // 总体动画进度
        withAnimation(.easeInOut(duration: 2.0)) {
            animationProgress = 2.0
        }
        
        // 动画结束后调用回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let onComplete = onComplete {
                onComplete()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isActive = false
            }
        }
    }
    
    // MARK: - 初始化方法
    
    // 默认初始化器 - 使用屏幕中心
    init(isActive: Binding<Bool>, onComplete: (() -> Void)? = nil) {
        self._isActive = isActive
        self.onComplete = onComplete
        self.effectCenterPosition = nil
    }
    
    // 自定义中心点初始化器
    init(isActive: Binding<Bool>, centerPosition: CGPoint, onComplete: (() -> Void)? = nil) {
        self._isActive = isActive
        self.onComplete = onComplete
        self.effectCenterPosition = centerPosition
    }
}

#Preview {
    TimeSpaceEffectView(isActive: .constant(true), onComplete: {})
} 