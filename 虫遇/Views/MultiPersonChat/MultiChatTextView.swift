import SwiftUI
import UIKit

// 专门为梦幻联动设计的自适应高度文本视图
struct MultiChatTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var heightChanged: ((CGFloat) -> Void)? = nil
    
    // 添加防抖动计时器
    private static var heightUpdateTimer: Timer?
    // 添加上次计算的高度缓存
    private static var lastCalculatedHeight: CGFloat = 36
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.textContainerInset = UIEdgeInsets(top: 7, left: 0, bottom: 7, right: 0)
        textView.returnKeyType = .default
        textView.autocorrectionType = .default
        
        // 设置文本内容
        textView.text = text
        
        // 添加调试日志
        print("MultiChatTextView - makeUIView 创建")
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 同步文本内容，但保留光标位置
        if uiView.text != text {
            let selectedRange = uiView.selectedRange
            uiView.text = text
            
            // 只有在输入框获得焦点时才计算高度
            if isFocused {
                calculateAndUpdateHeight(uiView)
                
                // 滚动到底部，确保显示最后一行文本
                scrollToBottom(uiView)
                
                // 保留用户的选择范围，不强制将光标设置到末尾
                if selectedRange.location != NSNotFound {
                    uiView.selectedRange = selectedRange
                }
            }
        }
        
        // 处理焦点状态变化
        if isFocused != uiView.isFirstResponder {
            print("MultiChatTextView - updateUIView - isFocused: \(isFocused), isFirstResponder: \(uiView.isFirstResponder)")
            
            // 使用动画过渡，减少抖动
            UIView.animate(withDuration: 0.25) {
            if isFocused {
                // 使用延迟确保视图已完全加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("MultiChatTextView - 尝试激活键盘")
                    uiView.becomeFirstResponder()
                    
                        // 手动触发键盘通知，使用更平滑的动画
                    let keyboardHeight = UIScreen.main.bounds.height * 0.35
                    let keyboardFrame = CGRect(
                        x: 0,
                        y: UIScreen.main.bounds.height - keyboardHeight,
                        width: UIScreen.main.bounds.width,
                        height: keyboardHeight
                    )
                    
                    let userInfo: [AnyHashable: Any] = [
                        UIResponder.keyboardFrameEndUserInfoKey: keyboardFrame,
                            UIResponder.keyboardAnimationDurationUserInfoKey: 0.3, // 增加动画时间
                        UIResponder.keyboardAnimationCurveUserInfoKey: UIView.AnimationCurve.easeInOut.rawValue
                    ]
                    
                    NotificationCenter.default.post(
                        name: UIResponder.keyboardWillShowNotification,
                        object: nil,
                        userInfo: userInfo
                    )
                    
                    // 延迟后再次发送通知，确保键盘显示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: UIResponder.keyboardDidShowNotification,
                            object: nil,
                            userInfo: userInfo
                        )
                    }
                    
                    // 当获得焦点时，立即计算高度
                    if !text.isEmpty {
                        calculateAndUpdateHeight(uiView)
                        
                        // 获得焦点时也滚动到底部
                        scrollToBottom(uiView)
                    }
                }
            } else {
                uiView.resignFirstResponder()
                }
            }
        }
    }
    
    // 统一的高度计算和更新方法
    func calculateAndUpdateHeight(_ textView: UITextView) {
        guard let heightChanged = heightChanged else { return }
        
        // 计算新高度
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        let newHeight = size.height
        
        // 防抖动逻辑，增加阈值和延迟时间
        if abs(newHeight - MultiChatTextView.lastCalculatedHeight) > 3 { // 增加高度变化阈值
            MultiChatTextView.heightUpdateTimer?.invalidate()
            MultiChatTextView.heightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                // 在主线程上更新高度，使用动画
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25) {
                    heightChanged(newHeight)
                    MultiChatTextView.lastCalculatedHeight = newHeight
                    }
                }
            }
        }
    }
    
    // 滚动到底部的方法
    private func scrollToBottom(_ textView: UITextView) {
        let contentHeight = textView.contentSize.height
        let frameHeight = textView.frame.size.height
        if contentHeight > frameHeight {
            // 使用动画滚动到底部
            UIView.animate(withDuration: 0.2) {
            textView.scrollRangeToVisible(NSRange(location: (textView.text as NSString).length - 1, length: 1))
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultiChatTextView
        
        init(_ parent: MultiChatTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.calculateAndUpdateHeight(textView)
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            print("MultiChatTextView - textViewDidBeginEditing")
            
            // 使用动画过渡状态，但避免在视图更新期间直接修改状态
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.parent.isFocused = true
                }
            
                // 手动触发键盘通知，使用更平滑的动画
            let keyboardHeight = UIScreen.main.bounds.height * 0.35
            let keyboardFrame = CGRect(
                x: 0,
                y: UIScreen.main.bounds.height - keyboardHeight,
                width: UIScreen.main.bounds.width,
                height: keyboardHeight
            )
            
            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: keyboardFrame,
                    UIResponder.keyboardAnimationDurationUserInfoKey: 0.3, // 增加动画时间
                UIResponder.keyboardAnimationCurveUserInfoKey: UIView.AnimationCurve.easeInOut.rawValue
            ]
            
            NotificationCenter.default.post(
                name: UIResponder.keyboardWillShowNotification,
                object: nil,
                userInfo: userInfo
            )
            
            // 延迟后再次发送通知，确保键盘显示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(
                    name: UIResponder.keyboardDidShowNotification,
                    object: nil,
                    userInfo: userInfo
                )
            }
            
                self.parent.calculateAndUpdateHeight(textView)
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            print("MultiChatTextView - textViewDidEndEditing")
            // 使用动画过渡状态，但避免在视图更新期间直接修改状态
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.parent.isFocused = false
                }
            }
        }
    }
} 