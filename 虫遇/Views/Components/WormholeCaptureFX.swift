import SwiftUI

/**
 * 虫洞捕捉特效
 * 为应用提供虫洞捕捉的视觉效果
 */
struct WormholeCaptureFX: View {
    // 动画进度绑定变量
    @Binding var animationProgress: Double
    // 是否激活绑定变量
    @Binding var isActive: Bool
    // 方向枚举
    var direction: WormholeDirection = .forward
    
    // 方向枚举定义
    enum WormholeDirection {
        case forward   // 前进
        case backward  // 后退
    }
    
    var body: some View {
        ZStack {
            // 只在激活状态下显示特效
            if isActive {
                GeometryReader { geometry in
                    ZStack {
                        // 引力场特效 - 分解复杂表达式
                        ZStack {
                            // 计算不透明度
                            let colorOpacity = min(1.0, animationProgress * 1.5)
                            // 计算颜色
                            let startColor = Color(red: 0.1, green: 0.1, blue: 0.3, opacity: colorOpacity)
                            let endColor = Color(red: 0.05, green: 0.05, blue: 0.1, opacity: colorOpacity * 0.7)
                            
                            // 计算半径
                            let startRadius = 0.0
                            let endRadius = 300.0 * animationProgress
                            
                            // 计算缩放比例
                            let scale = 0.2 + (animationProgress * 2.0)
                            
                            // 计算不透明度
                            let opacity = min(0.9, animationProgress * 1.2)
                            
                            // 引力场外环
                            RadialGradient(
                                gradient: Gradient(colors: [startColor, endColor]),
                                center: .center,
                                startRadius: startRadius,
                                endRadius: endRadius
                            )
                            .scaleEffect(scale)
                            .opacity(opacity)
                        }
                        
                        // 时间折叠特效 - 分解复杂表达式
                        ForEach(0..<5) { index in
                            let indexDouble = Double(index)
                            
                            // 计算缩放比例
                            let pulseScale = 0.1 + (animationProgress * (1.0 + indexDouble * 0.2))
                            
                            // 计算不透明度
                            let pulseOpacity = min(0.7, animationProgress) * (1.0 - (indexDouble * 0.15))
                            
                            // 外环时间折叠效果
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.6, green: 0.4, blue: 0.8, opacity: pulseOpacity),
                                            Color(red: 0.4, green: 0.2, blue: 0.6, opacity: pulseOpacity * 0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: min(geometry.size.width, geometry.size.height) * pulseScale,
                                       height: min(geometry.size.width, geometry.size.height) * pulseScale)
                                .opacity(pulseOpacity)
                        }
                        
                        // 中心能量核心 - 分解复杂表达式
                        ZStack {
                            // 计算核心尺寸
                            let coreSize = min(100.0, animationProgress * 150.0)
                            
                            // 计算中心不透明度
                            let coreOpacity = min(1.0, animationProgress * 1.5)
                            
                            // 计算核心颜色
                            let innerColor = Color(red: 0.7, green: 0.4, blue: 0.9, opacity: coreOpacity)
                            let outerColor = Color(red: 0.3, green: 0.1, blue: 0.6, opacity: coreOpacity * 0.7)
                            
                            // 计算辐射半径
                            let innerRadius = 0.0
                            let outerRadius = coreSize * 0.5
                            
                            // 能量核心
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [innerColor, outerColor]),
                                        center: .center,
                                        startRadius: innerRadius,
                                        endRadius: outerRadius
                                    )
                                )
                                .frame(width: coreSize, height: coreSize)
                                .opacity(coreOpacity)
                                .shadow(
                                    color: Color(red: 0.5, green: 0.3, blue: 0.7, opacity: 0.7),
                                    radius: 15,
                                    x: 0,
                                    y: 0
                                )
                        }
                        
                        // 粒子效果 - 分解复杂表达式
                        ForEach(0..<20, id: \.self) { index in
                            let indexDouble = Double(index)
                            let indexInt = index
                            
                            // 计算角度和位置
                            let angle = indexDouble * (2 * .pi / 20.0)
                            let distanceVariation = Double(indexInt % 3) * 0.1
                            let distanceFactor = animationProgress * (0.7 + distanceVariation)
                            let startDistance = 10.0
                            let maxDistance = min(geometry.size.width, geometry.size.height) * 0.4
                            
                            // 计算位置
                            let distance = startDistance + (distanceFactor * (maxDistance - startDistance))
                            let xPosition = geometry.size.width / 2 + cos(angle) * distance
                            let yPosition = geometry.size.height / 2 + sin(angle) * distance
                            
                            // 计算尺寸和不透明度
                            let sizeVariation = Double(indexInt % 4) * 1.0
                            let particleSize = 2.0 + sizeVariation
                            let particleOpacity = min(0.8, animationProgress) * (1.0 - distanceFactor * 0.3)
                            
                            // 粒子
                            Circle()
                                .fill(
                                    Color(
                                        red: 0.6 + Double(indexInt % 3) * 0.1,
                                        green: 0.3 + Double(indexInt % 4) * 0.05,
                                        blue: 0.9,
                                        opacity: particleOpacity
                                    )
                                )
                                .frame(width: particleSize, height: particleSize)
                                .position(x: xPosition, y: yPosition)
                                .opacity(particleOpacity)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .opacity(isActive ? 1 : 0)
    }
}

// 为了预览
struct WormholeCaptureFX_Previews: PreviewProvider {
    static var previews: some View {
        WormholeCaptureFX(
            animationProgress: .constant(0.5),
            isActive: .constant(true)
        )
    }
} 