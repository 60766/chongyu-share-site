import SwiftUI

// 添加UIWindow扩展，用于查找第一响应者和文本视图
extension UIWindow {
    func firstResponder() -> UIResponder? {
        return findFirstResponder(in: self)
    }

    private func findFirstResponder(in view: UIView) -> UIResponder? {
        for subview in view.subviews {
            if subview.isFirstResponder {
                return subview
            }

            if let responder = findFirstResponder(in: subview) {
                return responder
            }
        }
        return nil
    }

    // 查找视图层次结构中的UITextView
    func findTextViewInHierarchy() -> UITextView? {
        return findTextView(in: self)
    }

    private func findTextView(in view: UIView) -> UITextView? {
        // 首先检查当前视图是否是UITextView
        if let textView = view as? UITextView {
            return textView
        }

        // 递归检查所有子视图
        for subview in view.subviews {
            if let textView = findTextView(in: subview) {
                return textView
            }
        }

        return nil
    }
}

struct KeyboardForcingHelper {
    static func forceHideKeyboard() {
        #if DEBUG
        print("KeyboardForcingHelper - 强制隐藏键盘")
        #endif
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 添加UIPerformSelector辅助类，用于调用私有API
class UIPerformSelector {
    static func perform(_ target: AnyObject, selector: String) {
        let selector = NSSelectorFromString(selector)
        if target.responds(to: selector) {
            // 使用 _ = 接收返回值，避免警告
            _ = target.perform(selector)
        }
    }
} 