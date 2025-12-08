import SwiftUI

// 自适应高度的UITextView - 简化iPad兼容版本
struct AutoSizingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var heightChanged: ((CGFloat) -> Void)? = nil
    
    // 添加防抖动计时器
    private static var heightUpdateTimer: Timer?
    // 添加上次计算的高度缓存
    private static var lastCalculatedHeight: CGFloat = 42
    
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
        
        // 设置行间距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 2
        textView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 15),
            .paragraphStyle: paragraphStyle
        ]
        
        // 设置文本内容
        textView.text = text
        
        #if DEBUG
        debugLog("AutoSizingTextView - makeUIView 创建")
        #endif
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 同步文本内容
        if uiView.text != text {
            let selectedRange = uiView.selectedRange
            
            // 应用行间距到现有文本
            if !text.isEmpty {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                paragraphStyle.paragraphSpacing = 2
                
                let attributedText = NSMutableAttributedString(string: text)
                attributedText.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: NSRange(location: 0, length: text.count))
                attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
                
                uiView.attributedText = attributedText
            } else {
            uiView.text = text
            }
            
            // 确保typingAttributes也有行间距设置
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            paragraphStyle.paragraphSpacing = 2
            uiView.typingAttributes = [
                .font: UIFont.systemFont(ofSize: 15),
                .paragraphStyle: paragraphStyle
            ]
            
            // 只有在输入框获得焦点时才计算高度
            if isFocused {
                calculateAndUpdateHeight(uiView)
                scrollToBottom(uiView)
                
                // 保留用户的选择范围
                if selectedRange.location != NSNotFound {
                    uiView.selectedRange = selectedRange
                }
            }
        }
        
        // 简化的焦点状态处理
        if isFocused && !uiView.isFirstResponder {
            #if DEBUG
            debugLog("AutoSizingTextView - 激活键盘")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    uiView.becomeFirstResponder()
            }
        } else if !isFocused && uiView.isFirstResponder {
            #if DEBUG
            debugLog("AutoSizingTextView - 收起键盘")
            #endif
                    uiView.resignFirstResponder()
                }
        
        // 如果有焦点且有文本，确保正确显示
        if isFocused && !text.isEmpty {
            calculateAndUpdateHeight(uiView)
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
        if abs(newHeight - AutoSizingTextView.lastCalculatedHeight) > 4 {
            AutoSizingTextView.heightUpdateTimer?.invalidate()
            AutoSizingTextView.heightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
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
            let range = NSRange(location: max(0, textView.text.count - 1), length: 1)
            textView.scrollRangeToVisible(range)
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
            // 同步文本变化
                parent.text = textView.text
            parent.calculateAndUpdateHeight(textView)
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            #if DEBUG
            debugLog("AutoSizingTextView - textViewDidBeginEditing")
            #endif
            // 简单更新焦点状态
            if !parent.isFocused {
                DispatchQueue.main.async {
                self.parent.isFocused = true
                }
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            #if DEBUG
            debugLog("AutoSizingTextView - textViewDidEndEditing")
            #endif
            // 简单更新焦点状态
            if parent.isFocused {
                DispatchQueue.main.async {
                self.parent.isFocused = false
                }
            }
        }
    }
} 