import SwiftUI

/**
 * 虫洞过渡特效组件
 * 提供在页面过渡时的虫洞特效动画
 */
struct WormholeTransitionEffect: View {
    // 控制动画进度的绑定变量
    @Binding var progress: Double
    // 是否显示特效
    @Binding var isActive: Bool
    // 方向 - 进入或退出
    var direction: TransitionDirection = .enter
    
    // 转场方向枚举
    enum TransitionDirection {
        case enter   // 进入
        case exit    // 退出
    }
    
    // 屏幕尺寸
    @State private var screenSize: CGSize = UIScreen.main.bounds.size
    // 粒子系统
    @State private var particles: [TransitionParticle] = []
    
    // 波纹层级数量
    private let rippleCount = 3
    // 粒子数量
    private let particleCount = 80
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景层 - 随着进度变化透明度
                let backgroundOpacity = direction == .enter ? 
                    Double(min(0.7, progress * 1.2)) : 
                    Double(min(0.7, (1.0 - progress) * 1.2))
                
                Color.black
                    .opacity(backgroundOpacity)
                    .edgesIgnoringSafeArea(.all)
                
                // 波纹效果层
                ForEach(0..<rippleCount, id: \.self) { index in
                    let indexDouble = Double(index)
                    // 计算当前波纹的放大比例
                    let currentScale: CGFloat = {
                        if direction == .enter {
                            // 进入时，从小到大
                            return CGFloat(progress * (1.0 + indexDouble * 0.15))
                        } else {
                            // 退出时，从大到小
                            let reverseProgress = 1.0 - progress
                            return CGFloat(reverseProgress * (1.0 + indexDouble * 0.15))
                        }
                    }()
                    
                    // 计算不透明度
                    let baseOpacity = 0.7 - (indexDouble * 0.2)
                    let fadeOpacity: Double = {
                        if direction == .enter {
                            // 进入时，逐渐显示
                            return min(1.0, progress * 2.0) * baseOpacity
                        } else {
                            // 退出时，逐渐消失
                            return min(1.0, (1.0 - progress) * 2.0) * baseOpacity
                        }
                    }()
                    
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.8).opacity(fadeOpacity),
                                    Color(red: 0.5, green: 0.3, blue: 0.7).opacity(fadeOpacity * 0.6),
                                    Color(red: 0.4, green: 0.2, blue: 0.6).opacity(fadeOpacity * 0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0 + (indexDouble * 0.2)
                        )
                        .frame(
                            width: min(geometry.size.width, geometry.size.height) * 0.8 * currentScale,
                            height: min(geometry.size.width, geometry.size.height) * 0.8 * currentScale
                        )
                        .blur(radius: 0.5 + (indexDouble * 0.5))
                }
                
                // 粒子效果层
                ForEach(particles) { particle in
                    // 计算粒子位置
                    let particleProgress: Double = {
                        if direction == .enter {
                            return progress
                        } else {
                            return 1.0 - progress
                        }
                    }()
                    
                    // 根据方向设置起始和结束位置
                    let startX = particle.startPosition.x
                    let startY = particle.startPosition.y
                    let endX = particle.endPosition.x
                    let endY = particle.endPosition.y
                    
                    // 计算当前位置
                    let currentX = startX + (endX - startX) * particleProgress
                    let currentY = startY + (endY - startY) * particleProgress
                    
                    // 粒子不透明度
                    let maxOpacity = particle.baseOpacity
                    let currentOpacity = direction == .enter ?
                        min(maxOpacity, progress * 1.5) :
                        min(maxOpacity, (1.0 - progress) * 1.5)
                    
                    Circle()
                        .fill(particle.color.opacity(currentOpacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: currentX, y: currentY)
                        .blur(radius: particle.size * 0.3)
                }
                
                // 中心虫洞效果
                let centerSize: CGFloat = {
                    if direction == .enter {
                        return 100.0 * CGFloat(progress)
                    } else {
                        return 100.0 * CGFloat(1.0 - progress)
                    }
                }()
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.1, blue: 0.3),
                                Color.black
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: centerSize * 0.5
                        )
                    )
                    .frame(width: centerSize, height: centerSize)
                    .shadow(
                        color: Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.5),
                        radius: 10,
                        x: 0,
                        y: 0
                    )
            }
            .onChange(of: geometry.size) { newSize in
                screenSize = newSize
                if particles.isEmpty {
                    generateParticles(in: geometry)
                }
            }
            .onAppear {
                screenSize = geometry.size
                generateParticles(in: geometry)
            }
        }
        .ignoresSafeArea()
        .opacity(isActive ? 1 : 0)
    }
    
    // 生成粒子
    private func generateParticles(in geometry: GeometryProxy) {
        particles = []
        
        // 中心点
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        // 外围圆环半径
        let radius = min(geometry.size.width, geometry.size.height) * 0.4
        
        // 生成粒子
        for _ in 0..<particleCount {
            // 生成随机角度
            let angle = Double.random(in: 0..<(2 * .pi))
            
            // 计算外围起始/结束点
            let outerRadius = radius * Double.random(in: 0.8...1.2)
            
            // 计算粒子起始和结束位置
            let startX: CGFloat
            let startY: CGFloat
            let endX: CGFloat
            let endY: CGFloat
            
            if direction == .enter {
                // 入场：从外部到中心
                startX = centerX + cos(angle) * outerRadius
                startY = centerY + sin(angle) * outerRadius
                endX = centerX
                endY = centerY
            } else {
                // 出场：从中心到外部
                startX = centerX
                startY = centerY
                endX = centerX + cos(angle) * outerRadius
                endY = centerY + sin(angle) * outerRadius
            }
            
            // 随机粒子大小
            let size = CGFloat.random(in: 1.5...4.0)
            
            // 随机粒子基础不透明度
            let baseOpacity = Double.random(in: 0.3...0.8)
            
            // 随机粒子颜色 - 紫色系
            let color = Color(
                red: Double.random(in: 0.4...0.6),
                green: Double.random(in: 0.2...0.4),
                blue: Double.random(in: 0.7...0.9)
            )
            
            // 创建粒子并添加到数组
            particles.append(
                TransitionParticle(
                    id: UUID(),
                    startPosition: CGPoint(x: startX, y: startY),
                    endPosition: CGPoint(x: endX, y: endY),
                    color: color,
                    size: size,
                    baseOpacity: baseOpacity
                )
            )
        }
    }
}

// 过渡特效中使用的粒子模型
struct TransitionParticle: Identifiable {
    let id: UUID
    let startPosition: CGPoint
    let endPosition: CGPoint
    let color: Color
    let size: CGFloat
    let baseOpacity: Double
}

// 为了预览
struct WormholeTransitionEffect_Previews: PreviewProvider {
    static var previews: some View {
        WormholeTransitionEffect(
            progress: .constant(0.5),
            isActive: .constant(true)
        )
    }
} 