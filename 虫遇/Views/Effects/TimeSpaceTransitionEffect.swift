import SwiftUI
// 修改导入方式以直接引用SwipeDirection
// 直接在文件中定义SwipeDirection

/**
 * 滑动方向枚举
 * 控制转场过渡的方向
 */
public enum SwipeDirection {
    case left
    case right
    case none
}

/**
 * 时空粒子效果视图
 * 在页面转换过程中显示，增强穿越时空的主题感
 */
public struct TimeSpaceParticleView: View {
    @State private var phase: CGFloat = 0
    public let direction: SwipeDirection
    
    // 添加公共初始化方法
    public init(direction: SwipeDirection) {
        self.direction = direction
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景层 - 使用协调的色彩
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.92, green: 0.94, blue: 0.98, opacity: 0.85),  // 淡蓝白色
                        Color(red: 0.94, green: 0.92, blue: 0.97, opacity: 0.85)   // 淡紫白色
                    ]),
                    startPoint: direction == .left ? .trailing : .leading,
                    endPoint: direction == .left ? .leading : .trailing
                )
                
                // 粒子层
                ForEach(0..<45, id: \.self) { index in
                    Circle()
                        .fill(Color(red: 0.6, green: 0.7, blue: 0.95, opacity: Double.random(in: 0.3...0.6)))
                        .frame(width: CGFloat.random(in: 3...10))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(x: offsetForIndex(index, width: geometry.size.width))
                        .animation(
                            Animation.linear(duration: Double.random(in: 0.4...0.8))
                                .repeatForever(autoreverses: false),
                            value: phase
                        )
                }
                
                // 光线效果
                ForEach(0..<15, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear, 
                                    Color(red: 0.65, green: 0.7, blue: 0.95, opacity: 0.45), 
                                    .clear
                                ]),
                                startPoint: direction == .left ? .trailing : .leading,
                                endPoint: direction == .left ? .leading : .trailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 100...350), height: CGFloat.random(in: 1.5...3))
                        .rotationEffect(.degrees(Double.random(in: -15...15)))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(x: offsetForIndex(index + 40, width: geometry.size.width) * 1.5)
                        .animation(
                            Animation.linear(duration: Double.random(in: 0.5...0.9))
                                .repeatForever(autoreverses: false),
                            value: phase
                        )
                }
                
                // 方向指示箭头
                Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color(red: 0.55, green: 0.65, blue: 0.95, opacity: 0.8))
                    .offset(x: direction == .left ? -30 : 30)
                    .opacity(phase == 1.0 ? 0.9 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: phase
                    )
            }
            .onAppear {
                // 使用异步调用避免在视图更新过程中修改状态
                DispatchQueue.main.async {
                    self.phase = 1.0
                }
            }
            .drawingGroup() // 使用离屏渲染提高性能
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // 根据方向计算偏移量
    private func offsetForIndex(_ index: Int, width: CGFloat) -> CGFloat {
        let baseOffset = direction == .left ? width * 2 : -width * 2
        return phase * baseOffset
    }
}

/**
 * 时空波纹效果视图
 * 作为备选效果，模拟穿越时空时的空间波纹
 */
public struct TimeSpaceRippleView: View {
    @State private var animating = false
    public let direction: SwipeDirection
    
    // 添加公共初始化方法
    public init(direction: SwipeDirection) {
        self.direction = direction
    }
    
    public var body: some View {
        ZStack {
            // 背景层
            Color(red: 0.93, green: 0.95, blue: 0.98, opacity: 0.9)
                .edgesIgnoringSafeArea(.all)
            
            // 波纹效果
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(Color(red: 0.6, green: 0.7, blue: 0.95, opacity: 0.3 - Double(index) * 0.04), lineWidth: 2.5)
                    .scaleEffect(animating ? 1 + CGFloat(index) * 0.25 : 0.2)
                    .opacity(animating ? 0 : 0.7)
                    .animation(
                        Animation.easeOut(duration: 0.8)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
            
            // 中心光效
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.65, green: 0.75, blue: 0.95, opacity: 0.7), 
                            .clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 100, height: 100)
                .opacity(animating ? 0.6 : 0.3)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: animating
                )
            
            // 方向指示
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(Color(red: 0.55, green: 0.65, blue: 0.9, opacity: 0.8))
                .offset(x: direction == .left ? -30 : 30)
                .opacity(animating ? 0.9 : 0.6)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true),
                    value: animating
                )
        }
        .onAppear {
            // 使用异步调用避免在视图更新过程中修改状态
            DispatchQueue.main.async {
                self.animating = true
            }
        }
        .drawingGroup() // 使用离屏渲染提高性能
    }
}

/**
 * 虫洞过渡视图
 * 提供一个完整的四阶段过渡动画
 */
public struct WormholeTransitionView: View {
    @Binding var isActive: Bool
    
    // 动画阶段状态
    @State private var phase1: Bool = false  // 虫洞形成
    @State private var phase2: Bool = false  // 虫洞隧道
    @State private var phase3: Bool = false  // 虫洞爆发
    @State private var phase4: Bool = false  // 回到主页面
    
    // 粒子控制
    @State private var particleScale: CGFloat = 0.1
    @State private var particleOpacity: Double = 0
    @State private var particleBlur: CGFloat = 10
    
    // 波纹控制
    @State private var ringScale: CGFloat = 0.2
    @State private var ringOpacity: Double = 0
    
    // 光束控制
    @State private var beamScale: CGFloat = 0
    @State private var beamOpacity: Double = 0
    
    // 闪光控制
    @State private var flashOpacity: Double = 0
    
    public var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .opacity(phase1 ? 1.0 : 0)
                .animation(.easeIn(duration: 0.3), value: phase1)
            
            // 阶段1：虫洞形成（0-1.0秒）
            ZStack {
                // 能量波纹
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.7),
                                    Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.9),
                                    Color(red: 0.6, green: 0.4, blue: 1.0).opacity(1.0),
                                    Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.9),
                                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.7)
                                ]),
                                center: .center
                            ),
                            lineWidth: 2 - CGFloat(i) * 0.5
                        )
                        .scaleEffect(ringScale + CGFloat(i) * 0.2)
                        .opacity(ringOpacity * (1.0 - Double(i) * 0.2))
                }
                
                // 中心波纹
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.8),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(phase1 ? 1.0 : 0.5)
                    .opacity(phase1 ? 0.7 : 0)
                    .blur(radius: phase1 ? 5 : 15)
            }
            .opacity(phase2 ? 0 : 1) // 在阶段2开始时淡出
            
            // 阶段2：虫洞隧道（1.0-3.0秒）
            ZStack {
                // 虫洞隧道 - 射线效果
                ForEach(0..<30) { _ in
                    let length = CGFloat.random(in: 50...200)
                    let angle = Double.random(in: 0...360)
                    let delay = Double.random(in: 0...0.3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.9),
                                    Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.7),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: length, height: 1.5)
                        .rotationEffect(.degrees(angle))
                        .offset(x: phase2 ? length * 0.5 : 0)
                        .opacity(phase2 ? Double.random(in: 0.5...0.9) : 0)
                        .animation(.easeOut(duration: 0.8).delay(delay), value: phase2)
                }
                
                // 中心隧道光束
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color(red: 0.7, green: 0.5, blue: 1.0).opacity(0.7),
                                Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.5),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(phase2 ? 1.2 : 0.2)
                    .opacity(phase2 ? 0.8 : 0)
                    .blur(radius: 5)
                
                // 星际粒子
                ForEach(0..<100) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(phase2 ? Double.random(in: 0.3...0.9) : 0)
                        .blur(radius: CGFloat.random(in: 0...0.5))
                }
            }
            .opacity(phase3 ? 0 : (phase2 ? 1 : 0)) // 在阶段2激活时显示，阶段3开始时淡出
            
            // 阶段3：虫洞爆发（3.0-4.0秒）
            ZStack {
                // 闪光效果
                Color.white
                    .opacity(flashOpacity)
                    .edgesIgnoringSafeArea(.all)
                
                // 爆发光环
                ForEach(0..<4) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color(red: 0.7, green: 0.5, blue: 1.0).opacity(0.8),
                                    Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.6)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3 - CGFloat(i) * 0.5
                        )
                        .scaleEffect(phase3 ? 1.5 + CGFloat(i) * 0.3 : 0.2)
                        .opacity(phase3 ? 0.9 - Double(i) * 0.2 : 0)
                        .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.1), value: phase3)
                }
                
                // 辐射粒子
                ForEach(0..<20) { _ in
                    let size = CGFloat.random(in: 3...8)
                    let distance = CGFloat.random(in: 50...200)
                    let angle = Double.random(in: 0...360)
                    let xOffset = cos(angle * .pi / 180) * distance
                    let yOffset = sin(angle * .pi / 180) * distance
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: size, height: size)
                        .offset(x: phase3 ? CGFloat(xOffset) : 0, y: phase3 ? CGFloat(yOffset) : 0)
                        .opacity(phase3 ? Double.random(in: 0.7...1.0) : 0)
                        .blur(radius: 1)
                        .animation(.easeOut(duration: 0.8), value: phase3)
                }
            }
            .opacity(phase4 ? 0 : (phase3 ? 1 : 0)) // 在阶段3激活时显示，阶段4开始时淡出
            
            // 阶段4：溶解回主页面（4.0-5.0秒）
            Color.black
                .opacity(phase4 ? 0 : (phase3 ? 0.8 : 0))
                .animation(.easeOut(duration: 0.8), value: phase4)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // 执行虫洞动画序列
            startWormholeAnimation()
        }
    }
    
    // 启动虫洞动画序列
    private func startWormholeAnimation() {
        // 触发触觉反馈
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
        impactHeavy.impactOccurred()
        
        // 记录动画开始时间
        let startTime = Date()
        #if DEBUG
        debugLog("⭐️ 虫洞动画开始: \(startTime)")
        #endif
        
        // 阶段1：虫洞形成（0-1.0秒）
        withAnimation(.easeInOut(duration: 0.6)) {
            phase1 = true
            ringScale = 1.0
            ringOpacity = 0.9
        }
        
        // 阶段2：虫洞隧道（1.0-3.0秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 触发触觉反馈
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            
            #if DEBUG
            debugLog("⭐️ 虫洞动画阶段2开始: +1.0秒")
            #endif
            
            withAnimation(.easeInOut(duration: 0.6)) {
                phase2 = true
            }
        }
        
        // 阶段3：虫洞爆发（3.0-4.0秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // 触发触觉反馈
            let impactMed = UIImpactFeedbackGenerator(style: .rigid)
            impactMed.impactOccurred()
            
            #if DEBUG
            debugLog("⭐️ 虫洞动画阶段3开始: +3.0秒")
            #endif
            
            withAnimation(.easeOut(duration: 0.2)) {
                phase3 = true
                flashOpacity = 0.9
            }
            
            // 闪光快速消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.6)) {
                    flashOpacity = 0
                }
            }
        }
        
        // 阶段4：溶解回主页面（4.0-5.0秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            #if DEBUG
            debugLog("⭐️ 虫洞动画阶段4开始: +4.0秒")
            #endif
            
            withAnimation(.easeOut(duration: 0.8)) {
                phase4 = true
            }
        }
        
        // 结束动画并关闭视图
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            #if DEBUG
            debugLog("⭐️ 虫洞动画阶段已全部完成: \(endTime), 总持续时间: \(duration)秒")
            #endif
            
            // 增加短暂延迟后再关闭视图，确保动画能够完全展示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                #if DEBUG
                debugLog("⭐️ 现在关闭虫洞视图")
                #endif
                isActive = false
                
                // 重置所有状态以便下次使用
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    phase1 = false
                    phase2 = false
                    phase3 = false
                    phase4 = false
                    ringScale = 0.2
                    ringOpacity = 0
                    flashOpacity = 0
                }
            }
        }
    }
    
    public init(isActive: Binding<Bool>) {
        self._isActive = isActive
    }
}

/**
 * 主控制视图
 * 用于在点击按钮后触发时空穿越效果
 */
struct TimeSpaceTransitionDemo: View {
    @State private var showingTransition = false
    @State private var buttonPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.8)
    @State private var transitionDirection: SwipeDirection = .right
    
    var body: some View {
        ZStack {
            // 背景 - 深紫到黑色的渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.03, blue: 0.15), // 深紫色
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // 星空背景
            ZStack {
                // 微妙的星星
                ForEach(0..<100) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.5)))
                        .frame(width: CGFloat.random(in: 1...2.5), height: CGFloat.random(in: 1...2.5))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                }
                
                // 彩色微弱星星
                ForEach(0..<25) { _ in
                    Circle()
                        .fill(Color(
                            red: Double.random(in: 0.5...0.8),
                            green: Double.random(in: 0.5...0.8),
                            blue: Double.random(in: 0.8...1.0)
                        ).opacity(Double.random(in: 0.1...0.3)))
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                }
            }
            
            VStack {
                Text("虫洞探索")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Spacer()
                
                // 启动虫洞捕捉按钮
                Button(action: {
                    // 获取按钮位置 - 使用更新的API
                    // 直接设置按钮在屏幕中心的位置，不再依赖windows API
                    buttonPosition = CGPoint(
                        x: UIScreen.main.bounds.width / 2,
                        y: UIScreen.main.bounds.height * 0.8
                    )
                    
                    // 触发触觉反馈
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                    
                    // 显示转场效果
                    showingTransition = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("启动虫洞捕捉")
                            .font(.system(size: 18, weight: .semibold))
                            .kerning(0.3)
                    }
                    .foregroundColor(.black)
                    .frame(height: 56)
                    .frame(width: UIScreen.main.bounds.width * 0.6)
                    .background(
                        ZStack {
                            // 主渐变背景
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color(red: 0.96, green: 0.96, blue: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // 添加轻微的内部光晕效果
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color.clear
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 150
                            )
                            .opacity(0.4)
                        }
                    )
                    .cornerRadius(28)
                    .shadow(
                        color: Color(red: 0.58, green: 0.44, blue: 0.86, opacity: 0.4),
                        radius: 12,
                        x: 0,
                        y: 2
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                }
                .padding(.bottom, 40)
            }
            
            // 时空穿越效果覆盖层
            if showingTransition {
                WormholeTransitionView(
                    isActive: $showingTransition
                )
                .zIndex(100)
            }
        }
    }
}

// 预览
struct TimeSpaceTransitionEffect_Previews: PreviewProvider {
    static var previews: some View {
        TimeSpaceTransitionDemo()
    }
} 