import SwiftUI
import UIKit

/// UITextView的SwiftUI包装器
/// 使用UIKit原生UITextView组件提供更可靠的文本输入体验
struct UIKitTextView: UIViewRepresentable {
    // MARK: - 属性
    
    @Binding var text: String
    var placeholder: String
    var isFirstResponder: Bool = false
    var onTap: (() -> Void)? = nil
    
    // MARK: - 静态属性
    
    /// 控制是否应该激活文本视图
    static var globalShouldActivate: Bool = true
    
    // MARK: - UIViewRepresentable 实现
    
    /**
     * 创建UITextView并配置其基本属性
     */
    func makeUIView(context: Context) -> UITextView {
        #if DEBUG
        print("UIKitTextView - 创建新的UITextView实例")
        #endif
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        // 设置外观 - 优化设计，确保文本和光标对齐
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.backgroundColor = .white // 使用白色背景而非透明
        textView.textColor = .black // 黑色文本
        textView.tintColor = .blue // 蓝色光标
        
        // 优化文本视图内边距 - 减少左侧内边距使光标更接近文本
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 3, bottom: 8, right: 5)
        // 设置为0确保文本与光标精确对齐
        textView.textContainer.lineFragmentPadding = 0
        
        // 基本功能设置
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.showsVerticalScrollIndicator = false
        
        // 添加手势识别
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.cancelsTouchesInView = false // 不取消其他触摸事件
        tapGesture.requiresExclusiveTouchType = false // 不需要独占触摸类型
        tapGesture.delegate = context.coordinator // 设置手势委托
        textView.addGestureRecognizer(tapGesture)
        
        // 在整个视图层级上打印点击区域信息，便于调试
        #if DEBUG
        print("UIKitTextView - 点击区域大小: \(textView.bounds)")
        #endif
        
        // 增强点击响应
        textView.addSubview(UIView()) // 添加一个空视图确保点击事件正常工作
        
        // 设置初始文本或占位符
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.gray
        } else {
            textView.text = text
            textView.textColor = UIColor.black
        }
        
        // 调整文本绘制位置
        textView.layoutManager.usesFontLeading = false // 禁用字体前导可能有助于更精确的文本定位
        
        // 激活文本视图（如果需要）
        if isFirstResponder && UIKitTextView.globalShouldActivate {
            #if DEBUG
            print("UIKitTextView - 尝试激活第一响应者")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textView.becomeFirstResponder()
                #if DEBUG
                print("UIKitTextView - 成为第一响应者: \(textView.isFirstResponder)")
                #endif
            }
        }
        
        return textView
    }
    
    /**
     * 更新UITextView的状态
     */
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
            #if DEBUG
            print("UIKitTextView - 需要聚焦但未聚焦，尝试聚焦")
            #endif
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                #if DEBUG
                print("UIKitTextView - 焦点状态变更为: \(uiView.isFirstResponder)")
                #endif
            }
        } else if !isFirstResponder && uiView.isFirstResponder {
            #if DEBUG
            print("UIKitTextView - 不需要聚焦但已聚焦，取消聚焦")
            #endif
            uiView.resignFirstResponder()
        }
        
        // 强制刷新视图
        uiView.setNeedsDisplay()
    }
    
    /**
     * 创建协调器
     */
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, placeholder: placeholder, onTap: onTap)
    }
    
    // MARK: - Coordinator
    
    /**
     * 协调器处理UITextView的代理回调
     */
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        @Binding var text: String
        let placeholder: String
        let onTap: (() -> Void)?
        
        init(text: Binding<String>, placeholder: String, onTap: (() -> Void)?) {
            self._text = text
            self.placeholder = placeholder
            self.onTap = onTap
        }
        
        /**
         * 开始编辑
         */
        func textViewDidBeginEditing(_ textView: UITextView) {
            #if DEBUG
            print("UIKitTextView - 开始编辑")
            #endif
            if textView.text == placeholder {
                textView.text = ""
                textView.textColor = UIColor.black
            }
        }
        
        /**
         * 结束编辑
         */
        func textViewDidEndEditing(_ textView: UITextView) {
            #if DEBUG
            print("UIKitTextView - 结束编辑")
            #endif
            if textView.text.isEmpty {
                textView.text = placeholder
                textView.textColor = UIColor.gray
            }
        }
        
        /**
         * 文本变化
         */
        func textViewDidChange(_ textView: UITextView) {
            if textView.text != placeholder {
                text = textView.text
                #if DEBUG
                print("UIKitTextView - 文本已更新: \(text.count) 字符")
                #endif
            } else {
                text = ""
            }
        }
        
        /**
         * 处理点击
         */
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            #if DEBUG
            print("UIKitTextView - 检测到点击手势")
            #endif
            onTap?()
            
            if let textView = gesture.view as? UITextView {
                if !textView.isFirstResponder {
                    #if DEBUG
                    print("UIKitTextView - 手动激活输入框")
                    #endif
                    textView.becomeFirstResponder()
                }
            }
        }
        
        /**
         * 允许同时识别多个手势
         */
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true // 允许手势同时识别
        }
    }
} 