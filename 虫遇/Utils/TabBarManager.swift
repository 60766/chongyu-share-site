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
    
    /// 隐藏状态栈 - 用于管理嵌套页面的TabBar状态
    var hideStateStack: [Bool] = []
    
    /// 获取完整的底部区域高度（TabBar + 安全区域）
    var fullBottomAreaHeight: CGFloat {
        return isVisible ? (tabBarHeight + bottomSafeAreaHeight) : 0
    }
    
    /// 单例实例
    static let shared = TabBarManager()
    
    /// 调试状态
    #if DEBUG
    var debugModeEnabled: Bool = false
    #endif
    
    /// 动画持续时间
    private let animationDuration: TimeInterval = 0.25
    
    /// 存储添加的底部覆盖视图，便于后续移除
    private var addedOverlayViews: [UIView] = []
    
    /// 存储添加的高度约束，防止重复添加
    private var heightConstraint: NSLayoutConstraint?
    
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
        
        // 添加应用完成启动的监听，确保初始样式正确应用
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidFinishLaunching),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )
        
        // 添加应用进入前台的监听，确保每次回到应用时样式正确
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // 监听应用状态变化，确保状态一致性
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationStateChanged),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 清空堆栈，确保初始状态正确
        hideStateStack.removeAll()
        
        // 延迟一点时间应用初始样式，确保UI完全加载
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.forceResetAndShow()
            self.initialStyleSetup()
        }
    }
    
    /// 应用初始样式设置
    @objc private func applicationDidFinishLaunching(_ notification: Notification) {
        // 延迟执行，确保TabBar已经完全初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.initialStyleSetup()
        }
    }
    
    /// 应用进入前台时重新应用样式
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        // 应用重新进入前台时应用样式
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.initialStyleSetup()
        }
    }
    
    /// 应用状态变化处理
    @objc private func applicationStateChanged(_ notification: Notification) {
        // 当应用进入后台时重置堆栈，避免状态不一致
        if notification.name == UIApplication.didEnterBackgroundNotification {
            hideStateStack.removeAll()
            isVisible = true
            isFullyHidden = false
        }
    }
    
    /// 初始样式设置 - 确保TabBar透明
    private func initialStyleSetup() {
        guard let tabBarController = findTabBarController() else { return }
        tabBarController.tabBar.isHidden = false
        
        // 应用透明样式
        applyTransparentStyle(to: tabBarController.tabBar)
        
        // 应用一致的样式，但确保不会隐藏TabBar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.applyConsistentStyle()
            
            // 再次确保TabBar可见
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tabBarController.tabBar.isHidden = false
            }
        }
    }
    
    /// 推入新的隐藏状态 - 简化版
    func pushHideState() {
        hideStateStack.append(true)
        
        // 简单直接地隐藏TabBar - 不再使用位置记忆和复杂动画
        DispatchQueue.main.async {
            if let tabBarController = self.findTabBarController() {
                // 直接设置TabBar为隐藏状态
                tabBarController.tabBar.isHidden = true
                
                // 明确禁用TabBar的交互，防止点击事件穿透
                tabBarController.tabBar.isUserInteractionEnabled = false
                print("TabBar交互已禁用 (pushHideState)")
                
                // 如果已有高度约束，先移除
                if let existingConstraint = self.heightConstraint {
                    existingConstraint.isActive = false
                    self.heightConstraint = nil
                }
                
                // 给TabBar添加零高度约束，避免重复添加
                let newHeightConstraint = tabBarController.tabBar.heightAnchor.constraint(equalToConstant: 0)
                newHeightConstraint.priority = .required
                newHeightConstraint.isActive = true
                self.heightConstraint = newHeightConstraint
                
                // 立即更新布局
                UIView.performWithoutAnimation {
                    tabBarController.view.layoutIfNeeded()
                }
                
                // 更新观察属性
                self.isVisible = false
                self.isFullyHidden = true
                self.showFloatingButtons = false
            }
        }
    }
    
    /// 弹出一个隐藏状态
    func popHideState() {
        if !hideStateStack.isEmpty {
            hideStateStack.removeLast()
            
            // 如果状态栈为空，立即显示TabBar
            if hideStateStack.isEmpty {
                isVisible = true
                isFullyHidden = false
                showFloatingButtons = true
                prefersHomeIndicatorAutoHidden = false
                
                // 立即获取并设置TabBar
                if let tabBarController = findTabBarController() {
                    tabBarController.tabBar.isHidden = false
                    
                    // 移除高度约束
                    if let existingConstraint = self.heightConstraint {
                        existingConstraint.isActive = false
                        self.heightConstraint = nil
                    }
                    
                    // 恢复TabBar交互
                    tabBarController.tabBar.isUserInteractionEnabled = true
                    print("TabBar交互已恢复 (popHideState)")
                    
                    // 应用一致的样式
                    applyConsistentStyle()
                }
            }
            
            #if DEBUG
            if self.debugModeEnabled {
    
            }
            #endif
        } else {
            #if DEBUG
            if self.debugModeEnabled {
    
            }
            #endif
        }
    }
    
    /// 应用透明样式到TabBar
    private func applyTransparentStyle(to tabBar: UITabBar) {
        // 确保TabBar可见
        tabBar.isHidden = false
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.isTranslucent = true
            tabBar.backgroundColor = UIColor.clear
            tabBar.backgroundImage = UIImage()
            tabBar.shadowImage = UIImage()
        }
    }
    
    /// 无动画显示TabBar - 内部使用
    private func showWithoutAnimation() {
        // 先移除所有覆盖层和约束
        removeAllOverlays()
        restoreTabBarInteraction()
        removeAllBottomLines()
        
        // 查找并重置TabBar
        if let tabBarController = findTabBarController() {
            // 移除所有高度约束
            for constraint in tabBarController.tabBar.constraints {
                if constraint.firstAttribute == .height {
                    constraint.isActive = false
                }
            }
            
            // 重置TabBar状态
            tabBarController.tabBar.isHidden = false
            tabBarController.tabBar.alpha = 1
            
            // 恢复内容视图布局 - 确保不改变其位置
            if let contentView = tabBarController.selectedViewController?.view {
                // 保持内容视图的布局一致性
                contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            
            // 立即更新布局
            tabBarController.view.setNeedsLayout()
            tabBarController.view.layoutIfNeeded()
        }
    }
    
    /// 重置所有状态
    func resetState() {
        hideStateStack.removeAll()
        show()
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
        // 注意：不再将TabBar设置为隐藏
        if findTabBarController() != nil {
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
                
                window = windowScenes.first?.windows.first(where: { $0.isKeyWindow })
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
        
        // 获取TabBar并禁用其交互
        if let tabBarController = findTabBarController() {
            // 明确禁用TabBar的交互，防止点击事件穿透
            tabBarController.tabBar.isUserInteractionEnabled = false
            print("TabBar交互已禁用 (hide)")
        }
    }
    
    /// 显示底部导航栏和所有浮动按钮 - 无动画直接显示
    func show() {
        isVisible = true
        isFullyHidden = false
        showFloatingButtons = true
        prefersHomeIndicatorAutoHidden = false
        
        // 恢复TabBar交互
        if let tabBarController = findTabBarController() {
            tabBarController.tabBar.isUserInteractionEnabled = true
        }
    }
    
    /// 保存所有ScrollView的位置
    private func saveScrollViewPositions(in view: UIView, to positions: inout [UIScrollView: CGPoint]) {
        if let scrollView = view as? UIScrollView {
            positions[scrollView] = scrollView.contentOffset
        }
        
        for subview in view.subviews {
            saveScrollViewPositions(in: subview, to: &positions)
        }
    }
    
    /// 恢复所有ScrollView的位置
    private func restoreScrollViewPositions(in view: UIView, from positions: [UIScrollView: CGPoint]) {
        if let scrollView = view as? UIScrollView, let position = positions[scrollView] {
            scrollView.setContentOffset(position, animated: false)
        }
        
        for subview in view.subviews {
            restoreScrollViewPositions(in: subview, from: positions)
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
    
    /// 无动画彻底隐藏TabBar - 内部使用
    private func completelyHideWithoutAnimation() {
        // 设置ScrollView全局配置，确保内容可以延伸到底部
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = false
        
        // 移除所有之前的覆盖层
        self.removeAllOverlays()
        
        // 查找并隐藏TabBar
        if let tabBarController = self.findTabBarController() {
            // 移除所有现有约束
            for constraint in tabBarController.tabBar.constraints {
                if constraint.firstAttribute == .height {
                    constraint.isActive = false
                }
            }
            
            // 设置TabBar完全隐藏
            tabBarController.tabBar.isHidden = true
            tabBarController.tabBar.alpha = 0
            
            // 添加新的高度约束
            let heightConstraint = tabBarController.tabBar.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.priority = .required
            heightConstraint.isActive = true
            
            // 调整内容视图布局 - 但保持滚动位置
            if let contentView = tabBarController.selectedViewController?.view {
                // 只更新自动调整遮罩而不改变frame
                contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            
            // 立即更新布局
            tabBarController.view.setNeedsLayout()
            tabBarController.view.layoutIfNeeded()
        }
        
        // 移除底部黑线
        self.removeAllBottomLines()
        
        // 修复底部白色区域
        self.fixBottomWhiteArea()
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
        // 立即执行，不使用延迟
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
        
        // 移除fullCover视图，它可能导致白色遮挡问题
        
        // 移除gradientView和gradientLayer，它们可能导致白色遮挡问题
        
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
        
        // 先重置所有状态
        DispatchQueue.main.async {
            // 移除所有之前的覆盖层
            self.removeAllOverlays()
            
            // 查找并隐藏TabBar
            if let tabBarController = self.findTabBarController() {
                // 移除所有现有约束
                for constraint in tabBarController.tabBar.constraints {
                    if constraint.firstAttribute == .height {
                        constraint.isActive = false
                    }
                }
                
                // 设置TabBar完全隐藏
                tabBarController.tabBar.isHidden = true
                tabBarController.tabBar.alpha = 0
                
                // 添加新的高度约束
                let heightConstraint = tabBarController.tabBar.heightAnchor.constraint(equalToConstant: 0)
                heightConstraint.priority = .required
                heightConstraint.isActive = true
                
                // 调整内容视图布局
                if let contentView = tabBarController.selectedViewController?.view {
                    // 移除原有的底部约束
                    contentView.constraints.forEach { constraint in
                        if constraint.firstAttribute == .bottom {
                            constraint.isActive = false
                        }
                    }
                    
                    // 确保内容视图填充整个空间
                    contentView.frame = tabBarController.view.bounds
                    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                }
                
                // 立即更新布局
                tabBarController.view.setNeedsLayout()
                tabBarController.view.layoutIfNeeded()
            }
            
            // 移除底部黑线
            self.removeAllBottomLines()
            
            // 修复底部白色区域
            self.fixBottomWhiteArea()
        }
    }
    
    /// 立即显示TabBar，没有任何延迟
    func showImmediately() {
        // 立即重置状态
        hideStateStack.removeAll()
        isVisible = true
        isFullyHidden = false
        showFloatingButtons = true
        prefersHomeIndicatorAutoHidden = false
        
        // 立即获取并设置TabBar
        if let tabBarController = findTabBarController() {
            // 立即设置可见
            tabBarController.tabBar.isHidden = false
            tabBarController.tabBar.alpha = 1.0
            
            // 恢复TabBar交互
            tabBarController.tabBar.isUserInteractionEnabled = true
            print("TabBar交互已恢复 (showImmediately)")
            
            // 立即更新布局
            UIView.performWithoutAnimation {
                tabBarController.view.setNeedsLayout()
                tabBarController.view.layoutIfNeeded()
            }
            
            // 立即应用样式
            applyConsistentStyle()
        }
        
        // 立即设置ScrollView
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
        UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = true
        
        print("TabBar立即显示完成")
    }
    
    /// 强制重置堆栈和显示状态
    func forceResetAndShow() {
        // 立即重置状态栈
        hideStateStack.removeAll()
        
        // 立即更新状态
        isVisible = true
        isFullyHidden = false
        showFloatingButtons = true
        prefersHomeIndicatorAutoHidden = false
        
        // 立即获取TabBar控制器
        guard let tabBarController = findTabBarController() else {
            print("TabBarManager: 无法获取TabBar控制器")
            return
        }
        
        // 立即设置TabBar可见
        tabBarController.tabBar.isHidden = false
        tabBarController.tabBar.alpha = 1.0
        
        // 立即应用样式
        applyConsistentStyle()
        
        // 立即更新布局
        tabBarController.view.setNeedsLayout()
        tabBarController.view.layoutIfNeeded()
        
        // 立即设置ScrollView默认设置
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
        UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = true
        
        #if DEBUG
        if self.debugModeEnabled {
            print("TabBar强制重置并立即显示完成")
        }
        #endif
    }
    
    /**
     * 确保TabBar可见
     * 用于保证TabBar在特定页面中始终可见
     */
    func ensureTabBarVisible() {
        // 如果存在隐藏状态，逐一弹出
        while !hideStateStack.isEmpty {
            popHideState()
        }
        
        // 确保TabBar完全显示
        if let tabBarController = findTabBarController() {
            tabBarController.tabBar.isHidden = false
            
            // 应用一致的样式
            applyConsistentStyle()
            
            // 立即更新状态
            isVisible = true
            isFullyHidden = false
            showFloatingButtons = true
            
            // 立即确保TabBar可见，不使用延迟
            tabBarController.tabBar.isHidden = false
            // 再次确保状态一致
            self.isVisible = true
            self.isFullyHidden = false
            
            #if DEBUG
            if self.debugModeEnabled {
        
            }
            #endif
        }
    }
    
    #if DEBUG
    /// 打印当前堆栈状态 - 仅在调试模式可用
    func printStackState() {
        if debugModeEnabled {
            print("TabBar堆栈状态: 深度 \(hideStateStack.count)")
            print("TabBar可见性: \(isVisible ? "可见" : "隐藏")")
            print("TabBar完全隐藏: \(isFullyHidden ? "是" : "否")")
        }
    }

    /// 启用调试模式
    func enableDebugMode() {
        debugModeEnabled = true
        print("TabBar调试模式已启用")
        printStackState()
    }

    /// 重置并打印状态
    func resetAndPrintState() {
        showImmediately()
        print("TabBar已强制重置并显示")
        printStackState()
    }
    #endif
    
    /// 平滑显示TabBar - 用于从详情页返回时避免闪烁
    func smoothShowTabBar() {
        // 立即重置状态栈，但不立即更新UI
        hideStateStack.removeAll()
        
        // 立即更新状态
        isVisible = true
        isFullyHidden = false
        showFloatingButtons = true
        prefersHomeIndicatorAutoHidden = false
        
        // 立即获取TabBar控制器
        guard let tabBarController = findTabBarController() else {
            print("TabBarManager: 无法获取TabBar控制器")
            return
        }
        
        // 直接设置TabBar可见，不进行任何中间状态
        tabBarController.tabBar.isHidden = false
        tabBarController.tabBar.alpha = 1.0
        tabBarController.tabBar.isUserInteractionEnabled = true
        
        // 移除所有可能的高度约束
        for constraint in tabBarController.tabBar.constraints {
            if constraint.firstAttribute == .height && constraint.constant == 0 {
                constraint.isActive = false
            }
        }
        
        // 立即应用样式，但不触发额外的布局更新
        UIView.performWithoutAnimation {
            // 应用一致的样式
            applyConsistentStyle()
            
            // 立即更新布局
            tabBarController.view.layoutIfNeeded()
        }
        
        // 设置ScrollView默认设置
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
        UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = true
        
        print("TabBar平滑显示完成")
    }
    
    /// 平滑隐藏TabBar - 用于导航到详情页前
    func smoothHideTabBar() {
        // 添加隐藏状态，但不立即触发布局更新
        hideStateStack.append(true)
        
        // 更新状态
        isVisible = false
        isFullyHidden = true
        showFloatingButtons = false
        
        // 获取TabBar控制器
        guard let tabBarController = findTabBarController() else {
            print("TabBarManager: 无法获取TabBar控制器")
            return
        }
        
        // 使用无动画的方式隐藏TabBar
        UIView.performWithoutAnimation {
            // 直接设置TabBar隐藏
            tabBarController.tabBar.isHidden = true
            tabBarController.tabBar.alpha = 0
            tabBarController.tabBar.isUserInteractionEnabled = false
            
            // 立即更新布局
            tabBarController.view.layoutIfNeeded()
        }
        
        print("TabBar平滑隐藏完成")
    }
}
