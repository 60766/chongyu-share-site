import SwiftUI
import CoreHaptics
import UIKit
// 导入AppLauncher
import Foundation

// 在主应用启动时设置自定义图标
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 设置自定义Tab图标
        UITabBar.appearance().tintColor = UIColor(red: 0.45, green: 0.45, blue: 0.95, alpha: 1.0)
        
        // 彻底移除底部白色背景 - 设置窗口背景为透明
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.backgroundColor = .clear
                window.rootViewController?.view.backgroundColor = .clear
            }
        }
        
        // 全局设置TabBar为透明
        UITabBar.appearance().backgroundColor = .clear
        UITabBar.appearance().barTintColor = .clear
        UITabBar.appearance().isTranslucent = true
        
        // 调用AppLauncher执行启动任务（添加延迟确保初始化完成）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let appLauncherClass = NSClassFromString("AppLauncher") as? NSObject.Type {
                _ = appLauncherClass.perform(NSSelectorFromString("onAppLaunch"))
            } else {
                print("⚠️ 无法找到AppLauncher类")
            }
        }
        
        return true
    }
}

/**
 * 底部导航栏图标类型
 */
enum CosmicIconType {
    case wormholeEntry      // 虫洞入口（首页）
    case cosmicExplorer     // 宇宙探索者（探索）
    case pulsarSignal       // 脉冲星信号（通知）
    case cosmicIdentity     // 宇宙身份（个人空间）
    
    // 获取对应的系统图标名称 - 参考图二的图标，保留图一的风格
    var systemIcon: String {
        switch self {
        case .wormholeEntry: return "circle.fill" // 虫遇/首页，圆形图标
        case .cosmicExplorer: return "magnifyingglass.circle" // 探索，使用圆形放大镜图标
        case .pulsarSignal: return "sparkles" // 动态，使用星尘图标
        case .cosmicIdentity: return "person.circle.fill" // 空间，使用宇航员风格图标（人物圆形），更加宇宙感
        }
    }
    
    // 获取图标的主色调 - 统一使用蓝紫色系，类似图二
    var primaryTint: Color {
        // 使用图二中的蓝紫色调
        return Color(red: 0.45, green: 0.45, blue: 0.95)  // 蓝紫色
    }
    
    // 获取图标的辅助色调
    var secondaryTint: Color {
        return Color(red: 0.6, green: 0.6, blue: 1.0)   // 浅蓝紫色
    }
    
    // 获取图标标题 - 使用图一的文字
    var title: String {
        switch self {
        case .wormholeEntry: return "虫遇"
        case .cosmicExplorer: return "探索"
        case .pulsarSignal: return "动态"
        case .cosmicIdentity: return "空间"
        }
    }
    
    // 获取自定义图片名称
    var customImageName: String? {
        switch self {
        case .wormholeEntry: return "wormhole_entry"
        case .cosmicExplorer: return "cosmic_explorer"
        case .pulsarSignal: return "pulsar_signal"
        case .cosmicIdentity: return "cosmic_identity"
        }
    }
}

/**
 * 标签项视图
 * 用于简化 TabView 中的标签项定义
 */
private struct TabItemView: View {
    let title: String
    let iconName: String
    
    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: iconName)
        }
    }
}

/**
 * 主标签视图
 * 应用的主要导航结构
 */
struct CosmicTabView: View {
    /// 当前选中的标签索引
    @State private var selectedTab = 0
    /// 是否显示发布页面
    @State private var showPublishView = false
    /// 按钮动画状态
    @State private var isButtonPressed = false
    /// 按钮旋转动画
    @State private var rotationAngle = 0.0
    /// 虫洞漩涡动画
    @State private var wormholePhase = 0.0
    /// 粒子系统动画
    @State private var particlePhase = 0.0
    /// 用于存储上一次选中的标签索引
    @State private var previousTab = 0
    /// 性能模式 - 设备性能较低时为true
    @State private var isLowPerformanceMode = false
    /// 触觉引擎
    @State private var hapticEngine: CHHapticEngine?
    /// 显示快捷发布菜单
    @State private var showQuickPublishMenu = false
    /// 快捷发布类型
    @State private var selectedPublishType: PublishOption?
    
    // 环境值读取设备性能配置
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorScheme) var colorScheme
    
    // 发布选项
    let publishOptions: [PublishOption] = [.text, .image, .voice, .story]
    
    // 动画状态
    @State private var rotationDegrees: Double = 0
    @State private var glowOpacity: Double = 0.5
    @State private var stardustOpacity: Double = 0.8
    @State private var isAnimating: Bool = false
    @State private var orbitPhase: Double = 0
    @State private var pulsePhase: Double = 0
    @State private var starPhase: Double = 0
    
    // 动画定时器
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // 首页标签 - 星系主界面
                HomeView()
                    .tag(0)
                    .tabItem {
                        TabItemView(title: "虫遇", iconName: "circle.fill")
                    }
                
                // 探索页标签 - 星际探索
                ExploreView()
                    .tag(1)
                    .tabItem {
                        TabItemView(title: "探索", iconName: "magnifyingglass.circle")
                    }
                
                // 发布标签（占位，实际点击事件由中间的大按钮处理）
                Color.clear
                    .tag(2)
                    .tabItem {
                        TabItemView(title: "发布", iconName: "plus")
                    }
                
                // 通知页面标签 - 时空脉动
                NotificationView()
                    .tag(3)
                    .tabItem {
                        TabItemView(title: "动态", iconName: "sparkles")
                    }
                
                // 个人资料标签 - 星际身份
                ProfileView()
                    .tag(4)
                    .tabItem {
                        TabItemView(title: "空间", iconName: "person.circle")
                    }
            }
            .accentColor(Color(red: 0.45, green: 0.45, blue: 0.95)) // 蓝紫色
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabChange(oldValue: oldValue, newValue: newValue)
            }
            
            // 虫洞发布按钮区域
            ZStack {
                // 快捷发布选项菜单
                if showQuickPublishMenu {
                    quickPublishMenu
                }
                
                // 虫洞发布按钮
                Button(action: {
                    handleWormholeButtonTap()
                }) {
                    // 虫洞按钮设计
                    ZStack {
                        // 根据设备可访问性和性能选择不同复杂度的按钮样式
                        if reduceMotion || isLowPerformanceMode {
                            // 简化版本的按钮（静态版本）
                            simplifiedWormholeButton
                        } else {
                            // 完整版虫洞按钮
                            fullWormholeButton
                        }
                    }
                    .scaleEffect(isButtonPressed ? 0.9 : 1)
                    .accessibilityLabel("发布内容")
                    .accessibilityHint("轻触创建新内容，长按查看更多选项")
                    .accessibilityAddTraits(.isButton)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, -10) // 向上移动按钮位置
                .shadow(color: colorScheme == .dark ? Color.purple.opacity(0.3) : Color.black.opacity(0.2), 
                        radius: 10, x: 0, y: 4)
                // 启动周期性动画
                .onAppear {
                    setupOnAppear()
                }
                // 支持长按手势
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            // 长按展示快捷发布选项
                            showQuickPublishOptions()
                        }
                )
            }
            .zIndex(1) // 确保发布按钮和菜单始终在顶层
        }
        .sheet(isPresented: $showPublishView) {
            if let publishType = selectedPublishType {
                // 这里需要在PublishView中添加一个构造函数来接收PublishOption类型参数
                // 并将其转换为PublishView需要的类型
                PublishView(publishType: convertToViewPublishType(publishType))
            } else {
                PublishView()
            }
        }
        .onChange(of: showPublishView) { oldValue, newValue in
            if !newValue {
                // 当发布视图关闭时，重置选择的发布类型
                selectedPublishType = nil
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.016)) {
                updateAnimationPhases()
                
                // 呼吸动画 - 使用多个正弦波叠加
                let baseGlow = 0.5
                let glowVariation = calculateGlowVariation()
                glowOpacity = baseGlow + glowVariation
                
                // 星尘透明度 - 使用余弦波
                let baseStardust = 0.8
                let stardustVariation = calculateStardustVariation()
                stardustOpacity = baseStardust + stardustVariation
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
    
    // 处理标签页切换
    private func handleTabChange(oldValue: Int, newValue: Int) {
        if newValue == 2 {
            // 立即重置为之前的选中标签，因为中间的发布标签只是占位
            selectedTab = oldValue == 2 ? previousTab : oldValue
            previousTab = selectedTab
            // 显示发布页面
            if !showQuickPublishMenu {
                showPublishView = true
            }
        } else {
            // 记录当前标签，用于保持导航状态
            previousTab = newValue
        }
    }
    
    // 计算发光变化
    private func calculateGlowVariation() -> Double {
        let sinRotation = sin(rotationDegrees * .pi / 180) * 0.2
        let sinPulse = sin(pulsePhase * .pi / 180) * 0.1
        let cosOrbit = cos(orbitPhase * .pi / 180) * 0.15
        
        return sinRotation + sinPulse + cosOrbit
    }
    
    // 计算星尘变化
    private func calculateStardustVariation() -> Double {
        let cosStarPhase = cos(starPhase * .pi / 180) * 0.1
        let sinPulsePhase = sin(pulsePhase * .pi / 180) * 0.05
        
        return cosStarPhase + sinPulsePhase
    }
    
    // 更新动画相位
    private func updateAnimationPhases() {
        // 主旋转
        rotationDegrees += 0.3
        if rotationDegrees >= 360 {
            rotationDegrees = 0
        }
        
        // 更新各种相位
        updateOrbitPhase()
        updatePulsePhase()
        updateStarPhase()
    }
    
    // 更新轨道相位
    private func updateOrbitPhase() {
        orbitPhase += 0.2
        if orbitPhase >= 360 {
            orbitPhase = 0
        }
    }
    
    // 更新脉冲相位
    private func updatePulsePhase() {
        pulsePhase += 0.15
        if pulsePhase >= 360 {
            pulsePhase = 0
        }
    }
    
    // 更新星体相位
    private func updateStarPhase() {
        starPhase += 0.25
        if starPhase >= 360 {
            starPhase = 0
        }
    }
    
    // 快捷发布菜单
    private var quickPublishMenu: some View {
        ZStack {
            // 背景蒙版
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring()) {
                        showQuickPublishMenu = false
                    }
                }
            
            // 菜单内容
            VStack(spacing: 20) {
                Text("创建内容")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 30) {
                    ForEach(publishOptions) { option in
                        VStack {
            Button(action: {
                                selectedPublishType = option
                                showQuickPublishMenu = false
                showPublishView = true
            }) {
                                ZStack {
                                    Circle()
                                        .fill(option.color.opacity(0.8))
                                        .frame(width: 60, height: 60)
                                        .shadow(color: option.color.opacity(0.5), radius: 5, x: 0, y: 2)
                                    
                                    Image(systemName: option.iconName)
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(option.title)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 10)
                
                Button(action: {
                    withAnimation(.spring()) {
                        showQuickPublishMenu = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 25)
            .background(
                CosmicBlurView(style: .systemUltraThinMaterialDark)
            )
            .padding(.bottom, 100)
        }
        .transition(.opacity)
    }
    
    // 将PublishOption转换为PublishView所需的PublishType
    private func convertToViewPublishType(_ option: PublishOption) -> PublishType {
        return PublishType(
            title: option.title,
            iconName: option.iconName,
            color: option.color
        )
    }
    
    // 完整版虫洞按钮 - 参考图片的设计风格
    private var fullWormholeButton: some View {
        ZStack {
            // 主背景
            wormholeBackground
            
            // 外部虚线环
            wormholeOuterRing
            
            // 内部虚线环
            wormholeInnerRing
            
            // 中央白色圆点
            wormholeCenterDot
            
            // 外部小圆点
            wormholeOrbitingDots
        }
        .frame(width: 70, height: 70)
    }
    
    // 虫洞背景
    private var wormholeBackground: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.purple.opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 64, height: 64)
            .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 2)
    }
    
    // 外部虚线环
    private var wormholeOuterRing: some View {
        Circle()
            .stroke(
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: [3, 6]
                )
            )
            .foregroundColor(Color.white.opacity(0.7))
            .frame(width: 60, height: 60)
            .rotationEffect(.degrees(particlePhase * 40))
    }
    
    // 内部虚线环
    private var wormholeInnerRing: some View {
        Circle()
            .stroke(
                style: StrokeStyle(
                    lineWidth: 1.5,
                    lineCap: .round,
                    dash: [2, 5]
                )
            )
            .foregroundColor(Color.white.opacity(0.5))
            .frame(width: 46, height: 46)
            .rotationEffect(.degrees(-particlePhase * 30))
    }
    
    // 中央白色圆点
    private var wormholeCenterDot: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 16, height: 16)
            .shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 0)
    }
    
    // 外部小圆点
    private var wormholeOrbitingDots: some View {
        ZStack {
            // 小圆点
            ForEach(0..<4) { i in
                createOrbitingDot(index: i)
            }
            
            // 连接线
            ForEach(0..<4) { i in
                createConnectingLine(index: i)
            }
        }
    }
    
    // 创建连接线
    private func createConnectingLine(index: Int) -> some View {
        let angle = Double.pi * 2 * (Double(index) / 4.0 + particlePhase)
        let centerX = 0
        let centerY = 0
        let endX = cos(angle) * 28
        let endY = sin(angle) * 28
        
        return Path { path in
            path.move(to: CGPoint(x: centerX, y: centerY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(
            createConnectingLineGradient(),
            lineWidth: 1
        )
    }
    
    // 创建连接线渐变
    private func createConnectingLineGradient() -> LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.8),
                Color.white.opacity(0.1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // 创建轨道小圆点
    private func createOrbitingDot(index: Int) -> some View {
        let angle = Double.pi * 2 * (Double(index) / 4.0 + particlePhase)
        let xOffset = cos(angle) * 28
        let yOffset = sin(angle) * 28
        
        return Circle()
            .fill(Color.white)
            .frame(width: 4, height: 4)
            .offset(x: xOffset, y: yOffset)
            .shadow(color: .white.opacity(0.6), radius: 2, x: 0, y: 0)
    }
    
    // 简化版虫洞按钮 - 为低性能设备和可访问性设计
    private var simplifiedWormholeButton: some View {
        ZStack {
            // 简化的背景
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                
            // 外部虚线环 - 简化版
            Circle()
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        dash: [3, 6]
                    )
                )
                .foregroundColor(Color.white.opacity(0.7))
                .frame(width: 56, height: 56)
                
            // 中央白色圆点
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                
            // 简化的辐射线
            ForEach(0..<4) { i in
                let _ = Double.pi * 2 * (Double(i) / 4.0)
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 10, height: 1.5)
                    .offset(x: 14, y: 0)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .frame(width: 70, height: 70)
    }
    
    // 检测设备性能
    private func checkDevicePerformance() {
        // 这里可以添加更复杂的性能检测逻辑
        // 简单示例：检查设备型号或iOS版本
        #if targetEnvironment(simulator)
            isLowPerformanceMode = false
        #else
            // 根据设备处理能力决定是否启用低性能模式
            let thermalState = ProcessInfo.processInfo.thermalState
            isLowPerformanceMode = (thermalState == .serious || thermalState == .critical)
        #endif
    }
    
    // 准备触觉反馈
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("触觉引擎启动失败: \(error.localizedDescription)")
        }
    }
    
    // 触发触觉反馈
    private func triggerHapticFeedback() {
        // 基本触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 高级触觉反馈 (iOS 13+)
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else { return }
        
        // 创建高级触觉模式
        var events = [CHHapticEvent]()
        
        // 初始短促的触感
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        // 转动感触觉
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        let event2 = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity2, sharpness2], relativeTime: 0.1, duration: 0.15)
        events.append(event2)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("触觉播放失败: \(error.localizedDescription)")
        }
    }
    
    // 显示快捷发布选项
    private func showQuickPublishOptions() {
        withAnimation(.spring()) {
            showQuickPublishMenu = true
        }
        
        // 触发成功触觉反馈
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    // 处理虫洞按钮点击
    private func handleWormholeButtonTap() {
        // 触发触觉反馈
        triggerHapticFeedback()
        
        // 添加虫洞旋转效果动画
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isButtonPressed = true
            rotationAngle += 360
            wormholePhase += 1.0
        }
        
        // 延迟执行以显示动画效果，优化为0.3秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !showQuickPublishMenu {
                showPublishView = true
            }
            
            // 重置按钮状态
            withAnimation {
                isButtonPressed = false
            }
        }
    }
    
    // 设置出现时的初始化
    private func setupOnAppear() {
        // 检测设备性能
        checkDevicePerformance()
        // 初始化触觉引擎
        prepareHaptics()
        
        setupAnimations()
        setupTabBarAppearance()
    }
    
    // 设置动画
    private func setupAnimations() {
        if !reduceMotion && !isLowPerformanceMode {
            // 创建平滑循环动画
            withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotationAngle = 360
                particlePhase = 1.0
            }
            
            // 脉动效果
            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                wormholePhase = 0.5
            }
        }
    }
    
    // 设置标签栏外观
    private func setupTabBarAppearance() {
        // 设置tabBar的外观
        let appearance = UITabBarAppearance()
        
        // 使用自定义背景配置，而不是默认背景
        appearance.configureWithTransparentBackground()
        
        // 添加自定义模糊效果
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundEffect = blur
        
        // 设置背景色透明
        appearance.backgroundColor = UIColor.clear
        
        // 设置全局不透明度，使整个Tab Bar更透明
        if #available(iOS 15.0, *) {
            // appearance.backgroundEffectOpacity = 0.25 // 降低模糊效果的不透明度
            // 备注：iOS 17使用自定义视图实现更高透明度效果
            UITabBar.appearance().alpha = 0.95 // 使用全局alpha实现类似效果
        }
        
        // 设置颜色属性
        let normalAttributes = createTabBarAttributes(isSelected: false)
        let selectedAttributes = createTabBarAttributes(isSelected: true)
        
        // 应用颜色设置
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        // 应用设置到UITabBar
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // 确保移除底部边框
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
    }
    
    // 创建标签栏文本属性
    private func createTabBarAttributes(isSelected: Bool) -> [NSAttributedString.Key: Any] {
        if isSelected {
            return [
                .foregroundColor: UIColor(red: 0.45, green: 0.45, blue: 0.95, alpha: 1.0)
            ]
        } else {
            return [
                .foregroundColor: UIColor.gray.withAlphaComponent(0.8)
            ]
        }
    }
}

// 半透明背景模糊视图
struct CosmicBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/**
 * 发布选项类型
 * 用于MainTabView中显示的发布选项
 */
struct PublishOption: Identifiable {
    var id = UUID()
    var title: String
    var iconName: String
    var color: Color
    
    static let text = PublishOption(title: "文字", iconName: "text.bubble.fill", color: .blue)
    static let image = PublishOption(title: "图片", iconName: "photo.fill", color: .green)
    static let voice = PublishOption(title: "语音", iconName: "mic.fill", color: .purple)
    static let story = PublishOption(title: "故事", iconName: "book.fill", color: .orange)
}

/**
 * 虫洞粒子背景视图
 * 模拟星空和宇宙微粒
 * 优化版本，支持性能调整
 */
struct WormholeParticlesView: View {
    var phase: Double
    var particleCount: Int = 35  // 可调整粒子数量以适应不同性能的设备
    
    var body: some View {
        Canvas { context, size in
            // 绘制星空背景
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "0c164f"), Color(hex: "1a1b46"), Color(hex: "0c164f")]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
            
            // 绘制星星 - 数量根据性能调整
            let starCount = min(particleCount, 35)
            for _ in 0..<starCount {
                let position = CGPoint(
                    x: size.width * CGFloat.random(in: 0...1),
                    y: size.height * CGFloat.random(in: 0...1)
                )
                
                let starSize = CGFloat.random(in: 1...2.5)
                let opacity = CGFloat.random(in: 0.3...1.0)
                
                context.opacity = opacity
                context.fill(
                    Path(ellipseIn: CGRect(x: position.x, y: position.y, width: starSize, height: starSize)),
                    with: .color(.white)
                )
            }
            
            // 绘制时空粒子流 - 数量根据性能调整
            let particleFlowCount = min(particleCount / 2, 20)
            for i in 0..<particleFlowCount {
                let progress = (CGFloat(i) / CGFloat(particleFlowCount)) + CGFloat(phase).truncatingRemainder(dividingBy: 1.0)
                let radian = progress * 2 * .pi * 3
                
                let distance = progress * size.width * 0.3
                let xPos = size.width / 2 + cos(radian) * distance
                let yPos = size.height / 2 + sin(radian) * distance
                
                let particleSize = (1.0 - progress) * 3
                let alpha = (1.0 - progress) * 0.7
                
                let colorIndex = i % 3
                let color = [Color.blue, Color.purple, Color.cyan][colorIndex]
                
                context.opacity = alpha
                context.fill(
                    Path(ellipseIn: CGRect(x: xPos, y: yPos, width: particleSize, height: particleSize)),
                    with: .color(color)
                )
            }
        }
    }
}

/**
 * 虫洞漩涡视图
 * 模拟深邃的虫洞效果
 * 优化版本，提升性能和代码可读性
 */
struct WormholeView: View {
    var phase: Double
    
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2
            
            // 绘制深邃背景
            context.fill(
                Path(ellipseIn: CGRect(origin: .zero, size: size)),
                with: .color(Color(hex: "070b27"))
            )
            
            // 绘制螺旋漩涡 - 优化版本
            for i in 1...8 {
                let iFloat: CGFloat = CGFloat(i)
                let radiusStep: CGFloat = maxRadius / 8
                let radius: CGFloat = maxRadius - radiusStep * (iFloat - 1)
                let spiralPath = Path { path in
                    path.move(to: center)
                    
                    // 减少点数量以提高性能
                    for angle in stride(from: 0, to: 2 * .pi, by: 0.2) {
                        let phaseAngle: CGFloat = CGFloat(phase) * 2 * .pi
                        let adjustedAngle: CGFloat = angle + phaseAngle
                        let spiralFactor: CGFloat = 1.0 - (iFloat / 16.0)
                        let spiralRadius: CGFloat = radius * spiralFactor
                        let xOffset: CGFloat = cos(adjustedAngle) * spiralRadius
                        let yOffset: CGFloat = sin(adjustedAngle) * spiralRadius
                        let x: CGFloat = center.x + xOffset
                        let y: CGFloat = center.y + yOffset
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                let opacity = 1.0 - Double(i) / 8.0
                context.opacity = opacity
                
                // 使用渐变色
                let color1 = i % 2 == 0 ? Color.blue : Color.purple
                let color2 = i % 2 == 0 ? Color.purple : Color.blue
                
                let lineWidthBase: CGFloat = 1.5
                let lineWidthAdjustment: CGFloat = CGFloat(i) * 0.15
                let finalLineWidth: CGFloat = lineWidthBase - lineWidthAdjustment
                
                context.stroke(
                    spiralPath,
                    with: .linearGradient(
                        Gradient(colors: [color1.opacity(0.7), color2.opacity(0.3)]),
                        startPoint: CGPoint(x: center.x - radius, y: center.y - radius),
                        endPoint: CGPoint(x: center.x + radius, y: center.y + radius)
                    ),
                    lineWidth: finalLineWidth
                )
            }
            
            // 绘制中心光点
            context.opacity = 0.9
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)),
                with: .color(.white)
            )
            context.opacity = 0.7
            context.blendMode = .screen
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)),
                with: .color(.blue)
            )
        }
    }
}

/**
 * 主标签视图预览
 */
struct CosmicTabView_Previews: PreviewProvider {
    static var previews: some View {
        CosmicTabView()
    }
} 

/**
 * 宇宙主题图标视图
 * 简约风格，使用基本形状确保兼容性
 */
struct CosmicIconView: View {
    let iconType: CosmicIconType
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // 图标容器
            ZStack {
                // 使用简单的形状和SF Symbols组合
                switch iconType {
                case .wormholeEntry:
                    // 虫遇图标 - 圆点和环
                    ZStack {
                        // 主圆
                        Circle()
                            .fill(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8))
                            .frame(width: 20, height: 20)
                        
                        // 外环
                        Circle()
                            .stroke(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                            .frame(width: 30, height: 30)
                    }
                case .cosmicExplorer:
                    // 探索图标 - 自定义放大镜
                    ZStack {
                        // 镜面圆环
                        Circle()
                            .stroke(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8), lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        
                        // 十字线
                        Group {
                            Rectangle()
                                .fill(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8))
                                .frame(width: 1.5, height: 8)
                            
                            Rectangle()
                                .fill(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8))
                                .frame(width: 8, height: 1.5)
                        }
                        .offset(y: -1)
                        
                        // 手柄
                        Rectangle()
                            .fill(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8))
                            .frame(width: 1.5, height: 10)
                            .rotationEffect(Angle(degrees: 45))
                            .offset(x: 6, y: 6)
                    }
                case .pulsarSignal:
                    // 动态图标 - 星形
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8))
                case .cosmicIdentity:
                    // 空间图标 - 宇航员
                    ZStack {
                        // 头盔
                        Circle()
                            .stroke(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                        
                        // 面具
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8))
                    }
                }
            }
            .frame(width: 30, height: 30)
            
            // 标题文字
            Text(iconType.title)
                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? iconType.primaryTint : Color.gray.opacity(0.8))
        }
        .frame(width: 60)
    }
}

// 自定义绘制的图标组件
struct CustomDrawnIcon: View {
    enum IconType {
        case wormholeEntry  // 虫遇图标
        case explore        // 探索图标
        case dynamic        // 动态图标
        case space          // 空间图标
    }
    
    let type: IconType
    let color: Color
    let size: CGFloat
    
    init(type: IconType, color: Color = .blue, size: CGFloat = 24) {
        self.type = type
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            // 计算中心点和缩放因子
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let scale = min(canvasSize.width, canvasSize.height) / 30
            
            context.blendMode = .normal
            
            switch type {
            case .wormholeEntry:
                // 虫遇图标 - 参考图2的设计，环绕中心点的多个圆圈
                drawWormholeIcon(context: context, center: center, scale: scale)
            case .explore:
                // 探索图标 - 放大镜形状
                drawExploreIcon(context: context, center: center, scale: scale)
            case .dynamic:
                // 动态图标 - 类似闪光星状
                drawDynamicIcon(context: context, center: center, scale: scale)
            case .space:
                // 空间图标 - 宇航员风格
                drawSpaceIcon(context: context, center: center, scale: scale)
            }
        }
        .frame(width: size, height: size)
    }
    
    // 绘制虫遇图标 - 参考图2的设计，环绕中心点的圆环
    private func drawWormholeIcon(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        // 绘制中心大圆
        let centerCirclePath = Path(ellipseIn: CGRect(
            x: center.x - 4 * scale,
            y: center.y - 4 * scale,
            width: 8 * scale,
            height: 8 * scale
        ))
        context.fill(centerCirclePath, with: .color(color))
        
        // 绘制三个虚线环
        for i in 0..<3 {
            let radius = (8 + 4 * CGFloat(i)) * scale
            let dashPath = Path { path in
                path.addEllipse(in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            }
            
            // 使用虚线样式
            let dashStyle = StrokeStyle(
                lineWidth: 1.0 * scale,
                lineCap: .round,
                lineJoin: .round,
                dash: [2 * scale, 3 * scale],
                dashPhase: CGFloat(i) * 2
            )
            
            context.stroke(dashPath, with: .color(color.opacity(0.8 - Double(i) * 0.2)), style: dashStyle)
        }
        
        // 周围的小圆点
        let smallDotsCount = 4
        for i in 0..<smallDotsCount {
            let angle = CGFloat(i) * .pi * 2 / CGFloat(smallDotsCount)
            let distance = 12 * scale
            let x = center.x + cos(angle) * distance
            let y = center.y + sin(angle) * distance
            
            let dotSize = 2.5 * scale
            let dotPath = Path(ellipseIn: CGRect(
                x: x - dotSize/2,
                y: y - dotSize/2,
                width: dotSize,
                height: dotSize
            ))
            
            context.fill(dotPath, with: .color(color))
        }
    }
    
    // 绘制探索图标 - 放大镜形状
    private func drawExploreIcon(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        // 绘制放大镜圆环
        let circlePath = Path(ellipseIn: CGRect(
            x: center.x - 7 * scale,
            y: center.y - 7 * scale,
            width: 14 * scale,
            height: 14 * scale
        ))
        context.stroke(circlePath, with: .color(color), lineWidth: 2 * scale)
        
        // 绘制放大镜手柄
        var handlePath = Path()
        let startX = center.x + 5 * scale
        let startY = center.y + 5 * scale
        let endX = center.x + 10 * scale
        let endY = center.y + 10 * scale
        
        handlePath.move(to: CGPoint(x: startX, y: startY))
        handlePath.addLine(to: CGPoint(x: endX, y: endY))
        context.stroke(handlePath, with: .color(color), lineWidth: 2 * scale)
        
        // 放大镜内部十字线
        var crossPath1 = Path()
        crossPath1.move(to: CGPoint(x: center.x, y: center.y - 4 * scale))
        crossPath1.addLine(to: CGPoint(x: center.x, y: center.y + 4 * scale))
        
        var crossPath2 = Path()
        crossPath2.move(to: CGPoint(x: center.x - 4 * scale, y: center.y))
        crossPath2.addLine(to: CGPoint(x: center.x + 4 * scale, y: center.y))
        
        context.stroke(crossPath1, with: .color(color), lineWidth: scale)
        context.stroke(crossPath2, with: .color(color), lineWidth: scale)
    }
    
    // 绘制动态图标 - 闪光星状
    private func drawDynamicIcon(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        // 中心圆
        let centerCirclePath = Path(ellipseIn: CGRect(
            x: center.x - 3 * scale,
            y: center.y - 3 * scale,
            width: 6 * scale,
            height: 6 * scale
        ))
        context.fill(centerCirclePath, with: .color(color))
        
        // 发散的小光点/短线
        let rays = 8
        for i in 0..<rays {
            let angle = CGFloat(i) * .pi * 2 / CGFloat(rays)
            let innerDistance = 6 * scale
            let outerDistance = 10 * scale
            
            let innerX = center.x + cos(angle) * innerDistance
            let innerY = center.y + sin(angle) * innerDistance
            let outerX = center.x + cos(angle) * outerDistance
            let outerY = center.y + sin(angle) * outerDistance
            
            // 光线
            var rayPath = Path()
            rayPath.move(to: CGPoint(x: innerX, y: innerY))
            rayPath.addLine(to: CGPoint(x: outerX, y: outerY))
            
            context.stroke(rayPath, with: .color(color), lineWidth: 1.5 * scale)
            
            // 在交替的射线端点添加小圆点
            if i % 2 == 0 {
                let dotPath = Path(ellipseIn: CGRect(
                    x: outerX - 1.5 * scale,
                    y: outerY - 1.5 * scale,
                    width: 3 * scale,
                    height: 3 * scale
                ))
                context.fill(dotPath, with: .color(color))
            }
        }
    }
    
    // 绘制空间图标 - 宇航员风格
    private func drawSpaceIcon(context: GraphicsContext, center: CGPoint, scale: CGFloat) {
        // 绘制头盔圆形轮廓
        let headPath = Path(ellipseIn: CGRect(
            x: center.x - 6 * scale,
            y: center.y - 8 * scale,
            width: 12 * scale,
            height: 12 * scale
        ))
        context.stroke(headPath, with: .color(color), lineWidth: 1.5 * scale)
        
        // 绘制头盔面部区域
        let facePath = Path(ellipseIn: CGRect(
            x: center.x - 4 * scale,
            y: center.y - 6 * scale,
            width: 8 * scale,
            height: 8 * scale
        ))
        context.stroke(facePath, with: .color(color), lineWidth: scale)
        
        // 绘制宇航员身体部分
        var bodyPath = Path()
        bodyPath.move(to: CGPoint(x: center.x - 5 * scale, y: center.y + 4 * scale))
        bodyPath.addCurve(
            to: CGPoint(x: center.x + 5 * scale, y: center.y + 4 * scale),
            control1: CGPoint(x: center.x - 3 * scale, y: center.y + 7 * scale),
            control2: CGPoint(x: center.x + 3 * scale, y: center.y + 7 * scale)
        )
        
        context.stroke(bodyPath, with: .color(color), lineWidth: 1.5 * scale)
        
        // 添加太空人的背包/推进器
        var backpackPath = Path()
        backpackPath.move(to: CGPoint(x: center.x - 2 * scale, y: center.y + 4 * scale))
        backpackPath.addLine(to: CGPoint(x: center.x - 2 * scale, y: center.y + 8 * scale))
        backpackPath.addLine(to: CGPoint(x: center.x + 2 * scale, y: center.y + 8 * scale))
        backpackPath.addLine(to: CGPoint(x: center.x + 2 * scale, y: center.y + 4 * scale))
        
        context.stroke(backpackPath, with: .color(color), lineWidth: scale)
    }
}

// 自定义探索图标
struct ExploreTabIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(Color.gray)
                .offset(x: 0.5, y: -0.5) // 稍微偏移以匹配图片中的位置
        }
    }
} 
