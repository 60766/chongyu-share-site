import SwiftUI
import UIKit

/// 专门为梦幻联动设计的键盘强制工具
class MultiChatKeyboardHelper {
    /// 强制显示键盘
    static func forceShowKeyboard() {
        #if DEBUG
        print("MultiChatKeyboardHelper - 强制显示键盘")
        #endif
        
        // 尝试让当前第一响应者获得焦点
        let result = UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        #if DEBUG
        print("MultiChatKeyboardHelper - becomeFirstResponder 结果: \(result)")
        #endif
        
        // 手动发送键盘通知
        let keyboardHeight = UIScreen.main.bounds.height * 0.35
        let keyboardFrame = CGRect(
            x: 0,
            y: UIScreen.main.bounds.height - keyboardHeight,
            width: UIScreen.main.bounds.width,
            height: keyboardHeight
        )
        
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: keyboardFrame,
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
            UIResponder.keyboardAnimationCurveUserInfoKey: UIView.AnimationCurve.easeInOut.rawValue
        ]
        
        // 发送系统键盘通知
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: userInfo
        )
        
        // 延迟发送键盘已显示通知
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: UIResponder.keyboardDidShowNotification,
                object: nil,
                userInfo: userInfo
            )
        }
        
        // 发送自定义通知
        NotificationCenter.default.post(
            name: Notification.Name("MultiChatForceShowKeyboard"),
            object: nil,
            userInfo: ["height": keyboardHeight]
        )
    }
    
    /// 强制隐藏键盘
    static func forceHideKeyboard() {
        #if DEBUG
        print("MultiChatKeyboardHelper - 强制隐藏键盘")
        #endif
        
        // 让当前第一响应者失去焦点
        let result = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #if DEBUG
        print("MultiChatKeyboardHelper - resignFirstResponder 结果: \(result)")
        #endif
        
        // 发送自定义通知
        NotificationCenter.default.post(
            name: Notification.Name("MultiChatForceHideKeyboard"),
            object: nil
        )
        
        // 发送系统键盘通知，确保所有观察者都知道键盘已隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )
            
            // 延迟发送键盘已隐藏通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(
                    name: UIResponder.keyboardDidHideNotification,
                    object: nil
                )
            }
        }
    }
} 