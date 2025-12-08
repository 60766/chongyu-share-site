import SwiftUI
import UIKit

/**
 * 新版直接文本输入组件
 * 使用最简单直接的方法实现UITextView
 */
struct DirectTextInput: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onFocus: ((Bool) -> Void)?
    // 添加一个debug选项
    var debug: Bool = false
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        
        if debug {
            #if DEBUG
            debugLog("创建UITextView，初始文本: \"\(text)\"")
            #endif
            // 设置醒目的背景色和边框，便于调试
            textView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.2)
            textView.layer.borderWidth = 2
            textView.layer.borderColor = UIColor.red.cgColor
        } else {
            // 确保背景是明确的白色或系统背景色
            textView.backgroundColor = UIColor.white
            textView.layer.borderWidth = 1
            textView.layer.borderColor = UIColor.systemGray5.cgColor
        }
        
        // 基本设置
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        
        // 完全禁用内边距自动调整，这可能影响文本显示
        textView.textContainer.lineFragmentPadding = 0
        
        // 确保文本颜色清晰可见
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else {
            textView.text = text
            // 使用纯黑色以确保最高对比度
            textView.textColor = UIColor.black
        }
        
        // 确保可交互
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        
        // 禁用自动更正和自动大写，避免潜在干扰
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        
        // 增强版点击识别 - 对所有实例都添加点击处理
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        
        // 移除键盘工具栏，去掉"完成"按钮
        textView.inputAccessoryView = nil
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if debug {
            #if DEBUG
            debugLog("更新UITextView，文本绑定: \"\(text)\", 当前文本显示: \"\(textView.text ?? "")\"")
            #endif
            #if DEBUG
            debugLog("文本颜色: \(textView.textColor == .placeholderText ? "占位符颜色" : "正常颜色")")
            #endif
        }
        
        // 更严格的判断：当绑定的text有值时，确保文本显示正确且颜色为黑色
        if !text.isEmpty {
            // 总是设置文本和颜色
            if textView.text != text || textView.textColor == .placeholderText {
                #if DEBUG
                if debug { debugLog("强制更新文本和颜色") }
                #endif
                textView.text = text
                textView.textColor = UIColor.black
            }
        } else {
            // 当绑定的text为空时的处理
            if textView.isFirstResponder {
                // 当处于编辑状态时，保持文本为空白并且颜色为黑色
                if textView.text != "" {
                    textView.text = ""
                }
                textView.textColor = UIColor.black
            } else {
                // 当未处于编辑状态时，显示占位符
                if textView.text != placeholder {
                    textView.text = placeholder
                }
                textView.textColor = .placeholderText
            }
        }
        
        // 每次更新时都确保交互性
        textView.isUserInteractionEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: DirectTextInput
        
        init(_ parent: DirectTextInput) {
            self.parent = parent
        }
        
        // 增强版点击处理方法
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if parent.debug {
                #if DEBUG
                debugLog("检测到UITextView上的点击!")
                #endif
            }
            
            if let textView = gesture.view as? UITextView {
                // 使用更强力的方式确保获取焦点
                if !textView.isFirstResponder {
                    // 尝试让上级视图放弃焦点
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    // 震动反馈确认点击被识别
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // 强制成为第一响应者
                    DispatchQueue.main.async {
                        textView.becomeFirstResponder()
                        
                        // 确保占位符文本被清除
                        if textView.textColor == .placeholderText {
                            textView.text = ""
                            textView.textColor = UIColor.black
                        }
                    }
                }
            }
        }
        
        // 确保手势识别器与其他手势兼容
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if parent.debug {
                #if DEBUG
                debugLog("UITextView开始编辑，当前文本: \"\(textView.text ?? "")\"")
                #endif
            }
            
            parent.onFocus?(true)
            
            if textView.textColor == .placeholderText {
                textView.text = ""
                // 使用纯黑色确保可见性
                textView.textColor = UIColor.black
            }
            
            textView.layer.borderColor = UIColor.systemBlue.cgColor
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.debug {
                #if DEBUG
                debugLog("UITextView结束编辑，文本内容: \"\(textView.text ?? "")\"")
                #endif
            }
            
            parent.onFocus?(false)
            
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            } else {
                // 确保非空文本使用黑色
                textView.textColor = UIColor.black
                
                // 额外检查：确保Binding中的文本被正确更新
                if parent.text != textView.text {
                    DispatchQueue.main.async {
                        self.parent.text = textView.text ?? ""
                    }
                }
            }
            
            textView.layer.borderColor = UIColor.systemGray5.cgColor
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.textColor != .placeholderText {
                // 更新绑定的文本
                parent.text = textView.text ?? ""
                
                // 设置调试打印
                if parent.debug {
                    #if DEBUG
                    debugLog("文本已更新为: \"\(parent.text)\"")
                    #endif
                }
            }
        }
    }
}

/**
 * 最简化文本输入测试视图
 * 用于诊断发布页面的文本输入问题
 */
struct MinimalTextTest: View {
    @State private var text = ""
    @State private var isFocused = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("输入测试").font(.headline)
            
            // 直接嵌入测试用文本输入组件
            DirectTextInput(
                text: $text,
                placeholder: "请点击这里输入文本",
                onFocus: { focused in
                    isFocused = focused
                    #if DEBUG
                    debugLog("焦点状态: \(focused ? "获得焦点" : "失去焦点")")
                    #endif
                },
                debug: true // 启用调试模式
            )
            .frame(height: 100)
            .padding(20)
            // 添加鲜艳的背景便于识别
            .background(Color.yellow.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red, lineWidth: 2)
            )
            
            // 状态显示
            Text("状态: \(isFocused ? "已获取焦点" : "未获取焦点")")
                .padding()
                .background(isFocused ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
        .padding()
    }
}

/**
 * 重置后的原SimpleTextView
 * 保留以便兼容性
 */
struct SimpleTextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onFocus: ((Bool) -> Void)?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        
        // 基本设置
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = .systemBackground
        textView.layer.cornerRadius = 10
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        
        // 初始文本
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else {
            textView.text = text
            textView.textColor = .label
        }
        
        // 确保可交互
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        
        // 增强版点击识别 - 对所有实例都添加点击处理
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        
        // 移除键盘工具栏，去掉"完成"按钮
        textView.inputAccessoryView = nil
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.textColor != .placeholderText && textView.text != text {
            textView.text = text
        }
        
        // 更新边框颜色以反映焦点状态
        if textView.isFirstResponder {
            textView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            textView.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: SimpleTextView
        
        init(_ parent: SimpleTextView) {
            self.parent = parent
        }
        
        // 增强版点击处理方法
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if let textView = gesture.view as? UITextView {
                // 使用更强力的方式确保获取焦点
                if !textView.isFirstResponder {
                    // 尝试让上级视图放弃焦点
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    // 强制成为第一响应者
                    DispatchQueue.main.async {
                        textView.becomeFirstResponder()
                    }
                }
            }
        }
        
        // 确保手势识别器与其他手势兼容
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onFocus?(true)
            
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.onFocus?(false)
            
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.textColor != .placeholderText {
                parent.text = textView.text
            }
        }
    }
}

/**
 * 输入按钮视图
 * 当没有文本输入时显示的按钮
 */
struct InputButton: View {
    var placeholder: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text(placeholder)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("点击输入")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(14)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * 文本输入区域包装器
 * 提供良好的视觉反馈和交互体验
 */
struct TextInputArea: View {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool
    
    // 添加内部状态跟踪点击事件
    @State private var wasPressed: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            // 如果没有焦点且没有文本，显示按钮
            if !isFocused && text.isEmpty {
                InputButton(placeholder: placeholder) {
                    #if DEBUG
                    debugLog("点击了InputButton")
                    #endif
                    isFocused = true
                    
                    // 尝试强制第一响应者为nil，再设置新的响应者
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            } else {
                // 否则显示文本输入框，但使用更直接的交互方式
                ZStack {
                    // 底层添加一个透明按钮，确保能接收到点击事件
                    Button(action: {
                        #if DEBUG
                        debugLog("点击了底层按钮区域")
                        #endif
                        if !isFocused {
                            isFocused = true
                            // 强制文本视图成为第一响应者
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }) {
                        // 完全透明的背景，但可以接收点击
                        Rectangle()
                            .fill(Color.clear)
                    }
                    
                    // 实际的文本输入框
                    DirectTextInput(
                        text: $text,
                        placeholder: placeholder,
                        onFocus: { focused in
                            #if DEBUG
                            debugLog("DirectTextInput焦点变化: \(focused)")
                            #endif
                            isFocused = focused
                        },
                        debug: true // 继续保留调试模式
                    )
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: isFocused ? 2 : 1)
                    )
                }
                .onTapGesture {
                    #if DEBUG
                    debugLog("检测到ZStack的点击事件")
                    #endif
                    if !isFocused {
                        isFocused = true
                        wasPressed = true
                        
                        // 使用震动反馈提示点击已被识别
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // 尝试让文本视图成为第一响应者
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
                .onChange(of: wasPressed) { oldValue, newValue in
                    if newValue {
                        // 重置按压状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.wasPressed = false
                        }
                    }
                }
                
                // 如果有内容但没有焦点，显示继续编辑按钮
                if !isFocused && !text.isEmpty {
                    Button(action: {
                        #if DEBUG
                        debugLog("点击了继续编辑按钮")
                        #endif
                        isFocused = true
                        
                        // 尝试让文本视图成为第一响应者
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }) {
                        Text("继续编辑")
                            .font(.system(size: 13))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(14)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.opacity)
                }
            }
        }
    }
}

/**
 * 测试专用TextField组件
 * 用于测试SwiftUI环境中的文本输入功能
 */
struct TextFieldTest: View {
    @State private var text = ""
    @State private var isFocused = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("文本输入测试")
                .font(.headline)
            
            // 使用标准SwiftUI TextField
            TextField("使用SwiftUI TextField输入", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // 使用自定义UITextView封装
            SimpleTextView(text: $text, placeholder: "使用UITextView输入", onFocus: { focused in
                isFocused = focused
            })
            .frame(height: 100)
            .padding(.horizontal)
            
            // 使用TextInputArea组件
            TextInputArea(text: $text, placeholder: "综合组件测试", isFocused: $isFocused)
                .padding(.horizontal)
            
            // 测试按钮
            Button("测试输入框焦点") {
                isFocused.toggle()
                
                if isFocused {
                    // 尝试让UIKit文本视图获取焦点
                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                } else {
                    // 尝试让UIKit文本视图失去焦点
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .buttonStyle(.borderedProminent)
            
            // 显示当前状态
            VStack(alignment: .leading) {
                Text("输入文本: \(text)")
                Text("焦点状态: \(isFocused ? "获得焦点" : "失去焦点")")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .padding()
    }
}

// 提供预览
struct TextFieldTest_Previews: PreviewProvider {
    static var previews: some View {
        TextFieldTest()
    }
}

/**
 * 直接输入组件 - 使用原生TextField
 * 完全避开UITextView的使用，使用原生SwiftUI控件
 */
struct DirectTextField: View {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool
    
    // 内部焦点状态
    @FocusState private var fieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 直接使用原生TextField
            TextField(placeholder, text: $text)
                .focused($fieldFocused)
                .font(.system(size: 16))
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(fieldFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: fieldFocused ? 2 : 1)
                )
                .padding(1)
                .onChange(of: fieldFocused) { oldValue, newValue in
                    isFocused = newValue
                    #if DEBUG
                    debugLog("TextField焦点状态变化: \(newValue)")
                    #endif
                }
                .onTapGesture {
                    #if DEBUG
                    debugLog("TextField被点击")
                    #endif
                    fieldFocused = true
                }
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if newValue != fieldFocused {
                fieldFocused = newValue
            }
        }
    }
}

/**
 * 超级简化版文本输入区域
 * 使用最基本的SwiftUI组件，确保可交互性
 * 此组件供所有需要简单文本输入的视图使用
 */
public struct SimpleInputArea: View {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool
    
    // 调试模式标志，用于开发过程中排查问题
    var debug: Bool = false
    
    // 添加内部状态跟踪点击事件
    @State private var wasPressed: Bool = false
    // 内部焦点状态，用于增强可靠性
    @FocusState private var internalFocus: Bool
    
    // 公开初始化方法以便其他文件可以使用
    public init(text: Binding<String>, placeholder: String, isFocused: Binding<Bool>, debug: Bool = false) {
        self._text = text
        self.placeholder = placeholder
        self._isFocused = isFocused
        self.debug = debug
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // 占位符文本 - 当文本为空且未获得焦点时显示
            if text.isEmpty && !internalFocus {
                Text(placeholder)
                    .font(.system(size: 16))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false) // 允许点击穿透到下层
            }
            
            // 使用TextEditor替代TextField获得更好的多行支持
            TextEditor(text: $text)
                .font(.system(size: 16))
                .foregroundColor(.primary) // 确保文本颜色正确显示
                .focused($internalFocus)
                .scrollContentBackground(.hidden) // iOS 16+隐藏背景
                .background(Color.clear)
                .padding(.horizontal, 12) // 水平内边距
                .padding(.vertical, 12) // 垂直内边距
                .frame(maxWidth: .infinity, maxHeight: .infinity) // 填充整个可用空间
                .opacity(1) // 确保文本不会透明
        }
        .frame(minHeight: 120) // 最小高度确保有足够的空间
        .background(Color.clear) // 确保背景透明
        .contentShape(Rectangle()) // 使整个区域可点击
        .onTapGesture {
            if debug {
                #if DEBUG
                debugLog("SimpleInputArea被点击")
                #endif
            }
            internalFocus = true
            isFocused = true
            wasPressed = true
            
            // 提供触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        .onAppear {
            if debug {
                #if DEBUG
                debugLog("SimpleInputArea 出现")
                #endif
            }
            
            // 确保焦点状态同步
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                internalFocus = isFocused
            }
        }
        .onChange(of: wasPressed) { oldValue, newValue in
            if newValue {
                // 重置按压状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.wasPressed = false
                }
            }
        }
        .onChange(of: internalFocus) { oldValue, newValue in
            if debug {
                #if DEBUG
                debugLog("内部焦点变化: \(newValue)")
                #endif
            }
            isFocused = newValue
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if internalFocus != newValue {
                if debug {
                    #if DEBUG
                    debugLog("外部焦点变化: \(newValue)")
                    #endif
                }
                internalFocus = newValue
            }
        }
        // 添加轻微动画效果
        .animation(.easeInOut(duration: 0.2), value: internalFocus)
    }
}

// 添加缩放按钮样式
struct InputScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/**
 * 增强型TextField组件
 * 提供更好的视觉反馈和交互体验
 */
struct HighlightableTextField: View {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool
    var debug: Bool = false
    
    // 使用FocusState
    @FocusState private var fieldFocused: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 使用原生SwiftUI TextField
            TextField(placeholder, text: $text)
                .focused($fieldFocused)
                .font(.system(size: 16))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .shadow(color: fieldFocused ? Color.blue.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 1)
                )
                .onChange(of: fieldFocused) { oldValue, newValue in
                    if debug {
                        #if DEBUG
                        debugLog("HighlightableTextField焦点变化: \(newValue)")
                        #endif
                    }
                    isFocused = newValue
                }
                .onChange(of: isFocused) { oldValue, newValue in
                    if newValue != fieldFocused {
                        if debug {
                            #if DEBUG
                            debugLog("正在同步外部焦点状态到HighlightableTextField: \(newValue)")
                            #endif
                        }
                        fieldFocused = newValue
                    }
                }
                .onTapGesture {
                    if debug {
                        #if DEBUG
                        debugLog("HighlightableTextField被点击")
                        #endif
                    }
                    
                    // 立即触发反馈
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    fieldFocused = true
                    isPressed = true
                    
                    // 延迟重置按压状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPressed = false
                    }
                }
                // 添加视觉状态指示器（仅在调试模式下显示）
                .overlay(
                    debug ? 
                    HStack {
                        Spacer()
                        Circle()
                            .fill(fieldFocused ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                            .padding(4)
                    } : nil
                )
                // 添加按压动画效果
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.3), value: isPressed)
                .onAppear {
                    if debug {
                        #if DEBUG
                        debugLog("HighlightableTextField 出现")
                        #endif
                    }
                    
                    // 如果外部已经设置了焦点，同步到内部
                    if isFocused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            fieldFocused = true
                        }
                    }
                }
                // 增加底层按钮作为后备方案
                .background(
                    Button(action: {
                        if debug {
                            #if DEBUG
                            debugLog("HighlightableTextField底层按钮被点击")
                            #endif
                        }
                        fieldFocused = true
                    }) {
                        Color.clear
                    }
                    .buttonStyle(PlainButtonStyle())
                )
        }
    }
}

/**
 * 直接输入视图
 * 使用最直接的方式实现文本输入功能
 */
public struct DirectInputView: View {
    @Binding var text: String
    var placeholder: String
    @FocusState private var isFocused: Bool
    
    public var body: some View {
        VStack {
            TextEditor(text: $text)
                .focused($isFocused)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.blue : Color.gray.opacity(0.5), 
                                lineWidth: isFocused ? 2 : 1)
                )
                .overlay(
                    Group {
                        if text.isEmpty && !isFocused {
                            Text(placeholder)
                                .foregroundColor(.gray)
                                .padding(.leading, 12)
                                .padding(.top, 16)
                        }
                    },
                    alignment: .topLeading
                )
                .onChange(of: isFocused) { oldValue, newValue in
                    #if DEBUG
                    debugLog("焦点状态变化: \(newValue)")
                    #endif
                }
                .onChange(of: text) { oldValue, newValue in
                    #if DEBUG
                    debugLog("文本长度: \(newValue.count)")
                    #endif
                }
        }
    }
}

/**
 * 超简化版文本输入框
 * 使用最基本的UIKit实现，专门用于解决文本显示问题
 */
struct SuperSimpleTextInput: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        // 设置字体和颜色
        view.font = UIFont.systemFont(ofSize: 16)
        view.textColor = UIColor.black
        
        // 设置背景为明确的白色
        view.backgroundColor = UIColor.white
        
        // 设置内容
        view.text = text.isEmpty ? placeholder : text
        
        // 设置占位符颜色
        if text.isEmpty {
            view.textColor = UIColor.gray
        }
        
        // 简单的边框设置
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
        
        // 设置代理
        view.delegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 只有当实际文本不同且不是占位符时才更新
        let isPlaceholder = uiView.textColor == UIColor.gray
        
        // 如果是占位符但绑定的text不为空，更新内容和颜色
        if isPlaceholder && !text.isEmpty {
            uiView.text = text
            uiView.textColor = UIColor.black
        }
        // 如果不是占位符且绑定的text为空，显示占位符
        else if !isPlaceholder && text.isEmpty {
            uiView.text = placeholder
            uiView.textColor = UIColor.gray
        }
        // 如果不是占位符且文本不同，更新文本
        else if !isPlaceholder && uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SuperSimpleTextInput
        
        init(_ parent: SuperSimpleTextInput) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // 如果是占位符，清空并改变颜色
            if textView.textColor == UIColor.gray {
                textView.text = ""
                textView.textColor = UIColor.black
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // 如果文本为空，显示占位符
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.gray
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // 更新绑定
            parent.text = textView.text ?? ""
            
            // 调试输出
            #if DEBUG
            debugLog("文本更新为: \"\(textView.text ?? "")\"")
            #endif
        }
    }
}

// 测试视图
struct SuperSimpleTestView: View {
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("超简单文本测试")
                .font(.headline)
            
            SuperSimpleTextInput(text: $text, placeholder: "点击输入文字...")
                .frame(height: 100)
                .padding()
                .background(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1)
                )
            
            Text("当前文本: \"\(text)\"")
                .padding()
            
            Button("添加测试文本") {
                text = "这是一段测试文本 " + Date().formatted()
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
    }
}
