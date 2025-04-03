import UIKit
import SwiftUI

/**
 * UIViewController扩展，提供查找导航控制器的方法
 */
extension UIViewController {
    /**
     * 查找当前视图控制器层级中的导航控制器
     * @return 找到的导航控制器，如果没有找到则返回nil
     */
    func findNavigationController() -> UINavigationController? {
        if let nav = self as? UINavigationController {
            return nav
        }
        
        for child in children {
            if let nav = child as? UINavigationController {
                return nav
            }
            
            if let nav = child.findNavigationController() {
                return nav
            }
        }
        
        return nil
    }
} 