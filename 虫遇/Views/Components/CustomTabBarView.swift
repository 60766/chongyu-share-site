import SwiftUI

/**
 * 自定义底部导航栏组件
 * 设计符合"虫遇"应用时空穿越主题的导航图标
 * 优化设计：更轻量化，更高透明度效果，减小高度
 */
struct CustomTabBarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            // 磨砂背景层
            TabBarBackground()
                .zIndex(0)
                .allowsHitTesting(false) // 禁止背景接收点击事件
            
            // 内容层 - 按钮和文字
            HStack(spacing: 0) {
                // 虫遇
                CustomTabButton(
                    isSelected: selectedTab == 0,
                    title: "虫遇",
                    action: { selectedTab = 0 },
                    icon: { TimePortalIcon(isSelected: selectedTab == 0) }
                )
                .frame(maxWidth: .infinity)
                
                // 探索
                CustomTabButton(
                    isSelected: selectedTab == 1,
                    title: "探索",
                    action: { selectedTab = 1 },
                    icon: { ExploreIcon(isSelected: selectedTab == 1) }
                )
                .frame(maxWidth: .infinity)
                
                // 中间空间 - 使用透明按钮而非Spacer，确保点击不会触发任何操作
                Color.clear
                    .frame(maxWidth: 80)
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
                
                // 通知
                CustomTabButton(
                    isSelected: selectedTab == 3,
                    title: "通知",
                    action: { selectedTab = 3 },
                    icon: { NotificationIcon(isSelected: selectedTab == 3) }
                )
                .frame(maxWidth: .infinity)
                
                // 空间
                CustomTabButton(
                    isSelected: selectedTab == 4,
                    title: "空间",
                    action: { selectedTab = 4 },
                    icon: { SpaceIcon(isSelected: selectedTab == 4) }
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 5)
            .zIndex(1)
        }
        .background(Color.clear)
    }
}

/**
 * 自定义底部导航栏背景
 * 实现轻微磨砂玻璃效果，更亮的底色与上方白色搭配
 */
struct TabBarBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            if #available(iOS 15.0, *) {
                // iOS 15 - 使用更轻的模糊效果，移除白色背景层
                Rectangle()
                    .fill(Material.ultraThinMaterial) // 保持最轻的材质确保下方内容清晰可见
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: 0.01) // 保持几乎不可见的模糊效果
                    .allowsHitTesting(false) // 允许点击穿透
            } else {
                // iOS 14 - 使用更轻的模糊效果，移除白色背景层
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial)) // 保持最轻的模糊效果
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: 0.01) // 保持几乎不可见的模糊效果
                    .allowsHitTesting(false) // 允许点击穿透
            }
        }
        // 确保延伸到所有边缘
        .edgesIgnoringSafeArea(.all)
        .allowsHitTesting(false) // 确保整个背景视图不拦截点击事件
    }
}

/**
 * 优化的磨砂玻璃背景视图
 * 实现轻微的磨砂玻璃效果，更亮的效果与白色界面搭配
 */
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
        // 提高不透明度，让背景更亮
        uiView.alpha = 0.85
    }
}

/**
 * 标签按钮组件
 */
struct CustomTabButton<IconContent: View>: View {
    let isSelected: Bool
    let title: String
    let action: () -> Void
    let icon: () -> IconContent
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                // 图标
                icon()
                    .frame(height: 22)
                    .brightness(isSelected ? 0.1 : 0)
                
                // 文本
                Text(title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color.primaryColor : Color.gray.opacity(0.8))
            }
            .contentShape(Rectangle()) // 确保整个区域可点击
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 虫洞穿越中央按钮 - 更轻量化设计
 */
struct WormholeButton: View {
    let action: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 外环 - 减小尺寸，降低视觉重量
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.primaryColor.opacity(0.85),
                                Color.purple.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52) // 减小尺寸
                    .shadow(color: Color.primaryColor.opacity(0.2), radius: 6, x: 0, y: 0) // 减轻阴影
                
                // 内环动画 - 减少层数和尺寸
                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    .frame(width: 38, height: 38)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // 中心光点 - 减小尺寸
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .blur(radius: 1.5)
                
                // 星光粒子 - 减少数量
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 2, height: 2)
                        .offset(
                            x: CGFloat.random(in: -12...12),
                            y: CGFloat.random(in: -12...12)
                        )
                        .opacity(isAnimating ? 0.8 : 0.4)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: isAnimating
                        )
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

/**
 * 虫遇图标（首页）- 时空门户
 */
struct TimePortalIcon: View {
    let isSelected: Bool
    
    // 使用TimelineView来驱动动画，比Timer更适合SwiftUI
    @State private var orbitPulse: CGFloat = 1.0
    // 使用普通状态变量存储角度
    @State private var rotationAngle: Double = 0.0
    // 使用Date类型跟踪上次更新时间
    @State private var lastUpdateTime = Date()
    // 添加方向控制变量
    @State private var isReversed: Bool = false
    // 记录上次选中状态，用于检测变化
    @State private var lastSelected: Bool = false
    
    var body: some View {
        TimelineView(.animation) { timeline in
            // 在每一帧更新角度
            let now = timeline.date
            let elapsed = now.timeIntervalSince(lastUpdateTime)
            
            // 更新旋转角度 - 旋转速度降低，使运动更加柔和
            let rotationSpeed: Double = isSelected ? 40.0 : 20.0 // 每秒旋转的角度进一步降低
            
            // 根据方向计算当前角度增量
            let angleIncrement = isReversed ? -(elapsed * rotationSpeed) : (elapsed * rotationSpeed)
            
            // 计算当前应该显示的角度
            let currentAngle = rotationAngle + angleIncrement
            
            ZStack {
                // 外层轮廓 - 宇宙空间边界
                Circle()
                    .stroke(isSelected ? Color.primaryColor : Color.gray, lineWidth: 2.0)
                    .frame(width: 22, height: 22)
                    .scaleEffect(isSelected ? orbitPulse : 1.0)
                
                // 轨道线 - 表示宇宙轨道
                Circle()
                    .stroke(isSelected ? Color.primaryColor.opacity(0.9) : Color.gray.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .scaleEffect(isSelected ? orbitPulse * 0.95 : 1.0)
                
                // 中心恒星/行星
                Circle()
                    .fill(isSelected ? Color.primaryColor : Color.gray)
                    .frame(width: 5, height: 5)
                
                // 卫星/小行星轨道系统 - 使用GeometryReader确保相对于视图中心的精确定位
                GeometryReader { geometry in
                    let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                    let radius: CGFloat = 9 // 轨道半径
                    
                    // 卫星/小行星1 - 根据isReversed决定旋转方向
                    Circle()
                        .fill(isSelected ? Color.primaryColor : Color.gray)
                        .frame(width: 3, height: 3)
                        .position(
                            x: center.x + radius * cos(CGFloat(currentAngle.truncatingRemainder(dividingBy: 360)) * .pi / 180),
                            y: center.y + radius * sin(CGFloat(currentAngle.truncatingRemainder(dividingBy: 360)) * .pi / 180)
                        )
                    
                    // 卫星/小行星2 - 始终与小行星1保持对称
                    Circle()
                        .fill(isSelected ? Color.primaryColor : Color.gray)
                        .frame(width: 2, height: 2)
                        .position(
                            x: center.x + radius * cos(CGFloat((currentAngle + 180).truncatingRemainder(dividingBy: 360)) * .pi / 180),
                            y: center.y + radius * sin(CGFloat((currentAngle + 180).truncatingRemainder(dividingBy: 360)) * .pi / 180)
                        )
                }
            }
            .onAppear {
                // 初始化初始角度为随机值，避免所有图标同步
                rotationAngle = Double.random(in: 0...360)
                // 记录初始选中状态
                lastSelected = isSelected
                
                // 启动脉冲动画（只影响外观，不影响小球运动）
                if isSelected {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        orbitPulse = 1.05
                    }
                }
            }
            .onChange(of: isSelected) { _, newValue in
                // 当选中状态发生变化时，切换方向
                if newValue != lastSelected {
                    isReversed.toggle()
                    lastSelected = newValue
                }
                
                // 只有脉冲效果需要根据选中状态变化
                if newValue {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        orbitPulse = 1.05
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        orbitPulse = 1.0
                    }
                }
            }
            .onChange(of: timeline.date) { _, newDate in
                // 防抖：避免同一帧内多次更新
                let timeSinceLastUpdate = newDate.timeIntervalSince(lastUpdateTime)
                if abs(timeSinceLastUpdate) > 0.016 { // ~60fps阈值
                    // 保存当前时间作为下一帧的参考
                    lastUpdateTime = newDate
                    // 更新存储的角度值，确保在0-360范围内
                    rotationAngle = currentAngle.truncatingRemainder(dividingBy: 360)
                }
            }
        }
    }
}

/**
 * 探索图标 - 星图探索
 */
struct ExploreIcon: View {
    let isSelected: Bool
    
    // 动画状态
    @State private var isAnimating = false
    @State private var starOpacity: [Double] = [0.7, 0.8, 0.9, 0.7, 0.8]
    @State private var lineGlow = 0.6
    @State private var magnifierScale = 1.0
    
    var body: some View {
        ZStack {
            // 星座连线 - 添加光效流动
            Path { path in
                path.move(to: CGPoint(x: 5, y: 5))
                path.addLine(to: CGPoint(x: 15, y: 10))
                path.addLine(to: CGPoint(x: 20, y: 5))
                path.addLine(to: CGPoint(x: 18, y: 18))
                path.addLine(to: CGPoint(x: 8, y: 15))
                path.addLine(to: CGPoint(x: 5, y: 5))
            }
            .stroke(isSelected ? Color.primaryColor.opacity(isAnimating ? lineGlow : 0.6) : Color.gray.opacity(0.4), lineWidth: 1.2)
            
            // 星点 - 添加闪烁效果
            ForEach(0..<5) { index in
                let points = [
                    CGPoint(x: 5, y: 5),
                    CGPoint(x: 15, y: 10),
                    CGPoint(x: 20, y: 5),
                    CGPoint(x: 18, y: 18),
                    CGPoint(x: 8, y: 15)
                ]
                let sizes: [CGFloat] = [3, 5, 3, 3, 3]
                
                Circle()
                    .fill(isSelected ? Color.primaryColor : Color.gray)
                    .frame(width: sizes[index], height: sizes[index])
                    .position(points[index])
                    .opacity(isSelected && isAnimating ? starOpacity[index] : 1.0)
                    .scaleEffect(isSelected && isAnimating ? (starOpacity[index] + 0.3) : 1.0)
            }
            
            // 放大镜 - 添加轻微放大效果
            Circle()
                .stroke(isSelected ? Color.primaryColor : Color.gray, lineWidth: 1.8)
                .frame(width: 10, height: 10)
                .offset(x: 5, y: 5)
                .scaleEffect(isSelected && isAnimating ? magnifierScale : 1.0)
            
            Rectangle()
                .fill(isSelected ? Color.primaryColor : Color.gray)
                .frame(width: 1.8, height: 6)
                .rotationEffect(.degrees(45))
                .offset(x: 8, y: 8)
                .scaleEffect(isSelected && isAnimating ? magnifierScale : 1.0)
        }
        .frame(width: 24, height: 24)
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                // 激活动画
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = true
                }
                
                // 星点闪烁动画
                for i in 0..<starOpacity.count {
                    withAnimation(.easeInOut(duration: Double.random(in: 0.7...1.5)).repeatForever(autoreverses: true).delay(Double(i) * 0.2)) {
                        starOpacity[i] = Double.random(in: 0.6...1.0)
                    }
                }
                
                // 连线光效动画
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    lineGlow = 1.0
                }
                
                // 放大镜轻微放大动画
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    magnifierScale = 1.05
                }
            } else {
                // 停止动画
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = false
                    lineGlow = 0.6
                    magnifierScale = 1.0
                }
                for i in 0..<starOpacity.count {
                    starOpacity[i] = Double.random(in: 0.7...0.9)
                }
            }
        }
        .onAppear {
            if isSelected {
                // 在组件出现且被选中时，立即开始动画
                isAnimating = true
                
                // 星点闪烁动画
                for i in 0..<starOpacity.count {
                    withAnimation(.easeInOut(duration: Double.random(in: 0.7...1.5)).repeatForever(autoreverses: true).delay(Double(i) * 0.2)) {
                        starOpacity[i] = Double.random(in: 0.6...1.0)
                    }
                }
                
                // 连线光效动画
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    lineGlow = 1.0
                }
                
                // 放大镜轻微放大动画
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    magnifierScale = 1.05
                }
            }
        }
    }
}

/**
 * 通知图标 - 采用点线连接设计，具有更高的精致度
 */
struct NotificationIcon: View {
    let isSelected: Bool
    
    // 动画状态
    @State private var isAnimating = false
    @State private var centerScale = 1.0
    @State private var glowOpacity = 0.15
    @State private var pointsPulse: [Double] = [1.0, 1.0, 1.0, 1.0]
    @State private var linesOpacity: [Double] = [0.25, 0.25, 0.25, 0.25]
    
    var body: some View {
        ZStack {
            // 辅助光晕效果 - 增加设计感和动态效果
            Circle()
                .fill(isSelected ? Color.primaryColor.opacity(isAnimating ? glowOpacity : 0.15) : Color.gray.opacity(0.08))
                .frame(width: 16, height: 16)
                .blur(radius: 3)
                .position(x: 12, y: 12)
            
            // 连接线 - 从中心向四周辐射，添加脉冲流动效果
            ZStack {
                // 第一组辅助线 - 底层较淡
                Path { path in
                    // 左上连线
                    path.move(to: CGPoint(x: 12, y: 12))
                    path.addLine(to: CGPoint(x: 5, y: 5))
                    
                    // 右上连线
                    path.move(to: CGPoint(x: 12, y: 12))
                    path.addLine(to: CGPoint(x: 19, y: 5))
                    
                    // 左下连线
                    path.move(to: CGPoint(x: 12, y: 12))
                    path.addLine(to: CGPoint(x: 5, y: 19))
                    
                    // 右下连线
                    path.move(to: CGPoint(x: 12, y: 12))
                    path.addLine(to: CGPoint(x: 17, y: 16))
                }
                .stroke(isSelected ? Color.primaryColor.opacity(isAnimating ? 0.3 : 0.25) : Color.gray.opacity(0.15), 
                       lineWidth: 2.5)
                .blur(radius: 1)
                
                // 主要连接线 - 使用线性渐变增强视觉效果
                ForEach(0..<4) { index in
                    let startPoint = CGPoint(x: 12, y: 12)
                    let endpoints = [
                        CGPoint(x: 5, y: 5),   // 左上
                        CGPoint(x: 19, y: 5),  // 右上
                        CGPoint(x: 5, y: 19),  // 左下
                        CGPoint(x: 17, y: 16)  // 右下
                    ]
                    
                    // 使用梯度粗细的线条
                    GradientLine(
                        start: startPoint,
                        end: endpoints[index],
                        startColor: isSelected ? Color.primaryColor.opacity(isAnimating ? linesOpacity[index] : 1.0) : Color.gray,
                        endColor: isSelected ? Color.primaryColor.opacity(isAnimating ? linesOpacity[index] * 0.7 : 0.7) : Color.gray.opacity(0.7),
                        startWidth: 1.8,
                        endWidth: 0.8
                    )
                }
            }
            
            // 中心大圆点 - 添加光晕和内部细节增强精致感
            ZStack {
                // 光晕效果
                Circle()
                    .fill(isSelected ? Color.primaryColor.opacity(isAnimating ? 0.3 + (glowOpacity * 0.3) : 0.3) : Color.gray.opacity(0.2))
                    .frame(width: 10, height: 10)
                    .scaleEffect(isAnimating && isSelected ? centerScale : 1.0)
                
                // 主圆点
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                isSelected ? Color.primaryColor : Color.gray,
                                isSelected ? Color.primaryColor.opacity(0.9) : Color.gray.opacity(0.9)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 4
                        )
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating && isSelected ? centerScale * 0.95 : 1.0)
                
                // 高亮点
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.7) : Color.white.opacity(0.4))
                    .frame(width: 2.5, height: 2.5)
                    .offset(x: -1.5, y: -1.5)
                    .scaleEffect(isAnimating && isSelected ? centerScale * 0.9 : 1.0)
            }
            .position(x: 12, y: 12)
            
            // 四个端点小圆点 - 使用渐变增加质感，添加脉冲效果
            ForEach(0..<4) { index in
                let points = [
                    CGPoint(x: 5, y: 5),   // 左上
                    CGPoint(x: 19, y: 5),  // 右上
                    CGPoint(x: 5, y: 19),  // 左下
                    CGPoint(x: 17, y: 16)  // 右下
                ]
                
                ZStack {
                    // 小圆点阴影
                    Circle()
                        .fill(isSelected ? Color.primaryColor.opacity(0.2) : Color.gray.opacity(0.15))
                        .frame(width: 5, height: 5)
                        .blur(radius: 1)
                        .scaleEffect(isAnimating && isSelected ? pointsPulse[index] : 1.0)
                    
                    // 小圆点主体
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    isSelected ? Color.primaryColor.opacity(0.9) : Color.gray.opacity(0.9),
                                    isSelected ? Color.primaryColor : Color.gray
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 2.5
                            )
                        )
                        .frame(width: 4, height: 4)
                        .scaleEffect(isAnimating && isSelected ? pointsPulse[index] * 0.95 : 1.0)
                    
                    // 小圆点高亮
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.3))
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: -0.5, y: -0.5)
                        .scaleEffect(isAnimating && isSelected ? pointsPulse[index] * 0.9 : 1.0)
                }
                .position(points[index])
            }
        }
        .frame(width: 24, height: 24)
        .compositingGroup()
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                // 激活动画
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = true
                }
                
                // 中心点脉冲动画
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    centerScale = 1.15
                    glowOpacity = 0.25
                }
                
                // 端点脉冲动画
                for i in 0..<pointsPulse.count {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(Double(i) * 0.15)) {
                        pointsPulse[i] = 1.15
                    }
                }
                
                // 连接线光效动画
                for i in 0..<linesOpacity.count {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(i) * 0.2)) {
                        linesOpacity[i] = 1.0
                    }
                }
            } else {
                // 停止动画
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = false
                    centerScale = 1.0
                    glowOpacity = 0.15
                }
                for i in 0..<pointsPulse.count {
                    pointsPulse[i] = 1.0
                }
                for i in 0..<linesOpacity.count {
                    linesOpacity[i] = 0.25
                }
            }
        }
        .onAppear {
            if isSelected {
                // 在组件出现且被选中时，立即开始动画
                isAnimating = true
                
                // 中心点脉冲动画
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    centerScale = 1.15
                    glowOpacity = 0.25
                }
                
                // 端点脉冲动画
                for i in 0..<pointsPulse.count {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(Double(i) * 0.15)) {
                        pointsPulse[i] = 1.15
                    }
                }
                
                // 连接线光效动画
                for i in 0..<linesOpacity.count {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(i) * 0.2)) {
                        linesOpacity[i] = 1.0
                    }
                }
            }
        }
    }
}

/**
 * 梯度线条组件 - 为通知图标提供线条粗细变化效果
 */
struct GradientLine: View {
    var start: CGPoint
    var end: CGPoint
    var startColor: Color
    var endColor: Color
    var startWidth: CGFloat
    var endWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 创建具有粗细变化的线条
                Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [startColor, endColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: startWidth,
                        lineCap: .round
                    )
                )
            }
        }
    }
}

/**
 * 空间图标 - 用户空间
 */
struct SpaceIcon: View {
    let isSelected: Bool
    
    // 动画状态
    @State private var isAnimating = false
    @State private var outerRingScale = 1.0
    @State private var innerCircleOpacity = 0.3
    @State private var innerCircleScale = 1.0
    @State private var centerDotScale = 1.0
    @State private var rotation = 0.0
    
    var body: some View {
        ZStack {
            // 基础圆形 - 添加脉冲呼吸效果
            Circle()
                .stroke(
                    isSelected ? Color.primaryColor : Color.gray.opacity(0.6),
                    lineWidth: 1.8
                )
                .frame(width: 22, height: 22)
                .scaleEffect(isAnimating && isSelected ? outerRingScale : 1.0)
            
            // 内部结构 - 添加旋转和呼吸效果
            Circle()
                .fill(isSelected ? Color.primaryColor.opacity(isAnimating ? innerCircleOpacity : 0.3) : Color.clear)
                .frame(width: 12, height: 12)
                .scaleEffect(isAnimating && isSelected ? innerCircleScale : 1.0)
                .rotationEffect(.degrees(isSelected ? rotation : 0))
            
            // 中心点 - 添加缩放效果
            Circle()
                .fill(isSelected ? Color.primaryColor : Color.gray)
                .frame(width: 5, height: 5)
                .scaleEffect(isAnimating && isSelected ? centerDotScale : 1.0)
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                // 激活动画
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = true
                }
                
                // 外环脉冲动画
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    outerRingScale = 1.08
                }
                
                // 内部圆呼吸动画
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    innerCircleOpacity = 0.5
                    innerCircleScale = 1.1
                }
                
                // 中心点脉冲动画
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    centerDotScale = 1.15
                }
                
                // 旋转动画
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                // 停止动画
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAnimating = false
                    outerRingScale = 1.0
                    innerCircleOpacity = 0.3
                    innerCircleScale = 1.0
                    centerDotScale = 1.0
                }
                rotation = 0
            }
        }
        .onAppear {
            if isSelected {
                // 在组件出现且被选中时，立即开始动画
                isAnimating = true
                
                // 外环脉冲动画
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    outerRingScale = 1.08
                }
                
                // 内部圆呼吸动画
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    innerCircleOpacity = 0.5
                    innerCircleScale = 1.1
                }
                
                // 中心点脉冲动画
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    centerDotScale = 1.15
                }
                
                // 旋转动画
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

// 预览
struct CustomTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            CustomTabBarView(selectedTab: .constant(2))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}