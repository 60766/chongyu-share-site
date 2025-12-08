import SwiftUI
import Combine

/**
 * 创作类型管理器
 * 管理内容类型的选择状态
 */
public class CreationTypeManager: ObservableObject {
    public static let shared = CreationTypeManager()
    
    // 探索方向数据 - 确保与ContentGeneratorService.ContentType的rawValue一致
    public let types = ["虫洞共鸣", "日常心情", "古潮新语", "穿越吐槽", "时空记事"]
    public let icons = ["waveform.path.ecg", "heart.circle", "hourglass", "bubble.left", "infinity"]
    
    @Published public var selectedIndex: Int = 0
    
    public func selectType(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            selectedIndex = index
        }
    }
    
    private init() {
        // 初始化时验证类型是否与ContentGeneratorService.ContentType一致
        #if DEBUG
        debugLog("📊 CreationTypeManager初始化，验证类型一致性：")
        #endif
        for (_, type) in types.enumerated() {
            if ContentGeneratorService.ContentType(rawValue: type) != nil {
                #if DEBUG
                debugLog("  ✅ 类型[\(type)]可以成功映射到ContentGeneratorService.ContentType")
                #endif
            } else {
                #if DEBUG
                debugLog("  ⚠️ 警告：类型[\(type)]无法映射到ContentGeneratorService.ContentType")
                #endif
            }
        }
    }
}

/**
 * 添加脉冲动画效果的修饰符
 */
public struct PulseEffect: ViewModifier {
    public var isSelected: Bool
    @State private var isPulsing = false
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isSelected {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            .scaleEffect(isPulsing ? 1.35 : 1.25)
                            .opacity(isPulsing ? 0 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: isPulsing
                            )
                            .onAppear {
                                // 使用异步调用避免在视图更新过程中修改状态
                                DispatchQueue.main.async {
                                self.isPulsing = true
                                }
                            }
                    }
                }
            )
    }
    
    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }
}

/**
 * 星空效果视图
 */
public struct StarfieldView: View {
    @State private var stars: [Star] = []
    
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 绘制随机星星
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y)
                        .opacity(star.opacity)
                }
            }
            .onAppear {
                // 生成随机星星
                stars = (0..<100).map { _ in
                    Star(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height),
                        size: CGFloat.random(in: 1...2.5),
                        opacity: Double.random(in: 0.2...0.9)
                    )
                }
            }
        }
    }
    
    public init() {}
}

/**
 * 粒子环视图
 */
public struct ParticleRingView: View {
    let count: Int
    let minSize: CGFloat
    let maxSize: CGFloat
    let radius: CGFloat
    let innerRadius: CGFloat
    let rotationDuration: Double
    
    @State private var rotation: Double = 0
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 创建多层粒子环，每层旋转角度和大小略有不同
                ForEach(0..<3, id: \.self) { ringIndex in
                    ZStack {
                        ForEach(0..<count, id: \.self) { index in
                            // 随机粒子大小和不透明度
                            let size = CGFloat.random(in: minSize...maxSize)
                            let opacity = Double.random(in: 0.3...0.9)
                            
                            // 计算粒子在环上的位置
                            let angle = Double(index) * (360.0 / Double(count))
                            let particleRadius = CGFloat.random(in: innerRadius...radius)
                            let xPos = cos(angle * .pi / 180) * Double(particleRadius)
                            let yPos = sin(angle * .pi / 180) * Double(particleRadius)
                            
                            Circle()
                                .fill(Color.white.opacity(opacity))
                                .frame(width: size, height: size)
                                .position(
                                    x: geometry.size.width / 2 + CGFloat(xPos),
                                    y: geometry.size.height / 2 + CGFloat(yPos)
                                )
                                .blur(radius: 0.2)
                        }
                    }
                    .rotationEffect(.degrees(rotation + Double(ringIndex) * 30))
                }
            }
            .onAppear {
                // 添加缓慢旋转动画
                withAnimation(.linear(duration: rotationDuration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
    
    public init(count: Int, minSize: CGFloat, maxSize: CGFloat, radius: CGFloat, innerRadius: CGFloat, rotationDuration: Double) {
        self.count = count
        self.minSize = minSize
        self.maxSize = maxSize
        self.radius = radius
        self.innerRadius = innerRadius
        self.rotationDuration = rotationDuration
    }
}

/**
 * 创作类型按钮
 */
public struct CreationTypeButton: View {
    let index: Int
    let isSelected: Bool
    let size: CGFloat
    let fontSize: CGFloat
    
    @StateObject private var typeManager = CreationTypeManager.shared
    
    public var body: some View {
        ZStack {
            // 按钮背景 - 半透明圆形
            Circle()
                .fill(isSelected ? Color.white : Color.white.opacity(0.07))
                .frame(width: size, height: size)
                .shadow(
                    color: isSelected ? Color(red: 0.95, green: 0.95, blue: 1.0, opacity: 0.6) : Color.clear, 
                    radius: isSelected ? 8 : 0, 
                    x: 0, 
                    y: 0
                )
                // 添加细微的边框，提升在黑色背景上的可见度
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        .opacity(isSelected ? 0 : 1)
                )
                // 添加精致的内部高光效果(仅在选中时)
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                        .scaleEffect(0.85)
                        .opacity(isSelected ? 0.15 : 0)
                )
            
            // 图标
            Image(systemName: typeManager.icons[index])
                .font(.system(size: size * 0.4, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .black : .white)
                .opacity(isSelected ? 1.0 : 0.9) // 微调未选中时图标的透明度
        }
        .scaleEffect(isSelected ? 1.05 : 1.0) // 缩放比例
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        
        // 按钮标题 - 优化文字排版
            Text(typeManager.types[index])
            .font(.system(size: fontSize, weight: isSelected ? .medium : .regular, design: .rounded))
            .foregroundColor(.white)
            .opacity(isSelected ? 1.0 : 0.7)
            .tracking(0.6) // 增加字间距提升科技感
            .padding(.top, index == 0 ? 3 : 2)
            // 增强可读性的阴影效果
            .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 0.5)
            // 选中时添加轻微辉光效果
            .shadow(color: isSelected ? Color.white.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 0)
    }
    
    public init(index: Int, isSelected: Bool, size: CGFloat, fontSize: CGFloat) {
        self.index = index
        self.isSelected = isSelected
        self.size = size
        self.fontSize = fontSize
    }
}

/**
 * 黑洞视图
 * 创建虫洞视觉效果
 */
public struct BlackHoleView: View {
    // 添加回调属性
    var onCenterPositionChanged: ((CGPoint) -> Void)?
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var centerButtonScale: CGFloat = 1.0
    
    // 添加中心位置偏好键
    struct CenterIconPositionPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint? = nil
        
        static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
            value = nextValue() ?? value
        }
    }
    
    @EnvironmentObject private var typeManager: CreationTypeManager
    
    // 黑洞中心按钮 - 动态显示当前选中的类型
    private func centerButton() -> some View {
        // 获取当前选中的索引和相关信息
        let selectedIndex = typeManager.selectedIndex
        let iconName = typeManager.icons[selectedIndex]
        let typeName = typeManager.types[selectedIndex]
        
        return ZStack {
            // 按钮部分 - 保持在中心位置
            Button(action: {
                // 触发触觉反馈
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                
                // 按钮动作保持不变 - 确保选中当前类型
                typeManager.selectType(at: selectedIndex)
            }) {
                ZStack {
                    // 外部光晕扩散效果 - 类似于黑洞的吸积盘
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.2), // 改为紫色
                                            Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.6), // 改为紫色
                                            Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.8), // 改为紫色
                                            Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.6), // 改为紫色
                                            Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.2)  // 改为紫色
                                        ]),
                                        center: .center
                                    ),
                                    lineWidth: 1.5
                                )
                                .blur(radius: 1.5)
                        )
                        .rotationEffect(.degrees(innerRotation * 0.3))
                    
                    // 外部星云效果 - 类似于黑洞周围的星云
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: CGFloat.random(in: 10...20), height: CGFloat.random(in: 10...20))
                            .blur(radius: CGFloat.random(in: 2...4))
                            .offset(
                                x: cos(Double(index) * 2 * .pi / 6) * 45,
                                y: sin(Double(index) * 2 * .pi / 6) * 45
                            )
                    }
                    
                    // 主按钮背景 - 半透明暗色调，更好地融入黑洞
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.15, green: 0.12, blue: 0.2), // 深紫黑色
                                    Color.black.opacity(0.8)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.8), // 改回白色
                                            Color.white.opacity(0.8), // 改回白色
                                            Color.white.opacity(0.3)  // 改回白色
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.white.opacity(0.2), radius: 8, x: 0, y: 0) // 改回白色阴影
                    
                    // 内部星空效果 - 在按钮内部添加微妙的星空
                    ZStack {
                        // 内部星星点缀
                        ForEach(0..<20) { _ in
                            Circle()
                                .fill(Color.white)
                                .frame(width: CGFloat.random(in: 0.5...1.2), 
                                      height: CGFloat.random(in: 0.5...1.2))
                                .position(
                                    x: CGFloat.random(in: 15...55),
                                    y: CGFloat.random(in: 15...55)
                                )
                                .opacity(Double.random(in: 0.3...0.8))
                                .blur(radius: 0.1)
                        }
                    }
                    .frame(width: 70, height: 70)
                    .mask(Circle().frame(width: 70, height: 70))
                    .opacity(0.6)
                    .rotationEffect(.degrees(innerRotation * 0.5))
                    
                    // 能量光环 - 添加内部光环效果
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0),           // 改回白色
                                    Color.white.opacity(0.5),         // 改回白色
                                    Color.white.opacity(0.8),         // 改回白色
                                    Color.white.opacity(0.5),         // 改回白色
                                    Color.white.opacity(0)            // 改回白色
                                ]),
                                center: .center
                            ),
                            lineWidth: 0.8
                        )
                        .frame(width: 50, height: 50)
                        .blur(radius: 0.5)
                        .rotationEffect(.degrees(innerRotation * -0.7))
                    
                    // 图标和光晕效果
                    Image(systemName: iconName)
                        .font(.system(size: 26, weight: .light))
                        .foregroundColor(Color(red: 255/255, green: 220/255, blue: 0/255)) // 更亮的黄色
                        .opacity(1.0) // 增加不透明度，使其更明亮
                        .shadow(color: Color(red: 255/255, green: 220/255, blue: 0/255).opacity(0.9), radius: 8, x: 0, y: 0) // 增强黄色光晕
                        .transition(.scale.combined(with: .opacity))
                        .overlay(
                            Image(systemName: iconName)
                                .font(.system(size: 26, weight: .light))
                                .foregroundColor(Color(red: 255/255, green: 220/255, blue: 0/255)) // 更亮的黄色
                                .opacity(0.8) // 增加不透明度
                                .blur(radius: 5) // 增加模糊以增强发光效果
                                .offset(x: 0.5, y: 0.5)
                        )
                        // 添加背景来获取图标的精确位置
                        .background(
                            GeometryReader { iconGeometry in
                                Color.clear
                                    .preference(
                                        key: CenterIconPositionPreferenceKey.self,
                                        value: CGPoint(
                                            x: iconGeometry.frame(in: .global).midX,
                                            y: iconGeometry.frame(in: .global).midY
                                        )
                                    )
                            }
                        )
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
            }
            .buttonStyle(PlainButtonStyle()) // 使用Plain样式避免默认按钮效果
            
            // 类型文字 - 放置在按钮下方，作为单独元素
            Text(typeName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .opacity(0.7) // 降低透明度从0.95到0.7
                .shadow(color: .black, radius: 2, x: 0, y: 0)
                .offset(y: 48) // 将文字放置在按钮下方，使用足够大的偏移确保不在按钮内
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
        }
    }
    
    public var body: some View {
        ZStack {
            // 最外层光晕 - 添加紫色调
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.05, blue: 0.15), // 深紫黑色
                            Color.black.opacity(0)
                        ]),
                        center: .center,
                        startRadius: UIScreen.main.bounds.width * 0.3,
                        endRadius: UIScreen.main.bounds.width * 0.8
                    )
                )
                .frame(width: UIScreen.main.bounds.width * 1.6, height: UIScreen.main.bounds.width * 1.6)
                .shadow(color: Color.white.opacity(0.05), radius: 50, x: 0, y: 0) // 改为白色阴影
            
            // 最外层星空
            StarfieldView()
                .frame(width: UIScreen.main.bounds.width * 1.2, height: UIScreen.main.bounds.width * 1.2)
                .opacity(0.7)
                .rotationEffect(.degrees(outerRotation))
            
            // 黑洞外围光环效果 - 最外层 - 修改为白色
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1) // 改为白色
                .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.width * 0.85)
                .blur(radius: 1)
            
            // 黑洞外围光环效果 - 中间层 - 修改为白色
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 2) // 改为白色
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
            
            // 黑洞外围粒子层
            ParticleRingView(count: 200, minSize: 1.0, maxSize: 2.5, radius: UIScreen.main.bounds.width * 0.32, innerRadius: UIScreen.main.bounds.width * 0.28, rotationDuration: 240)
            
            // 辉光圆环 - 修改为白色
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.8), // 改为白色
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .frame(width: UIScreen.main.bounds.width * 0.44, height: UIScreen.main.bounds.width * 0.44)
                .blur(radius: 0.5)
                .rotationEffect(.degrees(innerRotation * -0.5))
            
            // 黑洞内环 - 修改为白色
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.5) // 改为白色
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .frame(width: UIScreen.main.bounds.width * 0.34, height: UIScreen.main.bounds.width * 0.34)
                .rotationEffect(.degrees(innerRotation))
            
            // 脉冲效果 - 修改为白色
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1) // 改为白色
                .frame(width: UIScreen.main.bounds.width * 0.3, height: UIScreen.main.bounds.width * 0.3)
                .scaleEffect(pulseScale)
            
            // 黑洞中心
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.05, blue: 0.15), // 深紫黑色
                            Color.black
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: UIScreen.main.bounds.width * 0.14
                    )
                )
                .frame(width: UIScreen.main.bounds.width * 0.28, height: UIScreen.main.bounds.width * 0.28)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6), // 改为白色，原为黄色调
                                    Color.white.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blur(radius: 1)
                )
                .overlay(
                    // 中心光晕效果 - 添加黄色调
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3), // 改为白色，原为黄色调
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: UIScreen.main.bounds.width * 0.15
                                )
                            )
                            .frame(width: UIScreen.main.bounds.width * 0.26, height: UIScreen.main.bounds.width * 0.26)
                            .blur(radius: 5)
                        
                        // 内部星空效果
                        StarfieldView()
                            .frame(width: UIScreen.main.bounds.width * 0.25, height: UIScreen.main.bounds.width * 0.25)
                            .mask(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: UIScreen.main.bounds.width * 0.25, height: UIScreen.main.bounds.width * 0.25)
                            )
                            .opacity(0.9)
                            .blur(radius: 0.5)
                            .rotationEffect(.degrees(innerRotation * 1.2))
                    }
                )
            
            // 添加中心按钮显示当前选中的类型
            centerButton()
                .scaleEffect(centerButtonScale)
                .offset(y: 0) // 确保按钮位于黑洞正中心
                .onAppear {
                    // 添加缓慢脉动动画
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        centerButtonScale = 1.03 // 略微减小脉动幅度
                    }
                }
        }
        .onAppear {
            // 添加旋转和脉冲动画
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            
            withAnimation(.linear(duration: 180).repeatForever(autoreverses: false)) {
                innerRotation = 360
            }
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
        .onPreferenceChange(CenterIconPositionPreferenceKey.self) { position in
            if let position = position, let onCenterPositionChanged = onCenterPositionChanged {
                onCenterPositionChanged(position)
            }
        }
    }
    
    public init(onCenterPositionChanged: ((CGPoint) -> Void)? = nil) {
        self.onCenterPositionChanged = onCenterPositionChanged
    }
}

/**
 * 创作类型按钮视图组
 * 将创作类型按钮排列成更美观的布局
 */
public struct CreationTypeButtonsView: View {
    @EnvironmentObject private var typeManager: CreationTypeManager
    @State private var animateButtons = false
    // 记录上一个选中的按钮索引
    @State private var previousSelectedIndex: Int = 0
    // 记录当前显示在底部的四个按钮索引
    @State private var bottomButtonIndices: [Int] = [1, 2, 3, 4]
    // 按钮位置映射，用于保持未点击按钮的位置稳定
    @State private var buttonPositions: [Int: Int] = [:]
    
    public var body: some View {
        // 水平排列四个按钮
        HStack(spacing: 24) {
            // 显示底部的4个按钮
            ForEach(0..<4, id: \.self) { position in
                let buttonIndex = bottomButtonIndices[position]
                categoryButton(index: buttonIndex, position: position)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .center) // 确保HStack在容器中居中
        .onAppear {
            // 初始化
            initializeButtonLayout()
            
            // 添加出现动画
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    animateButtons = true
                }
            }
        }
        .onChange(of: typeManager.selectedIndex) { oldValue, newValue in
            updateButtonLayout(oldValue: oldValue, newValue: newValue)
        }
    }
    
    // 初始化按钮布局
    private func initializeButtonLayout() {
        // 初始状态：如果黑洞中心按钮是0(随机漫游)，那么底部显示1,2,3,4
        // 否则，底部显示除当前选中以外的四个按钮
        let selectedIndex = typeManager.selectedIndex
        previousSelectedIndex = selectedIndex
        
        // 设置初始底部按钮
        bottomButtonIndices = Array(0...4).filter { $0 != selectedIndex }.prefix(4).map { $0 }
        
        // 初始化按钮位置映射
        for (index, buttonIndex) in bottomButtonIndices.enumerated() {
            buttonPositions[buttonIndex] = index
        }
    }
    
    // 更新按钮布局 - 实现点击交换效果
    private func updateButtonLayout(oldValue: Int, newValue: Int) {
        // 先检查新值是否已经在底部按钮中
        if let positionIndex = bottomButtonIndices.firstIndex(of: newValue) {
            // 用户点击了底部的按钮，需要与中心按钮交换
            
            // 保存点击的按钮的位置索引
            let clickedPosition = positionIndex
            
            // 将原中心按钮放到被点击按钮的位置
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                bottomButtonIndices[clickedPosition] = oldValue
                // 更新按钮位置映射
                buttonPositions[oldValue] = clickedPosition
            }
        }
        
        // 更新上一个选中索引
        previousSelectedIndex = newValue
    }
    
    // 普通分类按钮
    private func categoryButton(index: Int, position: Int) -> some View {
        let isSelected = typeManager.selectedIndex == index
        
        return VStack(spacing: 7) {  // 垂直布局，间距7
            // 按钮圆形部分
            ZStack {
                // 背景圆形
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isSelected ? Color.white : Color.white.opacity(0.05),
                                isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 55, height: 55)  // 按钮尺寸为55x55
                
                // 为所有按钮添加微弱的白色边框，增加可见度
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0 : 0.15), lineWidth: 0.5)
                    .frame(width: 55, height: 55)
                
                // 内部阴影效果
                if isSelected {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 55, height: 55)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.white.opacity(0.3), radius: 6, x: 0, y: 0)
                }
                
                // 图标
                Image(systemName: typeManager.icons[index])
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))  // 图标大小20
                    .foregroundColor(isSelected ? .black : .white)
                    .shadow(color: isSelected ? Color.black.opacity(0.2) : Color.clear, radius: 1, x: 0, y: 1)
            }
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            // 按钮文字
            Text(typeManager.types[index])
                .font(.system(size: 12, weight: isSelected ? .medium : .regular, design: .rounded))
                .foregroundColor(.white)
                .opacity(isSelected ? 1.0 : 0.7)
                .tracking(0.5) // 增加字间距，提升科技感
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                // 添加轻微阴影效果增强可读性
                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 0.5)
                // 选中时添加微弱辉光效果
                .shadow(color: isSelected ? Color.white.opacity(0.2) : Color.clear, radius: 1.5, x: 0, y: 0)
        }
        .frame(width: 65)  // 整体宽度65
        .offset(y: animateButtons ? 0 : 30)
        .opacity(animateButtons ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
            .delay(0.05 + Double(position) * 0.05), // 使用位置索引确保动画延迟合理
            value: animateButtons
        )
        .onTapGesture {
            // 触发触觉反馈
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            
            // 更新选中状态
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                typeManager.selectType(at: index)
            }
        }
        .modifier(PulseEffect(isSelected: isSelected))
        // 添加id确保视图在按钮变化时正确重建
        .id("button-\(index)-\(position)-\(isSelected)")
    }
    
    public init() {}
} 