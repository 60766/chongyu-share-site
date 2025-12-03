import SwiftUI
import Combine
import Darwin

/**
 * 增强版时空特效视图
 * 提供高级的虫洞穿越动画效果，遵循物理现实感和Apple的设计语言
 * 包含四个主要阶段：形成、隧道、爆发和溶解
 */
struct TimeSpaceEffectView: View {
    // 获取CreationTypeManager
    @ObservedObject private var creationTypeManager = CreationTypeManager.shared
    
    // 绑定状态，用于控制特效的开始和结束
    @Binding var isActive: Bool
    
    // 动画完成时的回调
    var onComplete: (() -> Void)?
    
    // 特效中心点位置，可自定义或使用默认屏幕中心
    var centerPosition: CGPoint?
    
    // 状态变量控制动画效果
    @State private var animationProgress: Double = 0
    @State private var ringScale: CGFloat = 0.2
    @State private var ringOpacity: Double = 0
    @State private var particlesOpacity: Double = 0
    @State private var tunnelScale: CGFloat = 0.1
    @State private var tunnelRotation: Double = 0
    @State private var tunnelDepth: Double = 0
    @State private var starScale: CGFloat = 1.0
    @State private var starOpacity: Double = 0
    @State private var centerPulse: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var rayOpacity: Double = 0
    @State private var rayScale: Double = 0.1
    @State private var finalGlowScale: CGFloat = 1.0
    @State private var finalGlowOpacity: Double = 0
    @State private var backgroundBlur: Double = 0
    @State private var perspectiveOffset: CGSize = .zero
    @State private var colorTransition: Double = 0
    @State private var tunnelSpeed: Double = 1.0
    @State private var particleSystemActive: Bool = false
    @State private var wormholeIntensity: Double = 0
    
    // 状态变量控制探索提示的显示
    @State private var showExplorationPrompt = false
    @State private var explorationPromptOpacity: Double = 0
    @State private var currentExplorationStage: ExplorationStage = .exploring
    
    // 探索阶段枚举 - 根据不同分类显示不同文字
    enum ExplorationStage: String, CaseIterable {
        case exploring = "探索中"
        
        var description: String {
            // 获取当前选中的分类索引
            let selectedIndex = CreationTypeManager.shared.selectedIndex
            
            // 根据分类索引返回不同的文字提示
            switch selectedIndex {
            case 0: // 随机漫游
                return "虫洞随机跳跃"
            case 1: // 日常心情
                return "感知情绪波动"
            case 2: // 古潮新语
                return "连接古今桥梁"
            case 3: // 穿越吐槽
                return "时空碰撞共鸣"
            case 4: // 时空记事
                return "历史画面重构"
            default:
                return "探索中"
            }
        }
    }
    
    // 颜色系统 - 从冷色到暖色的渐变过渡
    private var gradientColors: [Color] {
        [
            colorOne,   // 深蓝色起始
            colorTwo,   // 深紫色
            colorThree, // 亮紫色
            colorFour   // 向暖色过渡
        ]
    }
    
    // 分解后的颜色计算属性
    private var colorOne: Color {
        Color(red: 0.2, green: 0.3, blue: 0.55).opacity(0.8 - 0.3 * colorTransition)
    }
    
    private var colorTwo: Color {
        Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.8 + 0.1 * colorTransition)
    }
    
    private var colorThree: Color {
        Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.9)
    }
    
    private var colorFour: Color {
        let red = 0.7 + 0.2 * colorTransition
        let green = 0.5 + 0.3 * colorTransition
        let blue = 0.9 - 0.2 * colorTransition
        let opacity = 0.8 + 0.2 * colorTransition
        
        return Color(red: red, green: green, blue: blue).opacity(opacity)
    }
    
    var body: some View {
        GeometryReader { geometry in
            // 计算中心位置 - 使用提供的中心点或默认为屏幕中心
            let center = centerPosition ?? CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            
            // 强制使用传入的中心点位置，不要使用默认值
            let actualCenter = centerPosition ?? center
            
            ZStack {
                // 黑色背景层 - 改为半透明
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                // =============== 阶段1: 虫洞形成 (0-0.6秒) ===============
                ZStack {
                    // 添加视觉景深模糊效果 - 模拟真实的大气散射，降低不透明度
                    GaussianBlur(radius: backgroundBlur * 30)
                        .opacity(min(0.7, animationProgress * 3 * 0.7))
                        .edgesIgnoringSafeArea(.all)
                    
                    // 中心爆发光点 - 更精细的渐变
                    centerExplosionLight(center: actualCenter)
                    
                    // 扩散环 - 多层次同心圆扩散带有Z轴运动感
                    ForEach(0..<5, id: \.self) { index in
                        diffusionRing(index: index, center: actualCenter, screenWidth: geometry.size.width)
                    }
                    
                    // 初始星星 - 随机大小和亮度，增加深度感
                    ForEach(0..<80, id: \.self) { _ in
                        let size = CGFloat.random(in: 1...3.5)
                        let opacity = Double.random(in: 0.3...0.8)
                        let x = CGFloat.random(in: 0...geometry.size.width)
                        let y = CGFloat.random(in: 0...geometry.size.height)
                        
                        // 计算到中心的距离，影响视差效果
                        let distanceX = x - actualCenter.x
                        let distanceY = y - actualCenter.y
                        let distance = sqrt(distanceX * distanceX + distanceY * distanceY)
                        let parallaxFactor = max(0.4, min(1.0, distance / (geometry.size.width / 2))) * 0.15
                        
                        initialStar(
                            size: size, 
                            baseOpacity: opacity, 
                            position: CGPoint(x: x, y: y), 
                            parallaxFactor: parallaxFactor
                        )
                    }
                }
                
                // =============== 阶段2: 虫洞隧道 (0.6-1.3秒) ===============
                ZStack {
                    // 隧道层 - 更复杂的Z轴效果
                    ForEach(0..<10, id: \.self) { index in
                        // 使用更小的内圈，创建明显的隧道深度错觉
                        let scaleFactor = max(0.05, tunnelScale - (tunnelDepth * Double(index) / 10))
                        let rotationFactor = tunnelRotation * (1.0 - Double(index) * 0.08) // 不同层的旋转速度不同
                        
                        tunnelLayer(index: index, center: actualCenter, screenWidth: geometry.size.width, scaleFactor: scaleFactor, rotationFactor: rotationFactor)
                    }
                    
                    // 隧道星光粒子 - 动态移动创造穿越感
                    ForEach(0..<50, id: \.self) { index in
                        let size = CGFloat.random(in: 1.5...3.5)
                        let speed = Double.random(in: 0.7...1.3) * tunnelSpeed
                        let delay = Double.random(in: 0...0.2)
                        
                        // 粒子动态位置计算 - 根据动画进度移动，创建穿越感
                        let baseProgress = max(0, min(1, (animationProgress - 0.6 - delay) * speed))
                        let radialPosition = baseProgress * 0.9 // 控制粒子起始位置到结束位置的径向距离比例
                        let angle = Double.random(in: 0...2*Double.pi)
                        
                        tunnelStarParticle(
                            center: actualCenter, 
                            size: size, 
                            radialPosition: radialPosition, 
                            angle: angle, 
                            screenSize: geometry.size
                        )
                    }
                    
                    // 隧道中心光芒 - 动态脉动创造能量汇聚感
                    tunnelCenterBeam(center: actualCenter)
                }
                
                // =============== 阶段3: 虫洞爆发动画 (1.7-2.2秒) ===============
                ZStack {
                    // 爆发闪光 - 更加柔和的过渡
                    Color.white
                        .opacity(flashOpacity)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 5 * (1.0 - flashOpacity)) // 越亮越锐利
                    
                    // 移除放射光线效果
                    // ForEach(0..<24, id: \.self) { index in
                    //     let angle = Double(index) * (360.0 / 24.0)
                    //     let length = geometry.size.width * rayScale
                    //     
                    //     radiatingRay(
                    //         index: index, 
                    //         center: actualCenter, 
                    //         angle: angle, 
                    //         length: length
                    //     )
                    // }
                }
                
                // =============== 阶段4: 溶解返回 (2.2-2.6秒) ===============
                ZStack {
                    // 逐渐显示背景色但不使用白色过渡效果 - 使用半透明黑色代替
                    Color.black
                        .opacity(max(0, 0.3 - getFinalBackgroundOpacity(progress: animationProgress) * 0.3))
                        .blur(radius: getFinalBackgroundBlur(progress: animationProgress))
                        .edgesIgnoringSafeArea(.all)
                    
                    // 最终粒子效果 - 优雅的小星星缓缓消失，但不使用白色
                    ForEach(0..<40, id: \.self) { _ in
                        let size = CGFloat.random(in: 1.5...3.0)
                        let x = CGFloat.random(in: 0...geometry.size.width)
                        let y = CGFloat.random(in: 0...geometry.size.height)
                        
                        // 距离中心的距离，影响消失速度
                        let distanceX = x - actualCenter.x
                        let distanceY = y - actualCenter.y
                        let distance = sqrt(distanceX * distanceX + distanceY * distanceY)
                        let maxDistance = sqrt(geometry.size.width * geometry.size.width + 
                                              geometry.size.height * geometry.size.height) / 2
                        let normalizedDistance = distance / maxDistance
                        
                        // 距离中心越远，消失越快
                        let disappearRate = 1.0 + normalizedDistance * 2
                        
                        finalParticle(
                            size: size, 
                            position: CGPoint(x: x, y: y), 
                            disappearRate: disappearRate
                        )
                    }
                }
                
                // =============== 探索状态提示视图 ===============
                if showExplorationPrompt {
                    ExplorationStatusView(stage: currentExplorationStage)
                        .opacity(explorationPromptOpacity)
                        .animation(.easeInOut(duration: 0.3), value: explorationPromptOpacity)
                        .position(actualCenter)
                }
            }
            .onChange(of: isActive) { _, newValue in
                // 当特效被激活时启动动画
                if newValue {
                    startAnimation()
                }
            }
            .onAppear {
                // 如果初始状态是激活的，则启动动画
                if isActive {
                    startAnimation()
                }
            }
        }
    }
    
    // 统一控制所有动画
    private func startAnimation() {
        // 重置所有状态
        resetAnimationState()
        
        // 播放初始触觉反馈
        let initialFeedback = UIImpactFeedbackGenerator(style: .medium)
        initialFeedback.impactOccurred()
        
        // 显示探索状态提示 - 简化为只显示"探索中"
        showExplorationPrompt = true
        withAnimation(.easeInOut(duration: 0.5)) {
            explorationPromptOpacity = 1.0
            currentExplorationStage = .exploring
        }
        
        // 主动画进度控制 - 整体时长2.6秒
        withAnimation(.easeInOut(duration: 2.6)) {
            animationProgress = 2.0
        }
        
        // =============== 阶段1: 虫洞形成动画 (0-0.8秒) ===============
        
        // 视觉模糊和景深效果
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundBlur = 0.5
            particlesOpacity = 0.8
        }
        
        // 扩散环动画
        withAnimation(.easeOut(duration: 0.8)) {
            ringScale = 1.0
            ringOpacity = 0.8
            perspectiveOffset = CGSize(width: 0.02, height: 0.01) // 添加轻微的透视效果
        }
        
        // 颜色渐变过渡 - 从冷色调过渡到暖色调
        withAnimation(.easeInOut(duration: 1.6)) {
            colorTransition = 1.0 // 完成颜色过渡
        }
        
        // =============== 阶段2: 隧道形成动画 (0.8-1.7秒) ===============
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            // 触觉反馈 - 虫洞形成，使用双脉冲增强感觉
            let formationFeedback = UIImpactFeedbackGenerator(style: .soft)
            formationFeedback.impactOccurred(intensity: 0.7)
            
            // 隧道扩展和旋转动画
            withAnimation(.easeInOut(duration: 0.9)) {
                tunnelScale = 1.0  // 更大的隧道
                tunnelRotation = 60 // 更多旋转
                tunnelDepth = 0.6  // 添加深度效果
                starOpacity = 0.9  // 星光完全显示
            }
            
            // 速度渐变 - 开始慢，中间快，结束变慢
            withAnimation(.easeIn(duration: 0.4)) {
                tunnelSpeed = 1.5 // 加速阶段
            }
            
            // 虫洞中心脉动动画
            withAnimation(.easeInOut(duration: 0.8)) {
                centerPulse = 1.0
            }
            
            // 虫洞强度增加
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                wormholeIntensity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    tunnelSpeed = 0.8 // 减速阶段
                }
            }
        }
        
        // =============== 阶段3: 虫洞爆发动画 (1.7-2.2秒) ===============
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            // 触觉反馈 - 虫洞爆发，使用多连发反馈
            let burstFeedback = UIImpactFeedbackGenerator(style: .rigid)
            burstFeedback.impactOccurred(intensity: 0.6)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let secondBurst = UIImpactFeedbackGenerator(style: .rigid)
                secondBurst.impactOccurred(intensity: 0.8)
            }
            
            // 闪光动画 - 更柔和的过渡
            withAnimation(.easeIn(duration: 0.2)) {
                flashOpacity = 0.6 // 降低强度，更舒适
            }
            
            // 将光线不透明度设为0，确保不显示
            rayOpacity = 0
            rayScale = 0
            
            // 移除爆发光球动画 - 已不再需要
            // 只需要将opacity设为0，不需要创建光球
            finalGlowOpacity = 0
            
            // 闪光淡出 - 更渐进的淡出
            withAnimation(.easeOut(duration: 0.25).delay(0.2)) {
                flashOpacity = 0
            }
        }
        
        // 探索状态提示淡出
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                explorationPromptOpacity = 0
            }
        }
        
        // 动画结束后调用回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            // 回调传递到上层组件
            if let onComplete = onComplete {
                onComplete()
            }
            
            // 隐藏探索状态提示
            showExplorationPrompt = false
            
            // 延迟一点重置isActive状态，确保所有视觉效果完全结束
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isActive = false
                
                // 完全重置状态
                resetAnimationState()
            }
        }
    }
    
    // 重置所有动画状态
    private func resetAnimationState() {
        // 重置所有状态变量到初始值
        animationProgress = 0
        ringScale = 0.2
        ringOpacity = 0
        particlesOpacity = 0
        tunnelScale = 0.1
        tunnelRotation = 0
        tunnelDepth = 0
        starScale = 1.0
        starOpacity = 0
        centerPulse = 0
        flashOpacity = 0
        rayOpacity = 0
        rayScale = 0.1
        finalGlowScale = 1.0
        finalGlowOpacity = 0
        backgroundBlur = 0
        perspectiveOffset = .zero
        colorTransition = 0
        tunnelSpeed = 1.0
        particleSystemActive = false
        wormholeIntensity = 0
        
        // 重置探索状态提示相关变量
        explorationPromptOpacity = 0
        currentExplorationStage = .exploring
    }
    
    // 辅助视图 - 高斯模糊
    struct GaussianBlur: View {
        let radius: CGFloat
        
        var body: some View {
            Rectangle()
                .fill(Color.black.opacity(0.2)) // 降低背景黑色的不透明度
                .blur(radius: radius)
        }
    }
    
    // 默认初始化器 - 使用屏幕中心作为特效中心
    init(isActive: Binding<Bool>, onComplete: (() -> Void)? = nil) {
        self._isActive = isActive
        self.onComplete = onComplete
        self.centerPosition = nil
    }
    
    // 带位置参数的初始化器 - 使用指定位置作为特效中心
    init(isActive: Binding<Bool>, centerPosition: CGPoint, onComplete: (() -> Void)? = nil) {
        self._isActive = isActive
        self.onComplete = onComplete
        self.centerPosition = centerPosition
    }
    
    // 辅助方法：获取中心圆的大小
    private func getCenterCircleSize() -> CGFloat {
        if animationProgress < 0.8 {
            return animationProgress * 220 + sin(animationProgress * 30) * 8
        } else {
            return 130
        }
    }
    
    // 辅助方法：获取中心圆的不透明度
    private func getCenterCircleOpacity() -> Double {
        if animationProgress < 0.8 {
            return 0.1 + animationProgress * 0.9
        } else {
            return max(0, 0.9 - (animationProgress - 0.8) * 1.5)
        }
    }
    
    // 辅助方法：获取星星粒子的透明度
    private func getStarParticleOpacity(progress: Double, baseOpacity: Double) -> Double {
        if progress < 0.8 {
            return min(baseOpacity, progress * 1.1)
        } else {
            return min(baseOpacity, max(0, 1.0 - (progress - 0.8) * 1.8))
        }
    }
    
    // 获取隧道层不透明度
    private func getTunnelLayerOpacity(baseOpacity: Double, index: Int) -> Double {
        // 调整隧道层不透明度计算 - 根据动画进度和索引
        var result = 0.0
        
        // 隧道形成阶段 (0.0-0.5)
        if animationProgress < 0.5 {
            // 前半段逐渐显示
            let formingProgress = animationProgress / 0.5
            result = formingProgress * baseOpacity * (1.0 - Double(index) / 13.0)
        }
        // 高潮阶段 (0.5-0.8)
        else if animationProgress < 0.8 {
            result = baseOpacity * (1.0 - Double(index) / 15.0)
        }
        // 消失阶段 (0.8-1.3)
        else {
            // 后半段逐渐消失
            let disappearProgress = (animationProgress - 0.8) / 0.5
            result = baseOpacity * (1.0 - disappearProgress) * (1.0 - Double(index) / 12.0)
        }
        
        // 整体降低不透明度以增强半透明效果
        return result * 0.7
    }
    
    // 辅助方法：获取隧道星光的透明度
    private func getTunnelStarOpacity(progress: Double, radialPosition: Double, baseOpacity: Double) -> Double {
        let opacityProfile = sin(radialPosition * .pi) // 创造一个从0到1再到0的曲线
        
        if progress >= 0.8 && progress < 1.7 {
            return min(1.0, opacityProfile * 2) * baseOpacity
        } else if progress >= 1.7 {
            return max(0, 1.0 - (progress - 1.7) * 4) * baseOpacity
        } else {
            return 0.0
        }
    }
    
    // 辅助方法：获取隧道中心光芒的透明度
    private func getCenterBeamOpacity(progress: Double) -> Double {
        if progress >= 1.0 && progress < 1.7 {
            return min(0.9, (progress - 1.0) * 4)
        } else if progress >= 1.7 {
            return max(0, 1.0 - (progress - 1.7) * 2.5)
        } else {
            return 0.0
        }
    }
    
    // 辅助方法：获取最终背景的不透明度
    private func getFinalBackgroundOpacity(progress: Double) -> Double {
        if progress >= 2.2 {
            return min(1.0, (progress - 2.2) * 2.5)
        } else {
            return 0.0
        }
    }
    
    // 辅助方法：获取最终背景的模糊半径
    private func getFinalBackgroundBlur(progress: Double) -> CGFloat {
        if progress >= 2.2 {
            return max(0, 10 - (progress - 2.2) * 25)
        } else {
            return 0.0
        }
    }
    
    // 辅助方法：获取最终粒子的透明度
    private func getFinalParticleOpacity(progress: Double, disappearRate: Double) -> Double {
        if progress >= 2.2 {
            // 修改为随时间增加不透明度，而不是减少
            // 将进度(progress-2.2)映射到0-1的范围内（2.2-2.6秒）
            let fadeProgress = min(1.0, (progress - 2.2) * 2.5) // 2.5是因为总时间是0.4秒(2.6-2.2)
            // 使用平方函数让不透明度增长更明显
            return fadeProgress * fadeProgress * 1.2 // 最大值可以稍微超过1以增强效果
        } else {
            return 0.0
        }
    }
    
    // 辅助方法：获取光线的不透明度
    private func getRayOpacity(baseOpacity: Double, index: Int) -> Double {
        return baseOpacity * (1.0 - 0.03 * Double(index % 5))
    }
    
    // 辅助方法：获取光线的模糊半径
    private func getRayBlurRadius(index: Int) -> CGFloat {
        return 1 + 0.5 * CGFloat(index % 3)
    }
    
    // 辅助方法：获取扩散环的大小
    private func getRingSize(index: Int, scale: CGFloat, screenWidth: CGFloat) -> CGFloat {
        return scale * (1 + CGFloat(index) * 0.25) * screenWidth * 0.6
    }
    
    // 辅助方法：获取扩散环的不透明度
    private func getRingOpacity(baseOpacity: Double, index: Int) -> Double {
        return max(0, baseOpacity - Double(index) * 0.15)
    }
    
    // 辅助方法：获取扩散环的模糊半径
    private func getRingBlurRadius(index: Int) -> CGFloat {
        return 0.3 + 0.5 * Double(index)
    }
    
    // 创建中心爆发光点
    private func centerExplosionLight(center: CGPoint) -> some View {
        let gradient = RadialGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.9),
                Color(red: 0.8, green: 0.7, blue: 0.9).opacity(0.8),
                Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.7),
                Color.clear
            ]),
            center: .center,
            startRadius: 3,
            endRadius: 90 * (1 + colorTransition * 0.5)
        )
        
        let blurRadius = 5 - 4 * min(1, animationProgress * 2)
        let scaleEffect = 1.0 + sin(animationProgress * 10) * 0.05
        // 使用原基础不透明度的80%
        let finalOpacity = getCenterCircleOpacity() * 0.8
        
        return Circle()
            .fill(gradient)
            .frame(width: getCenterCircleSize() * 0.8, height: getCenterCircleSize() * 0.8)
            .opacity(finalOpacity)
            .blur(radius: blurRadius)
            .offset(x: perspectiveOffset.width * 8, y: perspectiveOffset.height * 8)
            .position(center)
            .scaleEffect(scaleEffect)
    }
    
    // 隧道中心光芒
    private func tunnelCenterBeam(center: CGPoint) -> some View {
        let gradient = RadialGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.9),
                Color(red: 0.9, green: 0.8, blue: 1.0).opacity(0.7),
                Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.4),
                Color.clear
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 35 * (1 + wormholeIntensity * 2)
        )
        
        let frameSize = 16 + centerPulse * 20
        // 将原始不透明度乘以0.85，增加半透明效果
        let opacity = getCenterBeamOpacity(progress: animationProgress) * 0.85
        let blurRadius = 1.6 + centerPulse * 1.6
        let scaleEffect = 1.0 + sin(animationProgress * 30) * 0.1
        
        return Circle()
            .fill(gradient)
            .frame(width: frameSize, height: frameSize)
            .opacity(opacity)
            .blur(radius: blurRadius)
            .position(center)
            .scaleEffect(scaleEffect)
    }
    
    // 扩散环
    private func diffusionRing(index: Int, center: CGPoint, screenWidth: CGFloat) -> some View {
        let ringSize = getRingSize(index: index, scale: ringScale, screenWidth: screenWidth)
        // 降低散射环的基础不透明度到60%
        let baseOpacity = 0.6
        let opacity = getRingOpacity(baseOpacity: baseOpacity, index: index)
        let blurRadius = getRingBlurRadius(index: index)
        
        // 自定义颜色 - 从中心到边缘的渐变
        let ringColor = index % 2 == 0 
            ? Color(red: 0.7, green: 0.5, blue: 0.9).opacity(opacity)
            : Color(red: 0.6, green: 0.4, blue: 0.8).opacity(opacity * 0.8)
        
        return Circle()
            .stroke(ringColor, lineWidth: 1.2 + CGFloat(index) * 0.2)
            .frame(width: ringSize, height: ringSize)
            .blur(radius: blurRadius)
            .position(center)
    }
    
    // 隧道层
    private func tunnelLayer(index: Int, center: CGPoint, screenWidth: CGFloat, scaleFactor: CGFloat, rotationFactor: Double) -> some View {
        let size = screenWidth * (0.06 + CGFloat(index) * 0.03) * scaleFactor
        // 降低隧道层的基础不透明度
        let baseOpacity = min(0.7, 0.8 - (Double(index) * 0.05))
        let opacity = getTunnelLayerOpacity(baseOpacity: baseOpacity, index: index)
        let rotation = Angle(degrees: Double(index) * 12 * rotationFactor)
        let blurAmount = (CGFloat(index) * 0.4 + 0.8) * (1.0 - tunnelScale * 0.5)
        
        // 颜色混合
        let tunnelColors = gradientColors.map { color in
            color.opacity(opacity * (1.0 - Double(index) * 0.05))
        }
        
        return Circle()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: tunnelColors),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                lineWidth: 0.8 + CGFloat(index) * 0.6
            )
            .frame(width: size, height: size)
            .blur(radius: blurAmount)
            .rotationEffect(rotation)
            .position(center)
    }
    
    // 隧道星粒子
    private func tunnelStarParticle(center: CGPoint, size: CGFloat, radialPosition: CGFloat, angle: Double, screenSize: CGSize) -> some View {
        let distance = size * 0.4 * radialPosition
        let calculatedPosition = CGPoint(
            x: center.x + distance * cos(Angle(degrees: angle).radians),
            y: center.y + distance * sin(Angle(degrees: angle).radians)
        )
        
        // 修改星粒子颜色和不透明度
        let particleColor = Color.white.opacity(getStarParticleOpacity(progress: animationProgress, baseOpacity: particlesOpacity) * 0.8)
        let blurRadius = 0.8 + (1.0 - radialPosition) * 1.6
        let particleSize = 1.6 + (1.0 - radialPosition) * 2.4
        
        return Circle()
            .fill(particleColor)
            .frame(width: particleSize, height: particleSize)
            .blur(radius: blurRadius)
            .position(calculatedPosition)
    }
    
    // 初始星点
    private func initialStar(size: CGFloat, baseOpacity: Double, position: CGPoint, parallaxFactor: CGFloat) -> some View {
        // 降低不透明度使其更加透明
        let adjustedBaseOpacity = baseOpacity * 0.7
        let opacity = getStarParticleOpacity(progress: animationProgress, baseOpacity: adjustedBaseOpacity)
        
        return Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: size, height: size)
            .position(
                x: position.x + perspectiveOffset.width * parallaxFactor * 100,
                y: position.y + perspectiveOffset.height * parallaxFactor * 100
            )
            .blur(radius: 0.5) // 增加一点模糊度让它看起来更柔和
            .animation(.easeInOut(duration: 0.5), value: perspectiveOffset)
    }
    
    // 放射光线 - 保留但不使用
    private func radiatingRay(index: Int, center: CGPoint, angle: Double, length: CGFloat) -> some View {
        let start = CGPoint(
            x: center.x,
            y: center.y
        )
        let end = CGPoint(
            x: center.x + Darwin.cos(angle * .pi / 180) * length * 0.6,
            y: center.y + Darwin.sin(angle * .pi / 180) * length * 0.6
        )
        
        let gradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.8),
                Color(red: 0.9, green: 0.8, blue: 1.0).opacity(0.6),
                Color.clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        let lineWidth = 1.2 + CGFloat(index % 3) * 0.4
        // 降低基础不透明度到70%
        let baseOpacity = rayOpacity * 0.7
        let opacity = getRayOpacity(baseOpacity: baseOpacity, index: index)
        let blurRadius = getRayBlurRadius(index: index)
        
        // 创建从中心点向外放射的光线
        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(gradient, lineWidth: lineWidth)
        .opacity(opacity)
        .blur(radius: blurRadius)
        .animation(.easeOut(duration: 0.2), value: rayOpacity)
    }
    
    // 最终粒子效果
    private func finalParticle(size: CGFloat, position: CGPoint, disappearRate: Double) -> some View {
        // 改为使用更明亮更饱和的紫色，增强视觉效果
        let color = Color(red: 0.6, green: 0.3, blue: 0.9).opacity(0.7)
        // 获取不透明度，不再额外乘以0.75，保持原始计算值
        let opacity = getFinalParticleOpacity(progress: animationProgress, disappearRate: disappearRate)
        // 随着不透明度增加，粒子尺寸也稍微增大
        let dynamicSize = size * (1.0 + CGFloat(opacity) * 0.3)
        
        return Circle()
            .fill(color)
            .frame(width: dynamicSize, height: dynamicSize)
            .position(position)
            .opacity(opacity)
            .blur(radius: 0.5)
            // 添加轻微发光效果
            .shadow(color: Color(red: 0.6, green: 0.3, blue: 0.9).opacity(opacity * 0.5), radius: 2, x: 0, y: 0)
    }
    
    // 探索状态提示视图 - 优化动画效果
    struct ExplorationStatusView: View {
        let stage: ExplorationStage
        @State private var dotOffset: CGFloat = 0
        @State private var pulseScale: CGFloat = 1.0
        @State private var textGlowIntensity: CGFloat = 0.4 // 降低默认辉光强度
        
        var body: some View {
            VStack(spacing: 6) { // 减小间距
                Text(stage.description)
                    .font(.system(size: 15, weight: .light, design: .rounded)) // 减小字体并降低粗细
                    .foregroundColor(Color.white.opacity(0.85)) // 降低文字不透明度
                    .tracking(1.5) // 减小字间距
                    .kerning(0.3) // 减小字符间距
                    .shadow(color: Color.white.opacity(textGlowIntensity * 0.5), radius: 1, x: 0, y: 0) // 减弱白色阴影
                    .shadow(color: Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.2), radius: 3, x: 0, y: 0) // 减弱紫色辉光
                    .overlay(
                        Text(stage.description)
                            .font(.system(size: 15, weight: .ultraLight, design: .rounded)) // 匹配主文字大小
                            .foregroundColor(Color.white.opacity(0.5)) // 降低叠加层不透明度
                            .tracking(1.5)
                            .kerning(0.3)
                            .offset(x: 0.2, y: 0.2) // 减小错位距离
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.05), // 减弱渐变起始透明度
                                Color.white.opacity(0.3), // 减弱渐变高亮透明度
                                Color.white.opacity(0.05) // 减弱渐变结束透明度
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text(stage.description)
                                .font(.system(size: 15, weight: .light, design: .rounded)) // 匹配主文字大小
                                .tracking(1.5)
                                .kerning(0.3)
                        )
                        .opacity(textGlowIntensity * 0.7) // 降低渐变不透明度
                    )
                
                // 使用更细、更微妙的光线指示器
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.5), // 降低中心亮度
                                Color.white.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 0.7) // 减小宽度和高度
                    .offset(x: -16 + (dotOffset * 32)) // 调整移动范围
            }
            .padding(.horizontal, 16) // 减小水平内边距
            .padding(.vertical, 10) // 减小垂直内边距
            .background(
                ZStack {
                    // 内部暗圆，增强对比度，略微增大尺寸
                    Circle()
                        .fill(Color.black.opacity(0.85)) // 增加透明度使其融入背景
                        .frame(width: 110, height: 110) // 减小背景圆大小
                        .blur(radius: 0.5) // 减小模糊
                    
                    // 发光边缘效果，呈现能量感
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3), // 降低边缘高亮
                                    Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.4), // 降低紫色亮度
                                    Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.3), // 降低深紫亮度
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1 // 减小线宽
                        )
                        .frame(width: 100, height: 100) // 减小边框圆大小
                        .scaleEffect(pulseScale)
                }
            )
            .onAppear {
                // 光线移动动画
                withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    dotOffset = 1.0
                }
                
                // 脉冲效果 - 减小脉冲幅度
                withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05 // 减小脉冲幅度
                }
                
                // 文字辉光动画 - 降低最大辉光强度
                withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    textGlowIntensity = 0.6 // 降低最大辉光强度
                }
            }
        }
    }
}

#Preview {
    TimeSpaceEffectView(isActive: .constant(true), onComplete: {
        #if DEBUG
        print("时空效果完成")
        #endif
    })
} 