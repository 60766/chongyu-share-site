import Foundation
import SwiftUI
import UIKit
import Combine

/// 底部导航栏管理器 - 用于控制底部导航栏的显示和隐藏
class TabBarManager: ObservableObject {
    /// 是否显示底部导航栏
    @Published var isVisible: Bool = true
    
    /// 是否完全隐藏底部导航栏（物理隐藏，而不仅是透明度为0）
    @Published var isFullyHidden: Bool = false
    
    /// 是否显示底部浮动按钮（包括非导航栏的其他浮动按钮）
    @Published var showFloatingButtons: Bool = true
    
    /// TabBar的高度 (不包含安全区域) - 从49减小到42
    @Published private(set) var tabBarHeight: CGFloat = 42
    
    /// 底部安全区域高度，由系统计算并在AppTabView中设置
    @Published private(set) var bottomSafeAreaHeight: CGFloat = 34
    
    /// Home Indicator 控制
    @Published var prefersHomeIndicatorAutoHidden: Bool = false
    
    /// 获取完整的底部区域高度（TabBar + 安全区域）
    var fullBottomAreaHeight: CGFloat {
        return isVisible ? (tabBarHeight + bottomSafeAreaHeight) : 0
    }
    
    /// 单例实例
    static let shared = TabBarManager()
    
    /// 动画持续时间
    private let animationDuration: TimeInterval = 0.25
    
    /// 存储添加的底部覆盖视图，便于后续移除
    private var addedOverlayViews: [UIView] = []
    
    private init() {
        // 获取初始安全区域高度
        setupSafeAreaHeight()
        
        // 监听屏幕旋转和应用状态变化重新计算安全区域
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setupSafeAreaHeight),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setupSafeAreaHeight),
            name: UIScene.didActivateNotification,
            object: nil
        )
        
        // 添加监听器，确保页面转换时TabBar视觉效果一致性
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ensureConsistentTabBar),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    /// 确保TabBar视觉效果一致性
    @objc private func ensureConsistentTabBar() {
        DispatchQueue.main.async {
            self.applyConsistentStyle()
            self.removeAllBottomLines() // 在每次应用状态变化时移除黑线
        }
    }
    
    /// 应用一致的样式
    func applyConsistentStyle() {
        // 使用alpha值0.4来匹配我们想要的高透明效果
        if let tabBarController = findTabBarController() {
            tabBarController.tabBar.isHidden = true
            
            // 获取根视图控制器并应用一致的样式
            if #available(iOS 15.0, *) {
                // iOS 15及更高版本
                let windowScenes = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                
                if let windowScene = windowScenes.first,
                   let window = windowScene.windows.first {
                    applyUltraThinStyle(to: window.rootViewController)
                }
            } else {
                // iOS 15以下版本
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                    applyUltraThinStyle(to: window.rootViewController)
                }
            }
        }
    }
    
    /// 递归应用超薄样式到所有控制器
    private func applyUltraThinStyle(to viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        // 应用样式到当前控制器
        if let navController = viewController as? UINavigationController {
            navController.navigationBar.isTranslucent = true
            if #available(iOS 15.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                navController.navigationBar.standardAppearance = appearance
                navController.navigationBar.scrollEdgeAppearance = appearance
            }
        }
        
        // 应用到任何子控制器
        for child in viewController.children {
            applyUltraThinStyle(to: child)
        }
        
        // 应用到任何呈现的控制器
        if let presented = viewController.presentedViewController {
            applyUltraThinStyle(to: presented)
        }
    }
    
    /// 查找TabBarController
    private func findTabBarController() -> UITabBarController? {
        if #available(iOS 15.0, *) {
            let windowScenes = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
            
            if let windowScene = windowScenes.first,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                return findTabBarControllerRecursively(in: rootViewController)
            }
        } else {
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
               let rootViewController = window.rootViewController {
                return findTabBarControllerRecursively(in: rootViewController)
            }
        }
        return nil
    }
    
    /// 递归查找TabBarController
    private func findTabBarControllerRecursively(in viewController: UIViewController) -> UITabBarController? {
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        for child in viewController.children {
            if let found = findTabBarControllerRecursively(in: child) {
                return found
            }
        }
        
        if let presentedVC = viewController.presentedViewController {
            return findTabBarControllerRecursively(in: presentedVC)
        }
        
        return nil
    }
    
    // 自动计算当前设备的底部安全区域高度
    @objc private func setupSafeAreaHeight() {
        // 使用主线程更新UI属性
        DispatchQueue.main.async {
            // 获取KeyWindow
            var window: UIWindow?
            
            if #available(iOS 15.0, *) {
                // iOS 15及以上使用UIWindowScene.windows
                let windowScenes = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                
                let scene = windowScenes.first
                window = scene?.windows.first(where: { $0.isKeyWindow })
            } else {
                // iOS 15以下使用UIApplication.windows
                window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            }
            
            // 获取安全区域
            if let window = window {
                self.bottomSafeAreaHeight = window.safeAreaInsets.bottom
                // 确保即使在没有安全区域的设备上也至少有8点的间距
                if self.bottomSafeAreaHeight < 8 {
                    self.bottomSafeAreaHeight = 8
                }
            }
            
            // 确保样式一致
            self.applyConsistentStyle()
        }
    }
    
    /// 隐藏底部导航栏和所有浮动按钮 - 无动画直接隐藏
    func hide() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            isVisible = false
            isFullyHidden = false
            showFloatingButtons = false
            prefersHomeIndicatorAutoHidden = true
        }
    }
    
    /// 显示底部导航栏和所有浮动按钮 - 无动画直接显示
    func show() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            isVisible = true
            isFullyHidden = false
            showFloatingButtons = true
            prefersHomeIndicatorAutoHidden = false
            
            // 恢复ScrollView默认设置
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
            UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = true
        }
        
        // 移除之前添加的所有覆盖层，确保交互正常
        DispatchQueue.main.async {
            self.removeAllOverlays()
            self.restoreTabBarInteraction()
            self.removeAllBottomLines() // 确保在显示TabBar时移除所有黑线
        }
    }
    
    /// 移除所有添加的透明覆盖层
    private func removeAllOverlays() {
        // 移除所有保存的覆盖视图
        for overlayView in addedOverlayViews {
            overlayView.removeFromSuperview()
        }
        addedOverlayViews.removeAll()
        
        // 查找并移除任何可能阻止交互的视图
        if #available(iOS 15.0, *) {
            let windowScenes = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
            
            if let windowScene = windowScenes.first,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                removeInteractionBlockingViews(from: rootVC.view)
            }
        } else {
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
               let rootVC = window.rootViewController {
                removeInteractionBlockingViews(from: rootVC.view)
            }
        }
    }
    
    /// 递归移除可能阻止交互的视图
    private func removeInteractionBlockingViews(from view: UIView) {
        // 查找底部区域的任何覆盖视图
        let viewsToRemove = view.subviews.filter { subview in
            // 位于底部的视图
            let isAtBottom = subview.frame.maxY > view.bounds.height - 100
            // 是覆盖层(透明视图)
            let isOverlay = subview.backgroundColor == .clear || subview.alpha < 0.1
            // 允许交互
            let blocksInteraction = subview.isUserInteractionEnabled
            
            return isAtBottom && isOverlay && blocksInteraction
        }
        
        // 移除这些视图
        for viewToRemove in viewsToRemove {
            viewToRemove.removeFromSuperview()
        }
        
        // 递归检查所有子视图
        for subview in view.subviews {
            removeInteractionBlockingViews(from: subview)
        }
    }
    
    /// 恢复TabBar交互
    private func restoreTabBarInteraction() {
        if let tabBarController = findTabBarController() {
            // 设置TabBar可见性
            tabBarController.tabBar.isHidden = true // 依然保持隐藏，因为我们使用自定义TabBar
            
            // 移除可能添加的高度约束
            for constraint in tabBarController.tabBar.constraints where constraint.firstAttribute == .height {
                if constraint.constant == 0 {
                    constraint.isActive = false
                }
            }
            
            // 更新布局
            tabBarController.view.layoutIfNeeded()
        }
    }
    
    /// 彻底隐藏底部导航栏 - 物理移除而不仅仅是视觉隐藏
    func completelyHide() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            isVisible = false
            isFullyHidden = true
            showFloatingButtons = false
            prefersHomeIndicatorAutoHidden = true
            
            // 设置ScrollView全局配置，确保内容可以延伸到底部
            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
            UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        // 物理隐藏TabBar - 使用直接方式操作TabBar
        DispatchQueue.main.async {
            if #available(iOS 15.0, *) {
                // 使用新的API - 遍历所有活跃的窗口场景
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            self.hideTabBarInView(window)
                        }
                    }
                }
            } else {
                // iOS 15之前使用旧API
                for window in UIApplication.shared.windows {
                    self.hideTabBarInView(window)
                }
            }
            
            // 解决底部白色区域
            self.fixBottomWhiteArea()
            // 移除底部黑线
            self.removeAllBottomLines()
        }
    }
    
    // 在视图层次中隐藏TabBar
    private func hideTabBarInView(_ view: UIView) {
        if let tabBar = view as? UITabBar {
            // 直接隐藏TabBar
            tabBar.isHidden = true
            
            // 修改高度约束
            for constraint in tabBar.constraints where constraint.firstAttribute == .height {
                constraint.constant = 0
            }
            
            // 直接添加一个强制的高度约束
            let heightConstraint = tabBar.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.isActive = true
            
            // 立即应用布局更改
            tabBar.superview?.layoutIfNeeded()
        }
        
        // 递归检查所有子视图
        for subview in view.subviews {
            hideTabBarInView(subview)
        }
    }
    
    // 修复底部白色区域
    private func fixBottomWhiteArea() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            if #available(iOS 15.0, *) {
                // 使用新的API - 获取活跃的窗口场景
                let windowScenes = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                
                if let windowScene = windowScenes.first,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    // 添加完全透明的覆盖视图
                    self.createTransparentOverlays(for: rootVC, window: window)
                }
            } else {
                // iOS 15以下的处理代码
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                   let rootVC = window.rootViewController {
                    
                    // 添加完全透明的覆盖视图
                    self.createTransparentOverlays(for: rootVC, window: window)
                }
            }
        }
    }
    
    // 创建透明底部覆盖层
    private func createTransparentOverlays(for rootVC: UIViewController, window: UIWindow) {
        // 移除底部的黑线
        self.removeAllBottomLines()
        
        // 添加柔和分隔线 - 完全透明
        let separatorLine = UIView(frame: CGRect(
            x: 0,
            y: window.bounds.height - 0.5, // 位于屏幕最底部
            width: window.bounds.width,
            height: 0.5 // 只需0.5像素高度
        ))
        separatorLine.backgroundColor = UIColor.clear // 完全透明
        separatorLine.isUserInteractionEnabled = false
        separatorLine.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        rootVC.view.addSubview(separatorLine)
        addedOverlayViews.append(separatorLine)
        
        // 添加一个全覆盖透明层，确保没有白色边缘
        let fullCover = UIView(frame: CGRect(
            x: 0,
            y: window.bounds.height - 50, // 覆盖底部50像素区域
            width: window.bounds.width,
            height: 50
        ))
        fullCover.backgroundColor = UIColor.clear
        fullCover.isUserInteractionEnabled = false // 不拦截点击事件
        fullCover.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        rootVC.view.addSubview(fullCover)
        addedOverlayViews.append(fullCover)
        
        // 添加轻微的背景过渡层
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(
            x: 0,
            y: window.bounds.height - 20, // 位于屏幕底部上方20像素
            width: window.bounds.width,
            height: 20 // 20像素高度
        )
        // 创建从透明到极轻微背景色的渐变
        let backgroundColor = UIColor.systemBackground.withAlphaComponent(0.01) // 降低不透明度到0.01
        gradientLayer.colors = [UIColor.clear.cgColor, backgroundColor.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        
        // 创建包含渐变的视图
        let gradientView = UIView(frame: CGRect(
            x: 0,
            y: window.bounds.height - 20,
            width: window.bounds.width,
            height: 20
        ))
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        gradientView.isUserInteractionEnabled = false
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        rootVC.view.addSubview(gradientView)
        addedOverlayViews.append(gradientView)
        
        // 单一的底部透明层
        let invisibleBottomCover = UIView(frame: CGRect(
            x: 0,
            y: window.bounds.height - max(0, window.safeAreaInsets.bottom),
            width: window.bounds.width,
            height: max(0, window.safeAreaInsets.bottom)
        ))
        
        // 设置为完全透明，不拦截点击
        invisibleBottomCover.backgroundColor = UIColor.clear
        invisibleBottomCover.isUserInteractionEnabled = false
        invisibleBottomCover.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        // 将视图添加到根视图
        rootVC.view.addSubview(invisibleBottomCover)
        addedOverlayViews.append(invisibleBottomCover)
        
        // 强制布局刷新
        rootVC.view.layoutIfNeeded()
    }
    
    /// 更新底部安全区域高度
    func updateBottomSafeArea(height: CGFloat) {
        bottomSafeAreaHeight = height
    }
    
    /// 设置Home Indicator自动隐藏状态
    func setHomeIndicatorAutoHidden(_ hidden: Bool) {
        prefersHomeIndicatorAutoHidden = hidden
        updateRootViewControllerHomeIndicator()
    }
    
    /// 更新根视图控制器的Home Indicator设置
    private func updateRootViewControllerHomeIndicator() {
        DispatchQueue.main.async {
            if #available(iOS 15.0, *) {
                // 使用新的API - 获取活跃的窗口场景
                let windowScenes = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                
                if let windowScene = windowScenes.first,
                   let window = windowScene.windows.first,
                   var topController = window.rootViewController {
                    // 获取顶层控制器
                    while let presentedViewController = topController.presentedViewController {
                        topController = presentedViewController
                    }
                    
                    // 更新控制器设置 - 接受任何类型的UIHostingController
                    if let hostingController = topController as? UIHostingController<AnyView> {
                        self.updateHomeIndicator(for: hostingController)
                    } else if let hostingController = topController as? UIHostingController<AnyView> {
                        self.updateHomeIndicator(for: hostingController)
                    } else if let hostingController = topController as? UIHostingController<FullscreenContentView.FullscreenContent> {
                        self.updateHomeIndicator(for: hostingController)
                    } else if topController.isKind(of: UIHostingController<AnyView>.self) {
                        // 如果是UIHostingController的子类，但无法确定View类型，尝试使用运行时机制
                        self.updateHomeIndicatorUsingRuntime(for: topController)
                    }
                }
            } else {
                // iOS 15以下使用旧API
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                   var topController = window.rootViewController {
                    // 获取顶层控制器
                    while let presentedViewController = topController.presentedViewController {
                        topController = presentedViewController
                    }
                    
                    // 更新控制器设置 - 接受任何类型的UIHostingController
                    if let hostingController = topController as? UIHostingController<AnyView> {
                        self.updateHomeIndicator(for: hostingController)
                    } else if let hostingController = topController as? UIHostingController<AnyView> {
                        self.updateHomeIndicator(for: hostingController)
                    } else if let hostingController = topController as? UIHostingController<FullscreenContentView.FullscreenContent> {
                        self.updateHomeIndicator(for: hostingController)
                    } else if topController.isKind(of: UIHostingController<AnyView>.self) {
                        // 如果是UIHostingController的子类，但无法确定View类型，尝试使用运行时机制
                        self.updateHomeIndicatorUsingRuntime(for: topController)
                    }
                }
            }
        }
    }
    
    // 处理特定UIHostingController实例的Helper方法
    private func updateHomeIndicator<T: View>(for hostingController: UIHostingController<T>) {
        // 检查是否已经设置过子类
        let hasSetup = objc_getAssociatedObject(hostingController, "hasSetupHomeIndicator") as? Bool
        if hasSetup != true {
            hostingController.setupPrefersHomeIndicatorAutoHidden()
            objc_setAssociatedObject(hostingController, "hasSetupHomeIndicator", true, .OBJC_ASSOCIATION_RETAIN)
        }
        
        // 根据当前状态决定是启用还是禁用自动隐藏
        if self.prefersHomeIndicatorAutoHidden {
            hostingController.enableHomeIndicatorAutoHiding()
        } else {
            hostingController.disableHomeIndicatorAutoHiding()
        }
    }
    
    // 使用运行时处理任意UIViewController类型的方法
    private func updateHomeIndicatorUsingRuntime(for viewController: UIViewController) {
        // 检查是否是UIHostingController的实例
        let className = NSStringFromClass(type(of: viewController))
        guard className.contains("UIHostingController") else { return }
        
        // 检查是否已经设置过子类
        let hasSetup = objc_getAssociatedObject(viewController, "hasSetupHomeIndicator") as? Bool
        if hasSetup != true {
            // 设置子类以覆盖prefersHomeIndicatorAutoHidden方法
            HomeIndicatorHelper.setupPrefersHomeIndicatorAutoHidden(for: viewController)
            objc_setAssociatedObject(viewController, "hasSetupHomeIndicator", true, .OBJC_ASSOCIATION_RETAIN)
        }
        
        // 根据当前状态决定是启用还是禁用自动隐藏
        if self.prefersHomeIndicatorAutoHidden {
            HomeIndicatorHelper.enableHomeIndicatorAutoHiding(for: viewController)
        } else {
            HomeIndicatorHelper.disableHomeIndicatorAutoHiding(for: viewController)
        }
    }
    
    /// 移除所有页面中的底部黑线
    func removeAllBottomLines() {
        DispatchQueue.main.async {
            if #available(iOS 15.0, *) {
                let windowScenes = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                
                if let windowScene = windowScenes.first,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    self.findAndRemoveBottomLines(in: rootVC.view)
                }
            } else {
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                   let rootVC = window.rootViewController {
                    self.findAndRemoveBottomLines(in: rootVC.view)
                }
            }
        }
    }
    
    /// 递归查找并移除底部黑线
    private func findAndRemoveBottomLines(in view: UIView) {
        let screenHeight = UIScreen.main.bounds.height
        
        // 查找位于屏幕底部的细线视图
        for subview in view.subviews {
            // 检查是否是位于底部的细线
            let isBottomLine = subview.frame.height <= 1.0 && 
                              subview.frame.maxY > screenHeight - 50 &&
                              subview.frame.width > UIScreen.main.bounds.width * 0.5
            
            // 如果是黑线或分隔线，设置为完全透明
            if isBottomLine {
                subview.backgroundColor = UIColor.clear
                subview.alpha = 0
                subview.isHidden = true
            }
            
            // 递归查找子视图中的黑线
            findAndRemoveBottomLines(in: subview)
        }
    }
}
