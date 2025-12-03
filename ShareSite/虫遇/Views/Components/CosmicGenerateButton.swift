import SwiftUI
import Combine
import UIKit

/**
 * 宇宙球体生成按钮
 * 具有螺旋动效的按钮
 */
struct CosmicGenerateButton: View {
    // 设备适配
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // 状态变量
    @State private var isRotating = false
    @State private var isPulsing = false
    @State private var isPressed = false
    @Binding var isGenerating: Bool
    @State private var rotationSpeed = 15.0
    @State private var capsuleScale: CGFloat = 0.0
    @State private var capsuleLength: CGFloat = 1.0
    
    // 螺旋动画参数
    @State private var currentTheta: CGFloat = 0
    @State private var spiralRotation: Double = 0
    
    // 彩球自然运动状态 - 添加更多状态变量用于流体运动
    @State private var ballsRotation = 0.0
    @State private var ball1Offset: CGSize = .zero
    @State private var ball2Offset: CGSize = .zero
    @State private var ball3Offset: CGSize = .zero
    @State private var ball4Offset: CGSize = .zero
    @State private var ball5Offset: CGSize = .zero
    @State private var ball1Scale: CGFloat = 1.0
    @State private var ball2Scale: CGFloat = 1.0
    @State private var ball3Scale: CGFloat = 1.0
    @State private var ball4Scale: CGFloat = 1.0
    @State private var ball5Scale: CGFloat = 1.0
    @State private var animationPhase: Double = 0.0
    
    // 半隐藏模式相关状态
    var isHalfHidden: Bool = false  // 改为非State属性，通过参数传入
    @State private var isDragging: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded: Bool = false
    
    // 添加水滴效果状态
    @State private var animateWaterDropEffect = false
    
    // 性能优化：添加应用状态监听
    @Environment(\.scenePhase) private var scenePhase
    
    // 性能优化：使用timer引用便于管理生命周期
    @State private var animationTimer: AnyCancellable?
    
    // 性能优化：使用displayLink进行高效重绘
    @State private var displayLink: DisplayLink?
    
    // 点击回调
    var action: () -> Void
    
    // 胶囊颜色数组
    private let capsuleColors: [Color] = [
        Color(red: 0.75, green: 0.20, blue: 1.0),  // 鲜亮紫色
        Color(red: 0.35, green: 0.65, blue: 1.0),  // 亮蓝色
        Color(red: 1.0, green: 0.40, blue: 0.75),  // 亮粉色
        Color(red: 0.0, green: 0.75, blue: 1.0),   // 天蓝色
        Color(red: 0.50, green: 0.30, blue: 1.0),  // 深紫色
        Color(red: 0.30, green: 1.0, blue: 0.7),   // 亮绿色
        Color(red: 1.0, green: 0.80, blue: 0.2),   // 金黄色
        Color(red: 1.0, green: 0.35, blue: 0.35)   // 珊瑚红
    ]
    
    // 螺旋参数 - 增大基础半径使螺旋更大
    private let baseRadius: CGFloat = 0.6  // 从0.4增大到0.6
    private let maxTheta: CGFloat = .pi * 40
    private let maxAllowedTheta: CGFloat = 20  // 从15增大到20，增加螺旋的最大范围
    
    // 添加时间状态以实现更流畅的动画
    @State private var animationTime: Double = 0
    
    // 添加位置相关状态
    @State private var buttonVerticalPosition: CGFloat = 0 // 记录垂直位置
    @State private var isLongPressing: Bool = false // 长按状态
    @State private var initialPosition: CGPoint = .zero // 开始拖动时的位置
    @State private var isAdjustingPosition: Bool = false // 是否正在调整位置
    @State private var hasSetInitialPosition: Bool = false // 是否已设置初始位置
    @AppStorage("buttonVerticalOffset") private var savedVerticalOffset: Double = 0 // 保存位置
    
    // 添加一个namespace用于在初始化时避免动画
    @Namespace private var initialRenderNamespace
    
    // 添加新的状态变量来控制初始渲染
    @State private var isFirstAppear: Bool = true
    
    // 按钮参数设置 - 根据设备调整大小
    private var buttonParameters: (size: CGFloat, offset: CGFloat, hiddenOffset: CGFloat) {
        // 获取当前设备信息
        let deviceSize = UIScreen.main.bounds.size
        let isSmallDevice = min(deviceSize.width, deviceSize.height) < 375 // iPhone SE 尺寸
        let isLargeDevice = min(deviceSize.width, deviceSize.height) >= 428 // iPhone Pro Max 尺寸
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        // 判断设备方向
        let isLandscape = deviceSize.width > deviceSize.height
        
        // 基础参数
        var size: CGFloat = 55
        var offset: CGFloat = -10
        var hiddenOffset: CGFloat = 27.5
        
        // 根据设备类型和方向调整
        if isPad {
            // iPad上按钮稍大
            size = isLandscape ? 70 : 65
            offset = isLandscape ? -12 : -15
            hiddenOffset = size * 0.5
        } else if isLargeDevice {
            // 大型iPhone
            size = 60
            offset = -12
            hiddenOffset = 30
        } else if isSmallDevice {
            // 小型iPhone
            size = 50
            offset = -8
            hiddenOffset = 25
        }
        
        // 根据水平尺寸类调整
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            // 宽屏设备，按钮更大
            size *= 1.1
        }
        
        return (size, offset, hiddenOffset)
    }
    
    // 初始化方法
    init(isGenerating: Binding<Bool>, action: @escaping () -> Void) {
        self._isGenerating = isGenerating
        self.action = action
        self.isHalfHidden = false
        // 初始化时设置正确的垂直位置
        self._buttonVerticalPosition = State(initialValue: CGFloat(UserDefaults.standard.double(forKey: "buttonVerticalOffset")))
    }
    
    // 新增初始化方法，支持半隐藏模式
    init(isGenerating: Binding<Bool>, isHalfHidden: Bool = false, action: @escaping () -> Void) {
        self._isGenerating = isGenerating
        self.action = action
        self.isHalfHidden = isHalfHidden
        // 初始化时设置正确的垂直位置
        self._buttonVerticalPosition = State(initialValue: CGFloat(UserDefaults.standard.double(forKey: "buttonVerticalOffset")))
    }
    
    // 计算按钮是否应该处于展开状态（完全显示）
    private var shouldBeExpanded: Bool {
        // 当正在生成内容或已手动展开时，按钮应完全显示
        return isGenerating || isExpanded
    }
    
    // 添加计算属性，获取当前按钮的水平偏移量，避免动画冲突
    private func buttonHorizontalOffset(_ params: (size: CGFloat, offset: CGFloat, hiddenOffset: CGFloat)) -> CGFloat {
        return isHalfHidden && !shouldBeExpanded ? (params.hiddenOffset + dragOffset) : params.offset
    }

    var body: some View {
        // 获取按钮参数
        let params = buttonParameters
        
        // 使用ZStack作为容器，确保点击区域正确
        ZStack {
            // 透明背景覆盖整个按钮区域，但不响应点击
            Color.clear
                .frame(width: params.size, height: params.size)
                .contentShape(Circle())
                .allowsHitTesting(false)
            
            Button(action: {
                // 仅在不处于位置调整模式时才响应点击
                if !isAdjustingPosition {
                    if isHalfHidden && !shouldBeExpanded {
                        // 如果是半隐藏模式且未展开，则展开而不触发动作
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = true
                        }
                        
                        // 3秒后自动收回（仅当不在生成状态时）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            // 只有当不在生成状态时才自动收回
                            if !isGenerating {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isExpanded = false
                                }
                            }
                        }
                    } else {
                        // 正常模式或已展开，触发按压动画
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                        
                        // 触发动画
                        withAnimation(.easeOut(duration: 0.5)) {
                            isGenerating = true
                            rotationSpeed = 1.2 // 加快旋转速度
                            capsuleScale = 1.0  // 显示动画
                        }
                        
                        // 开始螺旋动画
                        if isGenerating {
                            startSpiralAnimation()
                        }
                        
                        // 短暂延迟后恢复按压效果
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isPressed = false
                            }
                            // 执行传入的动作
                            action()
                        }
                    }
                }
            }) {
                ZStack {
                    // 外层玻璃球效果 - 保持透明度一致
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.7)) // 固定透明度
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.white.opacity(0.2), location: 0),
                                            .init(color: Color.white.opacity(0.05), location: 0.5),
                                            .init(color: Color.clear, location: 1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blur(radius: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color(red: 0.4, green: 0.3, blue: 0.9, opacity: 0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.4, blue: 0.9, opacity: 0.2), radius: 6)
                        .scaleEffect(isPulsing ? 1.02 : 1.0)
                        .scaleEffect(isPressed ? 0.92 : 1.0)
                    
                    // 螺旋动画 - 生成状态显示 - 增大尺寸
                    if isGenerating {
                        SpiralAnimation(
                            currentTheta: currentTheta,
                            baseRadius: baseRadius,
                            colors: capsuleColors,
                            opacity: capsuleScale
                        )
                        .frame(width: params.size * 0.98, height: params.size * 0.98) // 动态调整大小
                        .rotationEffect(Angle(degrees: spiralRotation))
                        .shadow(color: Color.white.opacity(0.2), radius: 1, x: 0, y: 0)
                        .clipShape(Circle()) // 确保内容不超出圆形边界
                    }
                    
                    // 中心小球 - 静止状态下显示 - 增强流体感运动效果
                    if !isGenerating {
                        ZStack {
                            // 水波纹效果 - 增加流体感
                            Circle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: params.size * 0.82, height: params.size * 0.82) // 动态调整大小
                                .scaleEffect(isPulsing ? 1.05 : 0.95)
                                .animation(Animation.easeInOut(duration: 4.5).repeatForever(), value: isPulsing)
                            
                            // 紫色主球 - 动态调整大小和位置
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            capsuleColors[6].opacity(0.95),  // 改为金黄色
                                            capsuleColors[6].opacity(0.7)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 10
                                    )
                                )
                                .frame(width: params.size * 0.36, height: params.size * 0.36)
                                .scaleEffect(ball1Scale)
                                .offset(x: scaledOffset(baseValue: -5, size: params.size).width + ball1Offset.width, 
                                        y: scaledOffset(baseValue: -2, size: params.size).height + ball1Offset.height)
                                .blur(radius: 0.5)
                            
                            // 蓝色球 - 动态调整大小和位置
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            capsuleColors[4].opacity(0.95),  // 改为深紫色
                                            capsuleColors[4].opacity(0.7)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 8
                                    )
                                )
                                .frame(width: params.size * 0.29, height: params.size * 0.29)
                                .scaleEffect(ball2Scale)
                                .offset(x: scaledOffset(baseValue: 10, size: params.size).width + ball2Offset.width, 
                                        y: scaledOffset(baseValue: -8, size: params.size).height + ball2Offset.height)
                                .blur(radius: 0.5)
                            
                            // 粉色球 - 动态调整大小和位置
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            capsuleColors[2].opacity(0.95),
                                            capsuleColors[2].opacity(0.7)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 7
                                    )
                                )
                                .frame(width: params.size * 0.25, height: params.size * 0.25)
                                .scaleEffect(ball3Scale)
                                .offset(x: scaledOffset(baseValue: 8, size: params.size).width + ball3Offset.width, 
                                        y: scaledOffset(baseValue: 10, size: params.size).height + ball3Offset.height)
                                .blur(radius: 0.5)
                            
                            // 亮紫色球 - 动态调整大小和位置
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            capsuleColors[3].opacity(0.95),
                                            capsuleColors[3].opacity(0.7)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 6
                                    )
                                )
                                .frame(width: params.size * 0.22, height: params.size * 0.22)
                                .scaleEffect(ball4Scale)
                                .offset(x: scaledOffset(baseValue: -12, size: params.size).width + ball4Offset.width, 
                                        y: scaledOffset(baseValue: -6, size: params.size).height + ball4Offset.height)
                                .blur(radius: 0.5)
                            
                            // 小蓝球改为黄色球 - 动态调整大小和位置
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            capsuleColors[0].opacity(0.95),  // 改为紫色
                                            capsuleColors[0].opacity(0.7)
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 5
                                    )
                                )
                                .frame(width: params.size * 0.18, height: params.size * 0.18)
                                .scaleEffect(ball5Scale)
                                .offset(x: scaledOffset(baseValue: -9, size: params.size).width + ball5Offset.width, 
                                        y: scaledOffset(baseValue: 12, size: params.size).height + ball5Offset.height)
                                .blur(radius: 0.5)
                        }
                        .rotationEffect(Angle(degrees: ballsRotation))
                        .opacity(isGenerating ? 0 : 1)
                    }
                    
                    // 添加轻微的高光效果 - 保持一致的透明度
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25), // 固定透明度
                                    Color.white.opacity(0.0),
                                ]),
                                center: .topLeading,
                                startRadius: 3,
                                endRadius: 25
                            )
                        )
                        .frame(width: params.size, height: params.size)
                        .blur(radius: 1.5) // 固定模糊度
                        .mask(Circle())
                        .opacity(0.5) // 固定透明度
                }
                .frame(width: params.size, height: params.size)
                // 强制使点击区域总是为圆形，无论位置如何变化
                .contentShape(Circle())
            }
            .buttonStyle(CosmicScaleButtonStyle())
            // 使用固定的修饰符顺序，避免动画冲突
            .scaleEffect(animateWaterDropEffect ? 0.85 : 1.0)
            .scaleEffect(isAdjustingPosition ? 1.1 : 1.0) // 调整位置时稍微放大按钮提供视觉反馈
            // 位置修改 - 使用单一的动画修饰符，放在缩放后面
            .offset(
                x: buttonHorizontalOffset(params),
                y: buttonVerticalPosition
            )
            // 仅在非首次渲染时应用动画
            .animation(isFirstAppear ? nil : .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: shouldBeExpanded)
            .animation(isFirstAppear ? nil : .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: isGenerating)
            .animation(isFirstAppear ? nil : .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: buttonVerticalPosition)
            .animation(isFirstAppear ? nil : .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: dragOffset)
            
            // 位置调整指示器 - 移到ZStack顶层以确保可见性
            if isAdjustingPosition {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.white)
                    Image(systemName: "arrow.down")
                        .foregroundColor(.white)
                }
                .font(.system(size: 12, weight: .bold))
                .opacity(0.7)
                .offset(x: buttonHorizontalOffset(params), y: buttonVerticalPosition)
                .allowsHitTesting(false) // 防止指示器干扰点击事件
            }
        }
        // 组合手势：长按和拖动 - 现在应用到整个ZStack
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1)
                .onEnded { _ in
                    // 只有当按钮展开且不在生成状态时才能调整位置
                    if (isExpanded || !isHalfHidden) && !isGenerating {
                        withAnimation {
                            isLongPressing = true
                            isAdjustingPosition = true
                            
                            // 触发振动反馈
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if isHalfHidden && !isGenerating && !isAdjustingPosition {
                        // 处理水平拖动（原有功能）
                        isDragging = true
                        // 限制拖动范围
                        let newOffset = value.translation.width
                        if newOffset <= 0 && newOffset >= -27.5 {
                            // 使用直接赋值，避免动画冲突
                            dragOffset = newOffset
                        }
                    } else if isAdjustingPosition {
                        // 处理垂直位置调整
                        if !hasSetInitialPosition {
                            initialPosition = value.startLocation
                            hasSetInitialPosition = true
                        }
                        
                        // 计算垂直方向的移动距离
                        let verticalTranslation = value.location.y - initialPosition.y
                        
                        // 限制垂直移动范围（屏幕高度的40%）
                        let screenHeight = UIScreen.main.bounds.height
                        let maxOffset = screenHeight * 0.4
                        let minOffset = -screenHeight * 0.4
                        let newPosition = savedVerticalOffset + Double(verticalTranslation)
                        
                        // 使用直接赋值，避免动画冲突
                        buttonVerticalPosition = CGFloat(min(maxOffset, max(minOffset, newPosition)))
                    }
                }
                .onEnded { value in
                    if isHalfHidden && !isGenerating && !isAdjustingPosition {
                        // 处理原有的水平拖动结束逻辑
                        isDragging = false
                        
                        // 使用统一的动画参数
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                            if value.translation.width < -10 {
                                // 向左拖动超过10pt，展开按钮
                                isExpanded = true
                                dragOffset = 0
                            } else {
                                // 否则收回按钮
                                isExpanded = false
                                dragOffset = 0
                            }
                        }
                        
                        // 如果展开且不在生成状态，3秒后自动收回
                        if isExpanded && !isGenerating {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                // 再次检查生成状态，确保在生成时不会收回
                                if !isGenerating {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                                        isExpanded = false
                                        dragOffset = 0 // 确保dragOffset为0
                                    }
                                }
                            }
                        }
                    } else if isAdjustingPosition {
                        // 结束位置调整模式
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                            isAdjustingPosition = false
                            isLongPressing = false
                            hasSetInitialPosition = false
                            
                            // 保存新的垂直位置
                            savedVerticalOffset = Double(buttonVerticalPosition)
                        }
                        
                        // 触发成功振动反馈
                        let generator = UIImpactFeedbackGenerator(style: .rigid)
                        generator.impactOccurred()
                    }
                }
        )
        .onAppear {
            // 确保按钮初始位置正确，避免闪烁
            buttonVerticalPosition = CGFloat(savedVerticalOffset)
            
            // 启动脉动动画
            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            
            // 启动彩球自然运动
            startFluidBallsMovement()
            
            // 启动动画相位计时器
            startAnimationPhaseTimer()
            
            // 创建DisplayLink以获得流畅的动画更新
            setupDisplayLink()
            
            // 如果初始状态是生成中，确保按钮完全展开
            if isGenerating {
                isExpanded = true
            }
            
            // 设置初始渲染完成标记，延迟一小段时间后启用动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFirstAppear = false
            }
        }
        .onDisappear {
            // 性能优化：清理计时器资源
            animationTimer?.cancel()
            animationTimer = nil
            
            // 清理DisplayLink
            displayLink?.isPaused = true
            displayLink = nil
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // 根据应用状态管理动画
            switch newPhase {
            case .active:
                // 应用进入前台，恢复动画
                if animationTimer == nil {
                    startAnimationPhaseTimer()
                }
                displayLink?.isPaused = false
                
            case .inactive, .background:
                // 应用进入后台，暂停动画以节省资源
                animationTimer?.cancel()
                animationTimer = nil
                displayLink?.isPaused = true
                
            @unknown default:
                break
            }
        }
        // 添加设备旋转监听
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // 强制重绘按钮，确保在旋转后正确适配新尺寸
            DispatchQueue.main.async {
                withAnimation {
                    // 触发重绘但不改变状态本身
                    let currentScale = self.isPulsing
                    self.isPulsing = !currentScale
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            self.isPulsing = currentScale
                        }
                    }
                }
            }
        }
        .onChange(of: isGenerating) { oldValue, newValue in
            // 当生成状态改变时更新动画参数和展开状态
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                capsuleScale = newValue ? 1.0 : 0.0
                
                // 当开始生成时，确保按钮完全展开
                if newValue {
                    isExpanded = true
                } 
                // 当停止生成时，确保展开状态被重置，按钮可以缩回
                else if isHalfHidden {
                    // 为了流畅性，在螺旋动画消失后再缩回按钮
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                            isExpanded = false
                            dragOffset = 0 // 直接设置dragOffset为0，避免多重动画
                        }
                    }
                }
            }
            
            if newValue {
                // 开始螺旋动画
                startSpiralAnimation()
            } else {
                // 重置螺旋参数
                currentTheta = 0
                spiralRotation = 0
                // 恢复彩球流体运动
                startFluidBallsMovement()
            }
        }
        // 当状态变化时添加水滴动画和处理位置变化
        .onChange(of: shouldBeExpanded) { oldValue, newValue in
            if oldValue && !newValue {
                // 从展开到缩回时触发水滴效果
                withAnimation(.easeInOut(duration: 0.15)) {
                    animateWaterDropEffect = true
                }
                
                // 短暂延迟后恢复
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                        animateWaterDropEffect = false
                    }
                }
            }
            
            if oldValue != newValue && !isGenerating {
                // 状态变化时更新流体运动速度，只在非生成状态下改变
                let speedFactor = newValue ? 2.5 : 1.0
                updateFluidMovement(speedFactor: speedFactor)
            }
        }
    }
    
    // 根据设备尺寸缩放偏移量
    private func scaledOffset(baseValue: CGFloat, size: CGFloat) -> CGSize {
        let scaleFactor = size / 55.0 // 按钮标准尺寸为55
        return CGSize(width: baseValue * scaleFactor, height: baseValue * scaleFactor)
    }
    
    // 启动动画相位计时器 - 用于创建连续的流体感动画，优化性能
    private func startAnimationPhaseTimer() {
        // 取消可能存在的旧计时器
        animationTimer?.cancel()
        
        // 使用Combine的定时器，方便管理生命周期
        animationTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // 根据按钮状态调整动画速度
                let speedFactor: Double = (self.shouldBeExpanded && !self.isGenerating) ? 2.5 : 1.0
                self.animationPhase += 0.05 * speedFactor
                self.updateFluidMovement(speedFactor: speedFactor)
            }
    }
    
    // 设置DisplayLink以获得更流畅的动画
    private func setupDisplayLink() {
        displayLink = DisplayLink(preferredFrameRateRange: .init(minimum: 30, maximum: 60, preferred: 60))
        displayLink?.onFrame = { _ in
            // 此处可以添加需要在每一帧更新的内容
            // 当前使用Timer足够，这里预留扩展空间
        }
        displayLink?.isPaused = false
    }
    
    // 更新流体运动 - 使用正弦波和余弦波创建流体感
    private func updateFluidMovement(speedFactor: Double = 1.0) {
        // 使用不同频率和振幅的正弦波，创造自然的流体运动
        let phase = animationPhase
        
        // 振幅系数 - 展开时增大振幅
        let amplitudeFactor: CGFloat = speedFactor > 1.0 ? 1.5 : 1.0
        
        // 增加运动模式变化，基于animationPhase创建周期性变化
        let cyclePosition = sin(phase * 0.2) // 较慢的周期变化
        let patternShift = cos(phase * 0.07) // 非常缓慢的模式转换
        
        // 计算新的偏移量 - 使用不同的频率、相位和运动模式
        withAnimation(.easeInOut(duration: 0.3)) {
            // 球1：添加椭圆运动趋势
            let ellipticalFactor = 0.5 + 0.5 * sin(phase * 0.09)
            ball1Offset = CGSize(
                width: 3 * amplitudeFactor * (sin(phase * 0.5 + 0.2) + 0.3 * sin(phase * 0.23)),
                height: 2.5 * amplitudeFactor * ellipticalFactor * (cos(phase * 0.4 + 1.1) + 0.2 * cos(phase * 0.31))
            )
            
            // 球2：添加微小的螺旋趋势
            let spiralX = 2.8 * amplitudeFactor * sin(phase * 0.6 + 2.1)
            let spiralY = 3 * amplitudeFactor * cos((phase * 0.3 + 0.5) + patternShift * 0.3)
            ball2Offset = CGSize(
                width: spiralX + cyclePosition * 0.8,
                height: spiralY + cyclePosition * 0.5
            )
            
            // 球3：八字形运动趋势
            let figureEightX = 2.5 * amplitudeFactor * sin(phase * 0.45 + 1.7)
            let figureEightY = 2.2 * amplitudeFactor * cos(phase * 0.55 + 2.3) * sin(phase * 0.15)
            ball3Offset = CGSize(
                width: figureEightX,
                height: figureEightY + patternShift * 1.2
            )
            
            // 球4：波浪形运动趋势
            ball4Offset = CGSize(
                width: 2.2 * amplitudeFactor * (sin(phase * 0.7 + 0.9) + 0.3 * sin(phase * 0.26 + 1.3)),
                height: 2.7 * amplitudeFactor * cos(phase * 0.5 + 1.5) * (1 + 0.2 * cyclePosition)
            )
            
            // 球5：渐进近似轨道运动
            let orbitFactor = 0.7 + 0.3 * sin(phase * 0.12)
            ball5Offset = CGSize(
                width: 2.4 * amplitudeFactor * sin(phase * 0.55 + 1.3) * orbitFactor,
                height: 2.3 * amplitudeFactor * cos(phase * 0.65 + 0.7) * orbitFactor
            )
            
            // 微妙的缩放变化，增强流体感，使用不同的节奏
            let scaleFactor: CGFloat = speedFactor > 1.0 ? 1.3 : 1.0
            
            // 缩放现在也有不同的模式
            ball1Scale = 1.0 + 0.08 * scaleFactor * (sin(phase * 0.3 + 0.5) * cos(phase * 0.07))
            ball2Scale = 1.0 + 0.07 * scaleFactor * sin(phase * 0.35 + 1.2 + patternShift * 0.4)
            ball3Scale = 1.0 + 0.06 * scaleFactor * (sin(phase * 0.4 + 2.1) + 0.2 * sin(phase * 0.18))
            ball4Scale = 1.0 + 0.05 * scaleFactor * (sin(phase * 0.45 + 0.8) * (1 + 0.3 * cyclePosition))
            ball5Scale = 1.0 + 0.04 * scaleFactor * smoothPulse(phase * 0.2)
        }
    }
    
    // 添加平滑脉冲函数，创造更自然的缩放效果
    private func smoothPulse(_ x: Double) -> CGFloat {
        let value = sin(x) * sin(x * 0.31) // 复合正弦，创造不规则脉冲
        return CGFloat(value)
    }
    
    // 启动彩球流体运动 - 替代原来的简单运动
    private func startFluidBallsMovement() {
        // 非常缓慢的整体旋转，增加深度感
        withAnimation(Animation.linear(duration: 60).repeatForever(autoreverses: false)) {
            ballsRotation = 360
        }
        
        // 初始化动画相位
        animationPhase = 0.0
        
        // 初始化流体运动
        updateFluidMovement()
    }
    
    // 启动螺旋动画
    private func startSpiralAnimation() {
        // 重置初始值
        currentTheta = 0
        spiralRotation = 0
        
        // 设置螺旋旋转动画 - 使用适中的旋转速度
        withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
            spiralRotation = 360
        }
        
        // 逐渐增加螺旋范围 - 加快展开速度，这里使用Timer而非重复创建多个Timer
        let expandSpiralTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
        
        // 先声明变量，避免循环引用问题
        var expandCancellable: AnyCancellable?
        
        expandCancellable = expandSpiralTimer.sink { _ in
            if !self.isGenerating {
                // 结束动画时取消计时器
                self.currentTheta = 0
                DispatchQueue.main.async {
                    expandCancellable?.cancel()
                }
                return
            }
            
            withAnimation(.linear(duration: 0.03)) {
                self.currentTheta += 0.2 // 从0.15增加到0.2，加快展开速度
                if self.currentTheta > self.maxAllowedTheta {
                    // 达到最大范围后停止
                    DispatchQueue.main.async {
                        expandCancellable?.cancel()
                    }
                }
            }
        }
        
        // 存储计时器引用以便稍后取消
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            expandCancellable?.cancel()
        }
    }
}

// 创建DisplayLink类，用于高效地更新UI
class DisplayLink: ObservableObject {
    struct FrameRateRange {
        var minimum: Int
        var maximum: Int
        var preferred: Int
        
        static let full = FrameRateRange(minimum: 10, maximum: 120, preferred: 60)
    }
    
    var onFrame: ((TimeInterval) -> Void)?
    var isPaused: Bool = false {
        didSet {
            if isPaused {
                displayLink?.invalidate()
                displayLink = nil
            } else if displayLink == nil {
                createDisplayLink()
            }
        }
    }
    
    private var displayLink: CADisplayLink?
    private var lastFrameTime: TimeInterval = 0
    private let preferredFrameRateRange: FrameRateRange
    
    init(preferredFrameRateRange: FrameRateRange = .full) {
        self.preferredFrameRateRange = preferredFrameRateRange
        createDisplayLink()
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func createDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleFrame))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(
            minimum: Float(preferredFrameRateRange.minimum),
            maximum: Float(preferredFrameRateRange.maximum),
            preferred: Float(preferredFrameRateRange.preferred)
        )
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func handleFrame(displayLink: CADisplayLink) {
        guard let onFrame = onFrame, !isPaused else { return }
        
        let timestamp = displayLink.timestamp
        let deltaTime = lastFrameTime == 0 ? 0 : timestamp - lastFrameTime
        lastFrameTime = timestamp
        
        onFrame(deltaTime)
    }
}

/**
 * 螺旋动画组件
 */
struct SpiralAnimation: View {
    let currentTheta: CGFloat
    let baseRadius: CGFloat
    let colors: [Color]
    let opacity: CGFloat
    
    // 添加时间状态以实现更流畅的动画
    @State private var animationTime: Double = 0
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
            Canvas { context, size in
                // 移除未使用的变量，用_忽略
                _ = timeline.date.timeIntervalSince1970
                
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) / 2
                
                // 绘制中心光点
                let centerGlowSize: CGFloat = 8
                let centerGlow = Path(ellipseIn: CGRect(
                    x: center.x - centerGlowSize/2,
                    y: center.y - centerGlowSize/2,
                    width: centerGlowSize,
                    height: centerGlowSize
                ))
                
                // 使用固定颜色创建中心光晕
                let centerGlowColor = colors[0]
                
                context.fill(centerGlow, with: .color(centerGlowColor.opacity(0.8 * opacity)))
                
                // 绘制光环 - 降低不透明度以减少背景色变化
                for ring in 1...2 {
                    let ringSize = CGFloat(ring * 6)
                    let ringPath = Path(ellipseIn: CGRect(
                        x: center.x - ringSize,
                        y: center.y - ringSize,
                        width: ringSize * 2,
                        height: ringSize * 2
                    ))
                    
                    let ringColor = colors[ring % colors.count]
                    
                    context.drawLayer { ctx in
                        ctx.addFilter(.blur(radius: 1 + CGFloat(ring)))
                        ctx.stroke(ringPath, with: .color(ringColor.opacity(0.08)), lineWidth: 0.5) // 降低不透明度
                    }
                }
                
                // 绘制螺旋 - 增大点的大小和密度
                var theta: CGFloat = 0
                while theta < currentTheta {
                    let r = baseRadius * theta
                    // 不使用x和y变量，直接在绘制位置计算坐标
                    
                    // 计算颜色索引
                    let colorPosition = (theta / currentTheta) * CGFloat(colors.count - 1)
                    let colorIndex1 = Int(colorPosition)
                    let colorIndex2 = (colorIndex1 + 1) % colors.count
                    let colorFraction = colorPosition - CGFloat(colorIndex1)
                    
                    let color1 = colors[colorIndex1]
                    let color2 = colors[colorIndex2]
                    
                    // 混合两种颜色创建平滑渐变
                    let blendedColor = blendColors(color1, color2, fraction: colorFraction)
                    
                    // 计算点的大小 - 增大点的尺寸
                    let distanceFactor = min(1, r / (baseRadius * maxAllowedTheta * 0.8))
                    let pointSize: CGFloat = 3.5 * (1.0 - distanceFactor * 0.3) // 从3.0增大到3.5
                    
                    // 添加轨迹尾巴效果
                    let trailLength = 3
                    for i in 0..<trailLength {
                        let trailOpacity = (1.0 - CGFloat(i) / CGFloat(trailLength)) * 0.8
                        let trailSize = pointSize * (1.0 - CGFloat(i) * 0.15)
                        
                        // 计算尾巴位置
                        let trailTheta = max(0, theta - CGFloat(i) * 0.15)
                        let trailR = baseRadius * trailTheta
                        let trailX = cos(trailTheta) * trailR * maxRadius / 10 + center.x
                        let trailY = sin(trailTheta) * trailR * maxRadius / 10 + center.y
                        
                        // 绘制尾巴点
                        let trailPath = Path(ellipseIn: CGRect(
                            x: trailX - trailSize/2,
                            y: trailY - trailSize/2,
                            width: trailSize,
                            height: trailSize
                        ))
                        
                        // 使用模糊效果增强视觉效果
                        if i > 0 {
                            context.drawLayer { ctx in
                                ctx.addFilter(.blur(radius: CGFloat(i) * 0.8))
                                ctx.fill(trailPath, with: .color(blendedColor.opacity(opacity * trailOpacity)))
                            }
                        } else {
                            // 主点不模糊，保持锐利
                            context.fill(trailPath, with: .color(blendedColor.opacity(opacity)))
                        }
                    }
                    
                    // 计算下一个点 - 减小步长使点更密集
                    let arcStep: CGFloat = 0.25 // 从0.3减小到0.25，使点更密集
                    let angleStep = arcStep / sqrt(r * r + baseRadius * baseRadius)
                    theta += angleStep
                }
                
                // 添加整体光晕效果 - 降低不透明度
                let glowPath = Path(ellipseIn: CGRect(
                    x: center.x - maxRadius * 0.8,
                    y: center.y - maxRadius * 0.8,
                    width: maxRadius * 1.6,
                    height: maxRadius * 1.6
                ))
                
                context.drawLayer { ctx in
                    ctx.addFilter(.blur(radius: 8))
                    ctx.fill(glowPath, with: .color(colors[0].opacity(0.05 * opacity))) // 降低不透明度
                }
            }
            .onAppear {
                // 在视图加载时设置初始动画时间
                animationTime = timeline.date.timeIntervalSince1970
            }
            .onChange(of: timeline.date) { _, newDate in
                // 🚀 性能优化：降低更新频率，减少性能开销
                let newTime = newDate.timeIntervalSince1970
                if abs(newTime - animationTime) > 0.1 { // 降低到10fps
                    animationTime = newTime
                }
            }
        }
        .clipShape(Circle()) // 确保内容不超出圆形边界
    }
    
    // 螺旋参数
    private let maxAllowedTheta: CGFloat = 20 // 从15增大到20，与上面保持一致
    
    // 颜色混合函数
    private func blendColors(_ color1: Color, _ color2: Color, fraction: CGFloat) -> Color {
        // 使用UIColor进行颜色混合
        guard let uiColor1 = UIColor(color1).cgColor.components,
              let uiColor2 = UIColor(color2).cgColor.components else {
            return color1
        }
        
        // 混合RGB分量
        let r = uiColor1[0] + (uiColor2[0] - uiColor1[0]) * fraction
        let g = uiColor1[1] + (uiColor2[1] - uiColor1[1]) * fraction
        let b = uiColor1[2] + (uiColor2[2] - uiColor1[2]) * fraction
        let a = uiColor1[3] + (uiColor2[3] - uiColor1[3]) * fraction
        
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

/**
 * 缩放按钮样式
 */
struct CosmicScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Circle())
    }
}

/**
 * 预览提供者
 */
struct CosmicGenerateButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            CosmicGenerateButton(isGenerating: .constant(false)) {
                print("宇宙按钮被点击")
            }
        }
    }
} 