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
        GeometryReader { geometry in
            ZStack {
                // 最外层光晕
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                            center: .center,
                            startRadius: geometry.size.width * 0.25,
                            endRadius: geometry.size.width * 0.7
                        )
                    )
                    .frame(width: geometry.size.width * 1.4, height: geometry.size.width * 1.4)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .shadow(color: Color.white.opacity(0.05), radius: 50, x: 0, y: 0)
                
                // 最外层星空
                StarfieldView()
                    .frame(width: geometry.size.width * 1.1, height: geometry.size.width * 1.1)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .opacity(0.7)
                    .rotationEffect(.degrees(outerRotation))
                
                // 黑洞外围光环效果 - 最外层
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .blur(radius: 1)
                
                // 黑洞外围光环效果 - 中间层
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
                    .frame(width: geometry.size.width * 0.65, height: geometry.size.width * 0.65)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // 黑洞外围粒子层
                ParticleRingView(
                    count: 200, 
                    minSize: 1.0, 
                    maxSize: 2.5, 
                    radius: geometry.size.width * 0.3, 
                    innerRadius: geometry.size.width * 0.25, 
                    rotationDuration: 240
                )
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
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
                    .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .blur(radius: 0.5)
                    .rotationEffect(.degrees(innerRotation * -0.5))
                
                // 黑洞内环
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    .frame(width: geometry.size.width * 0.3, height: geometry.size.width * 0.3)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .rotationEffect(.degrees(innerRotation))
                
                // 脉冲效果
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .scaleEffect(pulseScale)
                
                // 黑洞中心
                Circle()
                    .fill(Color.black)
                    .frame(width: geometry.size.width * 0.22, height: geometry.size.width * 0.22)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            .blur(radius: 1)
                            .frame(width: geometry.size.width * 0.22, height: geometry.size.width * 0.22)
                            .position(x: geometry.size.width/2, y: geometry.size.height/2)
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
                                        endRadius: geometry.size.width * 0.12
                                    )
                                )
                                .frame(width: geometry.size.width * 0.22, height: geometry.size.width * 0.22)
                                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                                .blur(radius: 5)
                            
                            // 内部星空效果
                            StarfieldView()
                                .frame(width: geometry.size.width * 0.2, height: geometry.size.width * 0.2)
                                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                                .mask(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: geometry.size.width * 0.2, height: geometry.size.width * 0.2)
                                        .position(x: geometry.size.width/2, y: geometry.size.height/2)
                                )
                                .opacity(0.9)
                                .blur(radius: 0.5)
                                .rotationEffect(.degrees(innerRotation * 1.2))
                        }
                    )
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
    }
    
    public init() {}
}

/**
 * 创作类型按钮视图组
 * 将创作类型按钮排列成环绕式布局，呼应黑洞结构
 */
public struct CreationTypeButtonsView: View {
    @EnvironmentObject private var typeManager: CreationTypeManager
    @State private var animateButtons = false
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 中心随机漫游按钮
                randomButton()
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .opacity(animateButtons ? 1 : 0)
                    .scaleEffect(animateButtons ? 1 : 0.5)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(0.05),
                        value: animateButtons
                    )
                
                // 四个分类按钮围绕中心按钮环形排列
                ForEach(1...4, id: \.self) { index in
                    let angle = Double(index-1) * (360/4) + 45 // 从右上方开始，45度偏移
                    let radius: CGFloat = min(geometry.size.width, geometry.size.height) * 0.32
                    let xPos = cos(angle * .pi / 180) * radius + geometry.size.width/2
                    let yPos = sin(angle * .pi / 180) * radius + geometry.size.height/2
                    
                    categoryButton(index: index)
                        .position(x: xPos, y: yPos)
                        .opacity(animateButtons ? 1 : 0)
                        .scaleEffect(animateButtons ? 1 : 0.5)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(0.1 + Double(index) * 0.05),
                            value: animateButtons
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // 添加出现动画
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                        animateButtons = true
                    }
                }
            }
        }
    }
    
    // 随机漫游中心按钮
    private func randomButton() -> some View {
        let isSelected = typeManager.selectedIndex == 0
        
        return VStack(spacing: 8) {
            ZStack {
                // 外部发光效果
                if isSelected {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 75, height: 75)
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
                        .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)
                }
                
                // 主背景圆形
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isSelected ? Color.white.opacity(1) : Color.white.opacity(0.12),
                                isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.18)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 65, height: 65)
                    .shadow(color: isSelected ? Color.white.opacity(0.4) : Color.black.opacity(0.2), radius: isSelected ? 8 : 4, x: 0, y: 0)
                
                // 图标
                Image(systemName: typeManager.icons[0])
                    .font(.system(size: 26, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .black : .white)
                    .shadow(color: isSelected ? Color.black.opacity(0.2) : Color.clear, radius: 1, x: 0, y: 1)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            // 按钮文字
            Text(typeManager.types[0])
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(.white)
                .opacity(isSelected ? 1.0 : 0.8)
        }
        .onTapGesture {
            // 触发触觉反馈
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            
            // 更新选中状态
            typeManager.selectType(at: 0)
        }
        .modifier(PulseEffect(isSelected: isSelected))
    }
    
    // 围绕分类按钮
    private func categoryButton(index: Int) -> some View {
        let isSelected = typeManager.selectedIndex == index
        
        return VStack(spacing: 6) {
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
                    .frame(width: 50, height: 50)
                
                // 内部阴影效果
                if isSelected {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 50)
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
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .black : .white)
                    .shadow(color: isSelected ? Color.black.opacity(0.2) : Color.clear, radius: 1, x: 0, y: 1)
            }
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            // 按钮文字
            Text(typeManager.types[index])
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundColor(.white)
                .opacity(isSelected ? 1.0 : 0.7)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 60)
        .onTapGesture {
            // 触发触觉反馈
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            
            // 更新选中状态
            typeManager.selectType(at: index)
        }
        .modifier(PulseEffect(isSelected: isSelected))
    }
    
    public init() {}
} 