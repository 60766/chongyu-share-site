import UIKit
import SwiftUI

/**
 * 导航助手类
 * 提供全局导航控制和支持
 */
public class NavigationHelper {
    /// 单例实例
    public static let shared = NavigationHelper()
    
    /// 私有初始化方法
    private init() {
        #if DEBUG
        print("NavigationHelper初始化")
        #endif
    }
    
    /// 强制返回上一级页面
    public func forceGoBack() {
        DispatchQueue.main.async {
            // 查找顶层视图控制器
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let topVC = window.rootViewController?.topMostViewController {
                
                // 如果是导航控制器，尝试弹出
                if let navigationController = topVC.navigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    // 否则尝试dismiss
                    topVC.dismiss(animated: true)
                }
            }
        }
    }
}

// MARK: - UIViewController扩展
extension UIViewController {
    /// 获取最顶层的视图控制器
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController ?? self
        }
        
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController ?? self
        }
        
        return self
    }
    
    /// 关闭当前视图控制器
    func dismissVC(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: animated)
            completion?()
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }
} 