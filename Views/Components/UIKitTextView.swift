import SwiftUI
import UIKit

/// UITextView的SwiftUI包装器
struct UIKitTextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isFirstResponder: Bool = false
    var onTap: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        // 设置外观
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.tintColor = .blue
        
        // 设置文本视图内边距
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        textView.textContainer.lineFragmentPadding = 0
        
        // 基本功能设置
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.showsVerticalScrollIndicator = false
        
        // 添加手势识别
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        textView.addGestureRecognizer(tapGesture)
        
        // 设置初始文本或占位符
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.gray
        } else {
            textView.text = text
            textView.textColor = UIColor.black
        }
        
        // 激活文本视图（如果需要）
        if isFirstResponder {
            textView.becomeFirstResponder()
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 更新文本内容（如果已更改）
        if uiView.text != text && !(text.isEmpty && uiView.text == placeholder) {
            if text.isEmpty && !uiView.isFirstResponder {
                uiView.text = placeholder
                uiView.textColor = UIColor.gray
            } else if uiView.text == placeholder && !text.isEmpty {
                uiView.text = text
                uiView.textColor = UIColor.black
            } else {
                uiView.text = text
                uiView.textColor = UIColor.black
            }
        }
        
        // 处理焦点状态
        if isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, placeholder: placeholder, onTap: onTap)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        let placeholder: String
        let onTap: (() -> Void)?
        
        init(text: Binding<String>, placeholder: String, onTap: (() -> Void)?) {
            self._text = text
            self.placeholder = placeholder
            self.onTap = onTap
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == placeholder {
                textView.text = ""
                textView.textColor = UIColor.black
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = placeholder
                textView.textColor = UIColor.gray
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.text != placeholder {
                text = textView.text
            } else {
                text = ""
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            onTap?()
            
            if let textView = gesture.view as? UITextView {
                if !textView.isFirstResponder {
                    textView.becomeFirstResponder()
                }
            }
        }
    }
} 