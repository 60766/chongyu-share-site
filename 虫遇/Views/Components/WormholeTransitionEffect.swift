import SwiftUI

/**
 * 虫洞捕捉转场效果
 * 提供点击启动虫洞捕捉按钮后的视觉动效
 */
struct WormholeTransitionEffect: View {
    // 动画状态
    @Binding var isActive: Bool
    @State private var animationProgress: CGFloat = 0
    
    // 动画完成回调
    var onComplete: (() -> Void)?
    
    // 粒子系统状态
    @State private var particlePositions: [(CGPoint, CGPoint, CGFloat, Color)] = []
    @State private var wormholeScale: CGFloat = 0.1
    @State private var distortionIntensity: CGFloat = 0
    @State private var showTimeRipple: Bool = false
    @State private var showSpaceFold: Bool = false
    
    // 构造函数
    init(isActive: Binding<Bool>, onComplete: (() -> Void)? = nil) {
        self._isActive = isActive
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // 背景层 - 深紫色星空背景
            backgroundLayer
            
            // 1. 虫洞引力场效果 - 从中心向外扩散的波纹
            if isActive {
                gravityFieldEffect
            }
            
            // 2. 时间折叠效果 - 屏幕上下向中心折叠
            if showSpaceFold {
                SpaceFoldEffect(progress: animationProgress)
                    .opacity(max(0, 1 - animationProgress * 2))
            }
            
            // 3. 光速粒子流效果
            particleFlowEffect
            
            // 4. 中心虫洞效果
            wormholeEffect
            
            // 5. 时空波纹效果
            if showTimeRipple {
                TimeRippleEffect(progress: animationProgress)
                    .opacity(1.0 - animationProgress)
            }
            
            // 6. 空间扭曲效果 - 使用ZStack包裹以便应用3D变换
            if distortionIntensity > 0 {
                spaceDistortionLayer
            }
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                // 启动动画
                startAnimation()
            } else {
                // 重置动画
                resetAnimation()
            }
        }
    }
    
    // 背景层
    private var backgroundLayer: some View {
        Color(red: 0.08, green: 0.03, blue: 0.15)
            .edgesIgnoringSafeArea(.all)
            .opacity(isActive ? 1 : 0)
            .animation(.easeIn(duration: 0.2), value: isActive)
    }
    
    // 虫洞引力场效果
    private var gravityFieldEffect: some View {
        ForEach(0..<3, id: \.self) { index in
            Circle()
                .fill(createGravityFieldGradient(index: index))
                .scaleEffect(0.3 + CGFloat(index) * 0.2 + animationProgress * 0.7)
                .opacity(1.0 - animationProgress * 0.7)
        }
    }
    
    // 创建引力场渐变
    private func createGravityFieldGradient(index: Int) -> RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(red: 0.6, green: 0.4, blue: 0.8, opacity: max(0.0, 0.4 - Double(index) * 0.1)),
                Color(red: 0.5, green: 0.3, blue: 0.7, opacity: max(0.0, 0.1 - Double(index) * 0.03)),
                Color.clear
            ]),
            center: .center,
            startRadius: 5 + 20.0 * Double(index),
            endRadius: 800.0 * animationProgress
        )
    }
    
    // 粒子流效果
    private var particleFlowEffect: some View {
        ForEach(0..<particlePositions.count, id: \.self) { index in
            particleView(at: index)
        }
    }
    
    // 单个粒子视图
    private func particleView(at index: Int) -> some View {
        let (initialPos, endPos, size, color) = particlePositions[index]
        
        return ZStack {
            // 粒子主体
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            color,
                            color.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 2
                    )
                )
                .frame(width: size, height: size)
                .position(
                    x: initialPos.x + (endPos.x - initialPos.x) * animationProgress,
                    y: initialPos.y + (endPos.y - initialPos.y) * animationProgress
                )
                .opacity(max(0.0, 1 - animationProgress * 0.8))
            
            // 粒子轨迹 - 尾迹效果
            if animationProgress > 0.1 && animationProgress < 0.9 {
                particleTrailEffect(initialPos: initialPos, endPos: endPos, size: size, color: color)
            }
        }
    }
    
    // 粒子尾迹效果
    private func particleTrailEffect(initialPos: CGPoint, endPos: CGPoint, size: CGFloat, color: Color) -> some View {
        let angle = atan2(endPos.y - initialPos.y, endPos.x - initialPos.x)
        
        return Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0.7),
                        color.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(
                width: min(size * 6 * animationProgress, 15),
                height: max(size * 0.6, 1)
            )
            .rotationEffect(Angle(radians: Double(angle)))
            .position(
                x: initialPos.x + (endPos.x - initialPos.x) * animationProgress * 0.85,
                y: initialPos.y + (endPos.y - initialPos.y) * animationProgress * 0.85
            )
            .opacity(max(0.0, 0.7 - abs(animationProgress - 0.5)))
    }
    
    // 中心虫洞效果
    private var wormholeEffect: some View {
        ZStack {
            // 虫洞外圈光环
            wormholeRings
            
            // 虫洞中心黑洞
            wormholeCenter
            
            // 虫洞中心能量核心
            wormholeEnergyCore
        }
        .scaleEffect(1 + animationProgress * 0.3)
    }
    
    // 虫洞光环
    private var wormholeRings: some View {
        ForEach(0..<3, id: \.self) { index in
            Circle()
                .strokeBorder(createWormholeRingGradient(index: index), lineWidth: max(0.1, 2.0 - CGFloat(index) * 0.5))
                .frame(width: 120 + CGFloat(index) * 30, height: 120 + CGFloat(index) * 30)
                .scaleEffect(wormholeScale + CGFloat(index) * 0.1)
                .opacity(max(0.0, 1.0 - animationProgress))
        }
    }
    
    // 创建虫洞光环渐变
    private func createWormholeRingGradient(index: Int) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.6, green: 0.4, blue: 0.8, opacity: max(0.0, 0.8 - Double(index) * 0.2)),
                Color(red: 0.8, green: 0.7, blue: 0.9, opacity: max(0.0, 0.6 - Double(index) * 0.2)),
                Color(red: 0.6, green: 0.4, blue: 0.8, opacity: max(0.0, 0.4 - Double(index) * 0.1))
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 虫洞中心
    private var wormholeCenter: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.7),
                        Color(red: 0.15, green: 0.10, blue: 0.25).opacity(0.5),
                        Color.black.opacity(0.9)
                    ]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 60
                )
            )
            .frame(width: 100, height: 100)
            .scaleEffect(wormholeScale)
            .opacity(max(0.0, 1.0 - animationProgress))
    }
    
    // 虫洞能量核心
    private var wormholeEnergyCore: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.9, green: 0.8, blue: 0.2, opacity: 0.9), // 黄色能量核心
                        Color(red: 0.9, green: 0.5, blue: 0.1, opacity: 0.5),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 30
                )
            )
            .frame(width: 40, height: 40)
            .scaleEffect(wormholeScale * (0.8 + 0.2 * sin(animationProgress * 10)))
            .blur(radius: 2)
            .opacity(max(0.0, 1.0 - animationProgress))
    }
    
    // 空间扭曲效果层
    private var spaceDistortionLayer: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(SpaceDistortionEffect(intensity: distortionIntensity))
    }
    
    // 启动动画
    private func startAnimation() {
        // 重置状态
        resetAnimation()
        
        // 生成随机粒子
        generateParticles()
        
        // 启动动画序列
        withAnimation(.easeIn(duration: 0.3)) {
            wormholeScale = 1.0
        }
        
        // 阶段1: 开始扭曲
        withAnimation(.easeInOut(duration: 0.3)) {
            distortionIntensity = 0.5
        }
        
        // 阶段2: 显示时间波纹
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.2)) {
                showTimeRipple = true
            }
        }
        
        // 阶段3: 加强空间扭曲
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                distortionIntensity = 1.0
            }
        }
        
        // 阶段4: 空间折叠效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.2)) {
                showSpaceFold = true
            }
        }
        
        // 主动画进度
        withAnimation(.easeInOut(duration: 1.0)) {
            animationProgress = 1.0
        }
        
        // 阶段5: 完成动画并调用回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete?()
        }
    }
    
    // 重置动画状态
    private func resetAnimation() {
        animationProgress = 0
        wormholeScale = 0.1
        distortionIntensity = 0
        showTimeRipple = false
        showSpaceFold = false
        particlePositions = []
    }
    
    // 生成粒子系统
    private func generateParticles() {
        // 清空现有粒子
        particlePositions = []
        
        // 屏幕中心
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        // 生成100个粒子
        for _ in 0..<100 {
            // 初始位置 - 靠近中心
            let initialRadius = CGFloat.random(in: 20...70)
            let initialAngle = CGFloat.random(in: 0...(2 * .pi))
            let initialX = centerX + initialRadius * cos(initialAngle)
            let initialY = centerY + initialRadius * sin(initialAngle)
            
            // 终点位置 - 向屏幕边缘飞出
            let endRadius = CGFloat.random(in: UIScreen.main.bounds.width...UIScreen.main.bounds.width * 1.5)
            let endX = centerX + endRadius * cos(initialAngle)
            let endY = centerY + endRadius * sin(initialAngle)
            
            // 粒子大小
            let size = CGFloat.random(in: 1.5...5)
            
            // 粒子颜色 - 以紫色为主
            let color: Color
            let colorChoice = Int.random(in: 0...10)
            if colorChoice < 7 {
                // 70% 几率是紫色系
                color = Color(
                    red: Double.random(in: 0.5...0.7),
                    green: Double.random(in: 0.3...0.5),
                    blue: Double.random(in: 0.7...0.9),
                    opacity: Double.random(in: 0.7...1.0)
                )
            } else if colorChoice < 9 {
                // 20% 几率是蓝白色系
                color = Color(
                    red: Double.random(in: 0.7...0.9),
                    green: Double.random(in: 0.7...0.9),
                    blue: Double.random(in: 0.9...1.0),
                    opacity: Double.random(in: 0.7...1.0)
                )
            } else {
                // 10% 几率是金黄色系
                color = Color(
                    red: Double.random(in: 0.8...1.0),
                    green: Double.random(in: 0.7...0.9),
                    blue: Double.random(in: 0.1...0.3),
                    opacity: Double.random(in: 0.7...1.0)
                )
            }
            
            // 添加到粒子系统
            particlePositions.append((
                CGPoint(x: initialX, y: initialY),
                CGPoint(x: endX, y: endY),
                size,
                color
            ))
        }
    }
}

/**
 * 空间扭曲效果修饰符
 */
struct SpaceDistortionEffect: ViewModifier {
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(intensity * 3), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(intensity * -2), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(intensity * 1), axis: (x: 0, y: 0, z: 1))
            .blur(radius: intensity * 2)
    }
}

/**
 * 时间波纹效果
 */
struct TimeRippleEffect: View {
    let progress: CGFloat
    @State private var animateRings: Bool = false
    
    var body: some View {
        ZStack {
            // 创建3个波纹圆环
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        Color(red: 0.6, green: 0.4, blue: 0.8, opacity: max(0.0, 0.5 - Double(index) * 0.15)),
                        lineWidth: max(0.1, 1.5 - CGFloat(index) * 0.3)
                    )
                    .scaleEffect(animateRings ? 1 + CGFloat(index) * 0.25 : 0.2)
                    .opacity(animateRings ? 0 : 0.6)
                    .animation(
                        Animation.easeOut(duration: 0.8)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                        value: animateRings
                    )
            }
        }
        .onAppear {
            // 延迟启动波纹动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateRings = true
            }
        }
    }
}

/**
 * 空间折叠效果
 */
struct SpaceFoldEffect: View {
    let progress: CGFloat
    
    var body: some View {
        ZStack {
            // 上半部分向下折叠
            Rectangle()
                .fill(Material.ultraThinMaterial)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2)
                .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/4)
                .offset(y: progress * UIScreen.main.bounds.height/4)
            
            // 下半部分向上折叠
            Rectangle()
                .fill(Material.ultraThinMaterial)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2)
                .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height*3/4)
                .offset(y: -progress * UIScreen.main.bounds.height/4)
        }
        .opacity(0.3)
        .blur(radius: 3)
    }
}

#Preview {
    WormholeTransitionEffect(isActive: .constant(true))
} 