import SwiftUI
import Combine

/**
 * 创作类型管理器
 * 管理内容类型的选择状态
 */
public class CreationTypeManager: ObservableObject {
    public static let shared = CreationTypeManager()
    
    // 探索方向数据
    public let types = ["随机漫游", "日常心情", "古今对望", "奇思妙想", "时空记事"]
    public let icons = ["shuffle", "heart.fill", "globe.americas.fill", "lightbulb.fill", "clock.fill"]
    
    @Published public var selectedIndex: Int = 0
    
    public func selectType(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            selectedIndex = index
        }
    }
    
    private init() {}
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
    var index: Int
    var isSelected: Bool
    var size: CGFloat
    var fontSize: CGFloat
    
    @EnvironmentObject private var typeManager: CreationTypeManager
    
    public var body: some View {
        ZStack {
            // 按钮背景 - 半透明圆形
            Circle()
                .fill(isSelected ? Color.white : Color.white.opacity(0.07))
                .frame(width: size, height: size)
                .shadow(
                    color: isSelected ? Color.white.opacity(0.4) : Color.clear, 
                    radius: isSelected ? 8 : 0, 
                    x: 0, 
                    y: 0
                )
            
            // 图标
            Image(systemName: typeManager.icons[index])
                .font(.system(size: size * 0.4, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .black : .white)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0) // 缩放比例
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        
        // 按钮标题 - 优化文字排版
        Text(typeManager.types[index])
            .font(.system(size: fontSize, weight: isSelected ? .medium : .regular))
            .foregroundColor(.white)
            .opacity(isSelected ? 1.0 : 0.7) // 提高对比度
            .padding(.top, index == 0 ? 3 : 2) // 随机漫游按钮文字间距稍大
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
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    public var body: some View {
        ZStack {
            // 最外层光晕
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                        center: .center,
                        startRadius: UIScreen.main.bounds.width * 0.3,
                        endRadius: UIScreen.main.bounds.width * 0.8
                    )
                )
                .frame(width: UIScreen.main.bounds.width * 1.6, height: UIScreen.main.bounds.width * 1.6)
                .shadow(color: Color.white.opacity(0.05), radius: 50, x: 0, y: 0)
            
            // 最外层星空
            StarfieldView()
                .frame(width: UIScreen.main.bounds.width * 1.2, height: UIScreen.main.bounds.width * 1.2)
                .opacity(0.7)
                .rotationEffect(.degrees(outerRotation))
            
            // 黑洞外围光环效果 - 最外层
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.width * 0.85)
                .blur(radius: 1)
            
            // 黑洞外围光环效果 - 中间层
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
            
            // 黑洞外围粒子层
            ParticleRingView(count: 200, minSize: 1.0, maxSize: 2.5, radius: UIScreen.main.bounds.width * 0.32, innerRadius: UIScreen.main.bounds.width * 0.28, rotationDuration: 240)
            
            // 辉光圆环
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.8),
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
            
            // 黑洞内环
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: UIScreen.main.bounds.width * 0.34, height: UIScreen.main.bounds.width * 0.34)
                .rotationEffect(.degrees(innerRotation))
            
            // 脉冲效果
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(width: UIScreen.main.bounds.width * 0.3, height: UIScreen.main.bounds.width * 0.3)
                .scaleEffect(pulseScale)
            
            // 黑洞中心
            Circle()
                .fill(Color.black)
                .frame(width: UIScreen.main.bounds.width * 0.28, height: UIScreen.main.bounds.width * 0.28)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        .blur(radius: 1)
                )
                .overlay(
                    // 中心光晕效果
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]),
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
    }
    
    public init() {}
}

/**
 * 创作类型按钮视图组
 * 将创作类型按钮排列成与黑洞呼应的环形结构
 */
public struct CreationTypeButtonsView: View {
    @EnvironmentObject private var typeManager: CreationTypeManager
    
    public var body: some View {
        ZStack {
            // 中央的随机漫游按钮
            CreationTypeButton(
                index: 0,
                isSelected: typeManager.selectedIndex == 0,
                size: 80, // 中央按钮更大
                fontSize: 14
            )
            .onTapGesture {
                // 触发触觉反馈
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                
                // 更新选中状态
                typeManager.selectType(at: 0)
            }
            .overlay(
                // 发光效果
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.5), .white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .scaleEffect(1.15)
                    .opacity(typeManager.selectedIndex == 0 ? 1 : 0)
            )
            .overlay(
                // 第二层发光效果
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .scaleEffect(1.3)
                    .opacity(typeManager.selectedIndex == 0 ? 1 : 0)
            )
            .modifier(PulseEffect(isSelected: typeManager.selectedIndex == 0))
            .zIndex(1) // 确保中央按钮位于最上层
            
            // 围绕中央的四个按钮
            ForEach(1..<typeManager.types.count, id: \.self) { index in
                OrbitingButton(
                    index: index,
                    totalButtons: typeManager.types.count - 1,
                    distance: 140, // 距离中心点的半径
                    isSelected: typeManager.selectedIndex == index,
                    onTap: {
                        // 触发触觉反馈
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        // 更新选中状态
                        typeManager.selectType(at: index)
                    }
                )
            }
        }
        .frame(height: 300) // 提供足够的空间容纳环形布局
        .padding(.bottom, 20)
    }
    
    public init() {}
}

/**
 * 环绕式按钮
 * 计算位置围绕中心点排列
 */
public struct OrbitingButton: View {
    @EnvironmentObject private var typeManager: CreationTypeManager
    
    let index: Int
    let totalButtons: Int
    let distance: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        // 计算按钮在环上的位置
        // 从顶部开始顺时针排列(-90度开始)
        let angle = -90.0 + (360.0 / Double(totalButtons)) * Double(index - 1)
        let radians = angle * .pi / 180.0
        
        let xOffset = cos(radians) * distance
        let yOffset = sin(radians) * distance
        
        return CreationTypeButton(
            index: index,
            isSelected: isSelected,
            size: isSelected ? 60 : 54, // 选中时稍大
            fontSize: 12
        )
        .offset(x: xOffset, y: yOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onTapGesture(perform: onTap)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .scaleEffect(1.2)
                .opacity(isSelected ? 0.8 : 0)
        )
        .modifier(PulseEffect(isSelected: isSelected))
    }
    
    public init(index: Int, totalButtons: Int, distance: CGFloat, isSelected: Bool, onTap: @escaping () -> Void) {
        self.index = index
        self.totalButtons = totalButtons
        self.distance = distance
        self.isSelected = isSelected
        self.onTap = onTap
    }
} 