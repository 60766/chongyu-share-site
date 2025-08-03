import SwiftUI

// 自适应高度的UITextView
struct AutoSizingTextView: UIViewRepresentable {
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
        
        // 设置文本内容
        textView.text = text
        
        // 确保初始状态正确
        if isFocused {
            DispatchQueue.main.async {
                textView.becomeFirstResponder()
                
                // 将光标放在文本末尾
                if !self.text.isEmpty {
                    let endPosition = textView.endOfDocument
                    textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
                }
            }
        }
        
        // 如果有文本，确保一开始就滚动到底部
        if !text.isEmpty {
            DispatchQueue.main.async {
                self.scrollToBottom(textView)
            }
        }
        
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
            DispatchQueue.main.async {
                if isFocused {
                    uiView.becomeFirstResponder()
                    
                    // 当获得焦点时，立即计算高度
                    if !text.isEmpty {
                        calculateAndUpdateHeight(uiView)
                        
                        // 获得焦点时也滚动到底部
                        scrollToBottom(uiView)
                    }
                } else {
                    uiView.resignFirstResponder()
                }
            }
        } else if isFocused && !text.isEmpty {
            // 即使焦点状态没变，只要是焦点状态，也计算高度
            calculateAndUpdateHeight(uiView)
            
            // 确保文本显示在底部
            scrollToBottom(uiView)
        }
    }
    
    // 统一的高度计算和更新方法
    private func calculateAndUpdateHeight(_ textView: UITextView) {
        guard let heightChanged = heightChanged else { return }
        
        // 计算新高度
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        let newHeight = size.height
        
        // 防抖动逻辑
        if abs(newHeight - AutoSizingTextView.lastCalculatedHeight) > 2 { // 高度变化阈值
            AutoSizingTextView.heightUpdateTimer?.invalidate()
            AutoSizingTextView.heightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                // 在主线程上更新高度
                DispatchQueue.main.async {
                    heightChanged(newHeight)
                    AutoSizingTextView.lastCalculatedHeight = newHeight
                }
            }
        }
    }
    
    // 滚动到底部的方法
    private func scrollToBottom(_ textView: UITextView) {
        let contentHeight = textView.contentSize.height
        let frameHeight = textView.frame.size.height
        if contentHeight > frameHeight {
            textView.scrollRangeToVisible(NSRange(location: (textView.text as NSString).length - 1, length: 1))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AutoSizingTextView
        
        init(_ parent: AutoSizingTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
            parent.calculateAndUpdateHeight(textView)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
            // 在失去焦点时重置高度，如果需要的话
            // parent.heightChanged?(36) //
        }
    }
} 