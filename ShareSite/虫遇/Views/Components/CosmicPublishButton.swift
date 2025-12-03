import SwiftUI
import CoreHaptics
import UIKit

/**
 * 粒子视图组件
 * 用于虫洞按钮点击时的粒子动画效果
 */
struct ParticleView: View {
    @State private var position = CGPoint.zero
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    private let destination = CGPoint(
        x: CGFloat.random(in: -100...100),
        y: CGFloat.random(in: -100...100)
    )
    
    private let particleSize = CGFloat.random(in: 3...8)
    private let rotationAmount = Double.random(in: 0...360)
    private let particleColor = [
        Color(red: 0.5, green: 0.5, blue: 1.0),
        Color(red: 0.6, green: 0.6, blue: 1.0),
        Color(red: 0.4, green: 0.4, blue: 0.9)
    ].randomElement()!
    
    var body: some View {
        Circle()
            .fill(particleColor)
            .frame(width: particleSize, height: particleSize)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .offset(x: position.x, y: position.y)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    position = destination
                    scale = 1
                    opacity = 1
                    rotation = rotationAmount
                }
                
                withAnimation(.easeIn(duration: 0.2).delay(0.6)) {
                    scale = 0
                    opacity = 0
                }
            }
    }
}

/**
 * 虫洞发布按钮
 * 应用的核心交互组件，用于发起内容创建流程
 * 优化设计：减轻视觉重量，更加协调
 */
struct CosmicPublishButton: View {
    /// 按钮按下状态
    @Binding var isPressed: Bool
    /// 动画相位
    @State private var animationPhase: Double = 0
    /// 光晕强度
    @State private var glowIntensity: Double = 0.6
    /// 旋转角度
    @State private var rotationAngle: Double = 0
    /// 粒子效果控制
    @State private var particlesActive = false
    
    /// 按钮点击回调
    var onPress: () -> Void
    
    /// 触觉引擎
    @State private var hapticEngine: CHHapticEngine?
    
    var body: some View {
        ZStack {
            // 虫洞背景光晕效果 - 减小尺寸和不透明度
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.45, green: 0.45, blue: 0.95, opacity: 0.7),
                            Color(red: 0.35, green: 0.35, blue: 0.9, opacity: 0.5),
                            Color(red: 0.1, green: 0.1, blue: 0.3, opacity: 0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60 // 减小半径
                    )
                )
                .frame(width: 90, height: 90) // 减小尺寸
                .opacity(glowIntensity)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowIntensity)
                .onAppear {
                    glowIntensity = 0.9 // 降低最大光晕强度
                }
            
            // 虫洞螺旋纹路 - 减小尺寸和层数
            ForEach(0..<2) { i in // 减少层数
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.5, green: 0.5, blue: 1.0, opacity: 0),
                                Color(red: 0.5, green: 0.5, blue: 1.0),
                                Color(red: 0.5, green: 0.5, blue: 1.0, opacity: 0)
                            ]),
                            center: .center
                        ),
                        lineWidth: 1.5 // 减小线宽
                    )
                    .frame(width: 50 - CGFloat(i * 8), height: 50 - CGFloat(i * 8)) // 减小尺寸
                    .rotationEffect(.degrees(rotationAngle + Double(i) * 30))
            }
            .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: rotationAngle)
            .onAppear {
                rotationAngle = 360
            }
            
            // 中心发光点 - 更加轻量化的加号设计
            ZStack {
                // 发光背景 - 减小尺寸和发光
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .white,
                                Color(red: 0.6, green: 0.6, blue: 1.0).opacity(0.5)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 15 // 减小发光半径
                        )
                    )
                    .frame(width: 30, height: 30) // 减小尺寸
                    .blur(radius: 4) // 减小模糊半径
                
                // 白色加号 - 更轻量化设计
                ZStack {
                    // 水平线 - 更短更细
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 16, height: 3) // 减小尺寸
                    
                    // 垂直线 - 更短更细
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 3, height: 16) // 减小尺寸
                }
                .shadow(color: .white, radius: 2) // 减小阴影
            }
            .shadow(color: Color(red: 0.5, green: 0.5, blue: 1.0), radius: 6) // 减小阴影
            
            // 粒子效果层 (当按钮被点击时激活) - 减少粒子数量
            if particlesActive {
                ZStack {
                    ForEach(0..<15, id: \.self) { _ in // 减少粒子数量
                        ParticleView()
                    }
                }
            }
        }
        .frame(width: 70, height: 70) // 减小整体尺寸
        .contentShape(Circle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        // 添加更轻量的脉冲动画效果
        .overlay(
            ZStack {
                // 外层脉冲光环 - 减轻效果
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.5, green: 0.5, blue: 1.0, opacity: 0.6),
                                Color(red: 0.5, green: 0.5, blue: 1.0, opacity: 0.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5 // 减小线宽
                    )
                    .scaleEffect(glowIntensity > 0.8 ? 1.08 : 1.0) // 减小缩放幅度
                    .opacity(glowIntensity > 0.8 ? 0.7 : 0.3) // 降低不透明度
                
                // 内层星光点缀 - 减少数量
                ForEach(0..<4) { i in // 减少星光点数量
                    Circle()
                        .fill(Color.white)
                        .frame(width: 2, height: 2) // 减小星光点尺寸
                        .offset(
                            x: cos(Double(i) * .pi / 2) * 40,
                            y: sin(Double(i) * .pi / 2) * 40
                        )
                        .opacity(glowIntensity > 0.9 ? 0.9 : 0.4) // 降低不透明度
                        .blur(radius: 0.5) // 减小模糊半径
                }
            }
        )
        .onTapGesture {
            // 触发点击动画
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            // 激活粒子效果
            particlesActive = true
            
            // 触发触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // 延迟重置按钮状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isPressed = false
                    
                    // 调用回调函数
                    onPress()
                }
                
                // 延迟关闭粒子效果
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    particlesActive = false
                }
            }
        }
        .accessibilityLabel("发布内容")
        .accessibilityHint("点击发布新内容，与虚拟角色互动")
        // 增强阴影效果
        .shadow(color: Color(red: 0.45, green: 0.45, blue: 0.95, opacity: 0.8), radius: 18, x: 0, y: 0)
        .shadow(color: Color.white.opacity(0.3), radius: 5, x: 0, y: 0)
        .onAppear {
            prepareHaptics()
        }
    }
    
    /**
     * 准备触觉引擎
     */
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("触觉引擎启动失败: \(error.localizedDescription)")
        }
    }
    
    /**
     * 触发高级触觉反馈
     */
    private func triggerHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }
        
        // 定义触觉模式
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        // 定义触觉事件
        let event1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )
        
        let event2 = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0.1,
            duration: 0.1
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("触觉播放失败: \(error.localizedDescription)")
        }
    }
}

/**
 * 预览提供者
 */
struct CosmicPublishButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.1).edgesIgnoringSafeArea(.all)
            
            CosmicPublishButton(isPressed: .constant(false)) {
                print("按钮被点击")
            }
        }
    }
} 