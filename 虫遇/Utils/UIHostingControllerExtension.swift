import SwiftUI
import UIKit

/**
 * UIHostingController扩展
 * 提供完全禁用安全区域的方法，确保全屏视图不受系统安全区域的影响
 */
extension UIHostingController {
    
    /**
     * 完全禁用安全区域（增强版）
     * 通过递归查找子视图并设置safeAreaInsets为零实现
     */
    func disableSafeAreaEnhanced() {
        // 递归遍历所有子视图并禁用安全区域
        if let viewClass = NSClassFromString("_UIRemoteKeyboardWindow") {
            // 兼容iOS 15+的窗口获取方式
            if #available(iOS 15.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            if type(of: window) != viewClass {
                                process(view: window)
                            }
                        }
                    }
                }
            } else {
                // 旧版iOS的窗口获取方式
                for window in UIApplication.shared.windows {
                    if type(of: window) != viewClass {
                        process(view: window)
                    }
                }
            }
        }
        
        // 禁用当前控制器的安全区域
        guard let viewClass = object_getClass(view) else { return }
        
        let selector = #selector(getter: UIView.safeAreaInsets)
        guard let method = class_getInstanceMethod(viewClass, selector) else { return }
        
        let originalImpl = method_getImplementation(method)
        let originalType = method_getTypeEncoding(method)
        
        // 替换safeAreaInsets方法，使其永远返回零边距
        class_replaceMethod(viewClass, selector, imp_implementationWithBlock({ _ in
            UIEdgeInsets.zero
        } as @convention(block) (UIView) -> UIEdgeInsets), originalType)
        
        // 保存原始实现，以便后续恢复
        objc_setAssociatedObject(self, "safeAreaOriginalImpl", originalImpl, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, "safeAreaOriginalType", originalType, .OBJC_ASSOCIATION_RETAIN)
    }
    
    /**
     * 递归处理视图及其子视图的安全区域
     */
    private func process(view: UIView) {
        // 处理当前视图
        if let viewClass = object_getClass(view) {
            let selector = #selector(getter: UIView.safeAreaInsets)
            if class_getInstanceMethod(viewClass, selector) != nil {
                let key = "safeAreaProcessed_\(viewClass)"
                if objc_getAssociatedObject(view, key) == nil {
                    let originalImpl = class_replaceMethod(viewClass, selector, imp_implementationWithBlock({ _ in
                        UIEdgeInsets.zero
                    } as @convention(block) (UIView) -> UIEdgeInsets), nil)
                    
                    objc_setAssociatedObject(view, key, true, .OBJC_ASSOCIATION_RETAIN)
                    if let original = originalImpl {
                        objc_setAssociatedObject(view, "\(key)_original", original, .OBJC_ASSOCIATION_RETAIN)
                    }
                }
            }
        }
        
        // 递归处理所有子视图
        for subview in view.subviews {
            process(view: subview)
        }
    }
    
    /**
     * 恢复安全区域设置
     */
    func restoreSafeArea() {
        guard let viewClass = object_getClass(view),
              let originalImpl = objc_getAssociatedObject(self, "safeAreaOriginalImpl"),
              let originalType = objc_getAssociatedObject(self, "safeAreaOriginalType") else { return }
        
        let selector = #selector(getter: UIView.safeAreaInsets)
        class_replaceMethod(viewClass, selector, originalImpl as! IMP, originalType as? UnsafePointer<Int8>)
    }
    
    /**
     * 自动隐藏Home Indicator
     * 使全屏体验更加沉浸
     */
    func enableHomeIndicatorAutoHiding() {
        // 使用关联对象存储值
        objc_setAssociatedObject(self, "homeIndicatorShouldAutoHide", true, .OBJC_ASSOCIATION_RETAIN)
        // 要求系统更新Home Indicator状态
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    /**
     * 显示Home Indicator
     * 恢复标准系统行为
     */
    func disableHomeIndicatorAutoHiding() {
        // 使用关联对象存储值
        objc_setAssociatedObject(self, "homeIndicatorShouldAutoHide", false, .OBJC_ASSOCIATION_RETAIN)
        // 要求系统更新Home Indicator状态
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    /**
     * 覆盖 prefersHomeIndicatorAutoHidden 方法
     * 这个方法需要在子类中实现，但我们可以用运行时添加
     */
    func setupPrefersHomeIndicatorAutoHidden() {
        // 检查是否已经是自定义子类
        let currentClass: AnyClass = object_getClass(self)!
        let className = NSStringFromClass(currentClass)
        if className.hasPrefix("CustomUIHostingController_") {
            // 已经设置过了，不需要重复设置
            return
        }
        
        // 创建一个子类
        let newClassName = "CustomUIHostingController_\(arc4random())"
        
        // 注册新的子类，以当前类为父类
        guard let subclass = objc_allocateClassPair(currentClass, newClassName, 0) else {
            print("无法创建子类来控制Home Indicator")
            return
        }
        
        // 添加方法实现
        let selector = #selector(getter: UIViewController.prefersHomeIndicatorAutoHidden)
        guard let method = class_getInstanceMethod(UIViewController.self, selector) else {
            print("无法获取prefersHomeIndicatorAutoHidden方法")
            objc_disposeClassPair(subclass)
            return
        }
        
        // 创建新的实现
        let implementation = imp_implementationWithBlock { (controller: AnyObject) -> Bool in
            // 从关联对象获取值，默认false
            return objc_getAssociatedObject(controller, "homeIndicatorShouldAutoHide") as? Bool ?? false
        } as IMP
        
        // 添加方法到子类
        if !class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method)) {
            print("无法添加prefersHomeIndicatorAutoHidden方法")
            objc_disposeClassPair(subclass)
            return
        }
        
        // 注册并设置类
        objc_registerClassPair(subclass)
        object_setClass(self, subclass)
        
        // 标记已设置子类
        objc_setAssociatedObject(self, "hasSetupHomeIndicator", true, .OBJC_ASSOCIATION_RETAIN)
    }
}

/**
 * 提供全屏展示功能的控制器创建扩展
 */
extension View {
    /**
     * 创建一个完全禁用安全区域的UIHostingController
     */
    func createFullscreenController() -> UIHostingController<Self> {
        let controller = UIHostingController(rootView: self)
        controller.disableSafeAreaEnhanced()
        return controller
    }
    
    /**
     * 创建一个全屏模态控制器
     */
    func presentAsFullscreenModal(from presentingController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        let controller = createFullscreenController()
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        presentingController.present(controller, animated: animated, completion: completion)
    }
}

/**
 * 辅助运行时工具类
 * 提供对 Objective-C 运行时可见的方法，帮助处理 Home Indicator
 */
@objc class HomeIndicatorHelper: NSObject {
    
    /**
     * 启用 Home Indicator 自动隐藏
     */
    @objc static func enableHomeIndicatorAutoHiding(for viewController: UIViewController) {
        objc_setAssociatedObject(viewController, "homeIndicatorShouldAutoHide", true, .OBJC_ASSOCIATION_RETAIN)
        viewController.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    /**
     * 禁用 Home Indicator 自动隐藏
     */
    @objc static func disableHomeIndicatorAutoHiding(for viewController: UIViewController) {
        objc_setAssociatedObject(viewController, "homeIndicatorShouldAutoHide", false, .OBJC_ASSOCIATION_RETAIN)
        viewController.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    /**
     * 设置 prefersHomeIndicatorAutoHidden 方法覆盖
     */
    @objc static func setupPrefersHomeIndicatorAutoHidden(for viewController: UIViewController) {
        // 检查是否已经是自定义子类
        let currentClass: AnyClass = object_getClass(viewController)!
        let className = NSStringFromClass(currentClass)
        if className.hasPrefix("CustomViewController_") {
            // 已经设置过了，不需要重复设置
            return
        }
        
        // 创建一个子类
        let newClassName = "CustomViewController_\(arc4random())"
        
        // 注册新的子类，以当前类为父类
        guard let subclass = objc_allocateClassPair(currentClass, newClassName, 0) else {
            print("无法创建子类来控制Home Indicator")
            return
        }
        
        // 添加方法实现
        let selector = #selector(getter: UIViewController.prefersHomeIndicatorAutoHidden)
        guard let method = class_getInstanceMethod(UIViewController.self, selector) else {
            print("无法获取prefersHomeIndicatorAutoHidden方法")
            objc_disposeClassPair(subclass)
            return
        }
        
        // 创建新的实现
        let implementation = imp_implementationWithBlock { (controller: AnyObject) -> Bool in
            // 从关联对象获取值，默认false
            return objc_getAssociatedObject(controller, "homeIndicatorShouldAutoHide") as? Bool ?? false
        } as IMP
        
        // 添加方法到子类
        if !class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method)) {
            print("无法添加prefersHomeIndicatorAutoHidden方法")
            objc_disposeClassPair(subclass)
            return
        }
        
        // 注册并设置类
        objc_registerClassPair(subclass)
        object_setClass(viewController, subclass)
        
        // 标记已设置子类
        objc_setAssociatedObject(viewController, "hasSetupHomeIndicator", true, .OBJC_ASSOCIATION_RETAIN)
    }
}

/// 强制更新所有窗口以应用新的约束
private func forceWindowUpdate() {
    if #available(iOS 15.0, *) {
        // 使用新的API - 遍历所有活跃的窗口场景
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.setNeedsLayout()
                    window.layoutIfNeeded()
                }
            }
        }
    } else {
        // iOS 15之前使用旧API
        for window in UIApplication.shared.windows {
            window.setNeedsLayout()
            window.layoutIfNeeded()
        }
    }
} 
